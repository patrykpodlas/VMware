function Get-vSphereCluster {
    <#
    .SYNOPSIS
        Simple function to quickly retrieve the cluster information.
    .DESCRIPTION
        Simple function to quickly retrieve the cluster information. The information includes the ratio of vCPU allocated to virtual machines, to actual physical CPU's for each host to esablish if resources are over commited.
    .PARAMETER Clusters
        Specify a single or comma-separated multiple cluster names.
    .EXAMPLE
        PS C:\> Get-vSphereCluster
        Retrieves the information for all the clusters.
    .EXAMPLE
        PS C:\> Get-vSphereCluster -Clusters <ClusterName>
        Retrieves the specified cluster information.
    .NOTES
        Author: Patryk Podlas
        Created: February 2022

        Change history:
        Date            Author      V       Notes
        15/02/2022      PP          1.0     First release
    #>
    #Requires -Version 5.1
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
                $VMHost | Select-Object Name, @{Name = 'pCPU'; Expression = { $_.NumCpu } },
                @{Name = 'vCPU'; Expression = { $vCPU } },
                @{Name = 'Ratio'; Expression = { [math]::Round($vCPU / $_.NumCpu, 1) } },
                @{Name = 'MemoryTotal'; Expression = { [math]::Round($VMHost.MemoryTotalGB, 2) } },
                @{Name = 'MemoryUsage'; Expression = { [math]::Round($VMHost.MemoryUsageGB, 2) } },
                @{Name = 'MemoryFree'; Expression = { [math]::Round($VMHost.MemoryTotalGB - $VMHost.MemoryUsageGB, 2) } },
                @{Name = 'MemoryFreePercentage'; Expression = { [math]::Round(($VMHost.MemoryTotalGB - $VMHost.MemoryUsageGB) / $VMHost.MemoryTotalGB * 100) } },
                @{Name = 'Cluster'; Expression = { $Cluster } }
            }
        }
    }

    end {

    }
}
