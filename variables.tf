variable "aws_region" {
  description = "AWS Region where the Control Tower API is available."
  type        = string
  default     = "us-east-1"
}

variable "default_tags" {
  description = "Tags applied to resources that support default tags."
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "aws-control-tower-terraform"
  }
}

variable "controls" {
  description = "Control Catalog IDs and OU IDs for controls without parameters."
  type = list(object({
    control_names           = list(string)
    organizational_unit_ids = list(string)
  }))
  default = []
}

variable "controls_with_params" {
  description = "Control Catalog IDs, parameters, and OU IDs for parameterized controls."
  type = list(object({
    control_names = list(map(object({
      parameters = optional(map(list(string)))
    })))
    organizational_unit_ids = list(string)
  }))
  default = []
}