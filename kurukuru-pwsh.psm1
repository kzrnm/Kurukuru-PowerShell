$publicStaticBindingFlags = [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::Public
$PatternsFields = [System.Reflection.FieldInfo[]]([Kurukuru.Patterns].GetFields($publicStaticBindingFlags) | Where-Object { $_.FieldType -EQ [Kurukuru.Pattern] })
$InvalidPatternName = "Invalid Pattern Name"
function AddPatternName {
    param (
        [Parameter(Mandatory = $true, Position = 0)][Kurukuru.Pattern]$Pattern,
        [Parameter(Mandatory = $true, Position = 1)][string]$Name
    )
    $result = [Kurukuru.Pattern]::new($Pattern.Frames, $Pattern.Interval)
    $result | Add-Member "Name" $Name
    $result
}

function ConvertToSymbolDefinition {
    [OutputType([Kurukuru.SymbolDefinition])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        $StringOrSymbol
    )
    if ($StringOrSymbol -is [Kurukuru.SymbolDefinition]) {
        return $StringOrSymbol
    }
    else {
        return [Kurukuru.SymbolDefinition]::new($StringOrSymbol, $null)
    }
}

function GetKurukuruPatternValue {
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
        $PatternValue = (GetKurukuruPatternValue $Pattern)
        if (-not $PatternValue) {
            throw "${InvalidPatternName}: $Pattern"
        }
        return (AddPatternName $PatternValue $Pattern)
    }
    return $PatternsFields | ForEach-Object { AddPatternName $_.GetValue($null) $_.Name }
}
function Show-KurukuruSample {
    param (
        [Parameter(Mandatory = $false)]
        [int]
        $ParallelLimit = 10,
        [Parameter(Mandatory = $false)]
        [int]
        $Seconds = 2
    )
    
    Get-KurukuruPattern | ForEach-Object -ThrottleLimit $ParallelLimit -Parallel {
        Start-Kurukuru -Text $_.Name -Pattern $_ { Start-Sleep -Seconds $using:Seconds }
    }
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
        [string]
        $FailedText,
        [Parameter(Mandatory = $false)]
        $Pattern,
        [Parameter(Mandatory = $false)]
        [Nullable[System.ConsoleColor]]
        $Color,
        [Parameter(Mandatory = $false)]
        $SymbolSucceed,
        [Parameter(Mandatory = $false)]
        $SymbolFailed,
        [Parameter(Mandatory = $false)]
        $SymbolWarn,
        [Parameter(Mandatory = $false)]
        $SymbolInfo
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
        $Pattern = [Kurukuru.Pattern](GetKurukuruPatternValue $Pattern)
        if (-not $Pattern) {
            Write-Warning "${InvalidPatternName}: $Pattern"
        }
    }

    $spinner = [Kurukuru.Spinner]::new($Text, $Pattern)
    $spinner.Color = $Color
    
    if ($SymbolSucceed) {
        $symbol = (ConvertToSymbolDefinition $SymbolSucceed)
        if ($symbol.Fallback) {
            $spinner.SymbolSucceed = $symbol
        }
        else {
            $spinner.SymbolSucceed = [Kurukuru.SymbolDefinition]::new($symbol.Default, $spinner.SymbolSucceed.Fallback)
        }
    }
    if ($SymbolFailed) {
        $symbol = (ConvertToSymbolDefinition $SymbolFailed)
        if ($symbol.Fallback) {
            $spinner.SymbolFailed = $symbol
        }
        else {
            $spinner.SymbolFailed = [Kurukuru.SymbolDefinition]::new($symbol.Default, $spinner.SymbolFailed.Fallback)
        }
    }
    if ($SymbolWarn) {
        $symbol = (ConvertToSymbolDefinition $SymbolWarn)
        if ($symbol.Fallback) {
            $spinner.SymbolWarn = $symbol
        }
        else {
            $spinner.SymbolWarn = [Kurukuru.SymbolDefinition]::new($symbol.Default, $spinner.SymbolWarn.Fallback)
        }
    }
    if ($SymbolInfo) {
        $symbol = (ConvertToSymbolDefinition $SymbolInfo)
        if ($symbol.Fallback) {
            $spinner.SymbolInfo = $symbol
        }
        else {
            $spinner.SymbolInfo = [Kurukuru.SymbolDefinition]::new($symbol.Default, $spinner.SymbolInfo.Fallback)
        }
    }

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
        if (-not $FailedText) {
            $FailedText = $spinner.Text
        }
        $spinner.Fail($FailedText)
        throw
    }
    finally {
        $spinner.Dispose()
    }
}

function CreateArgumentCompleter {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]]$Names
    )
    {
        param(
            $commandName,
            $parameterName,
            $wordToComplete,
            $commandAst,
            $fakeBoundParameter
        )
        
        if ($wordToComplete.Length -eq 0) { return $Names }
        foreach ($item in $Names) {
            if ($item.ToLower().StartsWith($wordToComplete.ToLower())) {
                [System.Management.Automation.CompletionResult]::new(
                    $item,
                    $item,
                    [System.Management.Automation.CompletionResultType]::ParameterValue, 
                    $item) 
            }
        }
    }.GetNewClosure()
}

Register-ArgumentCompleter -CommandName Start-Kurukuru, Get-KurukuruPattern -ParameterName Pattern -ScriptBlock (
    CreateArgumentCompleter -Names ($PatternsFields.Name)
)
Register-ArgumentCompleter -CommandName Start-Kurukuru -ParameterName Color -ScriptBlock (
    CreateArgumentCompleter -Names ([System.Enum]::GetNames([System.ConsoleColor]))
)