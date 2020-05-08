variable "base_domain" {
    default = "identitysandbox.gov"
    type = string
}

variable "cluster_name" {
  type = string
}

variable "region" {
  default = "us-west-2"
  type    = string
}

variable "oidc_endpoint" {
  type = string
}