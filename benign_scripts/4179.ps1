

Function GetRelativePath{  

	
	Set-Variable -Name RelativePath -Scope Local -Force
	
	$RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\"
	Return $RelativePath
	
	
	Remove-Variable -Name RelativePath -Scope Local -Force
	
}
 
Function GenerateGUID {

	
	Set-Variable -Name GetGUID -Scope Local -Force
	
	$GetGUID = [guid]::NewGuid()
	$GetGUID = $GetGUID.ToString().ToUpper()
	
	return $GetGUID

	
	Remove-Variable -Name GetGUID -Scope Local -Force
	
}

Function GetKeyInfo {

	
	Set-Variable -Name ComponentID -Scope Local -Force
	Set-Variable -Name Description -Scope Local -Force
	Set-Variable -Name StubPath -Scope Local -Force
	Set-Variable -Name Version -Scope Local -Force
	
	$ComponentID = Read-Host "Enter the title"
	$Description = Read-Host "Enter brief description"
	$Version = Read-Host "Enter the version number"
	$StubPath = Read-Host "Enter the command line execution string"
	$StubPath = $StubPath -replace '\\','\\'
	Return $ComponentID, $Description, $Version, $StubPath
	
	
	Remove-Variable -Name ComponentID -Scope Local -Force
	Remove-Variable -Name Description -Scope Local -Force
	Remove-Variable -Name StubPath -Scope Local -Force
	Remove-Variable -Name Version -Scope Local -Force
	
}

Function GenerateRegKey ($RelativePath, $GUID, $KeyInfo) {

	
	Set-Variable -Name File -Scope Local -Force
	Set-Variable -Name Text -Scope Local -Force
	
	$File = $RelativePath+"ActiveSetup.reg"
	If (Test-Path $File) {
		Remove-Item -Path $File -Force
	}
	New-Item -Name ActiveSetup.reg -Path $RelativePath -ItemType file -Force
	$Text = "Windows Registry Editor Version 5.00"
	Add-Content -Path $File -Value $Text -Force
	$Text = [char]13
	Add-Content -Path $File -Value $Text -Force
	$Text = "[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{"+$GUID+"}]"
	Add-Content -Path $File -Value $Text -Force
	$Text = "@="+[char]34+$KeyInfo[1]+[char]34
	Add-Content -Path $File -Value $Text -Force
	$Text = [char]34+"ComponentID"+[char]34+"="+[char]34+$KeyInfo[0]+[char]34
	Add-Content -Path $File -Value $Text -Force
	$Text = [char]34+"StubPath"+[char]34+"="+[char]34+$KeyInfo[3]+[char]34
	Add-Content -Path $File -Value $Text -Force
	$Text = [char]34+"Version"+[char]34+"="+[char]34+$KeyInfo[2]+[char]34
	Add-Content -Path $File -Value $Text -Force

	
	Remove-Variable -Name File -Scope Local -Force
	Remove-Variable -Name Text -Scope Local -Force

}


Set-Variable -Name GUID -Scope Local -Force
Set-Variable -Name KeyInfo -Scope Local -Force
Set-Variable -Name RelativePath -Scope Local -Force

cls
$RelativePath = GetRelativePath
$GUID = GenerateGUID
$KeyInfo = GetKeyInfo
GenerateRegKey $RelativePath $GUID $KeyInfo


Remove-Variable -Name GUID -Scope Local -Force
Remove-Variable -Name KeyInfo -Scope Local -Force
Remove-Variable -Name RelativePath -Scope Local -Force
