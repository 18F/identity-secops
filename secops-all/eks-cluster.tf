#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#
resource "aws_eks_cluster" "secops" {
  name     = var.cluster_name
  role_arn = aws_iam_role.secops-cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.secops-cluster.id]
    subnet_ids         = aws_subnet.secops[*].id
  }

  lifecycle {
    #prevent_destroy = true
  }

  version = "1.15"

  depends_on = [
    aws_iam_role_policy_attachment.secops-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.secops-cluster-AmazonEKSServicePolicy,
  ]
}

resource "aws_iam_role" "secops-cluster" {
  name = "${var.cluster_name}-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "secops-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.secops-cluster.name
}

resource "aws_iam_role_policy_attachment" "secops-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.secops-cluster.name
}

resource "aws_security_group" "secops-cluster" {
  name        = "terraform-eks-secops-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.secops.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-eks-secops"
  }
}

resource "aws_security_group_rule" "secops-cluster-ingress-workstation-https" {
  cidr_blocks       = var.kubecontrolnets
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.secops-cluster.id
  to_port           = 443
  type              = "ingress"
}
