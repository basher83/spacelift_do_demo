# spacelift/providers.tf
terraform {
  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = "1.27.0"
    }
  }
}

provider "spacelift" {}
