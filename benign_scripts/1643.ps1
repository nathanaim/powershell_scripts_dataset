






$comps = 1..10
$index = 0
$total = @($comps).Count
$starttime = $lasttime = Get-Date
foreach ($comp in $comps) {
    $index++
    $currtime = (Get-Date) - $starttime
    $avg = $currtime.TotalSeconds / $index
    $last = ((Get-Date) - $lasttime).TotalSeconds
    $left = $total - $index
    $WrPrgParam = @{
        Activity = (
            "<name-of-operation> $(Get-Date -f s)",
            "Total: $($currtime -replace '\..*')",
            "Avg: $('{0:N2}' -f $avg)",
            "Last: $('{0:N2}' -f $last)",
            "ETA: $('{0:N2}' -f ($avg * $left / 60))",
            "min ($([string](Get-Date).AddSeconds($avg*$left) -replace '^.* '))"
        ) -join ' '
        Status = "$index of $total ($left left) [$('{0:N2}' -f ($index / $total * 100))%]"
        CurrentOperation = "ping: $comp"
        PercentComplete = $index / $total * 100
    }
    Write-Progress @WrPrgParam
    $lasttime = Get-Date

    if (0..1 | Get-Random) {
        
        $WrPrgParam.CurrentOperation = "scanning...: $comp"
        Write-Progress @WrPrgParam
        sleep 2
    }

    Write-Host $comp
    sleep -m 3500
}

return



$comps = 1..10
$index = 0
$total = $comps.count
$sw = [System.Diagnostics.Stopwatch]::StartNew()
foreach ($comp in $comps) {
    $index++
    if ($sw.Elapsed.TotalMilliseconds -ge 2000) { 
        $WrPrgParam = @{
            Activity = "<name-of-operation> $(date -f s)"
            Status = "$index of $total ($($total - $index) left) [$('{0:N2}' -f ($index / $total * 100))%]"
            CurrentOperation = "COMP: $comp"
            PercentComplete = $index / $total * 100
        }
        Write-Progress @WrPrgParam
        $sw.Reset()
        $sw.Start()
    }

    $WrPrgParam.CurrentOperation = "COMP: $comp"
    Write-Progress @WrPrgParam
    sleep 1
}
