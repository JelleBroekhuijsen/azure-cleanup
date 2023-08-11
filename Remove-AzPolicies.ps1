#requires -version 7
#requires -module Az
<#
.SYNOPSIS
  Script to delete all custom policies in a tenant
.DESCRIPTION
  Script to delete all custom policies in a tenant
.NOTES
  Version:        1.0.0
  Author:         Jelle Broekhuijsen - jll.io Consultancy
  Creation Date:  11/8/2023
  
.EXAMPLE
  ./Remove-AzManagementGroups.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

#Retrieve all custom Azure Policy definitions and initiatives
$policies = Get-AzPolicyDefinition | Where-Object { $_.Properties.PolicyType -eq 'Custom' }

$initiatives = Get-AzPolicySetDefinition | Where-Object { $_.Properties.PolicyType -eq 'Custom' }

#Remove all custom policies
Write-Output "Found $($policies.Count) custom policies to remove"
$policies | ForEach-Object -Parallel {
    Write-Output "Removing policy '$($_.Properties.DisplayName)'"
    $result = Remove-AzPolicyDefinition -Name $_.Name
    if($result -eq $null){
        Write-Warning "Failed to remove policy '$($_.Properties.DisplayName)'"
    }
}

#Remove all custom initiatives
Write-Output "Found $($initiatives.Count) custom initiatives to remove"
$initiatives | ForEach-Object -Parallel {
    Write-Output "Removing initiative '$($_.Properties.DisplayName)'"
    $result = Remove-AzPolicySetDefinition -Name $_.Name
    if($result -eq $null){
        Write-Warning "Failed to remove initiative '$($_.Properties.DisplayName)'"
    }
}
