#New-UsersWFSPA-NEW.ps1
#The below commands allow you to load the Exchange Powershell modules
#if (!(Test-Path -Path $PROFILE ))
#{ New-Item -Type File -Path $PROFILE -Force }
#The above commands allow you to load the Exchange Powershell modules

#psEdit $profile

#These commands are used to create a new remote powershell session for the scheduled task. 
#Read-Host -Prompt "Enter your password" -AsSecureString | ConvertFrom-SecureString | Out-File "C:\Windows\temp\SScriptPass.txt"

###
#Change log, changes made locally on datctr-exchange
#Chage 1: 4/8/2020
#- Added this change log
#- Included a check to see if a duplicate username exists in the ForTheKids domain. This is necessary due to the bridge not allowing duplicate usernames. 
#- Commented out/deleted a random line which i think i used on troubleshooting (was on line 43)
#
#Change 2: 4/14/2020
#- Created the $LastNameNOSC variable to remove any non-alphabetic character from the persons last name. 
#- ...All future usernames will be alphabetic only. 
#- https://devblogs.microsoft.com/scripting/weekend-scripter-remove-non-alphabetic-characters-from-string/
###
#
#Change 3: 2/5/2021
#- Updated the Contractors portion of the script to a different OU. 
###
#
#Change 4: 7/20/2022 - AHR
#- Added a white space strip from csv file
###
#
#Change 4: 8/9/2022 - AHR
#- Added 90 experation on New User accounts
#- removed change password on next log as this is set by the onboarding script
###
#
#Change 5: 9/2/2022 - AHR
#- Added Sort on CSV Import to be able to select Unique Names (Prevents duplicate accounts when name was copied and pasted multiple times.)
###
#
#Change 5: 11/10/2022 - AHR
#- Added file exsist check on NewUsersFile.txt file to remove errors when no records processed
###
#
#Change 5: 11/14/2022 - AHR
#- Updated all AD calls to -Server datctr-wfs-dc-2.wfspa.local

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$VerbosePreference = "Continue"
$LogPath = "C:\Scripts\AccountAutomation\Logs\"
Get-ChildItem "$LogPath\*.log" | Where LastWriteTime -LT (Get-Date).AddDays(-15) | Remove-Item -Confirm:$false
$LogPathName = Join-Path -Path $LogPath -ChildPath "$($MyInvocation.MyCommand.Name)-$(Get-Date -Format 'MM-dd-yyyy').log"
Start-Transcript $LogPathName -Append



$SSCriptsUsername = "SSCripts@wfspa.org"
#$SSCriptsPass = Get-Content "C:\ScheduledScripts\SScriptPass.txt" | ConvertTo-SecureString
$SSCriptsPass = Get-Content "C:\Scripts\SScriptsPWD.txt" | ConvertTo-SecureString
$SScriptsCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SSCriptsUsername, $SSCriptsPass
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://datctr-exchange.wfspa.local/PowerShell -Authentication Kerberos -Credential $SScriptsCredentials
Import-PSSession $Session -DisableNameChecking -AllowClobber

#not sure if i need this
Import-Module activedirectory
$Date = Get-Date
#$OldPath = "\\wfspa.local\it\New Users\DailyResults\NewUsersFinal" + $Date.AddDays(-1).ToString("MMddyyyy") + ".txt"

#if ((Test-Path -Path "\\wfspa.local\it\New Users\NewUsersFinal.txt" -PathType Leaf)) {
#Rename-Item -Path "\\wfspa.local\it\New Users\NewUsersFinal.txt" -NewName $OldPath
# }



#Load CSV Values into Variable
#NewUsers = Import-Csv -Path "\\wfspa.local\it\New Users\NewUsers.csv" | sort FirstName,Lastname,type,status -unique
$AllUsers = Import-Csv -Path "\\wfspa.local\it\New Users\NewUsersV2.csv" | sort FirstName,Lastname,type,status,uniqueid,vpn,ADusername -unique
$NewUsers = $AllUsers | Select FirstName,LastName,Type,status,uniqueid,vpn,ADusername | where status -eq "New"



# Remove white space in CSV file
$NewUsers | Foreach-Object {
    $_.PSObject.Properties | Foreach-Object { $_.Value = $_.Value.Trim() }
}


#This portion of the script checks the file to see if there was a change within the last day. 
#$NewUsersFileDetails = Get-Item -Path "\\wfspa.local\it\New Users\NewUsers.csv"
##$OneDayAgo = (Get-Date).AddDays(-1)

#if($NewUsersFileDetails.LastWriteTime -ge $OneDayAgo)
    foreach($NewUser in $NewUsers)
    {
        $FirstName = $NewUser.FirstName
        $LastName = $NewUser.LastName
        $Letters = '[^a-zA-Z]'
        $LastNameNOSC = $LastName -replace $Letters, ''
        $DisplayName = $LastName + ", " + $FirstName
        $UserType = $NewUser.Type
        #$Domain = $NewUser.Domain
        $FirstPassword = "Wesley08"
        $Username = $FirstName.Substring(0,1) + $LastNameNOSC

        if($UserType -eq "Intern")
        {
            $OU = "OU=Interns,OU=New.Users,OU=WFS.Users,DC=wfspa,DC=local"
        }
        elseif($UserType -eq "Contractor")
        {
            $OU = "OU=Contractors,OU=New.Users,OU=WFS.Users,DC=wfspa,DC=local"
        }
		elseif($UserType -eq "Resident")
        {
            $OU = "OU=Contractors,OU=New.Users,OU=WFS.Users,DC=wfspa,DC=local"
        }
		elseif($UserType -eq "Temp")
        {
            $OU = "OU=Contractors,OU=New.Users,OU=WFS.Users,DC=wfspa,DC=local"
        }
		elseif($UserType -eq "Board")
        {
            $OU = "OU=New.Users,OU=WFS.Users,DC=wfspa,DC=local"
        }									  
        else 
        {
            $OU = "OU=New.Users,OU=WFS.Users,DC=wfspa,DC=local"
        }

        $UNExists = Get-ADUser -Server datctr-wfs-dc-2.wfspa.local -LDAPFilter "(SAMAccountName=$Username)"
        #Check if the username exists in ForTheKids domain
        $UNExistsFTK = Get-ADUser -Server "datctr-ftk-dc-1.forthekids.local" -LDAPFilter "(SAMAccountName=$Username)"
        $Counter = 2
        
        if(($UNExists -ne $null) -or ($UNExistsFTK -ne $null))
        {
            $ExistingUser = Get-ADUser -Server datctr-wfs-dc-2.wfspa.local -Identity $Username -Properties * | select givenname,surname,distinguishedname
            Write-Output $ExistingUser
            if(($ExistingUser.givenname -eq $FirstName) -and ($ExistingUser.surname -eq $LastName) -and ($ExistingUser.distinguishedname -like '*Disabled*'))
            {
                #Write-Output "Made it to line 43" #i think this was a test that i can delete
                Send-MailMessage -SmtpServer datctr-exchange.wfspa.local -From NewUserCreation@wfspa.org -To wfsnetadmin@wfspa.org, Ted.Lewczyk@wfspa.org, WFSITAccountAutomation@wfspa.org -Subject "Possible Existing User Was Created" -Body "$ExistingUser"
                #Send-MailMessage -SmtpServer datctr-exchange.wfspa.local -From NewUserCreation@wfspa.org -To richardsa@wfspa.org -Subject "Possible Existing User Was Created" -Body "$ExistingUser"
				$Username = "AlreadyExists"
            }
        }

        while ((($UNExists -ne $null) -or ($UNExistsFTK -ne $null)) -and ($Username -ne "AlreadyExists"))
        {
            $Output = "The username " + $Username + " already exists. Trying to create username with the second initial of their first name included in the username. `n"
            Send-MailMessage -SmtpServer datctr-exchange.wfspa.local -From NewUserCreation@wfspa.org -To wfsnetadmin@wfspa.org, Ted.Lewczyk@wfspa.org, WFSITAccountAutomation@wfspa.org -Subject "Possible Existing User Was Created" -Body "$Output"
            #Send-MailMessage -SmtpServer datctr-exchange.wfspa.local -From NewUserCreation@wfspa.org -To richardsa@wfspa.org -Subject "Possible Existing User Was Created" -Body "$Output"
			$Output | Out-File -FilePath C:\Windows\Temp\Output.txt -Append -NoClobber
            $Username = $FirstName.Substring(0,$Counter) + $LastNameNOSC
            $UNExists = Get-ADUser -Server datctr-wfs-dc-2.wfspa.local -LDAPFilter "(SAMAccountName=$Username)"
            $UNExistsFTK = Get-ADUser -Server "datctr-ftk-dc-1.forthekids.local" -LDAPFilter "(SAMAccountName=$Username)"
            $Counter = $Counter + 1

            if($Counter -eq "10")
            {
                Send-MailMessage -SmtpServer datctr-exchange.wfspa.local -From NewUserCreation@wfspa.org -To wfsnetadmin@wfspa.org, Ted.Lewczyk@wfspa.org, WFSITAccountAutomation@wfspa.org -Subject "Loop Occurred in New User Script" -Body $Output
				#Send-MailMessage -SmtpServer datctr-exchange.wfspa.local -From NewUserCreation@wfspa.org -To richardsa@wfspa.org -Subject "Loop Occurred in New User Script" -Body $Output
                exit
            }
        }

        if($Username -ne "AlreadyExists")
        {
        $UserLogonName = $Username + "@wfspa.org" #userlogonname is either @wesleyspectrum.org (for forthekids) or @wfspa.org (for wfspa)
        New-RemoteMailbox -Name $DisplayName -FirstName $FirstName -LastName $LastName -OnPremisesOrganizationalUnit $OU -UserPrincipalName $UserLogonName -Password (ConvertTo-SecureString -String $FirstPassword -AsPlainText -Force) #-ResetPasswordOnNextLogon $True #| Out-File -Append C:\Windows\Temp\NewEmailResult.txt
        #$FullUserName = $Domain + "\" + $Username
        #$FullUserName | Out-File -FilePath "\\wfspa.local\users\nconroy\NewUsersFinal.txt" -Append
        #Changed to the below
        #$Username | Out-File -FilePath "\\wfspa.local\it\New Users\NewUsersFinal.txt" -Append

        #This portion of the script will create a new U: drive for this user. 

        Start-Sleep -Seconds 30

		# 1/22/2024 - ahr - Start - No longer are creating home drives now using onedrive
        #$HomeDir = "\\wfspa.local\users\" + $Username
        #Set-ADUser -Server datctr-wfs-dc-2.wfspa.local -Identity $Username -HomeDirectory $HomeDir -HomeDrive U
        #New-Item -Path $HomeDir -ItemType Directory -Force
        #$HomeFolderACL = Get-Acl $HomeDir
        #$IdentityReference =  "wfspa\" + $Username
        #$FileSystemAccessRights = [System.Security.AccessControl.FileSystemRights]"Modify"
        #$InheritanceFlags=[System.Security.AccessControl.InheritanceFlags]”ContainerInherit, ObjectInherit”
        #$PropagationFlags=[System.Security.AccessControl.PropagationFlags]”None”
        #$AccessControl=[System.Security.AccessControl.AccessControlType]”Allow”
        #$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($IdentityReference,$FileSystemAccessRights, $InheritanceFlags, $PropagationFlags,$AccessControl)
        #$HomeFolderACL.AddAccessRule($AccessRule)
        #Set-Acl -Path $HomeDir -AclObject $HomeFolderACL
		# 1/22/2024 - ahr - End - No longer are creating home drives now using onedrive
        $NewUser.ADUsername = $Username
       
        }
    


        #This part of the script will set intern (120 days) and New Staff (90 Days) accounts to expire xx days after creation (Staff account experation will be cleared by Enable script on hire day - This allows us to clean up non-starting users)
		# Also set require password for intern and contractors but not staff
        if($UserType -eq "Intern")
        {
            Set-ADAccountExpiration -Server datctr-wfs-dc-2.wfspa.local -Identity $Username -TimeSpan "120"
			Start-Sleep 10
			Set-ADUser -Server datctr-wfs-dc-2.wfspa.local -Identity $Username -ChangePasswordAtLogon:$true
		}
        elseif($UserType -eq "Contractor")
        {
            Set-ADAccountExpiration -Server datctr-wfs-dc-2.wfspa.local -Identity $Username -TimeSpan "120"
			Start-Sleep 10
			Set-ADUser -Server datctr-wfs-dc-2.wfspa.local -Identity $Username -ChangePasswordAtLogon:$true
        }		
        elseif($UserType -eq "Temp")
        {
            Set-ADAccountExpiration -Server datctr-wfs-dc-2.wfspa.local -Identity $Username -TimeSpan "120"
			Start-Sleep 10
			Set-ADUser -Server datctr-wfs-dc-2.wfspa.local -Identity $Username -ChangePasswordAtLogon:$true
        }				
		elseif($UserType -eq "Board")
		{
            $BoardDescription = "Board Member"
			Start-Sleep 10
			Set-ADUser -Server datctr-wfs-dc-2.wfspa.local -Identity $Username -Description $BoardDescription
        }								   
		elseif($UserType -eq "Resident")
		{
            $ResidentDescription = "Resident:"
			Set-ADAccountExpiration -Server datctr-wfs-dc-2.wfspa.local -Identity $Username -TimeSpan "120"
			Start-Sleep 10
			Set-ADUser -Server datctr-wfs-dc-2.wfspa.local -Identity $Username -ChangePasswordAtLogon:$true
			Set-ADUser -Server datctr-wfs-dc-2.wfspa.local -Identity $Username -Description $ResidentDescription
        }		
        else 
        {
            Set-ADAccountExpiration -Server datctr-wfs-dc-2.wfspa.local -Identity $Username -TimeSpan "90"
        }
        Set-aduser -Server datctr-wfs-dc-2.wfspa.local -identity $Username -replace @{"EmployeeNumber"=$NewUser.uniqueid}
		
		
		Foreach($Person in $AllUsers){
        If($Person.uniqueid -eq $NewUser.uniqueid ){
            $Person.ADusername = $Username
        }
    }
		
		
		
		
    }

#Place a local copy of NewUserDetails on the Skype server
#if ((Test-Path -Path "\\wfspa.local\it\New Users\NewUsersFinal.txt" -PathType Leaf)) {
#robocopy "\\wfspa.local\it\New Users" "\\datctr-s4b-fe1.wfspa.local\c$\ScheduledScripts" NewUsersFinal.txt
# }

Foreach($item in $AllUsers){
        If($item.status -eq "new" ){
            $item.status = "licensing"
        }
    }

$AllUsers| Export-Csv -Path "\\wfspa.local\it\New Users\NewUsersV2.csv" -NoTypeInformation

Remove-PSSession $Session

Stop-Transcript