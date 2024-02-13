### output values

output "cluster" {
  description = "The generated AWS ECS cluster"
  value       = module.ecs.cluster
}

output "features" {
  description = "Features configurations of the AWS ECS cluster"
  value       = module.ecs.features
}
