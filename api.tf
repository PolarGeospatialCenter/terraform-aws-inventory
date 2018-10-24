data "aws_api_gateway_rest_api" "api_gateway_name" {
  count = "${length(var.api_gateway_names)}"
  name = "${var.api_gateway_names[count.index]}"
}

data "aws_route53_zone" "zone" {
  zone_id = "${var.route53_zone_id}"
}

locals {
  api_gateway_ids = ["${data.aws_api_gateway_rest_api.api_gateway_name.*.id}"]
  api_gateway_fqdn = "${var.dns_name}.${replace(data.aws_route53_zone.zone.name, "/[.]$/", "")}"
}

resource "aws_iam_policy" "inventory-api-policy" {
  count = "${length(local.api_gateway_ids)}"
  name        = "InventoryAPIPolicy"
  description = "Policy allowing read and post access to the Inventory API"

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
                "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.api_gateway_ids[count.index]}/v0/GET/*",
                "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.api_gateway_ids[count.index]}/v0/POST/*"
            ]
        }
    ]
}
POLICY
}

// Create Certificate for api gateway
resource "aws_acm_certificate" "inventory" {
  domain_name       = "${local.api_gateway_fqdn}"

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "inventory_cert_validation" {
  name    = "${aws_acm_certificate.inventory.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.inventory.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.route53_zone_id}"
  records = ["${aws_acm_certificate.inventory.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "inventory" {
  certificate_arn         = "${aws_acm_certificate.inventory.arn}"
  validation_record_fqdns = ["${aws_route53_record.inventory_cert_validation.fqdn}"]
}

resource "aws_api_gateway_domain_name" "inventory" {
  depends_on = ["aws_acm_certificate_validation.inventory"]
  count = "${length(local.api_gateway_ids)}"
  domain_name = "${local.api_gateway_fqdn}"
  regional_certificate_arn = "${aws_acm_certificate.inventory.arn}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

#TODO: ADD PATH MAPPING

// Route53 Setup
resource "aws_route53_record" "inventory" {
  count = "${length(local.api_gateway_ids)}"
  zone_id = "${var.route53_zone_id}"
  name    = "${var.dns_name}"
  type    = "A"

  alias {
    name                   = "${aws_api_gateway_domain_name.inventory.0.regional_domain_name}"
    zone_id                = "${aws_api_gateway_domain_name.inventory.0.regional_zone_id}"
    evaluate_target_health = true
  }
}
