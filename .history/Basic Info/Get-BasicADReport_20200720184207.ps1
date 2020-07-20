function Get-BasicADReport {
    [CmdletBinding()]
    param (
        
    )
    $MyForest   = Get-ADForest
    $MyDomains  = ($MyForest).domains | ForEach-Object{Get-ADDomain $_}
    $MyDCs      = $MyDomains | ForEach{ Get-ADDomainController -Filter * -Server $_.name } 

    $HTMLContent = @()
    $Now = get-date -Format "yyyy-MM-dd HH:mm:ss"
    $HTMLContent += "<h1>Basic Active Directory Report: $Now</h1>"
   

    # Forest name & functionality level
    $HTMLContent += "<h2>Forest name & functionality level</h2>"
    $HTMLContent += $MyForest | Sort-Object name | ConvertTo-HTML -Fragment -Property Name,ForestMode 
        
    # Domain names & functionality levels
    $HTMLContent += "<h2>Domain names & functionality levels</h2>"
    $HTMLContent += $MyDomains | Sort-Object name | ConvertTo-HTML -Fragment -Property name,domainmode
    
    # Total DCs & DCs per Domain
    $HTMLContent += "<h2>Total DCs & DCs per Domain</h2>"
    
    $HTMLContent += "<h3>$($MyForest.Name) Forest total DCs</h3>"
    $HTMLContent += "$($MyForest.Name) : $($MyDCs.Count) </br>"
    
    $HTMLContent += "<h3>DCs per domain</h3>"
    $HTMLContent += $MyDCs | Group-Object domain | Sort-Object name | ConvertTo-HTML -Fragment -Property name,count
    
    # DCs grouped by operating system
    $HTMLContent += "<h2>DCs grouped by operating system</h2>"
    $HTMLContent += $MyDCs | Group-Object OperatingSystem | Sort-Object name | ConvertTo-HTML -Fragment -Property name,count

    # Detail of DCs
    $HTMLContent += "<h2>Detail of DCs</h2>"
    $HTMLContent += $MyDCs | Sort-Object Domain,name | ConvertTo-HTML -Fragment -Property Domain,IPv4Address,IsGlobalCatalog,OperatingSystem,Site

    Return $HTMLContent
}