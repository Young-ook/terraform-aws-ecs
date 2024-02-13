tags = { example = "ecs_blueprint" }
node_groups = [
  {
    name                   = "default"
    desired_size           = 1
    min_size               = 1
    max_size               = 3
    instance_type          = "m6g.large"
    ami_type               = "AL2_ARM_64"
    termination_protection = false
  }
]
