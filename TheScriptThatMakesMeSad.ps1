#Smart guy I sgot most of the idea from.
#http://www.stephenthompson.tech/audit-ad-passwords-with-powershell/
#Install-Module -Name DSInternals #As Administrator\
#https://www.powershellgallery.com/packages/DSInternals/2.22
Import-Module DSInternals
 
$DictFile = "C:\temp\pass.txt"
$DC = "Domain Controller"
$Domain = "DC=Something,DC=Clever"
$Dict = Get-Content $DictFile | ConvertTo-NTHashDictionary
 
Get-ADReplAccount -All -Server $DC -NamingContext $Domain | Test-PasswordQuality -WeakPasswordHashes $Dict -ShowPlainTextPasswords -IncludeDisabledAccounts | out-file c:\temp\Password.txt
