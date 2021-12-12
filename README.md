# Kurukuru-PowerShell

This is PowerShell wrapper of [Kurukuru](https://github.com/mayuki/Kurukuru).

## Usage

### Simple

```powershell
Start-Kurukuru {
  param($spinner)
  $spinner.Text = "Start"
  Start-Sleep -Seconds 0.4
  $spinner.Text = "Foo"
  Start-Sleep -Seconds 0.4
  $spinner.Text = "End"
}
```

### Many Params

```powershell
Start-Kurukuru -Text "Initialize" -SucceedText "Success" -Pattern Moon {
  param($spinner)
    $spinner.SymbolSucceed = [Kurukuru.SymbolDefinition]::new("🌅", "O")
} {
  param($spinner)
  Start-Sleep -Seconds 0.4
  $spinner.Text = "Foo"
  Start-Sleep -Seconds 0.4
}
```

### Custom pattern

```powershell
Start-Kurukuru -Pattern ([Kurukuru.Pattern]::new(@("＿", "￣"), 150)) {
  param($spinner)
  $spinner.Text = "Start"
  Start-Sleep -Seconds 0.4
  $spinner.Text = "Foo"
  Start-Sleep -Seconds 0.4
  $spinner.Text = "End"
}
```


### Parallel

```powershell
class P {
    [int] $Id
    [int] $WaitMills
    P([int]$Id) {
        $this.Id = $Id
        $this.WaitMills = (Get-Random -Minimum 400 -Maximum 2000)
    }
}


0..20 | ForEach-Object { [P]::new($_) } | ForEach-Object -Parallel {
    $i = $_.Id
    $waitMills = $_.WaitMills
    Import-Module kurukuru-pwsh
    Start-Kurukuru -Text "Start: $i Wait: 500 ms" -SucceedText "Finish:$i" {
        param($spinner)
        Start-Sleep -Milliseconds 500
        $spinner.Text = "Running: $i Wait: $waitMills ms"
        Start-Sleep -Milliseconds $waitMills
    }
}
```