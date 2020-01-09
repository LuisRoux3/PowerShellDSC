#WillRequires -Module ActiveDirectory (Won't use Requires as the error makes more sense for me)
$MyResult = @()

foreach ($Domain in ((Get-ADForest).domains)) {
    Write-Output ((Get-Date -Format "yyyy/MM/dd HH:mm K") + "`t Domain: $Domain")
    $MyResult += Get-ADDomain -server $Domain | Select-Object DistinguishedName, SchemaMaster, DomainNamingMaster, InfrastructureMaster, PDCEmulator, RIDMaster
}

Write-Output ((Get-Date -Format "yyyy/MM/dd HH:mm K") + "`t Forest")
$MyResult += Get-ADForest | Select-Object Name,SchemaMaster, DomainNamingMaster,InfrastructureMaster, PDCEmulator, RIDMasterall
$MyResult | Sort-Object DistinguishedName | Out-GridView

<#
I found later that Patrick Gruenauer did a better job
https://sid-500.com/2017/06/26/powershell-my-top-10-commands-for-active-directory-documentation-and-monitoring/

#List all Domain-Controllers
Get-ADDomainController -Filter * | Format-List Name,Ipv4Address,IPv6Address,OperatingSystem

#List all Global Catalog Servers
Get-ADDomainController -Discover -Service "GlobalCatalog"

#Forest-wide Roles
Get-ADForest | Format-Table SchemaMaster,DomainNamingmaster

#Domain-wide Roles
Get-ADDomain | Format-List pdc*,infra*,rid*

netdom query fsmo

Get-EventLog -LogName Security -InstanceId 4624 | Where-Object Message -match "petra" | Format-Table TimeGenerated,Message -AutoSize -Wrap
#>