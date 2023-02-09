function Add-Disks {
    <#
.SYNOPSIS
    Adds virtual disks to vSphere VM and configures them with appropriate controllers and unit numbers.
.DESCRIPTION
    Adds 3 additional SCSI ParaVirtual controllers.
    Adds virtual disks to vSphere VM and configures them with appropriate controllers and keys.
    The script looks for the specified VM, and sets up configuration for each added disk, distributing them amongst all added SCSI controllers, each disk is added one by one and then configured with the first available controller and unit number.
    Supports a maximum of 15 disks added.
    By default the disks are added as lazy zeroed thick.
    The script does not support adding disks if the controller and key are already occupied by previously added disks, script works flawlessly when adding disks in addition to the OS disk.
.PARAMETER VMName
    Name of the virtual machine to configure.
.PARAMETER Confirm
    Switch to disable confirmation prompt to shutdown the VM. If -Confirm is present, the VM will be automatically shutdown, this is required to re-configure the disk.
.EXAMPLE
    Add-Disks -VMName <Name> -Confirm -DiskOneSize 1 -DiskTwoSize 2 -DiskThreeSize 3 -DiskFourSize 4 -DiskFiveSize 5 -DiskSixSize 6

    Adds 6 virtual disks to the specified VM, and confirms the VM to be shutdown so it doesn't ask you, useful for automatic procedure.
.EXAMPLE
    Add-Disks -VMName <Name> -Confirm -EagerZeroedThick -DiskOneSize 1 -DiskTwoSize 2 -DiskThreeSize 3 -DiskFourSize 4 -DiskFiveSize 5 -DiskSixSize 6

    Adds 6 eager zeroed thick virtual disks to the specified VM, and confirms the VM to be shutdown so it doesn't ask you, useful for automatic procedure.
.NOTES
    Author: Patryk Podlas
    Created: 13/01/2023

    Change history:
    Date            Author      V       Notes
    13/01/2023      PP          1.0     First release
    18/01/2023      PP          1.1     Update
    20/01/2023      PP          1.2     Update - Added more error handling, must add disk 7/8 (they don't match up in Windows if added to controllers 1:2 and 2:2).
    25/01/2023      PP          1.3     Update - Added support for up to 15 disks.
    30/01/2023      PP          1.4     Update - Changed the way number of disks are detected, fully working depending on amount of parameters specified.
    01/02/2023      PP          1.5     Update - Added support for 1, 2, 3, 4, 5 disks.
    07/02/2023      PP          1.6     Update - Added switch for Eager Zeroed Thick disks.
    08/02/2023      PP          1.7     Update - Fixed issue with manually added controllers, this script now adds the controllers and re-configured them in the appropriate SCSI slot numbers so they show up in order in Windows.
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$VMName,
        [Parameter(Mandatory = $false, Position = 2)]
        [switch]$Confirm,
        [Parameter(Mandatory = $false, Position = 3)]
        [switch]$EagerZeroedThick,
        [Parameter(Mandatory = $false, Position = 4)]
        [int64]$DiskOneSize,
        [Parameter(Mandatory = $false, Position = 5)]
        [int64]$DiskTwoSize,
        [Parameter(Mandatory = $false, Position = 6)]
        [int64]$DiskThreeSize,
        [Parameter(Mandatory = $false, Position = 7)]
        [int64]$DiskFourSize,
        [Parameter(Mandatory = $false, Position = 8)]
        [int64]$DiskFiveSize,
        [Parameter(Mandatory = $false, Position = 9)]
        [int64]$DiskSixSize,
        [Parameter(Mandatory = $false, Position = 10)]
        [int64]$DiskSevenSize,
        [Parameter(Mandatory = $false, Position = 11)]
        [int64]$DiskEightSize,
        [Parameter(Mandatory = $false, Position = 12)]
        [int64]$DiskNineSize,
        [Parameter(Mandatory = $false, Position = 13)]
        [int64]$DiskTenSize,
        [Parameter(Mandatory = $false, Position = 14)]
        [int64]$DiskElevenSize,
        [Parameter(Mandatory = $false, Position = 15)]
        [int64]$DiskTwelveSize,
        [Parameter(Mandatory = $false, Position = 16)]
        [int64]$DiskThirteenSize,
        [Parameter(Mandatory = $false, Position = 17)]
        [int64]$DiskFourteenSize,
        [Parameter(Mandatory = $false, Position = 18)]
        [int64]$DiskFifteenSize
    )

    begin {
        # This line is necessary because one mandatory parameter is always present, the -VMName parameter.
        $DiskCount = $PSBoundParameters.Count - 1
        # These two lines are necessary because having the -Confirm parameter needs to be accounted for in the disk count, this means if both - the -VMName and -Confirm parameters are present and no Disk<int64>Size parameters are present, the DiskCount is always 0.
        if ($Confirm) {
            $DiskCount -= 1
        }
        if ($EagerZeroedThick) {
            $DiskCount -= 1
        }
        $VM = Get-VM -Name $VMName -ErrorAction Stop
        # Shutdown the virtual machine
        if ($VM.PowerState -eq "PoweredOn" -and $Confirm) {
            Write-Output "---Shutting down the Virtual Machine: $VMName."
            try {
                $VM | Shutdown-VMGuest -Confirm:$false -ErrorAction Stop | Out-Null
                while ((Get-VM -Name $VMName).PowerState -eq "PoweredOn") {
                    Write-Output "---Waiting 5 seconds for $VMName to stop."
                    Start-Sleep 5
                }
            } catch {
                # Add error handling for "Operation "Shutdown VM guest." failed for VM <NMName> for the following reason: Cannot complete operation because VMware Tools is not running in this virtual machine."
                Write-Output "---Virtual Machine: $VMname failed to shutdown gracefully, forcing power off."
                $VM | Stop-VM -Confirm:$false
            }
        } elseif ($VM.PowerState -eq "PoweredOn" -and !$Confirm) {
            Write-Output "Virtual Machine: $VMName must be powered off before continuing! Stopping the script!"
            Exit
        } elseif ($VM.PowerState -eq "PoweredOff") {
            Write-Output "Virtual Machine: $VMName is already powered off."
        }

        # Add temporary disks with the controllers
        Write-Output "---Adding 3 ParaVirtual SCSI controllers."
        $VM | New-HardDisk -CapacityGB 1 | New-ScsiController -Type ParaVirtual | Out-Null -ErrorAction Stop ; Start-Sleep -Seconds 1
        $VM | New-HardDisk -CapacityGB 2 | New-ScsiController -Type ParaVirtual | Out-Null -ErrorAction Stop ; Start-Sleep -Seconds 1
        $VM | New-HardDisk -CapacityGB 3 | New-ScsiController -Type ParaVirtual | Out-Null -ErrorAction Stop ; Start-Sleep -Seconds 1

        # Power on the VM and remove the temporary disks - this is necessary because if the VM is powered off, it will remove the SCSI controllers as well.
        Write-Output "---Starting the virtual machine."
        $VM | Start-VM -Confirm:$false | Out-Null
        while ((Get-VM -Name $VMName).PowerState -eq "PoweredOff") {
            Write-Output "---Waiting 5 seconds for $VMName to start."
            Start-Sleep 5
        }

        # Remove the temporary disks
        Write-Output "---Removing temporary hard disks."
        $VM | Get-HardDisk | Select-Object -Skip 1 | Remove-HardDisk -Confirm:$false -DeletePermanently ; Start-Sleep -Seconds 5

        # Allow the virtual machine to power on completely to attempt graceful shutdown.
        Write-Output "---Allowing $VMName to power on completely to attempt graceful shutdown."
        Start-Sleep -Seconds 30

        # Shutdown the virtual machine once more
        if ((Get-VM $VMName).PowerState -eq "PoweredOn" -and $Confirm) {
            Write-Output "---Shutting down the Virtual Machine: $VMName."
            try {
                $VM | Shutdown-VMGuest -Confirm:$false -ErrorAction Stop | Out-Null
                while ((Get-VM -Name $VMName).PowerState -eq "PoweredOn") {
                    Write-Output "---Waiting 5 seconds for $VMName to stop."
                    Start-Sleep 5
                }
            } catch {
                # Add error handling for "Operation "Shutdown VM guest." failed for VM <NMName> for the following reason: Cannot complete operation because VMware Tools is not running in this virtual machine."
                Write-Output "---Virtual Machine: $VMname failed to shutdown gracefully, forcing power off."
                $VM | Stop-VM -Confirm:$false | Out-Null
            }
        } elseif ((Get-VM -Name $VMName).PowerState -eq "PoweredOn" -and !$Confirm) {
            Write-Output "Virtual Machine: $VMName must be powered off before continuing! Stopping the script!"
            Exit
        } elseif ((Get-VM -Name $VMName).PowerState -eq "PoweredOff") {
            Write-Output "Virtual Machine: $VMName is already powered off."
        }

        # Configure the correct order of the SCSI controllers.
        Write-Output "---Reconfiguring the controllers with appropriate SCSI slot numbers."

        $Table = @(
            @{SCSI = "0"; SlotNumber = "scsi0NewSlotNumber"; Value = "160" },
            @{SCSI = "1"; SlotNumber = "scsi1NewSlotNumber"; Value = "192" },
            @{SCSI = "2"; SlotNumber = "scsi2NewSlotNumber"; Value = "224" },
            @{SCSI = "3"; SlotNumber = "scsi3NewSlotNumber"; Value = "256" }
        ) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }


        $intNewSlotNumber = 1184
        $scsi0NewSlotNumber = 160
        $scsi1NewSlotNumber = 192
        $scsi2NewSlotNumber = 224
        $scsi3NewSlotNumber = 256

        # Network Interface Card
        $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
        $Config.extraConfig = New-Object VMware.Vim.OptionValue[] (1)
        $Config.extraConfig[0] = New-Object VMware.Vim.OptionValue -Property @{
            key   = "ethernet0.pciSlotNumber"
            value = $intNewSlotNumber
        }
        $viewVMToReconfig = Get-View -ViewType VirtualMachine -Property Name -Filter @{"Name" = $VMName }
        $viewVMToReconfig.ReconfigVM_Task($Config) | Out-Null

        # SCSI 0
        $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
        $Config.extraConfig = New-Object VMware.Vim.OptionValue[] (1)
        $Config.extraConfig[0] = New-Object VMware.Vim.OptionValue -Property @{
            key   = "scsi0.pciSlotNumber"
            value = $scsi0NewSlotNumber
        }
        $viewVMToReconfig = Get-View -ViewType VirtualMachine -Property Name -Filter @{"Name" = $VMName }
        $viewVMToReconfig.ReconfigVM_Task($Config) | Out-Null
        Start-Sleep 5

        # SCSI 1
        $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
        $Config.extraConfig = New-Object VMware.Vim.OptionValue[] (1)
        $Config.extraConfig[0] = New-Object VMware.Vim.OptionValue -Property @{
            key   = "scsi1.pciSlotNumber"
            value = $scsi1NewSlotNumber
        }
        $viewVMToReconfig = Get-View -ViewType VirtualMachine -Property Name -Filter @{"Name" = $VMName }
        $viewVMToReconfig.ReconfigVM_Task($Config) | Out-Null
        Start-Sleep 5

        # SCSI 2
        $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
        $Config.extraConfig = New-Object VMware.Vim.OptionValue[] (1)
        $Config.extraConfig[0] = New-Object VMware.Vim.OptionValue -Property @{
            key   = "scsi2.pciSlotNumber"
            value = $scsi2NewSlotNumber
        }
        $viewVMToReconfig = Get-View -ViewType VirtualMachine -Property Name -Filter @{"Name" = $VMName }
        $viewVMToReconfig.ReconfigVM_Task($Config) | Out-Null
        Start-Sleep 5

        # SCSI 3
        $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
        $Config.extraConfig = New-Object VMware.Vim.OptionValue[] (1)
        $Config.extraConfig[0] = New-Object VMware.Vim.OptionValue -Property @{
            key   = "scsi3.pciSlotNumber"
            value = $scsi3NewSlotNumber
        }
        $viewVMToReconfig = Get-View -ViewType VirtualMachine -Property Name -Filter @{"Name" = $VMName }
        $viewVMToReconfig.ReconfigVM_Task($Config) | Out-Null
        Start-Sleep 5
    }

    process {
        # Build the table depending on the number of disks to be added.

        # One disk
        if ($DiskCount -eq 1) {
            $Table = @(
                @{DiskNumber = "1"; DiskSize = "$DiskOneSize"; ControllerKey = "1001"; ControllerUnitNumber = "0" }
            ) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        }
        # Two disks
        if ($DiskCount -eq 2) {
            $Table = @(
                @{DiskNumber = "1"; DiskSize = "$DiskOneSize"; ControllerKey = "1001"; ControllerUnitNumber = "0" },
                @{DiskNumber = "2"; DiskSize = "$DiskTwoSize"; ControllerKey = "1001"; ControllerUnitNumber = "1" }
            ) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        }
        # Three disks
        if ($DiskCount -eq 3) {
            $Table = @(
                @{DiskNumber = "1"; DiskSize = "$DiskOneSize"; ControllerKey = "1001"; ControllerUnitNumber = "0" },
                @{DiskNumber = "2"; DiskSize = "$DiskTwoSize"; ControllerKey = "1001"; ControllerUnitNumber = "1" },
                @{DiskNumber = "3"; DiskSize = "$DiskThreeSize"; ControllerKey = "1002"; ControllerUnitNumber = "0" }
            ) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        }
        # Four disks
        if ($DiskCount -eq 4) {
            $Table = @(
                @{DiskNumber = "1"; DiskSize = "$DiskOneSize"; ControllerKey = "1001"; ControllerUnitNumber = "0" },
                @{DiskNumber = "2"; DiskSize = "$DiskTwoSize"; ControllerKey = "1001"; ControllerUnitNumber = "1" },
                @{DiskNumber = "3"; DiskSize = "$DiskThreeSize"; ControllerKey = "1002"; ControllerUnitNumber = "0" },
                @{DiskNumber = "4"; DiskSize = "$DiskFourSize"; ControllerKey = "1002"; ControllerUnitNumber = "1" }
            ) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        }
        # Five disks
        if ($DiskCount -eq 5) {

            $Table = @(
                @{DiskNumber = "1"; DiskSize = "$DiskOneSize"; ControllerKey = "1001"; ControllerUnitNumber = "0" },
                @{DiskNumber = "2"; DiskSize = "$DiskTwoSize"; ControllerKey = "1001"; ControllerUnitNumber = "1" },
                @{DiskNumber = "3"; DiskSize = "$DiskThreeSize"; ControllerKey = "1002"; ControllerUnitNumber = "0" },
                @{DiskNumber = "4"; DiskSize = "$DiskFourSize"; ControllerKey = "1002"; ControllerUnitNumber = "1" },
                @{DiskNumber = "5"; DiskSize = "$DiskFiveSize"; ControllerKey = "1003"; ControllerUnitNumber = "0" }
            ) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        }
        # Six disks
        if ($DiskCount -eq 6) {
            $Table = @(
                @{DiskNumber = "1"; DiskSize = "$DiskOneSize"; ControllerKey = "1001"; ControllerUnitNumber = "0" },
                @{DiskNumber = "2"; DiskSize = "$DiskTwoSize"; ControllerKey = "1001"; ControllerUnitNumber = "1" },
                @{DiskNumber = "3"; DiskSize = "$DiskThreeSize"; ControllerKey = "1002"; ControllerUnitNumber = "0" },
                @{DiskNumber = "4"; DiskSize = "$DiskFourSize"; ControllerKey = "1002"; ControllerUnitNumber = "1" },
                @{DiskNumber = "5"; DiskSize = "$DiskFiveSize"; ControllerKey = "1003"; ControllerUnitNumber = "0" },
                @{DiskNumber = "6"; DiskSize = "$DiskSixSize"; ControllerKey = "1003"; ControllerUnitNumber = "1" }
            ) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        }
        # Seven disks
        if ($DiskCount -eq 7) {
            $Table = @(
                @{DiskNumber = "1"; DiskSize = "$DiskOneSize"; ControllerKey = "1001"; ControllerUnitNumber = "0" },
                @{DiskNumber = "2"; DiskSize = "$DiskTwoSize"; ControllerKey = "1001"; ControllerUnitNumber = "1" },
                @{DiskNumber = "3"; DiskSize = "$DiskThreeSize"; ControllerKey = "1001"; ControllerUnitNumber = "2" },
                @{DiskNumber = "4"; DiskSize = "$DiskFourSize"; ControllerKey = "1002"; ControllerUnitNumber = "0" },
                @{DiskNumber = "5"; DiskSize = "$DiskFiveSize"; ControllerKey = "1002"; ControllerUnitNumber = "1" },
                @{DiskNumber = "6"; DiskSize = "$DiskSixSize"; ControllerKey = "1002"; ControllerUnitNumber = "2" },
                @{DiskNumber = "7"; DiskSize = "$DiskSevenSize"; ControllerKey = "1003"; ControllerUnitNumber = "0" }
            ) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        }
        # Eight disks
        if ($DiskCount -eq 8) {
            $Table = @(
                @{DiskNumber = "1"; DiskSize = "$DiskOneSize"; ControllerKey = "1001"; ControllerUnitNumber = "0" },
                @{DiskNumber = "2"; DiskSize = "$DiskTwoSize"; ControllerKey = "1001"; ControllerUnitNumber = "1" },
                @{DiskNumber = "3"; DiskSize = "$DiskThreeSize"; ControllerKey = "1001"; ControllerUnitNumber = "2" },
                @{DiskNumber = "4"; DiskSize = "$DiskFourSize"; ControllerKey = "1002"; ControllerUnitNumber = "0" },
                @{DiskNumber = "5"; DiskSize = "$DiskFiveSize"; ControllerKey = "1002"; ControllerUnitNumber = "1" },
                @{DiskNumber = "6"; DiskSize = "$DiskSixSize"; ControllerKey = "1002"; ControllerUnitNumber = "2" },
                @{DiskNumber = "7"; DiskSize = "$DiskSevenSize"; ControllerKey = "1003"; ControllerUnitNumber = "0" },
                @{DiskNumber = "8"; DiskSize = "$DiskEightSize"; ControllerKey = "1003"; ControllerUnitNumber = "1" }
            ) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        }
        # Nine disks
        if ($DiskCount -eq 9) {
            $Table = @(
                @{DiskNumber = "1"; DiskSize = "$DiskOneSize"; ControllerKey = "1001"; ControllerUnitNumber = "0" },
                @{DiskNumber = "2"; DiskSize = "$DiskTwoSize"; ControllerKey = "1001"; ControllerUnitNumber = "1" },
                @{DiskNumber = "3"; DiskSize = "$DiskThreeSize"; ControllerKey = "1001"; ControllerUnitNumber = "2" },
                @{DiskNumber = "4"; DiskSize = "$DiskFourSize"; ControllerKey = "1002"; ControllerUnitNumber = "0" },
                @{DiskNumber = "5"; DiskSize = "$DiskFiveSize"; ControllerKey = "1002"; ControllerUnitNumber = "1" },
                @{DiskNumber = "6"; DiskSize = "$DiskSixSize"; ControllerKey = "1002"; ControllerUnitNumber = "2" }
                @{DiskNumber = "7"; DiskSize = "$DiskSevenSize"; ControllerKey = "1003"; ControllerUnitNumber = "0" },
                @{DiskNumber = "8"; DiskSize = "$DiskEightSize"; ControllerKey = "1003"; ControllerUnitNumber = "1" },
                @{DiskNumber = "9"; DiskSize = "$DiskNineSize"; ControllerKey = "1003"; ControllerUnitNumber = "2" }
            ) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        }
        # Ten disks
        if ($DiskCount -eq 10) {
            $Table = @(
                @{DiskNumber = "1"; DiskSize = "$DiskOneSize"; ControllerKey = "1001"; ControllerUnitNumber = "0" },
                @{DiskNumber = "2"; DiskSize = "$DiskTwoSize"; ControllerKey = "1001"; ControllerUnitNumber = "1" },
                @{DiskNumber = "3"; DiskSize = "$DiskThreeSize"; ControllerKey = "1001"; ControllerUnitNumber = "2" },
                @{DiskNumber = "4"; DiskSize = "$DiskFourSize"; ControllerKey = "1001"; ControllerUnitNumber = "3" },
                @{DiskNumber = "5"; DiskSize = "$DiskFiveSize"; ControllerKey = "1002"; ControllerUnitNumber = "0" },
                @{DiskNumber = "6"; DiskSize = "$DiskSixSize"; ControllerKey = "1002"; ControllerUnitNumber = "1" },
                @{DiskNumber = "7"; DiskSize = "$DiskSevenSize"; ControllerKey = "1002"; ControllerUnitNumber = "2" },
                @{DiskNumber = "8"; DiskSize = "$DiskEightSize"; ControllerKey = "1002"; ControllerUnitNumber = "3" },
                @{DiskNumber = "9"; DiskSize = "$DiskNineSize"; ControllerKey = "1003"; ControllerUnitNumber = "0" },
                @{DiskNumber = "10"; DiskSize = "$DiskTenSize"; ControllerKey = "1003"; ControllerUnitNumber = "1" }
            ) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        }
        # Eleven disks
        if ($DiskCount -eq 11) {
            $Table = @(
                @{DiskNumber = "1"; DiskSize = "$DiskOneSize"; ControllerKey = "1001"; ControllerUnitNumber = "0" },
                @{DiskNumber = "2"; DiskSize = "$DiskTwoSize"; ControllerKey = "1001"; ControllerUnitNumber = "1" },
                @{DiskNumber = "3"; DiskSize = "$DiskThreeSize"; ControllerKey = "1001"; ControllerUnitNumber = "2" },
                @{DiskNumber = "4"; DiskSize = "$DiskFourSize"; ControllerKey = "1001"; ControllerUnitNumber = "3" },
                @{DiskNumber = "5"; DiskSize = "$DiskFiveSize"; ControllerKey = "1002"; ControllerUnitNumber = "0" },
                @{DiskNumber = "6"; DiskSize = "$DiskSixSize"; ControllerKey = "1002"; ControllerUnitNumber = "1" },
                @{DiskNumber = "7"; DiskSize = "$DiskSevenSize"; ControllerKey = "1002"; ControllerUnitNumber = "2" },
                @{DiskNumber = "8"; DiskSize = "$DiskEightSize"; ControllerKey = "1002"; ControllerUnitNumber = "3" },
                @{DiskNumber = "9"; DiskSize = "$DiskNineSize"; ControllerKey = "1003"; ControllerUnitNumber = "0" },
                @{DiskNumber = "10"; DiskSize = "$DiskTenSize"; ControllerKey = "1003"; ControllerUnitNumber = "1" },
                @{DiskNumber = "11"; DiskSize = "$DiskElevenSize"; ControllerKey = "1003"; ControllerUnitNumber = "2" }
            ) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        }
        # Twelve disks
        if ($DiskCount -eq 12) {
            $Table = @(
                @{DiskNumber = "1"; DiskSize = "$DiskOneSize"; ControllerKey = "1001"; ControllerUnitNumber = "0" },
                @{DiskNumber = "2"; DiskSize = "$DiskTwoSize"; ControllerKey = "1001"; ControllerUnitNumber = "1" },
                @{DiskNumber = "3"; DiskSize = "$DiskThreeSize"; ControllerKey = "1001"; ControllerUnitNumber = "2" },
                @{DiskNumber = "4"; DiskSize = "$DiskFourSize"; ControllerKey = "1001"; ControllerUnitNumber = "3" },
                @{DiskNumber = "5"; DiskSize = "$DiskFiveSize"; ControllerKey = "1002"; ControllerUnitNumber = "0" },
                @{DiskNumber = "6"; DiskSize = "$DiskSixSize"; ControllerKey = "1002"; ControllerUnitNumber = "1" },
                @{DiskNumber = "7"; DiskSize = "$DiskSevenSize"; ControllerKey = "1002"; ControllerUnitNumber = "2" },
                @{DiskNumber = "8"; DiskSize = "$DiskEightSize"; ControllerKey = "1002"; ControllerUnitNumber = "3" },
                @{DiskNumber = "9"; DiskSize = "$DiskNineSize"; ControllerKey = "1003"; ControllerUnitNumber = "0" },
                @{DiskNumber = "10"; DiskSize = "$DiskTenSize"; ControllerKey = "1003"; ControllerUnitNumber = "1" },
                @{DiskNumber = "11"; DiskSize = "$DiskElevenSize"; ControllerKey = "1003"; ControllerUnitNumber = "2" },
                @{DiskNumber = "12"; DiskSize = "$DiskTwelveSize"; ControllerKey = "1003"; ControllerUnitNumber = "3" }
            ) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        }
        # Thirteen disks
        if ($DiskCount -eq 13) {
            $Table = @(
                @{DiskNumber = "1"; DiskSize = "$DiskOneSize"; ControllerKey = "1001"; ControllerUnitNumber = "0" },
                @{DiskNumber = "2"; DiskSize = "$DiskTwoSize"; ControllerKey = "1001"; ControllerUnitNumber = "1" },
                @{DiskNumber = "3"; DiskSize = "$DiskThreeSize"; ControllerKey = "1001"; ControllerUnitNumber = "2" },
                @{DiskNumber = "4"; DiskSize = "$DiskFourSize"; ControllerKey = "1001"; ControllerUnitNumber = "3" },
                @{DiskNumber = "5"; DiskSize = "$DiskFiveSize"; ControllerKey = "1001"; ControllerUnitNumber = "4" },
                @{DiskNumber = "6"; DiskSize = "$DiskSixSize"; ControllerKey = "1002"; ControllerUnitNumber = "0" },
                @{DiskNumber = "7"; DiskSize = "$DiskSevenSize"; ControllerKey = "1002"; ControllerUnitNumber = "1" },
                @{DiskNumber = "8"; DiskSize = "$DiskEightSize"; ControllerKey = "1002"; ControllerUnitNumber = "2" },
                @{DiskNumber = "9"; DiskSize = "$DiskNineSize"; ControllerKey = "1002"; ControllerUnitNumber = "3" },
                @{DiskNumber = "10"; DiskSize = "$DiskTenSize"; ControllerKey = "1002"; ControllerUnitNumber = "4" },
                @{DiskNumber = "11"; DiskSize = "$DiskElevenSize"; ControllerKey = "1003"; ControllerUnitNumber = "0" },
                @{DiskNumber = "12"; DiskSize = "$DiskTwelveSize"; ControllerKey = "1003"; ControllerUnitNumber = "1" },
                @{DiskNumber = "13"; DiskSize = "$DiskThirteenSize"; ControllerKey = "1003"; ControllerUnitNumber = "2" }
            ) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        }
        # Fourteen disks
        if ($DiskCount -eq 14) {
            $Table = @(
                @{DiskNumber = "1"; DiskSize = "$DiskOneSize"; ControllerKey = "1001"; ControllerUnitNumber = "0" },
                @{DiskNumber = "2"; DiskSize = "$DiskTwoSize"; ControllerKey = "1001"; ControllerUnitNumber = "1" },
                @{DiskNumber = "3"; DiskSize = "$DiskThreeSize"; ControllerKey = "1001"; ControllerUnitNumber = "2" },
                @{DiskNumber = "4"; DiskSize = "$DiskFourSize"; ControllerKey = "1001"; ControllerUnitNumber = "3" },
                @{DiskNumber = "5"; DiskSize = "$DiskFiveSize"; ControllerKey = "1001"; ControllerUnitNumber = "4" },
                @{DiskNumber = "6"; DiskSize = "$DiskSixSize"; ControllerKey = "1002"; ControllerUnitNumber = "0" },
                @{DiskNumber = "7"; DiskSize = "$DiskSevenSize"; ControllerKey = "1002"; ControllerUnitNumber = "1" },
                @{DiskNumber = "8"; DiskSize = "$DiskEightSize"; ControllerKey = "1002"; ControllerUnitNumber = "2" },
                @{DiskNumber = "9"; DiskSize = "$DiskNineSize"; ControllerKey = "1002"; ControllerUnitNumber = "3" },
                @{DiskNumber = "10"; DiskSize = "$DiskTenSize"; ControllerKey = "1002"; ControllerUnitNumber = "4" },
                @{DiskNumber = "11"; DiskSize = "$DiskElevenSize"; ControllerKey = "1003"; ControllerUnitNumber = "0" },
                @{DiskNumber = "12"; DiskSize = "$DiskTwelveSize"; ControllerKey = "1003"; ControllerUnitNumber = "1" },
                @{DiskNumber = "13"; DiskSize = "$DiskThirteenSize"; ControllerKey = "1003"; ControllerUnitNumber = "2" },
                @{DiskNumber = "14"; DiskSize = "$DiskFourteenSize"; ControllerKey = "1003"; ControllerUnitNumber = "3" }
            ) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        }
        # Fifteen disks
        if ($DiskCount -eq 15) {
            $Table = @(
                @{DiskNumber = "1"; DiskSize = "$DiskOneSize"; ControllerKey = "1001"; ControllerUnitNumber = "0" },
                @{DiskNumber = "2"; DiskSize = "$DiskTwoSize"; ControllerKey = "1001"; ControllerUnitNumber = "1" },
                @{DiskNumber = "3"; DiskSize = "$DiskThreeSize"; ControllerKey = "1001"; ControllerUnitNumber = "2" },
                @{DiskNumber = "4"; DiskSize = "$DiskFourSize"; ControllerKey = "1001"; ControllerUnitNumber = "3" },
                @{DiskNumber = "5"; DiskSize = "$DiskFiveSize"; ControllerKey = "1001"; ControllerUnitNumber = "4" },
                @{DiskNumber = "6"; DiskSize = "$DiskSixSize"; ControllerKey = "1002"; ControllerUnitNumber = "0" },
                @{DiskNumber = "7"; DiskSize = "$DiskSevenSize"; ControllerKey = "1002"; ControllerUnitNumber = "1" },
                @{DiskNumber = "8"; DiskSize = "$DiskEightSize"; ControllerKey = "1002"; ControllerUnitNumber = "2" },
                @{DiskNumber = "9"; DiskSize = "$DiskNineSize"; ControllerKey = "1002"; ControllerUnitNumber = "3" },
                @{DiskNumber = "10"; DiskSize = "$DiskTenSize"; ControllerKey = "1002"; ControllerUnitNumber = "4" },
                @{DiskNumber = "11"; DiskSize = "$DiskElevenSize"; ControllerKey = "1003"; ControllerUnitNumber = "0" },
                @{DiskNumber = "12"; DiskSize = "$DiskTwelveSize"; ControllerKey = "1003"; ControllerUnitNumber = "1" },
                @{DiskNumber = "13"; DiskSize = "$DiskThirteenSize"; ControllerKey = "1003"; ControllerUnitNumber = "2" },
                @{DiskNumber = "14"; DiskSize = "$DiskFourteenSize"; ControllerKey = "1003"; ControllerUnitNumber = "3" },
                @{DiskNumber = "15"; DiskSize = "$DiskFifteenSize"; ControllerKey = "1003"; ControllerUnitNumber = "4" }
            ) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        }
        # Add the disks
        Write-Output "---Adding $($DiskCount) disks to: $VMName."

        foreach ($Disk in $Table) {
            try {
                if ($EagerZeroedThick) {
                    $VM | New-HardDisk -CapacityGB $Disk.DiskSize -StorageFormat EagerZeroedThick -ErrorAction Stop | Out-Null
                } elseif (!$EagerZeroedThick) {
                    $VM | New-HardDisk -CapacityGB $Disk.DiskSize -ErrorAction Stop | Out-Null
                }
                Start-Sleep -Seconds 5
                $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                $Config.deviceChange[0].operation = "edit"
                $Config.deviceChange[0].device = $HardDisk.ExtensionData
                $Config.deviceChange[0].device.ControllerKey = $Disk.ControllerKey
                $Config.deviceChange[0].device.UnitNumber = $Disk.ControllerUnitNumber
                $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                Start-Sleep -Seconds 5
                if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                    Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                    Exit
                }
            } catch {
                Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                Exit
            }
        }
    }

    end {
        Write-Output "---Added the following disks:"
        $VM | Get-HardDisk | Select-Object Parent, Name, DiskType, StorageFormat, CapacityGB, @{n = "ExtensionData"; e = { ($_.ExtensionData.ControllerKey) ; ($_.ExtensionData.UnitNumber) } } -Skip 1 | Format-Table -AutoSize
        Write-Output "---Starting the virtual machine."
        $VM | Start-VM -Confirm:$false | Out-Null
        while ((Get-VM -Name $VMName).PowerState -eq "PoweredOff") {
            Write-Output "---Waiting 5 seconds for $VMName to start."
            Start-Sleep 5
        }
    }
}
