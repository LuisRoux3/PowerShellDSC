#$AllServers = Get-Content .\ServicesServerList.txt
#or
$AllServers = Get-ADComputer -Filter *


#foreach ($OneServer in $AllServers) {
foreach ($OneServer in ($AllServers.DNSHostName)) {
    
    $OneServerServices = Get-WmiObject win32_service -ComputerName $OneServer -ErrorAction SilentlyContinue
    
    if ($?) {
        $OneServerServices | 
        Select-Object -Property PSComputerName,name,startname | 
        Where-Object {
            ($_.startname) -and 
            ($_.startname -ne 'LocalSystem') -and 
            ($_.startname -ne 'NT AUTHORITY\NetworkService') -and
            ($_.startname -ne 'NT AUTHORITY\system') -and
            ($_.startname -ne 'NT Authority\LocalService') 
        }
    }else {
        Write-Warning "Error accessing '$oneserver'"
    } 
}

#Get-LocalGroupMember -SID S-1-5-32-544