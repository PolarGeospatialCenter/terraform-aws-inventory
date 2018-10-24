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

variable "api_gateway_names" {
  description = "The name of the api gateway, only add once it exists. "
  default = []
}

variable "dns_name" {
    description = "The dns name of the inventory api"
}

variable "route53_zone_id" {
    description = "The id of the route 53 zone that the inventory api dns record should be created in"
}
