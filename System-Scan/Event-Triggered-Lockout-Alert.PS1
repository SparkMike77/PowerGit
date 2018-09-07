#Not useful yet, but getting the actual data was enough of a PITA that I didn't want to lose this.

$Results = Get-WinEvent -FilterHashTable @{LogName="Security"; ID=4740} -ComputerName crp-dc91-vp03 -MaxEvents 1| Select *
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
    $user = $Result.Properties[0].Value
    $system = $sMachineName
    $time = $Result.TimeCreated
    Write-Host "At $time , User $user was locked out on $system"
    }
    
    
