# spacelift/providers.tf
terraform {
  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = "~> 0.1.0"
    }
  }
}

provider "spacelift" {
  # API Token will be set via environment variables
  # SPACELIFT_API_KEY_ID and SPACELIFT_API_KEY_SECRET
}
