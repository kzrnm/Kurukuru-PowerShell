try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch [System.IO.IOException] {}
[System.Reflection.Assembly]::LoadFile("$PSScriptRoot/lib/Kurukuru.dll")

$publicStaticBindingFlags = [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::Public
$InvalidPatternName = "Invalid Pattern Name"
function Add-PatternName {
    param (
        [Parameter(Mandatory = $true, Position = 0)][Kurukuru.Pattern]$Pattern,
        [Parameter(Mandatory = $true, Position = 1)][string]$Name
    )
    $result = [Kurukuru.Pattern]::new($Pattern.Frames, $Pattern.Interval)
    $result | Add-Member "Name" $Name
    $result
}


function Get-KurukuruPatternValue {
    [OutputType([Kurukuru.Pattern[]])]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]
        $Pattern
    )
    $field = [Kurukuru.Patterns].GetField($Pattern, $publicStaticBindingFlags)
    if (-not $field) {
        return $null
    }
    return $field.GetValue($null)
}

function Get-KurukuruPattern {
    [OutputType([Kurukuru.Pattern[]])]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]
        $Pattern
    )
    if ($Pattern) {
        $PatternValue = (Get-KurukuruPatternValue $Pattern)
        if (-not $PatternValue) {
            throw "${InvalidPatternName}: $Pattern"
        }
        return (Add-PatternName $PatternValue $Pattern)
    }
    return [Kurukuru.Patterns].GetFields($publicStaticBindingFlags) |
    Where-Object { $_.FieldType -EQ [Kurukuru.Pattern] } |
    ForEach-Object { Add-PatternName $_.GetValue($null) $_.Name }
}

function Start-Kurukuru {
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'WithInitialization')]
        [scriptblock]
        $InitializationScript,
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'WithoutInitialization')]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'WithInitialization')]
        [scriptblock]
        $ScriptBlock,
        [Parameter(Mandatory = $false)]
        [string]
        $Text,
        [Parameter(Mandatory = $false)]
        [string]
        $SucceedText,
        [Parameter(Mandatory = $false)]
        $Pattern
    )

    if ($ScriptBlock.Equals($InitializationScript)) {
        $InitializationScript = $null
    }

    if (-not $Pattern) {
        $Pattern = $null
    }
    elseif ($Pattern -is [Kurukuru.Pattern]) {
        $Pattern = [Kurukuru.Pattern]$Pattern
    }
    else {
        $Pattern = [Kurukuru.Pattern](Get-KurukuruPatternValue $Pattern)
        if (-not $Pattern) {
            Write-Warning "${InvalidPatternName}: $Pattern"
        }
    }

    $spinner = [Kurukuru.Spinner]::new($Text, $Pattern)
    if ($InitializationScript) {
        $InitializationScript.Invoke($spinner)
    }
    $spinner.Start()
    try {
        $ScriptBlock.Invoke($spinner)
        if (-not $SucceedText) {
            $SucceedText = $spinner.Text
        }
        $spinner.Succeed($SucceedText)
    }
    catch {
        $spinner.Fail($spinner.Text)
        throw
    }
    finally {
        $spinner.Dispose()
    }
}