variable "project" {
  description = "Project name used in names and tags (e.g. ocsd-poc)."
  type        = string
}

variable "environment" {
  description = "Environment name: dev, test, stage or prod."
  type        = string

  validation {
    condition     = contains(["dev", "test", "stage", "prod"], var.environment)
    error_message = "environment must be one of dev, test, stage, prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Use a different range per environment."
  type        = string
}

variable "az_count" {
  description = "How many availability zones to spread subnets across."
  type        = number
  default     = 2
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway so private subnets can reach the internet (adds cost)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Extra tags applied to every resource (e.g. cost center, owner)."
  type        = map(string)
  default     = {}
}
