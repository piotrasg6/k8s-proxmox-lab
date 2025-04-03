# Kubernetes Proxmox Lab Environment

This repository contains Terraform configurations to create a reusable Kubernetes lab environment on Proxmox.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and customize the variables
2. Initialize Terraform: `terraform init`
3. Apply the configuration: `terraform apply`
4. To destroy the lab: `terraform destroy`

## Components

- 1 Kubernetes control plane node
- 3 Kubernetes worker nodes
- Dedicated storage VM (optional)
- Load balancer VM (optional)

## Network Configuration

- Management Network: 192.168.100.0/24
- Pod Network: 10.244.0.0/16
- Service Network: 10.96.0.0/12
