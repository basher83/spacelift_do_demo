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
    "--limit=localhost",
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

# List all files in the inventory directory
echo "Listing all files in the inventory directory:"
ls -la /mnt/workspace/source/ansible/inventory/

# Remove any existing inventory files that might be causing issues
echo "Removing any existing inventory files that might be causing issues..."
rm -f /mnt/workspace/source/ansible/inventory/*.yml.tpl
rm -f /mnt/workspace/source/ansible/inventory/*.tpl

# Create a clean inventory file with only localhost
echo "Creating clean inventory file with only localhost..."

cat > /mnt/workspace/source/ansible/inventory/inventory.yml << 'EOF'
# This is a static inventory file for Spacelift
# It only contains localhost to avoid connection errors
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

# Create a custom ansible.cfg file in the home directory
echo "Creating custom ansible.cfg in home directory..."
mkdir -p ~/.ansible
cat > ~/.ansible/ansible.cfg << 'EOF'
[defaults]
inventory = /mnt/workspace/source/ansible/inventory/inventory.yml
host_key_checking = False
roles_path = /mnt/workspace/source/ansible/roles
timeout = 30
localhost_warning = False

[ssh_connection]
pipelining = True
EOF

# Export ANSIBLE_CONFIG environment variable
export ANSIBLE_CONFIG=~/.ansible/ansible.cfg
echo "ANSIBLE_CONFIG set to $ANSIBLE_CONFIG"

# List all files in the inventory directory again
echo "Listing all files in the inventory directory after changes:"
ls -la /mnt/workspace/source/ansible/inventory/

echo "Run hook completed successfully."
EOT
}
