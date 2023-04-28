Set-StrictMode -Version latest

$projectRoot = Resolve-Path -Path "$PSScriptRoot/.."
if (-not $projectRoot) {
    $projectRoot = $PSScriptRoot
}


Import-Module -Name (Join-Path -Path $projectRoot -ChildPath 'tests/MetaFixers.psm1') -Verbose:$false -Force

Describe 'Text files formatting' {

    $allTextFiles = Get-TextFilesList $projectRoot

    Context 'Files encoding' {
        It "Doesn't use Unicode encoding" {
            $unicodeFilesCount = 0
            $allTextFiles | Foreach-Object {
                if (Test-FileUnicode $_) {
                    $unicodeFilesCount += 1
                    Write-Warning "File $($_.FullName) contains 0x00 bytes. It's probably uses Unicode and need to be converted to UTF-8. Use Fixer 'Get-UnicodeFilesList `$pwd | ConvertTo-UTF8'."
                }
            }
            $unicodeFilesCount | Should Be 0
        }
    }

    Context 'Indentations' {
        It 'Uses spaces for indentation, not tabs' {
            $totalTabsCount = 0
            $allTextFiles | Foreach-Object {
                $fileName = $_.FullName
                (Get-Content $_.FullName -Raw) | Select-String "`t" | Foreach-Object {
                    Write-Warning "There are tab in $fileName. Use Fixer 'Get-TextFilesList `$pwd | ConvertTo-SpaceIndentation'."
                    $totalTabsCount++
                }
            }
            $totalTabsCount | Should Be 0
        }
    }
}

Remove-Module -Name MetaFixers -Verbose:$false
