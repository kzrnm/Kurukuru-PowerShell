BeforeAll {
    Import-Module "$PSScriptRoot/../kurukuru-pwsh.psd1"
    $Pattern = [Kurukuru.Pattern]::new(
        @(
            "0", "1", "2", "3", "4",
            "5", "6", "7", "8", "9"
        ), 100)
        
    $writer = [System.IO.StringWriter]::new()
    $writer.NewLine = "`n"
    [Console]::SetOut($writer)
}

Describe 'Start-Kurukuru' {
    It "With InitializationScript" {
        Start-Kurukuru -Pattern $Pattern -SucceedText "Finish" {
            param($spinner)
            $spinner.SymbolSucceed = [Kurukuru.SymbolDefinition]::new("ゆ", "O")
        } {
            param($spinner)
            $spinner.Text = "Foo"
            Start-Sleep -Seconds 0.2
            $spinner.Text = "Bar"
            Start-Sleep -Seconds 0.2
        }
        $writer.Flush()
        $output = [string]$writer.GetStringBuilder().ToString()

        $output | Should -Match "ゆ Finish"
    }
    It "Without InitializationScript" {
        Start-Kurukuru -Pattern $Pattern -SucceedText "Finish" {
            param($spinner)
            $spinner.Text = "Foo"
            Start-Sleep -Seconds 0.2
            $spinner.Text = "Bar"
            Start-Sleep -Seconds 0.2
        }
        $writer.Flush()
        $output = [string]$writer.GetStringBuilder().ToString()

        $output | Should -Match "✔ Finish"
    }
}