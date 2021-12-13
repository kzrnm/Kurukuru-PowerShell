@{

    # Script module or binary module file associated with this manifest.
    RootModule        = 'kurukuru-pwsh.psm1'

    # Version number of this module.
    ModuleVersion     = '1.1.1'

    # ID used to uniquely identify this module
    GUID              = '3efd22ec-7409-4f93-9d2b-8b78416e63fe'

    # Author of this module
    Author            = 'kzrnm'

    # Copyright statement for this module
    Copyright         = '(c) 2021 kzrnm'

    # Description of the functionality provided by this module
    Description       = 'This module is a wrrapper of Kurukuru.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Functions to export from this module
    FunctionsToExport = @(
        'Start-Kurukuru',
        'Get-KurukuruPattern'
    )

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport   = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess.
    # This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('Kurukuru', 'console')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/kzrnm/Kurukuru-PowerShell/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/kzrnm/Kurukuru-PowerShell'

            # ReleaseNotes of this module
            ReleaseNotes = 'https://github.com/kzrnm/Kurukuru-PowerShell/blob/master/CHANGELOG.md'
        }
    }
}
