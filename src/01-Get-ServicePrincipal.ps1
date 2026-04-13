<#
.SYNOPSIS
Retrieves a Microsoft Entra service principal and returns core metadata from Microsoft Graph.

.DESCRIPTION
Connects to Microsoft Graph with the minimum read scope needed to query service principals,
retrieves a service principal by display name, and returns the display name, object ID,
application ID, and created date. This script is intended as a lightweight lookup utility
that can be used independently or as part of a larger investigation workflow.

.PARAMETER ServicePrincipalName
The display name of the service principal to retrieve.

.EXAMPLE
./01-Get-ServicePrincipal.ps1 -ServicePrincipalName "MyServicePrincipal"

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
    Connect-MgGraph -Scopes "Application.Read.All" -NoWelcome | Out-Null

    $servicePrincipal = Get-MgServicePrincipal -Filter "displayName eq '$ServicePrincipalName'" `
        -Property Id, AppId, DisplayName, CreatedDateTime

    if (-not $servicePrincipal) {
        Write-Warning ("Service principal '{0}' was not found." -f $ServicePrincipalName)
        return
    }

    $servicePrincipal | Select-Object DisplayName, Id, AppId, CreatedDateTime
}
catch {
    Write-Error ("Failed to retrieve service principal '{0}'. {1}" -f $ServicePrincipalName, $_.Exception.Message)
    throw
}
