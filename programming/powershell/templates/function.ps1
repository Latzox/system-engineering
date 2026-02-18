function Get-SampleFunction {
    <#
    .SYNOPSIS
    A brief description of what the function does.

    .DESCRIPTION
    A detailed explanation of the function’s purpose and how it works.

    .PARAMETER Param1
    Description of the first parameter.

    .PARAMETER Param2
    Description of the second parameter.

    .INPUTS
    If applicable, describe the types of objects that can be piped into this function.

    .OUTPUTS
    Describe the types of objects that the function returns.

    .EXAMPLE
    Example usage of the function with an explanation of what it does.
    PS> Get-SampleFunction -Param1 "Value1" -Param2 "Value2"

    .NOTES
    Additional information such as author, version, and any other notes.

    .LINK
    Link to documentation or related functions if applicable.
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Param1,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Param2 = 10
    )

    Begin {
        Write-Verbose "Starting to process."

        # Global settings
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'

    }

    Process {
        try {
            Write-Verbose "Processing the input parameters."

        }
        catch {
            Write-Error "An error occurred: $_"
        }
    }

    End {
        Write-Verbose "Function execution completed."
    }
}
