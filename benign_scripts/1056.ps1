











& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)
$carbonTestInstaller = Join-Path -Path $PSScriptRoot -ChildPath 'MSI\CarbonTestInstaller.msi' -Resolve
$carbonTestInstallerActions = Join-Path -Path $PSScriptRoot -ChildPath 'MSI\CarbonTestInstallerWithCustomActions.msi' -Resolve

Describe 'Install-Msi' {
    
    function Assert-CarbonTestInstallerInstalled
    {
        $Global:Error.Count | Should Be 0
        $maxTries = 200
        $tryNum = 0
        do
        {
            $item = Get-ProgramInstallInfo -Name 'Carbon Test Installer*'
            if( $item )
            {
                break
            }
    
            Start-Sleep -Milliseconds 100
        }
        while( $tryNum++ -lt $maxTries )
        $item | Should Not BeNullOrEmpty
    }
    
    function Assert-CarbonTestInstallerNotInstalled
    {
        $maxTries = 200
        $tryNum = 0
        do
        {
            $item = Get-ProgramInstallInfo -Name 'Carbon Test Installer*'
            if( -not $item )
            {
                break
            }

            Start-Sleep -Milliseconds 100
        }
        while( $tryNum++ -lt $maxTries )

        $item | Should BeNullOrEmpty
    }
    
    function Uninstall-CarbonTestInstaller
    {
        Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'MSI') -Filter *.msi |
            Get-Msi |
            Where-Object { Get-ProgramInstallInfo -Name $_.ProductName } |
            ForEach-Object {
                
                $msiProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList "/quiet","/fa",('"{0}"' -f $_.Path) -NoNewWindow -Wait -PassThru
                if( $msiProcess.ExitCode -ne $null -and $msiProcess.ExitCode -ne 0 )
                {
                    Write-Error ("{0} {1} repair failed. (Exit code: {2}; MSI: {3})" -f $_.ProductName,$_.ProductVersion,$msiProcess.ExitCode,$_.Path)
                }
                
                $msiProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList "/quiet","/uninstall",('"{0}"' -f $_.Path) -NoNewWindow -Wait -PassThru
                if( $msiProcess.ExitCode -ne $null -and $msiProcess.ExitCode -ne 0 )
                {
                    Write-Error ("{0} {1} uninstall failed. (Exit code: {2}; MSI: {3})" -f $_.ProductName,$_.ProductVersion,$msiProcess.ExitCode,$_.Path)
                }
            }
        Assert-CarbonTestInstallerNotInstalled
    }

    BeforeEach {
        $Global:Error.Clear()
        Uninstall-CarbonTestInstaller
    }
    
    AfterEach {
        Uninstall-CarbonTestInstaller
    }
    
    It 'should validate file is an MSI' {
        Invoke-WindowsInstaller -Path $PSCommandPath -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
    }
    
    It 'should support what if' {
        Assert-CarbonTestInstallerNotInstalled
        Invoke-WindowsInstaller -Path $carbonTestInstaller -WhatIf
        $Global:Error.Count | Should Be 0
        Assert-CarbonTestInstallerNotInstalled
    }
    
    It 'should install msi' {
        Assert-CarbonTestInstallerNotInstalled
        Install-Msi -Path $carbonTestInstaller
        Assert-CarbonTestInstallerInstalled
    }
    
    It 'should warn quiet switch is obsolete' {
        $warnings = @()
        Install-Msi -Path $carbonTestInstaller -Quiet -WarningVariable 'warnings'
        $warnings.Count | Should Be 1
        ($warnings[0] -like '*obsolete*') | Should Be $true
    }
    
    It 'should handle failed installer' {
        Set-EnvironmentVariable -Name 'CARBON_TEST_INSTALLER_THROW_INSTALL_EXCEPTION' -Value $true -ForComputer
        try
        {
            Install-Msi -Path $carbonTestInstallerActions -ErrorAction SilentlyContinue
            Assert-CarbonTestInstallerNotInstalled
        }
        finally
        {
            Remove-EnvironmentVariable -Name 'CARBON_TEST_INSTALLER_THROW_INSTALL_EXCEPTION' -ForComputer
        }
    }
    
    It 'should support wildcards' {
        $tempDir = 'TestDrive:'
        Copy-Item $carbonTestInstaller -Destination (Join-Path -Path $tempDir -ChildPath 'One.msi')
        Copy-Item $carbonTestInstaller -Destination (Join-Path -Path $tempDir -ChildPath 'Two.msi')
        Install-Msi -Path (Join-Path -Path $tempDir -ChildPath '*.msi')
        Assert-CarbonTestInstallerInstalled
    }
    
    It 'should not reinstall if already installed' {
        Install-Msi -Path $carbonTestInstallerActions
        Assert-CarbonTestInstallerInstalled
        $msi = Get-Msi -Path $carbonTestInstallerActions
        $installDir = Join-Path ${env:ProgramFiles(x86)} -ChildPath ('{0}\{1}' -f $msi.Manufacturer,$msi.ProductName)
        $installDir | Should Exist
        $tempName = [IO.Path]::GetRandomFileName()
        Rename-Item -Path $installDir -NewName $tempName
        try
        {
            Install-Msi -Path $carbonTestInstallerActions
            $installDir | Should Not Exist
        }
        finally
        {
            $tempDir = Split-Path -Path $installDir -Parent
            $tempDir = Join-Path -Path $tempDir -ChildPath $tempName
            Rename-Item -Path $tempDir -NewName (Split-Path -Path $installDir -Leaf)
        }
    }
    
    It 'should reinstall if forced to' {
        Install-Msi -Path $carbonTestInstallerActions
        Assert-CarbonTestInstallerInstalled
        $msi = Get-Msi -Path $carbonTestInstallerActions
    
        $installDir = Join-Path ${env:ProgramFiles(x86)} -ChildPath ('{0}\{1}' -f $msi.Manufacturer,$msi.ProductName)
        $maxTries = 100
        $tryNum = 0
        do
        {
            if( (Test-Path -Path $installDir -PathType Container) )
            {
                break
            }
            Start-Sleep -Milliseconds 100
        }
        while( $tryNum++ -lt $maxTries )
    
        $installDir | Should Exist
    
        $tryNum = 0
        do
        {
            Remove-Item -Path $installDir -Recurse -ErrorAction Ignore
            if( -not (Test-Path -Path $installDir -PathType Container) )
            {
                break
            }
            Start-Sleep -Milliseconds 100
        }
        while( $tryNum++ -lt $maxTries )
    
        $installDir | Should Not Exist
    
        Install-Msi -Path $carbonTestInstallerActions -Force
        $installDir | Should Exist
    }
    
    It 'should install msi with spaces in path' {
        $tempDir = 'TestDrive:'
        $newInstaller = Join-Path -Path $tempDir -ChildPath 'Installer With Spaces.msi'
        Copy-Item -Path $carbonTestInstaller -Destination $newInstaller
        Install-Msi -Path $newInstaller
        Assert-CarbonTestInstallerInstalled
    }
}

