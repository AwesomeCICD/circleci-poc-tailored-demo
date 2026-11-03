# Same variable set in every stack so one tfvars file per environment
# (infra/environments/<env>.tfvars) drives all of them.

variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "enable_nat_gateway" {
  type    = bool
  default = false
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}
