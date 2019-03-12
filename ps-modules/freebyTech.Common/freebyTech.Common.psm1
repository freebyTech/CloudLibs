#requires -Version 3
$ErrorActionPreference = "Stop"

<# 
--------------------------------------------------------------------------------
    Contains Common Functions used by Other Powershell Scripts.
--------------------------------------------------------------------------------
#>

<#
    .SYNOPSIS
        Write a Log Message to the screen and include the scripts current duration in that message.
#>
function Write-ToLog
{
    Param(
        # The DateTime that the script started.
	    [Parameter(Mandatory=$True)]
        [DateTime]$StartTime,
        
        # The string to log to the screen.
	    [Parameter(Mandatory=$True)]
	    [string]$OutputStr
    )
    Process
    {
        $endTime = Get-Date
	    $durationStr = [string]::Format(" - {0:hh\:mm\:ss tt} - [{1:hh\:mm\:ss}]", $endTime, $endTime - $jobStartTime)
	    $fullOutputStr = "$OutputStr$durationStr"
	    Write-Host $fullOutputStr
    }
}

<#
    .SYNOPSIS
        Returns a string representing the duration between the passed DateTime and the Current DateTime.
#>
function Get-Duration
{
    # The returned duration string.
    [OutputType([string])]
    Param(
        # The DateTime that the script started.
	    [Parameter(Mandatory=$True)]
	    [DateTime]$StartTime
    )
    Process {
        $endTime = Get-Date
	    $durationStr = [string]::Format("{0:hh\:mm\:ss}", $endTime - $jobStartTime)
        return $durationStr
    }
}

<#
    .SYNOPSIS
        Executes a command line operation and will throw an exception upon error.
#>
function Invoke-ThrowOnError
{
    Param(
        # The command line to execute.
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]$CommandLine,

        # The error message to display if the exit code of the command is non-zero.
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]$ExceptionMessage,

        # The number of attempts to execute the command (with a pause) before throwing and Exception.
        [Parameter(Mandatory=$false)]
        [int]$TryCount = 1,

        # The number of seconds to pause before attempting the operation again on failure.
        [Parameter(Mandatory=$false)]
        [int]$PauseDurationBeforeRetry = 30    
    )

    Process {
        
        $inc = 0
        while($inc -le $TryCount) {
            Invoke-Expression $CommandLine
            if($LASTEXITCODE -eq 0)
            {
                # Force an exit of loop
                $inc = $TryCount + 1
            }
            elseif($inc -ge $TryCount)
            {
                # Reached max tries, throw exception
                throw [System.Exception] $ExceptionMessage
            }
            else {
                Write-Host "Command execution failed with exit code of $LASTEXITCODE, pausing for $PauseDurationBeforeRetry seconds and retrying..."
                Start-Sleep -s $PauseDurationBeforeRetry
            }
            $inc = $inc + 1
        }
    }
}

<#
    .SYNOPSIS
        Turns an exception into a posting for "More Information".
#>
function Convert-ExceptionToMoreInformation
{
    Param(
        # The exception to extract information from.
	    [Parameter(Mandatory=$True)]
	    [System.Exception]$Exception
    )
    Process
    {
       return '```' + ($Exception | Format-List | Out-String).Trim() + '```'
    }
}


<#
    .SYNOPSIS
        Creates a new password with the specified number of characters.
#>
function New-Password
{
    [OutputType([string])]
    Param(
        # The length of the password.
	    [Parameter(Mandatory=$false)]
	    [int]$MaxChars=8
    )
    Process
    {
        $Password =  ("!@#$%^&*0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz".tochararray() | sort {Get-Random})[0..$MaxChars] -join ''
        return $Password
    }
}

<#
    .SYNOPSIS
        Converts a string into its Base64 equivalent.
#>
function Convert-ToBase64
{
    [OutputType([string])]
    Param(
        # The length of the password.
	    [Parameter(Mandatory=$true)]
	    [string]$StringToEncode
    )
    Process
    {
        $Bytes = [System.Text.Encoding]::Unicode.GetBytes($StringToEncode)
        $EncodedText = [Convert]::ToBase64String($Bytes)
        return $EncodedText
    }
}

<#
    .SYNOPSIS
        Converts a string into its Base64 equivalent.
#>
function Convert-ToLinuxPath
{
    [OutputType([string])]
    Param(
        # The path to examine and potentially convert.
	    [Parameter(Mandatory=$true)]
	    [string]$PathToConvert
    )
    Process
    {
        
        if($PathToConvert.Substring(1,1) -eq ':') {
            $PathToConvert = "/$($PathToConvert.Substring(0,1).ToLower())/$($PathToConvert.Substring(3))".Replace('\', '/')
        }
        return $PathToConvert
    }
}