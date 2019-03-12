#requires -Version 3
$ErrorActionPreference = "Stop"

<# 
--------------------------------------------------------------------------------
    Contains Crypto functions used by other Powershell scripts.
--------------------------------------------------------------------------------
#>


<#
    .SYNOPSIS
        Create a self sigend certificate in a specific directory.
#>
function New-SelfSignedCert
{
    Param(
        # The number of months the cert should be valid for.
	    [Parameter(Mandatory=$True)]
        [int]$MonthsValid,
        
        # The full path and file name to write the cert to.
	    [Parameter(Mandatory=$True)]
        [string]$FilePath,

        # The password as encrypted by ConvertTo-SecureString
	    [Parameter(Mandatory=$True)]
        [SecureString]$Password,

        # The CN subject for the certificate
	    [Parameter(Mandatory=$True)]
        [string]$Subject    
    )
    Process
    {
        $date_now = Get-Date
        $extended_date = $date_now.AddMonths($MonthsValid)
        $cert = New-SelfSignedCertificate -CertStoreLocation 'Cert:\CurrentUser\My' -Subject "CN=${Subject}" -FriendlyName $Subject -KeyExportPolicy Exportable -KeySpec KeyExchange -NotAfter $extended_date
        $path = 'Cert:\CurrentUser\My\' + $cert.thumbprint
        Export-PfxCertificate -cert $path -FilePath $FilePath -Password $Password
        #Remove-Item $path
    }
}

<#
    .SYNOPSIS
        Create a self sigend certificate in a specific directory.
    .DESCRIPTION
        This method uses the openssl command line program so it expects that binary to exist and be installed
        in the path for global execution.
#>
function Convert-PfxToPkcs12
{
    Param(
        # The full path and file name of the PFX file.
	    [Parameter(Mandatory=$True)]
        [string]$PfxFile,
        
        # The full path and file name of the PEM file to write.
	    [Parameter(Mandatory=$True)]
        [string]$PemFile,

        # The password as encrypted by ConvertTo-SecureString representing the passphrase for the PFX file.
	    [Parameter(Mandatory=$True)]
        [string]$pswd,

        # Whether or not the passphrase used to encrypt the PFX file should also be used to encrypt the PEM file.
	    [Parameter(Mandatory=$True)]
        [bool]$RemovePassphrase    
    )
    Process
    {
        if (!(Test-Path -Path $PfxFile)) { throw [System.ArgumentException] "PFX file ${PfxFile} does not exist." }

        if ($RemovePassphrase -eq $False) {
            & "openssl" pkcs12 -in "$PfxFile" -out "$PemFile" -passin pass:$pswd -passout pass:$pswd
        } else {
            & "openssl" pkcs12 -in "$PfxFile" -out "$PemFile" -passin pass:$pswd -nodes
        }
    }
}
