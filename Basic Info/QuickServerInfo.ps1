$MyOutFile_HTML = $env:TEMP + "\QuickServerInfo_" + (Get-Date -Format yyyyMMdd_hhmmss) + "_.html"

$Header = @"
<style>
h1 {
    color: white;
    background-color: SteelBlue;
    text-align: center;
  }
h2 {
    color: SteelBlue;
    border: 2px solid SteelBlue;
    border-radius: 5px;
    padding: 10px;
  }
h3 {
    border-left: 6px solid SteelBlue;
    padding: 10px;
    margin: 20px;
}
table {
    font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
    border-collapse: collapse;
    margin: 20px;
}
th {
    padding-top: 12px;
    padding-bottom: 12px;
    text-align: left;
    background-color: SteelBlue;
    color: white;
}
td {
    text-align: left;
    padding: 8px;
  }

tr:nth-child(even) {
    background-color: #f2f2f2;
}
</style>
"@

$MyResult = @()
$BDetailed = $false

$title = "Level of detail"
$message = "Do you want to check dig more details than basics?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Runs all the sections."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Gathers overview only."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 1)

switch ($result){
    0 {$BDetailed = $true}
    1 {$BDetailed = $false}
}




#Global Status
$MyResult += "<h1>Overview</h1>"

    ##Hostname
    $MyResult += "<h2>Hostname</h2>"
    $SingleContent = $env:COMPUTERNAME
    $MyResult += "<h3>$SingleContent</h3>"

    ##When Rebooted
    $MyResult += "<h2>Last Boot Uptime (UTC)</h2>"
    $SingleContent = '{0:u}' -f ((Get-CimInstance Win32_OperatingSystem).LastBootUpTime)
    $MyResult += "<h3>$SingleContent</h3>"

    ##Hours UP
    $MyResult += "<h2>Hours since last Boot</h2>"
    $SingleContent = '{0:N2}h' -f((New-TimeSpan -Start ((Get-CimInstance Win32_OperatingSystem).LastBootUpTime) -end (get-date)).TotalHours)
    $MyResult += "<h3>$SingleContent</h3>"

    ##CPU
    $MyResult += "<h2>CPU % used</h2>"
    $SingleContent = "{0:P}" -f ((Get-Counter '\Processor(_Total)\% Processor Time' | Select-Object -ExpandProperty countersamples | Select-Object -Property CookedValue).CookedValue /100)
    $MyResult += "<h3>$SingleContent</h3>"

    ##RAM
    $MyResult += "<h2>RAM % used</h2>"
    $Used = (Get-Counter '\memory\committed bytes' | Select-Object -ExpandProperty countersamples | Select-Object -Property CookedValue).CookedValue
    $Total = (Get-Counter '\memory\commit limit' | Select-Object -ExpandProperty countersamples | Select-Object -Property CookedValue).CookedValue
    $SingleContent = "{0:P}" -f ($Used / $Total)
    $MyResult += "<h3>$SingleContent</h3>"

    ##Disk space
    $MyResult += "<h2>Disk space</h2>"
    $MyResult += get-counter '\LogicalDisk(*)\% Free Space' | Select-Object -ExpandProperty countersamples | Where-Object {$_.instancename -like "?:"} | Select-Object -Property instancename,@{L='%Free';E={"{0:P}" -f ($_.CookedValue /100)}} | ConvertTo-HTML -Fragment

    ##Network
    $MyResult += "<h2>Network IPs</h2>"
    $MyResult += Get-NetIPAddress -AddressFamily IPv4 | Sort-Object IPv4Address | Select-Object IPv4Address,InterfaceAlias |  ConvertTo-HTML -Fragment

    ##Stopped Services
    $MyResult += "<h2>Automatic services stopped</h2>"
    $MyResult += Get-Ciminstance win32_service -filter "startmode='auto'" | Where-Object {$_.state -ne 'Running'} | ConvertTo-HTML -Fragment -Property Name,DisplayName,state,startmode

    ##Tail of errors
    $MyResult += "<h2>Up to 10 Error messages since yesterday</h2>"
    $Yesterday = (Get-Date) - (New-TimeSpan -Day 1)
    $MyResult += Get-WinEvent -FilterHashtable @{LogName='system'; Level=1,2; StartTime=$Yesterday } -maxevents 10 -ErrorAction SilentlyContinue| ConvertTo-HTML -Fragment -Property TimeCreated,ID,message

    ##Updates without reboot
    $MyResult += "<h2>Updates installed after rebooted</h2>"
    $MyResult += get-ciminstance -class win32_quickfixengineering | Where-Object {$_.InstalledOn -gt ((Get-CimInstance Win32_OperatingSystem).LastBootUpTime)} | Sort-Object installedon -Descending -ErrorAction SilentlyContinue | ConvertTo-HTML -Fragment -Property InstalledOn,HotFixID,Description,name,Caption



if ($BDetailed) {
    #Detail of patches
    $MyResult += "<h1>Hotfix detail</h1>"
    $MyResult += get-ciminstance -class win32_quickfixengineering | Sort-Object installedon -Descending -ErrorAction SilentlyContinue | ConvertTo-HTML -Fragment -Property InstalledOn,HotFixID,Description,name,Caption


    #Process
    $MyResult += "<h1>Process Detail</h1>"

        ##Command line
        $MyResult += "<h2>Process command line</h2>"
        $MyResult += Get-CimInstance Win32_Process | Sort-Object processid | ConvertTo-HTML -Fragment -Property ProcessId,ProcessName,CommandLine
        ##CPU usage
        $MyResult += "<h2>Process consuming more than 1% CPU</h2>"
        $MyResult += Get-Counter '\Process(*)\% Processor Time' | Select-Object -ExpandProperty countersamples | Where-Object {$_.CookedValue -gt 1}| Sort-Object CookedValue -Descending | ConvertTo-HTML -Fragment


    #Services
    $MyResult += "<h1>Services Detail</h1>"
    $MyResult += Get-Ciminstance win32_service  | ConvertTo-HTML -Fragment -Property Name,DisplayName,state,startmode


    #Last weeks errors
    $MyResult += "<h1>Error messages in last 7 days, System, Application, and setup (max 3k)</h1>"
    $LastWeek = (Get-Date) - (New-TimeSpan -Day 7)
    $KWinevents = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=$LastWeek } -maxevents 1000 -ErrorAction SilentlyContinue
    $KWinevents += Get-WinEvent -FilterHashtable @{LogName='Application'; Level=1,2; StartTime=$LastWeek } -maxevents 1000 -ErrorAction SilentlyContinue
    $KWinevents += Get-WinEvent -FilterHashtable @{LogName='Setup'; Level=1,2; StartTime=$LastWeek } -maxevents 1000 -ErrorAction SilentlyContinue
    $MyResult += $KWinevents | ConvertTo-HTML -Fragment -Property TimeCreated,ProviderName,Id,LevelDisplayName,Message


    #Disk
    $MyResult += "<h1>Disk detail</h1>"
        ##Disk space
        $MyResult += "<h2>Disk status</h2>"
        $MyResult += Get-Ciminstance Win32_logicaldisk -Filter "DriveType = '3'" | Select-Object DeviceID,VolumeName, @{L='FreeSpace GB';E={"{0:N2}" -f ($_.FreeSpace /1GB)}},@{L="Capacity GB";E={"{0:N2}" -f ($_.Size/1GB)}} | ConvertTo-HTML -Fragment

        ##Disk Queue
        $MyResult += "<h2>Disk Queues (Logical + Phisical)</h2>"
        $MyResult += get-counter '\LogicalDisk(*)\Current Disk Queue Length' | Select-Object -ExpandProperty countersamples |  Where-Object {$_.instancename -like "?:"} | ConvertTo-HTML -Fragment -Property instancename,CookedValue
        $MyResult += get-counter '\PhysicalDisk(*)\Current Disk Queue Length' | Select-Object -ExpandProperty countersamples | ConvertTo-HTML -Fragment -Property instancename,CookedValue
        ##Disk Activity
        $MyResult += "<h2>Disk Activity</h2> (Logical + Phisical)"
        $MyResult += get-counter '\LogicalDisk(*)\Disk Transfers/sec' | Select-Object -ExpandProperty countersamples |  Where-Object {$_.instancename -like "?:"} | Select-Object instancename,@{L='Transfer per sec';E={"{0:N2}" -f ($_.CookedValue)}} | ConvertTo-HTML -Fragment
        $MyResult += get-counter '\PhysicalDisk(*)\Disk Transfers/sec' | Select-Object -ExpandProperty countersamples | Select-Object instancename,@{L='Transfer per sec';E={"{0:N2}" -f ($_.CookedValue)}} | ConvertTo-HTML -Fragment


    #Network
    $MyResult += "<h1>Network settings</h1>"
        ##List of adapters
        $MyResult += "<h2>Adapters</h2>"
        $MyResult += Get-Ciminstance Win32_NetworkAdapterConfiguration | ConvertTo-HTML -Fragment -Property IPAddress,IPSubnet,DefaultIPGateway,Description,MACAddress
        ##Listening ports
        $MyResult += "<h2>Open listening ports</h2>"
        $MyResult += netstat -ano | select-string -pattern 'proto',"listening" | ConvertTo-HTML -Fragment -Property Line
        ##Connected ports
        $MyResult += "<h2>Connected ports</h2>"
        $MyResult += netstat -ano | select-string -pattern 'proto',"established" | ConvertTo-HTML -Fragment -Property Line
        ##Adapters v2
        $MyResult += "<h2>Adapters v2</h2>"
        $MyResult += Get-NetIPAddress | Select-Object InterfaceAlias,IPAddress | ConvertTo-HTML -Fragment
        ##Connected ports v2
        $MyResult += "<h2>Connected ports v2</h2>"
        $MyResult += Get-NetTCPConnection | Sort-Object State | ConvertTo-HTML -Fragment
}


ConvertTo-HTML -Body "$MyResult" -Title "Report: $MyOutFile_HTML" -Head $Header | Out-File $MyOutFile_HTML
Start-Process "$MyOutFile_HTML"
