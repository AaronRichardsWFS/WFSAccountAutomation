[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$VerbosePreference = "Continue"
$LogPath = "C:\Scripts\AccountAutomation\Logs\"
Get-ChildItem "$LogPath\*.log" | Where LastWriteTime -LT (Get-Date).AddDays(-15) | Remove-Item -Confirm:$false
$LogPathName = Join-Path -Path $LogPath -ChildPath "$($MyInvocation.MyCommand.Name)-$(Get-Date -Format 'MM-dd-yyyy').log"
Start-Transcript $LogPathName -Append



# $NewUsers = gc -Path "\\wfspa.local\it\New Users\NewUsersFinal.txt"
$AllUsers = Import-Csv -Path "\\wfspa.local\it\New Users\NewUsersV2.csv" | sort FirstName,LastName,Type,status,UniqueID,VPN,ADUsername -unique
$CompletedUsers = $AllUsers | Select FirstName,LastName,Type,status,UniqueID,VPN,ADUsername | where status -eq "completed"
$NotCompletedUsers = $AllUsers | Select FirstName,LastName,Type,status,UniqueID,VPN,ADUsername | where status -ne "completed"


$Date = Get-Date
$DateStr = $Date.ToString("MMddyyyyHHmm")
$TargetLocation = "\\wfspa.local\it\New Users\DailyResults\NewUserDetails" + $DateStr + ".txt"
$TargetLocationAch = "\\wfspa.local\it\New Users\DailyResults\NewUsersV2" + $DateStr + ".csv"

$NewUsersFinalFileDetails = Get-Item -Path "\\wfspa.local\it\New Users\NewUsersFinal.txt"
$OneDayAgo = (Get-Date).AddDays(-1)

foreach($NewUser in $CompletedUsers)
{
    $NewUserDetails = Get-ADUser -Server DATCTR-WFS-DC-2.wfspa.local -Identity $NewUser.ADUsername -Properties * | select DisplayName, samaccountname, canonicalName, emailAddress, homedrive, homedirectory, userprincipalname
    $DetailsWFSPA =     $DetailsFTK = "`nCreated user in WFSPA ECP. Assigned O365 license. Created Skype account. Created and mapped U drive. `n"
    $DetailsFTK | Out-File $TargetLocation -Append
    $NewUserDetails | Out-File $TargetLocation -Append
}
    Send-MailMessage -SmtpServer datctr-exchange.wfspa.local -From NewUserCreation@wfspa.org -To wfsnetadmin@wfspa.org, Ted.Lewczyk@wfspa.org, richardsa@wfspa.org -Subject "New User Details for $Date" -Body "See attachment" -Attachments $TargetLocation
    if($NewUser.VPN = $true) {
        #Add-ADPrincipalGroupMembership -Confirm:$false -Identity $NewUser.ADUsername  -MemberOf 'CN=Fortitoken.Users,OU=WFS.Users,DC=wfspa,DC=local' -Server datctr-wfs-dc-2.wfspa.local  -ErrorAction Stop
    }


$NotCompletedUsers | Export-Csv -Path "\\wfspa.local\it\New Users\NewUsersV2.csv" -NoTypeInformation


if($CompletedUsers.count -gt 0)
{
	$CompletedUsers | Export-Csv -Path $TargetLocationAch -NoTypeInformation
}




Stop-Transcript

$body2 = Get-Content -Path $LogPathName | Out-String 
Send-MailMessage -SmtpServer datctr-exchange.wfspa.local -From WFSITAccountAutomation@wfspa.org -To richardsa@wfspa.org -Subject "New Users - New User Details" -Body $	