# New slot number to use (number, not a string -- no quotes)
$intNewSlotNumber = 1184
$scsi0NewSlotNumber = 160
$scsi1NewSlotNumber = 192
$scsi2NewSlotNumber = 224
$scsi3NewSlotNumber = 256


# Network
## create new VMConfigSpec object
$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
## create an array of OptionValues (1 item long)
$spec.extraConfig = New-Object VMware.Vim.OptionValue[] (1)
## create a new OptionValue with the desired values
$spec.extraConfig[0] = New-Object VMware.Vim.OptionValue -Property @{
    key = "ethernet0.pciSlotNumber"
    value = $intNewSlotNumber
} ## end new-object

## get the .NET View object for the VM
$viewVMToReconfig = Get-View -ViewType VirtualMachine -Property Name -Filter @{"Name" = $VMName}
## reconfig the VM with the new spec
$viewVMToReconfig.ReconfigVM_Task($spec)

# SCSI 0
## create new VMConfigSpec object
$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
## create an array of OptionValues (1 item long)
$spec.extraConfig = New-Object VMware.Vim.OptionValue[] (1)
## create a new OptionValue with the desired values
$spec.extraConfig[0] = New-Object VMware.Vim.OptionValue -Property @{
    key = "scsi0.pciSlotNumber"
    value = $scsi0NewSlotNumber
} ## end new-object

## get the .NET View object for the VM
$viewVMToReconfig = Get-View -ViewType VirtualMachine -Property Name -Filter @{"Name" = $VMName}
## reconfig the VM with the new spec
$viewVMToReconfig.ReconfigVM_Task($spec)

# SCSI 1
## create new VMConfigSpec object
$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
## create an array of OptionValues (1 item long)
$spec.extraConfig = New-Object VMware.Vim.OptionValue[] (1)
## create a new OptionValue with the desired values
$spec.extraConfig[0] = New-Object VMware.Vim.OptionValue -Property @{
    key = "scsi1.pciSlotNumber"
    value = $scsi1NewSlotNumber
} ## end new-object

## get the .NET View object for the VM
$viewVMToReconfig = Get-View -ViewType VirtualMachine -Property Name -Filter @{"Name" = $VMName}
## reconfig the VM with the new spec
$viewVMToReconfig.ReconfigVM_Task($spec)

# SCSI 2
## create new VMConfigSpec object
$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
## create an array of OptionValues (1 item long)
$spec.extraConfig = New-Object VMware.Vim.OptionValue[] (1)
## create a new OptionValue with the desired values
$spec.extraConfig[0] = New-Object VMware.Vim.OptionValue -Property @{
    key = "scsi2.pciSlotNumber"
    value = $scsi2NewSlotNumber
} ## end new-object

## get the .NET View object for the VM
$viewVMToReconfig = Get-View -ViewType VirtualMachine -Property Name -Filter @{"Name" = $VMName}
## reconfig the VM with the new spec
$viewVMToReconfig.ReconfigVM_Task($spec)

# SCSI 3
## create new VMConfigSpec object
$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
## create an array of OptionValues (1 item long)
$spec.extraConfig = New-Object VMware.Vim.OptionValue[] (1)
## create a new OptionValue with the desired values
$spec.extraConfig[0] = New-Object VMware.Vim.OptionValue -Property @{
    key = "scsi3.pciSlotNumber"
    value = $scsi3NewSlotNumber
} ## end new-object

## get the .NET View object for the VM
$viewVMToReconfig = Get-View -ViewType VirtualMachine -Property Name -Filter @{"Name" = $VMName}
## reconfig the VM with the new spec
$viewVMToReconfig.ReconfigVM_Task($spec)