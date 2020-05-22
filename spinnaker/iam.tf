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
  name = "spinnaker-transit"
  path = "/spinnaker/"

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

resource "aws_iam_user_policy" "spinnaker-transit" {
  name = "spinnaker-transit"
  user = aws_iam_user.spinnaker-transit.name

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
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateSecurityGroup",
                "ec2:CreateTags",
                "ec2:DeleteTags",
                "ec2:DeleteSecurityGroup",
                "ec2:Describe*",
                "ec2:ModifyInstanceAttribute",
                "ec2:ModifyNetworkInterfaceAttribute",
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:Add*",
                "elasticloadbalancing:Create*",
                "elasticloadbalancing:Delete*",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:Describe*",
                "elasticloadbalancing:Modify*",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:Remove*",
                "elasticloadbalancing:Set*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_user_policy" "spinnaker-transit-waf" {
  name = "spinnaker-transit-waf"
  user = aws_iam_user.spinnaker-transit.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "waf-regional:GetWebACLForResource",
                "waf-regional:GetWebACL",
                "waf-regional:AssociateWebACL",
                "waf-regional:DisassociateWebACL"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "waf:GetWebACL"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "shield:DescribeProtection",
                "shield:GetSubscriptionState",
                "shield:DeleteProtection",
                "shield:CreateProtection",
                "shield:DescribeSubscription",
                "shield:ListProtections"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_user_policy" "spinnaker-transit-control" {
  name = "spinnaker-transit-control"
  user = aws_iam_user.spinnaker-transit.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "acm:DescribeCertificate",
                "acm:ListCertificates",
                "acm:GetCertificate"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole",
                "iam:GetServerCertificate",
                "iam:ListServerCertificates"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cognito-idp:DescribeUserPoolClient"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "tag:Get*"
            ],
            "Resource": "*"
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
