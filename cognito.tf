# locals {

#   cognito_user_pool_arn = module.aws_cognito_user_pool.arn
#   cognito_user_pool_id  = module.aws_cognito_user_pool.id

# }

module "aws_cognito_user_pool" {
  source = "./cognito"

  count = var.cognito_module_enabled ? 1 : 0
  # User Pools
  user_pool_name             = var.user_pool_name
  alias_attributes           = var.alias_attributes
  auto_verified_attributes   = var.auto_verified_attributes
  sms_authentication_message = "Your access code for the “Get security clearance” service is {####}. Your code expires in 3 minutes."
  sms_verification_message   = "Your access code for the “Get security clearance” service is {####}. Your code expires in 3 minutes."

  sms_configuration = {
    external_id    = "cognito-sms-external-id"
    sns_caller_arn = aws_iam_role.send_mfa_codes_via_sms_role.arn
  }

  deletion_protection = var.deletion_protection


  # SMS MFA must be available
  mfa_configuration = "ON"

  software_token_mfa_configuration = {
    enabled = true
  }


  admin_create_user_config = {
    allow_admin_create_user_only = true
    email_message                = "Dear {username}, your verification code is {####}."
    email_subject                = "Here, your verification code"
    sms_message                  = "Your username is {username} and temporary password is {####}."
  }

  # explicit_auth_flows = []

  device_configuration = {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = true
  }

  email_configuration = {
    email_sending_account  = var.email_sending_account
    reply_to_email_address = var.email_reply_to_address
    source_arn             = var.email_source_arn
  }


  # Backend can confirm user.
  # Backend can access user information

  lambda_config = {
    kms_key_id                     = aws_kms_key.encrypts_mfa_code.arn
    pre_authentication             = var.pre_authentication
    pre_sign_up                    = var.pre_sign_up
    create_auth_challenge          = var.lambda_create_auth_challenge
    custom_message                 = var.lambda_custom_message
    define_auth_challenge          = var.lambda_define_auth_challenge
    post_authentication            = var.lambda_post_authentication
    post_confirmation              = var.lambda_post_confirmation
    pre_authentication             = var.lambda_pre_authentication
    pre_sign_up                    = var.lambda_pre_sign_up
    pre_token_generation           = var.lambda_pre_token_generation
    user_migration                 = var.lambda_user_migration
    verify_auth_challenge_response = var.lambda_verify_auth_challenge_response
    custom_sms_sender = {
      lambda_arn     = "arn:aws:lambda:eu-west-2:${var.account_id}:function:custom_email_sender"
      lambda_version = "V1_0"
    },
  }

  #password policy
  password_policy = {
    minimum_length                   = 10
    require_lowercase                = false
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 120

  }

  verification_message_template = {
    default_email_option = var.default_email_option
  }

  string_schemas = [
    {
      name                     = "organisation_id"
      attribute_data_type      = "String"
      developer_only_attribute = false
      mutable                  = true
      required                 = false
      string_attribute_constraints = {
        min_length = 36
        max_length = 36
      }
    },
    {
      name                     = "roles"
      attribute_data_type      = "String"
      developer_only_attribute = false
      mutable                  = true
      required                 = false
      string_attribute_constraints = {
        min_length = 1
        max_length = 256
      }
    },

    {
      name                     = "internal_id"
      attribute_data_type      = "String"
      developer_only_attribute = false
      mutable                  = true
      required                 = false
      string_attribute_constraints = {
        min_length = var.internal_id_min_length
        max_length = var.internal_id_max_length
      }
    },
    {
      attribute_data_type      = "String"
      developer_only_attribute = false
      mutable                  = false
      name                     = "email"
      required                 = true

      string_attribute_constraints = {
        min_length = 7
        max_length = 15
      }
    },
  ]
  schemas = [
    {
      name                     = "uses_email_mfa"
      attribute_data_type      = "Boolean"
      developer_only_attribute = false
      mutable                  = true
      required                 = false
    },

  ]
  # number_schemas = [
  #   {
  #     developer_only_attribute = true
  #     mutable                  = true
  #     name                     = "phone_number"
  #     attribute_data_type      = "Number"
  #     required                 = true

  #     number_attribute_constraints = {
  #       min_value = 2
  #       max_value = 6
  #     }
  #   },
  # ]

  # user_pool_domain
  domain = "dcf-${var.env_name}"


  # User Pool Clients
  clients = [
    {
      allowed_oauth_flows                  = var.allowed_oauth_flows
      read_attributes                      = var.read_attributes
      write_attributes                     = var.write_attributes
      allowed_oauth_flows_user_pool_client = var.allowed_oauth_flows_user_pool_client #true
      allowed_oauth_scopes                 = var.allowed_oauth_scopes
      callback_urls                        = var.callback_urls
      generate_secret                      = var.generate_secret
      name                                 = var.client_name
      auto_verified_attributes             = var.auto_verified_attributes
      supported_identity_providers         = var.supported_identity_providers
      access_token_validity                = var.access_token_validity
      id_token_validity                    = var.id_token_validity
      prevent_user_existence_errors        = var.prevent_user_existence_errors
      refresh_token_validity               = var.refresh_token_validity
      token_validity_units = {
        access_token  = "minutes"
        id_token      = "minutes"
        refresh_token = "hours"
      }
  }]

  # user_group
  user_groups = [
    { name        = "dcf-group"
      description = "The DCF Group"
    }
  ]

  # Resource Servers
  resource_servers = [
    {
      name       = var.resource_server_name
      identifier = var.resource_server_identifier
      scope = [{
        scope_name        = var.scope_name
        scope_description = var.scope_description
      }]
    }
  ]

  # identity_providers
  identity_providers = [
    {
      provider_name = var.provider_name
      provider_type = var.provider_type

      provider_details = {
        authorize_scopes = "email"
        client_id        = "your client_id"
        client_secret    = "your client_secret"
      }

      attribute_mapping = {
        email    = "email"
        username = "sub"
        gender   = "gender"
      }
    }
  ]


  # This is failing due to version conflicts - requires version = "3.18.0" # https://github.com/hashicorp/terraform-provider-aws/issues/17228
  #   account_recovery_setting {
  #     recovery_mechanism {
  #       name     = "verified_email"
  #       priority = 1
  #     }
  # }

  # tags
  tags = {
    Owner        = var.owner
    Environment  = var.env_name
    Deployed_via = "Terraform"
    Code         = "Repo"
  }
}







