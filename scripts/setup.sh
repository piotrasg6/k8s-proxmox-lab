#!/bin/bash

# Create terraform.tfvars file if it doesn't exist
if [ ! -f terraform/terraform.tfvars ]; then
  echo "Creating terraform.tfvars from example file..."
  cp terraform/terraform.tfvars.example terraform/terraform.tfvars
  echo "Please edit terraform/terraform.tfvars with your specific configuration"
  exit 0
fi

# Initialize Terraform
cd terraform
terraform init

# Apply Terraform configuration
terraform apply
