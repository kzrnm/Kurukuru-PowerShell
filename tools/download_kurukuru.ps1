param (
    [switch]
    $NoDownload
)

$nupkgPath = "$PSScriptRoot/../tmp/kurukuru.nupkg"

if (-not $NoDownload) {
    mkdir tmp
    Invoke-WebRequest "https://www.nuget.org/api/v2/package/Kurukuru/" -OutFile $nupkgPath
    Expand-Archive -Path $nupkgPath ./tmp/kurukuru
}

$dllPath = (Resolve-Path "$PSScriptRoot/../tmp/kurukuru/lib/netstandard2.0/Kurukuru.dll")
$currentDllPath = (Resolve-Path "$PSScriptRoot/../lib/Kurukuru.dll")

$assemblyVersionScriptBlock = {
    param($dllPath)
    Write-Output ([System.Reflection.Assembly]::LoadFile($dllPath).GetName().Version)
}

$downloadedAsmJob = Start-Job -ScriptBlock $assemblyVersionScriptBlock -ArgumentList $dllPath
$currentAsmJob = Start-Job -ScriptBlock $assemblyVersionScriptBlock -ArgumentList $currentDllPath

Wait-Job $downloadedAsmJob, $currentAsmJob | Out-Null

$downloadedAsmVersion = [Version](Receive-Job -Job $downloadedAsmJob)
$currentAsmVersion = [Version](Receive-Job -Job $currentAsmJob)


if ($downloadedAsmVersion.CompareTo($currentAsmVersion) -gt 0) {
    Copy-Item $dllPath "$PSScriptRoot/../tmp/New-Kurukuru.dll"

    Write-Output "Download new Kurukuru.dll $(Resolve-Path "$PSScriptRoot/../tmp/New-Kurukuru.dll")"
    Write-Output "::set-output name=kurukuru-version::$downloadedAsmVersion"
}