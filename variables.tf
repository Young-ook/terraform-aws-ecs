### cluster 
variable "type" {
  description = "Instance type for worker node pools (EC2, FARGATE)"
  default     = "EC2"
}

variable "node_type" {
  description = "Instance type of node pools (EC2 cluster only)"
  default     = "m5.large"
}

variable "node_size" {
  description = "The cluster size of node pools (EC2 cluster only)"
  default     = "3"
}

variable "node_vol_size" {
  description = "The disk size of root volume of each node in node pools (EC2 cluster only)"
  default     = "8"
}

variable "node_ssh_port" {
  description = "The ssh port number to be applied when booting (EC2 cluster only)"
  default     = "2089"
}

### services
## required
# name                   task_file
#
## optional('default value')
# scheduling('REPLICA')  desired_count('1')
# cpu('256')             mem('512')
# securitygroups('default')

variable "services" {
  description = "The launch configuration of container and definition of cluster type of ecs"
  default     = []
}

### tags
variable "tags" {
  description = "The key-value maps for tagging"
  type        = "map"
  default     = {}
}

### network
variable "region" {
  description = "The aws region to deploy the service into"
  type        = "string"
}

variable "azs" {
  description = "A list of availability zones for the VPC"
  type        = "list"
}

variable "vpc" {
  description = "The vpc id of this service is being deployed into"
  type        = "string"
}

variable "subnets" {
  description = "A list of the AWS IDs of the Subnets which the Ubuntu server will be deployed into"
  type        = "list"
}

### description
variable "name" {
  description = "The logical name of the module instance"
  default     = "default"
}

variable "stack" {
  description = "Text used to identify stack or environment"
  default     = "default"
}

variable "detail" {
  description = "The extra description of module instance"
  default     = ""
}

variable "slug" {
  description = "A random string to be end of tail of module name"
  default     = ""
}
