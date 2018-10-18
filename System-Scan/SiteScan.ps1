#Written by Mike Plambeck
#Updated 18/10/2018
#More refactoring, Added Site link information, added logging (just putting each DC into an XML file for the moment
#More to come there
#Added a field to list which DCDiag test(s) fail "DiagError"
# To Do: Add Password Policy info (default Domain and fine-grain)
# To Do: Read in last run's XML files and compare
##9825;<br>
##&#9829;<br>


#region Setup

#check if there is a map already, if so delete it

$pathroot = "C:\SiteInfo\"
$path = $pathroot +"SiteMap.HTML"
$csspath = $pathroot + "style.css"
$jspath = $pathroot + "code.js"
$logpath = $pathroot + "log\"
$report = ""
$LeftGraphChar='%#%;'
$RightGraphChar='%@%'
$Servers = @()
New-Item -ItemType Directory -Force -path $pathroot
New-Item -ItemType Directory -Force -path $logpath
If ($(Try { Test-Path $path} Catch { $false })){Remove-Item $path -force}
If ($(Try { Test-Path $csspath} Catch { $false })){Remove-Item $csspath -force}
If ($(Try { Test-Path $jspath} Catch { $false })){Remove-Item $jspath -force}

#endregion

#region Functionblocks

    Function Get-ForestInfo
    {
    $ForestInfo = Get-ADForest
    $sites = ""
    $sitecount = 0
    $Forest = new-object psobject
    Add-Member -InputObject $Forest -MemberType NoteProperty -Name Forrest -Value $ForestInfo.Name
    Foreach($site in $ForestInfo.Sites)
        {
        $sitecount ++
        Add-Member -InputObject $Forest -MemberType NoteProperty -Name "Site $sitecount" -Value $site
        }
    return $Forest
    }


    Function Get-DomainInfo
    {
    
    $DomainInfo = Get-addomain 
    $Domain = new-object psobject
    $SchemaVersion =""
    $SchemaInfo = Get-ADObject (Get-ADRootDSE).schemaNamingContext -Property objectVersion | Select objectVersion
    
    switch ($SchemaInfo.objectVersion)
    {
    87{$SchemaVersion ="Windows Server 2016R2"}
    85{$SchemaVersion ="Windows Server 2016"}
    69{$SchemaVersion ="Windows Server 2012 R2"}
    56{$SchemaVersion ="Windows Server 2012"}
    47{$SchemaVersion ="Windows Server 2008 R2"}
    44{$SchemaVersion ="Windows Server 2008"}
    31{$SchemaVersion ="Windows Server 2003 R2"}
    30{$SchemaVersion ="Windows Server 2003"}
    13{$SchemaVersion ="Windows 2000"}
    default 
        {
        $SchemaVersion ="Unrecognised schema version "
        $SchemaVersion += $SchemaInfo.objectVersion
        }
    }
    
    Add-Member -InputObject $Domain -MemberType NoteProperty -Name DomainName -Value $DomainInfo.DistinguishedName
    Add-Member -InputObject $Domain -MemberType NoteProperty -Name DNSroot -Value $DomainInfo.DNSRoot
    Add-Member -InputObject $Domain -MemberType NoteProperty -Name FunctionalLevel -Value $DomainInfo.DomainMode
    Add-Member -InputObject $Domain -MemberType NoteProperty -Name Schema -Value $SchemaVersion    
    Add-Member -InputObject $Domain -MemberType NoteProperty -Name SchemaVersion -Value $SchemaInfo.objectVersion
    
    Return $Domain
    }

    Function Get-Sitelinks
    {
    $links = @() 
    $siteLinks = Get-ADObject -LDAPFilter '(objectClass=siteLink)' -SearchBase (Get-ADRootDSE).ConfigurationNamingContext -Property *
    foreach($sitelink in $siteLinks)
    {
    $targets = ""
    $link = New-Object PSObject
    Add-Member -InputObject $link -MemberType NoteProperty -Name Name -Value $sitelink.Name
    Add-Member -InputObject $link -MemberType NoteProperty -Name Cost -Value $sitelink.Cost
    Add-Member -InputObject $link -MemberType NoteProperty -Name Interval -Value $sitelink.replInterval
    Add-Member -InputObject $link -MemberType NoteProperty -Name Options -Value $sitelink.options
    foreach ($site in $sitelink.Sitelist)
        {
        $sitename = "$($site.SubString(3,$site.IndexOf(",")-3)),"
        if (($site.IndexOf("-")) -gt 0)
            {
            $sitename = "$($site.SubString(3,$site.IndexOf("-")-3)),"
            }
        $targets += $sitename
        }
        $targets = $targets.TrimEnd(',')
        Add-Member -InputObject $link -MemberType NoteProperty -Name Partners -Value $targets
        Add-Member -InputObject $link -MemberType NoteProperty -Name Description -Value $sitelink.Description
        $links += $link
        }
        Return $links
    }

    Function Check-HostConnection
        {
        param([string] $SystemName)
        $status = Test-Connection $SystemName -Quiet -Count 1
        return $status
        }

    Function Get-HostUptime 
        {
        param ([string]$ComputerName)
        $Uptime = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName
        $LastBootUpTime = $Uptime.ConvertToDateTime($Uptime.LastBootUpTime)
        $Time = (Get-Date) - $LastBootUpTime
        Return '{0:00}:{1:00}:{2:00}:{3:00}' -f $Time.Days, $Time.Hours, $Time.Minutes, $Time.Seconds
        }

    Function Get-DCDiag
    {
    param([string] $DCName)
    $dcdiag = Dcdiag.exe /s:$DCName
    $failcount = 0
    $passcount = 0
    $healthbar = ""
    $Results = New-Object Object
    # Regex work done by http://www.powershellbros.com/using-powershell-perform-dc-health-checks-dcdiag-repadmin/
    $Dcdiag | %{ 
    Switch -RegEx ($_) 
        { 
        "Starting"      { $TestName   = ($_ -Replace ".*Starting test: ").Trim() } 
        "passed test|failed test"
            { 
            If ($_ -Match "passed test")
                {
                $TestStatus = "Passed"
                $passcount ++
                }  
            Else 
                {
                $TestStatus = "Failed"
                $failcount ++
                } 
            } 
        }
        If ($TestName -ne $Null -And $TestStatus -ne $Null) 
            { 
            $testcount ++
        $Results | Add-Member -Name $("$TestName".Trim()) -Value $TestStatus -Type NoteProperty -force
            if($TestStatus = "Failed")
                {
                
                }
                $TestName = $Null; $TestStatus = $Null      
            }
        }
        #health bar - it's a kludge, I don't like it, but it will do as a bargain-basement visualization for now
        
        $healthbar= $healthbar + "<font color = Green>"
        for ($i = 0; $i -lt $passcount; $i++)
        { 
            $healthbar= $healthbar + $LeftGraphChar
        }
        $healthbar= $healthbar + "</font><font color = Red>"
        for ($i = 0; $i -lt $failcount; $i++)
        { 
            $healthbar= $healthbar + $RightGraphChar
        }
        Add-Type -AssemblyName System.Web

        $ConvertedHealthBar = [System.Web.HttpUtility]::HtmlDecode(($healthbar))
        $ConvertedFailBar = [System.Web.HttpUtility]::HtmlDecode(($healthbar))
        $Results | Add-Member -Type NoteProperty -Name "Health" -Value "$ConvertedHealthBar</font>"
        $perfmonRel = (get-ciminstance Win32_ReliabilityStabilityMetrics -computername $DCName -property * -ErrorAction SilentlyContinue | select-object -first 1 SystemStabilityIndex)
        $Results | Add-Member -Type NoteProperty -Name "Reliability" -Value $perfmonRel.SystemStabilityIndex
        Return $Results
    }
#endregion
$now = get-date
$report += "<br><H1>Active Directory Health Check:<br></H2><br>updated $now<br>"
$report += "<br><H3>Forrest Summary:<br></H2><br>"
$report += Get-ForestInfo | ConvertTo-Html -Fragment
$report += "<br><H3>Domain Summary:<br></H2><br>"
$report += Get-DomainInfo | ConvertTo-Html -Fragment
$report += "<br><H3>Replication Topology:<br></H2><br>"
$report += Get-Sitelinks  | ConvertTo-Html -Fragment
$report +='<dl class="decision-tree"><dt>Domain Controller Details</dt>'
$report += "<dd>"
$DomainControllers = Get-ADDomainController -filter *
$report += "<dl>"
Foreach($DomainController in $DomainControllers)
    {
    $rolecount = 0
    $roles = ""
    write-host $DomainController
    if(Check-HostConnection $DomainController)
        {
        write-host "Server is Alive!"        
        $DC = New-Object psobject
        Add-Member -InputObject $DC -MemberType NoteProperty -Name Name -Value $DomainController.Name
        Add-Member -InputObject $DC -MemberType NoteProperty -Name FQDN -Value $DomainController.HostName
        Add-Member -InputObject $DC -MemberType NoteProperty -Name Domain -Value $DomainController.Domain
        Add-Member -InputObject $DC -MemberType NoteProperty -Name OperatingSystem -Value $DomainController.OperatingSystem
        Add-Member -InputObject $DC -MemberType NoteProperty -Name OSVersion -Value $DomainController.OperatingSystemVersion
        Add-Member -InputObject $DC -MemberType NoteProperty -Name Uptime -Value (Get-HostUptime $DomainController)
        $roles += "<font size=1>"
        foreach($role in ($DomainController.OperationMasterRoles))
            {
            $roles += $role.ToString()
            $roles += "<br>"
            }
        $roles += "</font>"
        Add-Member -InputObject $DC -MemberType NoteProperty -Name FSMORoles -Value $roles
        Add-Member -InputObject $DC -MemberType NoteProperty -Name IPv4 -Value  $DomainController.IPv4Address
        $DcDiag = Get-DCDiag $DomainController
        $fails = ""
        foreach($property in $DcDiag.PsObject.Properties)
            {
            Add-Member -InputObject $DC -MemberType NoteProperty -Name $property.Name -Value $property.Value
            Write-Host $property.Name
            Write-host $property.Value
            if($property.Value -eq "Failed")
                {
                $fails += $property.Name
                $fails += "<br>"
                write-host "****FAILED*** $fails"
                }
            }
            
            Add-Member -InputObject $DC -MemberType NoteProperty -Name DiagError -Value $fails
            write-host "added $fails to DiagError"
        }
Else 
        {
        write-host "Server is Offline!"        
        $DC = New-Object psobject
        Add-Member -InputObject $DC -MemberType NoteProperty -Name Name -Value $DomainController.Name
        Add-Member -InputObject $DC -MemberType NoteProperty -Name FQDN -Value $DomainController.HostName
        Add-Member -InputObject $DC -MemberType NoteProperty -Name Domain -Value $DomainController.Domain
        Add-Member -InputObject $DC -MemberType NoteProperty -Name OperatingSystem -Value $DomainController.OperatingSystem
        Add-Member -InputObject $DC -MemberType NoteProperty -Name OSVersion -Value $DomainController.OperatingSystemVersion
        Add-Member -InputObject $DC -MemberType NoteProperty -Name Uptime -Value "00:00:00"
        Add-Member -InputObject $DC -MemberType NoteProperty -Name Uptime -Value (Get-HostUptime $DomainController)
        Add-Member -InputObject $DC -MemberType NoteProperty -Name DiagError -Value ""
        $roles += "<font size=1>"
        foreach($role in ($DomainController.OperationMasterRoles))
            {
            $roles += $role.ToString()
            $roles += "<br>"
            }
        $roles += "</font>"
        Add-Member -InputObject $DC -MemberType NoteProperty -Name FSMORoles -Value $roles
        Add-Member -InputObject $DC -MemberType NoteProperty -Name IPv4 -Value  $DomainController.IPv4Address
        }

        $Servers += $DC
        $exportpath = $logpath + $DC.Name + ".xml"
        If ($(Try { Test-Path $exportpath} Catch { $false })){Remove-Item $exportpath -force}
        $DC | Export-Clixml -Path $exportpath
       
    }
$report += $Servers |select FQDN,OperatingSystem,Uptime,FSMORoles,IPv4,Health,DiagError,Reliability | ConvertTo-Html -Fragment | Foreach {$PSItem -replace "<td>Failed</td>", "<td style='background-color:#FF8080'>Failed</td>"} | Foreach {$PSItem -replace '&lt;','<'} | Foreach {$PSItem -replace '&gt;','>'} | Foreach {$PSItem -replace '%#%','&#9829'} | Foreach {$PSItem -replace '%@%','&#9825'}
$report += "</dl></dd>"
    
$HTMLHead = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /><html><head><link rel="stylesheet" type="text/css" href="style.css" /><title>Site Information</title><meta http-equiv="refresh" content="600"> </head><body>'
$HTMLBody = ''
$HTMLFooter = '</dl></dd></dl></dd><script src="https://code.jquery.com/jquery-2.2.4.min.js" integrity="sha256-BbhdlvQf/xTY9gja0Dq3HiwQF8LaCRTXxZKRutelT44=" crossorigin="anonymous"></script>
<script type="text/javascript" src="code.js"></script></body></html>'

#if you build it, He will come.
add-content -Path $path -Value $HTMLHead
add-content -Path $path -Value $HTMLBody

add-content -Path $path -Value $report
add-content -Path $path -Value $HTMLFooter


add-content -Path $csspath -Value 'TABLE {border-width: 1px; border-style: solid; border-color: black; } TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;} tr:nth-child(even) {background-color: #6495ED;} tr:hover {background-color: #ffff66;} dl.decision-tree dl {margin:3px 0px;}dl.decision-tree dd {margin:3px 0px 3px 20px;}dl.decision-tree dd.collapsed {display:none;}dl.decision-tree dt:before {content:"-";display:inline-block;width:10px;font-weight:bold; font-size:65%;}dl.decision-tree dt.collapsed:before {content:"+";}' 
add-content -Path $jspath -Value '      $("dl.decision-tree dd, dl.decision-tree dt").addClass("collapsed");  $("dl.decision-tree dt").click(function(event) {  	$(event.target).toggleClass("collapsed");    $(event.target).next().toggleClass("collapsed");  });'
write-host "Report is complete, please check $path"
