#Not useful yet, but getting the actual data was enough of a PITA that I didn't want to lose this.

$Results = Get-WinEvent -FilterHashTable @{LogName="Security"; ID=4740} -ComputerName [TARGET DC] -MaxEvents 1| Select *
foreach($Result in $Results)
    {
    [string]$Item = $Result.Message
    $sMachineName = $Item.SubString($Item.IndexOf("Caller Computer Name"))
    $sMachineName = $sMachineName.TrimStart("Caller Computer Name :")
    $sMachineName = $sMachineName.TrimEnd("}")
    $sMachineName = $sMachineName.Trim()
    $sMachineName = $sMachineName.TrimStart("\\")
    #Write-Host $Result.Message
    #Write-Host "User $sUserName"
    #$user = $Result.Properties[0].Value
    #$system = $sMachineName
    $hint = ""

    if ($sMachineName -eq "CRP-ADFS91-VP01"){$hint = "This is likely a mobile device"}
    elseif ($sMachineName -eq "CRP-ADFS91-VP01"){$hint = "This Device is not reporting its' name"}

    $Lockout = New-Object PSObject -Property @{
    Time = $Result.TimeCreated
    Account = $Result.Properties[0].Value
    Source = $sMachineName
    Hint = $hint}

    $lockout | Export-Csv -Path c:\Tools\Lockout.csv -Append -NoTypeInformation
    
    #Write-Host "At $time , User $user was locked out on $system"
    }
