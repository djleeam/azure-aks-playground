# Resource Group
output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "The location of the resource group"
  value       = azurerm_resource_group.main.location
}

# AKS Cluster Information
output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks.aks_name
}

output "cluster_id" {
  description = "The ID of the AKS cluster"
  value       = module.aks.aks_id
}

# output "cluster_fqdn" {
#   description = "The FQDN of the AKS cluster"
#   value       = module.aks.fqdn
# }

output "cluster_endpoint" {
  description = "The endpoint for the AKS cluster API server"
  value       = module.aks.host
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate"
  value       = module.aks.cluster_ca_certificate
  sensitive   = true
}

# Node Pool Information
output "node_resource_group" {
  description = "The auto-generated resource group which contains the resources for this managed Kubernetes cluster"
  value       = module.aks.node_resource_group
}

# Identity Information
output "cluster_identity" {
  description = "The identity of the AKS cluster"
  value       = module.aks.cluster_identity
}

output "kubelet_identity" {
  description = "The kubelet identity of the AKS cluster"
  value       = module.aks.kubelet_identity
}

# Networking
output "network_profile" {
  description = "The network profile of the AKS cluster"
  value       = module.aks.network_profile
}

# Log Analytics (if enabled)
# output "log_analytics_workspace_id" {
#   description = "The ID of the Log Analytics workspace"
#   value       = var.enable_log_analytics ? module.aks.log_analytics_workspace_id : null
# }

# output "log_analytics_workspace_name" {
#   description = "The name of the Log Analytics workspace"
#   value       = var.enable_log_analytics ? module.aks.log_analytics_workspace_name : null
# }

# Kubeconfig (sensitive)
output "kube_config" {
  description = "Raw kubeconfig for the AKS cluster"
  value       = module.aks.kube_config_raw
  sensitive   = true
}

# Instructions for connecting to the cluster
output "cluster_connection_info" {
  description = "Instructions for connecting to the AKS cluster"
  value = <<-EOT
    To connect to your AKS cluster, run the following commands:

    1. Get cluster credentials:
       az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.aks_name}

    2. Launch k9s for interactive cluster management:
       k9s

    3. Or use kubectl directly:
       kubectl get nodes
       kubectl cluster-info
  EOT
}

# Security Information
output "security_info" {
  description = "Security configuration information"
  value = <<-EOT
    🛡️ SECURITY STATUS:

    Private Cluster: ${var.enable_private_cluster ? "✅ ENABLED" : "❌ DISABLED (Public cluster)"}
    API Server Restrictions: ${length(var.api_server_authorized_ip_ranges) > 0 ? "✅ ENABLED (${length(var.api_server_authorized_ip_ranges)} IP ranges)" : "❌ DISABLED (Open to all IPs)"}
    Network Security Groups: ${var.enable_network_security_group_rules ? "✅ ENABLED" : "❌ DISABLED"}
    Azure Policy: ${var.enable_azure_policy ? "✅ ENABLED" : "❌ DISABLED"}
    Network Policy: ${var.network_policy != "" ? "✅ ENABLED (${var.network_policy})" : "❌ DISABLED"}

    ⚠️  SECURITY RECOMMENDATIONS:
    ${var.enable_private_cluster ? "" : "- Consider enabling private cluster for production"}
    ${length(var.api_server_authorized_ip_ranges) > 0 ? "" : "- Add API server authorized IP ranges to restrict access"}
    - Review the SECURITY.md file for complete security hardening guide
    - Enable Azure Defender for Kubernetes in Azure Security Center
    - Implement Pod Security Standards for workload security
  EOT
}

# Current IP for reference (only if security.tf is included)
output "current_public_ip" {
  description = "Your current public IP (for authorized IP ranges configuration)"
  value       = var.enable_network_security_group_rules ? "Your current public IP: ${chomp(data.http.current_ip.response_body)}" : "Enable network security group rules to see current IP"
}
