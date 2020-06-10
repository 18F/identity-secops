resource "aws_vpc" "spinnaker-db" {
  cidr_block                       = "10.16.0.0/16"
  assign_generated_ipv6_cidr_block = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_internet_gateway" "spinnaker" {
  vpc_id = aws_vpc.spinnaker-db.id
}

resource "aws_subnet" "spinnaker-db-a" {
  vpc_id            = aws_vpc.spinnaker-db.id
  cidr_block        = "10.16.1.0/24"
  availability_zone = "${var.region}a"

  map_public_ip_on_launch = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_subnet" "spinnaker-db-b" {
  vpc_id            = aws_vpc.spinnaker-db.id
  cidr_block        = "10.16.2.0/24"
  availability_zone = "${var.region}b"

  map_public_ip_on_launch = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_subnet" "spinnaker-db-c" {
  vpc_id            = aws_vpc.spinnaker-db.id
  cidr_block        = "10.16.3.0/24"
  availability_zone = "${var.region}c"

  map_public_ip_on_launch = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_default_route_table" "spinnaker" {
  default_route_table_id = aws_vpc.spinnaker-db.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.spinnaker.id
  }
}

resource "aws_route_table_association" "spinnaker-db-a" {
  subnet_id      = aws_subnet.spinnaker-db-a.id
  route_table_id = aws_default_route_table.spinnaker.id
}

resource "aws_route_table_association" "spinnaker-db-b" {
  subnet_id      = aws_subnet.spinnaker-db-b.id
  route_table_id = aws_default_route_table.spinnaker.id
}

resource "aws_route_table_association" "spinnaker-db-c" {
  subnet_id      = aws_subnet.spinnaker-db-c.id
  route_table_id = aws_default_route_table.spinnaker.id
}

/*
See the README to understand why these are commented out.
*/
# see: https://www.terraform.io/docs/providers/external/data_source.html
# todo (mxplusb): implement the aws_ip_ranges data source.
data "external" "personal-ip" {
  program = ["curl", "https://ipecho.io/json"]
}

data "external" "amazon-ranges" {
  program = [
    "python3",
    "${path.cwd}/aws-ranges.py"
  ]
}

resource "aws_default_security_group" "allow-local-mysql" {
  vpc_id = aws_vpc.spinnaker-db.id

  ingress {
    description = "MySQL"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = flatten([
      "${data.external.personal-ip.result.ip}/32",
      keys(data.external.amazon-ranges.result)
    ])
  }
}

resource "aws_db_subnet_group" "spinnaker" {
  name       = "spinnaker-db"
  subnet_ids = ["${aws_subnet.spinnaker-db-a.id}", "${aws_subnet.spinnaker-db-b.id}", "${aws_subnet.spinnaker-db-c.id}"]

  depends_on = [
    aws_subnet.spinnaker-db-a,
    aws_subnet.spinnaker-db-b,
    aws_subnet.spinnaker-db-c
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_rds_cluster_parameter_group" "spinnaker" {
  name   = "spinnaker"
  family = "aurora-mysql5.7"

  parameter {
    name  = "tx_isolation"
    value = "READ-COMMITTED"
  }
}

resource "aws_db_parameter_group" "spinnaker" {
  name   = "spinnaker-db"
  family = "aurora-mysql5.7"

  parameter {
    name  = "tx_isolation"
    value = "READ-COMMITTED"
  }
}

resource "aws_rds_cluster" "spinnaker" {
  cluster_identifier = "spinnaker-db-dev"
  availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]
  database_name      = "empty"

  backup_retention_period = 5
  deletion_protection     = false
  storage_encrypted       = true
  skip_final_snapshot     = true
  apply_immediately       = false

  engine                          = "aurora-mysql"
  engine_version                  = "5.7.12"
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.spinnaker.id

  /*
  # enable this when mysql 5.7 is supported for serverless

  engine_mode    = "serverless"
  enable_http_endpoint = true
  scaling_configuration {
    auto_pause               = true
    max_capacity             = 8
    min_capacity             = 1
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }
  */

  master_username = "login"
  master_password = "Login123!" # just a placeholder.

  db_subnet_group_name   = aws_db_subnet_group.spinnaker.id
  vpc_security_group_ids = [aws_default_security_group.allow-local-mysql.id]

  #   lifecycle {
  #     prevent_destroy = true
  #   }
}

resource "aws_rds_cluster_instance" "spinnaker-db" {
  count                   = 2
  identifier              = "spinnaker-db-dev-${count.index}"
  cluster_identifier      = aws_rds_cluster.spinnaker.id
  instance_class          = "db.t3.medium"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.12"
  db_parameter_group_name = aws_db_parameter_group.spinnaker.id

  publicly_accessible = true

  depends_on = [
    aws_rds_cluster.spinnaker
  ]
}
