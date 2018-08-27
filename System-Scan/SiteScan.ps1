#Written by Mike Plambeck
#Updated 8/27/2018
#Refactor Continues

#region Setup

#check if there is a map already, if so delete it

$path = "C:\SiteInfo2\SiteMap.HTML"
$csspath ="C:\SiteInfo2\style.css"
$jspath ="C:\SiteInfo2\code.js"
$report = ""
$Servers = @()
If ($(Try { Test-Path $path} Catch { $false })){Remove-Item $path -force}
If ($(Try { Test-Path $csspath} Catch { $false })){Remove-Item $csspath -force}
If ($(Try { Test-Path $jspath} Catch { $false })){Remove-Item $jspath -force}

#endregion

#region Functionblocks

    Function Get-DomainInfo
    {
    #param([string] $DomainName)

    #Get Domain Schema Level
    $SchemaVersion =""
    $SchemaInfo = Get-ADObject (Get-ADRootDSE).schemaNamingContext -Property objectVersion | Select objectVersion
    switch ($SchemaInfo.objectVersion)
    {
    69{$SchemaVersion ="Windows Server 2012 R2"}
    56{$SchemaVersion ="Windows Server 2012"}
    47{$SchemaVersion ="Windows Server 2008 R2"}
    44{$SchemaVersion ="Windows Server 2008"}
    31{$SchemaVersion ="31 = Windows Server 2003 R2"}
    30{$SchemaVersion ="Windows Server 2003"}
    13{$SchemaVersion ="Windows 2000"}
    default 
        {
        $SchemaVersion ="Unrecognised schema version "
        $SchemaVersion += $SchemaInfo.objectVersion
        }
    }

    #Get Domain Attributes, incl Functional Level
    $DomainInfo = Get-addomain 
    $Domain = new-object psobject
    Add-Member -InputObject $Domain -MemberType NoteProperty -Name Forrest -Value $DomainInfo.Forest
    Add-Member -InputObject $Domain -MemberType NoteProperty -Name Name -Value $DomainInfo.DistinguishedName
    Add-Member -InputObject $Domain -MemberType NoteProperty -Name DNSroot -Value $DomainInfo.DNSRoot
    Add-Member -InputObject $Domain -MemberType NoteProperty -Name FunctionalLevel -Value $DomainInfo.DomainMode
    Add-Member -InputObject $Domain -MemberType NoteProperty -Name SchemaVersion -Value $SchemaInfo.objectVersion
    Add-Member -InputObject $Domain -MemberType NoteProperty -Name Schema -Value $SchemaVersion    
    
    Return $Domain
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
        $Results = New-Object Object
        $Results | Add-Member -Type NoteProperty -Name "ServerName" -Value $DCName
        $Dcdiag | %{ 
    # Don't mess with the RegEx. Https://alf.nu/RegexGolf  will teach you how, but it isn't fun.                                     
    # Mine sucked, this one was better. http://www.powershellbros.com/using-powershell-perform-dc-health-checks-dcdiag-repadmin/
        Switch -RegEx ($_) 
            { 
            "Starting" { $TestName   = ($_ -Replace ".*Starting test: ").Trim() } 
            "passed test|failed test"
                { 
            If ($_ -Match "passed test"){$TestStatus = "Passed"}  
            Else {$TestStatus = "Failed"} 
            } 
        }
        If ($TestName -ne $Null -And $TestStatus -ne $Null) 
            { 
        $Results | Add-Member -Name $("$TestName".Trim()) -Value $TestStatus -Type NoteProperty -force
            if($TestStatus = "Failed")
                {
                
                }
                $TestName = $Null; $TestStatus = $Null      
            }
        }
        Return $Results
    }


#endregion

$report += "<H2>Domain Summary:<br></H2>"
$report += Get-DomainInfo | ConvertTo-Html -Fragment
$report +='<br><br><dl class="decision-tree"><dt><H2>Domain Controller Details</H2></dt>'

$report += "<dd>"
$DomainControllers = Get-ADDomainController -filter *
Foreach($DomainController in $DomainControllers)
    {
    $report += "<dl>"
    $rolecount = 0
    if(Check-HostConnection $DomainController)
        {
        write-host $DomainController
        write-host "Server is Alive!"        
        $DC = New-Object psobject
        Add-Member -InputObject $DC -MemberType NoteProperty -Name Name -Value $DomainController.Name
        Add-Member -InputObject $DC -MemberType NoteProperty -Name FQDN -Value $DomainController.HostName
        Add-Member -InputObject $DC -MemberType NoteProperty -Name Domain -Value $DomainController.Domain
        Add-Member -InputObject $DC -MemberType NoteProperty -Name OperatingSystem -Value $DomainController.OperatingSystem
        Add-Member -InputObject $DC -MemberType NoteProperty -Name OperatingSystemVersion -Value $DomainController.OperatingSystemVersion
        Add-Member -InputObject $DC -MemberType NoteProperty -Name Uptime -Value (Get-HostUptime $DomainController)
        foreach($role in ($DomainController.OperationMasterRoles))
            {
            $rolecount ++
            }
        Add-Member -InputObject $DC -MemberType NoteProperty -Name FSMO -Value $rolecount
        Add-Member -InputObject $DC -MemberType NoteProperty -Name IPv4 -Value  $DomainController.IPv4Address
    
        $DcDiag = Get-DCDiag $DomainController
        foreach($property in $DcDiag.PsObject.Properties)
            {
            Add-Member -InputObject $DC -MemberType NoteProperty -Name $property.Name -Value $property.Value
            }
        }
        $Servers += $DC
     
    }
           $report += $Servers | ConvertTo-Html -Fragment
           $report += "</dl></dd>"
    

$HTMLHead = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"><html><head><link rel="stylesheet" type="text/css" href="style.css" /><title>Site Information</title></head><body>'
$HTMLBody = ''
$HTMLFooter = '</dl></dd></dl></dd><script src="https://code.jquery.com/jquery-2.2.4.min.js" integrity="sha256-BbhdlvQf/xTY9gja0Dq3HiwQF8LaCRTXxZKRutelT44=" crossorigin="anonymous"></script>
<script type="text/javascript" src="code.js"></script></body></html>'

#if you build it, He will come.
add-content -Path $path -Value $HTMLHead
add-content -Path $path -Value $HTMLBody

add-content -Path $path -Value $report
add-content -Path $path -Value $HTMLFooter


add-content -Path $csspath -Value 'TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;} TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;} dl.decision-tree dl {margin:3px 0px;}dl.decision-tree dd {margin:3px 0px 3px 20px;}dl.decision-tree dd.collapsed {display:none;}dl.decision-tree dt:before {content:"-";display:inline-block;width:10px;font-weight:bold; font-size:65%;}dl.decision-tree dt.collapsed:before {content:"+";}' 
add-content -Path $jspath -Value '      $("dl.decision-tree dd, dl.decision-tree dt").addClass("collapsed");  $("dl.decision-tree dt").click(function(event) {  	$(event.target).toggleClass("collapsed");    $(event.target).next().toggleClass("collapsed");  });'
