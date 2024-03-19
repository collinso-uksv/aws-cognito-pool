terraform {
  required_version = ">= v1.3.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.38"
    }
  }
}
