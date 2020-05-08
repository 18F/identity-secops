# base domain ref. this will need to be imported with `terraform import before the deploy`
resource "aws_route53_zone" "dns" {
  name = var.base_domain

  lifecycle {
      prevent_destroy = true
  }
}

# base v2 infrastructure zone, mostly used to prevent collisions.
resource "aws_route53_zone" "v2" {
  name = "v2.${var.base_domain}"

  lifecycle {
      prevent_destroy = false
  }
}

# ns records for nested resolution.
resource "aws_route53_record" "v2-ns" {
  zone_id = aws_route53_zone.dns.zone_id
  name    = "v2.${var.base_domain}"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.v2.name_servers.0}",
    "${aws_route53_zone.v2.name_servers.1}",
    "${aws_route53_zone.v2.name_servers.2}",
    "${aws_route53_zone.v2.name_servers.3}",
  ]
}

# the per-env zone.
resource "aws_route53_zone" "nested" {
  name = "${var.cluster_name}.v2.${var.base_domain}"

  lifecycle {
      prevent_destroy = false
  }
}

# per-env NS records.
resource "aws_route53_record" "nested-ns" {
  zone_id = aws_route53_zone.dns.zone_id
  name    = "${var.cluster_name}.v2.${var.base_domain}"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.nested.name_servers.0}",
    "${aws_route53_zone.nested.name_servers.1}",
    "${aws_route53_zone.nested.name_servers.2}",
    "${aws_route53_zone.nested.name_servers.3}",
  ]
}

# ns records for nested resolution.
resource "aws_route53_record" "v2-nested-ns" {
  zone_id = aws_route53_zone.v2.zone_id
  name    = "${var.cluster_name}.v2.${var.base_domain}"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.v2.name_servers.0}",
    "${aws_route53_zone.v2.name_servers.1}",
    "${aws_route53_zone.v2.name_servers.2}",
    "${aws_route53_zone.v2.name_servers.3}",
  ]
}

# spinnaker deck
resource "aws_route53_record" "ci" {
  name    = aws_acm_certificate.ci.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.ci.domain_validation_options.0.resource_record_type
  zone_id = aws_route53_zone.nested.zone_id
  records = ["${aws_acm_certificate.ci.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

# spinnaker auth.
resource "aws_route53_record" "gate" {
  name    = aws_acm_certificate.gate.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.gate.domain_validation_options.0.resource_record_type
  zone_id = aws_route53_zone.nested.zone_id
  records = ["${aws_acm_certificate.gate.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}
