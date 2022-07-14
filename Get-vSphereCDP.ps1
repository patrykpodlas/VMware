#please-sign-me
function Get-vSphereCDP {
    <#
    .SYNOPSIS
        Simple function to quickly retrieve the CDP information for any cluster or host.
    .DESCRIPTION
        Simple function to quickly retrieve the CDP information for any cluster or host. This can be useful to send to the networking team through a readable format without manually copying/pasting the information through the GUI, for the purpose of tagging the switchports with needed VLANs.
        The function works with | Export-CSV -Path and is the recommended approach.
    .PARAMETER Clusters
        Specify one or more comma-separated cluster names.
    .PARAMETER ESXiHost
        Specify a single ESXi hostname.
    .EXAMPLE
        PS C:\> Get-vSphereCDP | Format-Table
        Run the without any parameters to cycle through every cluster the VCSA sees.
    .EXAMPLE
        PS C:\> Get-vSphereCDP -Clusters <ClusterName> | Format-Table
        Specifying the cluster will go through each host within and retrieve the CDP information and formats the output in a table format.
    .EXAMPLE
        PS C:\> Get-vSphereCDP -ESXiHost <ClusterName> | Out-GridView
        Specyfing the host will only target the host during CDP retrieval and displays a table with the results. The table can then be sorted as desired.
    .EXAMPLE
        PS C:\> Get-vSphereCDP -Clusters <ClusterName> | Export-CSV -Path .\CDPInfoFor<ClusterName>.csv -NoTypeInformation
        Retrieves the CDP information for the entire cluster and exports the results to a CSV file without type information.
    .NOTES
        Author: Patryk Podlas
        Created: February 2022

        Change history:
        Date            Author      V       Notes
        17/02/2022      PP          1.0     First release
        18/02/2022      PP          1.1     Added multiple cluster support and default value to all clusters
    #>
    #Requires -Modules VMware.VimAutomation.Core
    #Requires -Version 5.1
    [CmdletBinding(DefaultParameterSetName = "Clusters")]
    param (
        [Parameter(ParameterSetName = "Clusters")]
        [string[]]$Clusters = (Get-Cluster),
        [Parameter(ParameterSetName = "ESXiHost")]
        [string]$ESXiHost
    )

    begin {

    }

    process {
        if ($Clusters) {
            foreach ($Cluster in $Clusters) {
                $returnObj = @()
                foreach ($VMHost in Get-Cluster -Name $Cluster | Get-VMHost) {
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
                }
            }
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
