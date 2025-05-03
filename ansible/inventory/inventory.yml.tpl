# ansible/inventory/inventory_template.yml.tpl
all:
  children:
    webservers:
      hosts:
        ${droplet_name}:
          ansible_host: ${droplet_ip}
          ansible_user: ansible
          ansible_ssh_private_key_file: /mnt/workspace/.ssh/staging