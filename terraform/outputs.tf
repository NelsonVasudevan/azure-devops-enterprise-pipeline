output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "aks_kube_config_command" {
  description = "Run this to fetch kubeconfig credentials for kubectl"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

output "aks_node_resource_group" {
  description = "Auto-generated resource group holding the actual VMs/disks/load balancers"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "kube_admin_config_host" {
  value     = azurerm_kubernetes_cluster.main.kube_config.0.host
  sensitive = true
}
