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

resource "aws_security_group" "svc" {
  name        = "${module.platform.name_prefix}-svc"
  description = "Workshop service attached to the existing VPC"
  vpc_id      = module.platform.vpc_id

  tags = merge(module.platform.common_tags, {
    Name = "${module.platform.name_prefix}-svc"
  })
}

resource "aws_vpc_security_group_ingress_rule" "from_app" {
  security_group_id            = aws_security_group.svc.id
  referenced_security_group_id = module.platform.app_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443

  tags = merge(module.platform.common_tags, {
    Name = "${module.platform.name_prefix}-svc-from-app"
  })
}

resource "aws_network_interface" "svc" {
  subnet_id       = module.platform.private_subnet_ids[0]
  security_groups = [aws_security_group.svc.id]

  tags = merge(module.platform.common_tags, {
    Name = "${module.platform.name_prefix}-svc"
  })
}
