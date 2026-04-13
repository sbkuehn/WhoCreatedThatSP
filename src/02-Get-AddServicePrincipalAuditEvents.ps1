<#
.SYNOPSIS
Retrieves Add service principal audit events from Microsoft Entra audit logs.

.DESCRIPTION
Connects to Microsoft Graph and retrieves directory audit log entries where the activity
display name is 'Add service principal'. This is useful when reviewing service principal
creation activity across a tenant or preparing to correlate a specific service principal
to its originating audit event.

.EXAMPLE
./02-Get-AddServicePrincipalAuditEvents.ps1

.NOTES
Author: Shannon Eldridge-Kuehn
Created: 2026-04-12
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

try {
    Connect-MgGraph -Scopes "AuditLog.Read.All" -NoWelcome | Out-Null

    Get-MgAuditLogDirectoryAudit -Filter "activityDisplayName eq 'Add service principal'" |
        Select-Object ActivityDateTime, InitiatedBy, TargetResources, AdditionalDetails
}
catch {
    Write-Error ("Failed to retrieve Add service principal audit events. {0}" -f $_.Exception.Message)
    throw
}
