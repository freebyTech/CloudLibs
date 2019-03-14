resource "azurerm_resource_group" "devops-k8s" {
    name     = "${var.resource_group_name}"
    location = "${var.cluster_location}"
}

resource "azurerm_log_analytics_workspace" "devops-k8s-law" {
    name                = "${var.log_analytics_workspace_name}"
    location            = "${var.log_analytics_workspace_location}"
    resource_group_name = "${azurerm_resource_group.devops-k8s.name}"
    sku                 = "${var.log_analytics_workspace_sku}"
}

resource "azurerm_log_analytics_solution" "devops-k8s-las" {
    solution_name         = "ContainerInsights"
    location              = "${azurerm_log_analytics_workspace.devops-k8s-law.location}"
    resource_group_name   = "${azurerm_resource_group.devops-k8s.name}"
    workspace_resource_id = "${azurerm_log_analytics_workspace.devops-k8s-law.id}"
    workspace_name        = "${azurerm_log_analytics_workspace.devops-k8s-law.name}"

    plan {
        publisher = "Microsoft"
        product   = "OMSGallery/ContainerInsights"
    }
}

resource "azurerm_kubernetes_cluster" "devops-k8s" {
    name                = "${var.cluster_name}"
    location            = "${azurerm_resource_group.devops-k8s.location}"
    resource_group_name = "${azurerm_resource_group.devops-k8s.name}"
    dns_prefix          = "${var.dns_prefix}"

    linux_profile {
        admin_username = "ubuntu"

        ssh_key {
            key_data = "${file("${var.ssh_public_key}")}"
        }
    }

    agent_pool_profile {
        name            = "agentpool"
        count           = "${var.agent_count}"
        vm_size         = "${var.vm_size}"
        os_type         = "Linux"
        os_disk_size_gb = "${var.disk_size}"
    }

    service_principal {
        client_id     = "${var.client_id}"
        client_secret = "${var.client_secret}"
    }

    role_based_access_control {
		enabled=true
    }

    addon_profile {
        oms_agent {
        enabled                    = true
        log_analytics_workspace_id = "${azurerm_log_analytics_workspace.devops-k8s-law.id}"
        }
    }

    tags {
        Environment = "Production"
    }
}
