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
      "Resource": "${aws_s3_bucket.spinnaker-s3.arn}"
    }
  ]
}
EOF
}
