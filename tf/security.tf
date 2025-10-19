# Security Configuration for AKS Cluster
# This file contains additional security resources and configurations

# Data source to get current public IP (for authorized IP ranges)
data "http" "current_ip" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  current_ip = chomp(data.http.current_ip.response_body)
  
  # Default authorized IP ranges - includes current IP if no custom ranges provided
  default_authorized_ips = var.api_server_authorized_ip_ranges != [] ? var.api_server_authorized_ip_ranges : ["${local.current_ip}/32"]
}

# Network Security Group for additional security rules
resource "azurerm_network_security_group" "aks_additional_nsg" {
  count               = var.enable_network_security_group_rules ? 1 : 0
  name                = "${var.prefix}-aks-additional-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Block all inbound traffic by default (except what's explicitly allowed)
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTPS traffic from authorized IPs only
  dynamic "security_rule" {
    for_each = length(local.default_authorized_ips) > 0 ? [1] : []
    content {
      name                       = "AllowHTTPSFromAuthorizedIPs"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefixes    = local.default_authorized_ips
      destination_address_prefix = "*"
    }
  }

  # Allow SSH from authorized IPs only (if specified)
  dynamic "security_rule" {
    for_each = length(var.allowed_ssh_ip_ranges) > 0 ? [1] : []
    content {
      name                       = "AllowSSHFromAuthorizedIPs"
      priority                   = 1100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefixes    = var.allowed_ssh_ip_ranges
      destination_address_prefix = "*"
    }
  }

  # Allow internal AKS communication
  security_rule {
    name                       = "AllowAKSInternal"
    priority                   = 1200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.224.0.0/12"  # AKS VNet CIDR
    destination_address_prefix = "10.224.0.0/12"
  }

  # Allow Azure Load Balancer health probes
  security_rule {
    name                       = "AllowAzureLoadBalancer"
    priority                   = 1300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Key Vault for storing secrets (optional but recommended)
resource "azurerm_key_vault" "aks_kv" {
  name                = "${var.prefix}-aks-kv-${random_string.kv_suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Enable soft delete and purge protection
  soft_delete_retention_days = 7
  purge_protection_enabled   = false  # Set to true for production

  # Network access restrictions
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    
    # Allow access from authorized IP ranges
    ip_rules = local.default_authorized_ips
  }

  tags = var.tags
}

# Random string for Key Vault name uniqueness
resource "random_string" "kv_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Key Vault access policy for AKS cluster identity
resource "azurerm_key_vault_access_policy" "aks_cluster" {
  key_vault_id = azurerm_key_vault.aks_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = module.aks.cluster_identity.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  certificate_permissions = [
    "Get",
    "List"
  ]
}

# Key Vault access policy for current user/service principal
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.aks_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore"
  ]

  certificate_permissions = [
    "Get",
    "List",
    "Create",
    "Import",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "ManageContacts",
    "ManageIssuers",
    "GetIssuers",
    "ListIssuers",
    "SetIssuers",
    "DeleteIssuers"
  ]

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Recover",
    "Backup",
    "Restore"
  ]
}
