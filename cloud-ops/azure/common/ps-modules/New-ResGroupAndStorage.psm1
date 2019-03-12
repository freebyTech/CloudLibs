#requires -Version 5.1
$ErrorActionPreference = "Stop"

Import-Module Az.Storage
Import-Module Az.Resources

$commandPath = Split-Path -parent $PSCommandPath

Import-Module $commandPath\Add-CustomModulePath.psm1

Add-CustomModulePath

<#
    .SYNOPSIS
        Creates a new resource group, storage account, storage context, and storage container
        if they don't already exist. Also stores necessary values in environment variables to use
        that storage container in other operations.
    .DESCRIPTION    
        Creates the necessary environment variables load script in the secrets path that defines
        the necessary settings to be able to use the storage container.

            <SecretsPath>\Load-Envs-<StorageAccountName>.ps1

        Will only attempt the creation if the above environment variable load script doesn't already exist.
        If it does exist the function will assume the resources were already created and the user merely 
        wants the environment variables to be loaded related to the storage container.
#>
function New-ResGroupAndStorage
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
        [string]$StorageContainerName,

        # The path where all secrets for this creation operation should be placed.
	    [Parameter(Mandatory=$True)]
        [string]$SecretsPath,

        # The location for the resource group and storage account.
	    [Parameter(Mandatory=$True)]
        [string]$Location
    )
    Process
    {
        $envVarLoadScript = "${SecretsPath}\Load-Envs-${StorageAccountName}.ps1"

        # If Cert doesn't exist then we haven't created this service principle, if it does then we have already 
        if (!(Test-Path $envVarLoadScript)) {
            Write-Host "Creating Resource Group ${ResourceGroupName} in ${Location}."
            New-AzResourceGroup -Name $ResourceGroupName -Location $Location

            Write-Host "Creating Storage Account ${StorageAccountName} in ${Location}."
            New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -SkuName Standard_LRS -Location $Location
            $accountKey = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName

            Write-Host "Creating Storage Context for ${StorageAccountName}."
            $storageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $accountKey.Value[0]

            Write-Host "Creating Storage Container ${StorageContainerName} in context for ${StorageAccountName}."
            New-AzStorageContainer -Name $StorageContainerName -Context $storageContext

            $env:AZURE_SA_ACCOUNT_NAME = $StorageAccountName
            $env:AZURE_SA_ACCOUNT_KEY = $accountKey.Value[0]
            $env:AZURE_SA_ACCOUNT_KEY_BASE64 = Convert-ToBase64 -StringToEncode $env:AZURE_SA_ACCOUNT_KEY
            Write-Host "Writing new Env loading script file: $envVarLoadScript"
            $fileContents = @"
# Storage Account Info
`$env:AZURE_SA_ACCOUNT_NAME= '$env:AZURE_SA_ACCOUNT_NAME'
`$env:AZURE_SA_ACCOUNT_KEY= '$env:AZURE_SA_ACCOUNT_KEY'
`$env:AZURE_SA_ACCOUNT_KEY_BASE64= '$env:AZURE_SA_ACCOUNT_KEY_BASE64'
"@
            $fileContents | Out-File -FilePath $envVarLoadScript -Encoding utf8 
        }        
        else {
            Write-Host "$envVarLoadScript already exists, loading settings."
            . $envVarLoadScript
        }
    }
}

