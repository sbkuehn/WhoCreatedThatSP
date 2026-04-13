<#
.SYNOPSIS
Retrieves a Microsoft Entra service principal directly by object ID.

.DESCRIPTION
Connects to Microsoft Graph and retrieves a service principal using its object ID.
This script is useful when you already have the service principal identifier and
want a direct lookup without relying on display name filtering.

.PARAMETER ServicePrincipalObjectId
The object ID of the service principal to retrieve.

.EXAMPLE
./05-Get-ServicePrincipalByObjectId.ps1 -ServicePrincipalObjectId "00000000-0000-0000-0000-000000000000"

.NOTES
Author: Shannon Eldridge-Kuehn
Created: 2026-03-14
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServicePrincipalObjectId
)

$ErrorActionPreference = 'Stop'

try {
    Connect-MgGraph -Scopes "Application.Read.All" -NoWelcome | Out-Null

    Get-MgServicePrincipal -ServicePrincipalId $ServicePrincipalObjectId `
        -Property Id, AppId, DisplayName, CreatedDateTime |
        Select-Object Id, AppId, DisplayName, CreatedDateTime
}
catch {
    Write-Error ("Failed to retrieve service principal object ID '{0}'. {1}" -f $ServicePrincipalObjectId, $_.Exception.Message)
    throw
}
