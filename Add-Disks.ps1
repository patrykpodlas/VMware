function Add-Disks {
    <#
.SYNOPSIS
    Adds virtual disks to vSphere VM and configures them with appropriate controllers and unit numbers.
.DESCRIPTION
    Adds virtual disks to vSphere VM and configures them with appropriate controllers and keys.
    The script looks for the specified VM, and sets up configuration for each added disk, distributing them amongst all added SCSI controllers, each disk is added one by one and then configured with the first available controller and unit number.
    Two disks per controller in the right order.
.PARAMETER VMName
    Name of the virtual machine to configure.
.NOTES
    Author: Patryk Podlas
    Created: 13/01/2023

    Change history:
    Date            Author      V       Notes
    13/01/2023      PP          1.0     First release
    18/01/2023      PP          1.1     Update
    20/01/2023      PP          1.2     Update - Added more error handling, must add disk 7/8 (they don't match up in Windows if added to controllers 1:2 and 2:2)
#>

    [CmdletBinding()]
    param (
        [string]$VMName,
        [switch]$Confirm,
        [int64]$DiskOneSize = 1,
        [int64]$DiskTwoSize = 2,
        [int64]$DiskThreeSize = 3,
        [int64]$DiskFourSize = 4,
        [int64]$DiskFiveSize = 5,
        [int64]$DiskSixSize = 6,
        [int64]$DiskSevenSize = 7,
        [int64]$DiskEightSize = 8
    )

    begin {
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

        Write-Output "Adding disks to: $VMName"

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
        if ($DiskSevenSize) {
            try {
                $VM | New-HardDisk -CapacityGB $DiskSevenSize
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

    end {
        Write-Output "---Added the following disks:"
        $VM | Get-HardDisk | Select-Object Parent, Name, DiskType, DeviceName, CapacityGB, @{n = "ExtensionData"; e = { ($_.ExtensionData.ControllerKey) ; ($_.ExtensionData.UnitNumber) } } | Format-Table -AutoSize
        Write-Output "---Starting the VM"
        $VM | Start-VM -Confirm:$false
        while ((Get-VM -Name $VMName).PowerState -eq "PoweredOff") {
            Write-Output "---Waiting 5 seconds for $VMName to start."
            Start-Sleep 5
        }
    }
}
