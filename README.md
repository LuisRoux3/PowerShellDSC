# PowerShellDSC
Código en Powershell para Distributed State Configuration

### Get quick computre info

    $ScriptFromGitHub = Invoke-WebRequest https://raw.githubusercontent.com/LuisRoux3/PowerShellDSC/master/Basic%20Info/QuickServerInfo.ps1
    Invoke-Expression $($ScriptFromGitHub.Content)
