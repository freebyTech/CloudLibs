#requires -Version 5.1
$ErrorActionPreference = "Stop"

Import-Module Az.Accounts

$commandPath = Split-Path -parent $PSCommandPath

Import-Module $commandPath\Add-CustomModulePath.psm1

Add-CustomModulePath

Import-Module freebyTech.Common
Import-Module freebyTech.Crypto
Import-Module freebyTech.AzureAD

<#
    .SYNOPSIS
        Creates a new service principle in Azure that Azure that will be authenticated through a newly created
        self signed certificate. Requires a login operation to Azure with an administrative user to complete this
        operation. Once created it will store information about the service principle in environment variables
        and perform a connect operation using the new service principle.
    .DESCRIPTION    
        Places the self signed cert in PFX format and PEM format in the secrets directory.

            <SecretsPath>\<ServicePrincipleName>.pfx
            <SecretsPath>\<ServicePrincipleName>.pem

        Also creates the necessary environment variables load script in the secrets path that defines
        the necessary settings to be able to use the newly created service principle for a login operation.

            <SecretsPath>\Load-Envs-<ServicePrincipleName>.ps1

        Will only attempt the creation if the above environment variable load script doesn't already exist.
        If it does exist the function will assume the principle was already created and the user merely 
        wants the environment variables to be loaded and a connect operation given the defined service principle.
#>
function New-ServicePrinciple
{
    Param(
        # The service principle to create if it doesn't already exist.
	    [Parameter(Mandatory=$True)]
        [string]$ServicePrincipleName,

        # The path where all secrets for this creation operation should be placed.
	    [Parameter(Mandatory=$True)]
        [string]$SecretsPath,

        # Whether or not this service princicple should be secured by a new self signed cert or by a secret.
        [Parameter(Mandatory=$True)]
        [bool] $CertSecured,
        
        # The role to give this service principle
        [Parameter(Mandatory=$False)]
        [String] $ServiceRole = 'Contributor'
    )
    Process
    {
        $env:AZURE_SP_PFX_FILE = "${SecretsPath}\${ServicePrincipleName}.pfx"
        $env:AZURE_SP_PEM_FILE = "${SecretsPath}\${ServicePrincipleName}.pem"
        
        $envVarLoadScript = "${SecretsPath}\Load-Envs-${ServicePrincipleName}.ps1"
        $subject = "${ServicePrincipleName} Cert"

        # If env vars load file doesn't exist then we haven't created this service principle, if it does then we have already 
        if (!(Test-Path $envVarLoadScript)) {
            Connect-AzAccount

            $azureAccountPrinciple = Get-AzContext
            $env:AZURE_TENANT_ID = $azureAccountPrinciple.Tenant
            $env:AZURE_SUBSCRIPTION_ID = $azureAccountPrinciple.Subscription

            Write-Host "Account Tenant ID: $env:AZURE_TENANT_ID"
            Write-Host "Account Subscription ID: $env:AZURE_SUBSCRIPTION_ID"

            if($CertSecured -eq $True) {
                # If we don't already have a password then create one.
                if (!(Test-Path 'env:AZURE_SP_CERT_PSWD')) {
                    Write-Host 'Generating new password'
                    $env:AZURE_SP_CERT_PSWD = New-Password 12
                }    
                $selfSignedCertPswd = ConvertTo-SecureString -String $env:AZURE_SP_CERT_PSWD -Force -AsPlainText
                Write-Host "Creating new PFX certificate file: $env:AZURE_SP_PFX_FILE"
                New-SelfSignedCert -MonthsValid 24 -FilePath $env:AZURE_SP_PFX_FILE -Password $selfSignedCertPswd -Subject $subject

                $azureServicePrinciple = New-ADServicePrincipleWithCert -ApplicationDisplayName $ServicePrincipleName -SubscriptionId $env:AZURE_SUBSCRIPTION_ID -CertPath $env:AZURE_SP_PFX_FILE -CertPassword $selfSignedCertPswd -ServiceRole $ServiceRole

                $env:AZURE_SP_APP_ID = $azureServicePrinciple.ApplicationId
                Write-Host "Service Principle ID: $env:AZURE_SP_APP_ID"

                Write-Host "Writing new Env loading script file: $envVarLoadScript"
                $fileContents = @"
`$env:AZURE_TENANT_ID = '$env:AZURE_TENANT_ID'
`$env:AZURE_SUBSCRIPTION_ID = '$env:AZURE_SUBSCRIPTION_ID'
`$env:AZURE_SP_APP_ID = '$env:AZURE_SP_APP_ID'
`$env:AZURE_SP_CERT_PSWD = '$env:AZURE_SP_CERT_PSWD'
`$env:AZURE_SP_PFX_FILE = '$env:AZURE_SP_PFX_FILE'
"@             
            }
            else {
                # If we don't already have a password then create one.
                if (!(Test-Path 'env:AZURE_SP_SECRET')) {
                    Write-Host 'Generating new password'
                    $env:AZURE_SP_SECRET = New-Password 12
                }    
                $spSecret = ConvertTo-SecureString -String $env:AZURE_SP_SECRET -Force -AsPlainText
                
                $azureServicePrinciple = New-ADServicePrinciple -ApplicationDisplayName $ServicePrincipleName -SubscriptionId $env:AZURE_SUBSCRIPTION_ID -Secret $spSecret -ServiceRole $ServiceRole

                $env:AZURE_SP_APP_ID = $azureServicePrinciple.ApplicationId
                Write-Host "Service Principle ID: $env:AZURE_SP_APP_ID"

                Write-Host "Writing new Env loading script file: $envVarLoadScript"
                $fileContents = @"
`$env:AZURE_TENANT_ID = '$env:AZURE_TENANT_ID'
`$env:AZURE_SUBSCRIPTION_ID = '$env:AZURE_SUBSCRIPTION_ID'
`$env:AZURE_SP_APP_ID = '$env:AZURE_SP_APP_ID'
`$env:AZURE_SP_SECRET = '$env:AZURE_SP_SECRET'
"@
            }
            $fileContents | Out-File -FilePath $envVarLoadScript -Encoding utf8 
        }
        else {
            Write-Host "$envVarLoadScript already exists, loading settings."
            . $envVarLoadScript
            if($CertSecured -eq $True) {
                $selfSignedCertPswd = ConvertTo-SecureString -String $env:AZURE_SP_CERT_PSWD -Force -AsPlainText
            }
            else {
                $spSecret = ConvertTo-SecureString -String $env:AZURE_SP_SECRET -Force -AsPlainText
            }            
        }

        Write-Host 'Attempting to login using created service principle.'
        if($CertSecured) {
            Connect-WithADServicePrinciple -CertPath $env:AZURE_SP_PFX_FILE -CertPassword $selfSignedCertPswd -ApplicationId $env:AZURE_SP_APP_ID -TenantId $env:AZURE_TENANT_ID
        }
        else {
            $credential = New-Object System.Management.Automation.PSCredential ($env:AZURE_SP_APP_ID, $spSecret)
            Connect-AzAccount -ServicePrincipal -Credential $credential -TenantId $env:AZURE_TENANT_ID
        }
    }
}

