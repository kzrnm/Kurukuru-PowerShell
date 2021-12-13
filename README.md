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
Start-Kurukuru -Text "Initialize" -SucceedText "Success" -Pattern Moon {
  param($spinner)
    $spinner.SymbolSucceed = [Kurukuru.SymbolDefinition]::new("🌅", "O")
} {
  param($spinner)
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
0..20 | ForEach-Object -Parallel {
    $i = $_
    $waitMills = (Get-Random -Minimum 400 -Maximum 1500)
    Import-Module kurukuru-pwsh
    Start-Kurukuru -Text "Start: $i Wait: 400 ms" -SucceedText "Finish:$i" {
        param($spinner)
        Start-Sleep -Milliseconds 400
        $spinner.Text = "Running: $i Wait: $waitMills ms"
        Start-Sleep -Milliseconds $waitMills
    }
}
```
