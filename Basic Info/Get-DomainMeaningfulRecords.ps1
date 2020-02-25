function Get-DomainMeaningfulRecords {
    <#
    .SYNOPSIS
        From a given domain retrieves MX, SPF, DMARC, DKIM and MS Validator record.
        

    .DESCRIPTION
        From a given domain retrieves following records
            MX:     Any MX record, discarding precedence
            SPF:    Any TXT record like v=spf1* (if more than one should be considered an error)
            DMARC:  Any TXT record in the "Subdomain" _dmarc.<Domain> like v=DMARC1;*
            DKIM:   Any TXT record in the "subdomain" selector._domainkey.<Domain> like v=DKIM1;* Writes "Exist selector" (Selector, Selector1, Selector2)
            VerfMS: Any TXT record like v=verifydomain MS=*
        
        Queries 8.8.8.8 DNS server so will need internet access

    .PARAMETER Domain
        Domain to retrieve the records from

    .OUTPUTS
        Returns an array of 
        Selected.Microsoft.DnsClient.Commands.DnsRecord_TXT (if only MX is just _MX)
        in the form
        (Domain)Name    (Record)Type    (Record)Value

    .EXAMPLE
        Get-DomainMeaningfulRecords -ErrorAction SilentlyContinue -Domain 'microsoft.com'

    .EXAMPLE
        'microsoft.com','apple.com' | %{Get-DomainMeaningfulRecords -Domain $_ -ErrorAction SilentlyContinue} | Format-Table

        Name          Type  Value
        ----          ----  -----
        microsoft.com MX    microsoft-com.mail.protection.outlook.com
        microsoft.com SPF   v=spf1 include:_spf-a.microsoft.com include:_spf-b.microsoft.com include:_spf-c.microsoft.com include:_spf-ssg-a.microsoft.com incl...
        microsoft.com DMARC v=DMARC1; p=reject; pct=100; rua=mailto:d@rua.agari.com; ruf=mailto:d@ruf.agari.com; fo=1
        apple.com     MX    ma1-aaemail-dr-lapp01.apple.com
        apple.com     MX    ma1-aaemail-dr-lapp02.apple.com
        apple.com     MX    ma1-aaemail-dr-lapp03.apple.com
        apple.com     MX    nwk-aaemail-lapp01.apple.com
        apple.com     MX    nwk-aaemail-lapp02.apple.com
        apple.com     MX    nwk-aaemail-lapp03.apple.com
        apple.com     SPF   v=spf1 include:_spf.apple.com include:_spf-txn.apple.com ~all
        apple.com     DMARC v=DMARC1; p=quarantine; sp=reject; rua=mailto:d@rua.agari.com; ruf=mailto:d@ruf.agari.com;

    .NOTES
        DKIM searches
            Selector 
            Selector1 
            Selector2
        
        Requires Network access UDP 53 against 8.8.8.8

        Could reduce the number of queries but I think is more clear that way.

    #>
    [CmdletBinding()]
    [OutputType('Selected.Microsoft.DnsClient.Commands.DnsRecord_TXT')]
    param (
        # Domain to retrieve the records from
        [Parameter(Mandatory = $true,
        HelpMessage = 'Enter one Domain to retrieve the records from.',
        ValueFromPipelineByPropertyName = $true)]
        $Domain
    )

    process {
        $ServerDNS = '8.8.8.8'
        $MyResult = @()
    
        #Obtain MX records
        $MyResult += Resolve-DnsName -Server $ServerDNS -name $Domain -Type MX -DnsOnly -ErrorAction SilentlyContinue |
            Select-Object Name,@{label='Type';expression={'MX'}},@{label='Value';expression={$_.NameExchange}}
            
        #Obtain SPF records
        $MyResult += Resolve-DnsName -Server $ServerDNS -name $Domain -Type TXT -DnsOnly -ErrorAction SilentlyContinue |
            where-object {($_.strings -like 'v=spf1*')} | 
            Select-Object Name,@{label='Type';expression={'SPF'}},@{label='Value';expression={$_.strings}}
    
        #Obtain verification records
        $MyResult += Resolve-DnsName -Server $ServerDNS -name $Domain -Type TXT -DnsOnly -ErrorAction SilentlyContinue |
            where-object {($_.strings -like 'v=verifydomain MS=*')} | 
            Select-Object Name,@{label='Type';expression={'VerfMS'}},@{label='Value';expression={$_.strings}}
        
        #Obtain DMARC records
        $MyResult += Resolve-DnsName -Server $ServerDNS -name "_dmarc.$Domain" -Type TXT -DnsOnly -ErrorAction SilentlyContinue |
            where-object {($_.strings -like 'v=DMARC1;*')} | 
            Select-Object @{label='Name';expression={"$Domain"}},@{label='Type';expression={'DMARC'}},@{label='Value';expression={$_.strings}}
    
        #Obtain DKIM records
        $MyResult += Resolve-DnsName -Server $ServerDNS -name "selector._domainkey.$Domain" -Type TXT -DnsOnly |
            where-object {($_.strings -like 'v=DKIM1;*')} | 
            Select-Object @{label='Name';expression={"$Domain"}},@{label='Type';expression={'DKIM'}},@{label='Value';expression={"Exist selector._domainkey.$Domain"}}

        $MyResult += Resolve-DnsName -Server $ServerDNS -name "selector1._domainkey.$Domain" -Type TXT -DnsOnly |
            where-object {($_.strings -like 'v=DKIM1;*')} | 
            Select-Object @{label='Name';expression={"$Domain"}},@{label='Type';expression={'DKIM'}},@{label='Value';expression={"Exist selector1._domainkey.$Domain"}}

        $MyResult += Resolve-DnsName -Server $ServerDNS -name "selector2._domainkey.$Domain" -Type TXT -DnsOnly |
            where-object {($_.strings -like 'v=DKIM1;*')} | 
            Select-Object @{label='Name';expression={"$Domain"}},@{label='Type';expression={'DKIM'}},@{label='Value';expression={"Exist selector2._domainkey.$Domain"}}
    
        $MyResult # Returns it
    }

} # Get-DomainMeaningfulRecords