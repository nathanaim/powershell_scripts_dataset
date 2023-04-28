param(
	[string]$Version,
	[string]$Path,
	[switch]$Force,
	[switch]$Update,
	[switch]$Uninstall
)





$Configs = @{
	Url = "http://ola.hallengren.com/scripts/MaintenanceSolution.sql",
	"http://ola.hallengren.com/scripts/DatabaseBackup.sql",
	"http://ola.hallengren.com/scripts/DatabaseIntegrityCheck.sql",
	"http://ola.hallengren.com/scripts/IndexOptimize.sql",
	"http://ola.hallengren.com/scripts/CommandExecute.sql",
	"http://ola.hallengren.com/scripts/CommandLog.sql"
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
                    	
                
                
                

                $_.Downloads = $_.Url | ForEach-Object{
                    Get-File -Url $_ -Path $Config.Path
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