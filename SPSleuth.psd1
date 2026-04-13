@{
    RootModule        = 'SPSleuth.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '18fc3141-e9b2-4126-9e73-d4d95b69de31'
    Author            = 'Shannon Eldridge-Kuehn'
    CompanyName       = 'Shannon Eldridge-Kuehn'
    Copyright         = '(c) 2026 Shannon Eldridge-Kuehn. All rights reserved.'
    Description       = 'Utilities for investigating Microsoft Entra service principals and identifying likely creators via Microsoft Graph and Entra audit logs.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Connect-SPSleuthGraph',
        'Get-SPSleuthServicePrincipal',
        'Get-SPSleuthServicePrincipalById',
        'Get-SPSleuthServicePrincipalAuditEvent',
        'Get-SPSleuthServicePrincipalCreator'
    )
    CmdletsToExport   = @()
    VariablesToExport = '*'
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('PowerShell', 'MicrosoftGraph', 'EntraID', 'ServicePrincipal', 'AuditLogs')
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            ProjectUri   = 'https://github.com/'
            ReleaseNotes = 'Renamed module and exported functions to SPSleuth.'
        }
    }
}
