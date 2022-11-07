output "vpc_public_subnets" {
  description = "IDs of the VPC's public subnets"
  value       = module.vpc.public_subnets
}

output "ec2_pubblic" {
  description = "subnets"
  value       = module.ec2_instances_public[*].public_ip
}
output "key_pair" {
  description = "private_key BH"
  value       = module.key_pair.private_key_openssh
  sensitive   = true
}

output "server_id1" {
  value = toset(module.ec2_instances_public[*].id)
}

