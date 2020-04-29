#
# Variables Configuration
#

variable "cluster_name" {
  type    = string
}

variable "region" {
  default = "us-west-2"
  type    = string
}

# networks which are allowed to talk with the k8s API
variable "kubecontrolnets" {
  default = ["98.146.223.15/32", "159.142.0.0/16"]
  type    = list(string)
}
