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
	Get-EventLog -LogName Application -Source Docker -After (Get-Date).AddMinutes(-30) -ErrorAction SilentlyContinue | Sort-Object Time | Export-CSV ($PrefixCn + "Evt_Last30min_Application.csv")

#>

$slogonevents = @()
$startDate = (get-date).AddDays(-2)
$AllDCs = Get-ADDomainController -Filter *

foreach ($DC in $AllDCs) {
    $Percent = ($AllDCs.IndexOf($DC)/$AllDCs.Count*100)
    Write-Progress -Activity "Getting Events of $DC" -PercentComplete $Percent

    $slogonevents += Get-Eventlog -LogName Security -ComputerName $DC.Hostname -after $startDate | where {$_.eventID -eq 4722 }
}



Select-Object LogMode, MaximumSizeInBytes, RecordCount, LogName,
@{name='ComputerName'; expression={$Server}} |



$StartTime = (get-date).AddDays(-30)
$AllServersToCheck = (Get-ADDomainController -Filter *).hostname # That's for current domain
$FHT =@{
    LogName     = 'Security'
    Id          = 4726 # 4725,4726,4781
    StartTime   = $StartTime
}

$ResultEvents = foreach ($OneServer in $AllServersToCheck) {
                    $Percent = ($AllServersToCheck.IndexOf($OneServer)/$AllServersToCheck.Count*100)
                    Write-Progress -Activity "Getting Events of $OneServer" -PercentComplete $Percent

                    $ResultEvents += Get-WinEvent -FilterHashtable $FHT -ComputerName $OneServer -ErrorAction Continue #-maxevents 100
                }

$ResultEvents | Select-Object MachineName,TimeCreated,Message

<#
    https://learn.microsoft.com/en-us/powershell/scripting/samples/creating-get-winevent-queries-with-filterhashtable?view=powershell-7.3

    Key name	Value data type	Accepts wildcard characters?
    LogName	<String[]>	Yes
    ProviderName	<String[]>	Yes
    Path	<String[]>	No
    Keywords	<Long[]>	No
    ID	<Int32[]>	No
    Level	<Int32[]>	No
    StartTime	<DateTime>	No
    EndTime	<DateTime>	No
    UserID	<SID>	No
    Data	<String[]>	No
    <named-data>	<String[]>	No
#>
<#
    User Event ID
    4720    Created
    4722    Enabled
    4723    User changed password
    4724    Privideged user changed password
    4725    Disabled
    4726    Deleted
    4738    Changed
    4740    Locked out
    4767    Unlocked
    4781    Name change
#>