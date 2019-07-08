#requires -Version 5.1
$ErrorActionPreference = "Stop"

Import-Module Az.Sql

$commandPath = Split-Path -parent $PSCommandPath

Import-Module $commandPath\..\common\Add-CustomModulePath.psm1

Add-CustomModulePath

Import-Module freebyTech.Common

<#
    .SYNOPSIS
        Creates a new SQL Server with a random administrator user and a random password.
    .DESCRIPTION    
        Creates the necessary environment variables load script in the secrets path that defines
        the necessary settings to be able to find and access the SQL Server.

            <SecretsPath>\Load-Envs-Sql-<ServerBaseName>.ps1

        Will only attempt the creation if the above environment variable load script doesn't already exist.
        If it does exist the function will assume the resources were already created and the user merely 
        wants the environment variables to be loaded related to the storage container.
#>
function New-SqlServerAndAdminUser {
    Param(
        # The resource group for the SQL Server, this resource group will also be created.
        [Parameter(Mandatory = $True)]
        [string]$ResourceGroupName,

        # The path where all secrets for this creation operation should be placed.
        [Parameter(Mandatory = $True)]
        [string]$SecretsPath,

        # The name for the storage account.
        [Parameter(Mandatory = $True)]
        [string]$ServerBaseName,

        # The name for first administrative user for the SQL Server.
        [Parameter(Mandatory = $True)]
        [string]$SqlAdminName,

        # The location for the SQL Server.
        [Parameter(Mandatory = $True)]
        [string]$Location,

        # The starting IP address range allowed through the firewall, an IP Address range 0.0.0.0 to 0.0.0.0 means only azure based connections are allowed.
        [Parameter(Mandatory = $False)]
        [string]$StartIp = "0.0.0.0",

        # The ending IP address range allowed through the firewall.
        [Parameter(Mandatory = $False)]
        [string]$EndIp = "0.0.0.0"
    )
    Process {
        $envVarLoadScript = "${SecretsPath}\Load-Envs-SqlServer.ps1"
        $envVarLoadScriptBash = "${SecretsPath}\set-sql-server-environment-variables.sh"

        # If env vars load file doesn't exist then we haven't created this Resource Group and SQL Server, if it does then we have already created them.
        if (!(Test-Path $envVarLoadScript)) {
            Write-Host "Creating Resource Group ${ResourceGroupName} in ${Location}."
            New-AzResourceGroup -Name $ResourceGroupName -Location $Location

            # If we don't already have a password then create one.
            if (!(Test-Path 'env:AZURE_SQL_SERVER')) {
                $env:AZURE_SQL_SERVER = "${ServerBaseName}-$(Get-Random)".ToLower()
                Write-Host "Generating new Password for new server ${env:AZURE_SQL_SERVER} administrator user ${SqlAdminName}"

                $env:AZURE_SQL_SERVER_ADMIN_USER = $SqlAdminName
                $env:AZURE_SQL_SERVER_ADMIN_PASSWORD = New-Password 12
            }

            Write-Host "Creating SQL Server ${env:AZURE_SQL_SERVER} in ${Location}."
            $server = New-AzSqlServer -ResourceGroupName $ResourceGroupName `
                -ServerName $env:AZURE_SQL_SERVER `
                -Location $Location `
                -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SqlAdminName, $(ConvertTo-SecureString -String $env:AZURE_SQL_SERVER_ADMIN_PASSWORD -AsPlainText -Force))

            Write-Host "Updating firewall rules to allow ${StartIp} to ${EndIp}"
            $serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroupName `
                -ServerName $env:AZURE_SQL_SERVER `
                -FirewallRuleName "AllowedIPs" -StartIpAddress $StartIp -EndIpAddress $EndIp

            Write-Host "Writing new Env loading script file: $envVarLoadScript"
            $fileContents = @"
# SQL Server Info
`$env:AZURE_SQL_SERVER= '$env:AZURE_SQL_SERVER.database.windows.net'
`$env:AZURE_SQL_SERVER_ADMIN_USER= '$env:AZURE_SQL_SERVER_ADMIN_USER'
`$env:AZURE_SQL_SERVER_ADMIN_PASSWORD= '$env:AZURE_SQL_SERVER_ADMIN_PASSWORD'
"@
            $fileContents | Out-File -FilePath $envVarLoadScript -Encoding utf8 

            $fileContents = @"
export AZURE_SQL_SERVER='$env:AZURE_SQL_SERVER.database.windows.net'
export AZURE_SQL_SERVER_ADMIN_USER='$env:AZURE_SQL_SERVER_ADMIN_USER'
export AZURE_SQL_SERVER_ADMIN_PASSWORD='$env:AZURE_SQL_SERVER_ADMIN_PASSWORD'
"@
            Remove-Item $envVarLoadScriptBash -ErrorAction SilentlyContinue

            $fileContents | Out-FileUtf8NoBom -FilePath $envVarLoadScriptBash -Append
        }        
        else {
            Write-Host "$envVarLoadScript already exists, loading settings."
            . $envVarLoadScript
        }
    }
}

