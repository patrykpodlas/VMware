function Get-VMWareCluster {
    <#
    .SYNOPSIS
        Simple function to quickly retrieve the cluster information.
    .DESCRIPTION
        Simple function to quickly retrieve the cluster information. The information includes the ratio of vCPU to actual physical CPU's to esablish if resources are over commited.
    .EXAMPLE
        PS C:\> Get-VMwareCluster -Cluster <name>
        Retrieves the specified cluster information.
    .NOTES
        Author: Patryk Podlas
        Created: January 2022
        Change History:
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = "Cluster")]
        [string[]]$Cluster
    )

    begin {
        if (!$global:DefaultVIServer) {
            Write-Error -Message "Not Connected to any vCenters.  Connect to all linked vcenters (Connect-VIServer <vCenter> -AllLinked) before running this command ..." -Category AuthenticationError -ErrorAction Stop
        }
    }

    process {
        foreach ($Cluster in $Cluster) {
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