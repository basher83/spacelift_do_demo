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

  # Add additional Ansible arguments with absolute paths
  ansible_arguments = [
    "-v",
    "--extra-vars", "ansible_python_interpreter=/usr/bin/python3",
    "--inventory=/mnt/workspace/source/ansible/inventory/inventory.yml",
    "--module-path=/mnt/workspace/source/ansible/library",
    "--roles-path=/mnt/workspace/source/ansible/roles"
  ]

  # Add environment variables
  environment_variables = {
    ANSIBLE_CONFIG = "~/.ansible/ansible.cfg"
  }
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
set -e

echo "Starting Ansible run hook..."
echo "Current directory: $(pwd)"
echo "SPACELIFT_PHASE: $SPACELIFT_PHASE"

# Always use localhost for both planning and apply phases
echo "Creating inventory file with localhost..."

cat > /mnt/workspace/source/ansible/inventory/inventory.yml << EOF
all:
  children:
    webservers:
      hosts:
        localhost:
          ansible_connection: local
          ansible_python_interpreter: /usr/bin/python3
          ansible_become: false
EOF

echo "Inventory file created:"
cat /mnt/workspace/source/ansible/inventory/inventory.yml

# Verify the ansible.cfg file
echo "Ansible config file:"
if [ -f /mnt/workspace/source/ansible/ansible.cfg ]; then
  cat /mnt/workspace/source/ansible/ansible.cfg
else
  echo "ansible.cfg not found"
fi

# Verify the playbook
echo "Ansible playbook:"
cat /mnt/workspace/source/ansible/playbooks/setup.yml

echo "Run hook completed successfully."
EOT
}
