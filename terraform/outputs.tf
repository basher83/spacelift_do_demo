output "droplet_ip" {
  value       = digitalocean_droplet.drop_test.ipv4_address
  description = "The public IPv4 address of the droplet"
}

output "ansible_inventory" {
  value = templatefile("${path.module}/../ansible/inventory/inventory_template.yml", {
    droplet_ip   = digitalocean_droplet.drop_test.ipv4_address
    droplet_name = var.droplet_name
  })
}
