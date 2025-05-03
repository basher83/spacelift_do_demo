# spacelift/providers.tf
terraform {
  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = "1.21.0"
    }
  }
}

provider "spacelift" {}
