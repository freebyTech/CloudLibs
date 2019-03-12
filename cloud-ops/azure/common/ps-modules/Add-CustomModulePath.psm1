$ErrorActionPreference = "Stop"

<#
	.SYNOPSIS
        Adds the freebyTech powershell custom modules path to the path of auto loaded modules
        so they can be referenced. Will only add it once.
#>
function Add-CustomModulePath
{
    Process
    {
        $CommandPath = Split-Path -parent $PSCommandPath   
        $customModulesPath = Resolve-Path("${CommandPath}\..\..\..\..\ps-modules")
        if (!($env:PSModulePath -like "*${customModulesPath}*")) {
            Write-Host "Adding ${customModulesPath} to modules path."
            $env:PSModulePath = $env:PSModulePath + ";${customModulesPath}"
        }
    }    
}