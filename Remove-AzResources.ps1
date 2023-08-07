[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $SubscriptionId
)

#Set subscription context
Set-AzContext -SubscriptionId $SubscriptionId

#Get all resource groups that are not tagged with 'persistent = true'
$ResourceGroups = Get-AzResourceGroup | Where-Object {$_.Tags['persistent'] -ne 'true'}

$ResourceGroups | ForEach-Object {
    #Remove resource group
    Write-Output "Removing resource group: $($_.ResourceGroupName)"
    Remove-AzResourceGroup -Name $_.ResourceGroupName -Force
}
