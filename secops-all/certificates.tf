resource "aws_acm_certificate" "ci" {
  domain_name       = "ci.${var.cluster_name}.v2.identitysandbox.gov"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  options {
      certificate_transparency_logging_preference = "ENABLED"
  }
}

resource "aws_acm_certificate_validation" "ci" {
  certificate_arn         = "${aws_acm_certificate.ci.arn}"
  validation_record_fqdns = ["${aws_route53_record.ci.fqdn}"]
}
