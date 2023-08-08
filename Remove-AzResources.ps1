[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $SubscriptionId
)

$ErrorActionPreference = 'SilentlyContinue'

#Set subscription context
Set-AzContext -SubscriptionId $SubscriptionId

#Get all resource groups that are not tagged with 'persistent = true'
$ResourceGroups = Get-AzResourceGroup | Where-Object {$_.Tags['persistent'] -ne 'true'}

Write-Output "Found $($ResourceGroups.Count) resource groups to remove"

$ResourceGroups | ForEach-Object -Parallel {
    #Remove resource group
    Write-Output "Removing resource group: $($_.ResourceGroupName)"
    $result = Remove-AzResourceGroup -Name $_.ResourceGroupName -Force

    if ($result -eq $true) {
        Write-Output "Successfully removed resource group: $($_.ResourceGroupName)"
    }
    else {
        Write-Warning "Failed to remove resource group: $($_.ResourceGroupName)"
    }
}
