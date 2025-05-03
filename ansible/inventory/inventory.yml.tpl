# terraform/inventory.yml.tpl
all:
  children:
    webservers:
      hosts:
        drop-test-v3:
          ansible_host: ${droplet_ip}
          ansible_user: ansible
          ansible_ssh_private_key_file: ~/.ssh/id_rsa