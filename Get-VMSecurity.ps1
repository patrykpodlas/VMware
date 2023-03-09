function Get-VMSecurity {
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
        Author: Patryk Podlas
        Created: 24/02/2022

        Change history:
        Date            Author      V       Notes
        24/02/2022      PP          1.0     First release
    #>
    #Requires -Modules VMware.VimAutomation.Core
    #Requires -Version 5.1
    [CmdletBinding()]
    param (
        [string]$VM,
        [string]$ESXiHost,
        [string]$Cluster
    )

    begin {

        #HTML formatting for the export.
        $Header = @"
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
    <head>
    <title>VM report</title>
    <style type="text/css">
    <!--
    body {
    background-color: #E0E0E0;
    font-family: open-sans
    }
    table, th, td {
    background-color: white;
    border-collapse:collapse;
    border: 1px solid green;
    padding: 5px
    }
    -->
    </style>
    "@
$Body = @"
    <h1>VM report</h1>
"@

        $VMSettings = @{
            "isolation.tools.copy.disable"  = "TRUE"
            "isolation.tools.paste.disable" = "TRUE"
            "RemoteDisplay.maxConnections"  = 1
            "tools.guest.desktop.autolock"  = "TRUE"
        }
        if ($VM) {
            $VM = Get-VM $VM
        }
    }

    process {
        $returnObj = @()
        foreach ($Setting in $VMSettings.GetEnumerator()) {
            $SettingCheck = Get-VM -Name $VM | Get-AdvancedSetting | Where-Object -Property Name -EQ $Setting.Name
            if ($SettingCheck.Value -EQ $Setting.Value) {
                $PassOrFail = 'PASS'
                $Reason = $null
            } elseif (($SettingCheck.Value -NE $Setting.Value) -or (!$SettingCheck.Value)) {
                $PassOrFail = 'FAIL'
                if (!$SettingCheck.Value) {
                    $Reason = "NULL ≠ $($Setting.Value)"
                } else {
                    $Reason = "$($SettingCheck.Value) ≠ $($Setting.Value)"
                }
            }
            $Obj = New-Object psobject -Property @{
                "Test"               = $Setting.Name
                "Pass or Fail"       = $PassOrFail
                "VM"                 = $VM
                "Reason for failure" = $Reason
            }
            $returnObj += $Obj | Select-Object -Property 'Pass or Fail', Test, VM, 'Reason For Failure'
        }

        $returnObj | ConvertTo-Html -Head $Header -Body $Body | ForEach-Object {
            $_ -replace "<td>FAIL</td>", "<td style='background-color:#FF0000'>FAIL</td>" -replace "<td>PASS</td>", "<td style='background-color:#008000'>PASS</td>"
        } | Out-File -FilePath $env:USERPROFILE\Documents\TEMP\VMReport_settings.html ; Write-Output "Results are exported to $env:USERPROFILE\Documents\TEMP\VMReport_settings.html`n"
        $returnObj | Out-GridView -Title "VM settings"
    }

    end {

    }
}