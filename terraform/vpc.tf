#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

resource "aws_vpc" "secops" {
  cidr_block = "10.0.0.0/16"

  tags = map(
    "Name", "${var.cluster_name}-vpc",
    "kubernetes.io/cluster/${var.cluster_name}", "shared",
  )
}

resource "aws_subnet" "secops" {
  count = 2

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = aws_vpc.secops.id
  map_public_ip_on_launch = true

  tags = map(
    "Name", "${var.cluster_name}-node",
    "kubernetes.io/cluster/${var.cluster_name}", "shared",
    "kubernetes.io/role/elb", "1",
    "kubernetes.io/role/internal-elb", ""
  )
}

resource "aws_internet_gateway" "secops" {
  vpc_id = aws_vpc.secops.id

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_route_table" "secops" {
  vpc_id = aws_vpc.secops.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secops.id
  }
}

resource "aws_route_table_association" "secops" {
  count = 2

  subnet_id      = aws_subnet.secops.*.id[count.index]
  route_table_id = aws_route_table.secops.id
}

resource "aws_db_subnet_group" "db" {
  description = "${var.cluster_name} db subnet group for login.gov"
  name        = "${var.cluster_name}-db"
  subnet_ids  = [aws_subnet.db1.id, aws_subnet.db2.id]

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_subnet" "db1" {
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = "10.0.250.0/26"
  vpc_id            = aws_vpc.secops.id
  map_public_ip_on_launch = false

  tags = map(
    "Name", "${var.cluster_name}-db1",
  )
}

resource "aws_subnet" "db2" {
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = "10.0.250.64/26"
  vpc_id            = aws_vpc.secops.id
  map_public_ip_on_launch = false

  tags = map(
    "Name", "${var.cluster_name}-db2",
  )
}

resource "aws_elasticache_subnet_group" "redis" {
  description = "${var.cluster_name} redis subnet group for login.gov"
  name        = "${var.cluster_name}-redis"
  subnet_ids  = [aws_subnet.redis1.id, aws_subnet.redis2.id]
}

resource "aws_subnet" "redis1" {
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = "10.0.250.128/26"
  vpc_id            = aws_vpc.secops.id
  map_public_ip_on_launch = false

  tags = map(
    "Name", "${var.cluster_name}-redis1",
  )
}

resource "aws_subnet" "redis2" {
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = "10.0.252.192/26"
  vpc_id            = aws_vpc.secops.id
  map_public_ip_on_launch = false

  tags = map(
    "Name", "${var.cluster_name}-redis2",
  )
}

resource "aws_security_group" "db" {
  description = "Allow inbound and outbound postgresql traffic with app subnets in vpc"

  egress = []

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    security_groups = [aws_eks_cluster.secops.vpc_config[0].cluster_security_group_id]
  }

  name = "${var.cluster_name}-db"

  tags = {
    Name = "${var.cluster_name}-db_security_group"
  }

  vpc_id = aws_vpc.secops.id
}

resource "aws_security_group" "redis" {
  description = "Allow inbound and outbound redis traffic with app subnet in vpc"

  ingress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"
    security_groups = [aws_eks_cluster.secops.vpc_config[0].cluster_security_group_id]
  }

  name = "${var.cluster_name}-redis"

  tags = {
    Name = "${var.cluster_name}-redis"
  }

  vpc_id = aws_vpc.secops.id
}
