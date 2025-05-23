# spacelift/context.tf
resource "spacelift_context" "terraform_ansible_demo" {
  name        = "terraform-ansible-do-demo"
  description = "Context for DigitalOcean Terraform and Ansible demo"
}

# Add sensitive environment variables
resource "spacelift_environment_variable" "do_token" {
  context_id = spacelift_context.terraform_ansible_demo.id
  name       = "TF_VAR_do_token"
  value      = "your-do-token-placeholder" # Set through Spacelift UI
  write_only = true
}

resource "spacelift_environment_variable" "ssh_key" {
  context_id = spacelift_context.terraform_ansible_demo.id
  name       = "TF_VAR_staging_public_key"
  value      = "your-ssh-public-key-placeholder" # Set through Spacelift UI
  write_only = true
}

# Upload SSH private key as a mounted file
resource "spacelift_mounted_file" "ssh_private_key" {
  context_id    = spacelift_context.terraform_ansible_demo.id
  relative_path = ".ssh/staging"
  content       = "your-ssh-private-key-placeholder" # Set through Spacelift UI
  write_only    = true
}

resource "spacelift_environment_variable" "ssh_fingerprint" {
  context_id = spacelift_context.terraform_ansible_demo.id
  name       = "TF_VAR_ssh_fingerprint"
  value      = "your-ssh-fingerprint-placeholder"
  write_only = true
}
