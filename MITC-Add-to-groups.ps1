##############################################
# Importing the SqlServer module
##############################################
Import-Module SqlServer 
Import-Module activeDirectory

# we can now specify the variables required to connect to the local or remote SQL instance/database desired. The “.\InstanceName” connects to a local SQL instance for testing and I’m using the sa account to authenticate:
$SQLInstance = "EpicorHCM.wfspa.local" 
$SQLDatabase = "EpicorHCM"
$connectionString = "Data Source=" + $SQLInstance  + "; Integrated Security=SSPI; Initial Catalog=" + $SQLDatabase+  "; TrustServerCertificate=True " +" "

$SQLCMD = "exec WFS_GetMITCUsers;"
$EpicorUsers =  invoke-sqlcmd -connectionString  $connectionString  -query $SQLCMD
$ALLDSPS = @( Get-ADUser -Filter 'Title -like "Direct Support Prof*Residential*" -and Enabled -eq "True"' -SearchBase "OU=Service Lines, OU=WFS.Users, DC=wfspa, DC=local" -Properties * | select SamAccountName, AccountExpirationDate, mail, manager, distinguishedname, Description, Enabled, office, department, displayname, extensionAttribute10, Title, UserPrincipalName)
$ALLCNAS = @( Get-ADUser -Filter 'Title -like "Direct Support Prof*CNA*" -and Enabled -eq "True"' -SearchBase "OU=Service Lines, OU=WFS.Users, DC=wfspa, DC=local" -Properties * | select SamAccountName, AccountExpirationDate, mail, manager, distinguishedname, Description, Enabled, office, department, displayname, extensionAttribute10, Title, UserPrincipalName)
$group = 'CN=MITC_Users,OU=WFS.Groups,DC=wfspa,DC=local'

foreach($User in $EpicorUsers)
{

$userismember = Get-ADGroupMember -Identity $group | Where-Object {$_.SamAccountName -eq $User.SamAccountName}  
if($userismember){  
    #Write-Host $User.DisplayName '-' $User.UserPrincipalName '('$User.title') is already a member of: ' $Group
}  
else{  
    Write-Host $User.DisplayName '-' $User.UserPrincipalName '('$User.title') is not a member of: ' $Group
    Write-Host 'Adding group: '$Group
	Add-ADPrincipalGroupMembership -Confirm:$false -Identity $User.SamAccountName  -MemberOf $Group -Server datctr-wfs-dc-2.wfspa.local  -ErrorAction Stop
}  
}


