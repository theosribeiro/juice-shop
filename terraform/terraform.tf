terraform {
  backend "s3" {
    bucket = "juice-shop-tr-terraform-state"
    key    = "terraform"
    region = "sa-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}