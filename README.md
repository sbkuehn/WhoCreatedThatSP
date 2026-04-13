# Who Created that Service Principal?!?!?!?!?

Author: Shannon Eldridge-Kuehn

This repo contains the standalone scripts from the blog plus a reusable PowerShell module scaffold for tracing who created a service principal in Microsoft Entra ID with Microsoft Graph.

## Included scripts

### PowerShell scripts

- `src/01-Get-ServicePrincipal.ps1`
- `src/02-Get-AddServicePrincipalAuditEvents.ps1`
- `src/03-Match-ServicePrincipalToAuditEvent.ps1`
- `src/04-Find-ServicePrincipalCreator.ps1`
- `src/05-Get-ServicePrincipalByObjectId.ps1`

### PowerShell module

- `SPSleuth.psm1`
- `SPSleuth.psd1`

The module exports these functions:

- `Connect-SPSleuthGraph`
- `Get-SPSleuthServicePrincipal`
- `Get-SPSleuthServicePrincipalById`
- `Get-SPSleuthServicePrincipalAuditEvent`
- `Get-SPSleuthServicePrincipalCreator`

### REST examples

- `rest/get-service-principal.http`
- `rest/get-add-service-principal-audits.http`

## Requirements

- PowerShell 7+
- Microsoft Graph PowerShell SDK

Install the Graph SDK if needed:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

## Required Graph permissions

- Application.Read.All
- AuditLog.Read.All

## Example usage

```powershell
Import-Module ./SPSleuth.psd1 -Force
Connect-SPSleuthGraph
Get-SPSleuthServicePrincipalCreator -ServicePrincipalName "MyServicePrincipal"
```

## Notes

Entra audit log retention is limited unless you export logs elsewhere.

- Free: 7 days
- Entra ID P1/P2: 30 days

If the service principal was created outside that retention window and logs were not exported to Log Analytics, Sentinel, or storage, the creator may no longer be available.

## Repo structure

```text
src/
  01-Get-ServicePrincipal.ps1
  02-Get-AddServicePrincipalAuditEvents.ps1
  03-Match-ServicePrincipalToAuditEvent.ps1
  04-Find-ServicePrincipalCreator.ps1
  05-Get-ServicePrincipalByObjectId.ps1
rest/
  get-service-principal.http
  get-add-service-principal-audits.http
docs/
  rest-notes.md
SPSleuth.psm1
SPSleuth.psd1
README.md
LICENSE
.gitignore
```
