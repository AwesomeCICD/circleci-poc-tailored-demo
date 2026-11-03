# TEMPLATE for bringing an existing OCSD module into the pipeline.
#
# 1. Copy this folder to infra/modules/<your-module-name>.
# 2. Paste your existing module's resources below the lookup.
# 3. Replace any hard-coded VPC / subnet / security group IDs and tags with
#    module.platform.* (examples below). No renaming per environment:
#    the same module deploys to dev, test, stage and prod.
# 4. Add a stack for it under infra/stacks/ (copy infra/stacks/compute).

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

module "platform" {
  source      = "../platform-lookup"
  project     = var.project
  environment = var.environment
}

# --- Example: what "attach to existing" looks like -------------------------
#
# resource "aws_lb" "example" {
#   name               = "${module.platform.name_prefix}-alb"
#   internal           = true
#   load_balancer_type = "application"
#   subnets            = module.platform.private_subnet_ids     # was: ["subnet-0abc...", ...]
#   security_groups    = [module.platform.app_security_group_id] # was: ["sg-0abc..."]
#   tags               = module.platform.common_tags             # was: copy-pasted tag block
# }
# ---------------------------------------------------------------------------
