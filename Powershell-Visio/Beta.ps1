#this *sort of* works. 
#Find-module visio


Import-Module Visio
New-VisioApplication
$doc = New-VisioDocument
$pages = $doc.ActiveDocument.Pages 
#$page = $pages.Item(1) 
$basic_u = Open-VisioDocument basic_u.vss
$master = Get-VisioMaster "Rectangle" $basic_u

$font = $doc.Fonts["Segoe UI"]
$fontid  = $font.ID

# This is a demo, so get some dates relative to the current date
$date_today = Get-Date
$date_today = $date_today.Date
$lower_date = $date_today.AddDays(-3)
$upper_date = $date_today.AddDays(4)
$date_rtm = $date_today#.AddDays(2)

$width = 1.0
$height = 1.0 

# Perform the rendering

$color_normal = "rgb(255,255,255)"
$color_highlight = "rgb(255,0,0)"
$color_target = "rgb(200,200,200)"
$links = @()

$siteLinks = Get-ADObject -LDAPFilter '(objectClass=siteLink)' -SearchBase (Get-ADRootDSE).ConfigurationNamingContext -Property Name, Cost, Description, Sitelist 
foreach($sitelink in $siteLinks)
{
    $targets = ""
    $link = New-Object PSObject
    Add-Member -InputObject $link -MemberType NoteProperty -Name Name -Value $sitelink.Name
    Add-Member -InputObject $link -MemberType NoteProperty -Name Cost -Value $sitelink.Cost
    Add-Member -InputObject $link -MemberType NoteProperty -Name SiteLinks -Value $sitelink.Sitelist

    foreach ($site in $link.SiteLinks)
        {
        $sitename = "$($site.SubString(3,$site.IndexOf(",")-3)),"
        if (($site.IndexOf("-")) -gt 0)
        {$sitename = "$($site.SubString(3,$site.IndexOf("-")-3)),"}
        #Add-Member -InputObject $link -MemberType NoteProperty -Name $sitename -Value $site.ToString() 
        $targets += $sitename
        }
        $targets = $targets.TrimEnd(',')
    Add-Member -InputObject $link -MemberType NoteProperty -Name Partners -Value $targets
    $links += $link
    
}


$n=0
$y=10
$x=2
$step = (11/$links.Count)
foreach($link in $links)
{
    #$x = ($n*$width) + ($n)
    $y = (10-$n)-1
    $shape = New-VisioShape $master $x,$y 
    $text = $link.Name
    Set-VisioShapeText $text
    
    $n=$n+$step

    write-host "$y , $x"
    Add-Member -InputObject $link -MemberType NoteProperty -Name ShapeID $shape.ID
    
}
foreach($link in $links)
{
    foreach($target in $link.Partners.Split(","))
    {
    write-host ($link.Name) - " should connect to $target"
    }
}
$links
