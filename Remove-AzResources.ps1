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
  Version:        1.1.0
  Author:         Jelle Broekhuijsen - jll.io Consultancy
  Creation Date:  8/8/2023
  
.EXAMPLE
  ./Remove-AzResources.ps1 -SubscriptionId 00000000-0000-0000-0000-000000000000
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $SubscriptionId
)

$ErrorActionPreference = 'SilentlyContinue'

#Set subscription context
$subscription = Set-AzContext -SubscriptionId $SubscriptionId
Write-Output "Connected to Azure subscription: $($subscription.Name)"

#Get all resource groups that are not tagged with 'persistent = true'
$resourceGroups = Get-AzResourceGroup
$resourceGroupsWithoutPersistence = @()

$resourceGroups | ForEach-Object -Parallel {
    if($null -eq $_.Tags){
        Write-Output "Resource group '$($_.ResourceGroupName)' has no tags, marking for removal..."
        $resourceGroupsWithoutPersistence += $_
    }
    elseif($null -eq $_.Tags.persistent){
        Write-Output "Resource group '$($_.ResourceGroupName)' has no 'persistent' tag, marking for removal..."
        $resourceGroupsWithoutPersistence += $_
    }
    elseif($_.Tags.persistent -ne 'true'){
        Write-Output "Resource group '$($_.ResourceGroupName)' has 'persistent' tag set to '$($_.Tags.persistent)', marking for removal..."
        $resourceGroupsWithoutPersistence += $_
    }
}

Write-Output "Found $($resourceGroupsWithoutPersistence.Count) resource groups to remove"

#Terminate if no resource groups are found
if($resourceGroupsWithoutPersistence.Count -eq 0){
    Write-Output "No resource groups to remove"
    break
}

#Remove resource groups
$resourceGroupsWithoutPersistence | ForEach-Object -Parallel {
    Write-Output "Removing resource group: $($_.ResourceGroupName)"
    $result = Remove-AzResourceGroup -Name $_.ResourceGroupName -Force

    if ($result -eq $true) {
        Write-Output "Successfully removed resource group: $($_.ResourceGroupName)"
    }
    else {
        Write-Warning "Failed to remove resource group: $($_.ResourceGroupName)"
    }
}
