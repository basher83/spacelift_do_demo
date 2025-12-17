# spacelift/providers.tf
terraform {
  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = "1.41.0"
    }
  }
}

provider "spacelift" {}
