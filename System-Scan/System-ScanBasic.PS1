[CmdletBinding()]
param (
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[string] $DCName = $null
)
$Logpath = "C:\temp"
$Logfile = "Health.txt"

Function Write-Log
    {
    param
        (
        [string] $line
        )
    add-content -Path "$Logpath\$Logfile" -Value $line
    }

Function Check-LogPath
    {
    if (!(Test-Path $Logpath)) 
        {
        New-Item -Force -Path $Logpath -ItemType directory
        }
    if(![System.IO.File]::Exists($Logfile))
        {
        #rename file to .old

        }
    }

Function Check-HostConnection
    {
    param([string] $ComputerName)
    $status = Test-Connection $ComputerName -Quiet -Count 1
    return $status
    }

Function Check-DCDiag
    {
    param([string] $DCname)
    #check if DC
    $isDC = $false
    try
        {
        $DC = Get-ADDomainController -Identity $DCName
        $isDC = $true
        }
    catch
        {
        Write-Log "Error:"
        Write-Log $_.Exception.Message 
        }

        if($isDC)
            {
            $dcdiag = Dcdiag.exe /s:$DCName

            }
       }

    

Function Get-HostUptime 
{
    param ([string]$ComputerName)
    $Uptime = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName
    $LastBootUpTime = $Uptime.ConvertToDateTime($Uptime.LastBootUpTime)
    $Time = (Get-Date) - $LastBootUpTime
    Return '{0:00} Days, {1:00} Hours, {2:00} Minutes, {3:00} Seconds' -f $Time.Days, $Time.Hours, $Time.Minutes, $Time.Seconds
}

Function Get-SystemInfo
    {
    param([string] $ComputerName)
    $diskinfo = Get-WmiObject Win32_LogicalDisk -ComputerName $ComputerName -Filter "DeviceID='C:'" |Select-Object Size,FreeSpace
    $compinfo = Get-WmiObject Win32_ComputerSystem -computername $ComputerName | Select-Object PartofDomain,Caption,Domain,Username
    $RAMInfo = Get-WmiObject -Class Win32_OperatingSystem -computername $ComputerName | Select-Object Name, TotalVisibleMemorySize, FreePhysicalMemory
    $TotalRAM = $RAMInfo.TotalVisibleMemorySize/1MB
    $FreeRAM = $RAMInfo.FreePhysicalMemory/1MB
    $UsedRAM = $TotalRAM - $FreeRAM
    $RAMPercentFree = ($FreeRAM / $TotalRAM) * 100
    $system = New-Object psobject -Property @{
        Name = $ComputerName
        OS = $_.caption 
        HDDinGB = [Math]::Round((($diskinfo.Size / 1024) / 1024) / 1024,2)
        HDDFreeInGB = [Math]::Round((($diskinfo.FreeSpace / 1024) / 1024) / 1024,2)
        HDDFreePercent = [Math]::Round($diskinfo.FreeSpace / $diskinfo.Size * 100,2)
        TotalRAM = [Math]::Round($TotalRAM, 2)
        FreeRAM = [Math]::Round($FreeRAM, 2)
        UsedRAM = [Math]::Round($UsedRAM, 2)
        RAMPercentFree = [Math]::Round($RAMPercentFree, 2)
        Domain = $compinfo.Domain
        ActiveUSer = $compinfo.Username
        Uptime = Get-HostUptime $ComputerName
        }
        Return $system
    }


    $Diag = Get-SystemInfo $DCName
    $Diag

