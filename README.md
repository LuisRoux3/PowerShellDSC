# PowerShellDSC

PowerShell code for "one day"... use Distributed State Configuration

## Get basic computer info

The script is just to log in a server, run two lines of code and get a quick .html with basic information to help in the troubleshooting.

    $ScriptFromGitHub = Invoke-WebRequest https://raw.githubusercontent.com/LuisRoux3/PowerShellDSC/master/Basic%20Info/QuickServerInfo.ps1
    Invoke-Expression $($ScriptFromGitHub.Content)

- Hostname
- When Rebooted
- Hours UP
- CPU usage (as is "current" not so useful)
- RAM (same issue as CPU)
- Disk space
- Network
- Services Stopped with automatic startup
- Tail of errors (Up to 10 Error messages since "yesterday")
- Updates without reboot (not yet the "pending reboot status")

If Detailed report requested, will bring ... well ... more information.
