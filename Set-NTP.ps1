# =======================================================
# NAME: Set-NTP.ps1
# AUTHOR: LOPES Mickaël, AZEO
# DATE: 25/11/2014
#
# VERSION 1.0
# COMMENTS: Set NTP
#
# /!\ Execute with Administrator's rights !
# =======================================================

<#
 .EXAMPLE
     [ps] c:\users> set-ntp -url 10.17.215.50,1.pool.ntp.org,2.pool.ntp.org
  #>

PARAM (
[parameter()] 
[String[]] $URL)


#Check run in Administrator
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
     Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
     Break
    }

# Check if URL != NULL
if ($URL -eq $NULL) {
write-Warning "No URL set, please set an URL"
Break
}

# FUNCTION
Function Config-NTP {
write-host -fore white "INFO : Test NTP Connectivity"
                foreach ($i in $URL) {
				$test = w32tm /stripchart /computer:$i /samples:1 /dataonly
				    if ($test.split() -ccontains "Collecting" -eq $true) {
                    write-host -fore green "NTP Connectivity for $i OK"
                    if ($Script:URLS) {$Script:URLS += ","}
                    $Script:URLS += $i
                    }else{
                    write-Warning "$i is unreachable. Please Check Firewall or URL"
                    }
                    }
if ($URLS -eq $NULL) {
write-host -fore Red "ERROR : No URL available, please set an URL"
Break
}
	write-host -fore white "INFO : Configure NTP Service with param : $URLS"
			w32tm /configure /manualpeerlist:$URLS /syncfromflags:manual /update
    if ((Get-Service -name W32Time).status -eq "Running" -eq $true){
    write-host -fore white "INFO : Stop NTP Service"	
			net stop w32time 
    }else{}
	write-host -fore white "INFO : Start NTP Service"
			net start w32time
}

Function Test-NTP {
write-host -fore white "INFO : Test NTP Configuration"
sleep 20

$Configuration = (W32tm /query /source).trim()
if ($Configuration -like $URLS) {
write-host -fore Green "NTP Configuration OK ! Your configuration is $Configuration"
write-host -fore white "INFO : Force NTP Sync"
W32tm /resync /rediscover
}else{
write-host -fore red "ERROR : NTP Configuration KO Your NTP Server is $Configuration"
}
}

# BODY

# Check if this computer is member of a domain
if ((gwmi win32_computersystem).partofdomain -eq $true) {
    write-host -fore white "INFO : Your are a member of a domain"
try{
    $PDCHost = (Get-ADDomain -EA Stop).PDCEmulator 
}catch{ write-host -fore red "ERROR : This script is for PDC Server"
exit}
    if ($PDCHost -eq "$env:computername.$env:userdnsdomain") {
                write-host -fore green "Your are on the PDC Server"
                Config-NTP
                Test-NTP
		}else{
			write-host -fore red "ERROR : This script is for PDC Server. Please execute in this server: $PDCHost"
			exit
			}
# If not a member of domain
} else {
    write-host -fore white "INFO : Your are in a workgroup"
    Config-NTP
    Test-NTP
}
