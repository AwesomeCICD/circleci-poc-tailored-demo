# prod environment. The only file that differs between environments.
project     = "ocsd-poc"
environment = "prod"
aws_region  = "us-west-2" # Change this to the sandbox region.
vpc_cidr    = "10.13.0.0/16"

instance_type      = "t3.small"
enable_nat_gateway = false

extra_tags = {
  Owner = "ocsd-platform"
}
