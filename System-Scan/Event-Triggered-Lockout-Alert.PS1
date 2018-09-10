#Now Useful!  Hooray!
#written by Mike Plambeck
#Updated 9/10/2018
#To Do: Create setup XML file to contain the parameters
#To Do: Automatically archive the script Daily
#To Do: Get the output from the script into a dashboard
#To Do: Create a "Hint Engine" to look at each entry and propose next steps

#To use this, attach it to event 4740 in the event viewer, running under a service account regardless of whether the user is logged in
#the c:\tools path is here just for convenience, the $PDCe parameter is mandatory, the $ADFS  parameter is not.

param(
[Parameter(Mandatory=$True,Position=1)][string]$PDCe,
[Parameter(Mandatory=$False)][string]$ADFS

)
$outpath = "c:\Tools\Lockout.csv"

$Results = Get-WinEvent -FilterHashTable @{LogName="Security"; ID=4740} -ComputerName $PDCe -MaxEvents 1| Select *
foreach($Result in $Results)
    {
    [string]$Item = $Result.Message
    $sMachineName = $Item.SubString($Item.IndexOf("Caller Computer Name"))
    $sMachineName = $sMachineName.TrimStart("Caller Computer Name :")
    $sMachineName = $sMachineName.TrimEnd("}")
    $sMachineName = $sMachineName.Trim()
    $sMachineName = $sMachineName.TrimStart("\\")
    $hint = ""

    if ($sMachineName -eq $ADFS){$hint = "This is likely a mobile device"}
    elseif ($sMachineName -eq ""){$hint = "This Device is not reporting its' name"}

    $Lockout = New-Object PSObject -Property @{
    Time = $Result.TimeCreated
    Account = $Result.Properties[0].Value
    Source = $sMachineName
    Hint = $hint}

    $lockout | Export-Csv -Path $outpath -Append -NoTypeInformation
    
    
    }
