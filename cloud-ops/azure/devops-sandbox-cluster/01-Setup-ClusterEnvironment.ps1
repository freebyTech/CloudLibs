#requires -Version 5.1
$ErrorActionPreference = "Stop"

$commandPath = Split-Path -parent $PSCommandPath
$commonPsModulesPath = Resolve-Path -Path "$commandPath\..\common\ps-modules"

Import-Module "$commonPsModulesPath\New-ClusterByTerraform.psm1"

$clusterName = 'devopsk8s'

$newClusterInfo = New-ClusterByTerraform -ClusterName $clusterName -ClusterPath $commandPath -AgentCount 2 -VmSize 'Standard_DS1_v2' -ClusterLocation 'East US' -DiskSize 64

# This new storage container is for Harbor.
New-StorageContainer -ResourceGroupName $newClusterInfo.ResourceGroupName -StorageAccountName $newClusterInfo.StorageAccountName -StorageContainerName "$clusterName-harbor"