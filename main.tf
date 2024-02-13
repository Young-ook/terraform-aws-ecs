## features
locals {
  node_groups_enabled = (var.node_groups != null ? ((length(var.node_groups) > 0) ? true : false) : false)
  tasks_enabled       = (var.tasks != null ? ((length(var.tasks) > 0) ? true : false) : false)
}

### cluster
resource "aws_ecs_cluster" "cp" {
  name = local.name
  tags = merge(local.default-tags, var.tags)

  dynamic "setting" {
    for_each = {
      containerInsights = var.container_insights_enabled ? "enabled" : "disabled"
    }
    content {
      name  = setting.key
      value = setting.value
    }
  }

  depends_on = [
    aws_ecs_capacity_provider.ng,
  ]
}

### security/policy
resource "aws_iam_role" "ng" {
  for_each = local.node_groups_enabled ? toset(["enabled"]) : []
  name     = join("-", [local.name, "ng"])
  tags     = merge(local.default-tags, var.tags)
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [format("ec2.%s", local.aws.dns)]
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_instance_profile" "ng" {
  for_each = local.node_groups_enabled ? toset(["enabled"]) : []
  name     = format("%s-ng", local.name)
  role     = aws_iam_role.ng["enabled"].name
}

resource "aws_iam_role_policy_attachment" "ecs-ng" {
  for_each   = local.node_groups_enabled ? toset(["enabled"]) : []
  policy_arn = format("arn:%s:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role", local.aws.partition)
  role       = aws_iam_role.ng["enabled"].name
}

resource "aws_iam_role_policy_attachment" "ecr-read" {
  for_each   = local.node_groups_enabled ? toset(["enabled"]) : []
  policy_arn = format("arn:%s:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", local.aws.partition)
  role       = aws_iam_role.ng["enabled"].name
}

### ecs-optimized linux
data "aws_ami" "ecs" {
  for_each    = { for ng in var.node_groups : ng.name => ng if local.node_groups_enabled }
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*"]
  }
  filter {
    name   = "architecture"
    values = [length(regexall("ARM", lookup(each.value, "ami_type", "AL2_x86_64"))) > 0 ? "arm64" : "x86_64"]
  }
}

data "cloudinit_config" "ng" {
  for_each      = { for ng in var.node_groups : ng.name => ng if local.node_groups_enabled }
  base64_encode = true
  gzip          = false

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOT
    #!/bin/bash -v
    echo ECS_CLUSTER=${local.name} >> /etc/ecs/ecs.config
    start ecs
    EOT
  }
}

resource "aws_launch_template" "ng" {
  for_each      = { for ng in var.node_groups : ng.name => ng if local.node_groups_enabled }
  name          = format("ecs-%s", uuid())
  tags          = merge(local.default-tags, var.tags)
  image_id      = data.aws_ami.ecs[each.key].id
  user_data     = data.cloudinit_config.ng[each.key].rendered
  instance_type = lookup(each.value, "instance_type", local.default_ecs.instance_type)

  iam_instance_profile {
    arn = aws_iam_instance_profile.ng["enabled"].arn
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = lookup(each.value, "volume_size", local.default_ecs.volume_size)
      volume_type           = lookup(each.value, "volume_type", local.default_ecs.volume_type)
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.default-tags, var.tags)
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
}

resource "aws_autoscaling_group" "ng" {
  for_each              = { for ng in var.node_groups : ng.name => ng if local.node_groups_enabled }
  name                  = format("ecs-%s", uuid())
  vpc_zone_identifier   = var.subnets
  max_size              = lookup(each.value, "max_size", local.default_ecs.max_size)
  min_size              = lookup(each.value, "min_size", local.default_ecs.min_size)
  desired_capacity      = lookup(each.value, "desired_size", local.default_ecs.desired_size)
  force_delete          = lookup(each.value, "force_delete", local.default_ecs.force_delete)
  protect_from_scale_in = lookup(each.value, "termination_protection", local.default_ecs.termination_protection)
  termination_policies  = ["Default"]
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ng[each.key].id
        version            = aws_launch_template.ng[each.key].latest_version
      }

      dynamic "override" {
        for_each = lookup(each.value, "launch_override", [])
        content {
          instance_type     = lookup(override.value, "instance_type", null)
          weighted_capacity = lookup(override.value, "weighted_capacity", null)
        }
      }
    }

    dynamic "instances_distribution" {
      for_each = { for key, val in each.value : key => val if key == "instances_distribution" }
      content {
        on_demand_allocation_strategy            = lookup(instances_distribution.value, "on_demand_allocation_strategy", null)
        on_demand_base_capacity                  = lookup(instances_distribution.value, "on_demand_base_capacity", null)
        on_demand_percentage_above_base_capacity = lookup(instances_distribution.value, "on_demand_percentage_above_base_capacity", null)
        spot_allocation_strategy                 = lookup(instances_distribution.value, "spot_allocation_strategy", null)
        spot_instance_pools                      = lookup(instances_distribution.value, "spot_instance_pools", null)
        spot_max_price                           = lookup(instances_distribution.value, "spot_max_price", null)
      }
    }
  }

  dynamic "tag" {
    for_each = local.ecs-tag
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity, name]
  }

  depends_on = [
    aws_iam_role.ng,
    aws_iam_role_policy_attachment.ecs-ng,
    aws_iam_role_policy_attachment.ecr-read,
    aws_launch_template.ng,
  ]
}

#### cluster/capacity
resource "aws_ecs_capacity_provider" "ng" {
  for_each = { for ng in var.node_groups : ng.name => ng if local.node_groups_enabled }
  name     = each.key
  tags     = merge(local.default-tags, var.tags)

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ng[each.key].arn
    managed_termination_protection = lookup(each.value, "termination_protection", false) ? "ENABLED" : "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = lookup(each.value, "max_scaling_step_size", null)
      minimum_scaling_step_size = lookup(each.value, "min_scaling_step_size", null)
      status                    = "ENABLED"
      target_capacity           = lookup(each.value, "target_capacity", 100)
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "ng" {
  cluster_name       = aws_ecs_cluster.cp.name
  capacity_providers = local.node_groups_enabled ? keys(aws_ecs_capacity_provider.ng) : ["FARGATE"]
}

### security/policy
resource "aws_iam_role" "task" {
  for_each = local.tasks_enabled ? toset(["enabled"]) : []
  name     = join("-", [local.name, "task"])
  tags     = merge(local.default-tags, var.tags)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [format("ecs-tasks.%s", local.aws.dns)]
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs-task" {
  for_each   = local.tasks_enabled ? toset(["enabled"]) : []
  policy_arn = format("arn:%s:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy", local.aws.partition)
  role       = aws_iam_role.task["enabled"].name
}

#### cluster/task
resource "aws_ecs_service" "svc" {
  for_each            = { for t in var.tasks : t.name => t if local.tasks_enabled }
  name                = each.key
  tags                = merge(local.default-tags, var.tags)
  cluster             = aws_ecs_cluster.cp.id
  launch_type         = lookup(each.value, "launch_type", local.default_task.launch_type)
  task_definition     = aws_ecs_task_definition.task[each.key].arn
  scheduling_strategy = lookup(each.value, "scheduling", local.default_task.scheduling_strategy)
  desired_count       = lookup(each.value, "desired_count", local.default_task.desired_count)

  network_configuration {
    security_groups = lookup(each.value, "security_groups", null)
    subnets         = var.subnets
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_task_definition" "task" {
  for_each                 = { for t in var.tasks : t.name => t if local.tasks_enabled }
  tags                     = merge(local.default-tags, var.tags)
  requires_compatibilities = lookup(each.value, "type", local.default_task.compatibilities)
  family                   = lookup(each.value, "family", each.key)
  network_mode             = "awsvpc"
  cpu                      = lookup(each.value, "cpu", local.default_task.cpu)
  memory                   = lookup(each.value, "memory", local.default_task.memory)
  execution_role_arn       = aws_iam_role.task["enabled"].arn
  container_definitions    = jsonencode(lookup(each.value, "container_definitions"))
}
