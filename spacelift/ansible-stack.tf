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

# Get Terraform outputs
output_json=$(spacectl stack output get -s "${spacelift_stack.terraform.id}" -o terraform_outputs)

# Extract the droplet IP and name
droplet_ip=$(echo $output_json | jq -r '.droplet_ip')
droplet_name=$(echo $output_json | jq -r '.droplet_name')

echo "Got droplet IP: $droplet_ip and name: $droplet_name"

# Fix permissions on ansible directory to avoid world-writable warning
echo "Fixing permissions on ansible directory..."
chmod -R 755 /mnt/workspace/source/ansible

# Create a specific ansible.cfg file in a non-world-writable location
echo "Creating ansible.cfg in home directory..."
mkdir -p ~/.ansible
cat > ~/.ansible/ansible.cfg << EOF
[defaults]
inventory = /mnt/workspace/source/ansible/inventory/inventory.yml
remote_user = ansible
host_key_checking = False
roles_path = /mnt/workspace/source/ansible/roles
timeout = 30

[ssh_connection]
pipelining = True
EOF

# Set ANSIBLE_CONFIG environment variable
export ANSIBLE_CONFIG=~/.ansible/ansible.cfg
echo "ANSIBLE_CONFIG set to $ANSIBLE_CONFIG"

# Create the inventory file with absolute paths
echo "Creating inventory file..."
cat > /mnt/workspace/source/ansible/inventory/inventory.yml << EOF
all:
  children:
    webservers:
      hosts:
        $droplet_name:
          ansible_host: $droplet_ip
          ansible_user: ansible
          ansible_ssh_private_key_file: /mnt/workspace/.ssh/staging
EOF

# Verify the inventory file
echo "Verifying inventory file..."
ls -la /mnt/workspace/source/ansible/inventory/
cat /mnt/workspace/source/ansible/inventory/inventory.yml

# Verify roles directory
echo "Verifying roles directory..."
ls -la /mnt/workspace/source/ansible/roles/

# Create symbolic links for roles in the expected locations
echo "Creating symbolic links for roles..."
mkdir -p /mnt/workspace/source/ansible/playbooks/roles
mkdir -p /mnt/workspace/source/ansible/.spacelift/.ansible/roles

# Link each role to the expected locations
for role in /mnt/workspace/source/ansible/roles/*; do
  role_name=$(basename "$role")
  echo "Linking role $role_name..."
  ln -sf "$role" "/mnt/workspace/source/ansible/playbooks/roles/$role_name"
  ln -sf "$role" "/mnt/workspace/source/ansible/.spacelift/.ansible/roles/$role_name"
done

# Verify the links
echo "Verifying role links in playbooks/roles..."
ls -la /mnt/workspace/source/ansible/playbooks/roles/
echo "Verifying role links in .spacelift/.ansible/roles..."
ls -la /mnt/workspace/source/ansible/.spacelift/.ansible/roles/

echo "Run hook completed successfully. Created Ansible inventory with droplet IP: $droplet_ip"
EOT
}
