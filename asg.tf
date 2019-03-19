# Container cluster for microservice

### container optimized cluster
data "aws_ami" "ecs_ami" {
  count       = "${var.type == "EC2" ? 1 : 0}"
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

### register cluster id
data "template_file" "cluster_userdata" {
  count    = "${var.type == "EC2" ? 1 : 0}"
  template = "${file("${path.module}/res/cluster.tpl")}"

  vars {
    ssh_port    = "${var.node_ssh_port}"
    ecs_cluster = "${aws_ecs_cluster.this.id}"
  }
}

### Launch configuration
resource "aws_launch_configuration" "node_pool" {
  count                = "${var.type == "EC2" ? 1 : 0}"
  image_id             = "${data.aws_ami.ecs_ami.id}"
  instance_type        = "${var.node_type}"
  name_prefix          = "${local.node_pool_name}-"
  user_data            = "${data.template_file.cluster_userdata.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.node_pool.name}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.node_vol_size}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

### Auto scaling group
resource "aws_autoscaling_group" "node_pool" {
  count                = "${var.type == "EC2" ? 1 : 0}"
  name                 = "${local.node_pool_name}"
  max_size             = "${var.node_size}"
  min_size             = "${var.node_size}"
  desired_capacity     = "${var.node_size}"
  vpc_zone_identifier  = ["${var.subnets}"]
  availability_zones   = ["${var.azs}"]
  launch_configuration = "${aws_launch_configuration.node_pool.name}"
  force_delete         = true
  termination_policies = ["Default"]

  lifecycle {
    create_before_destroy = true
  }

  tags = ["${concat(list(
    map("key", "Name", "value", "${local.node_pool_name}", "propagate_at_launch", "true"),
  ))}"]
}

# node pools policy/role 
resource "aws_iam_role" "node_pool" {
  name               = "${local.cluster_name}"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.cluster_trust_rel.json}"
}

data "aws_iam_policy_document" "cluster_trust_rel" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com",
      ]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "ecs_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = "${aws_iam_role.node_pool.id}"
}

# instance profiles
resource "aws_iam_instance_profile" "node_pool" {
  name = "${local.cluster_name}"
  role = "${aws_iam_role.node_pool.name}"
}
