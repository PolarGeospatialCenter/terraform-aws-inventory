variable "branch" {
  description = "branch to deploy from"
  default     = "master"
}

variable "stack_name" {
  description = "name of CloudFormation stack to create"
  default     = "inventory-api"
}

variable "github_token" {
  description = "GitHub OAuth Token"
  default     = ""
}

variable "cache_bucket_name" {
  description = "The name for the S3 cache bucket. Must not be interpolated"
}
