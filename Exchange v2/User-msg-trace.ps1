$AllServers = Get-Content .\ServicesServerList.txt

foreach ($OneServer in $AllServers) {
    
    $OneServerServices = Get-WmiObject win32_service -ComputerName $OneServer -ErrorAction SilentlyContinue
    
    if ($?) {
        $OneServerServices | 
        Select-Object -Property PSComputerName,name,startname | 
        Where-Object {
            ($_.startname) -and 
            ($_.startname -ne 'LocalSystem') -and 
            ($_.startname -notmatch 'PERNOD-RICARD\\') -and 
            ($_.startname -ne 'NT AUTHORITY\NetworkService') -and
            ($_.startname -ne 'NT Authority\LocalService')
        }
    }else {
        Write-Warning "Error accessing '$oneserver'"
    } 
}
