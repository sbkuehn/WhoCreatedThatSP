function Connect-SPSleuthGraph {
<#
.SYNOPSIS
Connects to Microsoft Graph with the scopes required for service principal investigations.

.DESCRIPTION
Establishes a Microsoft Graph session using the provided scopes. If no scopes are supplied,
the function connects with both Application.Read.All and AuditLog.Read.All, which are the
core permissions needed for the functions in this module.

.PARAMETER Scopes
One or more Microsoft Graph scopes to request during connection.

.EXAMPLE
Connect-SPSleuthGraph

.EXAMPLE
Connect-SPSleuthGraph -Scopes "Application.Read.All"

.NOTES
Author: Shannon Eldridge-Kuehn
Created: 2026-04-12
#>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$Scopes = @("Application.Read.All", "AuditLog.Read.All")
    )

    $ErrorActionPreference = 'Stop'

    try {
        Connect-MgGraph -Scopes $Scopes -NoWelcome | Out-Null
    }
    catch {
        Write-Error ("Failed to connect to Microsoft Graph. {0}" -f $_.Exception.Message)
        throw
    }
}

function Get-SPSleuthServicePrincipal {
<#
.SYNOPSIS
Gets a Microsoft Entra service principal by display name.

.DESCRIPTION
Retrieves a service principal by display name and returns structured object output that
includes the display name, object ID, application ID, and created date.

.PARAMETER ServicePrincipalName
The display name of the service principal to retrieve.

.EXAMPLE
Get-SPSleuthServicePrincipal -ServicePrincipalName "MyServicePrincipal"

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
}

function Get-SPSleuthServicePrincipalById {
<#
.SYNOPSIS
Gets a Microsoft Entra service principal by object ID.

.DESCRIPTION
Retrieves a service principal directly by object ID and returns core metadata for the object.

.PARAMETER ServicePrincipalObjectId
The object ID of the service principal to retrieve.

.EXAMPLE
Get-SPSleuthServicePrincipalById -ServicePrincipalObjectId "00000000-0000-0000-0000-000000000000"

.NOTES
Author: Shannon Eldridge-Kuehn
Created: 2026-04-12
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServicePrincipalObjectId
    )

    $ErrorActionPreference = 'Stop'

    try {
        Get-MgServicePrincipal -ServicePrincipalId $ServicePrincipalObjectId `
            -Property Id, AppId, DisplayName, CreatedDateTime |
            Select-Object Id, AppId, DisplayName, CreatedDateTime
    }
    catch {
        Write-Error ("Failed to retrieve service principal object ID '{0}'. {1}" -f $ServicePrincipalObjectId, $_.Exception.Message)
        throw
    }
}

function Get-SPSleuthServicePrincipalAuditEvent {
<#
.SYNOPSIS
Gets Add service principal audit events from Microsoft Entra audit logs.

.DESCRIPTION
Returns audit log records where the activity display name is Add service principal. If a
service principal name is supplied, the function attempts to match the returned records
to the target service principal object.

.PARAMETER ServicePrincipalName
Optional display name of the service principal to match to audit records.

.EXAMPLE
Get-SPSleuthServicePrincipalAuditEvent

.EXAMPLE
Get-SPSleuthServicePrincipalAuditEvent -ServicePrincipalName "MyServicePrincipal"

.NOTES
Author: Shannon Eldridge-Kuehn
Created: 2026-04-12
#>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ServicePrincipalName
    )

    $ErrorActionPreference = 'Stop'

    try {
        $audits = Get-MgAuditLogDirectoryAudit -Filter "activityDisplayName eq 'Add service principal'"

        if ([string]::IsNullOrWhiteSpace($ServicePrincipalName)) {
            return $audits | Select-Object ActivityDateTime, InitiatedBy, TargetResources, AdditionalDetails
        }

        $servicePrincipal = Get-MgServicePrincipal -Filter "displayName eq '$ServicePrincipalName'" `
            -Property Id, AppId, DisplayName, CreatedDateTime

        if (-not $servicePrincipal) {
            Write-Warning ("Service principal '{0}' was not found." -f $ServicePrincipalName)
            return
        }

        $audits | Where-Object {
            $_.TargetResources.Id -contains $servicePrincipal.Id
        } | Select-Object ActivityDateTime, InitiatedBy, TargetResources, AdditionalDetails
    }
    catch {
        Write-Error ("Failed to retrieve service principal audit events. {0}" -f $_.Exception.Message)
        throw
    }
}

function Get-SPSleuthServicePrincipalCreator {
<#
.SYNOPSIS
Gets the likely creator of a Microsoft Entra service principal.

.DESCRIPTION
Correlates a service principal object with Add service principal audit events in Microsoft
Entra and returns a structured object with service principal metadata, the matching audit
event timestamp, the initiator, and additional audit details when present.

.PARAMETER ServicePrincipalName
The display name of the service principal to investigate.

.EXAMPLE
Get-SPSleuthServicePrincipalCreator -ServicePrincipalName "MyServicePrincipal"

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
        $servicePrincipal = Get-MgServicePrincipal -Filter "displayName eq '$ServicePrincipalName'" `
            -Property Id, AppId, DisplayName, CreatedDateTime

        if (-not $servicePrincipal) {
            Write-Warning ("Service principal '{0}' was not found." -f $ServicePrincipalName)
            return
        }

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

        [PSCustomObject]@{
            DisplayName        = $servicePrincipal.DisplayName
            ServicePrincipalId = $servicePrincipal.Id
            AppId              = $servicePrincipal.AppId
            CreatedDateTime    = $servicePrincipal.CreatedDateTime
            ActivityDateTime   = $match.ActivityDateTime
            InitiatedBy        = $initiator
            LoggedByService    = $match.LoggedByService
            Category           = $match.Category
            AdditionalDetails  = $match.AdditionalDetails
        }
    }
    catch {
        Write-Error ("Failed to determine the creator for service principal '{0}'. {1}" -f $ServicePrincipalName, $_.Exception.Message)
        throw
    }
}

Export-ModuleMember -Function Connect-SPSleuthGraph, Get-SPSleuthServicePrincipal, Get-SPSleuthServicePrincipalById, Get-SPSleuthServicePrincipalAuditEvent, Get-SPSleuthServicePrincipalCreator
