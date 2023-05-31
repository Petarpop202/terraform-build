terraform {
  required_version = ">= 0.13"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.53.0, < 5.0.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.40.0, < 5.0.0"
    }
  }
}