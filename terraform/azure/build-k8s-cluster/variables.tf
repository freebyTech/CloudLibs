variable "client_id" {}
variable "client_secret" {}
variable "cluster_name" {}
variable "log_analytics_workspace_name" {}
variable "dns_prefix" {}
variable "vm_size" {}
variable "disk_size" {}
variable "agent_count" {}
variable "resource_group_name" {}

variable "kubernetes_version" {
    default = "1.13.5"
}

variable "ssh_public_key" {
    default = "~/.ssh/id_rsa.pub"
}

variable "cluster_location" {
    default = "centralus"
}

# refer https://azure.microsoft.com/global-infrastructure/services/?products=monitor for log analytics available regions
variable log_analytics_workspace_location {
    default = "eastus"
}

# refer https://azure.microsoft.com/pricing/details/monitor/ for log analytics pricing 
variable log_analytics_workspace_sku {
    default = "PerGB2018"
}