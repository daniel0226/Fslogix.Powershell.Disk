function Format-FslDriveLetter {
    <#
        .SYNOPSIS
        Function to either get, set, or remove a disk's driveletter.

        .DESCRIPTION
        Created by Daniel Kim @ FSLogix
        Github: https://github.com/FSLogix/Fslogix.Powershell.Disk

        .PARAMETER Get
        Returns the driveletter associated with the VHD. If none is available, returns the path.

        .PARAMETER Remove
        Removes the driveletter associated with the VHD.

        .PARAMETER Set
        Sets a driveletter to a vhd

        .PARAMETER Letter
        User associated letter when setting vhd's driveletter

        .PARAMETER Assign
        Automatically assigns a driveletter, starting from Z. If 'Z' is not available, then
        the script will iterate alphabetically downwards until letter 'D'. If D is not availabe, then 
        a driveletter cannot be assigned.

        .EXAMPLE
        format-fsldriveletter -path C:\users\danie\documents\ODFC\test1.vhd -get

        .EXAMPLE
        format-fsldriveletter -path C:\users\danie\documents\ODFC\test1.vhd -set -letter T
        Assigns drive letter 'T' to test1.vhd

        .EXAMPLE
        format-fsldriveletter -path C:\users\danie\documents\ODFC\test1.vhd -remove
        Remove's the driveltter on test1.vhd

        .EXAMPLE 
        format-fsldriveletter -path C:\users\danie\documents\ODFC\test1.vhd -assign
        Assigns the VHD, test1.vhd, drive letter Z. If Z is not 
        available, then it'll iterate downwards.
    #>
    [CmdletBinding(DefaultParametersetName = 'None')]
    param (

        [Parameter(Position = 0, Mandatory = $true,
            ValueFromPipeline = $true)]
        [alias("path")]
        [System.String]$VhdPath,

        [Parameter(Position = 1, ParameterSetName = 'GetDL')]
        [Switch]$Get,

        [Parameter(Position = 2, ParameterSetName = 'RemoveDL')]
        [Switch]$Remove,

        [Parameter(Position = 3, ParameterSetName = 'SetDL')]
        [Switch]$Set,

        [Parameter(Position = 4, ParameterSetName = 'SetDL', Mandatory = $true)]
        [ValidatePattern('^[a-zA-Z]')]
        [System.Char]$Letter,

        [Parameter(Position = 5, ParameterSetName = 'AssignDL')]
        [Switch]$Assign,

        [Parameter(Position = 6, ParameterSetName = 'index', Mandatory = $true)]
        [int]$Start,

        [Parameter(Position = 7, ParameterSetName = 'index', Mandatory = $true)]
        [int]$End


    )

    begin {
    }

    process {
        ## FsLogix helper function
        $VHD = get-fsldisk $VhdPath

        ## Helper FsLogix functions, Get-DriveLetter, Set-FslDriveletters, remove-fslDriveletter, and dismount-fsldisk ##
        ## Will validate error handling.                                                                               ##
        if ($Get) {
            get-driveletter -VHDPath $vhd.path
            dismount-FslDisk -path $vhd.path
        }
        if ($Set) {
            Set-FslDriveLetter -VHDPath $vhd.path -Letter $letter
        }
        if ($Remove) {
            Remove-FslDriveLetter -Path $vhd.path
        }
        if ($Assign) {
            $Driveletterassigned = $false
            $letter = [int][char]'Z'
            while ($DriveLetterAssigned -eq $false) {
                try {
                    Write-Verbose "$Letter"
                    
                    if ($Vhd.attached) {
                        $Disk = Get-Disk | Where-Object {$_.Location -eq $VhdPath}
                    }
                    else {
                        $mount = Mount-DiskImage -ImagePath $vhd.path -NoDriveLetter -PassThru -ErrorAction Stop | get-diskimage
                        $Disk = $mount | get-disk -ErrorAction Stop
                    }
                    $Partition = $Disk | get-partition -ErrorAction Stop
                        
                    $Partition_Obj = $Partition | sort-object -property size | select-object -last 1
                    $Partition_Obj | set-partition -NewDriveLetter $letter -ErrorAction Stop 
                        
                    $DriveLetterAssigned = $true

                }
                catch {
                    ## For some reason
                    ## $Letter-- won't work.
                    $letter = $letter - 1
                    if ($Letter -eq 'C') {
                        Write-Error "Cannot find free drive letter" -ErrorAction Stop
                    }
                }
            }
            if ($Driveletterassigned) {
                Write-Verbose "Assigned DriveLetter: $([char]$letter)."
            }
            dismount-FslDisk -fullname $vhd.path
        }
        
    }

    end {
    }
}