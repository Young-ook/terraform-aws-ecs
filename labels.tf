### frigga name
module "frigga" {
  source  = "Young-ook/spinnaker/aws//modules/frigga"
  version = "3.0.0"
  name    = var.name == null || var.name == "" ? "ecs" : var.name
  petname = var.name == null || var.name == "" ? true : false
}

locals {
  name = module.frigga.name
  default-tags = merge(
    { "terraform.io" = "managed" },
    { "Name" = local.name },
  )
  ecs-tag = merge(
    { "ecs:cluster-name" = local.name },
    { "AmazonECSManaged" = "true" },
  )
}
