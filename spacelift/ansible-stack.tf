# spacelift/ansible-stack.tf
resource "spacelift_stack" "ansible" {
  name         = "do-ansible-stack"
  description  = "Stack for configuring DigitalOcean droplet with Ansible"
  repository   = "basher83/spacelift_do_demo"
  branch       = "main"
  project_root = "ansible"

  # Use context with secrets
  context_id = spacelift_context.terraform_ansible_demo.id

  # Define push policy
  ansible_playbook = "playbooks/setup.yml"
}

# Create a dependency so this stack runs after the Terraform stack
resource "spacelift_stack_dependency" "terraform_to_ansible" {
  stack_id            = spacelift_stack.ansible.id
  depends_on_stack_id = spacelift_stack.terraform.id
}

# Use output from Terraform to create the Ansible inventory
resource "spacelift_run_hook" "create_inventory" {
  stack_id = spacelift_stack.ansible.id
  name     = "Create Ansible inventory from Terraform outputs"
  type     = "BEFORE_INIT"

  run_command = <<EOT
#!/bin/bash
# Get Terraform outputs
output_json=$(spacectl stack output get -s "${spacelift_stack.terraform.id}" -o terraform_outputs)

# Extract the droplet IP
droplet_ip=$(echo $output_json | jq -r '.droplet_ip')

# Create the inventory file
mkdir -p inventory
cat > inventory/hosts.yml << EOF
all:
  children:
    webservers:
      hosts:
        drop-test-v3:
          ansible_host: $droplet_ip
          ansible_user: ansible
          ansible_ssh_private_key_file: /mnt/workspace/.ssh/id_rsa
EOF

echo "Created Ansible inventory with droplet IP: $droplet_ip"
EOT
}
