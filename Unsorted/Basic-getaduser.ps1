#it might be helpful for you to see the last time a password was changed and when an account logged in.  Every user in AD has read access, so you should be able to see it
 
import-module ActiveDirectory
get-aduser Bob.McBob -Properties *| select name,passwordlastset,@{n='LastLogon';e={[DateTime]::FromFileTime($_.LastLogon)}}
 
replacing Bob.McBob with whomever's username you need.
