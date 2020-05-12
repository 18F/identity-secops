#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EKS Node Group to launch worker nodes
#
resource "aws_eks_node_group" "secops" {
  cluster_name    = aws_eks_cluster.secops.name
  node_group_name = "secops-${var.cluster_name}"
  node_role_arn   = aws_iam_role.secops-node.arn
  subnet_ids      = aws_subnet.secops[*].id
  instance_types  = ["t3a.large"]

  scaling_config {
    desired_size = 4
    max_size     = 6
    min_size     = 2
  }

  depends_on = [
    aws_iam_role_policy_attachment.secops-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.secops-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.secops-node-AmazonEC2ContainerRegistryReadOnly
  ]
}

resource "aws_iam_role" "secops-node" {
  name = "${var.cluster_name}-noderole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "secops-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.secops-node.name
}

resource "aws_iam_role_policy_attachment" "secops-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.secops-node.name
}

resource "aws_iam_role_policy_attachment" "secops-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.secops-node.name
}

resource "aws_iam_role_policy" "ebs_csi_driver" {
  name = "ebs_csi_driver"
  role = aws_iam_role.secops-node.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteSnapshot",
        "ec2:DeleteTags",
        "ec2:DeleteVolume",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DetachVolume"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
