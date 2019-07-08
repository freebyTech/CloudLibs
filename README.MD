# freebyTech CloudLibs

This code is an extensive set of helper modules, scripts, and terraform files for creating resources in the cloud.

## ps-modules - Common Powershell Modules

This directory contains common powershell modules used in freebyTech scripting operations. There are several different submodules
that contain categories of functionality. These categories are:

* freebyTech.Azure - General azure functions such as working with Storage Containers.
* freebyTech.AzureAD - Azure functions related to Azure AD.
* freebyTech.Common - Common library functions such as logging, error wrappers to common functions, etc.
* freebyTech.Crypto - Functions related to cryptography and security.
* freebyTech.IO - Useful directory and file related functions.
* freebyTech.Network - Functions related to networking.
* freebyTech.PowerCLI - Functions wrapping functionality of VMWare's PowerCLI commands.
* freebyTech.Slack - Functions to logging to a slack channel.

## ps-functions - Complex Resource Creation Functions

This directory contains powershell functions that can be used to create complete resources in Azure. Some of these functions use
terraform as the basis for their functionality and simply setup and run the proper terraform commands and files.

### Azure Kubernetes Service and SQL Server Functions

Here is an example of creating an Azure Kubernetes Service cluster.

```powershell


```

## terraform - Common terraform modules for performing standard operations.