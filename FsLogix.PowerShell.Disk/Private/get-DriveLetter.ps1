function get-driveletter {
    <#
        .NOTES
        Created on 6/6/18
        Created by Daniel Kim @ FSLogix    
        Created by Jim Moyle @ FSLogix

        .SYNOPSIS
        Obtains a VHD path and mounts the VHD to the next available
        drive Letter. Allows ability to search and use folders/items
        within a VHD. User will need to then dismount VHD on their
        own. 

        .DESCRIPTION
        This function can be added to any script that requires mounting 
        a vhd and accessing it's contents.

        .PARAMETER VHDPath
        The target path for VHD location.

        .EXAMPLE
        mount-FSLVHD -path \\server\share\ODFC\vhd1.vhdx
        Will return the drive letter
    #>

    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [Alias("path")]
        [string]$VHDPath
    )
    begin {
        Set-StrictMode -Version Latest
    }
    process {

        $Attached = $false

        if (test-path $VHDPath) {
            Write-Verbose "$VHDPath is valid."
        }
        else {
            Write-Error "$VHDPath is invalid."
            exit
        }

        $VHDProperties = get-vhd -path $VHDPath

        if ($VHDProperties.Attached -eq $true) {
            $Attached = $true        
        }

        if ($Attached) {

            ## If disk is already mounted, can skip mounting process.
            $disk = Get-Disk | Where-Object {$_.Location -eq $VHDPath}
            $driveLetter = $disk | Get-Partition | Select-Object -ExpandProperty AccessPaths | Select-Object -first 1

        }
        else {
        
            try {
                ## Need to mount
                $mount = Mount-VHD -path $VHDPath -Passthru -ErrorAction Stop
                Write-Verbose "VHD succesfully mounted."
            }
            catch {
                write-error $Error[0]
                Write-Error "Could not mount VHD. Perhaps the VHD Path is incorrect or already attached."
                break
            }
            #Obtain drive letter
            $driveLetter = $mount | Get-Disk | Get-Partition | Select-Object -ExpandProperty AccessPaths | Select-Object -first 1
        }
    
        if ($null -eq $driveLetter) {

            Write-warning "DriveLetter is null, assigning drive letter."
            if ($Attached) {
                $disk = Get-Disk | Where-Object {$_.Location -eq $VHDPath} | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false -Force
                $driveLetter = $disk | Get-Partition | Select-Object -ExpandProperty AccessPaths | Select-Object -first 1
            }
            else {
                $mount | Get-Disk -Passthru |New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false -Force
                $driveLetter = $mount | Get-Disk | Get-Partition | Select-Object -ExpandProperty AccessPaths | Select-Object -first 1
            }
        }

        #A drive letter was never initialized to the VHD
        if ($driveLetter -like "*\\?\Volume{*") {

            Write-warning "Driveletter is invalid: $Driveletter. Reassigning Drive Letter."
            if ($Attached) {
                $disk = Get-Disk | Where-Object {$_.Location -eq $VHDPath}
                $driveLetter = $disk | Get-Partition | Add-PartitionAccessPath -AssignDriveLetter
            }
            else {
                $driveLetter = $mount | get-disk | Get-Partition | Add-PartitionAccessPath -AssignDriveLetter 
            }      
            <# For some reason, after assigning an partition access path drive letter, the variable
               driveLetter will be null unless remounted. Maybe the code above needs to be
               assigned differently  #>
            if ($null -eq $driveLetter) {
                #Refresh mount
                            
                try {
                    Write-Verbose "Remounting VHD."
                    Dismount-VHD $VHDPath -Passthru -ErrorAction Stop
                }
                catch {
                    Write-Error $Error[0]
                    Write-Error "Failed to Dismount $VHDPath vhd will need to be manually dismounted"
                }

                try {
                    $mount = mount-vhd -path $VHDPath -Passthru -ErrorAction stop
                    $driveLetter = $mount | get-disk | Get-Partition | Select-Object -ExpandProperty AccessPaths | Select-Object -first 1
                    Write-Verbose "Remounted VHD"
                }
                catch {
                    Write-Error "Could not remount VHD"
                    break
                }
                            
            }#end if(null)
        }#end if {volume}
        else {
            Write-Verbose "VHD mounted on drive letter [$DriveLetter]"
        }#end else

        Write-Output $driveLetter
        #return $driveLetter
    
    }#end process
    end {
    }
}
