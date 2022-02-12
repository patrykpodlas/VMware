function Get-VMWareCluster {
    <#
    .SYNOPSIS
        Simple function to quickly retrieve the cluster information.
    .DESCRIPTION
        Simple function to quickly retrieve the cluster information. The information includes the ratio of vCPU allocated to virtual machines, to actual physical CPU's for each host to esablish if resources are over commited.
    .EXAMPLE
        PS C:\> Get-VMwareCluster
        Retrieves the information for all the clusters.
    .EXAMPLE
        PS C:\> Get-VMwareCluster -Clusters <name>
        Retrieves the specified cluster information.
    .NOTES
        Author: Patryk Podlas
        Created: January 2022
        Change History:
    #>
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = "Clusters")]
        [string[]]$Clusters = (Get-Cluster)
    )

    begin {

    }

    process {
        foreach ($Cluster in $Clusters) {
            foreach ($VMHost in Get-Cluster -Name $Cluster | Get-VMHost) {
                $vCPU = Get-VM -Location $VMHost | Measure-Object -Property NumCpu -Sum | Select-Object -ExpandProperty Sum
                $VMHost | Select-Object Name, @{N = 'pCPU'; E = { $_.NumCpu } },
                @{N = 'vCPU'; E = { $vCPU } },
                @{N = 'Ratio'; E = { [math]::Round($vCPU / $_.NumCpu, 1) } },
                @{N = 'Cluster'; E = { $Cluster } }
            }
        }
    }

    end {

    }
}