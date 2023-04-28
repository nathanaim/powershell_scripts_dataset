param(
    [Parameter(HelpMessage='ReleaseTag from the job.  Set to "fromBranch" or $null to update using the branch name')]
    [string]$ReleaseTag,

    [Parameter(HelpMessage='The branch name used to update the release tag.')]
    [string]$Branch=$env:BUILD_SOURCEBRANCH,

    [Parameter(HelpMessage='The variable name to put the new release tagin.')]
    [string]$Variable='ReleaseTag',

    [switch]$CreateJson
)

function New-BuildInfoJson {
    param(
        [parameter(Mandatory = $true)]
        [string]
        $ReleaseTag,
        [switch] $IsDaily
    )

    $blobName = $ReleaseTag -replace '\.', '-'

    $isPreview = $ReleaseTag -like '*-*'

    $filename = 'stable.json'
    if($isPreview)
    {
        $filename = 'preview.json'
    }
    if($IsDaily.IsPresent)
    {
        $filename = 'daily.json'
    }

    
    $dateTime = [datetime]::UtcNow
    $dateTime = [datetime]::new($dateTime.Ticks - ($dateTime.Ticks % [timespan]::TicksPerSecond), $dateTime.Kind)

    @{
        ReleaseTag = $ReleaseTag
        ReleaseDate = $dateTime
        BlobName = $blobName
    } | ConvertTo-Json | Out-File -Encoding ascii -Force -FilePath $filename

    $resolvedPath = (Resolve-Path -Path $filename).ProviderPath
    $vstsCommandString = "vso[task.setvariable variable=BuildInfoPath]$resolvedPath"
    Write-Verbose -Message "$vstsCommandString" -Verbose
    Write-Host -Object "

    Write-Host "
}





$branchOnly = $Branch -replace '^refs/heads/';
$branchOnly = $branchOnly -replace '[_\-]'

if($ReleaseTag -eq 'fromBranch' -or !$ReleaseTag)
{
    $isDaily = $false
    
    if($Branch -match '^.*(release[-/])')
    {
        Write-verbose "release branch:" -verbose
        $releaseTag = $Branch -replace '^.*(release[-/])'
        $vstsCommandString = "vso[task.setvariable variable=$Variable]$releaseTag"
        Write-Verbose -Message "setting $Variable to $releaseTag" -Verbose
        Write-Host -Object "

        if ($CreateJson.IsPresent)
        {
            New-BuildInfoJson -ReleaseTag $releaseTag
        }
    }
    elseif($branchOnly -eq 'master' -or $branchOnly -like '*dailytest*')
    {
        $isDaily = $true
        Write-verbose "daily build" -verbose
        $metaDataJsonPath = Join-Path $PSScriptRoot -ChildPath '..\metadata.json'
        $metadata = Get-content $metaDataJsonPath | ConvertFrom-Json
        $versionPart = $metadata.PreviewReleaseTag
        if($versionPart -match '-.*$')
        {
            $versionPart = $versionPart -replace '-.*$'
        }

        $releaseTag = "$versionPart-daily.$((get-date).ToString('yyyyMMdd'))"
        $vstsCommandString = "vso[task.setvariable variable=$Variable]$releaseTag"
        Write-Verbose -Message "setting $Variable to $releaseTag" -Verbose
        Write-Host -Object "

        if ($CreateJson.IsPresent)
        {
            New-BuildInfoJson -ReleaseTag $releaseTag -IsDaily
        }
    }
    else
    {
        Write-verbose "non-release branch" -verbose
        
        
        $metaDataJsonPath = Join-Path $PSScriptRoot -ChildPath '..\metadata.json'
        $metadata = Get-content $metaDataJsonPath | ConvertFrom-Json
        $versionPart = $metadata.PreviewReleaseTag
        if($versionPart -match '-.*$')
        {
            $versionPart = $versionPart -replace '-.*$'
        }

        $releaseTag = "$versionPart-$branchOnly"
        $vstsCommandString = "vso[task.setvariable variable=$Variable]$releaseTag"
        Write-Verbose -Message "setting $Variable to $releaseTag" -Verbose
        Write-Host -Object "

        if ($CreateJson.IsPresent)
        {
            New-BuildInfoJson -ReleaseTag $releaseTag
        }
    }
}

$vstsCommandString = "vso[task.setvariable variable=IS_DAILY]$($isDaily.ToString().ToLowerInvariant())"
Write-Verbose -Message "$vstsCommandString" -Verbose
Write-Host -Object "

Write-Output $releaseTag
