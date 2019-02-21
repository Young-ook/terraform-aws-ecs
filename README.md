# AWS ECS

## Using module
You can use this module like as below example.

### EC2 based cluster
This is an exmaple to show how to create a ecs cluster using ec2 autoscaling group.
```
module "your_ecs" {
  source  = "youngookkim/ecs/aws"
  version = "1.0.0"

  name          = "exmple"
  stack         = "dev"
  detail        = "extra-desc"
  region        = "${var.aws_region}"
  vpc           = "${var.vpc_id}"
  azs           = "${var.azs}"
  subnets       = "${var.subnet_ids}"
  tags          = "${map("env", var.stack_name)}"
  type          = "EC2"
  node_type     = "m5.large"
  node_size     = "3"
  node_vol_size = "256"

  services = "${list(
    map("name", "test-ecs-nginx", "task_file", "${path.cwd}/tasks/nginx.json"),
  )}"
}
```

### Fargate cluster
This is an example to show how to create a fargate cluster and deploy two service.

```
module "your_fgt" {
  source  = "youngookkim/ecs/aws"
  version = "1.0.0"

  name        = "exmple"
  stack       = "dev"
  detail      = "extra-desc"
  region      = "${var.aws_region}"
  vpc         = "${var.vpc_id}"
  azs         = "${var.azs}"
  subnets     = "${var.subnet_ids}"
  tags        = "${map("env", var.stack_name)}"
  type        = "FARGATE"
}
```
