#
# Provider Configuration
#

provider "aws" {
  region  = "us-west-2"
  version = ">= 2.38.0"
}

# Using these data sources allows the configuration to be
# generic for any region.
data "aws_region" "current" {}

data "aws_availability_zones" "available" {}
