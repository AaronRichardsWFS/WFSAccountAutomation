[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$VerbosePreference = "Continue"
$LogPath = "C:\Scripts\AccountAutomation\Logs\"
Get-ChildItem "$LogPath\*.log" | Where LastWriteTime -LT (Get-Date).AddDays(-15) | Remove-Item -Confirm:$false
$LogPathName = Join-Path -Path $LogPath -ChildPath "$($MyInvocation.MyCommand.Name)-$(Get-Date -Format 'MM-dd-yyyy').log"
Start-Transcript $LogPathName -Append


##############################################
# HCMtoADUsers.ps1 on datctr-wfs-dc-1
# Checking to see if the SqlServer module is already installed, if not installing it
##############################################
$SQLModuleCheck = Get-Module -ListAvailable SqlServer
if ($SQLModuleCheck -eq $null)
{
write-host "SqlServer Module Not Found - Installing"
# Not installed, trusting PS Gallery to remove prompt on install
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
# Installing module, requires run as admin for -scope AllUsers, change to CurrentUser if not possible
Install-Module -Name SqlServer –Scope AllUsers -Confirm:$false -AllowClobber
}
##############################################
# Importing the SqlServer module
##############################################
Import-Module SqlServer 
Import-Module activeDirectory




##VARIABLES
$ADDomain = "wfspa"


# we can now specify the variables required to connect to the local or remote SQL instance/database desired. The “.\InstanceName” connects to a local SQL instance for testing and I’m using the sa account to authenticate:
$SQLInstance = "EpicorHCM.wfspa.local" 
$SQLDatabase = "EpicorHCM"
$connectionString = "Data Source=" + $SQLInstance  + "; Integrated Security=SSPI; Initial Catalog=" + $SQLDatabase+  "; TrustServerCertificate=True " +" "


# $SQLUsers = "USE $SQLDatabase;  SELECT username from usysuser where username like '" + $ADDomain + "%'"


$Rundate = (get-date -Format g).ToString()


## FUNCTIONS

function GetLocationName
{
param ( [string] $locCode )

$locName =""
$locName = $locCode
switch ( $locCode )
{
'ADAM' {$locName = "CLA Adam"}
'ALPHA' {$locName = "RIDC Admin"}
'AUTEAST' {$locName = "Monroeville"}
'AUTNORTH' {$locName = "Wexford"}
'AUTSOUTH' {$locName = "Bridgeville"}
'BETA' {$locName = "RIDC Beta"}
'BRACKENRID' {$locName = "CLA Brackenridge"}
'CALLO' {$locName = "Callowhill"}
'CAMPBELLS' {$locName = "CLA Campbells"}
'CCP' {$locName = "CCP New Kensington"} #Site no longer exists
'CHARLES' {$locName = "CLA Charles"}
'CHERRY' {$locName = "CLA Cherry"}
'CORBET' {$locName = "CIC Corbet"}
'CRAIG' {$locName = "CLA Craig"}
'DALLAS' {$locName = "CLA Dallas"}
'EAST FIFTH' {$locName = "DAS Tarentum East 4th"}
'FAIRWEATHER' {$locName = "Fairweather Lodge"} #Site no longer exists
'FREEPORT' {$locName = "CLA Freeport"}
'HALLCT' {$locName = "Hall Cort"}
'HICKEY' {$locName = "Hickey"}
'HICKORY' {$locName = "CLA Hickory"}
'HIGHLAND' {$locName = "Caste School"}
'HUFF' {$locName = "Greensburg Huff"}
'HYDE PARK' {$locName = "CLA Hyde Park"}
'JOHNSTON' {$locName = "Johnston School"}
'LEECHBUR' {$locName = "Adult DAS"}
'LEECHBURG' {$locName = "DAS Leechburg"}
'LIN' {$locName = "CLA Linda"}
'linda' {$locName = "CLA Linda"}
'LOCKSLEY' {$locName = "Locksley"}
'NEW HAMPSH' {$locName = "CLA New Hampshire"}
'OLDWILLIA' {$locName = "Monroeville"}
'PAIGE' {$locName = "CLA Paige"}
'PAHEIGHTS' {$locName = "CLA PA Heights"}
'PENN' {$locName = "Wilkinsburg Penn"}
'PENHURST' {$locName = "CLA Penhurst"}
'PENNSYLVAN' {$locName = "CLA Pennsylvania"}
'PIONE' {$locName = "Pioneer"}
'PLYMOUTH' {$locName = "Greensburg Plymouth"}
'REGENCY' {$locName = "CLA Regency"}
'RIVERVIEW' {$locName = "CLA Riverview"}
'S WATER' {$locName = "Kitanning South Water"} #Site no longer exists
'STACY' {$locName = "CLA Stacy"}
'STOTLER' {$locName = "CLA Stotler"}
'SNEGLEY' {$locName = "South Negley"}
'UPARC' {$locName = "U-PARC Building A-3"} #Site no longer exists
'WASH' {$locName = "Washington"}
'WEST' {$locName = "Greensburg Plymouth"}
'WEX' {$locName = "Wexford"}
'WID' {$locName = "CLA Widmer"}
'WILLIAMS' {$locName = "CLA Williams"}
'WONDERLY' {$locName = "CLA Wonderly"}
'WOOD' {$locName = "Wood Street"}
'WOODBERRY' {$locName = "CLA Woodberry"}




}
    
    return  [string]$locName 
}


##
## MAIn
##


     
 

<##
userlogon           : zanandreal
OrganizationUnit    : Behavioral Health
Department          : Drop-In Westmoreland County
Location            : CCP
LocationCode
BusinessCardtitle   : Peer Support Worker
Supervisorlogon     : tortd
departmentcode      : 6645
division            : Legacy Family Services
divisioncode
HireDate            : 03/30/2015
CostCenterCode      : 6645
LastName            : Zanandrea
Firstname           : Linda
PositionTitle
DirectReports
CompanyRelationship : Staff
Status              : Active
TermDate            :
##>


$SQLUsers = "EXEC GetADuserinfo_AutoTerm '${ADDomain}'"
$tabHCMUser =  invoke-sqlcmd -connectionString  $connectionString  -query $SQLUsers 
## $tabHCMUser
## $tabHCMUser.count


## Set-aduser -identity $user.samaccountname -Title $user.title -Company $user.Company -Department $user.Department  -Office $user.physicalDeliveryOfficeName -manager $user.manager

Foreach ( $wfsUser in  $tabHCMUser) 

{
    Set-aduser -identity $wfsuser.Userlogon -Title $wfsUser.BusinessCardtitle  -Department $wfsuser.Department 
IF ( $wfsuser.OrganizationUnit -ne '0' -and  $wfsuser.OrganizationUnit -ne '' ) {	
	Set-aduser -identity $wfsuser.Userlogon -Company $wfsuser.OrganizationUnit
	}
	
    
    $LocationName = $wfsuser.Location
    $LocationName = GetLocationName -LocCode $wfsuser.LocationCode 
#write-output $LocationName

    Set-aduser -identity $wfsuser.Userlogon -Office  $LocationName

    $sllen =   $wfsuser.Supervisorlogon.length -1
      


    if ( $sllen -gt 0 ) {  Set-aduser -identity $wfsuser.Userlogon  -manager $wfsuser.Supervisorlogon }

    ## extensioattribute extensionAttribute1, -add @{"extensionattribute1"="MyString"
#write-output $wfsuser.locationcode

    Set-aduser -identity $wfsuser.Userlogon -employeeId $wfsuser.employeeid     

    Set-aduser -identity $wfsuser.Userlogon -replace @{"extensionattribute1"=$wfsuser.LocationCode}        
    Set-aduser -identity $wfsuser.Userlogon -replace @{"extensionattribute2"=$wfsuser.departmentcode}
    Set-aduser -identity $wfsuser.Userlogon -replace @{"extensionattribute3"=$wfsuser.CostCenterCode}
    Set-aduser -identity $wfsuser.Userlogon -replace @{"extensionattribute4"=$wfsuser.HireDate}
	
               

     IF ( $wfsuser.badgeid -ne '0' -and  $wfsuser.badgeid -ne '' )
		{
		
		Set-aduser -identity $wfsuser.Userlogon -replace @{"pager"=$wfsuser.badgeid}
		
		}


                IF ( $wfsuser.PositionTitle -ne '0' -and  $wfsuser.PositionTitle -ne '' )
    { Set-aduser -identity $wfsuser.Userlogon -replace @{"extensionattribute5"=$wfsuser.PositionTitle} }



                
    IF ( $wfsuser.Directreports -ne '0' -and  $wfsuser.Directreports -ne '' )
    { Set-aduser -identity $wfsuser.Userlogon -replace @{"extensionattribute6"='SV' } }
                ELSE { Set-aduser -identity $wfsuser.Userlogon -clear "extensionattribute6" }

                
#             IF ( $wfsuser.Directreports -eq '0' -or  $wfsuser.Directreports -eq '' )
#    { Set-aduser -identity $wfsuser.Userlogon -replace @{"extensionattribute6"='' } }

IF ( $wfsuser.DivisionCode -ne '0' -and  $wfsuser.DivisionCode -ne '' ) {
    Set-aduser -identity $wfsuser.Userlogon -replace @{"extensionattribute7"=$wfsuser.DivisionCode}
	}
	
    Set-aduser -identity $wfsuser.Userlogon -replace @{"extensionattribute8"=$wfsuser.CompanyRelationship}
    
Set-aduser -identity $wfsuser.Userlogon -replace @{"extensionattribute9"=$wfsuser.Status}

IF ( $wfsuser.TermDate -ne '0' -and  $wfsuser.TermDate -ne '' ) {
Set-aduser -identity $wfsuser.Userlogon -replace @{"extensionattribute10"=$wfsuser.TermDate}
}

  Set-aduser -identity $wfsuser.Userlogon -replace @{"extensionattribute15"=$RunDate}
  
  Set-aduser -identity $wfsuser.Userlogon -replace @{"EmployeeNumber"=$wfsuser.PersonGuid}
  
}

Stop-Transcript

## EXIT
exit
