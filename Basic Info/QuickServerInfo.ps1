$MyOutFile_HTML = $env:TEMP + "\QuickServerInfo_" + (Get-Date -Format yyyyMMdd_hhmmss) + "_.html"

$Header = @"
<style>
table {
font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
border-collapse: collapse;
width: 100%;
}
th {
padding-top: 12px;
padding-bottom: 12px;
text-align: left;
background-color: #4CAF50;
color: white;
}
</style>
"@

$MyResult = @()

#When Rebooted
$MyResult += "<h1>How long since the computer restarted</h1>"
$MyResult += New-TimeSpan -Start ((Get-CimInstance Win32_OperatingSystem).LastBootUpTime) -end (get-date) | ConvertTo-HTML -Property days,hours,minutes,seconds -Fragment

#CPU consumption
$MyResult += "<h1>CPU & RAM</h1>"
$MyResult += "<h2>CPU Average usage</h2>"
$MyResult += Get-Ciminstance win32_processor | Measure-Object -property LoadPercentage -Average | ConvertTo-HTML -Fragment -Property Average
$MyResult += "<h2>CPU Usage per CPU</h2>"
$MyResult += Get-Ciminstance win32_processor | ConvertTo-HTML -Fragment -Property DeviceID,LoadPercentage,Name

#RAM Consumption
$MyResult += "<h2>Available RAM %</h2>"
$RAM_Available = "{0:N2}" -f (((Get-Ciminstance Win32_OperatingSystem).FreePhysicalMemory/(Get-Ciminstance Win32_OperatingSystem).TotalVisibleMemorySize)*100)
$MyResult += "<h2>$RAM_Available </h2>"

#Drive available
$MyResult += "<h1>Disk available space</h1>"
$MyResult += Get-Ciminstance Win32_logicaldisk -Filter "DriveType = '3'" | Select-Object DeviceID,VolumeName, @{L='FreeSpace GB';E={"{0:N2}" -f ($_.FreeSpace /1GB)}},@{L="Capacity GB";E={"{0:N2}" -f ($_.Size/1GB)}} | ConvertTo-HTML -Fragment

#Services
$MyResult += "<h1>Services Totals</h1>"
$MyResult += Get-Ciminstance win32_service | Group-Object startmode | ConvertTo-HTML -Fragment -Property count,name
$MyResult += "<h2>Automatic services stopped</h2>"
$MyResult += Get-Ciminstance win32_service -filter "startmode='auto'" | Where-Object {$_.state -ne 'Running'} | ConvertTo-HTML -Fragment -Property Name,DisplayName,state,startmode

#Last Patches installed
$MyResult += "<h1>Latest patches</h1>"
$MyResult += get-ciminstance -class win32_quickfixengineering | Sort-Object installedon -Descending -ErrorAction SilentlyContinue | ConvertTo-HTML -Fragment -Property InstalledOn,HotFixID,Description,name,Caption

#Tail of errors
$MyResult += "<h1>Error messages</h1>"
$Yesterday = (Get-Date) - (New-TimeSpan -Day 1)
$MyResult += Get-WinEvent -FilterHashtable @{LogName='system'; Level=2; StartTime=$Yesterday } -maxevents 100 | ConvertTo-HTML -Fragment -Property TimeCreated,ID,message

#Network
$MyResult += "<h1>Network settings</h1>"
$MyResult += "<h2>IPs</h2>"
$MyResult += Get-Ciminstance Win32_NetworkAdapterConfiguration | ConvertTo-HTML -Fragment -Property IPAddress,IPSubnet,DefaultIPGateway,Description,MACAddress
$MyResult += "<h2>Open listening ports</h2>"
$MyResult += netstat -ano | select-string -pattern 'proto',"listening" | ConvertTo-HTML -Fragment -Property Line
$MyResult += "<h2>Connected ports</h2>"
$MyResult += netstat -ano | select-string -pattern 'proto',"established" | ConvertTo-HTML -Fragment -Property Line
$MyResult += "<h2>IPs (New PowerShell)</h2>"
$MyResult += Get-NetIPAddress | Select-Object InterfaceAlias,IPAddress | ConvertTo-HTML -Fragment
$MyResult += "<h2>Connected ports (New PowerShell)</h2>"
$MyResult += Get-NetTCPConnection | Sort-Object State | ConvertTo-HTML -Fragment


ConvertTo-HTML -Body "$MyResult" -Title "Report: $MyOutFile_HTML" -Head $Header | Out-File $MyOutFile_HTML
Start-Process "$MyOutFile_HTML"
