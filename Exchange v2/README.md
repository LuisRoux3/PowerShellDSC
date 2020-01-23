# Exchange v2

Just a compilation of exchange quick scripts. As a reminder, probably need to get modules installed and updates.

```PowerShell
Install-Module PowerShellGet -Force

#or
update-Module PowerShellGet -Force

#Maybe not required in your case
Set-ExecutionPolicy Unrestricted

Install-Module -Name ExchangeOnlineManagement
```

## User-msg-trace.ps1

Ask for an email and check all the user's send message. First approach to Exchange PowerShell V2.
