
[CmdletBinding()]
param ()

function Get-CurrentDate {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$CurrentDate = Get-Date
	$CurrentDate = $CurrentDate.ToShortDateString()
	$CurrentDate = $CurrentDate -replace "/", "-"
	If ($CurrentDate[2] -ne "-") {
		$CurrentDate = $CurrentDate.Insert(0, "0")
	}
	If ($CurrentDate[5] -ne "-") {
		$CurrentDate = $CurrentDate.Insert(3, "0")
	}
	Return $CurrentDate
}

function Invoke-HardwareInventoryCycle {

	
	[CmdletBinding()]
	param ()
	
	$Completed = $false
	$StartTime = Get-Date -UFormat %R
	$CurrentDate = Get-CurrentDate
	Write-Host "Running Hardware Inventory Cycle....." -NoNewline
	Start-ConfigurationManagerClientScan -ScheduleID "00000000-0000-0000-0000-000000000001"
	Do {
		Start-Sleep -Seconds 1
		$CurrentTime = Get-Date -UFormat %R
		$TimeDifference = New-TimeSpan -Start $StartTime -End $CurrentTime
		$Log = Get-Content $env:windir"\ccm\logs\InventoryAgent.log"
		$Count = $Log.count
		$Count = $Count - 1
		$Log = $Log[$Count]
		$LogTable = $Log.split("<")[-1]
		$LogTable = $LogTable.Substring(0, $LogTable.length - 1) -replace ' ', ';'
		$LogTable = "@{$($LogTable)}" | Invoke-Expression
		$LogTime = $LogTable.time.Substring(0, 5)
		[datetime]$StringTime = $LogTable.time
		If (($Log -like "*End of message processing*") -and ($CurrentDate -eq $LogTable.date) -and ($LogTime -ge $StartTime)) {
			Write-Host "Completed" -ForegroundColor Yellow
			$Success = $true
			$Completed = $true
		}
		If (($Log -like "*already in queue. Message ignored.*") -and ($CurrentDate -eq $LogTable.date) -and ($LogTime -ge $StartTime)) {
			Write-Host "Ignored" -ForegroundColor Red
			$Success = $false
			$Completed = $true
		}
		If ($TimeDifference.Minutes -ge 5) {
			Write-Host "Failed" -ForegroundColor Yellow
			$Success = $false
			$Completed = $true
		}
	} while ($Completed -eq $false)
	Return $Success
}

function Start-ConfigurationManagerClientScan {

	
	[CmdletBinding()]
	param
	(
		[ValidateSet('00000000-0000-0000-0000-000000000121', '00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000108', '00000000-0000-0000-0000-000000000113', '00000000-0000-0000-0000-000000000111', '00000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000027', '00000000-0000-0000-0000-000000000032')]$ScheduleID
	)
	
	$WMIPath = "\\" + $env:COMPUTERNAME + "\root\ccm:SMS_Client"
	$SMSwmi = [wmiclass]$WMIPath
	$Action = [char]123 + $ScheduleID + [char]125
	[Void]$SMSwmi.TriggerSchedule($Action)
}

Clear-Host
$Success = Invoke-HardwareInventoryCycle
If ($Success -eq $false) {
	Exit 1
}
