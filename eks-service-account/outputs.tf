output "role_arn" {
  value = module.create_aws_role_eks.role_arn
}

output "policy_arn" {
    value = module.create_aws_role_eks.policy_arn
}

output "service_account_name" {
    value = module.create_aws_role_eks.service_account_name
}