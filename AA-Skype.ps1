$AllUsers = Import-Csv -Path "\\wfspa.local\it\New Users\NewUsersV2.csv" | sort FirstName,Lastname,type,status,uniqueid,vpn,ADusername -unique
$SkypeUsers = $AllUsers | Select FirstName,LastName,Type,status,UniqueID,VPN,ADUsername | where status -eq "skype"


#foreach($NewUser in $SkypeUsers)
#{
#    $UPN = Get-ADUser -Server DATCTR-WFS-DC-2.wfspa.local -Identity $NewUser.ADUsername -Properties * | select DisplayName
#	Enable-CsUser -DomainController DATCTR-WFS-DC-2.wfspa.local -Identity $UPN.DisplayName -RegistrarPool "s4bpool01.wfspa.org" -SipAddressType UserPrincipalName
#}

Foreach($item in $AllUsers){
    If($item.status -eq "skype" ){
        $item.status = "completed"
    }
}

$AllUsers| Export-Csv -Path "\\wfspa.local\it\New Users\NewUsersV2.csv" -NoTypeInformation

#Get-CsServerVersion

#Get-CsUser -Identity S
#Get-CsUser lgriffith | Get-CsClientPinInfo | Set-CsClientPin -Pin 12345
#Disable-CsUser AAddress