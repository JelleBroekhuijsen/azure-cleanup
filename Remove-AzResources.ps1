#requires -version 7
#requires -module Az
<#
.SYNOPSIS
  Script to delete resource groups that are not tagged with 'persistent = true' for a given subscription
.DESCRIPTION
  Script to delete resource groups that are not tagged with 'persistent = true' for a given subscription
.PARAMETER SubscriptionId
  The subscription id to run the script against
.NOTES
  Version:        1.1.3
  Author:         Jelle Broekhuijsen - jll.io Consultancy
  Last Update:  4/9/2023
  
.EXAMPLE
  ./Remove-AzResources.ps1 -SubscriptionId 00000000-0000-0000-0000-000000000000
#>

[CmdletBinding()]
param (
  [Parameter(Mandatory)]
  [string]
  $SubscriptionId
)

$ErrorActionPreference = 'Continue'

#Set subscription context
$subscription = Set-AzContext -SubscriptionId $SubscriptionId
Write-Output "Connected to Azure subscription: $($subscription.Name)."

#Get all resource groups that are not tagged with 'persistent = true'
$resourceGroups = Get-AzResourceGroup -ErrorAction Stop
$resourceGroupsWithoutPersistence = [System.Collections.Concurrent.ConcurrentBag[PSObject]]::new()

#Create a concurrent bag to store failures
$failures = [System.Collections.Concurrent.ConcurrentBag[PSObject]]::new()

$resourceGroups | ForEach-Object -Parallel {
  $localResourceGroupList = $using:resourceGroupsWithoutPersistence
  if ($null -eq $_.Tags) {
    Write-Output "Resource group '$($_.ResourceGroupName)' has no tags, marking for removal..."
    $localResourceGroupList.Add($_)
  }
  elseif ($null -eq $_.Tags.persistent) {
    Write-Output "Resource group '$($_.ResourceGroupName)' has no 'persistent' tag, marking for removal..."
    $localResourceGroupList.Add($_)
  }
  elseif ($_.Tags.persistent -ne 'true') {
    Write-Output "Resource group '$($_.ResourceGroupName)' has 'persistent' tag set to '$($_.Tags.persistent)', marking for removal..."
    $localResourceGroupList.Add($_)
  }
}

Write-Output "Found $($resourceGroupsWithoutPersistence.Count) resource groups to remove."

#Terminate if no resource groups are found
if ($resourceGroupsWithoutPersistence.Count -eq 0) {
  Write-Output "No resource groups to remove."
  break
}

#Remove resource groups
$resourceGroupsWithoutPersistence | ForEach-Object -Parallel {
  $localFailures = $using:failures
  Write-Output "Removing resource group: $($_.ResourceGroupName)."
  $result = Remove-AzResourceGroup -Name $_.ResourceGroupName -Force

  if ($result -ne $true) {
    Write-Warning "Failed to remove resource group: $($_.ResourceGroupName)."
    $localFailures.Add($_)
  }
}

#Report failures
if ($failures.Count -gt 0) {
  Throw "Failed to remove $($failures.Count) resource groups."
}

