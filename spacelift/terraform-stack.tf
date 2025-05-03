# spacelift/terraform-stack.tf
resource "spacelift_stack" "terraform" {
  name         = "do-terraform-stack"
  description  = "Stack for deploying DigitalOcean infrastructure with Terraform"
  repository   = "basher83/spacelift_do_demo"
  branch       = "main"
  project_root = "terraform"

  # Use context with secrets
  context_id = spacelift_context.terraform_ansible_demo.id

  # Enable autodeploy for changes to Terraform files
  autodeploy = true

  # Define push policy
  terraform_workflow_tool = "TERRAFORM"
}

# Publish terraform outputs as JSON to be consumed by Ansible stack
resource "spacelift_stack_terraform_output" "terraform_outputs" {
  stack_id = spacelift_stack.terraform.id
  name     = "terraform_outputs"
}
