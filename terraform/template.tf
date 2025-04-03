resource "null_resource" "create_template" {
  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      ssh root@${split(":", replace(var.proxmox_api_url, "https://", ""))[0]} '
        # Check if template already exists
        if qm list | grep -q "${var.template_name}"; then
          echo "Template ${var.template_name} already exists"
          exit 0
        fi

        # Copy the cloud image
        cp /var/lib/vz/template/iso/jammy-server-cloudimg-amd64.img /var/lib/vz/template/qemu-server/jammy-server-cloudimg-amd64.qcow2

        # Create new VM
        qm create 9000 --name "${var.template_name}" --memory 2048 --cores 2 --net0 virtio,bridge=${var.vm_network_bridge}

        # Import the disk
        qm importdisk 9000 /var/lib/vz/template/qemu-server/jammy-server-cloudimg-amd64.qcow2 local-lvm

        # Configure the disk
        qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

        # Add cloud-init drive
        qm set 9000 --ide2 local-lvm:cloudinit

        # Set boot order
        qm set 9000 --boot c --bootdisk scsi0

        # Configure cloud-init
        qm set 9000 --serial0 socket --vga serial0
        qm set 9000 --ipconfig0 ip=dhcp
        qm set 9000 --cicustom "user=local:snippets/cloud-init-user.yml"

        # Create cloud-init user config
        cat > /var/lib/pve/local/snippets/cloud-init-user.yml << EOF
        #cloud-config
        hostname: template
        manage_etc_hosts: true
        users:
          - name: ubuntu
            sudo: ALL=(ALL) NOPASSWD:ALL
            shell: /bin/bash
            ssh_authorized_keys:
              - ${var.ssh_key}
        packages:
          - qemu-guest-agent
        package_update: true
        package_upgrade: true
        runcmd:
          - systemctl enable qemu-guest-agent
          - systemctl start qemu-guest-agent
        EOF

        # Convert to template
        qm template 9000
      '
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Template will not be removed automatically to avoid disrupting other environments.'"
  }
}
