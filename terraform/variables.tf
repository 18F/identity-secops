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


variable "enable_rds_idp_read_replica" {
  description = "Whether to create an RDS read replica of the IDP database"
  default     = false
  # TODO: TF 0.12
  # type = bool
}

variable "rds_backup_retention_period" {
  default = "34"
}

variable "rds_backup_window" {
  default = "08:00-08:34"
}

# Changing engine or engine_version requires also changing any relevant uses of
# aws_db_parameter_group, which has a family attribute that tightly couples its
# parameter to the engine and version.

variable "rds_engine" {
  default = "postgres"
}

variable "rds_engine_version" {
  default = "9.6.15"
}

variable "rds_engine_version_replica" {
  default     = "9.6.15"
  description = "RDS requires that replicas be upgraded *before* primaries"
}

variable "rds_engine_version_short" {
  default = "9.6"
}

variable "rds_instance_class" {
  default = "db.t3.micro"
}

variable "rds_instance_class_replica" {
  default = "db.t3.micro"
}

variable "rds_storage_type_idp" {
  # possible storage types:
  # standard (magnetic)
  # gp2 (general SSD)
  # io1 (provisioned IOPS SSD)
  description = "The type of EBS storage (magnetic, SSD, PIOPS) used by the IdP database"
  default     = "standard"
}

variable "rds_iops_idp" {
  description = "If PIOPS storage is used, the number of IOPS provisioned"

  # Terraform doesn't distinguish between 0 and unset / TODO TF 0.12
  default = 0
}

variable "rds_iops_idp_replica" {
  description = "If PIOPS storage is used, the number of IOPS provisioned for the read replica"

  # Terraform doesn't distinguish between 0 and unset / TODO TF 0.12
  default = 0
}

variable "rds_storage_app" {
  default = "8"
}

variable "rds_storage_idp" {
  default = "8"
}

variable "rds_username" {
  # These are not actually used.  We update them after launching.
  default = "upaya"
}

variable "rds_password" {
  # These are not actually used.  We update them after launching.
  default = "upayaupaya"
}

variable "rds_maintenance_window" {
  default = "Sun:08:34-Sun:09:08"
}

variable "rds_dashboard_idp_vertical_annotations" {
  description = "A raw JSON array of vertical annotations to add to all cloudwatch dashboard widgets"
  default     = "[]"
}

variable "elasticache_redis_node_type" {
  description = "Instance type used for redis elasticache. Changes incur downtime."

  # allowed values: t2.micro-medium, m3.medium-2xlarge, m4|r3|r4.large-
  default = "cache.t3.micro"
}

variable "elasticache_redis_engine_version" {
  description = "Engine version used for redis elasticache. Changes may incur downtime."
  default     = "3.2.10"
}

variable "elasticache_redis_parameter_group_name" {
  default = "default.redis3.2"
}

variable "elasticsearch_volume_size" {
  description = "EBS volume size for elasticsearch hosts"

  # allowed values: 300 - 1000
  default = 300
}
