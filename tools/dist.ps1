[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $TagName
)

#Install-Module PowerShellGet -Scope CurrentUser -Force -AllowClobber
$module = "kurukuru-pwsh"
if (Test-Path "$module") {
    Remove-Item -Recurse "$module/"
}
mkdir $module

Copy-Item * -Recurse -Destination $module -Exclude $module, tools, .github, .gitignore, .vscode, src
Copy-Item src/* -Recurse -Destination $module -Exclude $module, tools, .github, .gitignore, .vscode, src

(Get-Content "./src/$module.psd1" -Raw).Replace('blob/master', "blob/$TagName") | Out-File -Encoding utf8NoBOM -FilePath "./$module/$module.psd1"
