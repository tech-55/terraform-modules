output "service_account_aws_iam_role_arn" {
  value = aws_iam_role.service_account_role.arn
}
output "service_account_aws_iam_policy_arn" {
    value = aws_iam_policy.service_account_policy.arn
}

output "service_account_name" {
  value = var.service_account_name
}

output "namespace" {
  value = var.namespace
}