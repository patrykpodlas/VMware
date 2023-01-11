<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Detailed description
.PARAMETER <name>
    Parameter explanation
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.NOTES
    Author:
    Created:

    Change history:
    Date            Author      V       Notes
    01/02/2022      II          1.0     First release
#>
function Add-Disks {
    [CmdletBinding()]
    param (
        [string]$VMName
    )

    begin {
        $VM = Get-VM -Name $VMName
        Write-Output "Adding disks to: $VM.Name"
    }

    process {
        $VM | New-HardDisk -CapacityGB 1
        $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
        $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
        $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
        $Config.deviceChange[0].operation = "edit"
        $Config.deviceChange[0].device = $HardDisk.ExtensionData
        $Config.deviceChange[0].device.ControllerKey = "1001"
        $Config.deviceChange[0].device.UnitNumber = "0"
        $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
        Start-Sleep 5

        $VM | New-HardDisk -CapacityGB 2
        $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
        $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
        $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
        $Config.deviceChange[0].operation = "edit"
        $Config.deviceChange[0].device = $HardDisk.ExtensionData
        $Config.deviceChange[0].device.ControllerKey = "1002"
        $Config.deviceChange[0].device.UnitNumber = "0"
        $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
        Start-Sleep 5

        $VM | New-HardDisk -CapacityGB 3
        $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
        $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
        $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
        $Config.deviceChange[0].operation = "edit"
        $Config.deviceChange[0].device = $HardDisk.ExtensionData
        $Config.deviceChange[0].device.ControllerKey = "1003"
        $Config.deviceChange[0].device.UnitNumber = "0"
        $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
        Start-Sleep 5

        $VM | New-HardDisk -CapacityGB 4
        $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
        $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
        $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
        $Config.deviceChange[0].operation = "edit"
        $Config.deviceChange[0].device = $HardDisk.ExtensionData
        $Config.deviceChange[0].device.ControllerKey = "1001"
        $Config.deviceChange[0].device.UnitNumber = "1"
        $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
        Start-Sleep 5

        $VM | New-HardDisk -CapacityGB 5
        $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
        $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
        $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
        $Config.deviceChange[0].operation = "edit"
        $Config.deviceChange[0].device = $HardDisk.ExtensionData
        $Config.deviceChange[0].device.ControllerKey = "1002"
        $Config.deviceChange[0].device.UnitNumber = "1"
        $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
        Start-Sleep 5

        $VM | New-HardDisk -CapacityGB 6
        $HardDisk = $VM | Get-HardDisk | Select-Object -Last 1
        $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
        $Config.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
        $Config.deviceChange[0].operation = "edit"
        $Config.deviceChange[0].device = $HardDisk.ExtensionData
        $Config.deviceChange[0].device.ControllerKey = "1003"
        $Config.deviceChange[0].device.UnitNumber = "1"
        $VM.ExtensionData.ReconfigVM_Task($Config) | Out-Null
        Start-Sleep 5
    }

    end {
        $VM | Get-HardDisk | Select-Object Parent, Name, DiskType, DeviceName, CapacityGB, @{n = "ExtensionData"; e = { ($_.ExtensionData.ControllerKey) ; ($_.ExtensionData.UnitNumber) } } | Format-Table -AutoSize
    }
}