

function Write-PPEventLog{



	param(        
        [Parameter(Mandatory=$true)]
		$Message,
        
        [Parameter(Mandatory=$false)]
		$EventLog,
        
        [Parameter(Mandatory=$false)]
		$EventId, 
               
        [Parameter(Mandatory=$false)]
		$Source,       
                
        [Parameter(Mandatory=$false)]
		[string]
        $EntryType,
        
		[switch]
        $WriteMessage,
		
        [switch]
        $AppendSessionLog
	)
	
	
	
	
    $EventLogs =  Get-PPConfiguration $PSconfigs.EventLog.Filter | %{$_.Content.EventLog}
    
    if($EventLog){$EventLogs = $EventLogs | where{$_.Name -eq $EventLog}        
    }elseif($EventLogs){$EventLogs = $EventLogs | where{$_.Role -eq "Default"} | select -first 1
    }else{throw "Couldn't find event log configurations with role: Default in $($PSconfigs.Path)"}
    
    if($EventLogs -eq $null){throw "Couldn't find event log configurations in $($PSconfigs.Path)"}
    
    $EventLogs | %{   
    	    
        if(-not $EventId){    
            if($EntryType -eq "Error"){$EventId = $_.ErrorEventId        
            }elseif($EntryType -eq "Warning"){$EventId = $_.WarningEventId
            }elseif($EntryType -eq "FailureAudit"){$EventId = $_.FailureAudit     
            }elseif($EntryType -eq "SuccessAudit"){$EventId = $_.SuccessAudit
            }elseif($EntryType -eq "InformationEventId"){$EventId = $_.InformationEventId     
            }else{$EventId = $_.DefaultEventId}
        }
        
        if(-not $EntryType){$EntryType = $_.DefaultEntryType}
        
        if($WriteMessage){
    		if($EntryType -eq "Error"){Write-Error $Message    
    		}elseif($EntryType -eq "Warning"){Write-Warning $Message       
    		}else{Write-Host $Message}
        }
        
        if(-not $Source){
            $Source = $_.Source | where{$_.Role -eq "Default"} | %{"$($_.Name)"}
            if($Source -eq $null){throw "Couldn't find default source in event log configuration for: $($_.Name)"}
        }
             
        if($AppendSessionLog){
    		Copy-Item $PSlogs.SessionFile ("$($PSlogs.SessionFile).tmp")
    		$Message += "`n`n" + (Get-Content $PSlogs.SessionFile | Out-String)
    		Remove-Item ("$($PSlogs.SessionFile).tmp")
    	}       
        
        Write-EventLog -EventId $EventId -Message $Message -ComputerName $env:COMPUTERNAME -LogName $_.Name -Source $Source -EntryType $EntryType
    }
}