### Not finished!
function Get-VMwareHBA {
    <#
    .SYNOPSIS
        Short description
    .DESCRIPTION
        Long description
    .EXAMPLE
        PS C:\> <example usage>
        Explanation of what the example does
    .NOTES
        Created: January 2022
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Cluster,
        [Parameter(Mandatory = $false)]
        [string]$ESXiHost
    )

    begin {
        if (!$global:DefaultVIServer) {
            Write-Error -Message "You are not currently connected to any vCenter servers. Please connect first using the Connect-VIServer -AllLinked cmdlet" -ErrorAction Stop
        } else {
            Write-Host "Already connected to $($global:DefaultVIServer)`n" -ForegroundColor Green
        }
        if (!$Cluster -and !$ESXiHost) {
            $Prompt = Read-Host "You must specify a cluster name or ESXi host, do you want to retrieve the list of available clusters or ESXi hosts? (C(Cluster)/H(Host))"
            if ($Prompt -contains "C") {
                Get-Cluster ; Write-Host "`nExiting the script`n" ; Exit
            }
            if ($Prompt -contains "H") {
                Get-VMHost ; Write-Host "`nExiting the script`n" ; Exit
            } else {
                Write-Host "Exiting the script`n" ; Exit
            }
        }
    }

    process {
        if ($Cluster) {
            $ESXCluster = Get-Cluster -Name $Cluster
            $VMHosts = $ESXCluster | Get-VMHost
            #Builds a table with CDP information
            $returnObj = @()
            foreach ($VMHost in $VMHosts) {
                Get-VMHostHba -VMHost $VMHost -Type FibreChannel |
                Select-Object  @{N = "Host"; E = { $VMHost.Name } },
                @{N = 'HBA Node WWN'; E = { $wwn = "{0:X}" -f $_.NodeWorldWideName; (0..7 | ForEach-Object { $wwn.Substring($_ * 2, 2) }) -join ':' } },
                @{N = 'HBA Node WWP'; E = { $wwp = "{0:X}" -f $_.PortWorldWideName; (0..7 | ForEach-Object { $wwp.Substring($_ * 2, 2) }) -join ':' } }
            }
        }
    }

    end {

    }
}

$VMHosts = Get-VMHost
foreach ($VMHost in $VMHosts) {
    Get-VMHostHba -VMHost $VMHost -Type FibreChannel |
    Select-Object  @{N = "Host"; E = { $VMHost.Name } },
    @{N = 'HBA Node WWN'; E = { $wwn = "{0:X}" -f $_.NodeWorldWideName; (0..7 | ForEach-Object { $wwn.Substring($_ * 2, 2) }) -join ':' } },
    @{N = 'HBA Node WWP'; E = { $wwp = "{0:X}" -f $_.PortWorldWideName; (0..7 | ForEach-Object { $wwp.Substring($_ * 2, 2) }) -join ':' } }
}