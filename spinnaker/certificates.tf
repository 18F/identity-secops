resource "aws_acm_certificate" "ci" {
  domain_name       = "ci.${var.cluster_name}.v2.${var.base_domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
    prevent_destroy = false
  }

  options {
      certificate_transparency_logging_preference = "ENABLED"
  }
}

resource "aws_acm_certificate_validation" "ci" {
  certificate_arn         = aws_acm_certificate.ci.arn
  validation_record_fqdns = [aws_route53_record.ci.fqdn]
}

resource "aws_acm_certificate" "gate" {
  domain_name       = "gate.${var.cluster_name}.v2.${var.base_domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
    prevent_destroy = false
  }

  options {
      certificate_transparency_logging_preference = "ENABLED"
  }
}

resource "aws_acm_certificate_validation" "gate" {
  certificate_arn         = aws_acm_certificate.gate.arn
  validation_record_fqdns = [aws_route53_record.gate.fqdn]
}
