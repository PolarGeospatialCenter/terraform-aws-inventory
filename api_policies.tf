resource "aws_iam_policy" "inventory-api-read-policy" {
  name        = "InventoryAPIRead"
  description = "Policy allowing read access to the Inventory API"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "execute-api:Invoke"
            ],
            "Resource": [
                "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*/*/GET/*"
            ]
        }
    ]
}
POLICY
}
