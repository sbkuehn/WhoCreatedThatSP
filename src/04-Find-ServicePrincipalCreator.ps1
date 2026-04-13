<#
.SYNOPSIS
Finds the likely creator of a Microsoft Entra service principal by correlating Graph object data with audit logs.

.DESCRIPTION
Retrieves a service principal by display name, captures its core metadata, then queries
Microsoft Entra directory audit logs for Add service principal events and attempts to
identify the best matching creation record. The script reports the service principal
details, the matching audit event, the initiator, and any additional audit properties
that may help explain how or why the object was created.

.PARAMETER ServicePrincipalName
The display name of the service principal to investigate.

.EXAMPLE
./04-Find-ServicePrincipalCreator.ps1 -ServicePrincipalName "MyServicePrincipal"

.NOTES
Author: Shannon Eldridge-Kuehn
Created: 2026-03-14
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServicePrincipalName
)

$ErrorActionPreference = 'Stop'

try {
    Connect-MgGraph -Scopes "Application.Read.All", "AuditLog.Read.All" -NoWelcome | Out-Null

    $servicePrincipal = Get-MgServicePrincipal -Filter "displayName eq '$ServicePrincipalName'" `
        -Property Id, AppId, DisplayName, CreatedDateTime

    if (-not $servicePrincipal) {
        Write-Warning ("Service principal '{0}' was not found." -f $ServicePrincipalName)
        return
    }

    Write-Host "Service Principal:"
    Write-Host ("  Name:        {0}" -f $servicePrincipal.DisplayName)
    Write-Host ("  Object ID:   {0}" -f $servicePrincipal.Id)
    Write-Host ("  App ID:      {0}" -f $servicePrincipal.AppId)
    Write-Host ("  Created:     {0}" -f $servicePrincipal.CreatedDateTime)
    Write-Host ""

    $audits = Get-MgAuditLogDirectoryAudit -Filter "activityDisplayName eq 'Add service principal'"

    $match = $audits | Where-Object {
        $_.TargetResources.Id -contains $servicePrincipal.Id
    } | Sort-Object ActivityDateTime -Descending | Select-Object -First 1

    if (-not $match) {
        Write-Warning "No matching Add service principal audit event was found. Audit logs may have aged out."
        return
    }

    $initiatedByUser = $match.InitiatedBy.User.UserPrincipalName
    $initiatedByApp  = $match.InitiatedBy.App.DisplayName

    if ($initiatedByUser) {
        $initiator = $initiatedByUser
    }
    elseif ($initiatedByApp) {
        $initiator = $initiatedByApp
    }
    else {
        $initiator = "Unknown"
    }

    Write-Host "Creation Audit Event:"
    Write-Host ("  Activity Time:   {0}" -f $match.ActivityDateTime)
    Write-Host ("  Initiated By:    {0}" -f $initiator)
    Write-Host ("  Logged By:       {0}" -f $match.LoggedByService)
    Write-Host ("  Category:        {0}" -f $match.Category)
    Write-Host ""

    if ($match.AdditionalDetails) {
        Write-Host "Additional Details:"
        foreach ($detail in $match.AdditionalDetails) {
            Write-Host ("  {0}: {1}" -f $detail.Key, $detail.Value)
        }
    }
}
catch {
    Write-Error ("Failed to determine the creator for service principal '{0}'. {1}" -f $ServicePrincipalName, $_.Exception.Message)
    throw
}
