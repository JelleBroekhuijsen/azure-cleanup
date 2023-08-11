#requires -version 7
#requires -module Az
<#
.SYNOPSIS
  Script to delete application registrations that are not tagged with 'persistent'
.DESCRIPTION
  Script to delete application registrations that are not tagged with 'persistent'. This script is intended to be run on a schedule to clean up unused application registrations. Tags are checked in the application manifest.
.NOTES
  Version:        1.0.0
  Author:         Jelle Broekhuijsen - jll.io Consultancy
  Creation Date:  11/8/2023
  
.EXAMPLE
  ./Remove-AzAdApplications.ps1
#>

[CmdletBinding()]
param ()

$ErrorActionPreference = 'Continue'

#Create a concurrent bag to store failures
$failures = [System.Collections.Concurrent.ConcurrentBag[PSObject]]::new()

#Get all application registrations
$applications = Get-AzADApplication

#Create a concurrent bag to store applications for removal
$applicationForRemoval = [System.Collections.Concurrent.ConcurrentBag[PSObject]]::new()

#Filter out applications that are not tagged with 'persistent'
$applications | ForEach-Object -Parallel {
  $localApplicationForRemoval = $using:applicationForRemoval
  $application = Get-AzADApplication -ObjectId $_.Id | Select-Object DisplayName,Id,AppId,Tag
  if ($application.Tag -notcontains 'persistent') {
    Write-Output "Marked application '$($application.DisplayName)' for removal"
    $localApplicationForRemoval.Add($application)
  } 
}

#Remove applications
Write-Output "Found $($applicationForRemoval.Count) applications to remove"
$applicationForRemoval | ForEach-Object -Parallel {
  $localFailures = $using:failures
  Write-Output "Removing application '$($_.DisplayName)'"
  $result = Remove-AzADApplication -ObjectId $_.Id -Force
  if ($null -eq $result) {
    Write-Warning "Failed to remove application '$($_.DisplayName)'"
    $localFailures.Add($_)
  }
}

#Report failures
if ($failures.Count -gt 0) {
  Throw "Failed to remove $($failures.count) applications"
}

