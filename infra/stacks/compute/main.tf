terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(var.extra_tags, {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform-circleci"
    })
  }
}

# Note what is NOT here: no VPC ID, subnet ID or security group ID.
# The module finds the environment's network by tag.
module "app_server" {
  source = "../../modules/ec2-linux"

  project       = var.project
  environment   = var.environment
  name          = "app01"
  instance_type = var.instance_type
  subnet_tier   = "private"
}

output "instance_id" {
  value = module.app_server.instance_id
}

output "private_ip" {
  value = module.app_server.private_ip
}
