import-module activedirectory
#$file = "SG_list.txt"
$Sharelist =@("SHARE$","users$","banana") #each share name, comma seperated
$computer = "SERVER" #file server name

foreach($share in $Sharelist)
{
write-host $share
$permissions = Get-SharePermissions($share)
write-host $permissions

}


Function Get-SharePermissions($ShareName){
    $Share = Get-WmiObject win32_LogicalShareSecuritySetting -Filter "name='$ShareName'"
    if($Share){
        $obj = @()
        $ACLS = $Share.GetSecurityDescriptor().Descriptor.DACL
        foreach($ACL in $ACLS){
            $User = $ACL.Trustee.Name
            if(!($user)){$user = $ACL.Trustee.SID}
            $Domain = $ACL.Trustee.Domain
            switch($ACL.AccessMask)
            {
                2032127 {$Perm = "Full Control"}
                1245631 {$Perm = "Change"}
                1179817 {$Perm = "Read"}
            }
            $obj = $obj + "$Domain\$user  $Perm"
        }
    }
    if(!($Share)){$obj = " ERROR: cannot enumerate share permissions. "}
    Return $obj
} # End Get-SharePermissions Function

Function Get-NTFSOwner($Path){
    $ACL = Get-Acl -Path $Path
    $a = $ACL.Owner.ToString()
    Return $a
} # End Get-NTFSOwner Function

Function Get-NTFSPerms($Path){
    $ACL = Get-Acl -Path $Path
    $obj = @()
    foreach($a in $ACL.Access){
        $aA = $a.FileSystemRights
        $aB = $a.AccessControlType
        $aC = $a.IdentityReference
        $aD = $a.IsInherited
        $aE = $a.InheritanceFlags
        $aF = $a.PropagationFlags
        $obj = $obj + "$aC | $aB | $aA | $aD | $aE | $aF <br>"
    }
    Return $obj
} # End Get-NTFSPerms Function

