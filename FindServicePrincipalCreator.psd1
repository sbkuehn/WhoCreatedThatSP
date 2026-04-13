@{
    RootModule        = 'FindServicePrincipalCreator.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '6e390f0d-315c-4b9f-a060-0cf4a781d8d1'
    Author            = 'Shannon Eldridge-Kuehn'
    CompanyName       = 'Shannon Eldridge-Kuehn'
    Copyright         = '(c) 2026 Shannon Eldridge-Kuehn. All rights reserved.'
    Description       = 'Utilities for investigating Microsoft Entra service principals and identifying likely creators via Microsoft Graph and Entra audit logs.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Connect-SEKGraph',
        'Get-SEKServicePrincipal',
        'Get-SEKServicePrincipalById',
        'Get-SEKServicePrincipalAuditEvent',
        'Get-SEKServicePrincipalCreator'
    )
    CmdletsToExport   = @()
    VariablesToExport = '*'
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('PowerShell', 'MicrosoftGraph', 'EntraID', 'ServicePrincipal', 'AuditLogs')
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            ProjectUri   = 'https://github.com/'
            ReleaseNotes = 'Initial module scaffold added alongside standalone scripts and REST examples.'
        }
    }
}
