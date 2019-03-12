#requires -version 3
$ErrorActionPreference = "Stop"

<# 
--------------------------------------------------------------------------------
    Contains file directory and IO based functions used by other Powershell scripts.
--------------------------------------------------------------------------------
#>

<#
    .SYNOPSIS
        Will create a directory if it doesn't already exist and return True if it had to create it, 
        otherwise it returns false.
#>
function New-DirectoryWithTest
{
    # The returned duration string.
    [OutputType([bool])]
    Param(
        # The directory to test for existence and create if it doesn't already.
	    [Parameter(Mandatory=$True)]
	    [string]$Path
    )
    Process {
        If(!(Test-Path -Path $Path))
        {
            New-Item -ItemType Directory -Force -Path $Path | Write-Host
            return $True
        }
        return $False
    }
}


<#
.SYNOPSIS
  Outputs to a UTF-8-encoded file without a byte order mark like Out-File does.#>
function Out-FileUtf8NoBom {

    param(
        [Parameter(Mandatory=$True)]
        [string] $FilePath,

        [Parameter(Mandatory=$False)]
        [switch] $NoClobber,

        [Parameter(Mandatory=$False)]
        [switch] $Append,

        [AllowNull()]
        [int] $Width,

        [Parameter(ValueFromPipeline)] 
        $InputObject
    )
    process {
        # Make sure that the .NET framework sees the same working dir. as PS
        # and resolve the input path to a full path.
        [System.IO.Directory]::SetCurrentDirectory($PWD) # Caveat: .NET Core doesn't support [Environment]::CurrentDirectory
        $FilePath = [IO.Path]::GetFullPath($FilePath)
    
        # If -NoClobber was specified, throw an exception if the target file already
        # exists.
        if ($NoClobber -and (Test-Path $FilePath)) {
            Throw [IO.IOException] "The file '$FilePath' already exists."
        }
    
        # Create a StreamWriter object.
        # Note that we take advantage of the fact that the StreamWriter class by default:
        # - uses UTF-8 encoding
        # - without a BOM.
        $sw = New-Object IO.StreamWriter $FilePath, $Append
    
        $htOutStringArgs = @{}
        if ($Width) {
            $htOutStringArgs += @{ Width = $Width }
        }
    
        # Note: By not using begin / process / end blocks, we're effectively running
        #       in the end block, which means that all pipeline input has already
        #       been collected in automatic variable $Input.
        #       We must use this approach, because using | Out-String individually
        #       in each iteration of a process block would format each input object
        #       with an indvidual header.
        try {
            $Input | Out-String -Stream @htOutStringArgs | ForEach-Object { $sw.WriteLine($_) }
        } finally {
            $sw.Dispose()
        }
    }
}

<#
.SYNOPSIS
  Writes a UTF-8-encoded file without a byte order mark like Out-File does.#>
  function Write-FileUtf8NoBom {

    param(
        [Parameter(Mandatory=$True)]
        [string] $FilePath,

        [Parameter(Mandatory=$True)]
        [string] $FileContents,

        [Parameter(Mandatory=$False)]
        [switch] $NoClobber = $False
    )
    process {
        # Make sure that the .NET framework sees the same working dir. as PS
        # and resolve the input path to a full path.
        [System.IO.Directory]::SetCurrentDirectory($PWD) # Caveat: .NET Core doesn't support [Environment]::CurrentDirectory
        $FilePath = [IO.Path]::GetFullPath($FilePath)
    
        # If -NoClobber was specified, throw an exception if the target file already
        # exists.
        if ($NoClobber -and (Test-Path $FilePath)) {
            Throw [IO.IOException] "The file '$FilePath' already exists."
        }        
    
        [System.IO.File]::WriteAllLines($FilePath, $FileContents)
    }
}