resource "aws_route53_zone" "identity-sandbox" {
  name = "identitysandbox.gov"
}

resource "aws_route53_zone" "v2" {
  name = "v2.identitysandbox.gov"
}

resource "aws_route53_record" "v2-ns" {
  zone_id = "${aws_route53_zone.identity-sandbox.zone_id}"
  name    = "v2.identitysandbox.gov"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.v2.name_servers.0}",
    "${aws_route53_zone.v2.name_servers.1}",
    "${aws_route53_zone.v2.name_servers.2}",
    "${aws_route53_zone.v2.name_servers.3}",
  ]
}

resource "aws_route53_zone" "nested" {
  name = "${var.cluster_name}.v2.identitysandbox.gov"
}

resource "aws_route53_record" "nested-ns" {
  zone_id = "${aws_route53_zone.identity-sandbox.zone_id}"
  name    = "${var.cluster_name}.v2.identitysandbox.gov"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.nested.name_servers.0}",
    "${aws_route53_zone.nested.name_servers.1}",
    "${aws_route53_zone.nested.name_servers.2}",
    "${aws_route53_zone.nested.name_servers.3}",
  ]
}

resource "aws_route53_record" "ci" {
  name    = "${aws_acm_certificate.ci.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.ci.domain_validation_options.0.resource_record_type}"
  zone_id = "${aws_route53_zone.nested.zone_id}"
  records = ["${aws_acm_certificate.ci.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}
