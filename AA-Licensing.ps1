
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$VerbosePreference = "Continue"
$LogPath = "C:\Scripts\AccountAutomation\Logs\"
Get-ChildItem "$LogPath\*.log" | Where LastWriteTime -LT (Get-Date).AddDays(-15) | Remove-Item -Confirm:$false
$LogPathName = Join-Path -Path $LogPath -ChildPath "$($MyInvocation.MyCommand.Name)-$(Get-Date -Format 'MM-dd-yyyy').log"
Start-Transcript $LogPathName -Append


#$SSCriptsUsername = "SSCripts@wfspa.org"
#$SSCriptsPass = Get-Content "C:\Scripts\SScriptsPWD.txt" | ConvertTo-SecureString
#$SScriptsCredentials = New-Object  System.Management.Automation.PSCredential ($SSCriptsUsername, $SSCriptsPass )
#Connect-MsolService -Credential $SScriptsCredentials



# $NewUsers = gc -Path "\\wfspa.local\it\New Users\NewUsersFinal.txt"
$AllUsers = Import-Csv -Path "\\wfspa.local\it\New Users\NewUsersV2.csv" | sort FirstName,Lastname,type,status,uniqueid,vpn,ADusername -unique
$ADLicensceUsers = $AllUsers | Select FirstName,Lastname,type,status,uniqueid,vpn,ADusername | where status -eq "licensing"
$group = 'CN=E3.License,OU=WFS.Groups,DC=wfspa,DC=local'





Foreach($item in $AllUsers){
    If($item.status -eq "licensing" ){
        Write-Host 'User: '$item.ADUsername
		Write-Host 'Adding group: '$Group
	    Add-ADPrincipalGroupMembership -Confirm:$false -Identity $item.ADUsername  -MemberOf $Group -Server datctr-wfs-dc-2.wfspa.local  -ErrorAction Stop
		
#Disabled Skype Status
#		$item.status = "skype"
		$item.status = "completed"
    }
}

$AllUsers | Export-Csv -Path "\\wfspa.local\it\New Users\NewUsersV2.csv" -NoTypeInformation





Stop-Transcript