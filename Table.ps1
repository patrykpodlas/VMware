
$Table = @(
    @{DiskNumber = "1"; DiskSize = "$DiskOneSize"; ControllerKey = "1001"; ControllerUnitNumber = "0" },
    @{DiskNumber = "2"; DiskSize = "$DiskTwoSize"; ControllerKey = "1001"; ControllerUnitNumber = "1" },
    @{DiskNumber = "3"; DiskSize = "$DiskThreeSize"; ControllerKey = "1002"; ControllerUnitNumber = "0" },
    @{DiskNumber = "4"; DiskSize = "$DiskFourSize"; ControllerKey = "1002"; ControllerUnitNumber = "1" },
    @{DiskNumber = "5"; DiskSize = "$DiskFiveSize"; ControllerKey = "1003"; ControllerUnitNumber = "0" },
    @{DiskNumber = "6"; DiskSize = "$DiskSixSize"; ControllerKey = "1003"; ControllerUnitNumber = "1" }
) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }