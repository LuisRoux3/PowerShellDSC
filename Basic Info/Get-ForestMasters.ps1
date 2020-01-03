#WillRequires -Module ActiveDirectory (Won't use Requires as the error makes more sense for me)
$MyResult = @()

foreach ($Domain in ((Get-ADForest).domains)) {
    Write-Output ((Get-Date -Format "yyyy/MM/dd HH:mm K") + "`t Domain: $Domain")
    $MyResult += Get-ADDomain -server $Domain | Select-Object DistinguishedName, SchemaMaster, DomainNamingMaster, InfrastructureMaster, PDCEmulator, RIDMaster
}

Write-Output ((Get-Date -Format "yyyy/MM/dd HH:mm K") + "`t Forest")
$MyResult += Get-ADForest | Select-Object Name,SchemaMaster, DomainNamingMaster,InfrastructureMaster, PDCEmulator, RIDMasterall
$MyResult | Sort-Object DistinguishedName | Out-GridView