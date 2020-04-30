resource "aws_s3_bucket" "spinnaker" {
  bucket = "spinnaker-config-${random_pet.rand.id}"
  acl    = "private"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role" "spinnaker-s3" {
  name = "spinnaker-s3-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# todo (mxplusb): this needs to be updated and scoped accordingly.
resource "aws_iam_role_policy" "spinnaker-s3" {
  name = "spinnaker-s3"
  role = aws_iam_role.spinnaker-s3.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "secops-node-spinnaker-s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.spinnaker-s3.id
}
