# Create a KMS key for lambda custom sender config"
resource "aws_kms_key" "encrypts_mfa_code" {
  description = "KMS key for lambda custom sender config"
}
