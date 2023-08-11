#requires -version 7
#requires -module Az
<#
.SYNOPSIS
  Script to delete all management groups in a tenant and resets all subscriptions to the tenant root group
.DESCRIPTION
  Script to delete all management groups in a tenant and resets all subscriptions to the tenant root group
.PARAMETER TenantId
  The tenant id to run the script against
.NOTES
  Version:        1.1.1
  Author:         Jelle Broekhuijsen - jll.io Consultancy
  Creation Date:  8/8/2023
  
.EXAMPLE
  ./Remove-AzManagementGroups.ps1 -TenantId 00000000-0000-0000-0000-000000000000
#>

[CmdletBinding()]
param (
  [Parameter(Mandatory)]
  [string]
  $TenantId
)

$ErrorActionPreference = 'Continue'
$errorCount = 0

#Get all management groups except the root group
$managementGroups = Get-AzManagementGroup -ErrorAction Stop | Where-Object { $_.Name -ne $TenantId }

#Get all subscriptions
$subscriptions = Get-AzSubscription

#Create a concurrent bag to store failures
$failures = [System.Collections.Concurrent.ConcurrentBag[PSObject]]::new()

#Get all management group assignments for non-root assignme
$assignments = $managementGroups | ForEach-Object {
  Get-AzManagementGroupSubscription -GroupName $_.Name 
}

#Reset all subscriptions to the root group
$assignments | ForEach-Object -Parallel {
  $localFailures = $using:failures
  Write-Output "Reset subscription: $(($_.Id -split '/')[-1]) to root group"
  $result = Remove-AzManagementGroupSubscription -GroupName ($_.Parent -split '/')[-1]  -SubscriptionId ($_.Id -split '/')[-1]
  if($result -ne $true) {
    Write-Warning "Failed to reset subscription: $(($_.Id -split '/')[-1]) to root group"
    $localFailures.Add($result)
  }
}

#Remove the entire hierachy of management groups
Write-Output "Attempting to remove $($managementGroups.Count) management groups"
$lingeringManagementGroups = [System.Collections.Concurrent.ConcurrentBag[PSObject]]::new()

do {
  $managementGroups | ForEach-Object -Parallel {
    $localLingeringManagementGroups = $using:lingeringManagementGroups
    $localFailures = $using:failures
    $managementGroup = Get-AzManagementGroup -GroupName $_.Name -ErrorAction SilentlyContinue
    if ($null -ne $managementGroup) {
      Write-Output "Attempting to remove management group: $($managementGroup.Name)"
      $result = Remove-AzManagementGroup -GroupName $managementGroup.Name -ErrorAction Continue
      if ($result -ne $true) {
        Write-Warning "Failed to remove management group: $($managementGroup.Name)"
        $localFailures.Add($result)
      }
    }
    else {
      Write-Output "Deleted management group '$($_.Name)' added to lingering management group count"
      $localLingeringManagementGroups.Add($_)
    }
  }
  $managementGroups = Get-AzManagementGroup | Where-Object { $_.Name -ne $TenantId }
  if ($managementGroups.Count -gt 0 -and $lingeringManagementGroups.Count -lt $managementGroups.Count) {
    Write-Output "Found $($managementGroups.Count - $lingeringManagementGroups.Count) remaining management groups to remove"
    Write-Output "Waiting 30 seconds before retrying"
    $lingeringManagementGroups.Clear()
    Start-Sleep -Seconds 30
  }
}
while ($managementGroups.Count -gt 0 -and $lingeringManagementGroups.Count -lt $managementGroups.Count)
Write-Output "Successfully removed all management groups"

#Report failures
if($failures.Count -gt 0) {
  Throw "Failed to remove $($failures.Count) management groups"
}
