#requires -Version 5.1
$ErrorActionPreference = "Stop"

Import-Module Az.Storage
Import-Module Az.Resources

<# 
--------------------------------------------------------------------------------
    Contains Common Azure Functions used by Other Powershell Scripts.
--------------------------------------------------------------------------------
#>

<#
    .SYNOPSIS
        Creates a storage context and storage container for the given storage account in the 
        given resource group.
#>
function New-StorageContainer
{
    Param(
        # The resource group for the storage account.
	    [Parameter(Mandatory=$True)]
        [string]$ResourceGroupName,

        # The name for the storage account.
	    [Parameter(Mandatory=$True)]
        [string]$StorageAccountName,

        # The name for the storage container.
	    [Parameter(Mandatory=$True)]
        [string]$StorageContainerName
    )
    Process
    {
        Write-Host "Getting Account Key for Account $StorageAccountName in Resource Group $ResourceGroupName."
        $accountKey = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName

        Write-Host "Creating Storage Context for ${StorageAccountName}."
        $storageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $accountKey.Value[0]

        Write-Host "Creating Storage Container ${StorageContainerName} in context for ${StorageAccountName}."
        New-AzStorageContainer -Name $StorageContainerName -Context $storageContext
    }
}