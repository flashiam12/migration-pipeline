terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
    confluent = {
      source  = "confluentinc/confluent"
    }
    google = {
      source  = "hashicorp/google"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "confluent" {
  cloud_api_key    = var.cc_cloud_api_key
  cloud_api_secret = var.cc_cloud_api_secret
}

provider "google" {
  project = var.gcp_project_id
}