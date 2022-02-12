function Get-VMwareCDP {
    <#
    .SYNOPSIS
        Simple function to quickly retrieve the CDP information for any cluster or host.
    .DESCRIPTION
        Simple function to quickly retrieve the CDP information for any cluster or host. This can be useful to send to the networking team through a readable format without manually copying/pasting the information through the GUI, for the purpose of tagging the switchports with needed VLANs.
        The function works with | Export-CSV -Path and is the recommended approach.
    .EXAMPLE
        PS C:\> Get-VMwareCDP -Cluster <name> | Format-Table
        Specifying the cluster will go through each host within and retrieve the CDP information and formats the output in a table format.
    .EXAMPLE
        PS C:\> Get-VMwareCDP -ESXiHost <name> | Out-GridView
        Specyfing the host will only target the host during CDP retrieval and displays a table with the results. The table can then be sorted as desired.
    .EXAMPLE
        PS C:\> Get-VMwareCDP -Cluster <name> | Export-CSV -Path .\<name>.csv -NoTypeInformation
        Retrieves the CDP information for the entire cluster and exports the results to a CSV file without type information.
    .NOTES
        Author: Patryk Podlas
        Created: January 2022
        Change History:
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = "Cluster")]
        [string]$Cluster,
        [Parameter(Mandatory, ParameterSetName = "ESXiHost")]
        [string]$ESXiHost
    )

    begin {
        if (!$global:DefaultVIServer) {
            Write-Error -Message "Not Connected to any vCenters.  Connect to all linked vcenters (Connect-VIServer <vCenter> -AllLinked) before running this command ..." -Category AuthenticationError -ErrorAction Stop
        }
    }

    process {
        if ($Cluster) {
            $VMHosts = Get-Cluster -Name $Cluster | Get-VMHost
            $returnObj = @()
            foreach ($VMHost in $VMHosts) {
                $NetSystem = Get-View $VMHost.ExtensionData.ConfigManager.NetworkSystem
                foreach ($Pnic in $VMHost.ExtensionData.Config.Network.Pnic) {
                    $PnicInfo = $NetSystem.QueryNetworkHint($Pnic.Device)
                    $Speed = $VMHost | Get-VMHostNetworkAdapter -Name $Pnic.Device | Select-Object BitRatePerSec
                    $Obj = [PSCustomObject] @{
                        'Host'       = $VMHost.Name
                        'VMNIC'      = $Pnic.Device
                        'Switch'     = $PnicInfo.ConnectedSwitchPort.DevId
                        'SwitchPort' = $PnicInfo.ConnectedSwitchPort.PortId
                        'MAC'        = $Pnic.Mac
                        'Driver'     = $Pnic.Driver
                        'Speed(GB)'  = $($Speed.BitRatePerSec) / 1000
                    }
                    $returnObj += $Obj
                }
            }   $returnObj
        }
        if ($ESXiHost) {
            $VMHost = Get-VMHost -Name $($ESXiHost + "*")
            $returnObj = @()
            $NetSystem = Get-View $VMHost.ExtensionData.ConfigManager.NetworkSystem
            foreach ($Pnic in $VMHost.ExtensionData.Config.Network.Pnic) {
                $PnicInfo = $NetSystem.QueryNetworkHint($Pnic.Device)
                $Speed = $VMHost | Get-VMHostNetworkAdapter -Name $Pnic.Device | Select-Object BitRatePerSec

                $Obj = [PSCustomObject] @{
                    'Host'       = $VMHost.Name
                    'VMNIC'      = $Pnic.Device
                    'Switch'     = $PnicInfo.ConnectedSwitchPort.DevId
                    'SwitchPort' = $PnicInfo.ConnectedSwitchPort.PortId
                    'MAC'        = $Pnic.Mac
                    'Driver'     = $Pnic.Driver
                    'Speed(GB)'  = $($Speed.BitRatePerSec) / 1000
                }
                $returnObj += $Obj
            }
        }   $returnObj
    }

    end {

    }
}