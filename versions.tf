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

  #   Define where to store tfstate 
  
    backend "gcs" {
    bucket         = "cloud-internship-petar_cloudbuild"
    prefix         = "terraform.tfstate"
    credentials    = "credentials.json"
  }
}