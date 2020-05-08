resource "aws_iam_user" "spinnaker-s3" {
    name = "spinnaker-s3-bot"
    path = "/spinnaker/"
}

resource "aws_iam_access_key" "spinnaker-s3" {
  user = aws_iam_user.spinnaker-s3.name
}

resource "aws_iam_user_policy" "spinnaker-s3" {
  name = "spinnaker-s3-policy"
  user = aws_iam_user.spinnaker-s3.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.spinnaker-s3.arn}",
        "${aws_s3_bucket.spinnaker-s3.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_user" "spinnaker-transit" {
    name = "spinnaker-transit-bot"
    path = "/spinnaker/"
}

resource "aws_iam_access_key" "spinnaker-transit" {
  user = aws_iam_user.spinnaker-transit.name
}

resource "aws_iam_policy" "spinnaker-transit" {
  name        = "spinnaker-transit"
  path        = "/spinnaker/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "route53:*",
        "route53domains:*",
        "elasticloadbalancing:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "spinnaker-transit" {
  name = "spinnaker-transit-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_endpoint}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${var.oidc_endpoint}:sub": "system:serviceaccount:identity-system:external-dns"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "spinnaker-transit" {
  role       = aws_iam_role.spinnaker-transit.name
  policy_arn = aws_iam_policy.spinnaker-transit.arn
}
