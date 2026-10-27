terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }

  # Bucket, key and region are passed at init time by scripts/tf.sh,
  # so one folder serves every environment (no copy per environment).
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

module "network" {
  source = "../../modules/network"

  project            = var.project
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  enable_nat_gateway = var.enable_nat_gateway
  tags               = var.extra_tags
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "app_security_group_id" {
  value = module.network.app_security_group_id
}
