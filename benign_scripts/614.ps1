param(
	[string]$Version,
	[string]$Path,
	[switch]$Force,
	[switch]$Update,
	[switch]$Uninstall
)





$Configs = @{
	Url = "https://chocolatey.org/install.ps1"
	ConditionExclusion = "Get-Command `"cinst`" -ErrorAction SilentlyContinue"
}

$Configs | ForEach-Object{

    try{

        $_.Result = $null
        if(-not $_.Path){$_.Path = $Path}
        $Config = $_

        
        
        

        if(-not $Uninstall){

            
            
            

            if($_.ConditionExclusion){            
                $_.ConditionExclusionResult = $(Invoke-Expression $Config.ConditionExclusion -ErrorAction SilentlyContinue)        
            }    
            if(($_.ConditionExclusionResult -eq $null) -or $Force){
                    	
                
                
                

                
                
                

                $_.Url | ForEach-Object{
                    Invoke-Expression (new-object Net.WebClient).DownloadString($_)
                }
                		
                
                
                
                
                
                
                
				
                
                
                
                		
                if($Update){$_.Result = "AppUpdated";$_
                }else{$_.Result = "AppInstalled";$_}
            		
            
            
            
            		
            }else{
            	
                $_.Result = "ConditionExclusion";$_
            }

        
        
        
        	
        }else{
            
            $_.Result = "AppUninstalled";$_
        }

    
    
    

    }catch{

        $Config.Result = "Error";$Config
    }
}