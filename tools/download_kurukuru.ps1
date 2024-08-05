param (
    [switch]
    $NoDownload
)

$nupkgPath = "$PSScriptRoot/../tmp/kurukuru.nupkg"

if (-not $NoDownload) {
    mkdir tmp -Force
    Invoke-WebRequest "https://www.nuget.org/api/v2/package/Kurukuru/" -OutFile $nupkgPath
    if (Test-Path ./tmp/kurukuru) {
        Remove-Item -Recurse ./tmp/kurukuru -Force
    }
    Expand-Archive -Path $nupkgPath ./tmp/kurukuru
}

$dllPath = (Resolve-Path "$PSScriptRoot/../tmp/kurukuru/lib/netstandard2.0/Kurukuru.dll")
$currentDllPath = (Resolve-Path "$PSScriptRoot/../src/lib/Kurukuru.dll")

$assemblyVersionScriptBlock = {
    param($dllPath)
    $assembly = [System.Reflection.Assembly]::Load([System.IO.File]::ReadAllBytes($dllPath))
    Write-Output ($assembly.GetName().Version)
}

$downloadedAsmJob = Start-Job -ScriptBlock $assemblyVersionScriptBlock -ArgumentList $dllPath
$currentAsmJob = Start-Job -ScriptBlock $assemblyVersionScriptBlock -ArgumentList $currentDllPath

Wait-Job $downloadedAsmJob, $currentAsmJob | Out-Null

$downloadedAsmVersion = [Version](Receive-Job -Job $downloadedAsmJob)
$currentAsmVersion = [Version](Receive-Job -Job $currentAsmJob)


if ($downloadedAsmVersion.CompareTo($currentAsmVersion) -gt 0) {
    Copy-Item $dllPath "$PSScriptRoot/../tmp/New-Kurukuru.dll"

    Write-Output "Download new Kurukuru.dll $(Resolve-Path "$PSScriptRoot/../tmp/New-Kurukuru.dll")"
    Write-Output "kurukuru-version=$downloadedAsmVersion" >> $env:GITHUB_OUTPUT
}