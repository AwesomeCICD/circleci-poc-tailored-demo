variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "name" {
  description = "Short name for this instance (e.g. app01)."
  type        = string
  default     = "app01"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "subnet_tier" {
  description = "Place the instance in a public or private subnet."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private"], var.subnet_tier)
    error_message = "subnet_tier must be public or private."
  }
}

variable "root_volume_gb" {
  type    = number
  default = 20
}

variable "extra_security_group_ids" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
