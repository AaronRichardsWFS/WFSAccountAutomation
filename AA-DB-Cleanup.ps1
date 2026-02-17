#NewUser-Reset-NewUserCSV-File.ps1
###
#Change log, changes made locally on datctr-exchange
#Chage 1: 9/20/2022
#- Added this change log
#- First Release

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$VerbosePreference = "Continue"
$LogPath = "C:\Scripts\AccountAutomation\Logs\"
Get-ChildItem "$LogPath\*.log" | Where LastWriteTime -LT (Get-Date).AddDays(-15) | Remove-Item -Confirm:$false
$LogPathName = Join-Path -Path $LogPath -ChildPath "$($MyInvocation.MyCommand.Name)-$(Get-Date -Format 'MM-dd-yyyy').log"
Start-Transcript $LogPathName -Append

##############################################
# Importing the SqlServer module
##############################################
Import-Module SqlServer 
Import-Module activeDirectory


$Date = Get-Date
$DateStr = $Date.ToString("MMddyyyyHHmm")
$TargetLocation = "\\wfspa.local\it\New Users\DailyResults\NewUsersV2" + $DateStr + ".csv"


##VARIABLES
$NeedsAccount = 1


# we can now specify the variables required to connect to the local or remote SQL instance/database desired. The “.\InstanceName” connects to a local SQL instance for testing and I’m using the sa account to authenticate:
$SQLInstance = "EpicorHCM.wfspa.local" 
$SQLDatabase = "EpicorHCM"
$connectionString = "Data Source=" + $SQLInstance  + "; Integrated Security=SSPI; Initial Catalog=" + $SQLDatabase+  "; TrustServerCertificate=True " +" "
# $SQLUsers = "USE $SQLDatabase;  SELECT username from usysuser where username like '" + $ADDomain + "%'"


$Rundate = (get-date -Format g).ToString()

$Date = Get-Date

#Load CSV Values into Variable
# $NewUsers = Import-Csv -Path "\\wfspa.local\it\New Users\NewUsers.csv" | sort FirstName,Lastname -Unique
#$OldPath = "\\wfspa.local\it\New Users\NewUsers\DailyResults\" + $Date.AddDays(-1).ToString("MMddyyyy_HHmmss") + ".csv"

# $OldPath = "\\wfspa.local\it\New Users\NewUsers\DailyResults\" + $Date.AddDays(-1).ToString("MM-dd-yyyy_hh-mm-ss-tt") + ".csv"

$AllUsers = @( Import-Csv -Path "\\wfspa.local\it\New Users\NewUsersV2.csv" | sort FirstName,Lastname,type,status,uniqueid,vpn,ADusername -unique )
$CompletedUsers = @( $AllUsers | Select FirstName,LastName,Type,status,uniqueid,vpn,ADusername | where status -eq "completed" )
$RemainingUsers = @( $AllUsers | Select FirstName,LastName,Type,status,uniqueid,vpn,ADusername | where status -ne "completed" )

$CompletedUsers | Foreach-Object { $_.PSObject.Properties | Foreach-Object { $_.Value = $_.Value.Trim() } } 


# write completed users to archive file
if($CompletedUsers.count -gt 0)
{
	$CompletedUsers | Export-Csv -Path $TargetLocation -NoTypeInformation
}

# $SQLUsers = "EXEC WFS_GetNewUsers ${NeedsAccount}"
#$SQLUsers = "EXEC WFS_GetNewUsers_V2 ${NeedsAccount}"
#V5 Pulls interns/temps/residents/contractors from servicenow form to auto create.
$SQLUsers = "EXEC WFS_GetNewUsers_V5 ${NeedsAccount}"
$SQLUsers
$tabHCMUser =  @( invoke-sqlcmd -connectionString  $connectionString  -query $SQLUsers )

if($tabHCMUser.count -gt 0)
{
$test2 = "Users found: " + $tabHCMUser.count + " addeding to file"
$test2

# data from WFS - keeping these fields first
$tabHCMUserMerge = @( $tabHCMUser | select FirstName, Lastname,Type, Status, Uniqueid, VPN, ADusername )
# $tabHCMUser	| select FirstName, Lastname,Type, Status, UniqueID, VPN | Export-Csv "\\wfspa.local\it\New Users\NewUsers.csv" -NoTypeInformation
}
if($RemainingUsers.count -gt 0 -And $tabHCMUserMerge.count -gt 0 )
{
$MergedUsers = @( $RemainingUsers + $tabHCMUserMerge )
}
if($RemainingUsers.count -gt 0 -And $tabHCMUserMerge.count -eq 0 )
{
$MergedUsers = @( $RemainingUsers )
}

if($RemainingUsers.count -eq 0 -And $tabHCMUserMerge.count -gt 0 )
{
$MergedUsers = @( $tabHCMUserMerge )
}



# add consolidated remaining users back to main file
if($MergedUsers.count -eq 0 )
{
Copy-Item "\\wfspa.local\it\New Users\NewUsersV2_Base.csv" -Destination "\\wfspa.local\it\New Users\NewUsersV2.csv"
}
Else
{
$MergedUsers | Export-Csv -Path "\\wfspa.local\it\New Users\NewUsersV2.csv" -NoTypeInformation
}




Stop-Transcript

## EXIT
exit

