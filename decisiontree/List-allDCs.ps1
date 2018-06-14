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

#endregion

$DomainControllers = Get-ADDomainController -filter * 
Foreach($dc in $DomainControllers)
{
    if(Check-HostConnection $dc){$report += "<dt><b> $dc.Name </b></dt>"}
    else{$report += "<dt><i> $dc.Name </i></dt>"}    
    #$report += "<dt><b> $dc.Name </b></dt>"
    $report += "<dd>"
    $report += "<dl>"
    #$dc.Name
    #write-host "Roles:"
    $roles =""
    $rolecount = 0
    #$rolecount
    foreach ($role in ($dc.OperationMasterRoles))
    {
        $roles += "$role <br>"
        $rolecount = $rolecount + 1
    }
    if($rolecount -eq 0){$report += "<dt><i>Roles: $rolecount</i></dt>"}
    else{$report += "<dt>Roles: $rolecount</dt>"}
   
    $report += "<dd>"
    $report += "<dl>"
    
    If ($rolecount -eq 0){$roles = "No FSMO Roles <br>"}

    $report += $roles
    $report += "</dl>"
    $report += "</dd>"
    
    $ipcount = 0
    $ips = ""
    foreach($ip in (Get-NetIPAddress).IPAddress)
    {
         $ips += "$ip <br>"
         $ipcount = $ipcount+1
    }
    $report += "<dt>IP Addresses:$ipcount</dt>"
    $report += "<dd>"
    $report += "<dl>"
    $report += $ips
    $report += "</dl>"
    $report += "</dd>"



    $report += "</dl>"
    $report += "</dd>"
}

#$report

#region WriteReport
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
