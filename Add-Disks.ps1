function Add-Disks {
    <#
.SYNOPSIS
    Adds virtual disks to vSphere VM and configures them with appropriate controllers and unit numbers.
.DESCRIPTION
    Adds virtual disks to vSphere VM and configures them with appropriate controllers and keys.
    The script looks for the specified VM, and sets up configuration for each added disk, distributing them amongst all added SCSI controllers, each disk is added one by one and then configured with the first available controller and unit number.
    Supports a maximum of 15 disks added.
.PARAMETER VMName
    Name of the virtual machine to configure.
.PARAMETER Confirm
    Switch to disable confirmation prompt to shutdown the VM. If -Confirm is present, the VM will be automatically shutdown, this is required to re-configure the disk.
.EXAMPLE
    Add-Disks -VMName <Name> -Confirm -DiskOneSize 1 -DiskTwoSize 2 -DiskThreeSize 3 -DiskFourSize 4 -DiskFiveSize 5 -DiskSixSize 6

    Adds 6 virtual disks to the specified VM, and confirms the VM to be shutdown so it doesn't ask you, useful for automatic procedure.
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
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$VMName,
        [Parameter(Mandatory = $false, Position = 2)]
        [switch]$Confirm,
        [Parameter(Mandatory = $false, Position = 3)]
        [int64]$DiskOneSize,
        [Parameter(Mandatory = $false, Position = 4)]
        [int64]$DiskTwoSize,
        [Parameter(Mandatory = $false, Position = 5)]
        [int64]$DiskThreeSize,
        [Parameter(Mandatory = $false, Position = 6)]
        [int64]$DiskFourSize,
        [Parameter(Mandatory = $false, Position = 7)]
        [int64]$DiskFiveSize,
        [Parameter(Mandatory = $false, Position = 8)]
        [int64]$DiskSixSize,
        [Parameter(Mandatory = $false, Position = 9)]
        [int64]$DiskSevenSize,
        [Parameter(Mandatory = $false, Position = 10)]
        [int64]$DiskEightSize,
        [Parameter(Mandatory = $false, Position = 11)]
        [int64]$DiskNineSize,
        [Parameter(Mandatory = $false, Position = 12)]
        [int64]$DiskTenSize,
        [Parameter(Mandatory = $false, Position = 13)]
        [int64]$DiskElevenSize,
        [Parameter(Mandatory = $false, Position = 14)]
        [int64]$DiskTwelveSize,
        [Parameter(Mandatory = $false, Position = 15)]
        [int64]$DiskThirteenSize,
        [Parameter(Mandatory = $false, Position = 16)]
        [int64]$DiskFourteenSize,
        [Parameter(Mandatory = $false, Position = 17)]
        [int64]$DiskFifteenSize
    )

    begin {
        # This line is necessary because one parameter is always present, the -VMName parameter.
        $DiskCount = $PSBoundParameters.Count - 1
        # This line is necessary because having the -Confirm parameter needs to be accounted for in the disk count, this means if both - the -VMName and -Confirm parameters are present and no Disk<int64>Size parameters are present, the DiskCount is always 0.
        if ($Confirm) {
            $DiskCount -= 1
        }
        Write-Output "Adding $($DiskCount) disks to: $VMName"
        # Shutdown VM
        $VM = Get-VM -Name $VMName -ErrorAction Stop
        if ($VM.PowerState -eq "PoweredOn" -and $Confirm) {
            Write-Output "---Shutting down the Virtual Machine: $VMName"
            try {
                $VM | Shutdown-VMGuest -Confirm:$false
                while ((Get-VM -Name $VMName).PowerState -eq "PoweredOn") {
                    Write-Output "---Waiting 5 seconds for $VMName to stop"
                    Start-Sleep 5
                }
            } catch {
                #Add error handling for "Operation "Shutdown VM guest." failed for VM "sql-001-p-p" for the following reason: Cannot complete operation because VMware Tools is not running in this virtual machine."
            }
        } elseif ($VM.PowerState -eq "PoweredOn" -and !$Confirm) {
            Write-Output "Virtual Machine: $VMName must be powered off before continuing! Stopping the script!"
            Exit
        } elseif ($VM.PowerState -eq "PoweredOff") {
            Write-Output "Virtual Machine: $VMName is already powered off"
        }
    }

    process {
        # One disk
        if ($DiskCount -eq 1) {
            if ($DiskOneSize) {
                try {
                    $VM | New-HardDisk -CapacityGB $DiskOneSize
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
        }
        # Two disks
        if ($DiskCount -eq 2) {
            if ($DiskOneSize) {
                try {
                    $VM | New-HardDisk -CapacityGB $DiskOneSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwoSize
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
        }
        # Three disks
        if ($DiskCount -eq 3) {
            if ($DiskOneSize) {
                try {
                    $VM | New-HardDisk -CapacityGB $DiskOneSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwoSize
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
            if ($DiskThreeSize) {
                try {
                    $VM | New-HardDisk -CapacityGB $DiskThreeSize
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
        # Four disks
        if ($DiskCount -eq 4) {
            if ($DiskOneSize) {
                try {
                    $VM | New-HardDisk -CapacityGB $DiskOneSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwoSize
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
                    $VM | New-HardDisk -CapacityGB $DiskThreeSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFourSize
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
                    $VM | New-HardDisk -CapacityGB $DiskOneSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwoSize
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
                    $VM | New-HardDisk -CapacityGB $DiskThreeSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFourSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFiveSize
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
                    $VM | New-HardDisk -CapacityGB $DiskOneSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwoSize
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
                    $VM | New-HardDisk -CapacityGB $DiskThreeSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFourSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFiveSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSixSize
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
                    $VM | New-HardDisk -CapacityGB $DiskOneSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwoSize
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
                    $VM | New-HardDisk -CapacityGB $DiskThreeSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFourSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFiveSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSixSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSevenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskOneSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwoSize
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
                    $VM | New-HardDisk -CapacityGB $DiskThreeSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFourSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFiveSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSixSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSevenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskEightSize
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
                    $VM | New-HardDisk -CapacityGB $DiskOneSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwoSize
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
                    $VM | New-HardDisk -CapacityGB $DiskThreeSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFourSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFiveSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSixSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSevenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskEightSize
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
                    $VM | New-HardDisk -CapacityGB $DiskNineSize
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
                    $VM | New-HardDisk -CapacityGB $DiskOneSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwoSize
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
                    $VM | New-HardDisk -CapacityGB $DiskThreeSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFourSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFiveSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSixSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSevenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskEightSize
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
                    $VM | New-HardDisk -CapacityGB $DiskNineSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTenSize
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
        # Eleven disks
        if ($DiskCount -eq 11) {
            if ($DiskOneSize) {
                try {
                    $VM | New-HardDisk -CapacityGB $DiskOneSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwoSize
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
                    $VM | New-HardDisk -CapacityGB $DiskThreeSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFourSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFiveSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSixSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSevenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskEightSize
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
                    $VM | New-HardDisk -CapacityGB $DiskNineSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskElevenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskOneSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwoSize
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
                    $VM | New-HardDisk -CapacityGB $DiskThreeSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFourSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFiveSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSixSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSevenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskEightSize
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
                    $VM | New-HardDisk -CapacityGB $DiskNineSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskElevenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwelveSize
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
                    $VM | New-HardDisk -CapacityGB $DiskOneSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwoSize
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
                    $VM | New-HardDisk -CapacityGB $DiskThreeSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFourSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFiveSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSixSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSevenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskEightSize
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
                    $VM | New-HardDisk -CapacityGB $DiskNineSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskElevenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwelveSize
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
                    $VM | New-HardDisk -CapacityGB $DiskThirteenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskOneSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwoSize
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
                    $VM | New-HardDisk -CapacityGB $DiskThreeSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFourSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFiveSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSixSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSevenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskEightSize
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
                    $VM | New-HardDisk -CapacityGB $DiskNineSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskElevenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwelveSize
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
                    $VM | New-HardDisk -CapacityGB $DiskThirteenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFourteenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskOneSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwoSize
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
                    $VM | New-HardDisk -CapacityGB $DiskThreeSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFourSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFiveSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSixSize
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
                    $VM | New-HardDisk -CapacityGB $DiskSevenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskEightSize
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
                    $VM | New-HardDisk -CapacityGB $DiskNineSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskElevenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskTwelveSize
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
                    $VM | New-HardDisk -CapacityGB $DiskThirteenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFourteenSize
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
                    $VM | New-HardDisk -CapacityGB $DiskFifteenSize
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
        $VM | Get-HardDisk | Select-Object Parent, Name, DiskType, DeviceName, CapacityGB, @{n = "ExtensionData"; e = { ($_.ExtensionData.ControllerKey) ; ($_.ExtensionData.UnitNumber) } } -Skip 1 | Format-Table -AutoSize
        Write-Output "---Starting the VM"
        $VM | Start-VM -Confirm:$false
        while ((Get-VM -Name $VMName).PowerState -eq "PoweredOff") {
            Write-Output "---Waiting 5 seconds for $VMName to start."
            Start-Sleep 5
        }
    }
}
