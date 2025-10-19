# Create Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Deploy AKS cluster using the official Azure module
module "aks" {
  source  = "Azure/aks/azurerm"
  version = "~> 11.0.0"

  # Basic Configuration
  prefix                           = var.prefix
  resource_group_name              = azurerm_resource_group.main.name
  location                         = azurerm_resource_group.main.location
  cluster_name                     = var.cluster_name
  kubernetes_version               = var.kubernetes_version
  orchestrator_version             = var.kubernetes_version
  sku_tier                         = var.sku_tier

  # Node Pool Configuration
  agents_count                     = var.node_count
  agents_size                      = var.vm_size
  agents_pool_name                 = "system"
  agents_type                      = "VirtualMachineScaleSets"

  # Authentication
  admin_username                   = var.admin_username

  # Security & Policy
  azure_policy_enabled            = var.enable_azure_policy
  role_based_access_control_enabled = false

  # Networking
  network_plugin                   = var.network_plugin
  network_policy                   = var.network_policy
  private_cluster_enabled          = var.enable_private_cluster
  api_server_authorized_ip_ranges  = var.api_server_authorized_ip_ranges

  # Monitoring
  log_analytics_workspace_enabled  = var.enable_log_analytics
  log_retention_in_days            = var.log_retention_in_days

  # Tags
  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}