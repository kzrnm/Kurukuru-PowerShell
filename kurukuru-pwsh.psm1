$publicStaticBindingFlags = [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::Public
$DefinedPatterns = [Kurukuru.Patterns].GetFields($publicStaticBindingFlags) | Where-Object {
    $_.FieldType -EQ [Kurukuru.Pattern]
} | ForEach-Object {
    $ret = $_.GetValue($null)
    $ret | Add-Member 'Name' $_.Name
    return $ret
}
$DefinedPatternsTable = @{}
foreach ($p in $DefinedPatterns) {
    $DefinedPatternsTable[$p.Name] = $p
}

$InvalidPatternName = "Invalid Pattern Name"

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
        return [Kurukuru.SymbolDefinition]::new($StringOrSymbol, $StringOrSymbol)
    }
}

function Get-KurukuruPattern {
    [OutputType([Kurukuru.Pattern[]])]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]
        $Pattern
    )
    if ($Pattern) {
        return $DefinedPatternsTable[$Pattern]
    }
    return $DefinedPatterns
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
    [CmdletBinding()]
    [OutputType([Kurukuru.Spinner[]])]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Spinner', ValueFromPipeline)]
        [Kurukuru.Spinner[]]
        $Spinner,
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'WithInitialization')]
        [scriptblock]
        $InitializationScript,
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'WithoutInitialization')]
        [Parameter(Mandatory, Position = 1, ParameterSetName = 'WithInitialization')]
        [scriptblock]
        $ScriptBlock,
        [Parameter(ParameterSetName = 'WithoutInitialization')]
        [Parameter(ParameterSetName = 'WithInitialization')]
        [string]
        $Text = '',
        [Parameter(ParameterSetName = 'WithoutInitialization')]
        [Parameter(ParameterSetName = 'WithInitialization')]
        [string]
        $SucceedText = $null,
        [Parameter(ParameterSetName = 'WithoutInitialization')]
        [Parameter(ParameterSetName = 'WithInitialization')]
        [string]
        $FailedText = $null,
        [Parameter(ParameterSetName = 'WithoutInitialization')]
        [Parameter(ParameterSetName = 'WithInitialization')]
        $Pattern = $null,
        [Parameter(ParameterSetName = 'WithoutInitialization')]
        [Parameter(ParameterSetName = 'WithInitialization')]
        [Nullable[System.ConsoleColor]]
        $Color = $null,
        [Parameter(ParameterSetName = 'WithoutInitialization')]
        [Parameter(ParameterSetName = 'WithInitialization')]
        $SymbolSucceed = $null,
        [Parameter(ParameterSetName = 'WithoutInitialization')]
        [Parameter(ParameterSetName = 'WithInitialization')]
        $SymbolFailed = $null,
        [Parameter(ParameterSetName = 'WithoutInitialization')]
        [Parameter(ParameterSetName = 'WithInitialization')]
        $SymbolWarn = $null,
        [Parameter(ParameterSetName = 'WithoutInitialization')]
        [Parameter(ParameterSetName = 'WithInitialization')]
        $SymbolInfo = $null,
        [Parameter(ParameterSetName = 'Spinner')]
        [switch] $PassThru
    )
    begin {
        $Spinners = [System.Collections.ArrayList]::new()
        if ($PSCmdlet.ParameterSetName -in @('WithoutInitialization', 'WithInitialization')) {
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
                $Pattern = [Kurukuru.Pattern]$DefinedPatternsTable[$Pattern]
                if (-not $Pattern) {
                    Write-Warning "${InvalidPatternName}: $Pattern"
                }
            }

            $s = New-Spinner `
                -Text $Text `
                -Pattern $Pattern `
                -Color $Color `
                -SymbolSucceed $SymbolSucceed `
                -SymbolFailed $SymbolFailed `
                -SymbolWarn $SymbolWarn `
                -SymbolINfo $SymbolINfo `
                -SucceedText $SucceedText `
                -FailedText $FailedText `
                -ScriptBlock $ScriptBlock

            if ($InitializationScript) {
                $InitializationScript.InvokeWithContext($null, ([psvariable]::new('_', $s)), @($s))
            }
            $Spinners.Add($s) | Out-Null
        }
    }
    process {
        if ($Spinner) {
            $Spinners.AddRange($Spinner) | Out-Null
        }
    }
    end {
        try {
            foreach ($s in $Spinners) {
                $s.Start() | Out-Null
            }
    
            $jobScript = {
                param([Kurukuru.Spinner]$s)
                try {
                    if ($s.ScriptBlock) {
                        & $s.ScriptBlock $s
                    }
                    $text = $s.SucceedText
                    if (-not $text) {
                        $text = $s.Text
                    }
                    $s.Succeed($text)
                }
                catch {
                    $text = $s.FailedText
                    if (-not $text) {
                        $text = $s.Text
                    }
                    $s.Fail($text)
                }
            }

            if (Get-Command Start-ThreadJob) {
                $Spinners | ForEach-Object {
                    Start-ThreadJob -ThrottleLimit 1000000 -ScriptBlock $jobScript -ArgumentList @($_)
                } | Receive-Job -Wait -AutoRemoveJob | Out-Null
            }
            if ($PassThru) {
                return $Spinners
            }
            return
        }
        finally {
            $Spinners.Dispose()
        }
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

function New-Spinner {
    [CmdletBinding()]
    [OutputType([Kurukuru.Spinner])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [AllowEmptyString()]
        [string]
        $Text,
        [Parameter(Position = 1)]
        $Pattern,
        [Nullable[System.ConsoleColor]]
        $Color = $null,
        $SymbolSucceed = $null,
        $SymbolFailed = $null,
        $SymbolWarn = $null,
        $SymbolInfo = $null,
        [string]
        $SucceedText = $null,
        [string]
        $FailedText = $null,
        $FallbackPattern = $null,
        [scriptblock]
        $ScriptBlock
    )

    if ($null -eq $Pattern) {}
    elseif ($Pattern -isnot [Kurukuru.Pattern]) {
        $Pattern = [Kurukuru.Patterns].GetField($Pattern).GetValue($null)
    }

    if ($null -eq $FallbackPattern) {}
    elseif ($FallbackPattern -is [string]) {
        $FallbackPattern = [Kurukuru.Patterns].GetField($FallbackPattern).GetValue($null)
    }

    $spinner = [Kurukuru.Spinner]::new($Text, $Pattern, $Color, $true, $FallbackPattern)

    if ($SymbolSucceed) {
        $spinner.SymbolSucceed = (ConvertToSymbolDefinition $SymbolSucceed)
    }
    if ($SymbolFailed) {
        $spinner.SymbolFailed = (ConvertToSymbolDefinition $SymbolFailed)
    }
    if ($SymbolWarn) {
        $spinner.SymbolWarn = (ConvertToSymbolDefinition $SymbolWarn)
    }
    if ($SymbolInfo) {
        $spinner.SymbolInfo = (ConvertToSymbolDefinition $SymbolInfo)
    }

    if ($null -ne $SucceedText) {
        Add-Member SucceedText $SucceedText -InputObject $spinner
    }
    if ($null -ne $FailedText) {
        Add-Member FailedText $FailedText -InputObject $spinner
    }
    if ($ScriptBlock) {
        Add-Member ScriptBlock $ScriptBlock -InputObject $spinner
    }
    return $spinner
}

$patternCompleter = CreateArgumentCompleter -Names ($DefinedPatternsTable.Keys)

Register-ArgumentCompleter -CommandName New-Spinner, Start-Kurukuru, Get-KurukuruPattern -ParameterName Pattern -ScriptBlock $patternCompleter
Register-ArgumentCompleter -CommandName New-Spinner -ParameterName FallbackPattern -ScriptBlock $patternCompleter

Register-ArgumentCompleter -CommandName New-Spinner, Start-Kurukuru -ParameterName Color -ScriptBlock (
    CreateArgumentCompleter -Names ([System.Enum]::GetNames([System.ConsoleColor]))
)
