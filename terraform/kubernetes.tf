# Generate inventory file for Ansible
resource "local_file" "ansible_inventory" {
  depends_on = [
    proxmox_vm_qemu.k8s_control_plane,
    proxmox_vm_qemu.k8s_worker
  ]
  
  content = templatefile("${path.module}/templates/inventory.tmpl",
    {
      control_plane_ips = local.control_plane_ips,
      worker_ips = local.worker_ips,
      ssh_user = "ubuntu",
      k8s_version = var.kubernetes_version
    }
  )
  filename = "${path.module}/../configs/inventory.yml"
}

# Generate Ansible playbook
resource "local_file" "ansible_playbook" {
  depends_on = [local_file.ansible_inventory]
  
  content = templatefile("${path.module}/templates/kubernetes-playbook.tmpl",
    {
      k8s_version = var.kubernetes_version,
      pod_network_cidr = "10.244.0.0/16",
      service_cidr = "10.96.0.0/12",
      control_plane_endpoint = local.control_plane_ips[0],
      control_plane_count = var.control_plane_count
    }
  )
  filename = "${path.module}/../configs/kubernetes-playbook.yml"
}

# Execute Ansible playbook
resource "null_resource" "kubernetes_installation" {
  depends_on = [
    local_file.ansible_inventory,
    local_file.ansible_playbook
  ]
  
  provisioner "local-exec" {
    command = "cd ${path.module}/.. && ansible-playbook -i configs/inventory.yml configs/kubernetes-playbook.yml"
  }
}
