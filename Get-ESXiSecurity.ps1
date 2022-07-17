function Get-ESXiSecurity {
    <#
    .SYNOPSIS
        Function which retrieves current security values and services status set on each ESXi host.
    .DESCRIPTION
        Function which retrieves current security values and services status set on each ESXi host.
        Each value is examined based on security standards, if the value matches then the result is a success, otherwise it's a fail, output shows what the value should be and what it currently is set to.
        The results are exported to HTML format into $env:USERPROFILE\Documents\TEMP, as well as outputted immediately to Out-GridView.
        The function will target all hosts added to the VCSA currently connected to.
        If no parameters are specified, all parameters are used by default.
    .PARAMETER Settings
        Retrieve the ESXi server security settings.
    .PARAMETER Services
        Retrieve the ESXi server services settings.
    .EXAMPLE
        PS C:\> Get-ESXiSecurity -Settings -Services
        Exports both, the settings and services statuses, this action is done by default.
    .NOTES
        Author: Patryk Podlas
        Created: January 2022

        Change history:
        Date            Author      V       Notes
        01/02/2022      PP          1.0     First release
    #>

    #Requires -Modules VMware.VimAutomation.Core
    #Requires -Version 5.1
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]$Settings,
        [Parameter()]
        [switch]$Services
    )

    begin {
        $ESXiHosts = @(
            Get-VMHost | Select-Object Name
        )
        if (!$Settings -and !$Services) {
            $Settings = $true
            $Services = $true
        }
        #HTML formatting for the export.
        $Header = @"
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
    <head>
    <title>ESXi report</title>
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
    <h1>ESXi report</h1>
"@

    }

    process {
        if ($Settings) {
            #ESXi settings which are based on the defined standard.
            $ESXiSettings = @{
                "Security.AccountUnlockTime"              = 900
                "Security.AccountLockFailures"            = 3
                "Security.PasswordHistory"                = 5
                "UserVars.DcuiTimeOut"                    = 600
                "UserVars.ESXiShellTimeOut"               = 600
                "UserVars.ESXiShellInteractiveTimeOut"    = 600
                "UserVars.SuppressShellWarning"           = 0
                #"Config.HostAgent.plugins.hostsvc.esxAdminsGroup" = "domain\accountorgroup"
                "Syslog.global.logDir"                    = "[] /scratch/log" #Logging directory, need to establish what it should be.
                "Syslog.global.logHost"                   = $true #Logging enabled
                "UserVars.ESXiVPsDisabledProtocols"       = "sslv3,tlsv1,tlsv1.1"
                "Mem.ShareForceSalting"                   = 2
                "Config.HostAgent.plugins.solo.enableMob" = $false
            }
            #Evaluates the ESXi settings.
            $returnObj = @()
            foreach ($ESXiHost in $ESXiHosts.Name) {
                foreach ($Setting in $ESXiSettings.GetEnumerator()) {
                    $SettingCheck = Get-AdvancedSetting -Entity $ESXiHost | Where-Object -Property Name -EQ $Setting.Name
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
                        "ESXi"               = $ESXiHost
                        "Reason for failure" = $Reason
                        "Value"              = $SettingCheck.Value
                    }
                    $returnObj += $Obj | Select-Object -Property 'Pass or Fail', Test, ESXi, 'Reason For Failure', Value
                }
            }

            $returnObj | Sort-Object -Property 'Pass or Fail' | ConvertTo-Html -Head $Header -Body $Body | ForEach-Object {
                $_ -replace "<td>FAIL</td>", "<td style='background-color:#FF0000'>FAIL</td>" -replace "<td>PASS</td>", "<td style='background-color:#008000'>PASS</td>"
            } | Out-File -FilePath $env:USERPROFILE\Documents\TEMP\ESXiReport_settings.html ; Write-Output "Results are exported to $env:USERPROFILE\Documents\TEMP\ESXiReport_settings.html`n"
            $returnObj | Out-GridView -Title "ESXi Settings"
        }
        if ($Services) {
            #ESXi services which are based on the defined standard.
            $ESXiServices = @{
                "ntpd"           = "on" #NTP Enabled
                "sfcbd-watchdog" = "off" #CIM Disabled
                "slpd"           = "off" #SLP Disabled
                "snmpd"          = "off" #SNMP Disabled
                "TSM-SSH"        = "off" #SSH Disabled
                "TSM"            = "off" #ESXiShell Disabled
            }
            #Evaluates the ESXi services.
            $returnObj = @()
            foreach ($ESXiHost in $ESXiHosts.Name) {
                foreach ($Setting in $ESXiServices.GetEnumerator()) {
                    $SettingCheck = Get-VMHost -Name $ESXiHost | Get-VMHostService | Where-Object -Property Key -EQ $Setting.Name
                    if ($SettingCheck.Policy -EQ $Setting.Value) {
                        $PassOrFail = 'PASS'
                        $Reason = $null
                    } elseif ($SettingCheck.Policy -NE $Setting.Value) {
                        $PassOrFail = 'FAIL'
                        $Reason = "$($SettingCheck.Policy) ≠ $($Setting.Value)"
                    }
                    $Obj = New-Object psobject -Property @{
                        "Test"               = $Setting.Name
                        "Pass or Fail"       = $PassOrFail
                        "ESXi"               = $ESXiHost
                        "Reason for failure" = $Reason
                        "Value"              = $SettingCheck.Policy
                    }
                    $returnObj += $Obj | Select-Object -Property 'Pass or Fail', Test, ESXi, 'Reason For Failure', Value
                }
            }
            $returnObj | Sort-Object -Property 'Pass or Fail' | ConvertTo-Html -Head $Header -Body $Body | ForEach-Object {
                $_ -replace "<td>FAIL</td>", "<td style='background-color:#FF0000'>FAIL</td>" -replace "<td>PASS</td>", "<td style='background-color:#008000'>PASS</td>"
            } | Out-File -FilePath $env:USERPROFILE\Documents\TEMP\ESXiReport_Services.html ; Write-Output "Results are exported to $env:USERPROFILE\Documents\TEMP\ESXiReport_services.html`n"
            $returnObj | Out-GridView -Title "ESXi Services"
        }
    }

    end {

    }

}