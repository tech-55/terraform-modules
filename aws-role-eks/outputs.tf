output "role_arn" {
  value = aws_iam_role.service_account_role.arn
}
output "policy_arn" {
    value = aws_iam_policy.service_account_policy.arn
}