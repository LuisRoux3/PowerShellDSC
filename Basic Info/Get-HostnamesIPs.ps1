#In case we need to conver a lot of servernames (discoveries or so)

Get-Content Servers.txt | ForEach-Object{
    $ipaddress = ([System.Net.Dns]::GetHostByName($_).AddressList.IPAddressToString)
    
    if($? -eq $True) {
    $_ +","+ $ipaddress >> "Addresses.txt"
    }
    else {
    $_ +",Cannot resolve hostname" >> "Addresses.txt"
    }
}