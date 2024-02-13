# Variables for providing to module fixture codes

### network
variable "aws_region" {
  description = "The aws region to deploy"
  type        = string
  default     = "ap-northeast-2"
}

variable "azs" {
  description = "A list of availability zones for the vpc to deploy resources"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c", "ap-northeast-2d"]
}

### ecs cluster
variable "node_groups" {
  description = "Node groups definition"
  default     = []
}

### container
variable "tasks" {
  description = "Container tasks definition"
  default     = []
}

### feature
variable "enable_container_insights" {
  description = "Enable container insights monitoring"
  type        = bool
  default     = true
}

### description
variable "name" {
  description = "An example name"
  type        = string
  default     = null
}

### tags
variable "tags" {
  description = "The key-value maps for tagging"
  type        = map(string)
  default     = {}
}
