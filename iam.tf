
resource "aws_iam_role" "send_mfa_codes_via_sms_role" {
  name = "Allow_Cognito_to_send_texts_via_sns_for_mfa"
  inline_policy {
    name   = "send_mfa_codes_via_sms_policy"
    policy = data.aws_iam_policy_document.send_mfa_codes_via_sms_policy_document.json
  }
  assume_role_policy = data.aws_iam_policy_document.assume_send_mfa_codes_via_sms_role.json
}

data "aws_iam_policy_document" "assume_send_mfa_codes_via_sms_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = ["cognito-sms-external-id"]
    }
    principals {
      type        = "Service"
      identifiers = ["cognito-idp.amazonaws.com"]
    }
  }
}


data "aws_iam_policy_document" "send_mfa_codes_via_sms_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["sns:Publish"]
    resources = [
      "*"
    ]
  }
}


data "aws_iam_policy_document" "send_updates_lambda_list_users_access_policy" {
  statement {
    effect = "Allow"

    actions = ["cognito-idp:ListUsers"]

    resources = [
      "*" #"module.aws_cognito_user_pool.${var.user_pool_name}.arn"
    ]
  }
}

resource "aws_iam_policy" "send_updates_lambda_list_users" {
  name   = "send-updates-lambda-list-users"
  policy = data.aws_iam_policy_document.send_updates_lambda_list_users_access_policy.json
}




# allow SNS to write to cloudwatch
data "aws_iam_policy_document" "sns_cloudwatch_log_access" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:*"
    ]
  }
}

# create the policy from the document declared above
resource "aws_iam_policy" "sns_cloudwatch_log_access" {
  name   = "sns_cloudwatch_log_access"
  policy = data.aws_iam_policy_document.sns_cloudwatch_log_access.json
}

# create a role for SNS to assume to write out logs
resource "aws_iam_role" "sns_sms_role" {
  name = "sns_sms_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "sns.amazonaws.com"
        }
      },
    ]
  })
}

# and attach the policies created above
resource "aws_iam_role_policy_attachment" "sns-cloudwatch-attach" {
  role       = aws_iam_role.sns_sms_role.name
  policy_arn = aws_iam_policy.sns_cloudwatch_log_access.arn
}



# turn on logging
resource "aws_sns_sms_preferences" "update_sms_prefs" {
  delivery_status_iam_role_arn          = aws_iam_role.sns_sms_role.arn
  delivery_status_success_sampling_rate = 0
}

data "aws_iam_policy_document" "lambda_admin_update_user_attributes_access_policy" {
  statement {
    effect = "Allow"

    actions = ["cognito-idp:AdminUpdateUserAttributes"]

    resources = [
      "*" #"module.aws_cognito_user_pool.${var.user_pool_name}.arn"
    ]
  }
}

resource "aws_iam_policy" "lambda_admin_update_user_attributes" {
  name   = "lambda_admin_update_user_attributes"
  policy = data.aws_iam_policy_document.lambda_admin_update_user_attributes_access_policy.json
}

