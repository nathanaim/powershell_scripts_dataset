

Describe "Export-FormatData" -Tags "CI" {
    BeforeAll {
        $fd = Get-FormatData
        $testOutput = Join-Path -Path $TestDrive -ChildPath "outputfile"
    }

    AfterEach {
        Remove-Item $testOutput -Force -ErrorAction SilentlyContinue
    }

    It "Can export all types" {
        try
        {
            $fd | Export-FormatData -path $TESTDRIVE\allformat.ps1xml -IncludeScriptBlock

            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $sessionState.Formats.Clear()
            $sessionState.Types.Clear()

            $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($sessionState)
            $runspace.Open()

            $runspace.CreatePipeline("Update-FormatData -AppendPath $TESTDRIVE\allformat.ps1xml").Invoke()
            $actualAllFormat = $runspace.CreatePipeline("Get-FormatData -TypeName *").Invoke()

            $fd.Count | Should -Be $actualAllFormat.Count
            Compare-Object $fd $actualAllFormat | Should -Be $null
        }
        finally
        {
            $runspace.Close()
            Remove-Item -Path $TESTDRIVE\allformat.ps1xml -Force -ErrorAction SilentlyContinue
        }
    }

    It "Works with literal path" {
        $filename = 'TestDrive:\[formats.ps1xml'
        $fd | Export-FormatData -LiteralPath $filename
        (Test-Path -LiteralPath $filename) | Should -BeTrue
    }

    It "Should overwrite the destination file" {
        $filename = 'TestDrive:\ExportFormatDataWithForce.ps1xml'
        $unexpected = "SHOULD BE OVERWRITTEN"
        $unexpected | Out-File -FilePath $filename -Force
        $file = Get-Item  $filename
        $file.IsReadOnly = $true
        $fd | Export-FormatData -Path $filename -Force

        $actual = @(Get-Content $filename)[0]
        $actual | Should -Not -Be $unexpected
    }

    It "should not overwrite the destination file with NoClobber" {
        $filename = "TestDrive:\ExportFormatDataWithNoClobber.ps1xml"
        $fd | Export-FormatData -LiteralPath $filename

        { $fd | Export-FormatData -LiteralPath $filename -NoClobber } | Should -Throw -ErrorId 'NoClobber,Microsoft.PowerShell.Commands.ExportFormatDataCommand'
    }

    It "Test basic functionality" {
        Export-FormatData -InputObject $fd[0] -Path $testOutput
        $content = Get-Content $testOutput -Raw
        $formatViewDefinition = $fd[0].FormatViewDefinition
        $typeName = $fd[0].TypeName
        $content.Contains($typeName) | Should -BeTrue
        for ($i = 0; $i -lt $formatViewDefinition.Count;$i++)
        {
            $content.Contains($formatViewDefinition[$i].Name) | Should -BeTrue
        }
    }

    It "Should have a valid xml tag at the start of the file" {
        $fd | Export-FormatData -Path $testOutput
        $piped = Get-Content $testOutput -Raw
        $piped[0] | Should -BeExactly "<"
    }

    It "Should pretty print xml output" {
        $xmlContent=@"
            <Configuration>
            <ViewDefinitions>
            <View>
            <Name>ExportFormatDataName</Name>
            <ViewSelectedBy>
                <TypeName>ExportFormatDataTypeName</TypeName>
            </ViewSelectedBy>
            <TableControl>
                <TableHeaders />
                <TableRowEntries>
                <TableRowEntry>
                <TableColumnItems>
                <TableColumnItem>
                    <PropertyName>Guid</PropertyName>
                </TableColumnItem>
                </TableColumnItems>
                </TableRowEntry>
                </TableRowEntries>
            </TableControl>
            </View>
            </ViewDefinitions>
            </Configuration>
"@
        $expected = @"
<?xml version="1.0" encoding="utf-8"?>
<Configuration>
  <ViewDefinitions>
    <View>
      <Name>ExportFormatDataName</Name>
      <ViewSelectedBy>
        <TypeName>ExportFormatDataTypeName</TypeName>
      </ViewSelectedBy>
      <TableControl>
        <TableHeaders />
        <TableRowEntries>
          <TableRowEntry>
            <TableColumnItems>
              <TableColumnItem>
                <PropertyName>Guid</PropertyName>
              </TableColumnItem>
            </TableColumnItems>
          </TableRowEntry>
        </TableRowEntries>
      </TableControl>
    </View>
  </ViewDefinitions>
</Configuration>
"@ -replace "`r`n?|`n", ""
        try
        {
            $testfilename = [guid]::NewGuid().ToString('N')
            $testfile = Join-Path -Path $TestDrive -ChildPath "$testfilename.ps1xml"
            Set-Content -Path $testfile -Value $xmlContent

            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $sessionState.Formats.Clear()
            $sessionState.Types.Clear()

            $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($sessionState)
            $runspace.Open()

            $runspace.CreatePipeline("Update-FormatData -prependPath $testfile").Invoke()
            $runspace.CreatePipeline("Get-FormatData -TypeName 'ExportFormatDataTypeName' | Export-FormatData -Path $testOutput").Invoke()

            $content = (Get-Content $testOutput -Raw) -replace "`r`n?|`n", ""

            $content | Should -BeExactly $expected
        }
        finally
        {
            $runspace.Close()
        }
    }
}
