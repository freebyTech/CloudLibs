variable "client_id" {}
variable "client_secret" {}

variable "agent_count" {
    default = %agent-count%
}

variable "ssh_public_key" {
    default = "~/.ssh/id_rsa.pub"
}

variable "dns_prefix" {
    default = "%dns-prefix%"
}

variable "cluster_name" {
    default = "%cluster-name%"
}

variable "resource_group_name" {
    default = "%resource-group-name%"
}

variable "cluster_location" {
    default = "%cluster-location%"
}

variable "vm_size" {
    default = "%vm-size%"
}

variable "disk_size" {
    default = %disk-size%
}

variable log_analytics_workspace_name {
    default = "%cluster-name%-log-analytics"
}

# refer https://azure.microsoft.com/global-infrastructure/services/?products=monitor for log analytics available regions
variable log_analytics_workspace_location {
    default = "eastus"
}

# refer https://azure.microsoft.com/pricing/details/monitor/ for log analytics pricing 
variable log_analytics_workspace_sku {
    default = "PerGB2018"
}