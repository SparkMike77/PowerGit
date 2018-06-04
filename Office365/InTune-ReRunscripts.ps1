# Heavily indebted to:
#http://powers-hell.com/how-to-force-intune-configuration-scripts-to-re-run/ (a fair chunk of this is a direct copy)
#and
#http://www.powershell.no/azure,graph,api/2017/10/30/unattended-ms-graph-api-authentication.html


#import the modules we need
import-module activedirectory
Import-Module AzureAD
import-module MSGraphIntuneManagement

#Get current date/time
$GMTDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($(Get-Date), [System.TimeZoneInfo]::Local.Id, 'GMT Standard Time')

#Define Comnputer we're working with: This will eventually be replaced
$ComputerName = Read-Host 'Specify Target System'

# Define client ID for an Azure AD Application with necessary permissions against the Microsoft Graph API
$ClientID = "1950a258-227b-4e31-a9cf-717495945fc2"

# Credentials for the user who should be used for authentication
$Credential = Get-Credential

# Generate an access token
$Token = Get-MSGraphAuthenticationToken -Credential $Credential -ClientId $ClientId
# test Token Expiry
if ($Token -ne $null) {$TokenExpDate = ([System.DateTimeOffset]$token.ExpiresOn).DateTime}
$Token
if ($GMTDate -le $tokenExpDate) {write-host "Token is still fresh." -ForegroundColor Green}

#First up, lets get some info about the device.
$deviceProps = (invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/v1.0/devices?`$filter=DisplayName eq '$ComputerName'" -Headers $Token).value
#Next, using the device id captured above, lets grab some info about the registered user of that device.
$owner = (Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/v1.0/devices/$($deviceProps.id)/registeredOwners" -Headers $token).value
#capture the script properties from Intune.
$InTuneScripts = (Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts" -Headers $token).value

#using the user id GUID, we simply iterate through each script object stored in Intune, match it up with the policy objects stored locally and present the combined data to the end user.
$deviceScriptStatus = @()
foreach ($script in $InTuneScripts) 
    {
    $tmpItem = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Policies\$($owner.id)\$($script.id)" -ErrorAction SilentlyContinue
    if ($tmpItem) {
        $tmpObj = [PSCustomObject]@{
            displayName = $script.displayName
            fileName    = $script.fileName
            Result      = $tmpItem.Result
            id          = $script.id
            psPath      = $tmpItem.PSPath
        }
        $deviceScriptStatus += $tmpObj
        }
  }
