#requires -Version 5.1
$ErrorActionPreference = "Stop"

Import-Module Az.Sql

<#
    .SYNOPSIS
        Creates a new SQL Server Database on the given SQL Server.
#>
function New-SqlServerDb
{
    Param(
        # The resource group for the SQL Server, this resource group should already exist.
	    [Parameter(Mandatory=$True)]
        [string]$ResourceGroupName,

        # The name for the storage account.
	    [Parameter(Mandatory=$True)]
        [string]$ServerName,

        # The database to create.
	    [Parameter(Mandatory=$True)]
        [string]$DbName,

        # The requested service object name for performance level
	    [Parameter(Mandatory=$False)]
        [string]$RequestedServiceObjectiveName = "S0"
    )
    Process
    {
            Write-Host "Creating new DB $DbName on SQL Server $ServerName with service level $RequestedServiceObjectiveName."
            $database = New-AzSqlDatabase  -ResourceGroupName $ResourceGroupName `
                -ServerName $ServerName `
                -DatabaseName $DbName `
                -RequestedServiceObjectiveName $RequestedServiceObjectiveName
    }
}

