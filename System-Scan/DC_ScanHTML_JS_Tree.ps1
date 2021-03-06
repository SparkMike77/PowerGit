#Domain Function Test
#Written by Michael Plambeck
# Updated 8/22/2018
#
# Added Domain Overview Section including Schema:
# 
#  Get-ADObject (Get-ADRootDSE).schemaNamingContext -Property objectVersion 
#
#  69 = Windows Server 2012 R2
#  56 = Windows Server 2012
#  47 = Windows Server 2008 R2
#  44 = Windows Server 2008
#  31 = Windows Server 2003 R2
#  30 = Windows Server 2003
#  13 = Windows 2000



#
#
# WARNING: Script Presented AS IS, No warranty implied or otherwise given
# - This Script creates 3 files, recycling them with each execution
# - This script produces a report that uses JavaScript
# - It's Dirty, I know.  Eventually I will convert this to HTML 5, and add pretty charts with pithy comments... hopefully before the heat death of the universe.
#
#Still needs Cleanup, but the functionality is what I need right now

# Things to add:
#  Domain Controller OS Detection
#  BPA link
#  Azure Connection/Sync detection and health checking
#  Graphs and health info, maybe something like what http://www.the-little-things.net/ did?

$path = "C:\SiteInfo\SiteMap.HTML"
$csspath ="C:\SiteInfo\style.css"
$jspath ="C:\SiteInfo\code.js"
$report = "<dt>Domain Controllers</dt>"
$report += "<dd>"
$report += "<dl>"

#region Setup

#check if there is a map already, if so delete it
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
    #Add-Member -InputObject $Domain -MemberType NoteProperty -Name Parent -Value $DomainInfo.ParentDomain
    #Add-Member -InputObject $Domain -MemberType NoteProperty -Name Children -Value $DomainInfo.ChildDomains
    
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
    #Don't mess with the RegEx.  Is wasn't fun to write.
    #https://alf.nu/RegexGolf  will teach you how, but it isn't fun.                                     
    # UPDATE: Mine sucked, this one was better.
    # http://www.powershellbros.com/using-powershell-perform-dc-health-checks-dcdiag-repadmin/
    Switch -RegEx ($_) 
        { 
        "Starting"      { $TestName   = ($_ -Replace ".*Starting test: ").Trim() } 
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
    #Maybe add something from these links to make it pretty?
    #https://chart.googleapis.com/chart?cht=p3&chd=t:60,40&chs=250x100&chl=Hello|World
    #https://developers.google.com/chart/image/docs/making_charts

#endregion

$DomainControllers = Get-ADDomainController -filter * 

#This is where Overall Domain info should go
$DomainBlock = Get-DomainInfo | ConvertTo-Html -Fragment
$report = "<h2>Domain Information</h2>"
$report += $DomainBlock
Write-host "Domain Block added"

$report +='<dl class="decision-tree">'
$report += "<dt>Domain Controllers</dt>"
$report += "<dd>"
$report += "<dl>"

#Individual DC health Checks
#region IndividualDCchecks


Foreach($dc in $DomainControllers)
{
    write-host "Testing $dc"
    if(Check-HostConnection $dc)
    {
    write-host "Server is Alive!"

    #get Uptime
    $uptime = Get-HostUptime $dc
    
    #get FSMO Role Holders and names
    $roles =""
    $rolecount = 0
    
    foreach ($role in ($dc.OperationMasterRoles))
        {
        $roles += "$role <br>"
        $rolecount = $rolecount + 1
        }
    if($rolecount -eq 0)
        {
        $report += "<dt><b> $dc - Uptime : $uptime </b></dt>"
        $roles = "No FSMO Roles <br>"
        $report += "<dd><dl>"
        $report += "<dt><i>Roles: $rolecount</i></dt>"
        $roles = "No FSMO Roles <br>"
        }
    else
        {
        $report += "<dt><b> $dc - Uptime : $uptime </b><sup>*FSMO Role Holder</sup></dt>"
        $report += "<dd><dl>"
        $report += "<dt>Roles: $rolecount</dt>"
        }
    
    $report += "<dd><dl>"
    $report += $roles
    $report += "</dl></dd>"
    
    #get DCDiag Results
    $DcDiag = $null #Just in case
    $DcDiag = Get-DCDiag $dc
    
    foreach($property in $DcDiag.PsObject.Properties)
        {
        #Write-host $property.Value
        if ($property.Value -eq "Passed")
            {
            #single Quotes so I can tag colors
            $DCTestTitle = '<dt>DCDiag Tests: <font color = "Green">All Pass</font></dt>'
            $DCTest +=  "$($property.Name)"
            $DCTest += '<font color ="green"> ' 
            $DCTest += "$($property.Value)"
            $DCTest += "</font><br>"
            }
        else
            {
            #single Quotes so I can tag colors
            $DCTestTitle = '<dt>DCDiag Tests: <font color ="red">Some Failures</font></dt>'
            $DCTest +=  "$($property.Name)"
            $DCTest += '<font color ="red"> ' 
            $DCTest += "$($property.Value)"
            $DCTest += "</font><br>"

            }
        }
    
    #$report += "<dt>DCDiag Tests:</dt>"
    $report += $DCTestTitle
    $report += "<dd><dl>"
    $report += $DCTest
    $report += "</dl></dd>"
    $DCTest = $null #just in case it didn't believe me last time!
    write-host "Diagnostics Complete"

    #get IP addresses
    $ipcount = 0
    $ips = ""
    
    foreach($ip in (Get-NetIPAddress).IPAddress)
        {
        $ips += "$ip <br>"
        $ipcount = $ipcount+1
        }
    $report += "<dt>IP Addresses:$ipcount</dt>"
    $report += "<dd><dl>"
    $report += $ips
    $ips = $null
    write-host "IP Lisiting Complete"
    }
    
    else
        {
        $report += "<dt><i> $dc.Name - Currently Unreachable </i></dt>"
        write-host "Server in Not Responding"
        }    

    $report += "</dl></dd>"

    #close Dropdown for this DC
    $report += "</dl></dd>"
    Write-Host "Report Updated"
}
#endregion


#region WriteOutPage

#there's probably no reason to screw with any of this
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
#endregion
