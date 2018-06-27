function Get-Requirements {
    [CmdletBinding()]
    param (
        
    )
    
    begin {
    }
    
    process {
        Set-StrictMode -Version latest

        Write-Verbose "Checking if Hyper-V is installed..."
        if (((Get-Module).Name -notcontains 'Hyper-V'))  {
            Write-Verbose "Hyper-V does not exist..."
            Write-Error "Hyper-V must be installed to use this script."
        }else{
            Write-Verbose "Hyper-V found"
        }

        Write-Verbose "Checking if in administrator mode..."
        If (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
            Write-Verbose "Validated administrator mode..."
        }else{
            Write-Error "Script must be ran in administrator mode."
        }
        
    }
    
    end {
    }
}