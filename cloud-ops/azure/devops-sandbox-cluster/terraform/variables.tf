variable "client_id" {}
variable "client_secret" {}

variable "agent_count" {
    default = 3
}

variable "ssh_public_key" {
    default = "~/.ssh/id_rsa.pub"
}

variable "dns_prefix" {
    default = "devops-k8s"
}

variable "cluster_name" {
    default = "devops-k8s"
}

variable "resource_group_name" {
    default = "devops-k8s-resgrp"
}

variable "cluster_location" {
    default = "Central US"
}

variable "vm_size" {
    default = "Standard_B2s"
}

variable "disk_size" {
    default = 32
}

variable log_analytics_workspace_name {
    default = "devops-k8s-log-analytics"
}

# refer https://azure.microsoft.com/global-infrastructure/services/?products=monitor for log analytics available regions
variable log_analytics_workspace_location {
    default = "eastus"
}

# refer https://azure.microsoft.com/pricing/details/monitor/ for log analytics pricing 
variable log_analytics_workspace_sku {
    default = "PerGB2018"
}
