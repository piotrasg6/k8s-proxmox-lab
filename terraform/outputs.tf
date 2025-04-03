output "control_plane_ips" {
  description = "IP addresses of the Kubernetes control plane nodes"
  value       = local.control_plane_ips
}

output "worker_ips" {
  description = "IP addresses of the Kubernetes worker nodes"
  value       = local.worker_ips
}

output "kubernetes_api_endpoint" {
  description = "Kubernetes API endpoint"
  value       = "https://${local.control_plane_ips[0]}:6443"
}

output "access_instructions" {
  description = "Instructions to access the Kubernetes cluster"
  value       = <<-EOT
    Your Kubernetes cluster has been provisioned!
    
    To access the cluster:
    
    1. SSH to the control plane node:
       ssh ubuntu@${local.control_plane_ips[0]}
    
    2. Check the cluster status:
       kubectl get nodes
    
    Your kubeconfig has been copied to ~/.kube/config on your local machine.
    You can use kubectl directly from your machine:
    
    $ kubectl get nodes
    $ kubectl get pods --all-namespaces
  EOT
}
