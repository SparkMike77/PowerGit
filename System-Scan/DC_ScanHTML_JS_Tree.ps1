#Domain Function Test
#Written by Michael Plambeck
#Updated 8/9/2018
# WARNING: Script Presented AS IS, No warranty implied or otherwise given
# - This Script creates 3 files, recycling them with each execution
# - This script produces a report that uses JavaScript
# - It's Dirty, I know.  Eventually I will convert this to HTML 5, and add pretty charts with pithy comments... hopefully before the heat death of the universe.
#
#Still needs Cleanup, but the functionality is what I need right now
#Things to add:
#  Domain Overview Section including Schema
#  Domain Controller OS Detection
#  

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
    $DcDiag = $null
    $DcDiag = Get-DCDiag $dc
    
    foreach($property in $DcDiag.PsObject.Properties)
        {
        $DCTest +=  "$($property.Name) $($property.Value) <br>"
        }
    
    $report += "<dt>DCDiag Tests:</dt>"
    $report += "<dd><dl>"
    $report += $DCTest
    $report += "</dl></dd>"
    $DCTest = $null
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


#region WriteOutReport

#there's probably no reason to screw with any of this
$HTMLHead = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"><html><head><link rel="stylesheet" type="text/css" href="style.css" /><title>Site Information</title></head><body>'
$HTMLBody ='<dl class="decision-tree">'
$HTMLFooter = '</dl></dd></dl></dd><script src="https://code.jquery.com/jquery-2.2.4.min.js" integrity="sha256-BbhdlvQf/xTY9gja0Dq3HiwQF8LaCRTXxZKRutelT44=" crossorigin="anonymous"></script>
<script type="text/javascript" src="code.js"></script></body></html>'

add-content -Path $path -Value $HTMLHead
add-content -Path $path -Value $HTMLBody
add-content -Path $path -Value $report
add-content -Path $path -Value $HTMLFooter


add-content -Path $csspath -Value 'dl.decision-tree dl {margin:3px 0px;}dl.decision-tree dd {margin:3px 0px 3px 20px;}dl.decision-tree dd.collapsed {display:none;}dl.decision-tree dt:before {content:"-";display:inline-block;width:10px;font-weight:bold; font-size:65%;}dl.decision-tree dt.collapsed:before {content:"+";}' 
add-content -Path $jspath -Value '      $("dl.decision-tree dd, dl.decision-tree dt").addClass("collapsed");  $("dl.decision-tree dt").click(function(event) {  	$(event.target).toggleClass("collapsed");    $(event.target).next().toggleClass("collapsed");  });'
#endregion
