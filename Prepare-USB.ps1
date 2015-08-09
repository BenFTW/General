<#
.SYNOPSIS

Prepare a USB stick as bootable Windows OS deployment media
.DESCRIPTION

WARNING: The first USB disk reported back by Windows will be used. Have backups
         before you go try this out.

Script will find a bootable USB disk, wipe the partition table, format it, then
copy bootfiles from a specified source.

      Author: Ben "The Slowest Zombie" Peterson
     Version: 1.0
Requirements: PowerShell 3.0, Windows 8
        ToDo: Add error handling, parameter validation, handle $Script better
.PARAMETER Source

Path to where WinPE media that will be copied to the USB drive
.PARAMETER TargetDiskNumber

Overrides auto-selection of the first available USB disk and forces a specific
one instead.
.PARAMETER MBR

Formats the USB partition as NTFS, forcing a non-EFI (legacy) boot
.EXAMPLE

 .\Prepare-USB.ps1 -Source C:\WinPE\* -TargetDiskNumber 4 -MBR
*Selects disk 4 (use diskpart and "list disk" to get numbers)
*Formats it as NTFS, making it bootable only in Legacy/MBR mode
*Copies WinPE files from C:\WinPE
NTFS (forces
.LINK

Author Homepage: http://slowestzombie.net/it_lives
#>

Param(
    [string]
    $Source = "C:\Path\To\ISO_Contents\*"
,
    [ValidateRange(0,10)]
    [int]
    $TargetDiskNumber = $null
,
    [string]
    $DriveLabel = "OSDEPLOY"
,
    [switch]
    $MBR
)

###Extra processing for Parameters
#If no disk number was specified, pick one
if ($TargetDiskNumber -eq $null) {
    $DiskList = Get-disk | Where-Object { $_.BusType -eq "USB" } | Select-Object -First 1

    Write-Host "Using the following disk:"
    $DiskList | Out-Host
    $TargetDiskNumber = $DiskList.Number
    Start-Sleep -Seconds 3
    }
#Handle MBR switch
if ($MBR) { $FileSystem = "NTFS" } else { $FileSystem = "FAT32" }


Get-Disk -Number $TargetDiskNumber | Clear-Disk -RemoveData
$NewPart = New-Partition -DiskNumber $TargetDiskNumber -UseMaximumSize -IsActive
Start-Sleep -Milliseconds 750
$NewPart | Format-Volume -FileSystem $FileSystem -NewFileSystemLabel $DriveLabel -Confirm:$false

Start-Sleep -Milliseconds 250

#Get a free drive letter
$TargetDriveLetter = (Get-ChildItem function:[f-z]: -Name | Where-Object { !(Test-Path $_) } | Select-Object -First 1).Replace(":","")
$Destination = $TargetDriveLetter + ":\"

$NewPart | Set-Partition -NewDriveLetter $TargetDriveLetter

Write-Host "`r`nCopying boot files to $Destination"
Copy-Item -Path $Source -Destination $Destination -Recurse