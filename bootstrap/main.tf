# ONE-TIME BOOTSTRAP, run once by an AWS admin from a laptop or CloudShell.
# Creates:
#   1. The CircleCI OIDC identity provider (so CircleCI never stores AWS keys)
#   2. One IAM role per environment that only this CircleCI project can assume
#   3. An S3 bucket for Terraform state (versioned, encrypted, private)
#
#   terraform init
#   terraform apply -var circleci_org_id=<ORG_ID> -var circleci_project_id=<PROJECT_ID>
#
# Then copy the role ARNs from the output into the CircleCI contexts
# (see docs/SETUP.md).

terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "circleci_org_id" {
  description = "CircleCI organization ID (Organization Settings > Overview)."
  type        = string
}

variable "circleci_project_id" {
  description = "CircleCI project ID (Project Settings > Overview). Limits role use to this project."
  type        = string
}

variable "project" {
  type    = string
  default = "ocsd-poc"
}

variable "environments" {
  type    = list(string)
  default = ["dev", "test", "stage", "prod"]
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  oidc_url  = "https://oidc.circleci.com/org/${var.circleci_org_id}"
  oidc_host = "oidc.circleci.com/org/${var.circleci_org_id}"
}

data "tls_certificate" "circleci" {
  url = local.oidc_url
}

resource "aws_iam_openid_connect_provider" "circleci" {
  url             = local.oidc_url
  client_id_list  = [var.circleci_org_id]
  thumbprint_list = [data.tls_certificate.circleci.certificates[0].sha1_fingerprint]
}

# --- Terraform state bucket ------------------------------------------------
resource "aws_s3_bucket" "tfstate" {
  bucket = "${var.project}-tfstate-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- One deploy role per environment ---------------------------------------
data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.circleci.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = [var.circleci_org_id]
    }
    # Only pipelines from this one CircleCI project may assume the role.
    condition {
      test     = "StringLike"
      variable = "${local.oidc_host}:sub"
      values   = ["org/${var.circleci_org_id}/project/${var.circleci_project_id}/user/*"]
    }
  }
}

resource "aws_iam_role" "deploy" {
  for_each = toset(var.environments)

  name                 = "${var.project}-circleci-${each.key}"
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = 3600
}

# Sandbox-scoped permissions: networking + EC2 + read the AMI parameter
# + this environment's state files. Tighten further for production use.
data "aws_iam_policy_document" "deploy" {
  for_each = toset(var.environments)

  statement {
    sid       = "NetworkAndCompute"
    actions   = ["ec2:*"]
    resources = ["*"]
  }

  statement {
    sid       = "ReadAmiParameter"
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["arn:${data.aws_partition.current.partition}:ssm:*::parameter/aws/service/ami-amazon-linux-latest/*"]
  }

  statement {
    sid       = "StateBucketList"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.tfstate.arn]
  }

  statement {
    sid       = "StateObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.tfstate.arn}/${each.key}/*"]
  }
}

resource "aws_iam_role_policy" "deploy" {
  for_each = toset(var.environments)

  name   = "deploy"
  role   = aws_iam_role.deploy[each.key].id
  policy = data.aws_iam_policy_document.deploy[each.key].json
}

output "tf_state_bucket" {
  value = aws_s3_bucket.tfstate.bucket
}

output "deploy_role_arns" {
  value = { for env, role in aws_iam_role.deploy : env => role.arn }
}
