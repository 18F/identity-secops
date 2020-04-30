resource "aws_route53_zone" "identity-sandbox" {
  name = "identitysandbox.gov"

  lifecycle {
      prevent_destroy = true
  }
}
