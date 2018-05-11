variable "branch" {
  description = "branch to deploy from"
  default     = "master"
}

variable "stack_name" {
  description = "name of CloudFormation stack to create"
  default     = "inventory-api"
}
