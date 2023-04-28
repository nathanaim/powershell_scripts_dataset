


$script:TestSourceRoot = $PSScriptRoot
Describe "Test suite for validating automounted PowerShell drives" -Tags @('Feature', 'Slow', 'RequireAdminOnWindows') {

    BeforeAll {
        $powershell = Join-Path -Path $PsHome -ChildPath "pwsh"

        $AutomountVHDDriveScriptPath = Join-Path $script:TestSourceRoot 'AutomountVHDDrive.ps1'
        $vhdPath = Join-Path $TestDrive 'TestAutomountVHD.vhd'

        $AutomountSubstDriveScriptPath = Join-Path $script:TestSourceRoot 'AutomountSubstDrive.ps1'
        $substDir = Join-Path (Join-Path $TestDrive 'TestAutomountSubstDrive') 'TestDriveRoot'
        New-Item $substDir -ItemType Directory -Force | Out-Null

        $SubstNotFound = $false
        try { subst.exe } catch { $SubstNotFound = $true }

        $VHDToolsNotFound = $false
        try
        {
            $tmpVhdPath = Join-Path $TestDrive 'TestVHD.vhd'
            New-VHD -path $tmpVhdPath -SizeBytes 5mb -Dynamic -ErrorAction Stop
            Remove-Item $tmpVhdPath
        }
        catch
        { $VHDToolsNotFound = $true }
    }

    Context "Validating automounting FileSystem drives" {

        It "Test automounting using subst.exe" -Skip:$SubstNotFound {
           & $powershell -noprofile -command "& '$AutomountSubstDriveScriptPath' -FullPath '$substDir'" | Should -BeExactly "Drive found"
        }

        It "Test automounting using New-VHD/Mount-VHD" -Skip:$VHDToolsNotFound {
            & $powershell -noprofile -command "& '$AutomountVHDDriveScriptPath' -VHDPath '$vhdPath'" | Should -BeExactly "Drive found"
        }
    }

    Context "Validating automounting FileSystem drives from modules" {

        It "Test automounting using subst.exe" -Skip:$SubstNotFound {
           & $powershell -noprofile -command "& '$AutomountSubstDriveScriptPath' -useModule -FullPath '$substDir'" | Should -BeExactly "Drive found"
        }

        It "Test automounting using New-VHD/Mount-VHD" -Skip:$VHDToolsNotFound {
            $vhdPath = Join-Path $TestDrive 'TestAutomountVHD.vhd'
            & $powershell -noprofile -command "& '$AutomountVHDDriveScriptPath' -useModule -VHDPath '$vhdPath'" | Should -BeExactly "Drive found"
        }
    }
}
