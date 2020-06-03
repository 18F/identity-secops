# create idp resources here:  postgres, redis, kms

resource "aws_db_instance" "idp" {
  allocated_storage       = var.rds_storage_idp
  apply_immediately       = true
  backup_retention_period = var.rds_backup_retention_period
  backup_window           = var.rds_backup_window
  db_subnet_group_name    = aws_db_subnet_group.db.id
  engine                  = var.rds_engine
  engine_version          = var.rds_engine_version
  identifier              = "${var.cluster_name}-idp"
  instance_class          = var.rds_instance_class
  maintenance_window      = var.rds_maintenance_window
  multi_az                = true
  parameter_group_name    = aws_db_parameter_group.force_ssl.name
  password                = var.rds_password # change this by hand after creation
  storage_encrypted       = true
  username                = var.rds_username
  storage_type            = var.rds_storage_type_idp
  iops                    = var.rds_iops_idp

  # we want to push these via Terraform now
  allow_major_version_upgrade = true

  tags = {
    Name = "${var.cluster_name}"
  }

  vpc_security_group_ids = [aws_security_group.db.id]

  # send logs to cloudwatch
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # If you want to destroy your database, you need to do this in two phases:
  # 1. Uncomment `skip_final_snapshot=true` and
  #    comment `prevent_destroy=true` and `deletion_protection = true` below.
  # 2. Perform a terraform/deploy "apply" with the additional
  #    argument of "-target=aws_db_instance.idp" to mark the database
  #    as not requiring a final snapshot.
  # 3. Perform a terraform/deploy "destroy" as needed.
  #
  #skip_final_snapshot = true
  lifecycle {
    prevent_destroy = true

    # we set the password by hand so it doesn't end up in the state file
    ignore_changes = [password]
  }

  deletion_protection = true
}


resource "aws_db_parameter_group" "force_ssl" {
  name_prefix = "${var.cluster_name}-idp-${var.rds_engine}${replace(var.rds_engine_version_short, ".", "")}-"

  # Before changing this value, make sure the parameters are correct for the
  # version you are upgrading to.  See
  # http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html.
  family = "${var.rds_engine}${var.rds_engine_version_short}"

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

  # Setting to 30 minutes, RDS requires value in ms
  # https://aws.amazon.com/blogs/database/best-practices-for-amazon-rds-postgresql-replication/
  parameter {
    name  = "max_standby_archive_delay"
    value = "1800000"
  }

  # Setting to 30 minutes, RDS requires value in ms
  # https://aws.amazon.com/blogs/database/best-practices-for-amazon-rds-postgresql-replication/
  parameter {
    name  = "max_standby_streaming_delay"
    value = "1800000"
  }

  # Log all Data Definition Layer changes (ALTER, CREATE, etc.)
  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  # Log all slow queries that take longer than specified time in ms
  parameter {
    name  = "log_min_duration_statement"
    value = "250" # 250 ms
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Multi-AZ redis cluster, used for session storage
resource "aws_elasticache_replication_group" "idp" {
  replication_group_id          = "${var.cluster_name}-idp"
  replication_group_description = "Multi AZ redis cluster for the IdP in ${var.cluster_name}"
  engine                        = "redis"
  engine_version                = var.elasticache_redis_engine_version
  node_type                     = var.elasticache_redis_node_type
  number_cache_clusters         = 2
  parameter_group_name          = var.elasticache_redis_parameter_group_name
  security_group_ids            = [aws_security_group.redis.id]
  subnet_group_name             = aws_elasticache_subnet_group.redis.name
  port                          = 6379

  # note that t2.* instances don't support automatic failover
  automatic_failover_enabled = true
}
