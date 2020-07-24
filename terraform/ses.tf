
#Allow SES to send emails from the idp hosts
data "aws_iam_policy_document" "ses_email_role_policy" {
  statement {
    sid    = "AllowSendEmail"
    effect = "Allow"
    actions = [
      "ses:SendRawEmail",
      "ses:SendEmail",
    ]
    resources = [
      "*",
    ]
  }
}
