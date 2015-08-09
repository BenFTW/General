<#
.SYNOPSIS

Generates passwords
.DESCRIPTION

Creates one or more passwords with a customizable amount of complexity
Based on examples from Powershell Magazine

      Author: Ben "The Slowest Zombie" Peterson
     Version: 1.0
Requirements: PowerShell 3.0
.PARAMETER Similar

Allows similar characters such as the number 0 and the letter O
.PARAMETER Extended

Allows extended characters such as {braces} and [brackets]
.EXAMPLE

 .\New-Password.ps1 5
Generates 5 passwords with default length and complexity settings.
.EXAMPLE

 .\New-Password.ps1 -Count 2 -Length 12 -Complexity 3
Generates 2 passwords with a length of 12 and at least 3 non-alphanumeric characters each.
.LINK

Author Homepage: http://slowestzombie.net/it_lives
.LINK

Reference Material: http://powershellmagazine.com
#>

Param(
    [ValidateRange(1,65536)]
    [int]
    $Count = 1
,
    [ValidateRange(6,64)]
    [int]
    $Length = 9
,
    [ValidateRange(0,64)]
    [int]
    $Complexity = 1
,
    [switch]
    $Similar
,
    [switch]
    $Extended
)

if ($Complexity -gt $Length) { $Complexity = $Length }

$Assembly = Add-Type -AssemblyName System.Web
$iteration = 0
$List = @()

Do { $List += [System.Web.Security.Membership]::GeneratePassword($Length,$Complexity); $iteration++ }
Until ($iteration -eq $Count)

if ( !$Similar ) { $List = $List.replace("O","T").Replace("0","5").Replace("I","y").Replace("l","r") }
if ( !$Extended ) { $List = $List.replace("=","%").Replace("<","#").Replace(">","@").Replace("{","&").Replace("}","^").Replace("[","&").Replace("]","^").Replace("/","*").Replace("\","!").Replace("(","?").Replace(")","!") }

Write-Output $List
