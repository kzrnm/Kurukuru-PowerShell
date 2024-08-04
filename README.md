# kurukuru-pwsh

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/kurukuru-pwsh)](https://www.powershellgallery.com/packages/kurukuru-pwsh)

PowerShell wrapper of [Kurukuru](https://github.com/mayuki/Kurukuru).

https://user-images.githubusercontent.com/32071278/145768756-23f1ab90-5e54-45cc-aedc-8bb7f353043b.mp4

## Get Started

[PowerShell Gallery](https://www.powershellgallery.com/packages/kurukuru-pwsh).

```powershell
Install-Module kurukuru-pwsh
```

## Usage

### Simple

```powershell
Start-Kurukuru {
  param($spinner)
  $spinner.Text = "Start"
  Start-Sleep -Seconds 1.5
  $spinner.Text = "Foo"
  Start-Sleep -Seconds 1.5
  $spinner.Text = "End"
}
```

### Many Params

```powershell
Start-Kurukuru -Text "Initialize" -SucceedText "Success" -Pattern Moon -SymbolFailed ([Kurukuru.SymbolDefinition]::new("🌑", "O")) {
    param([Kurukuru.Spinner]$spinner)
    if ((([datetime]::Now.Hour + 18) % 24) -gt 12) {
        $spinner.SymbolSucceed = [Kurukuru.SymbolDefinition]::new("🌕️", "O")
    }
    else {
        $spinner.SymbolSucceed = [Kurukuru.SymbolDefinition]::new("🌅", "O")
    }
} {
    param([Kurukuru.Spinner]$spinner)
    Start-Sleep -Seconds 1.5
    $spinner.Text = "Foo"
    Start-Sleep -Seconds 1.5
}
```

### Custom pattern

```powershell
Start-Kurukuru -Pattern ([Kurukuru.Pattern]::new(@("＿", "￣"), 150)) {
  param($spinner)
  $spinner.Text = "Start"
  Start-Sleep -Seconds 1.5
  $spinner.Text = "Foo"
  Start-Sleep -Seconds 1.5
  $spinner.Text = "End"
}
```

### Parallel

```powershell
1..20 | ForEach-Object { 
    $i = $_
    New-Spinner -Text "Start: $i and Wait: 300 ms" -Pattern (Get-Random (Get-KurukuruPattern)) -SucceedText "Finish:$i" -FailedText "Failed:$i" -ScriptBlock ({
            param([Kurukuru.Spinner]$s)
            $s.Text = "Starting: $i"
            if ($i % 2 -eq 0) {
                $waitMills = 250 * $i 
            }
            else {
                $waitMills = 500 + 100 * $i
            }
            Start-Sleep -Milliseconds 300
            $s.Text = "Running: $i Wait: $waitMills ms"
            Start-Sleep -Milliseconds $waitMills
            if ($i -eq 2) {
                throw "Error 2"
            }

            $s.Text = "Closing: $i"
        }).GetNewClosure()
} | Start-Kurukuru
```
