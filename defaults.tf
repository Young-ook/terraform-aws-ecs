### default values

### aws partitions
module "aws" {
  source = "Young-ook/spinnaker/aws//modules/aws-partitions"
}

locals {
  aws = {
    dns       = module.aws.partition.dns_suffix
    partition = module.aws.partition.partition
    region    = module.aws.region.name
  }
}

locals {
  default_ecs = {
    instance_type          = "t3.medium"
    volume_size            = "30"
    volume_type            = "gp3"
    desired_size           = 1
    min_size               = 1
    max_size               = 3
    force_delete           = true
    termination_protection = false
  }
  default_task = {
    launch_type         = "FARGATE"
    compatibilities     = ["EC2", "FARGATE"]
    scheduling_strategy = "REPLICA"
    security_groups     = []
    desired_count       = 1
    cpu                 = 256
    memory              = 512
  }
}
