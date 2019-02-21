# ecs.tf

### ecs cluster
resource "aws_ecs_cluster" "this" {
  name = "${local.name}"
}

### tasks definition
resource "aws_ecs_task_definition" "this" {
  count                    = "${length(var.services)}"
  requires_compatibilities = ["${var.type}"]
  family                   = "${local.task_name}-${count.index}"
  network_mode             = "awsvpc"
  cpu                      = "${lookup(var.services[count.index], "cpu", "256")}"
  memory                   = "${lookup(var.services[count.index], "mem", "512")}"
  execution_role_arn       = "${aws_iam_role.taskrun.arn}"
  container_definitions    = "${file("${lookup(var.services[count.index], "task_file")}")}"
}

### service definition
resource "aws_ecs_service" "this" {
  count               = "${length(var.services)}"
  name                = "${lookup(var.services[count.index], "name", "${local.task_name}-${count.index}")}"
  cluster             = "${aws_ecs_cluster.this.id}"
  launch_type         = "${var.type}"
  task_definition     = "${element(aws_ecs_task_definition.this.*.arn, count.index)}"
  scheduling_strategy = "${lookup(var.services[count.index], "scheduling", "REPLICA")}"
  desired_count       = "${lookup(var.services[count.index], "desired_count", "1")}"

  network_configuration = {
    subnets         = ["${var.subnets}"]
    security_groups = ["${lookup(var.services[count.index], "security_groups", element(data.aws_security_groups.default.ids, 0))}"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

### task run
resource "aws_iam_role" "taskrun" {
  name               = "${local.name}-taskrun"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.task_trust_rel.json}"
}

data "aws_iam_policy_document" "task_trust_rel" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "ecs-tasks.amazonaws.com",
      ]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "ecs_taskrun" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = "${aws_iam_role.taskrun.id}"
}

### look up default security group
data "aws_security_groups" "default" {
  filter {
    name   = "group-name"
    values = ["default*"]
  }

  filter {
    name   = "vpc-id"
    values = ["${var.vpc}"]
  }
}
