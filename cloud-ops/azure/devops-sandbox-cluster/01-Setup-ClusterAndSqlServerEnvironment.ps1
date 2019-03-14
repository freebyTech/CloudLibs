#requires -Version 5.1
$ErrorActionPreference = "Stop"

$commandPath = Split-Path -parent $PSCommandPath
$commonPsModulesPath = Resolve-Path -Path "$commandPath\..\common\ps-modules"

Import-Module "$commonPsModulesPath\New-ClusterByTerraform.psm1"
Import-Module "$commonPsModulesPath\New-SqlServerAndAdminUser.psm1"
Import-Module "$commonPsModulesPath\New-SqlServerDb.psm1"

$clusterName = 'devops-k8s'

$newClusterInfo = New-ClusterByTerraform -ClusterName $clusterName -ClusterPath $commandPath -AgentCount 3 -VmSize 'Standard_B2s' -ClusterLocation 'Central US' -DiskSize 32

# This new storage container is for Harbor.
New-StorageContainer -ResourceGroupName $newClusterInfo.ResourceGroupName -StorageAccountName $newClusterInfo.StorageAccountName -StorageContainerName "$clusterName-harbor"

$sqlResourceGroupName = "devops-sql-resgrp"

# Create the new SQL Server for the environment applications.
New-SqlServerAndAdminUser  -ResourceGroupName $sqlResourceGroupName -SecretsPath $newClusterInfo.SecretsPath -ServerBaseName 'devopssql' -SqlAdminName 'SqlAdmin' -Location 'Central US'

# Create the DB for the test application.
New-SqlServerDb  -ResourceGroupName $sqlResourceGroupName -ServerName $env:AZURE_SQL_SERVER -DbName 'ConferenceDb'