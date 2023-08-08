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
  Version:        1.0
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

$ErrorActionPreference = 'SilentlyContinue'

#Get all management groups except the root group
$managementGroups = Get-AzManagementGroup | Where-Object { $_.Name -ne $TenantId }

#Get all subscriptions
$subscriptions = Get-AzSubscription

#Get all management group assignments for non-root assignme
$assignments = $managementGroups | ForEach-Object {
    Get-AzManagementGroupSubscription -GroupName $_.Name 
}

#Reset all subscriptions to the root group
$assignments | ForEach-Object -Parallel {
    Write-Output "Reset subscription: $(($_.Id -split '/')[-1]) to root group"
    $result = Remove-AzManagementGroupSubscription -GroupName ($_.Parent -split '/')[-1]  -SubscriptionId ($_.Id -split '/')[-1]
}

#Remove the entire hierachy of management groups
Write-Output "Attempting to remove $($managementGroups.Count) management groups"
$lingeringManagementGroupCount = 0 
do{
  $managementGroups | ForEach-Object -Parallel {
    $managementGroup = Get-AzManagementGroup -GroupName $_.Name -ErrorAction SilentlyContinue
    if($null -ne $managementGroup){
      Write-Output "Attempting to remove management group: $($managementGroup.Name)"
      Remove-AzManagementGroup -GroupName $managementGroup.Name -ErrorAction SilentlyContinue
    }
    else{
      Write-Output "Deleted management group '$($_.Name)' added to lingering management group count"
      $lingeringManagementGroupCount++
    }
  }
  $managementGroups = Get-AzManagementGroup | Where-Object { $_.Name -ne $TenantId }
  if($managementGroups.Count -gt 0 -and $lingeringManagementGroupCount -lt $managementGroups.Count){
    Write-Output "Found $($managementGroups.Count - $lingeringManagementGroupCount) remaining management groups to remove"
    Write-Output "Waiting 30 seconds before retrying"
    $lingeringManagementGroupCount = 0
    Start-Sleep -Seconds 30
  }
}
while($managementGroups.Count -gt 0 -and $lingeringManagementGroupCount -lt $managementGroups.Count)
Write-Output "Successfully removed all management groups"
