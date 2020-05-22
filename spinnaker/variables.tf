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

variable "spinnaker_oauth_client_id" {
  type = string
}

variable "spinnaker_oauth_client_secret" {
  type = string
}

variable "spinnaker_oauth_access_token_uri" {
  type = string
}

variable "spinnaker_oauth_user_authorization_uri" {
  type = string
}

variable "spinnaker_oauth_userinfo_uri" {
  type = string
}