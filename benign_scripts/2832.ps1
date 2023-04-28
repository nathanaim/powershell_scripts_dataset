$global:psakeSwitches = @('-docs', '-task', '-properties', '-parameters')

function script:psakeSwitches($filter) {  
  $psakeSwitches | Where-Object { $_ -like "$filter*" }
}

function script:psakeDocs($filter, $file) {
  if ($file -eq $null -or $file -eq '') { $file = 'psakefile.ps1' }
  psake $file -docs | out-string -Stream | ForEach-Object { if ($_ -match "^[^ ]*") { $matches[0]} } | Where-Object { $_ -ne "Name" -and $_ -ne "----" -and $_ -like "$filter*" }
}

function script:psakeFiles($filter) {
    Get-ChildItem "$filter*.ps1" | ForEach-Object { $_.Name }
}

function PsakeTabExpansion($lastBlock) {
  switch -regex ($lastBlock) {
    '(invoke-psake|psake) ([^\.]*\.ps1)? ?.* ?\-ta?s?k? (\S*)$' { 
      psakeDocs $matches[3] $matches[2] | Sort-Object
    } 
    '(invoke-psake|psake) ([^\.]*\.ps1)? ?.* ?(\-\S*)$' { 
      psakeSwitches $matches[3] | Sort-Object
    } 
    '(invoke-psake|psake) ([^\.]*\.ps1) ?.* ?(\S*)$' { 
      @(psakeDocs $matches[3] $matches[2]) + @(psakeSwitches $matches[3]) | Sort-Object
    }
    '(invoke-psake|psake) (\S*)$' {
      @(psakeFiles $matches[2]) + @(psakeDocs $matches[2] 'psakefile.ps1') + @(psakeSwitches $matches[2]) | Sort-Object
    }
  }
}
