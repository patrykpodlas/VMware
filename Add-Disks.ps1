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
        Write-Output "---Adding SCSI controllers."
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
        Write-Output "---Allowing $VMName to power on completely to attempt gracefull shutdown."
        Start-Sleep -Seconds 30

        # Shutdown the virtual machine once more
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
                $VM | Stop-VM -Confirm:$false | Out-Null
            }
        } elseif ($VM.PowerState -eq "PoweredOn" -and !$Confirm) {
            Write-Output "Virtual Machine: $VMName must be powered off before continuing! Stopping the script!"
            Exit
        } elseif ($VM.PowerState -eq "PoweredOff") {
            Write-Output "Virtual Machine: $VMName is already powered off."
        }

        # Configure the correct order of the SCSI controllers.
        Write-Output "---Reconfiguring the controllers with appropriate SCSI slot numbers."
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
        Write-Output "---Adding $($DiskCount) disks to: $VMName."
        # One disk
        if ($DiskCount -eq 1) {
            if ($DiskOneSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
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
        # Two disks
        if ($DiskCount -eq 2) {
            if ($DiskOneSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                    Exit
                }
            }
            if ($DiskTwoSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
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
        # Three disks
        if ($DiskCount -eq 3) {
            if ($DiskOneSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                    Exit
                }
            }
            if ($DiskTwoSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                    Exit
                }
            }
            if ($DiskThreeSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
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
        # Four disks
        if ($DiskCount -eq 4) {
            if ($DiskOneSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                    Exit
                }
            }
            if ($DiskTwoSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskThreeSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFourSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
        }
        # Five disks
        if ($DiskCount -eq 5) {
            if ($DiskOneSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTwoSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskThreeSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFourSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFiveSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
        }
        # Six disks
        if ($DiskCount -eq 6) {
            if ($DiskOneSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTwoSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskThreeSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFourSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFiveSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSixSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
        }
        # Seven disks
        if ($DiskCount -eq 7) {
            if ($DiskOneSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTwoSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskThreeSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFourSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFiveSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize -StorageFormat EagerZeroedThick
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSixSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSevenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
        }
        # Eight disks
        if ($DiskCount -eq 8) {
            if ($DiskOneSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTwoSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskThreeSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFourSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFiveSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSixSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSevenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskEightSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskEightSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskEightSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
        }
        # Nine disks
        if ($DiskCount -eq 9) {
            if ($DiskOneSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTwoSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskThreeSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFourSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFiveSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSixSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSevenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskEightSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskEightSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskEightSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskNineSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskNineSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskNineSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
        }
        # Ten disks
        if ($DiskCount -eq 10) {
            if ($DiskOneSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTwoSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskThreeSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFourSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "3"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFiveSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSixSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSevenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskEightSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskEightSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskEightSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "3"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskNineSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskNineSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskNineSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
        }
        # Eleven disks
        if ($DiskCount -eq 11) {
            if ($DiskOneSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTwoSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskThreeSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFourSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "3"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFiveSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSixSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSevenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskEightSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskEightSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskEightSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "3"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskNineSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskNineSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskNineSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskElevenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskElevenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskElevenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "3"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
        }
        # Twelve disks
        if ($DiskCount -eq 12) {
            if ($DiskOneSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTwoSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskThreeSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFourSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "3"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFiveSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "4"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSixSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSevenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskEightSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskEightSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskEightSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskNineSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskNineSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskNineSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "3"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "4"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskElevenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskElevenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskElevenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTwelveSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwelveSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwelveSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
        }
        # Thirteen disks
        if ($DiskCount -eq 13) {
            if ($DiskOneSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTwoSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskThreeSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFourSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "3"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFiveSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "4"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSixSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSevenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskEightSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskEightSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskEightSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskNineSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskNineSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskNineSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "3"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "4"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskElevenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskElevenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskElevenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTwelveSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwelveSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwelveSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskThirteenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskThirteenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskThirteenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
        }
        # Fourteen disks
        if ($DiskCount -eq 14) {
            if ($DiskOneSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTwoSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskThreeSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFourSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "3"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFiveSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "4"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSixSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSevenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskEightSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskEightSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskEightSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskNineSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskNineSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskNineSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "3"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "4"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskElevenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskElevenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskElevenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTwelveSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwelveSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwelveSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskThirteenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskThirteenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskThirteenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFourteenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFourteenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFourteenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "3"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
        }
        # Fifteen disks
        if ($DiskCount -eq 15) {
            if ($DiskOneSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskOneSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTwoSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwoSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskThreeSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskThreeSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFourSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize -StorageFormat EagerZeroedThick -ErrorAction "Stop" | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFourSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "3"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFiveSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFiveSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1001"
                    $Config.deviceChange[0].device.UnitNumber = "4"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSixSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSixSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskSevenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskSevenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskEightSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskEightSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskEightSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskNineSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskNineSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskNineSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "3"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1002"
                    $Config.deviceChange[0].device.UnitNumber = "4"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskElevenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskElevenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskElevenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "0"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskTwelveSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskTwelveSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskTwelveSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "1"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskThirteenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskThirteenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskThirteenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "2"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFourteenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFourteenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFourteenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "3"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
            }
            if ($DiskFifteenSize) {
                try {
                    if ($EagerZeroedThick) {
                        $VM | New-HardDisk -CapacityGB $DiskFifteenSize -StorageFormat EagerZeroedThick | Out-Null
                    } else {
                        $VM | New-HardDisk -CapacityGB $DiskFifteenSize | Out-Null
                    }
                    Start-Sleep 5
                    $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
                    $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
                    $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $Config.deviceChange[0].operation = "edit"
                    $Config.deviceChange[0].device = $HardDisk.ExtensionData
                    $Config.deviceChange[0].device.ControllerKey = "1003"
                    $Config.deviceChange[0].device.UnitNumber = "4"
                    $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
                    Start-Sleep 5
                    if ((Get-Task | Select-Object -Last 1).State -eq "Error") {
                        Write-Output "Adding $HardDisk has failed! Check VM's event logs for more details, terminating the script."
                        Exit
                    }
                } catch {
                    Exit
                }
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
