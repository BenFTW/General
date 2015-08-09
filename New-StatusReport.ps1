<#
.SYNOPSIS

Creates a new weekly status report file if one doesn't already exist.
.DESCRIPTION

This script is for people who track things such as status reports or activities on a weekly basis and want to separate each week's data into different files
      Author: Ben "The Slowest Zombie" Peterson
     Version: 1.0
Requirements: PowerShell 3.0
.PARAMETER none

Placeholder for future parameters
.EXAMPLE

 .\New-StatusReport.ps1
In this example, the script runs with default settings.
.LINK

Author Homepage: http://slowestzombie.net/it_lives
#>


$ReportPath = $env:USERPROFILE + "\Documents\Status"
$Date = Get-Date
$Format = "yyyyMMdd"

$Template = @"
****Monday*****


****Tuesday****


***Wednesday***


***Thursday****


****Friday*****


****Weekend****
"@

Switch ($Date.DayOfWeek) {
    "Monday"    { $DaysToAdd = 4 }
    "Tuesday"   { $DaysToAdd = 3 }
    "Wednesday" { $DaysToAdd = 2 }
    "Thursday"  { $DaysToAdd = 1 }
    "Friday"    { $DaysToAdd = 0 }
    "Saturday"  { $DaysToAdd = -1 }
    "Sunday"    { $DaysToAdd = -2 }
    default { Write-Error "Something is wrong here..." -ErrorAction Stop }
    }

$Friday = $Date.AddDays($DaysToAdd) | Get-Date -Format $Format
$StatusFile = "$ReportPath\$Friday.txt"

if ( !(Test-Path $StatusFile) -and (Test-Path $ReportPath) ) { 
    $Template | Set-Content -Path $StatusFile    
    }