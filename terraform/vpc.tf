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
