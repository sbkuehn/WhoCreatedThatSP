<#
.SYNOPSIS
Matches a service principal to its related Add service principal audit events.

.DESCRIPTION
Retrieves a service principal by display name, then queries Microsoft Entra directory
audit logs for Add service principal events and returns the matching audit records for
the target object. This script is helpful when you want to inspect all matching creation
records before deciding which event is the best fit.

.PARAMETER ServicePrincipalName
The display name of the service principal to correlate to audit events.

.EXAMPLE
./03-Match-ServicePrincipalToAuditEvent.ps1 -ServicePrincipalName "MyServicePrincipal"

.NOTES
Author: Shannon Eldridge-Kuehn
Created: 2026-04-12
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

    $audits = Get-MgAuditLogDirectoryAudit -Filter "activityDisplayName eq 'Add service principal'"

    $matches = $audits | Where-Object {
        $_.TargetResources.Id -contains $servicePrincipal.Id
    }

    if (-not $matches) {
        Write-Warning ("No matching Add service principal audit events were found for '{0}'." -f $ServicePrincipalName)
        return
    }

    $matches | Select-Object ActivityDateTime, InitiatedBy, TargetResources, AdditionalDetails
}
catch {
    Write-Error ("Failed to match service principal '{0}' to audit events. {1}" -f $ServicePrincipalName, $_.Exception.Message)
    throw
}
