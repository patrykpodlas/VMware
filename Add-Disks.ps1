function Add-Disks {
    <#
.SYNOPSIS
    Adds virtual disks to vSphere VM and configures them with appropriate controllers and keys.
.DESCRIPTION
    Adds virtual disks to vSphere VM and configures them with appropriate controllers and keys.
    The script looks for the specified VM, and sets up configuration for each added disk, distributing them amongst all added SCSI controllers, each disk is added one by one and then configured with the first available controller and key.
    Two disks per controller in the right order.
.PARAMETER VMName
    Name of the virtual machine to configure.
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.NOTES
    Author: Patryk Podlas
    Created: 13/01/2023

    Change history:
    Date            Author      V       Notes
    13/01/2023      PP          1.0     First release
    18/01/2023      PP          1.1     Update
#>

    [CmdletBinding()]
    param (
        [string]$VMName
    )

    begin {
        # Shutdown VM
        $VM = Get-VM -Name $VMName
        if ($VM.PowerState -eq "PoweredOn") {
            Write-Output "---Shutting down the Virtual Machine: $VMName"
            $VM | Shutdown-VMGuest -Confirm:$false
            while ((Get-VM -Name $VMName).PowerState -eq "PoweredOn") {
                Write-Output "---Waiting 5 seconds for $VMName to stop"
                Start-Sleep 5
            }
        } elseif ($VM.PowerState -eq "PoweredOff") {
            Write-Output "Virtual Machine: $VM.Name is already powered off"
        }
    }

    process {

        Write-Output "Adding disks to: $VM.Name"

        try {
            $VM | New-HardDisk -CapacityGB 1
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
        } catch {
            <#Do this if a terminating exception happens#>
        }
        try {
            $VM | New-HardDisk -CapacityGB 2
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
        } catch {
            <#Do this if a terminating exception happens#>
        }
        try {
            $VM | New-HardDisk -CapacityGB 3
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
        } catch {
            <#Do this if a terminating exception happens#>
        }
        try {
            $VM | New-HardDisk -CapacityGB 4
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
        } catch {
            <#Do this if a terminating exception happens#>
        }
        try {
            $VM | New-HardDisk -CapacityGB 5
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
        } catch {
            <#Do this if a terminating exception happens#>
        }
        try {
            $VM | New-HardDisk -CapacityGB 6
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
        } catch {
            <#Do this if a terminating exception happens#>
        }
    }

    end {
        Write-Output "---Added the following disks:"
        $VM | Get-HardDisk | Select-Object Parent, Name, DiskType, DeviceName, CapacityGB, @{n = "ExtensionData"; e = { ($_.ExtensionData.ControllerKey) ; ($_.ExtensionData.UnitNumber) } } | Format-Table -AutoSize
        Write-Output "---Starting the VM"
        $VM | Start-VM -Confirm:$false
    }
}
