

function Get-MetaData {

	
	[CmdletBinding()][OutputType([object])]
	param
	(
			[ValidateNotNullOrEmpty()][string]$FileName
	)
	
	$MetaDataObject = New-Object System.Object
	$shell = New-Object -COMObject Shell.Application
	$folder = Split-Path $FileName
	$file = Split-Path $FileName -Leaf
	$shellfolder = $shell.Namespace($folder)
	$shellfile = $shellfolder.ParseName($file)
	$MetaDataProperties = 0..287 | Foreach-Object { '{0} = {1}' -f $_, $shellfolder.GetDetailsOf($null, $_) }
	For ($i = 0; $i -le 287; $i++) {
		$Property = ($MetaDataProperties[$i].split("="))[1].Trim()
		$Property = (Get-Culture).TextInfo.ToTitleCase($Property).Replace(' ', '')
		$Value = $shellfolder.GetDetailsOf($shellfile, $i)
		If ($Property -eq 'Attributes') {
			switch ($Value) {
				'A' {
					$Value = 'Archive (A)'
				}
				'D' {
					$Value = 'Directory (D)'
				}
				'H' {
					$Value = 'Hidden (H)'
				}
				'L' {
					$Value = 'Symlink (L)'
				}
				'R' {
					$Value = 'Read-Only (R)'
				}
				'S' {
					$Value = 'System (S)'
				}
			}
		}
		
		If (($Value -ne $null) -and ($Value -ne '')) {
			$MetaDataObject | Add-Member -MemberType NoteProperty -Name $Property -Value $Value
		}
	}
	[string]$FileVersionInfo = (Get-ItemProperty $FileName).VersionInfo
	$SplitInfo = $FileVersionInfo.Split([char]13)
	foreach ($Item in $SplitInfo) {
		$Property = $Item.Split(":").Trim()
		switch ($Property[0]) {
			"InternalName" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name InternalName -Value $Property[1]
			}
			"OriginalFileName" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name OriginalFileName -Value $Property[1]
			}
			"Product" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name Product -Value $Property[1]
			}
			"Debug" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name Debug -Value $Property[1]
			}
			"Patched" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name Patched -Value $Property[1]
			}
			"PreRelease" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name PreRelease -Value $Property[1]
			}
			"PrivateBuild" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name PrivateBuild -Value $Property[1]
			}
			"SpecialBuild" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name SpecialBuild -Value $Property[1]
			}
		}
	}
	
	
	$ReadOnly = (Get-ChildItem $FileName) | Select-Object IsReadOnly
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name ReadOnly -Value $ReadOnly.IsReadOnly
	
	$DigitalSignature = get-authenticodesignature -filepath $FileName
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateSubject -Value $DigitalSignature.SignerCertificate.Subject
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateIssuer -Value $DigitalSignature.SignerCertificate.Issuer
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateSerialNumber -Value $DigitalSignature.SignerCertificate.SerialNumber
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateNotBefore -Value $DigitalSignature.SignerCertificate.NotBefore
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateNotAfter -Value $DigitalSignature.SignerCertificate.NotAfter
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateThumbprint -Value $DigitalSignature.SignerCertificate.Thumbprint
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureStatus -Value $DigitalSignature.Status
	Return $MetaDataObject
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

Clear-Host
$RelativePath = Get-RelativePath
$File = $RelativePath + "scepinstall.exe"
$FileMetaData = Get-MetaData -FileName $File

$FileMetaData

$FileMetaData.Name

