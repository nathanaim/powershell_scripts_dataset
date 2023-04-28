


 
 
 
 return
 
$cmdletName = "Export-Counter"

. "$PSScriptRoot/CounterTestHelperFunctions.ps1"

$rootFilename = "exportedCounters"
$filePath = $null
$counterNames = @(
    (TranslateCounterPath "\Memory\Available Bytes")
    (TranslateCounterPath "\Processor(*)\% Processor Time")
    (TranslateCounterPath "\Processor(_Total)\% Processor Time")
    (TranslateCounterPath "\PhysicalDisk(_Total)\Current Disk Queue Length")
    (TranslateCounterPath "\PhysicalDisk(_Total)\Disk Bytes/sec")
    (TranslateCounterPath "\PhysicalDisk(_Total)\Disk Read Bytes/sec")
)
$counterValues = $null



function CheckExportResults
{
    Test-Path $filePath | Should -BeTrue
    $importedCounterValues = Import-Counter $filePath

    CompareCounterSets $counterValues $importedCounterValues
}


function RunTest($testCase)
{
    It "$($testCase.Name)" -Skip:$(SkipCounterTests) {
        $getCounterParams = ""
        if ($testCase.ContainsKey("GetCounterParams"))
        {
            $getCounterParams = $testCase.GetCounterParams
        }
        $counterValues = &([ScriptBlock]::Create("Get-Counter -Counter `$counterNames $getCounterParams"))

        
        $filePath = ""
        $pathParam = ""
        $formatParam = ""
        if ($testCase.ContainsKey("Path"))
        {
            $filePath = $testCase.Path
        }
        else
        {
            if ($testCase.ContainsKey("FileFormat"))
            {
                $formatParam = "-FileFormat $($testCase.FileFormat)"
                $filePath = Join-Path $script:outputDirectory "$rootFilename.$($testCase.FileFormat)"
            }
            else
            {
                $filePath = Join-Path $script:outputDirectory "$rootFilename.blg"
            }
        }
        if ($testCase.NoDashPath)
        {
            $pathParam = $filePath
        }
        else
        {
            $pathParam = "-Path $filePath"
        }
        $cmd = "$cmdletName $pathParam $formatParam -InputObject `$counterValues $($testCase.Parameters) -ErrorAction Stop"
        
        

        if ($testCase.CreateFileFirst)
        {
            if (-not (Test-Path $filePath))
            {
                New-Item $filePath -ItemType file
            }
        }

        try
        {
            if ($testCase.ContainsKey("Script"))
            {
                
                $sb = [ScriptBlock]::Create($cmd)
                &$sb
                &$testCase.Script
            }
            else
            {
                
                $sb = [ScriptBlock]::Create($cmd)
                { &$sb } | Should -Throw -ErrorId $testCase.ExpectedErrorId
            }
        }
        finally
        {
            if ($filePath)
            {
                Remove-Item $filePath -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "CI tests for Export-Counter cmdlet" -Tags "CI" {

    BeforeAll {
        $script:outputDirectory = $testDrive
    }

    $testCases = @(
        @{
            Name = "Can export BLG format"
            FileFormat = "blg"
            GetCounterParams = "-MaxSamples 5"
            Script = { CheckExportResults }
        }
        @{
            Name = "Exports BLG format by default"
            GetCounterParams = "-MaxSamples 5"
            Script = { CheckExportResults }
        }
    )

    foreach ($testCase in $testCases)
    {
        RunTest $testCase
    }
}

Describe "Feature tests for Export-Counter cmdlet" -Tags "Feature" {

    BeforeAll {
        $script:outputDirectory = $testDrive
    }

    Context "Validate incorrect parameter usage" {
        $testCases = @(
            @{
                Name = "Fails when given invalid path"
                Path = "c:\DAD288C0-72F8-47D3-8C54-C69481B528DF\counterExport.blg"
                ExpectedErrorId = "FileCreateFailed,Microsoft.PowerShell.Commands.ExportCounterCommand"
            }
            @{
                Name = "Fails when given null path"
                Path = "`$null"
                ExpectedErrorId = "ParameterArgumentValidationErrorNullNotAllowed,Microsoft.PowerShell.Commands.ExportCounterCommand"
            }
            @{
                Name = "Fails when -Path specified but no path given"
                Path = ""
                ExpectedErrorId = "MissingArgument,Microsoft.PowerShell.Commands.ExportCounterCommand"
            }
            @{
                Name = "Fails when given -Circular without -MaxSize"
                Parameters = "-Circular"
                ExpectedErrorId = "CounterCircularNoMaxSize,Microsoft.PowerShell.Commands.ExportCounterCommand"
            }
            @{
                Name = "Fails when given -Circular with zero -MaxSize"
                Parameters = "-Circular -MaxSize 0"
                ExpectedErrorId = "CounterCircularNoMaxSize,Microsoft.PowerShell.Commands.ExportCounterCommand"
            }
            @{
                Name = "Fails when -MaxSize < zero"
                Parameters = "-MaxSize -2"
                ExpectedErrorId = "CannotConvertArgumentNoMessage,Microsoft.PowerShell.Commands.ExportCounterCommand"
            }
        )

        foreach ($testCase in $testCases)
        {
            RunTest $testCase
        }
    }

    Context "Export tests" {
        $testCases = @(
            @{
                Name = "Fails when output file exists"
                CreateFileFirst = $true     
                ExpectedErrorId = "CounterFileExists,Microsoft.PowerShell.Commands.ExportCounterCommand"
            }
            @{
                Name = "Can force overwriting existing file"
                Parameters = "-Force"
                Script = { Test-Path $filePath | Should -BeTrue }
            }
            @{
                Name = "Can export BLG format"
                FileFormat = "blg"
                GetCounterParams = "-MaxSamples 5"
                Script = { CheckExportResults }
            }
            @{
                Name = "Exports BLG format by default"
                GetCounterParams = "-MaxSamples 5"
                Script = { CheckExportResults }
            }
            @{
                Name = "Can export CSV format"
                FileFormat = "csv"
                GetCounterParams = "-MaxSamples 2"
                Script = { CheckExportResults }
            }
            @{
                Name = "Can export TSV format"
                FileFormat = "tsv"
                GetCounterParams = "-MaxSamples 5"
                Script = { CheckExportResults }
            }
        )

        foreach ($testCase in $testCases)
        {
            RunTest $testCase
        }
    }
}
