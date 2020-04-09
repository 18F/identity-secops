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

# resource "aws_subnet" "db" {
#   vpc_id     = aws_vpc.eksvpc.id
#   cidr_block = "172.16.45.0/24"

#   tags = {
#     Name = "db"
#     createdby = "tspencer"
#   }
# }
resource "aws_subnet" "eks1" {
  vpc_id     = aws_vpc.eksvpc.id
  cidr_block = "172.16.43.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "tspencer-eks1"
    createdby = "tspencer"
    "kubernetes.io/cluster/ekstest" = "shared"
  }
}
resource "aws_subnet" "eks2" {
  vpc_id     = aws_vpc.eksvpc.id
  cidr_block = "172.16.44.0/24"
  availability_zone = "us-east-2c"

  tags = {
    Name = "tspencer-eks2"
    createdby = "tspencer"
    "kubernetes.io/cluster/ekstest" = "shared"
  }
}

# resource "aws_db_instance" "idp" {
#   allocated_storage    = 5
#   storage_type         = "standard"
#   engine               = "postgres"
#   engine_version       = "9.6.16"
#   instance_class       = "db.t3.small"
#   name                 = "idpdb"
#   username             = var.dbusername
#   password             = var.dbpw
#   db_subnet_group_name = aws_subnet.db.id
# }

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
    aws_iam_role_policy_attachment.ekstest-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.ekstest-AmazonEKSServicePolicy,
  ]

  tags = {
    createdby = "tspencer"
  }
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

resource "aws_iam_role_policy_attachment" "ekstest-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eksrole.name
}

resource "aws_iam_role_policy_attachment" "ekstest-AmazonEKSServicePolicy" {
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

  tags = {
    createdby = "tspencer"
  }
}
output "endpoint" {
  value = aws_eks_cluster.ekstest.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.ekstest.certificate_authority.0.data
}


##################################################
# eks fargate profile
##################################################
resource "aws_eks_fargate_profile" "eks" {
  cluster_name           = aws_eks_cluster.ekstest.name
  fargate_profile_name   = "tspencer-fargatetest"
  pod_execution_role_arn = aws_iam_role.eksfargaterole.arn
  subnet_ids             = [aws_subnet.eks1.id, aws_subnet.eks2.id]

  selector {
    namespace = "kube-system"
  }

  tags = {
    createdby = "tspencer"
  }
}

resource "aws_iam_role" "eksfargaterole" {
  name = "tspencer-eks-fargate-profile-test"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "ekstest-AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eksfargaterole.name
}

# output "idpdb" {
#   value = aws_db_instance.idp.endpoint
# }
