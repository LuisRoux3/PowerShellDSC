function Get-BasicInfo {
#This function is used to write "basic info  from current computer and write in HTML format into a variable
#Returns HTML code
    $HTMLContent = @()
    $Now = get-date -Format "yyyy-MM-dd HH:mm:ss"
    $HTMLContent += "<h1>Overview: $Now</h1>"
    
    #Hostname
    $HTMLContent += "<h2>Hostname.</h2>"
    $ComputerName = $env:COMPUTERNAME
    $HTMLContent += "<h3>$ComputerName</h3>"
    
    #Hostname
    $HTMLContent += "<h2>OS Info.</h2>"
    $HTMLContent += "<h3>OS Name: " + (Get-CimInstance Win32_OperatingSystem).Caption + "</br>"
    $HTMLContent += "OS Version: " + (Get-CimInstance Win32_OperatingSystem).Version + "</br>"

    #When Rebooted
    $HTMLContent += "<h2>Last Boot Uptime (UTC).</h2>"
    $LastBootUptime = '{0:u}' -f ((Get-CimInstance Win32_OperatingSystem).LastBootUpTime)
    $HTMLContent += "<h3>$LastBootUptime</h3>"

    #Hours UP
    $HTMLContent += "<h2>Hours since last Boot.</h2>"
    $HoursUP = '{0:N2}h' -f((New-TimeSpan -Start ((Get-CimInstance Win32_OperatingSystem).LastBootUpTime) -end (get-date)).TotalHours)
    $HTMLContent += "<h3>$HoursUP</h3>"
    
    #CPU
    $HTMLContent += "<h2>CPU % used.</h2>"
    $CPUUse = "{0:P}" -f ((Get-Counter '\Processor(_Total)\% Processor Time' | Select-Object -ExpandProperty countersamples | Select-Object -Property CookedValue).CookedValue /100)
    $HTMLContent += "<h3>$CPUUse</h3>"
    
    #RAM
    $HTMLContent += "<h2>RAM % used.</h2>"
    $UsedRAM = (Get-Counter '\memory\committed bytes' | Select-Object -ExpandProperty countersamples | Select-Object -Property CookedValue).CookedValue
    $TotalRAM = (Get-Counter '\memory\commit limit' | Select-Object -ExpandProperty countersamples | Select-Object -Property CookedValue).CookedValue
    $RAMUse = "{0:P}" -f ($UsedRAM / $TotalRAM)
    $HTMLContent += "<h3>$RAMUse</h3>"
    
    #Disk space
    $HTMLContent += "<h2>Disk space.</h2>"
    $HTMLContent += get-counter '\LogicalDisk(*)\% Free Space' | Select-Object -ExpandProperty countersamples | Where-Object {$_.instancename -like "?:"} | Select-Object -Property instancename,@{L='%Free';E={"{0:P}" -f ($_.CookedValue /100)}} | ConvertTo-HTML -Fragment
    
    #Network
    $HTMLContent += "<h2>Network IPs.</h2>"
    $HTMLContent += Get-NetIPAddress -AddressFamily IPv4 | Sort-Object IPv4Address | Select-Object IPv4Address,InterfaceAlias |  ConvertTo-HTML -Fragment
    
    #Stopped Services
    $HTMLContent += "<h2>Automatic services stopped.</h2>"
    $HTMLContent += Get-Ciminstance win32_service -filter "startmode='auto'" | Where-Object {$_.state -ne 'Running'} | ConvertTo-HTML -Fragment -Property Name,DisplayName,state,startmode
    
    #Tail of errors
    $HTMLContent += "<h2>Up to 10 Error messages since yesterday.</h2>"
    $Yesterday = (Get-Date) - (New-TimeSpan -Day 1)
    $HTMLContent += Get-WinEvent -FilterHashtable @{LogName='system'; Level=1,2; StartTime=$Yesterday } -maxevents 10 -ErrorAction SilentlyContinue | Sort-Object timecreated -Descending | ConvertTo-HTML -Fragment -Property TimeCreated,ID,message

    #Updates without reboot
    $HTMLContent += "<h2>Updates installed after rebooted.</h2>"
    $HTMLContent += get-ciminstance -class win32_quickfixengineering | Where-Object {$_.InstalledOn -gt ((Get-CimInstance Win32_OperatingSystem).LastBootUpTime)} | Sort-Object installedon -Descending -ErrorAction SilentlyContinue | ConvertTo-HTML -Fragment -Property InstalledOn,HotFixID,Description,name,Caption

    #Date of "users home"
    $HTMLContent += "<h2>Folder dates of Users profile sort by access time.</h2>"
    $UsrRoot = (get-item $env:USERPROFILE).Parent.FullName
    $HTMLContent += get-childitem $UsrRoot -Attributes Directory | Select-Object FullName,LastAccessTime,CreationTime,LastWriteTime | Sort-Object -Descending LastAccessTime | ConvertTo-HTML -Fragment #-Property InstalledOn,HotFixID,Description,name,Caption

    Return $HTMLContent
}#End function Get-BasicInfo


function Get-DetailedInfo {
#Returns THML with more information
    $HTMLContent = @()

    #Detail of patches
    $HTMLContent += "<h1>Hotfix detail</h1>"
    $HTMLContent += get-ciminstance -class win32_quickfixengineering | Sort-Object installedon -Descending -ErrorAction SilentlyContinue | ConvertTo-HTML -Fragment -Property InstalledOn,HotFixID,Description,name,Caption
    
    #Detail of OS (Including above's info)
    $HTMLContent += "<h1>OS detail</h1>"
    $HTMLContent += "<h3>OS Name: " + (Get-CimInstance Win32_OperatingSystem).Caption + "</br>"
    $HTMLContent += "OS Version: " + (Get-CimInstance Win32_OperatingSystem).Version + "</br>"
    $HTMLContent += "OS Root: " + (Get-CimInstance Win32_OperatingSystem).SystemDirectory + "</br>"
    $HTMLContent += "CurrentCulture: " + (Get-Host).CurrentCulture + "</br>"
    $HTMLContent += "CurrentUICulture: " + (Get-Host).CurrentUICulture + "</h3>"

    #Process
    $HTMLContent += "<h1>Process Detail</h1>"
    
    #Process with Command line
    $HTMLContent += "<h2>Process command line</h2>"
    $HTMLContent += Get-CimInstance Win32_Process | Sort-Object processid | ConvertTo-HTML -Fragment -Property ProcessId,ProcessName,CommandLine
    
    #Process with CPU usage >1
    $HTMLContent += "<h2>Process consuming more than 1% CPU</h2>"
    $HTMLContent += Get-Counter '\Process(*)\% Processor Time' | Select-Object -ExpandProperty countersamples | Where-Object {$_.CookedValue -gt 1}| Sort-Object CookedValue -Descending | ConvertTo-HTML -Fragment
    
    #Services
    $HTMLContent += "<h1>Services Detail</h1>"
    $HTMLContent += Get-Ciminstance win32_service  | ConvertTo-HTML -Fragment -Property Name,DisplayName,state,startmode
    
    #Last weeks errors
    $HTMLContent += "<h1>Error messages in last 7 days, System, Application, and setup (max 300)</h1>"
    $LastWeek = (Get-Date) - (New-TimeSpan -Day 7)
    $MyWinevents = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=$LastWeek } -maxevents 100 -ErrorAction SilentlyContinue
    $MyWinevents += Get-WinEvent -FilterHashtable @{LogName='Application'; Level=1,2; StartTime=$LastWeek } -maxevents 100 -ErrorAction SilentlyContinue
    $MyWinevents += Get-WinEvent -FilterHashtable @{LogName='Setup'; Level=1,2; StartTime=$LastWeek } -maxevents 100 -ErrorAction SilentlyContinue
    $HTMLContent += $MyWinevents | Sort-Object timecreated -Descending | ConvertTo-HTML -Fragment -Property TimeCreated,ProviderName,Id,LevelDisplayName,Message
    
    #Disk
    $HTMLContent += "<h1>Disk detail</h1>"
    
    #Disk space
    $HTMLContent += "<h2>Disk status</h2>"
    $HTMLContent += Get-Ciminstance Win32_logicaldisk -Filter "DriveType = '3'" | Select-Object DeviceID,VolumeName, @{L='FreeSpace GB';E={"{0:N2}" -f ($_.FreeSpace /1GB)}},@{L="Capacity GB";E={"{0:N2}" -f ($_.Size/1GB)}} | ConvertTo-HTML -Fragment

    #Disk Queue (not very accurate as is not a graph but a sample)
    $HTMLContent += "<h2>Disk Queues (Logical + Phisical)</h2>"
    $HTMLContent += get-counter '\LogicalDisk(*)\Current Disk Queue Length' | Select-Object -ExpandProperty countersamples |  Where-Object {$_.instancename -like "?:"} | ConvertTo-HTML -Fragment -Property instancename,CookedValue
    $HTMLContent += get-counter '\PhysicalDisk(*)\Current Disk Queue Length' | Select-Object -ExpandProperty countersamples | ConvertTo-HTML -Fragment -Property instancename,CookedValue

    #Disk Activity (not very accurate as is not a graph but a sample)
    $HTMLContent += "<h2>Disk Activity</h2> (Logical + Phisical)"
    $HTMLContent += get-counter '\LogicalDisk(*)\Disk Transfers/sec' | Select-Object -ExpandProperty countersamples |  Where-Object {$_.instancename -like "?:"} | Select-Object instancename,@{L='Transfer per sec';E={"{0:N2}" -f ($_.CookedValue)}} | ConvertTo-HTML -Fragment
    $HTMLContent += get-counter '\PhysicalDisk(*)\Disk Transfers/sec' | Select-Object -ExpandProperty countersamples | Select-Object instancename,@{L='Transfer per sec';E={"{0:N2}" -f ($_.CookedValue)}} | ConvertTo-HTML -Fragment
            
    #Network
    $HTMLContent += "<h1>Network settings</h1>"

    #List of adapters
    $HTMLContent += "<h2>Adapters</h2>"
    $HTMLContent += Get-Ciminstance Win32_NetworkAdapterConfiguration | ConvertTo-HTML -Fragment -Property IPAddress,IPSubnet,DefaultIPGateway,Description,MACAddress

    #Listening ports
    $HTMLContent += "<h2>Open listening ports</h2>"
    $HTMLContent += netstat -ano | select-string -pattern 'proto',"listening" | ConvertTo-HTML -Fragment -Property Line
    
    #Connected ports
    $HTMLContent += "<h2>Connected ports</h2>"
    $HTMLContent += netstat -ano | select-string -pattern 'proto',"established" | ConvertTo-HTML -Fragment -Property Line
    
    #Adapters v2 (Used a cmdlet that may not be supported in some OS)
    $HTMLContent += "<h2>Adapters v2</h2>"
    $HTMLContent += Get-NetIPAddress | Select-Object InterfaceAlias,IPAddress | ConvertTo-HTML -Fragment
    
    #Connected ports v2 (Used a cmdlet that may not be supported in some OS)
    $HTMLContent += "<h2>Connected ports v2</h2>"
    $HTMLContent += Get-NetTCPConnection | Sort-Object State | ConvertTo-HTML -Fragment
    
    #Logins
    $HTMLContent += "<h1>User Logins</h1>"
    
    #Member of local administrator group
    $HTMLContent += "<h2>Members of Local administrator group</h2>"
    $HTMLContent += Get-LocalGroupMember -SID S-1-5-32-544 | Select-Object name,PrincipalSource,ObjectClass,SID | Sort-Object Name | ConvertTo-HTML -Fragment

    #Local user lastlogon
    $HTMLContent += "<h2>Local user logins sort by Last Logon</h2>"
    $HTMLContent += Get-LocalUser | Select-Object name,LastLogon,enabled,AccountExpires,PasswordLastSet,sid,Description | Sort-Object -Descending LastLogon | ConvertTo-HTML -Fragment

    #User's Last logon
    $HTMLContent += "<h2>All users logins</h2>"
    $HTMLContent += '<p>Ref: <a href="https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/audit-logon">Audit logon</a></p>'
    $HTMLContent += '<p>Ref: <a href="https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2003/cc787567(v=ws.10)?redirectedfrom=MSDN">Audit logon events</a></p>'
    $HTMLContent += "<table>"
    $HTMLContent += "<tr><th>TimeCreated</th><th>Event</th><th>Account Name</th><th>Account Domain</th><th>Logon Type</th><th>Elevated Token</th>"
    
    $SrcWinevents = Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4624,528; StartTime=$LastWeek } -maxevents 10 | Sort-Object -Descending TimeCreated | Select-Object TimeCreated,Id,message
    foreach ($OneEvent in $SrcWinevents) {
        $OneModifMSG = $OneEvent.Message -split "\n\t" #Removes new lines and tab separator
        $One3AccountNames = ($OneModifMSG | Select-String "Account Name:") 
        $One3AccountDomains = ($OneModifMSG | Select-String "Account Domain:") 
        $OneLogonType = ($OneModifMSG | Select-String "Logon Type:") -Split "\t" | Select-Object -Last 1
        $OneElevationToken = ($OneModifMSG | Select-String "Elevated Token:") -Split "\t" #3 lines
        $OneElevationToken = ($OneElevationToken[2] -split "\n")[0] #Yes/no"
        
        
        # Time Created and Evemt
        $OneHTMLContent = "<tr><td>" + ([string]$OneEvent.TimeCreated) + "</td><td>" + ([string]$OneEvent.Id) + "</td><td>"
        # 3 Account names
        $OneHTMLContent += [string]$One3AccountNames[0] + "</p>" + [string]$One3AccountNames[1] + "</p>" + [string]$One3AccountNames[2] + "</td><td>"
        # 3 Account domains
        $OneHTMLContent += [string]$One3AccountDomains[0] + "</p>" + [string]$One3AccountDomains[1] + "</p>" + [string]$One3AccountDomains[2] + "</td><td>"
        #Logon type and Elevation token
        $OneHTMLContent +=  [string]$OneLogonType + "</td><td>" + [string]$OneElevationToken + "</td>"

        $HTMLContent += $OneHTMLContent
    }
    
    $HTMLContent += "</table>"


    Return $HTMLContent  
}#End function Get-DetailedInfo


function Get-DetailLevel {
    $title = "Level of detail"
    $message = "Do you want to check dig more details than basics?"

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Runs all the sections."
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Gathers overview only."
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 1)

    switch ($result){
        0 {return $true}
        1 {return $false}
    }
}#End function Get-DetailLevel

#region ----- MAIN -----
<#
    This script is to watch a .html file with information to help in the troubleshooting
    Some data are gather from perfmon counters and depends on the OS language
#>
#CSS for eye-friendly reports (https://www.w3schools.com/css/)
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


$HTMLContent = @()
$HTMLContent += Get-BasicInfo 
if(Get-DetailLevel){$HTMLContent += Get-DetailedInfo}

#Path for output
$MyOutFile_HTML = $env:TEMP + "\QuickServerInfo_" + (Get-Date -Format yyyyMMdd_hhmmss) + "_.html"

ConvertTo-HTML -Body "$HTMLContent" -Title "Report: $MyOutFile_HTML" -Head $Header | Out-File $MyOutFile_HTML

Start-Process "$MyOutFile_HTML"
#endregion ----- MAIN -----