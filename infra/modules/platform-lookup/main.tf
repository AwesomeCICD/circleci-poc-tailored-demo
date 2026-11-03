# platform-lookup: the answer to "how does a new module pick up the existing
# VPC, subnets, security groups and tags without cut-and-paste?"
#
# Give it a project + environment. It finds everything the network stack
# created (by tag) and hands back IDs and the standard tag set.
# Any new module calls this once instead of hard-coding IDs.

terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

variable "project" {
  type = string
}

variable "environment" {
  type = string
}

data "aws_vpc" "this" {
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  tags = { Tier = "public" }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  tags = { Tier = "private" }
}

data "aws_security_group" "app" {
  vpc_id = data.aws_vpc.this.id
  tags = {
    Project     = var.project
    Environment = var.environment
    Role        = "app"
  }
}

output "vpc_id" {
  value = data.aws_vpc.this.id
}

output "vpc_cidr" {
  value = data.aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  value = sort(data.aws_subnets.public.ids)
}

output "private_subnet_ids" {
  value = sort(data.aws_subnets.private.ids)
}

output "app_security_group_id" {
  value = data.aws_security_group.app.id
}

# One naming convention for every environment: ocsd-poc-dev, ocsd-poc-prod, and so on.
output "name_prefix" {
  value = "${var.project}-${var.environment}"
}

# The standard tags every new resource should carry.
output "common_tags" {
  value = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform-circleci"
  }
}
