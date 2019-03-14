#requires -Version 5.1
$ErrorActionPreference = "Stop"

class NewClusterInfo {
    [string] $ClusterName
    [string] $ServicePrincipleName
    [string] $ResourceGroupName
    [string] $StorageAccountName
    [string] $TerraformStateContainerName
    [string] $SecretsPath
}

$commandPath = Split-Path -parent $PSCommandPath

Import-Module $commandPath\Add-CustomModulePath.psm1

Add-CustomModulePath

Import-Module freebyTech.Common

<#
    .SYNOPSIS
        Main cluster build script.
#>
function New-ClusterByTerraform {
    [OutputType([NewClusterInfo])]
    Param(
        # The name of the cluster being built.
        [Parameter(Mandatory = $True)]
        [string]$ClusterName,

        # The base path of the cluster.
        [Parameter(Mandatory = $True)]
        [string]$ClusterPath,

        # The count of agents for the cluster.
        [Parameter(Mandatory = $True)]
        [int]$AgentCount,

        # The VM sizes for each agent.
        [Parameter(Mandatory = $True)]
        [string]$VmSize,

        # The Disk size for each agent.
        [Parameter(Mandatory = $True)]
        [int]$DiskSize,

        # The location in which to place the cluster.
        [Parameter(Mandatory = $True)]
        [string]$ClusterLocation
    )
    Process {
        $commonPsModulesPath = Split-Path -parent $PSCommandPath
        $secretsPath = "$ClusterPath\.secrets"
        $commonTerraformTemplatesPath = Resolve-Path -Path "$commonPsModulesPath\..\tf-templates"
        $terraformOutput = "$ClusterPath\terraform"

        Import-Module "$commonPsModulesPath\New-ServicePrinciple.psm1"
        Import-Module "$commonPsModulesPath\New-ResGroupAndStorage.psm1"

        $clusterInfo = [NewClusterInfo]::new()
        $clusterInfo.ClusterName = $ClusterName
        $clusterInfo.ServicePrincipleName = "$ClusterName-servp"
        $clusterInfo.ResourceGroupName = "$ClusterName-resgrp"
        $clusterInfo.StorageAccountName = "${ClusterName}storeacct" -Replace '-', ''
        $clusterInfo.TerraformStateContainerName = "$ClusterName-tfstate"
        $clusterInfo.SecretsPath = $secretsPath

        # Create secrets directory if it doesn't already exist.
        New-DirectoryWithTest -Path $secretsPath | Write-Host

        New-ServicePrinciple -ServicePrincipleName $clusterInfo.ServicePrincipleName -SecretsPath $secretsPath -CertSecured $False -ServiceRole 'Contributor' | Write-Host

        New-ResGroupAndStorage -ResourceGroupName $clusterInfo.ResourceGroupName -StorageAccountName $clusterInfo.StorageAccountName -StorageContainerName $clusterInfo.TerraformStateContainerName -SecretsPath $secretsPath -Location $ClusterLocation | Write-Host

        $envVarLoadScriptName = "Load-Envs-$($clusterInfo.ServicePrincipleName)-terraform.ps1"
        $envVarLoadScript = "$secretsPath\$envVarLoadScriptName"

        if (New-DirectoryWithTest -Path $terraformOutput) {
            Write-Host "Creating base terraform files for new cluster."
            $files = Get-ChildItem $commonTerraformTemplatesPath -Filter "*.tf"
            foreach ($file in $files) {
                $contents = Get-Content $file.FullName
                $newFile = "$terraformOutput\$($file.Name)"
                Write-Host "Creating ${newFile}."
                $contents.Replace('%cluster-name%', $clusterName).Replace('%dns-prefix%', $clusterName).Replace('%cluster-location%', $ClusterLocation).Replace('%resource-group-name%', $clusterInfo.ResourceGroupName).Replace('%agent-count%', $AgentCount).Replace('%vm-size%', $VmSize).Replace('%disk-size%', $DiskSize) | Out-FileUtf8NoBom -FilePath $newFile -Append
            }

            Write-Host "Writing new Env loading script file: $envVarLoadScript"

            Remove-Item $envVarLoadScript -ErrorAction SilentlyContinue

            $fileContents = @"
`$env:ARM_TENANT_ID='$env:AZURE_TENANT_ID'
`$env:ARM_SUBSCRIPTION_ID='$env:AZURE_SUBSCRIPTION_ID'
`$env:ARM_CLIENT_ID='$env:AZURE_SP_APP_ID'
`$env:ARM_CLIENT_SECRET='$env:AZURE_SP_SECRET'
`$env:TF_VAR_client_id='$env:AZURE_SP_APP_ID'
`$env:TF_VAR_client_secret='$env:AZURE_SP_SECRET'
"@
            $fileContents | Out-FileUtf8NoBom -FilePath $envVarLoadScript -Append
        }

        Write-Host "Running terraform init:"
        Set-Location $terraformOutput
        # If don't pipe to Write-Host then the "echo" statements get returned as a part of command output and we ruin
        # the fact that we are just trying to return the cluster information obect. This is because Powershell functions
        # return all uncaptured output.
        & "terraform" init -backend-config="storage_account_name=$env:AZURE_SA_ACCOUNT_NAME" -backend-config="container_name=$($clusterInfo.TerraformStateContainerName)" -backend-config="access_key=$env:AZURE_SA_ACCOUNT_KEY" -backend-config="key=freebytech.$($clusterInfo.TerraformStateContainerName)" | Write-Host
        Write-Host ""
        Write-Host "Loading $envVarLoadScript"
        & $envVarLoadScript  | Write-Host
        Write-Host "terraform plan -out out.plan"
        & "terraform" plan -out out.plan | Write-Host
        Write-Host "terraform apply out.plan"
        & "terraform" apply out.plan | Write-Host

        $clusterPathBash = Convert-ToLinuxPath $ClusterPath
        $commonFilesPathBash = Convert-ToLinuxPath (Resolve-Path -Path "$ClusterPath\..\common").Path
        $commonBashFilesPathBase = "${commonFilesPathBash}/bash-files"

        $initKubeFileName = 'init-kube-connection.sh'
        $fileContents = @"
cd $($terraformOutput.Replace('\', '/'))
echo `"`$(terraform output kube_config)`" > ../.secrets/kube_config
export KUBECONFIG=$clusterPathBash/.secrets/kube_config
export CLUSTER_NAME=$ClusterName
export CLUSTER_FILES_PATH=$clusterPathBash
export COMMON_FILES_PATH=$commonFilesPathBash
export COMMON_BASH_FILES_PATH=$commonBashFilesPathBase
cd $clusterPathBash
"@

        $initKubeFileFullPath = "$ClusterPath\$initKubeFileName"
        Remove-Item $initKubeFileFullPath -ErrorAction SilentlyContinue

        $fileContents | Out-FileUtf8NoBom -FilePath $initKubeFileFullPath -Append
        
        Write-Host 'You will need to run the following to attach to the new cluster in bash:'
        Write-Host ''
        Write-Host "cd $clusterPathBash"
        write-Host ". $initKubeFileName"
        Write-Host ''
        Write-Host 'You can optionally install helm locally by running this:'
        Write-Host ''
        Write-Host '. $COMMON_BASH_FILES_PATH/install-helm-locally.sh'
        Write-Host ''
        Write-Host 'To run the dashboard you can run this:'
        Write-Host ''
        Write-Host 'kubectl proxy'
        Write-Host ''
        Write-Host 'And go to:'
        Write-Host 'http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/overview?namespace=default'

        return $clusterInfo
    }
}