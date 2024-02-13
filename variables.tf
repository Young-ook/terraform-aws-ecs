### network
variable "subnets" {
  description = "The list of subnet IDs to deploy your ECS cluster"
  type        = list(string)
  validation {
    error_message = "Subnet list must not be null."
    condition     = var.subnets != null
  }
}

### ecs cluster
variable "node_groups" {
  description = "Node groups definition"
  default     = []
}

variable "tasks" {
  description = "Containers definition"
  default     = []
}

### feature
variable "container_insights_enabled" {
  description = "A boolean variable indicating to enable ContainerInsights"
  type        = bool
  default     = false
}

### description
variable "name" {
  description = "The logical name of the module instance"
  type        = string
  default     = null
}

### tags
variable "tags" {
  description = "The key-value maps for tagging"
  type        = map(string)
  default     = {}
}
