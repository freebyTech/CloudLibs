provider "azurerm" {
    version = "~>1.5"
}

terraform {
    backend "azurerm" {}
}

resource "azurerm_resource_group" "cluster_resgrp" {
    name     = "${var.resource_group_name}"
    location = "${var.cluster_location}"
}

resource "azurerm_log_analytics_workspace" "cluster_law" {
    name                = "${var.log_analytics_workspace_name}"
    location            = "${var.log_analytics_workspace_location}"
    resource_group_name = "${azurerm_resource_group.cluster_resgrp.name}"
    sku                 = "${var.log_analytics_workspace_sku}"
}

resource "azurerm_log_analytics_solution" "cluster_las" {
    solution_name         = "ContainerInsights"
    location              = "${azurerm_log_analytics_workspace.cluster_law.location}"
    resource_group_name   = "${azurerm_resource_group.cluster_resgrp.name}"
    workspace_resource_id = "${azurerm_log_analytics_workspace.cluster_law.id}"
    workspace_name        = "${azurerm_log_analytics_workspace.cluster_law.name}"

    plan {
        publisher = "Microsoft"
        product   = "OMSGallery/ContainerInsights"
    }
}

resource "azurerm_kubernetes_cluster" "cluster" {
    name                = "${var.cluster_name}"
    location            = "${azurerm_resource_group.cluster_resgrp.location}"
    resource_group_name = "${azurerm_resource_group.cluster_resgrp.name}"
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
        log_analytics_workspace_id = "${azurerm_log_analytics_workspace.cluster_law.id}"
        }
    }

    tags {
        Environment = "Production"
    }
}