#requires -Version 5.1
$ErrorActionPreference = "Stop"

Import-Module Az.Resources
Import-Module Az.Accounts

<# 
--------------------------------------------------------------------------------
    Contains Common Azure Functions used by Other Powershell Scripts.
--------------------------------------------------------------------------------
#>


<#
   .SYNOPSIS
      Creates a new Azure Service Principle with the Azure Resource Manager.
#>
function New-ADServicePrincipleWithCert
{
   [OutputType([Microsoft.Azure.Commands.ActiveDirectory.PSADServicePrincipal])]
   Param (
      # The display name of the application service principle.
      [Parameter(Mandatory=$true)]
      [String] $ApplicationDisplayName,

      # The subscription ID of whose resource manager context this should be created under.
      [Parameter(Mandatory=$true)]
      [String] $SubscriptionId,

      # The path to the X509 Cert that will be attached to this service principle.
      [Parameter(Mandatory=$true)]
      [String] $CertPath,

      # The password that unencrypts the cert file.
      [Parameter(Mandatory=$true)]
      [SecureString] $CertPassword,

      # The role to give this service principle
      [Parameter(Mandatory=$false)]
      [String] $ServiceRole = 'Contributor'
   )

   Write-Host "Setting context subscription ID to $SubscriptionId."
   Set-AzContext -Subscription $SubscriptionId

   $pfxCert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @($CertPath, $CertPassword)
   $keyValue = [System.Convert]::ToBase64String($pfxCert.GetRawCertData())
   $pfxCert | format-list

   Write-Host "Creating new application $ApplicationDisplayName."
   $application = New-AzADApplication -DisplayName $ApplicationDisplayName -IdentifierUris "http://$ApplicationDisplayName" -CertValue $keyValue -StartDate $pfxCert.NotBefore -EndDate $pfxCert.NotAfter

   Write-Host "Creating new service principle $ApplicationDisplayName."
   $servicePrincipal = New-AzADServicePrincipal -DisplayName $ApplicationDisplayName -ApplicationId $application.ApplicationId -Role $ServiceRole
   
   return $servicePrincipal
}

<#
   .SYNOPSIS
      Creates a new Azure Service Principle with the Azure Resource Manager.
#>
function New-ADServicePrinciple
{
   [OutputType([Microsoft.Azure.Commands.ActiveDirectory.PSADServicePrincipal])]
   Param (
      # The display name of the application service principle.
      [Parameter(Mandatory=$true)]
      [String] $ApplicationDisplayName,

      # The subscription ID of whose resource manager context this should be created under.
      [Parameter(Mandatory=$true)]
      [String] $SubscriptionId,

      # The password that unencrypts the cert file.
      [Parameter(Mandatory=$true)]
      [SecureString] $Secret,

      # The role to give this service principle
      [Parameter(Mandatory=$false)]
      [String] $ServiceRole = 'Contributor'
   )

   Write-Host "Setting context subscription ID to $SubscriptionId."
   Set-AzContext -Subscription $SubscriptionId

   Write-Host "Creating new application $ApplicationDisplayName."
   $application = New-AzADApplication -DisplayName $ApplicationDisplayName -IdentifierUris "http://$ApplicationDisplayName" -Password $Secret

   Write-Host "Creating new service principle $ApplicationDisplayName."
   $servicePrincipal = New-AzADServicePrincipal -DisplayName $ApplicationDisplayName -ApplicationId $application.ApplicationId -Role $ServiceRole
   
   return $servicePrincipal
}

<#
   .SYNOPSIS
      Connect to Azure with a service principle via a private certificate.
#>
function Connect-WithADServicePrinciple
{
   [OutputType([Microsoft.Azure.Commands.Profile.Models.Core.PSAzureProfile])]
   Param (

   [Parameter(Mandatory=$true)]
   [String] $CertPath,

   [Parameter(Mandatory=$true)]
   [SecureString] $CertPassword,

   [Parameter(Mandatory=$true)]
   [String] $ApplicationId,

   [Parameter(Mandatory=$true)]
   [String] $TenantId
   )

   $pfxCert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @($CertPath, $CertPassword)
   
   return Connect-AzAccount -ServicePrincipal -CertificateThumbprint $pfxCert.Thumbprint -ApplicationId $ApplicationId -TenantId $TenantId
}