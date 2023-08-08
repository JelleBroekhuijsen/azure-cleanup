#requires -version 7
#requires -module Az
<#
.SYNOPSIS
  Script to delete all management groups in a tenant and resets all subscriptions to the tenant root group
.DESCRIPTION
  Script to delete all management groups in a tenant and resets all subscriptions to the tenant root group
.NOTES
  Version:        1.0
  Author:         Jelle Broekhuijsen - jll.io Consultancy
  Creation Date:  8/8/2023
  
.EXAMPLE
  ./Remove-AzManagementGroups.ps1
#>

$ErrorActionPreference = 'SilentlyContinue'

#Get all management groups
$managementGroups = Get-AzManagementGroup -Recurse

Write-Output $managementGroups