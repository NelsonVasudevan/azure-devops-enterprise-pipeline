variable "subscription_id" {
  description = "Azure subscription ID for the free-tier account"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "centralindia"
}

variable "resource_group_name" {
  description = "Name of the resource group that holds all project resources"
  type        = string
  default     = "rg-azure-devops-pipeline"
}

variable "project_name" {
  description = "Short name used as a prefix for resource naming"
  type        = string
  default     = "adep" # azure-devops-enterprise-pipeline
}

variable "environment" {
  description = "Environment tag (dev/staging/prod) - single-env for this portfolio project"
  type        = string
  default     = "dev"
}

# ---------- AKS ----------

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster. Leave null to use the latest stable version AKS offers."
  type        = string
  default     = null
}

variable "node_count" {
  description = "Number of nodes in the default node pool. Keep this at 1-2 to stay within free-tier limits."
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "VM size for AKS nodes. B2s is the cheapest burstable size that can actually run a real workload."
  type        = string
  default     = "Standard_B2s"
}

variable "sku_tier" {
  description = "AKS control plane SKU tier. 'Free' has no SLA but costs nothing extra - correct choice for a free-tier account."
  type        = string
  default     = "Free"
}

# ---------- Budget alert ----------

variable "budget_amount" {
  description = "Monthly budget cap in USD that triggers alert emails"
  type        = number
  default     = 5
}

variable "alert_email" {
  description = "Email address to receive budget alerts"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    project     = "azure-devops-enterprise-pipeline"
    managed_by  = "terraform"
    purpose     = "portfolio"
  }
}
