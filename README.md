# Spacelift DigitalOcean Demo

This repository demonstrates how to build an integrated CI/CD workflow using Spacelift to provision DigitalOcean infrastructure with Terraform and configure it with Ansible.

## Architecture Overview

This project creates a complete infrastructure automation pipeline with two main stages:

1. **Infrastructure Provisioning**: Uses Terraform to create a DigitalOcean droplet
2. **Infrastructure Configuration**: Uses Ansible to configure the droplet with necessary software

The entire workflow is orchestrated by Spacelift, which manages dependencies between the stages and handles all secrets securely.

## Repository Structure

```
spacelift-do-demo/
├── terraform/                  # Terraform configuration for DigitalOcean
│   ├── main.tf                 # Main Terraform configuration with variables
│   ├── outputs.tf              # Output variables for Ansible
│   ├── digitalocean.tftpl      # Cloud-init template for droplet initialization
│   └── terraform.tfvars.example # Example variables (do not include secrets)
├── ansible/                    # Ansible configuration
│   ├── inventory/              # Inventory configuration
│   │   ├── ansible.cfg         # Ansible configuration
│   │   └── inventory.yml.tpl   # Template for inventory (populated by Terraform)
│   ├── playbooks/              # Ansible playbooks
│   │   └── setup.yml           # Main playbook
│   └── roles/                  # Ansible roles
│       ├── common/             # Common configurations
│       ├── docker/             # Docker configurations
│       └── app/                # Application configurations
└── spacelift/                  # Spacelift configuration
    ├── providers.tf            # Spacelift provider configuration
    ├── context.tf              # Shared context for secrets
    ├── terraform-stack.tf      # Terraform stack definition
    └── ansible-stack.tf        # Ansible stack definition
```

## Prerequisites

Before using this repository, you need:

1. A Spacelift account
2. A DigitalOcean account
3. SSH keys for accessing the droplet
4. Git repository connected to Spacelift

## Setup Instructions

### 1. Prepare Your DigitalOcean Account

1. Create a DigitalOcean personal access token
2. Add your SSH public key to DigitalOcean and note the fingerprint
3. Ensure you have the SSH private key available

### 2. Configure Spacelift

#### Create a Context

1. In Spacelift, create a new context named `terraform-ansible-do-demo`
2. Add the following environment variables:

   - `TF_VAR_do_token`: Your DigitalOcean API token
   - `TF_VAR_ssh_fingerprint`: Your SSH key fingerprint from DigitalOcean (eb:54:57:c9:f7:9c:be:2b:4b:e1:69:41:89:d1:ea:b1)
   - `TF_VAR_staging_public_key`: Your SSH public key content

3. Add the following mounted file:
   - Path: `.ssh/id_rsa`
   - Content: Your SSH private key

#### Create the Terraform Stack

1. Create a stack named `do-terraform-stack`
2. Connect it to your repository
3. Set project root to `terraform`
4. Attach the context you created
5. Enable autodeploy (optional)

#### Create the Ansible Stack

1. Create a stack named `do-ansible-stack`
2. Connect it to your repository
3. Set project root to `ansible`
4. Set playbook path to `playbooks/setup.yml`
5. Attach the context you created

#### Configure Dependencies

1. Create a dependency between the Ansible stack and the Terraform stack
2. Configure the hook to generate the inventory from Terraform outputs

### 3. Initial Deployment

1. Trigger the Terraform stack
2. Once completed, the Ansible stack will automatically trigger
3. Monitor both stacks for successful completion

## Infrastructure Details

### DigitalOcean Droplet

- **Image**: Ubuntu 24.04 x64
- **Size**: s-1vcpu-1gb (Basic Droplet)
- **Region**: NYC1
- **Name**: Configurable via `droplet_name` variable (default: "drop-test-v3")
- **Configuration**:
  - Ansible user with sudo access
  - Python3 and pip installed
  - ZSH shell installed
  - Docker installed via secure installation script

### Ansible Configuration

The Ansible playbook configures the droplet with:

1. **Common Role**:

   - System updates
   - Essential packages (curl, wget, htop, git, vim, ufw)
   - Firewall configuration (allows ports 22, 80, 443)

2. **Docker Role**:

   - Docker group configuration
   - User permissions

3. **App Role**:
   - Required Ansible collections (community.docker)
   - HTML directory with sample content
   - Nginx web server via Docker (pinned to specific version)
   - Container configuration

## How It Works

1. When code is pushed to the repository, Spacelift detects the changes
2. The Terraform stack runs first, provisioning the DigitalOcean droplet
3. Terraform outputs (like the droplet IP and name) are stored in Spacelift
4. When the Terraform stack completes, it triggers the Ansible stack
5. The Ansible stack uses a pre-run hook to generate an inventory file from the Terraform outputs
6. Ansible configures the droplet according to the defined roles
7. The entire workflow completes automatically, resulting in a fully provisioned and configured server

## Parameterization and Reusability

This project uses parameterization to enhance reusability:

1. **Droplet Configuration**: All droplet settings (name, size, region, image) are parameterized in Terraform variables
2. **Dynamic Inventory**: The Ansible inventory is dynamically generated using the droplet name and IP from Terraform outputs
3. **Consistent Paths**: All file paths use proper relative path references to ensure consistency across environments
4. **Version Pinning**: Docker and container images are pinned to specific versions for stability

## Extending the Project

You can extend this project by:

1. Adding more Terraform resources (additional droplets, load balancers, etc.)
2. Creating additional Ansible roles for specialized configurations
3. Adding integration tests to verify the infrastructure
4. Implementing policy checks in Spacelift to enforce compliance
5. Adding monitoring and alerting configurations

## Troubleshooting

Common issues and solutions:

1. **SSH Connection Failures**:

   - Verify SSH key paths and permissions
   - Ensure the private key is properly mounted in Spacelift at `/mnt/workspace/.ssh/id_rsa`
   - Check firewall rules on the droplet
   - Verify the ansible user was created correctly in cloud-init

2. **Terraform Failures**:

   - Verify DigitalOcean API token permissions
   - Check resource quotas in your DigitalOcean account
   - Validate Terraform syntax with `terraform validate`
   - Ensure path references use `${path.module}` for consistency

3. **Ansible Failures**:
   - Check inventory generation in the pre-run hook
   - Verify the inventory file is created at the correct location (`inventory/inventory.yml`)
   - Ensure the community.docker collection is installed successfully
   - Verify Python installation on the target server
   - Check that the HTML directory is created and accessible

## Security Best Practices

This project implements several security best practices:

1. **Secure Docker Installation**: Docker is installed using a downloaded script that can be verified
2. **Version Pinning**: All software versions are pinned to specific releases
3. **Firewall Configuration**: UFW is configured to only allow necessary ports
4. **SSH Hardening**: Password authentication is disabled, only key-based authentication is allowed
5. **Least Privilege**: The Ansible user has only the necessary permissions

## Resources

- [Spacelift Documentation](https://docs.spacelift.io/)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [DigitalOcean API Documentation](https://docs.digitalocean.com/reference/api/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Documentation](https://docs.docker.com/)

## License

This project is licensed under the MIT License - see the LICENSE file for details.
