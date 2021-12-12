[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $TagName
)

#Install-Module PowerShellGet -Scope CurrentUser -Force -AllowClobber
$dist = "kurukuru-pwsh"

mkdir $dist

Copy-Item * -Recurse -Destination $dist -Exclude $dist, tools, .github, .gitignore

(Get-Content ./kurukuru-pwsh.psd1 -Raw).Replace('Kurukuru-PowerShell/blob/master', "Kurukuru-PowerShell/blob/$TagName") | Out-File -Encoding utf8NoBOM -FilePath ./$dist/kurukuru-pwsh.psd1