### frigga naming rule
resource "random_string" "this" {
  length  = 4
  upper   = false
  lower   = true
  number  = false
  special = false
}

### frigga naming rule
locals {
  name           = "${join("-", compact(list(var.name, var.stack, var.detail, local.slug)))}"
  slug           = "${var.slug == "" ? random_string.this.result : var.slug}"
  cluster_name   = "${local.name}"
  cluster_id     = "${local.name}"
  task_name      = "${local.name}-task"
  node_pool_name = "${local.name}-node-pool"
}
