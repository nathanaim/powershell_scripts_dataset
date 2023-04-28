



function Get-GitDirectory {
    $pathInfo = Microsoft.PowerShell.Management\Get-Location
    if (!$pathInfo -or ($pathInfo.Provider.Name -ne 'FileSystem')) {
        $null
    }
    elseif ($Env:GIT_DIR) {
        $Env:GIT_DIR -replace '\\|/', [System.IO.Path]::DirectorySeparatorChar
    }
    else {
        $currentDir = Get-Item -LiteralPath $pathInfo -Force
        while ($currentDir) {
            $gitDirPath = Join-Path $currentDir.FullName .git
            if (Test-Path -LiteralPath $gitDirPath -PathType Container) {
                return $gitDirPath
            }

            
            if (Test-Path -LiteralPath $gitDirPath -PathType Leaf) {
                $gitDirPath = Invoke-Utf8ConsoleCommand { git rev-parse --git-dir 2>$null }
                if ($gitDirPath) {
                    return $gitDirPath
                }
            }

            $headPath = Join-Path $currentDir.FullName HEAD
            if (Test-Path -LiteralPath $headPath -PathType Leaf) {
                $refsPath = Join-Path $currentDir.FullName refs
                $objsPath = Join-Path $currentDir.FullName objects
                if ((Test-Path -LiteralPath $refsPath -PathType Container) -and
                    (Test-Path -LiteralPath $objsPath -PathType Container)) {

                    $bareDir = Invoke-Utf8ConsoleCommand { git rev-parse --git-dir 2>$null }
                    if ($bareDir -and (Test-Path -LiteralPath $bareDir -PathType Container)) {
                        $resolvedBareDir = (Resolve-Path $bareDir).Path
                        return $resolvedBareDir
                    }
                }
            }

            $currentDir = $currentDir.Parent
        }
    }
}

function Get-GitBranch($gitDir = $(Get-GitDirectory), [Diagnostics.Stopwatch]$sw) {
    if (!$gitDir) { return }

    Invoke-Utf8ConsoleCommand {
        dbg 'Finding branch' $sw
        $r = ''; $b = ''; $c = ''
        $step = ''; $total = ''
        if (Test-Path $gitDir/rebase-merge) {
            dbg 'Found rebase-merge' $sw
            if (Test-Path $gitDir/rebase-merge/interactive) {
                dbg 'Found rebase-merge/interactive' $sw
                $r = '|REBASE-i'
            }
            else {
                $r = '|REBASE-m'
            }
            $b = "$(Get-Content $gitDir/rebase-merge/head-name)"
            $step = "$(Get-Content $gitDir/rebase-merge/msgnum)"
            $total = "$(Get-Content $gitDir/rebase-merge/end)"
        }
        else {
            if (Test-Path $gitDir/rebase-apply) {
                dbg 'Found rebase-apply' $sw
                $step = "$(Get-Content $gitDir/rebase-apply/next)"
                $total = "$(Get-Content $gitDir/rebase-apply/last)"

                if (Test-Path $gitDir/rebase-apply/rebasing) {
                    dbg 'Found rebase-apply/rebasing' $sw
                    $r = '|REBASE'
                }
                elseif (Test-Path $gitDir/rebase-apply/applying) {
                    dbg 'Found rebase-apply/applying' $sw
                    $r = '|AM'
                }
                else {
                    $r = '|AM/REBASE'
                }
            }
            elseif (Test-Path $gitDir/MERGE_HEAD) {
                dbg 'Found MERGE_HEAD' $sw
                $r = '|MERGING'
            }
            elseif (Test-Path $gitDir/CHERRY_PICK_HEAD) {
                dbg 'Found CHERRY_PICK_HEAD' $sw
                $r = '|CHERRY-PICKING'
            }
            elseif (Test-Path $gitDir/REVERT_HEAD) {
                dbg 'Found REVERT_HEAD' $sw
                $r = '|REVERTING'
            }
            elseif (Test-Path $gitDir/BISECT_LOG) {
                dbg 'Found BISECT_LOG' $sw
                $r = '|BISECTING'
            }

            $b = Invoke-NullCoalescing `
                { dbg 'Trying symbolic-ref' $sw; git symbolic-ref HEAD -q 2>$null } `
                { '({0})' -f (Invoke-NullCoalescing `
                    {
                        dbg 'Trying describe' $sw
                        switch ($Global:GitPromptSettings.DescribeStyle) {
                            'contains' { git describe --contains HEAD 2>$null }
                            'branch' { git describe --contains --all HEAD 2>$null }
                            'describe' { git describe HEAD 2>$null }
                            default { git tag --points-at HEAD 2>$null }
                        }
                    } `
                    {
                        dbg 'Falling back on parsing HEAD' $sw
                        $ref = $null

                        if (Test-Path $gitDir/HEAD) {
                            dbg 'Reading from .git/HEAD' $sw
                            $ref = Get-Content $gitDir/HEAD 2>$null
                        }
                        else {
                            dbg 'Trying rev-parse' $sw
                            $ref = git rev-parse HEAD 2>$null
                        }

                        if ($ref -match 'ref: (?<ref>.+)') {
                            return $Matches['ref']
                        }
                        elseif ($ref -and $ref.Length -ge 7) {
                            return $ref.Substring(0,7)+'...'
                        }
                        else {
                            return 'unknown'
                        }
                    }
                ) }
        }

        dbg 'Inside git directory?' $sw
        if ('true' -eq $(git rev-parse --is-inside-git-dir 2>$null)) {
            dbg 'Inside git directory' $sw
            if ('true' -eq $(git rev-parse --is-bare-repository 2>$null)) {
                $c = 'BARE:'
            }
            else {
                $b = 'GIT_DIR!'
            }
        }

        if ($step -and $total) {
            $r += " $step/$total"
        }

        "$c$($b -replace 'refs/heads/','')$r"
    }
}

function GetUniquePaths($pathCollections) {
    $hash = New-Object System.Collections.Specialized.OrderedDictionary

    foreach ($pathCollection in $pathCollections) {
        foreach ($path in $pathCollection) {
            $hash[$path] = 1
        }
    }

    $hash.Keys
}

$castStringSeq = [Linq.Enumerable].GetMethod("Cast").MakeGenericMethod([string])


function Get-GitStatus {
    param(
        
        
        [Parameter(Position=0)]
        $GitDir = (Get-GitDirectory),

        
        
        [Parameter()]
        [switch]
        $Force
    )

    $settings = $Global:GitPromptSettings
    $enabled = $Force -or !$settings -or $settings.EnablePromptStatus
    if ($enabled -and $GitDir) {
        if ($settings.Debug) {
            $sw = [Diagnostics.Stopwatch]::StartNew(); Write-Host ''
        }
        else {
            $sw = $null
        }

        $branch = $null
        $aheadBy = 0
        $behindBy = 0
        $gone = $false
        $indexAdded = New-Object System.Collections.Generic.List[string]
        $indexModified = New-Object System.Collections.Generic.List[string]
        $indexDeleted = New-Object System.Collections.Generic.List[string]
        $indexUnmerged = New-Object System.Collections.Generic.List[string]
        $filesAdded = New-Object System.Collections.Generic.List[string]
        $filesModified = New-Object System.Collections.Generic.List[string]
        $filesDeleted = New-Object System.Collections.Generic.List[string]
        $filesUnmerged = New-Object System.Collections.Generic.List[string]
        $stashCount = 0

        if ($settings.EnableFileStatus -and !$(InDotGitOrBareRepoDir $GitDir) -and !$(InDisabledRepository)) {
            if ($null -eq $settings.EnableFileStatusFromCache) {
                $settings.EnableFileStatusFromCache = $null -ne (Get-Module GitStatusCachePoshClient)
            }

            if ($settings.EnableFileStatusFromCache) {
                dbg 'Getting status from cache' $sw
                $cacheResponse = Get-GitStatusFromCache
                dbg 'Parsing status' $sw

                $indexAdded.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.IndexAdded))))
                $indexModified.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.IndexModified))))
                foreach ($indexRenamed in $cacheResponse.IndexRenamed) {
                    $indexModified.Add($indexRenamed.Old)
                }
                $indexDeleted.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.IndexDeleted))))
                $indexUnmerged.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.Conflicted))))

                $filesAdded.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.WorkingAdded))))
                $filesModified.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.WorkingModified))))
                foreach ($workingRenamed in $cacheResponse.WorkingRenamed) {
                    $filesModified.Add($workingRenamed.Old)
                }
                $filesDeleted.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.WorkingDeleted))))
                $filesUnmerged.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.Conflicted))))

                $branch = $cacheResponse.Branch
                $upstream = $cacheResponse.Upstream
                $gone = $cacheResponse.UpstreamGone
                $aheadBy = $cacheResponse.AheadBy
                $behindBy = $cacheResponse.BehindBy

                if ($cacheResponse.Stashes) { $stashCount = $cacheResponse.Stashes.Length }
                if ($cacheResponse.State) { $branch += "|" + $cacheResponse.State }
            }
            else {
                dbg 'Getting status' $sw
                switch ($settings.UntrackedFilesMode) {
                    "No"      { $untrackedFilesOption = "-uno" }
                    "All"     { $untrackedFilesOption = "-uall" }
                    "Normal"  { $untrackedFilesOption = "-unormal" }
                }
                $status = Invoke-Utf8ConsoleCommand { git -c core.quotepath=false -c color.status=false status $untrackedFilesOption --short --branch 2>$null }
                if ($settings.EnableStashStatus) {
                    dbg 'Getting stash count' $sw
                    $stashCount = $null | git stash list 2>$null | measure-object | Select-Object -expand Count
                }

                dbg 'Parsing status' $sw
                switch -regex ($status) {
                    '^(?<index>[^
                        if ($sw) { dbg "Status: $_" $sw }

                        switch ($matches['index']) {
                            'A' { $null = $indexAdded.Add($matches['path1']); break }
                            'M' { $null = $indexModified.Add($matches['path1']); break }
                            'R' { $null = $indexModified.Add($matches['path1']); break }
                            'C' { $null = $indexModified.Add($matches['path1']); break }
                            'D' { $null = $indexDeleted.Add($matches['path1']); break }
                            'U' { $null = $indexUnmerged.Add($matches['path1']); break }
                        }
                        switch ($matches['working']) {
                            '?' { $null = $filesAdded.Add($matches['path1']); break }
                            'A' { $null = $filesAdded.Add($matches['path1']); break }
                            'M' { $null = $filesModified.Add($matches['path1']); break }
                            'D' { $null = $filesDeleted.Add($matches['path1']); break }
                            'U' { $null = $filesUnmerged.Add($matches['path1']); break }
                        }
                        continue
                    }

                    '^
                        if ($sw) { dbg "Status: $_" $sw }

                        $branch = $matches['branch']
                        $upstream = $matches['upstream']
                        $aheadBy = [int]$matches['ahead']
                        $behindBy = [int]$matches['behind']
                        $gone = [string]$matches['gone'] -eq 'gone'
                        continue
                    }

                    '^
                        if ($sw) { dbg "Status: $_" $sw }

                        $branch = $matches['branch']
                        continue
                    }

                    default { if ($sw) { dbg "Status: $_" $sw } }
                }
            }
        }

        if (!$branch) { $branch = Get-GitBranch $GitDir $sw }

        dbg 'Building status object' $sw

        
        $filesAdded = $filesAdded.ToArray()

        $indexPaths = @(GetUniquePaths $indexAdded,$indexModified,$indexDeleted,$indexUnmerged)
        $workingPaths = @(GetUniquePaths $filesAdded,$filesModified,$filesDeleted,$filesUnmerged)
        $index = (,$indexPaths) |
            Add-Member -Force -PassThru NoteProperty Added    $indexAdded.ToArray() |
            Add-Member -Force -PassThru NoteProperty Modified $indexModified.ToArray() |
            Add-Member -Force -PassThru NoteProperty Deleted  $indexDeleted.ToArray() |
            Add-Member -Force -PassThru NoteProperty Unmerged $indexUnmerged.ToArray()

        $working = (,$workingPaths) |
            Add-Member -Force -PassThru NoteProperty Added    $filesAdded |
            Add-Member -Force -PassThru NoteProperty Modified $filesModified.ToArray() |
            Add-Member -Force -PassThru NoteProperty Deleted  $filesDeleted.ToArray() |
            Add-Member -Force -PassThru NoteProperty Unmerged $filesUnmerged.ToArray()

        $result = New-Object PSObject -Property @{
            GitDir          = $GitDir
            RepoName        = Split-Path (Split-Path $GitDir -Parent) -Leaf
            Branch          = $branch
            AheadBy         = $aheadBy
            BehindBy        = $behindBy
            UpstreamGone    = $gone
            Upstream        = $upstream
            HasIndex        = [bool]$index
            Index           = $index
            HasWorking      = [bool]$working
            Working         = $working
            HasUntracked    = [bool]$filesAdded
            StashCount      = $stashCount
        }

        dbg 'Finished' $sw
        if ($sw) { $sw.Stop() }
        return $result
    }
}

function InDisabledRepository {
    $currentLocation = Get-Location

    foreach ($repo in $Global:GitPromptSettings.RepositoriesInWhichToDisableFileStatus) {
        if ($currentLocation -like "$repo*") {
            return $true
        }
    }

    return $false
}

function InDotGitOrBareRepoDir([string][ValidateNotNullOrEmpty()]$GitDir) {
    
    
    
    
    $pathInfo = Microsoft.PowerShell.Management\Get-Location
    $currentPath = if ($pathInfo.Drive) { $pathInfo.Path } else { $pathInfo.ProviderPath }
    $res = $currentPath.StartsWith($GitDir, (Get-PathStringComparison))
    $res
}

function Get-AliasPattern($cmd) {
    $aliases = @($cmd) + @(Get-Alias | Where-Object { $_.Definition -eq $cmd } | Select-Object -Exp Name)
   "($($aliases -join '|'))"
}


function Remove-GitBranch {
    [CmdletBinding(DefaultParameterSetName="Wildcard", SupportsShouldProcess, ConfirmImpact="Medium")]
    param(
        
        [Parameter(Position=0, Mandatory, ParameterSetName="Wildcard")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        
        [Parameter(Position=0, Mandatory, ParameterSetName="Pattern")]
        [ValidateNotNull()]
        [string]
        $Pattern,

        
        [Parameter()]
        [ValidateNotNull()]
        [string]
        $ExcludePattern = '(^\*)|(^. (develop|master)$)',

        
        [Parameter()]
        [string]
        $Commit = "HEAD",

        
        [Parameter()]
        [switch]
        $IncludeUnmerged,

        
        [Parameter()]
        [switch]
        $Force,

        
        [Parameter()]
        [switch]
        $DeleteForce
    )

    if ($IncludeUnmerged) {
        $branches = git branch
    }
    else {
        $branches = git branch --merged $Commit
    }

    $filteredBranches = $branches | Where-Object {$_ -notmatch $ExcludePattern }

    if ($PSCmdlet.ParameterSetName -eq "Wildcard") {
        $branchesToDelete = $filteredBranches | Where-Object { $_.Trim() -like $Name }
    }
    else {
        $branchesToDelete = $filteredBranches | Where-Object { $_ -match $Pattern }
    }

    $action = if ($DeleteForce) { "delete with force"} else { "delete" }
    $yesToAll = $noToAll = $false

    foreach ($branch in $branchesToDelete) {
        $targetBranch = $branch.Trim()
        if ($PSCmdlet.ShouldProcess($targetBranch, $action)) {
            if ($Force -or $yesToAll -or
                $PSCmdlet.ShouldContinue("Are you REALLY sure you want to $action `"$targetBranch`"?",
                                         "Confirm branch deletion", [ref]$yesToAll, [ref]$noToAll)) {

                if ($noToAll) { return }

                if ($DeleteForce) {
                    Invoke-Utf8ConsoleCommand { git branch --delete --force $targetBranch }
                }
                else {
                    Invoke-Utf8ConsoleCommand { git branch --delete $targetBranch }
                }
            }
        }
    }
}

function Update-AllBranches($Upstream = 'master', [switch]$Quiet) {
    $head = git rev-parse --abbrev-ref HEAD
    git checkout -q $Upstream
    $branches = Invoke-Utf8ConsoleCommand { (git branch --no-color --no-merged) } | Where-Object { $_ -notmatch '^\* ' }
    foreach ($line in $branches) {
        $branch = $line.SubString(2)
        if (!$Quiet) { Write-Host "Rebasing $branch onto $Upstream..." }

        git rebase -q $Upstream $branch > $null 2> $null
        if ($LASTEXITCODE) {
            git rebase --abort
            Write-Warning "Rebase failed for $branch"
        }
    }

    git checkout -q $head
}
