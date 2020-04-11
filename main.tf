# variable "dbusername" {}
# variable "dbpw" {}

provider "aws" {
  region = "us-east-2"
}

############################################################
# Network stuff
############################################################
resource "aws_vpc" "eksvpc" {
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "eks1" {
  vpc_id     = aws_vpc.eksvpc.id
  cidr_block = "172.16.43.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "tspencer-eks1",
    "kubernetes.io/cluster/tspencer-ekstest" = "shared"
  }
}
resource "aws_subnet" "eks2" {
  vpc_id     = aws_vpc.eksvpc.id
  cidr_block = "172.16.44.0/24"
  availability_zone = "us-east-2c"

  tags = {
    Name = "tspencer-eks2",
    "kubernetes.io/cluster/tspencer-ekstest" = "shared"
  }
}

output "vpc" {
  value = aws_vpc.eksvpc.id
}


##################################################
# eks cluster
resource "aws_eks_cluster" "ekstest" {
  name     = "tspencer-ekstest"
  role_arn = aws_iam_role.eksrole.arn
  enabled_cluster_log_types = ["api", "scheduler"]

  vpc_config {
    subnet_ids = [aws_subnet.eks1.id, aws_subnet.eks2.id]
    public_access_cidrs = ["98.146.223.15/32"]
    endpoint_private_access = true
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.tspencer-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.tspencer-AmazonEKSServicePolicy,
  ]
}


resource "aws_iam_role" "eksrole" {
  name = "tspencer-eks-cluster-ekstest"

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

resource "aws_iam_role_policy_attachment" "tspencer-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eksrole.name
}

resource "aws_iam_role_policy_attachment" "tspencer-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eksrole.name
}

resource "aws_iam_openid_connect_provider" "ekstest" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = []
  url             = aws_eks_cluster.ekstest.identity.0.oidc.0.issuer
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ekstest_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.ekstest.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = ["${aws_iam_openid_connect_provider.ekstest.arn}"]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "ekstest" {
  assume_role_policy = data.aws_iam_policy_document.ekstest_assume_role_policy.json
  name               = "tspencer-ekstest"
}
output "endpoint" {
  value = aws_eks_cluster.ekstest.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.ekstest.certificate_authority.0.data
}

###################################################
# EKS node group
resource "aws_eks_node_group" "ekstest" {
  cluster_name    = aws_eks_cluster.ekstest.name
  node_group_name = "tspencer-ekstest"
  node_role_arn   = aws_iam_role.ekstestnode.arn
  subnet_ids = [aws_subnet.eks1.id, aws_subnet.eks2.id]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.tspencer-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.tspencer-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.tspencer-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role" "ekstestnode" {
  name = "tspencer-eks-node-group-ekstest"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "tspencer-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.ekstestnode.name
}

resource "aws_iam_role_policy_attachment" "tspencer-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.ekstestnode.name
}

resource "aws_iam_role_policy_attachment" "tspencer-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.ekstestnode.name
}
