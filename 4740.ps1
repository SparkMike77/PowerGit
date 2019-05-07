
$DC = "SERVER-DC1" #This is where the DC name goes.
$ADFSServer = "ADFSServer" #if you are using ADFS, put the name of the sever here (not the web-proxy!)
$date = Get-Date -format "MM-dd-yy" 
$outpath = "c:\Tools\Lockout-$date.csv" #Update this path to reflect where you want the CSV to live
$Results = Get-WinEvent -FilterHashTable @{LogName="Security"; ID=4740} -ComputerName @DC -MaxEvents 1| Select *
foreach($Result in $Results)
    {
    [string]$Item = $Result.Message
    $sMachineName = $Item.SubString($Item.IndexOf("Caller Computer Name"))
    $sMachineName = $sMachineName.TrimStart("Caller Computer Name :")
    $sMachineName = $sMachineName.TrimEnd("}")
    $sMachineName = $sMachineName.Trim()
    $sMachineName = $sMachineName.TrimStart("\\")
    $hint = ""

    if ($sMachineName -eq $ADFSServer){$hint = "This is likely a mobile device"}
    elseif ($sMachineName -eq ""){$hint = "This Device is not reporting its' name"}

    $Lockout = New-Object PSObject -Property @{
    Time = $Result.TimeCreated
    Account = $Result.Properties[0].Value
    Source = $sMachineName
    Hint = $hint}

    $lockout | Export-Csv -Path $outpath -Append -NoTypeInformation
    }