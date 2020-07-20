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


#region ----- MAIN -----
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
$HTMLContent += Get-BasicADReport 

#Path for output
$MyOutFile_HTML = $env:TEMP + "\QuickServerInfo_" + (Get-Date -Format yyyyMMdd_hhmmss) + "_.html"

ConvertTo-HTML -Body "$HTMLContent" -Title "Report: $MyOutFile_HTML" -Head $Header | Out-File $MyOutFile_HTML

Start-Process "$MyOutFile_HTML"
#endregion ----- MAIN -----