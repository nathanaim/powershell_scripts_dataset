param(
	[string]$Version,
	[string]$Path,
	[switch]$Force,
	$Update,
	[switch]$Uninstall
)





$Configs = @{
	Version = "6.5.3"
	Url = "http://download.tuxfamily.org/notepadplus/6.5.3/npp.6.5.3.Installer.exe"
	
    Path = "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)\"
    
    Executable = "C:\Program Files (x86)\Sublime Text 2\sublime_text.exe"
}

$Configs = @{
	Version = "2.7.6"
	Url = "https://www.python.org/ftp/python/2.7.6/python-2.7.6.msi"
    Path = "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)\"
    MSIProductName = "Python 2.7.6"

},@{
	Version = "3.4.0"
	Url = "https://www.python.org/ftp/python/3.4.0/python-3.4.0.msi"
    Path = "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)\"
    MSIProductName = "Python 3.4.0"
}

$Configs | where{$_.Version -eq $Version} | ForEach-Object{

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

                
                
                
				
				$Directory = "C:\Program Files\MongoDB\"; if(-not (Test-Path -Path $Directory)){New-Item -Path $Directory -Type directory}
				
                $_.Downloads | ForEach-Object{
                    Start-Process -FilePath $(Join-Path $_.Path $_.Filename) -ArgumentList "/VERYSILENT /NORESTART" -Wait
					Start-Process -FilePath "msiexec" -ArgumentList "/i $(Join-Path $_.Path $_.Filename) /quiet /norestart" -Wait
                }
								
                $WorkingPath = (Get-Location).Path
                Set-Location "C:\Program Files\"
				$_.Downloads | ForEach-Object{
                    Unzip-File -File $(Join-Path $_.Path $_.Filename) -Destination $($env:PSModulePath.Split(";")[0])
                }
                Set-Location $WorkingPath
                
                Rename-Item -Path "C:\Program Files\mongodb-win32-x86_64-2008plus-2.4.9" -NewName "MongoDB" -Force
                		
                
                
                

                $Executable = "C:\Program Files (x86)\PuTTY\putty.exe";if(Test-Path $Executable){Set-Content -Path (Join-Path $PSbin.Path "putty.bat") -Value "@echo off`nstart `"`" `"$Executable`" %*"}
				
				Set-EnvironmentVariableValue -Name "Path" -Value ";C:\Program Files (x86)\Notepad++\" -Target "Machine" -Add
                
                
                Set-Content -Path (Join-Path $_.Path "Sublime Text 2 Context Add.bat") -Value @"
rem add it for all file types
reg add "HKEY_CLASSES_ROOT\*\shell\Open with Sublime Text 2" /t REG_SZ /v "" /d "Open with Sublime Text 2" /f
reg add "HKEY_CLASSES_ROOT\*\shell\Open with Sublime Text 2" /t REG_EXPAND_SZ /v "Icon" /d "$($_.Executable),0" /f
reg add "HKEY_CLASSES_ROOT\*\shell\Open with Sublime Text 2\command" /t REG_SZ /v "" /d "$($_.Executable) \"%%1\"" /f

rem add it for folders
reg add "HKEY_CLASSES_ROOT\Folder\shell\Open with Sublime Text 2" /t REG_SZ /v "" /d "Open with Sublime Text 2"   /f
reg add "HKEY_CLASSES_ROOT\Folder\shell\Open with Sublime Text 2" /t REG_EXPAND_SZ /v "Icon" /d "$($_.Executable),0" /f
reg add "HKEY_CLASSES_ROOT\Folder\shell\Open with Sublime Text 2\command" /t REG_SZ /v "" /d "$($_.Executable) \"%%1\"" /f
"@
                & (Join-Path $_.Path "Sublime Text 2 Context Add.bat") | out-null
                
                
                
                

                $_.Downloads | ForEach-Object{
                    Remove-Item (Join-Path $_.Path $_.Filename) -Force
                }
                Remove-Item (Join-Path $_.Path "Sublime Text 2 Context Add.bat") -Force
                		
                
                
                
                		
                if($Update){
                    $_.Result = "AppUpdated";$_
                }elseif($Downgrade){
                    $_.Result = "AppDowngraded";$_
                }else{
                    $_.Result = "AppInstalled";$_
                }
            		
            
            
            
            		
            }else{
            	
                $_.Result = "ConditionExclusion";$_
            }

        
        
        
        	
        }else{

			Remove-EnvironmentVariableValue -Name Path -Value ";C:\Program Files\nodejs" -Target Machine
		
            if(Test-Path (Join-Path $PSbin.Path "putty.bat")){Remove-Item (Join-Path $PSbin.Path "putty.bat")}
            
            $Executable = "C:\Program Files (x86)\PuTTY\unins000.exe"; if(Test-Path $Executable){Start-Process -FilePath $Executable -ArgumentList "/VERYSILENT /NORESTART" -Wait}
            
			$Directory = "C:\Program Files\MongoDB\"; if(Test-Path $Directory){Remove-Item -Path $Directory -Force -Recurse}
            
            Get-MSI | where{$_.ProductName -eq "7-Zip 9.20 (x64 edition)"} | ForEach-Object{
                 Start-Process -FilePath "msiexec" -ArgumentList "/uninstall $($_.LocalPackage) /qn /norestart" -Wait 
            }

			Set-Content -Path (Join-Path $_.Path "Sublime Text 2 Context Remove.bat") -Value @"
rem remove for all file types
reg delete "HKEY_CLASSES_ROOT\*\shell\Open with Sublime Text 2" /f

rem remove for folders
reg delete "HKEY_CLASSES_ROOT\Folder\shell\Open with Sublime Text 2" /f
"@
            & (Join-Path $_.Path "Sublime Text 2 Context Remove.bat") | out-null
                
            Remove-Item (Join-Path $_.Path "Sublime Text 2 Remove.bat") -Force
                
            $_.Result = "AppUninstalled";$_
        }

    
    
    

    }catch{

        $Config.Result = "Error";$Config
    }
}