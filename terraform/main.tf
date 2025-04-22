locals {
  control_plane_ips = [for i in range(var.control_plane_count) : cidrhost(var.management_network, 10 + i)]
  worker_ips = [for i in range(var.worker_node_count) : cidrhost(var.management_network, 20 + i)]

  all_ips = concat(local.control_plane_ips, local.worker_ips)

  # Parse CIDR to get netmask
  network_parts = split("/", var.management_network)
  network_address = local.network_parts[0]
  network_bits = local.network_parts[1]
  netmask = cidrnetmask(var.management_network)

  # Store the proxmox host for use in provisioners
  proxmox_host = split(":", replace(var.proxmox_api_url, "https://", ""))[0]
}

# Control plane nodes
resource "proxmox_vm_qemu" "k8s_control_plane" {
  depends_on = [null_resource.create_template]
  count = var.control_plane_count

  name = "k8s-control-${count.index + 1}"
  target_node = var.proxmox_node
  clone = var.template_name

  # VM resources
  cores = var.control_plane_vcpus
  sockets = 1
  memory = var.control_plane_memory

  # Disk settings
  disk {
    type = "scsi"
    storage = "local-lvm"
    size = var.disk_size
    discard = "on"
  }

  # Network settings
  network {
    model = "virtio"
    bridge = var.vm_network_bridge
  }

  # Cloud-init settings
  ipconfig0 = "ip=${local.control_plane_ips[count.index]}/${local.network_bits},gw=${var.management_gateway}"

  os_type = "cloud-init"
  cicustom = "user=local:snippets/user-data-${count.index}.yml"

  # Enable qemu agent
  agent = 1

  # Additional settings
  onboot = true

  # Create cloud-init user-data file
  provisioner "local-exec" {
    command = <<-EOT
      cat > /tmp/user-data-${count.index}.yml << 'EOFCI'
      #cloud-config
      hostname: k8s-control-${count.index + 1}
      manage_etc_hosts: true
      users:
        - name: ubuntu
          sudo: ALL=(ALL) NOPASSWD:ALL
          shell: /bin/bash
          ssh_authorized_keys:
            - ${var.ssh_key}
      package_update: true
      package_upgrade: true
      packages:
        - qemu-guest-agent
        - apt-transport-https
        - ca-certificates
        - curl
        - gnupg
        - lsb-release
      runcmd:
        - systemctl enable qemu-guest-agent
        - systemctl start qemu-guest-agent
        - echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-kubernetes.conf
        - echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/99-kubernetes.conf
        - sysctl --system
      EOFCI

      # Create snippets directory if it doesn't exist
      ssh -o StrictHostKeyChecking=no -i ${var.ssh_private_key_path} root@${local.proxmox_host} 'mkdir -p /var/lib/pve/local/snippets'

      # Copy the file
      scp -o StrictHostKeyChecking=no -i ${var.ssh_private_key_path} /tmp/user-data-${count.index}.yml root@${local.proxmox_host}:/var/lib/pve/local/snippets/
    EOT
  }
}

# Control plane cleanup resources
resource "null_resource" "control_plane_cleanup" {
  count = var.control_plane_count

  triggers = {
    vm_id = proxmox_vm_qemu.k8s_control_plane[count.index].id
    proxmox_host = local.proxmox_host
    snippet_index = count.index
    ssh_key_path = var.ssh_private_key_path
  }

  provisioner "local-exec" {
    when    = destroy
    command = "ssh -o StrictHostKeyChecking=no -i ${self.triggers.ssh_key_path} root@${self.triggers.proxmox_host} 'rm -f /var/lib/pve/local/snippets/user-data-${self.triggers.snippet_index}.yml'"
  }
}


# Worker nodes
resource "proxmox_vm_qemu" "k8s_worker" {
  depends_on = [null_resource.create_template]
  count = var.worker_node_count

  name = "k8s-worker-${count.index + 1}"
  target_node = var.proxmox_node
  clone = var.template_name

  # VM resources
  cores = var.worker_vcpus
  sockets = 1
  memory = var.worker_memory

  # Disk settings
  disk {
    type = "scsi"
    storage = "local-lvm"
    size = var.disk_size
    discard = "on"
  }

  # Network settings
  network {
    model = "virtio"
    bridge = var.vm_network_bridge
  }

  # Cloud-init settings
  ipconfig0 = "ip=${local.worker_ips[count.index]}/${local.network_bits},gw=${var.management_gateway}"

  os_type = "cloud-init"
  cicustom = "user=local:snippets/worker-data-${count.index}.yml"

  # Enable qemu agent
  agent = 1

  # Additional settings
  onboot = true

  # Create cloud-init user-data file
  provisioner "local-exec" {
    command = <<-EOT
      cat > /tmp/worker-data-${count.index}.yml << 'EOFCI'
      #cloud-config
      hostname: k8s-worker-${count.index + 1}
      manage_etc_hosts: true
      users:
        - name: ubuntu
          sudo: ALL=(ALL) NOPASSWD:ALL
          shell: /bin/bash
          ssh_authorized_keys:
            - ${var.ssh_key}
      package_update: true
      package_upgrade: true
      packages:
        - qemu-guest-agent
        - apt-transport-https
        - ca-certificates
        - curl
        - gnupg
        - lsb-release
      runcmd:
        - systemctl enable qemu-guest-agent
        - systemctl start qemu-guest-agent
        - echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-kubernetes.conf
        - echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/99-kubernetes.conf
        - sysctl --system
      EOFCI

      # Create snippets directory if it doesn't exist
      ssh -o StrictHostKeyChecking=no -i ${var.ssh_private_key_path} root@${local.proxmox_host} 'mkdir -p /var/lib/pve/local/snippets'

      # Copy the file
      scp -o StrictHostKeyChecking=no -i ${var.ssh_private_key_path} /tmp/worker-data-${count.index}.yml root@${local.proxmox_host}:/var/lib/pve/local/snippets/
    EOT
  }
}
# Worker cleanup resources
resource "null_resource" "worker_cleanup" {
  count = var.worker_node_count

  triggers = {
    vm_id = proxmox_vm_qemu.k8s_worker[count.index].id
    proxmox_host = local.proxmox_host
    snippet_index = count.index
    ssh_key_path = var.ssh_private_key_path
  }

  provisioner "local-exec" {
    when    = destroy
    command = "ssh -o StrictHostKeyChecking=no -i ${self.triggers.ssh_key_path} root@${self.triggers.proxmox_host} 'rm -f /var/lib/pve/local/snippets/worker-data-${self.triggers.snippet_index}.yml'"
  }
}
