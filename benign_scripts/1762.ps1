

param(
    [Parameter(Mandatory = $true, Position = 0)] $coverallsToken,
    [Parameter(Mandatory = $true, Position = 1)] $codecovToken,
    [Parameter(Position = 2)] $azureLogDrive = "L:\",
    [switch] $SuppressQuiet
)


function GetFileTable()
{
    $files = $script:covData | Select-Xml './/File'
    foreach($file in $files)
    {
        $script:fileTable[$file.Node.uid] = $file.Node.fullPath
    }
}


function GetSequencePointsForFile([string] $fileId)
{
    $lineCoverage = [System.Collections.Generic.Dictionary[string,int]]::new()

    $sequencePoints = $script:covData | Select-Xml ".//SequencePoint[@fileid = '$fileId']"

    if($sequencePoints.Count -gt 0)
    {
        foreach($sp in $sequencePoints)
        {
            $visitedCount = [int]::Parse($sp.Node.vc)
            $lineNumber = [int]::Parse($sp.Node.sl)
            $lineCoverage[$lineNumber] += [int]::Parse($visitedCount)
        }

        return $lineCoverage
    }
}


function ConvertTo-CodeCovJson
{
    param(
        [string] $Path,
        [string] $DestinationPath
    )

    $Script:fileTable = [ordered]@{}
    $Script:covData = [xml] (Get-Content -ReadCount 0 -Raw -Path $Path)
    $totalCoverage = [PSCustomObject]::new()
    $totalCoverage | Add-Member -MemberType NoteProperty -Name "coverage" -Value ([PSCustomObject]::new())

    
    GetFileTable
    $keys = $Script:fileTable.Keys
    $progress=0
    foreach($f in $keys)
    {
        Write-Progress -Id 1 -Activity "Converting to JSON" -Status 'Converting' -PercentComplete ($progress * 100 / $keys.Count)
        $fileCoverage = GetSequencePointsForFile -fileId $f
        $fileName = $Script:fileTable[$f]
        $previousFileCoverage = $totalCoverage.coverage.${fileName}

        
        if($null -ne $previousFileCoverage)
        {
            foreach($lineNumber in $fileCoverage.Keys)
            {
                $previousFileCoverage[$lineNumber] += [int]::Parse($fileCoverage[$lineNumber])
            }
        }
        else 
        {
            $totalCoverage.coverage | Add-Member -MemberType NoteProperty -Value $fileCoverage -Name $fileName
        }

        $progress++
    }

    Write-Progress -Id 1 -Completed -Activity "Converting to JSON"

    $totalCoverage | ConvertTo-Json -Depth 5 -Compress | Out-File $DestinationPath -Encoding ascii
}

function Write-LogPassThru
{
    Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position = 0)]
        [string] $Message,
        $Path = "$env:Temp\CodeCoverageRunLogs.txt"
    )

    $message = "{0:d} - {0:t} : {1}" -f ([datetime]::now),$message
    Add-Content -Path $Path -Value $Message -PassThru -Force
}

function Push-CodeCovData
{
    param (
        [Parameter(Mandatory=$true)]$file,
        [Parameter(Mandatory=$true)]$CommitID,
        [Parameter(Mandatory=$false)]$token,
        [Parameter(Mandatory=$false)]$Branch = "master"
    )
    $VERSION="64c1150"
    $url="https://codecov.io"

    $query = "package=bash-${VERSION}&token=${token}&branch=${Branch}&commit=${CommitID}&build=&build_url=&tag=&slug=&yaml=&service=&flags=&pr=&job="
    $uri = "$url/upload/v2?${query}"
    $response = Invoke-WebRequest -Method Post -InFile $file -Uri $uri

    if ( $response.StatusCode -ne 200 )
    {
        Write-LogPassThru -Message "Upload failed for upload uri: $uploaduri"
        throw "upload failed"
    }
}

Write-LogPassThru -Message "***** New Run *****"

Write-LogPassThru -Message "Forcing winrm quickconfig as it is required for remoting tests."
winrm quickconfig -force

$appVeyorUri = "https://ci.appveyor.com/api"
$project = Invoke-RestMethod -Method Get -Uri "${appVeyorUri}/projects/PowerShell/powershell-f975h"
$jobId = $project.build.jobs[0].jobId

$appVeyorBaseUri = "${appVeyorUri}/buildjobs/${jobId}/artifacts"
$codeCoverageZip = "${appVeyorBaseUri}/CodeCoverage.zip"
$testContentZip =  "${appVeyorBaseUri}/tests.zip"
$openCoverZip =    "${appVeyorBaseUri}/OpenCover.zip"

Write-LogPassThru -Message "codeCoverageZip: $codeCoverageZip"
Write-LogPassThru -Message "testcontentZip: $testContentZip"
Write-LogPassThru -Message "openCoverZip: $openCoverZip"

$outputBaseFolder = "$env:Temp\CC"
$null = New-Item -ItemType Directory -Path $outputBaseFolder -Force

$openCoverPath = "$outputBaseFolder\OpenCover"
$testRootPath = "$outputBaseFolder\tests"
$testPath = "$testRootPath\powershell"
$psBinPath = "$outputBaseFolder\PSCodeCoverage"
$openCoverTargetDirectory = "$outputBaseFolder\OpenCoverToolset"
$outputLog = "$outputBaseFolder\CodeCoverageOutput.xml"
$elevatedLogs = "$outputBaseFolder\TestResults_Elevated.xml"
$unelevatedLogs = "$outputBaseFolder\TestResults_Unelevated.xml"
$testToolsPath = "$testRootPath\tools"
$jsonFile = "$outputBaseFolder\CC.json"

try
{
    
    $prevSecProtocol = [System.Net.ServicePointManager]::SecurityProtocol

    [System.Net.ServicePointManager]::SecurityProtocol =
        [System.Net.ServicePointManager]::SecurityProtocol -bor
        [System.Security.Authentication.SslProtocols]::Tls12 -bor
        [System.Security.Authentication.SslProtocols]::Tls11

    
    Get-Process pwsh -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction Stop

    
    if(Test-Path $outputLog)
    {
        Remove-Item $outputLog -Force -ErrorAction SilentlyContinue
    }

    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    $oldProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    Write-LogPassThru -Message "Starting downloads."

    $CoverageZipFilePath = "$outputBaseFolder\PSCodeCoverage.zip"
    if(Test-Path $CoverageZipFilePath)
    {
        Remove-Item $CoverageZipFilePath -Force
    }
    Invoke-WebRequest -uri $codeCoverageZip -outfile "$outputBaseFolder\PSCodeCoverage.zip"

    $TestsZipFilePath = "$outputBaseFolder\tests.zip"
    if(Test-Path $TestsZipFilePath)
    {
        Remove-Item $TestsZipFilePath -Force
    }
    Invoke-WebRequest -uri $testContentZip -outfile $TestsZipFilePath

    $OpenCoverZipFilePath = "$outputBaseFolder\OpenCover.zip"
    if(Test-Path $OpenCoverZipFilePath)
    {
        Remove-Item $OpenCoverZipFilePath -Force
    }
    Invoke-WebRequest -uri $openCoverZip -outfile $OpenCoverZipFilePath

    Write-LogPassThru -Message "Downloads complete. Starting expansion"

    if(Test-Path $psBinPath)
    {
        Remove-Item -Force -Recurse $psBinPath
    }
    Expand-Archive -path $CoverageZipFilePath -destinationpath "$psBinPath" -Force

    if(Test-Path $testRootPath)
    {
        Remove-Item -Force -Recurse $testRootPath
    }
    Expand-Archive -path $TestsZipFilePath -destinationpath $testRootPath -Force

    if(Test-Path $openCoverPath)
    {
        Remove-Item -Force -Recurse $openCoverPath
    }
    Expand-Archive -path $OpenCoverZipFilePath -destinationpath $openCoverPath -Force
    Write-LogPassThru -Message "Expansion complete."

    if(Test-Path $elevatedLogs)
    {
        Remove-Item -Force -Recurse $elevatedLogs
    }

    if(Test-Path $unelevatedLogs)
    {
        Remove-Item -Force -Recurse $unelevatedLogs
    }

    if(Test-Path $outputLog)
    {
        Remove-Item $outputLog -Force -ErrorAction SilentlyContinue
    }

    Import-Module "$openCoverPath\OpenCover" -Force
    Install-OpenCover -TargetDirectory $openCoverTargetDirectory -force
    Write-LogPassThru -Message "OpenCover installed."

    Write-LogPassThru -Message "TestPath : $testPath"
    Write-LogPassThru -Message "openCoverPath : $openCoverTargetDirectory\OpenCover"
    Write-LogPassThru -Message "psbinpath : $psBinPath"
    Write-LogPassThru -Message "elevatedLog : $elevatedLogs"
    Write-LogPassThru -Message "unelevatedLog : $unelevatedLogs"
    Write-LogPassThru -Message "TestToolsPath : $testToolsPath"

    $openCoverParams = @{outputlog = $outputLog;
        TestPath = $testPath;
        OpenCoverPath = "$openCoverTargetDirectory\OpenCover";
        PowerShellExeDirectory = "$psBinPath";
        PesterLogElevated = $elevatedLogs;
        PesterLogUnelevated = $unelevatedLogs;
        TestToolsModulesPath = "$testToolsPath\Modules";
    }

    if($SuppressQuiet)
    {
        $openCoverParams.Add('SuppressQuiet', $true)
    }

    
    $assemblyLocation = & "$psBinPath\pwsh.exe" -noprofile -command { Get-Item ([psobject].Assembly.Location) }
    $productVersion = $assemblyLocation.VersionInfo.productVersion
    $commitId = $productVersion.split(" ")[-1]

    Write-LogPassThru -Message "Using GitCommitId: $commitId"

    
    try
    {
        $gitexe = "C:\Program Files\git\bin\git.exe"
        
        
        Push-Location $outputBaseFolder

        
        $cleanupDirectories = "${outputBaseFolder}/.git",
            "${outputBaseFolder}/src",
            "${outputBaseFolder}/assets"
        foreach($directory in $cleanupDirectories)
        {
            if ( Test-Path "$directory" )
            {
                Remove-Item -Force -Recurse "$directory"
            }
        }

        Write-LogPassThru -Message "initializing repo in $outputBaseFolder"
        & $gitexe init
        Write-LogPassThru -Message "git operation 'init' returned $LASTEXITCODE"

        Write-LogPassThru -Message "adding remote"
        & $gitexe remote add origin https://github.com/PowerShell/PowerShell
        Write-LogPassThru -Message "git operation 'remote add' returned $LASTEXITCODE"

        Write-LogPassThru -Message "setting sparse-checkout"
        & $gitexe config core.sparsecheckout true
        Write-LogPassThru -Message "git operation 'set sparse-checkout' returned $LASTEXITCODE"

        Write-LogPassThru -Message "pulling sparse repo"
        "/src" | Out-File -Encoding ascii .git\info\sparse-checkout -Force
        "/assets" | Out-File -Encoding ascii .git\info\sparse-checkout -Append
        & $gitexe pull origin master
        Write-LogPassThru -Message "git operation 'pull' returned $LASTEXITCODE"

        Write-LogPassThru -Message "checkout commit $commitId"
        & $gitexe checkout $commitId
        Write-LogPassThru -Message "git operation 'checkout' returned $LASTEXITCODE"
    }
    finally
    {
        Pop-Location
    }

    $openCoverParams | Out-String | Write-LogPassThru
    Write-LogPassThru -Message "Starting test run."

    try {
        
        Invoke-OpenCover @openCoverParams | Out-String | Write-LogPassThru
    }
    catch {
        ("ERROR: " + $_.ScriptStackTrace) | Write-LogPassThru
        $_ 2>&1 | out-string -Stream | %{ "ERROR: $_" } | Write-LogPassThru
    }

    if(Test-Path $outputLog)
    {
        Write-LogPassThru -Message (get-childitem $outputLog).FullName
    }

    Write-LogPassThru -Message "Test run done."

    Write-LogPassThru -Message $commitId

    $commitInfo = Invoke-RestMethod -Method Get "https://api.github.com/repos/powershell/powershell/git/commits/$commitId"
    $message = ($commitInfo.message).replace("`n", " ")

    Write-LogPassThru -Message "Uploading to CodeCov"
    if ( Test-Path $outputLog ) {
        ConvertTo-CodeCovJson -Path $outputLog -DestinationPath $jsonFile
        Push-CodeCovData -file $jsonFile -CommitID $commitId -token $codecovToken -Branch 'master'

        Write-LogPassThru -Message "Upload complete."
    }
    else {
        Write-LogPassThru -Message "ERROR: Could not find $outputLog - no upload"
    }
}
catch
{
    Write-LogPassThru -Message $_
}
finally
{
    
    [System.Net.ServicePointManager]::SecurityProtocol = $prevSecProtocol

    
    
    
    
    $ResolvedPSBinPath = (Resolve-Path ${psbinpath}).Path
    Get-Process PowerShell | Where-Object { $_.Path -like "*${ResolvedPSBinPath}*" } | Stop-Process -Force -ErrorAction Continue

    
    if(Test-Path $azureLogDrive)
    {
        
        $monthFolder = "{0:yyyy-MM}" -f [datetime]::Now
        $monthFolderFullPath = New-Item -Path (Join-Path $azureLogDrive $monthFolder) -ItemType Directory -Force
        $windowsFolderPath = New-Item (Join-Path $monthFolderFullPath "Windows") -ItemType Directory -Force

        $destinationPath = Join-Path $env:Temp ("CodeCoverageLogs-{0:yyyy_MM_dd}-{0:hh_mm_ss}.zip" -f [datetime]::Now)
        Compress-Archive -Path $elevatedLogs,$unelevatedLogs,$outputLog -DestinationPath $destinationPath
        Copy-Item $destinationPath $windowsFolderPath -Force -ErrorAction SilentlyContinue

        Remove-Item -Path $destinationPath -Force -ErrorAction SilentlyContinue
    }

    Write-LogPassThru -Message "**** COMPLETE ****"

    
    
    $ErrorActionPreference = $oldErrorActionPreference
    $ProgressPreference = $oldProgressPreference
}
