#requires -version 7
#requires -module Az
<#
.SYNOPSIS
  Script to delete all custom policies in a tenant
.DESCRIPTION
  Script to delete all custom policies in a tenant
.NOTES
  Version:        1.1.1
  Author:         Jelle Broekhuijsen - jll.io Consultancy
  Last Update:  4/9/2023
  
.EXAMPLE
  ./Remove-AzPolicies.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

#Retrieve all custom Azure Policy assignments, definitions and initiatives
$assignments = Get-AzPolicyAssignment -ErrorAction Stop | Where-Object { $_.Properties.PolicyType -eq 'Custom' }
$policies = Get-AzPolicyDefinition -ErrorAction Stop | Where-Object { $_.Properties.PolicyType -eq 'Custom' }
$initiatives = Get-AzPolicySetDefinition -ErrorAction Stop| Where-Object { $_.Properties.PolicyType -eq 'Custom' }

#Create a concurrent bag to store failures
$failures = [System.Collections.Concurrent.ConcurrentBag[PSObject]]::new()

#Remove all custom assignments
Write-Output "Found $($assignments.Count) custom assignments to remove."
$assignments | ForEach-Object -Parallel {
  $localFailures = $using:failures
  Write-Output "Removing assignment '$($_.Properties.DisplayName)'..."
  $result = Remove-AzPolicyAssignment -Id $_.ResourceId -Force
  if ($result -ne $true) {
    Write-Warning "Failed to remove assignment '$($_.Properties.DisplayName)'."
    $localFailures.Add($_)
  }
}

#Remove all custom initiatives
Write-Output "Found $($initiatives.Count) custom initiatives to remove."
$initiatives | ForEach-Object -Parallel {
  $localFailures = $using:failures
  Write-Output "Removing initiative '$($_.Properties.DisplayName)'."
  $result = Remove-AzPolicySetDefinition -Id $_.ResourceId -Force
  if ($result -ne $true) {
    Write-Warning "Failed to remove initiative '$($_.Properties.DisplayName)'."
    $localFailures.Add($_)
  }
}

#Remove all custom policies
Write-Output "Found $($policies.Count) custom policies to remove."
$policies | ForEach-Object -Parallel {
  $localFailures = $using:failures
  Write-Output "Removing policy '$($_.Properties.DisplayName)'..."
  $result = Remove-AzPolicyDefinition -Id $_.ResourceId -Force
  if ($result -ne $true) {
    Write-Warning "Failed to remove policy '$($_.Properties.DisplayName)'."
    $localFailures.Add($_)
  }
}

#Report failures
if ($failures.Count -gt 0) {
  Throw "Failed to remove $($failures.count) policies/initiatives."
}
