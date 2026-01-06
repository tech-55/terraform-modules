output "role_arn" {
  value = aws_iam_role.service_account_role.arn
}

output "role_name" {
  value = aws_iam_role.service_account_role.name
}

output "policy_arn" {
    value = aws_iam_policy.service_account_policy.arn
}