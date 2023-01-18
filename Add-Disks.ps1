function Add-Disks {
    <#
.SYNOPSIS
    Adds virtual disks to vSphere VM and configures them with appropriate controllers and keys.
.DESCRIPTION
    Adds virtual disks to vSphere VM and configures them with appropriate controllers and keys.
    The script looks for the specified VM, and sets up configuration for each added disk, distributing them amongst all added SCSI controllers, each disk is added one by one and then configured with the first available controller and key.
    Two disks per controller in the right order.
    All the environmental variables are retrieved from Azure Key Vault, the variables are filled out as part of the Azure DevOps Pipeline.
.PARAMETER VMName
    Name of the virtual machine to configure.
.PARAMETER vSphereServer
    Name of the vSphere server to connect to.
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
        Write-Output "---Shutting down the VM: $VMName"
        $VM | Shutdown-VMGuest -Confirm:$false
        Write-Output "VM: $VM.Name is already powered off"

        while ((Get-VM -Name $VMName).PowerState -EQ "PoweredOn") {
            Write-Output "---Waiting 5 seconds for $VMName to stop"
            Start-Sleep 5
        }
        Write-Output "Adding disks to: $VM.Name"
    }

    process {
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
