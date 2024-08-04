$KurukuruPatterns = [array]::AsReadOnly(([Kurukuru.Patterns].GetFields("Public, Static") | Where-Object {
            $_.FieldType -EQ [Kurukuru.Pattern]
        } | ForEach-Object {
            $ret = $_.GetValue($null)
            $ret | Add-Member 'Name' $_.Name
            return $ret
        }
    ))
$script:KurukuruPatternsTable = @{}
foreach ($p in $KurukuruPatterns) {
    $KurukuruPatternsTable[$p.Name] = $p
}

$script:EnabledThreadJob = (Get-Command Start-ThreadJob)

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
        [Parameter(Mandatory = $false, Position = 0, ValueFromRemainingArguments)]
        $Pattern
    )
    if ($Pattern) {
        $Pattern | ForEach-Object {
            if ($_ -is [Kurukuru.Pattern]) {
                $_
            }
            else {
                $KurukuruPatternsTable[$_]
            }
        }
    }
    else {
        $KurukuruPatterns
    }
}

function Stop-Spiner {
    param(
        [Parameter(Mandatory, Position = 0)]
        $Spinners
    )

    if ($EnabledThreadJob) {
        $Spinners | ForEach-Object {
            Start-ThreadJob -ArgumentList @($_) -ScriptBlock { param($s) $s.Info() }
        } | Receive-Job -Wait -AutoRemoveJob
    }
    else {
        $Spinners | ForEach-Object { $_.Info() }
    }
}

function Show-KurukuruSample {
    param(
        [Parameter(ValueFromRemainingArguments)]
        [array]
        $Pattern
    )
    $Patterns = (Get-KurukuruPattern $Pattern)
    if (-not $Patterns) {
        return
    }

    $Spinners = [System.Collections.Generic.LinkedList[Kurukuru.Spinner]]::new()
    try {
        foreach ($p in $Patterns) {
            $height = [math]::Max($Host.UI.RawUI.BufferSize.Height - 2, 1)
            $over = $Spinners.Count - $height
            if ($over -ge 0) {
                [Console]::Write("Press key. Enter: next line, n: next page, q: Quit")
                :read while ($true) {
                    $key = [Console]::ReadKey($true)
                    switch ($key.Key) {
                    ([ConsoleKey]::Q) {
                            return
                        }
                    ([ConsoleKey]::Enter) {
                            break read
                        }
                    ([ConsoleKey]::N) {
                            $over = $Spinners.Count
                            break read
                        }
                    }
                }
        
                $overSpinners = [System.Collections.ArrayList]::new()
                for ($i = 0; $i -lt $over; $i++) {
                    $overSpinners.Add($Spinners.First.Value)
                    $Spinners.RemoveFirst()
                }

                Stop-Spiner $overSpinners
            }

            if ($p.Frames -and $p.Frames[0]) {
                $sp = (New-Spinner -Text $p.Name -Pattern $p -SymbolInfo $p.Frames[0])
            }
            else {
                $sp = (New-Spinner -Text $p.Name -Pattern $p -SymbolInfo "")
            }
            $sp.Start()
            $Spinners.Add($sp)
        }
    
        [Console]::Write("Press any key to exit.")
        [Console]::ReadKey($true) | Out-Null
    }
    finally {
        Stop-Spiner $Spinners
    }
}

function Start-Kurukuru {
    [CmdletBinding()]
    [OutputType([Kurukuru.Spinner[]])]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Spinner', ValueFromPipeline)]
        [Kurukuru.Spinner[]]
        $Spinner,
        [Parameter(ParameterSetName = 'Spinner')]
        [switch] $PassThru,
        [Parameter(ParameterSetName = 'Spinner')]
        [switch] $NoDispose,
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
        $SymbolInfo = $null
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
                $Pattern = [Kurukuru.Pattern]$KurukuruPatternsTable[$Pattern]
                if (-not $Pattern) {
                    Write-Warning "Invalid Pattern Name: $Pattern"
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
                & $InitializationScript $s
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
                    if ($s.Stopped) { return }
                    $text = $s.SucceedText
                    if (-not $text) {
                        $text = $s.Text
                    }
                    $s.Succeed($text)
                }
                catch {
                    if ($s.Stopped) { return }
                    $text = $s.FailedText
                    if (-not $text) {
                        $text = $s.Text
                    }
                    $s.Fail($text)
                }
            }

            if ($Spinners.Count -eq 1) {
                $jobScript.Invoke($Spinners[0])
            }
            elseif ($EnabledThreadJob) {
                $Spinners | ForEach-Object {
                    Start-ThreadJob -ThrottleLimit 1000000 -ScriptBlock $jobScript -ArgumentList @($_)
                } | Receive-Job -Wait -AutoRemoveJob | Out-Null
            }
            else {
                $Spinners | ForEach-Object { & $jobScript $_ } | Out-Null
            }
            if ($PassThru) {
                return $Spinners
            }
            return
        }
        finally {
            if (-not $NoDispose) {
                $Spinners.Dispose()
            }
        }
    }
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

function New-KurukuruPattern {
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([Kurukuru.Pattern])]
    param(
        [Parameter(Mandatory, ValueFromRemainingArguments)]
        [string[]]
        $Frames,
        [Parameter()]
        [int]
        $Interval = 100
    )
    [Kurukuru.Pattern]::new($Frames, $Interval)
}

$patternCompleter = {
    param(
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameter
    )

    foreach ($p in ($KurukuruPatterns)) {
        if ($p.Name.ToLower().StartsWith($wordToComplete.ToLower())) {
            [System.Management.Automation.CompletionResult]::new(
                $p.Name,
                $p.Name,
                [System.Management.Automation.CompletionResultType]::ParameterValue, 
                "$($p.Frames) Interval=$($p.Interval)"
            )
        }
    }
}

Register-ArgumentCompleter -CommandName New-Spinner, Start-Kurukuru, Start-KurukuruSleep, Get-KurukuruPattern, Show-KurukuruSample -ParameterName Pattern -ScriptBlock $patternCompleter
Register-ArgumentCompleter -CommandName New-Spinner -ParameterName FallbackPattern -ScriptBlock $patternCompleter

Register-ArgumentCompleter -CommandName New-Spinner, Start-Kurukuru -ParameterName Color -ScriptBlock {
    param(
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameter
    )

    foreach ($item in ([System.Enum]::GetNames([System.ConsoleColor]))) {
        if ($item.ToLower().StartsWith($wordToComplete.ToLower())) {
            [System.Management.Automation.CompletionResult]::new(
                $item,
                $item,
                [System.Management.Automation.CompletionResultType]::ParameterValue, 
                $item
            )
        }
    }
}
Export-ModuleMember -Variable KurukuruPatterns
