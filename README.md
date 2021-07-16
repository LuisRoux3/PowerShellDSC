# PowerShellDSC

PowerShell code for "one day"... use Distributed State Configuration ... I promise... did I said already "one day"?

## Basic info

### QuickServerInfo.ps1

The script is just to log in a server, run two lines of code and get a quick .html with basic information to help in the troubleshooting.

    $ScriptFromGitHub = Invoke-WebRequest https://raw.githubusercontent.com/LuisRoux3/PowerShellDSC/master/Basic%20Info/QuickServerInfo.ps1
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
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

### Get-ForestMasters.ps1

Active Directory FSMOs inside a forest (including a multidomain forest)

### Get-HostnamesIPs.ps1

I had to resolve many servernames

### Get-DomainMeaningfulRecords.ps1
From a given domain retrieves following records
    MX:     Any MX record, discarding precedence
    SPF:    Any TXT record like v=spf1* (if more than one should be considered an error)
    DMARC:  Any TXT record in the "Subdomain" _dmarc.<Domain> like v=DMARC1;*
    DKIM:   Any TXT record in the "subdomain" selector._domainkey.<Domain> like v=DKIM1;* Writes "Exist selector" (Selector, Selector1, Selector2)
            VerfMS: Any TXT record like v=verifydomain MS=*

## Exchange v2

This will contain scripts using the v2 Module for exchange.

