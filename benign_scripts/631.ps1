param(
	[string]$Version,
	[string]$Path,
	[switch]$Force,
	$Update,
	[switch]$Uninstall
)





$Configs = @{
	Url = "https://bitbucket.org/splatteredbits/carbon/downloads/Carbon-1.7.0.zip"
	Path = "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)\"
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
                    Get-File -Url $_ -Path (Join-Path $Config.Path "Carbon.zip")
                }       			

                
                
                

                $ModulePath = (Join-Path $env:PSModulePath.Split(";")[0] "Carbon")
                
                if(Test-Path $ModulePath){
                    Remove-Item $ModulePath -Force -Recurse
                }
                
                New-Item -Path $ModulePath -ItemType Directory
                
                $_.Downloads | ForEach-Object{                   
                    
                    Unzip-File -File $(Join-Path $_.Path $_.Filename) -Destination $ModulePath
                }
                
                Move-Item -Path "$ModulePath\Carbon\*" -Destination $ModulePath -ErrorAction SilentlyContinue
                		
                
                
                
                
                
                
                

                $_.Downloads | ForEach-Object{
                    Remove-Item $(Join-Path $_.Path $_.Filename)
                }
                		
                
                
                
                		
                if($Update){$_.Result = "AppUpdated";$_
                }else{$_.Result = "AppInstalled";$_}
            		
            
            
            
            		
            }else{
            	
                $_.Result = "ConditionExclusion";$_
            }

        
        
        
        	
        }else{
            
			$ModulePath = (Join-Path $env:PSModulePath.Split(";")[0] "Carbon");if(Test-Path $ModulePath){Remove-Item -Path $ModulePath -Force -Recurse}
			
            $_.Result = "AppUninstalled";$_
        }

    
    
    

    }catch{

        $Config.Result = "Error";$Config
    }
}