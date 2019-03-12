#requires -Version 3

<# 
--------------------------------------------------------------------------------
    Contains PowerCLI Functions used by Other Powershell related to VMWare
    functionality.
--------------------------------------------------------------------------------
#>

<#
    .SYNOPSIS
        Starts a passed VM and waits for Customization events to complete. This will wait indefinitely.
#>
function Start-VMAndWaitForCustomizationEvents
{
    Param(
        # The virtual machine loaded by a PowerCLI function like Get-VM
	    [Parameter(Mandatory=$True)]
	    [Vmware.VIMAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]$VmRef,
        # Whether or not an OS customization is specified so we need to wait before returning from that.
        [Parameter(Mandatory=$False)]
        [bool] $SkipOSCustomization = $False
    )

    Process {
	    $vm = Start-VM $VmRef -Confirm:$False -ErrorAction:Stop
 
	    # wait until VM has started
	    Write-Host "Waiting for VM to start ..."
	    while ($True)
	    {
		    $vmEvents = Get-VIEvent -Entity $vm
 
		    $startedEvent = $vmEvents | Where { $_.GetType().Name -eq "VMStartingEvent" }
 
		    if ($startedEvent) 
		    {
			    break
		    }
		    else
		    {
			    Start-Sleep -Seconds 10	
		    }	
	    }
 
        if($SkipOSCustomization -eq $False)
        {
            # wait until customization process has started  
            Write-Host "Waiting for Customization to start ..."
            while($True)
            {
                $vmEvents = Get-VIEvent -Entity $vm 
                $startedEvent = $vmEvents | Where { $_.GetType().Name -eq "CustomizationStartedEvent" }
     
                if ($startedEvent)
                {
                    break   
                }
                else    
                {
                    Start-Sleep -Seconds 10
                }
            }
     
            # wait until customization process has completed or failed
            Write-Host "Waiting for Customization to complete ..."
            while ($True)
            {
                $vmEvents = Get-VIEvent -Entity $vm
                $succeedEvent = $vmEvents | Where { $_.GetType().Name -eq "CustomizationSucceeded" }
                $failEvent = $vmEvents | Where { $_.GetType().Name -eq "CustomizationFailed" }
     
                if ($failEvent)
                {
                    Write-Host "Customization failed!"
                    return
                }
     
                if($succeedEvent)
                {
                    Write-Host "Customization succeeded!"
                    Write-Host "Pausing for 30 seconds to allow final reboot to start ..."
                    Start-Sleep 30
                    return
                }
     
                Start-Sleep -Seconds 10
            }
        }	    
    }
}


# 
#    
#
#    
#    
#    Author: James Eby
#
#    Parameters:
#  
#    $vm       R = 
#

<#
    .SYNOPSIS
        Wait on the status of a VM's Guest Tools to become available to know that the OS has finished booting.

    .DESCRIPTION
        This function waits a maximum of 30 minutes for the operations to complete.

#>
function Wait-ForGuestOS
{
    Param(
        # The virtual machine loaded by a PowerCLI function like Get-VM
	    [Parameter(Mandatory=$True)]
	    [Vmware.VIMAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl] $VM
    )

    Process {
        $inc = 0
        do {	
	        Start-Sleep -s 10
	        $toolsStatus = (Get-VM $VM | Get-View).Guest.ToolsStatus
	        Write-Host "Status = $toolsStatus"
	        $inc = $inc + 1
	        if($inc -gt 180) 
	        { 
	    	    throw [System.TimeoutException] "Wait-ForGuestOS exceeded 30 minutes!"
	        }
        } until (( $toolsStatus -eq 'toolsOk' ) -or ($toolsStatus -eq 'toolsOld'))

    }
}