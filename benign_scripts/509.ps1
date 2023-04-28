function Add-DomainUserToLocalGroup{


	
	param(
		[Parameter(Mandatory=$true)]
		[String]
		$Domain,
		
		[Parameter(Mandatory=$true)]
		[String]
		$User,
		
		[Parameter(Mandatory=$true)]
		[String]
		$Group,
		
		[Parameter(Mandatory=$true)]
		[String]
		$Computer,
       
		[Parameter(Mandatory=$false)]
		$Credentials    
        
	)

	$Metadata = @{
		Title = "Add Domain User To Local Group"
		Filename = "Add-DomainUserToLocalGroup.ps1"
		Description = ""
		Tags = "powershell, function, activedirectory"
		Project = ""
		Author = "Janik von Rotz"
		AuthorContact = "www.janikvonrotz.ch"
		CreateDate = "2013-06-04"
		LastEditDate = "2013-06-04"
		Version = "1.0.0"
		License = @'
This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/3.0/ or
send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
'@
}

	
	
	
	
    $ScriptBlock = {
        $LocalGroup = [ADSI]"WinNT://$Computer/$Group,group"    	
    	$DomainUser = [ADSI]"WinNT://$Domain/$User,user"        	
    	Write-Host "Adding domain user: $User from: $Domain to local group: $Group on computer: $Computer"        	
    	$LocalGroup.Add($DomainUser.Path)    
    }
    
    if($Credentials){
    
        Invoke-Command -Computer $Computer -Credential $Credentials -ScriptBlock $Scriptblock

    
    }else{
    
        Invoke-Command -$Computer -ScriptBlock $Scriptblock -Credential (Get-Credential)
    
     }
}