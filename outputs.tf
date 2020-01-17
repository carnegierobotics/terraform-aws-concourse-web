output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "ALB DNS name"
}

output "nlb_dns_name" {
  value       = module.nlb.nlb_dns_name
  description = "NLB DNS name"
}

output "ecs_task_role_name" {
  value       = module.web.ecs_task_role_name
  description = "Name of the ECS task role"
}

output "ecs_service_security_group_id" {
  description = "Security Group ID of the ECS task"
  value       = module.web.ecs_service_security_group_id
}
