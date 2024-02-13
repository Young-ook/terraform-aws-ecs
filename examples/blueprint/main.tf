### ECS Blueprint

terraform {
  required_version = "~> 1.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

### vpc
module "vpc" {
  source  = "Young-ook/vpc/aws"
  version = "1.0.7"
  name    = var.name
  tags    = var.tags
  vpc_config = {
    azs         = var.azs
    cidr        = "10.10.0.0/16"
    subnet_type = "private"
    single_ngw  = true
  }

  # Amazon ECS tasks using the Fargate launch type and platform version 1.3.0 or earlier only require
  # the com.amazonaws.region.ecr.dkr Amazon ECR VPC endpoint and the Amazon S3 gateway endpoints.
  #
  # Amazon ECS tasks using the Fargate launch type and platform version 1.4.0 or later require both
  # the com.amazonaws.region.ecr.dkr and com.amazonaws.region.ecr.api Amazon ECR VPC endpoints and
  # the Amazon S3 gateway endpoints.
  #
  # For more details, please visit the https://docs.aws.amazon.com/AmazonECR/latest/userguide/vpc-endpoints.html
  vpce_config = [
    {
      service             = "ecr.dkr"
      type                = "Interface"
      private_dns_enabled = false
    },
    {
      service             = "ecr.api"
      type                = "Interface"
      private_dns_enabled = true
    },
  ]
}

module "ecs" {
  source                     = "../.."
  tags                       = { node_type = "ec2/fargate" }
  subnets                    = slice(values(module.vpc.subnets["private"]), 0, 3)
  container_insights_enabled = true
  node_groups                = var.node_groups
  tasks = [
    {
      name        = "service_on_fargate"
      launch_type = "FARGATE"
      container_definitions = [
        {
          name      = "nginx"
          image     = "nginx:latest"
          cpu       = 256
          memory    = 256
          essential = true
          portMappings = [
            {
              containerPort = 80
              protocol      = "tcp"
            }
          ]
          logConfiguration = {
            logDriver = "awslogs"
            options = {
              awslogs-group         = "awslogs-nginx-ecs"
              awslogs-region        = "${var.aws_region}"
              awslogs-stream-prefix = "ecs"
            }
          }
        },
      ]
    },
    {
      name        = "service_on_ec2"
      launch_type = "EC2"
      family      = "nginx_stack"
      cpu         = 1024
      memory      = 2048
      container_definitions = [
        {
          name      = "nginx"
          image     = "nginx:latest"
          cpu       = 128
          memory    = 128
          essential = true
          portMappings = [
            {
              containerPort = 80
              protocol      = "tcp"
            }
          ]
        },
        {
          name      = "nginx-prometheus-exporter"
          image     = "docker.io/nginx/nginx-prometheus-exporter:0.8.0"
          memory    = 128
          cpu       = 256
          essential = true
          command = [
            "-nginx.scrape-uri",
            "http://nginx:8080/stub_status"
          ]
          portMappings = [
            {
              containerPort = 9113
              protocol      = "tcp"
            }
          ]
        }
      ]
    },
  ]
}
