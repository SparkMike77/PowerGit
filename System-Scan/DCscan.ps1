[CmdletBinding()]
param (
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[string] $SystemName = $null
)
$Logpath = "C:\temp\Scan"
$Logfile = "C:\temp\Scan\$SystemName.txt"



Function Write-Log
    {
    param
        (
        [string] $line
        )
    add-content -Path "$Logfile" -Value $line
    add-content -Path "$Logfile" -Value "`r`n"	
    }

Function Check-LogPath
    {
    if (!(Test-Path $Logpath)) 
        {
        New-Item -Force -Path $Logpath -ItemType directory
        }
    	{
#	Get-ChildItem -Path $Logpath | ForEach-Object {Remove-Item}
        }
    }

Function Check-HostConnection
    {
    param([string] $SystemName)
    $status = Test-Connection $SystemName -Quiet -Count 1
    return $status
    }
Function Check-IfDC
    {
     param
        (
        [string] $ComputerName
        )
    Try
        {
        Get-ADDomainController -Identity $ComputerName
        Return $true
        }
    Catch
        {
        Return $false
        }
    }


Function Get-DCDiag
    {
    param([string] $DCName)
    $dcdiag = Dcdiag.exe /s:$DCName
    $Results = New-Object Object
    $Results | Add-Member -Type NoteProperty -Name "ServerName" -Value $Server
    $Dcdiag | %{ 
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
                $TestName = $Null; $TestStatus = $Null      
            }
        }
        Return $Results
    }


Function Get-HostUptime 
    {
    param ([string]$ComputerName)
    $Uptime = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName
    $LastBootUpTime = $Uptime.ConvertToDateTime($Uptime.LastBootUpTime)
    $Time = (Get-Date) - $LastBootUpTime
    Return '{0:00}:{1:00}:{2:00}:{3:00}' -f $Time.Days, $Time.Hours, $Time.Minutes, $Time.Seconds
    }

Function Get-SystemInfo
    {
    param([string] $ComputerName)
    if(Check-HostConnection $ComputerName)
        {
        $diskinfo = Get-WmiObject Win32_LogicalDisk -ComputerName $ComputerName -Filter "DeviceID='C:'" |Select-Object Size,FreeSpace
        $compinfo = Get-WmiObject Win32_ComputerSystem -computername $ComputerName | Select-Object PartofDomain,Domain,Username
        $RAMInfo = Get-WmiObject -Class Win32_OperatingSystem -computername $ComputerName | Select-Object Name, TotalVisibleMemorySize, FreePhysicalMemory,Caption
        if(Check-IfDC $Computername)
            {
            $DCinfo = Get-DCDiag $ComputerName
            $diskinfo = Get-WmiObject Win32_LogicalDisk -ComputerName $ComputerName -Filter "DeviceID='C:'" |Select-Object Size,FreeSpace
            $compinfo = Get-WmiObject Win32_ComputerSystem -computername $ComputerName | Select-Object PartofDomain,Domain,Username
            $RAMInfo = Get-WmiObject -Class Win32_OperatingSystem -computername $ComputerName | Select-Object Name, TotalVisibleMemorySize, FreePhysicalMemory,Caption
            $TotalRAM = $RAMInfo.TotalVisibleMemorySize/1MB
            $FreeRAM = $RAMInfo.FreePhysicalMemory/1MB
            $UsedRAM = $TotalRAM - $FreeRAM
            $RAMPercentFree = ($FreeRAM / $TotalRAM) * 100
            $system = New-Object psobject -Property 
                @{
                Name = $ComputerName
                OperatingSystem = [string]$RAMInfo.Name 
                HDDinGB = [Math]::Round((($diskinfo.Size / 1024) / 1024) / 1024,2)
                HDDFreeInGB = [Math]::Round((($diskinfo.FreeSpace / 1024) / 1024) / 1024,2)
                HDDFreePercent = [Math]::Round($diskinfo.FreeSpace / $diskinfo.Size * 100,2)
                TotalRAM = [Math]::Round($TotalRAM, 2)
                FreeRAM = [Math]::Round($FreeRAM, 2)
                UsedRAM = [Math]::Round($UsedRAM, 2)
                RAMPercentFree = [Math]::Round($RAMPercentFree, 2)
                Domain = [string]$compinfo.Domain
                ActiveUser = [string]$compinfo.Username
                Uptime = Get-HostUptime $ComputerName
                Advertising =$DCinfo.Advertising
                CheckSDRefDom = $DCinfo.CheckSDRefDom
                Connectivity =$DCinfo.Connectivity
                CrossRefValidation = $DCinfo.CrossRefValidation
                DFSREvent= $DCinfo.DFSREvent
                FrsEvent = $DCinfo.FrsEvent
                Intersite = $DCinfo.Intersite
                KccEvent = $DCinfo.KccEvent
                KnowsOfRoleHolders = $DCinfo.KnowsOfRoleHolders
                LocatorCheck = $DCinfo.LocatorCheck
                MachineAccount = $DCinfo.MachineAccount
                NCSecDesc = $DCinfo.NCSecDesc
                NetLogons =$DCinfo.NetLogons
                ObjectsReplicated = $DCinfo.ObjectsReplicated
                Replications = $DCinfo.Replications
                RidManager = $DCinfo.RidManager
                ServerName = $DCinfo.ServerName
                Services = $DCinfo.Services
                SystemLog = $DCinfo.SystemLog
                VerifyReferences = $DCinfo.VerifyReferences
                SysVolCheck = $DCinfo.SysVolCheck
                }
            Return $system
            }
        Else
            {
            $diskinfo = Get-WmiObject Win32_LogicalDisk -ComputerName $ComputerName -Filter "DeviceID='C:'" |Select-Object Size,FreeSpace
            $compinfo = Get-WmiObject Win32_ComputerSystem -computername $ComputerName | Select-Object PartofDomain,Domain,Username
            $RAMInfo = Get-WmiObject -Class Win32_OperatingSystem -computername $ComputerName | Select-Object Name, TotalVisibleMemorySize, FreePhysicalMemory,Caption
            $TotalRAM = $RAMInfo.TotalVisibleMemorySize/1MB
            $FreeRAM = $RAMInfo.FreePhysicalMemory/1MB
            $UsedRAM = $TotalRAM - $FreeRAM
            $RAMPercentFree = ($FreeRAM / $TotalRAM) * 100
            $system = New-Object psobject -Property 
                @{
                Name = $ComputerName
                OperatingSystem = [string]$RAMInfo.Name 
                HDDinGB = [Math]::Round((($diskinfo.Size / 1024) / 1024) / 1024,2)
                HDDFreeInGB = [Math]::Round((($diskinfo.FreeSpace / 1024) / 1024) / 1024,2)
                HDDFreePercent = [Math]::Round($diskinfo.FreeSpace / $diskinfo.Size * 100,2)
                TotalRAM = [Math]::Round($TotalRAM, 2)
                FreeRAM = [Math]::Round($FreeRAM, 2)
                UsedRAM = [Math]::Round($UsedRAM, 2)
                RAMPercentFree = [Math]::Round($RAMPercentFree, 2)
                Domain = [string]$compinfo.Domain
                ActiveUser = [string]$compinfo.Username
                Uptime = Get-HostUptime $ComputerName
                }
            Return $system
            }
        } 
    else {Return $null}
    }

    Check-LogPath
    $Diag = Get-SystemInfo $SystemName
    
    Write-Log "System : $SystemName, output to $Logpath\$SystemName.csv"
   
#    Write-Log $Diag
    $Diag | export-csv "$Logpath\$SystemName.csv"


