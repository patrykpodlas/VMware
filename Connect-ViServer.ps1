# Only works with secrets retrieved from Azure Key Vault through Azure DevOps, you can replace the variables with plain text though and it will work.
# Can be useful when trying to automate logging into the vSphere environment as part of a script.
# The $env: are environmental variables set using Azure DevOps pipeline in YAML file, the pipeline first retrievs the secrets from Azure Key Vault, and then sets them inside environmental variables, they can then be re-used by anything run on the host machine.

# Load PowerCLI
Write-Output "---Checking PSModulePath for debugging reasons and importing VMware PowerCLI module."
Write-Output $env:PSModulePath.Split(";")
Import-Module -Name "VMware.PowerCLI"
Write-Output "---Setting PowerCLI configuration."
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP:$false -DisplayDeprecationWarnings:$false -InvalidCertificateAction Ignore -Confirm:$false
# List environmental variables
Write-Output "---Variables visible right now:"
Get-ChildItem env: | Format-Table
# Create credential Object
Write-Output "---Setting up the credentials to login to vSphere using user: $env:env_vsphere_scripts_username, the credentials will be saved!"
[SecureString]$secureString = $env:env_vsphere_scripts_password | ConvertTo-SecureString -AsPlainText -Force
[PSCredential]$credentialObject = New-Object System.Management.Automation.PSCredential -ArgumentList $env:env_vsphere_scripts_username, $secureString
# Connect to vCenter
Connect-VIServer -Server $env:env_vsphere_server -credential $credentialObject -SaveCredentials
