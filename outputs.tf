output "inventory_policy_arns" {
  value = ["${aws_iam_policy.inventory-api-policy.*.arn}"]
}
