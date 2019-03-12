#requires -Version 3


<# 
--------------------------------------------------------------------------------
    Contains Network Functions used by Other Powershell scripts.
--------------------------------------------------------------------------------
#>

<#
	.SYNOPSIS
		Converts a subnet mask to its actual bit count.
#>
function ConvertTo-MaskLength
{
	# The mask length of the subnet mask passed.
	[OutputType([Int32])]
	Param (
		# The subnet mask to convert.
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[Alias("Mask")]
		[IPAddress]$SubnetMask
	)
	
	$binaryOctets = $SubnetMask.GetAddressBytes() | ForEach-Object {
		[Convert]::ToString($_, 2)
	}
	
	($binaryOctets -join '').Trim('0').Length
}