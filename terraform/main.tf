data "azurerm_client_config" "current" {}

# ---------- Resource Group ----------

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ---------- Networking ----------

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "${var.project_name}-aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.1.0/24"]
}

# ---------- AKS Cluster ----------

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project_name}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.project_name}-aks"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  default_node_pool {
    name           = "system"
    node_count     = var.node_count
    vm_size        = var.node_vm_size
    vnet_subnet_id = azurerm_subnet.aks.id
    type           = "VirtualMachineScaleSets"

    upgrade_settings {
      max_surge = "10%"
    }
  }

  # System-assigned managed identity - no need to hand-manage a
  # Service Principal's client secret rotation for the cluster itself.
  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "10.20.0.0/24"
    dns_service_ip = "10.20.0.10"
  }

  # Free-tier discipline: no auto-scaling by default (keeps node count
  # predictable and billable amount bounded). Flip this on deliberately
  # if you want to demo cluster autoscaler behaviour.
  # auto_scaler_profile {}

  tags = var.tags
}

# ---------- Azure Pipelines Service Connection auth ----------
# Azure Pipelines authenticates to this subscription via a Service
# Principal you create manually (see README) since Terraform creating
# the very identity that Terraform itself runs as is a bootstrapping
# problem best solved outside the state file:
#
#   az ad sp create-for-rbac --name "adep-pipeline-sp" \
#     --role Contributor \
#     --scopes /subscriptions/<subscription_id>/resourceGroups/<resource_group_name>
#
# Store the resulting appId/password/tenant as an Azure Pipelines
# Service Connection (or Azure DevOps secret variables) - never commit
# them to this repo.

# ---------- Budget Alert ----------

resource "azurerm_consumption_budget_resource_group" "main" {
  name              = "${var.project_name}-monthly-budget"
  resource_group_id = azurerm_resource_group.main.id

  amount     = var.budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00'Z'", timestamp())
  }

  notification {
    enabled        = true
    threshold      = 80.0
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100.0
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = [var.alert_email]
  }

  lifecycle {
    ignore_changes = [time_period]
  }
}
