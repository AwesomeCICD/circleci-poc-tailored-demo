# EC2 Linux instance that attaches itself to the existing environment.
# No VPC, subnet or security group IDs are passed in: platform-lookup finds them.

terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

module "platform" {
  source      = "../platform-lookup"
  project     = var.project
  environment = var.environment
}

# Latest Amazon Linux 2023 AMI from the public SSM parameter (no hard-coded AMI IDs).
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  subnet_ids = var.subnet_tier == "public" ? module.platform.public_subnet_ids : module.platform.private_subnet_ids
}

resource "aws_instance" "this" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  subnet_id              = local.subnet_ids[0]
  vpc_security_group_ids = concat([module.platform.app_security_group_id], var.extra_security_group_ids)

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = var.root_volume_gb
  }

  tags = merge(module.platform.common_tags, var.tags, {
    Name = "${var.project}-${var.environment}-${var.name}"
  })
}
