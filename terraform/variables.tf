variable "proxmox_api_url" {
  description = "The URL of the Proxmox API"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "The ID of the Proxmox API token"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "The secret of the Proxmox API token"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "The name of the Proxmox node"
  type        = string
  default     = "pve"
}

variable "template_name" {
  description = "The name of the VM template to use"
  type        = string
  default     = "ubuntu-2204-template"
}

variable "ssh_key" {
  description = "The public SSH key to use for VM access"
  type        = string
}

variable "control_plane_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 1
}

variable "worker_node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "control_plane_vcpus" {
  description = "Number of vCPUs for control plane nodes"
  type        = number
  default     = 2
}

variable "control_plane_memory" {
  description = "Memory in MB for control plane nodes"
  type        = number
  default     = 4096
}

variable "worker_vcpus" {
  description = "Number of vCPUs for worker nodes"
  type        = number
  default     = 4
}

variable "worker_memory" {
  description = "Memory in MB for worker nodes"
  type        = number
  default     = 8192
}

variable "vm_network_bridge" {
  description = "Network bridge to use for VMs"
  type        = string
  default     = "vmbr0"
}

variable "management_network" {
  description = "Network CIDR for management network"
  type        = string
  default     = "192.168.100.0/24"
}

variable "management_gateway" {
  description = "Gateway IP for management network"
  type        = string
  default     = "192.168.100.1"
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = string
  default     = "50G"
}

variable "kubernetes_version" {
  description = "Kubernetes version to install"
  type        = string
  default     = "1.26.0"
}
