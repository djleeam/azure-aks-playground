variable "prefix" {
  description = "A prefix used for all resources in this example"
  type        = string
  default     = "demo"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "demo-aks-rg"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created"
  type        = string
  default     = "West US"
}

variable "cluster_name" {
  description = "The name of the AKS cluster"
  type        = string
  default     = "demo-aks"
}

variable "kubernetes_version" {
  description = "The version of Kubernetes to use for the AKS cluster"
  type        = string
  default     = null # Use latest stable version
}

variable "node_count" {
  description = "The number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "The size of the Virtual Machine"
  type        = string
  default     = "Standard_D2s_v5"
}

variable "admin_username" {
  description = "The admin username for the AKS cluster"
  type        = string
  default     = "azureuser"
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy for the AKS cluster"
  type        = bool
  default     = true
}

variable "enable_log_analytics" {
  description = "Enable Log Analytics for the AKS cluster"
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "The retention period for logs in days"
  type        = number
  default     = 30
}

variable "network_plugin" {
  description = "Network plugin to use for networking (azure or kubenet)"
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "Network plugin must be either 'azure' or 'kubenet'."
  }
}

variable "network_policy" {
  description = "Sets up network policy to be used with Azure CNI (calico or azure)"
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "calico"], var.network_policy)
    error_message = "Network policy must be either 'azure' or 'calico'."
  }
}

variable "enable_private_cluster" {
  description = "Enable private cluster"
  type        = bool
  default     = false
}

variable "api_server_authorized_ip_ranges" {
  description = "List of authorized IP ranges that can access the Kubernetes API server"
  type        = list(string)
  default     = []
}

variable "enable_network_security_group_rules" {
  description = "Enable custom Network Security Group rules"
  type        = bool
  default     = true
}

variable "allowed_ssh_ip_ranges" {
  description = "List of IP ranges allowed for SSH access to nodes"
  type        = list(string)
  default     = []
}

variable "sku_tier" {
  description = "The SKU Tier for the AKS cluster (Free, Standard, Premium)"
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "SKU tier must be either 'Free', 'Standard', or 'Premium'."
  }
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default = {
    Environment = "demo"
    Project     = "aks-playground"
  }
}
