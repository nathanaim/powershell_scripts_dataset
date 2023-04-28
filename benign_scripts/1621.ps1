












cls

'step1', 'step2', 'step3' | % {try { rv $_ -ea stop } catch {}}

function step1 {
    cls

    $mfrs = @(
        'TOSHIBA 1'
        'TOSHIBA 2'
        'TOSHIBA 3'
        'TOSHIBA 4'
        'TOSHIBA 5'
        'TOSHIBA 6'
        'ACER 1'
        'ASUS 2'
        'HP 1'
        'HP 2'
        'HP 3'
        'HP 4'
        'HP 5'
        'HP 6'
    )

    $menuparams = @{
        Header = '----------Software/Driver Installation----------'
        Footer = '------------------------------------------------'
        Object = $mfrs
    }

    Menu @menuparams
}

function step2 ($mfr) {
    cls

    $menuparams = @{
        Header = "----------Software/Driver Installation----------`r`n`t   Choose Between Software or Driver`r`n`t`t`t`t  $mfr"
        Footer = '------------------------------------------------'
        Object = 'Software', 'Drivers', 'Go Back'
    }
    Menu @menuparams
}

function step3 {
    cls

    $packages = @(
        'Package 1'
        'Package 2'
        'Package 3'
        'Package 4'
        'Package 5'
        'Go Back'
    )

    $menuparams = @{
        Header = '----------Software/Driver Installation----------'
        Footer = 'Select a number 1 through 6 and select enter'
        Object = $packages
    }

    Menu @menuparams
}

function step4 ($pkg) {
    cls
        
    Write-Host "You chose to install $pkg"

    switch ($pkg) {
        'Package 1' {
            Write-Host Invoke-Item '\\network path 1'
        }
        
        'Package 2' {
            Write-Host Invoke-Item '\\network path 2'
        }
        
        'Package 3' {
            Write-Host Invoke-Item '\\network path 3'
        }
        
        'Package 4' {
            Write-Host Invoke-Item '\\network path 4'
        }
        
        'Package 5' {
            Write-Host Invoke-Item '\\network path 5'
        }

        default { Write-Warning "$pkg does not exist!" }
    }
}



do {
    if (!$step3 -or $step3 -eq 'Go Back') {
        do {
            if (!$step2 -or $step2 -eq 'Go Back') {
                $step1 = step1
            }
            $step2 = step2 -mfr $step1
        } while ($step2 -eq 'Go Back')
    }
    $step3 = step3
} while ($step3 -eq 'Go Back')

cls

$selection = [pscustomobject]@{
    MFG = $step1
    Install = $step2
    Package = $step3
}

Write-Object -Header 'You have selected:' -Object $selection

$continue = Menu -Header '----------Software/Driver Installation----------' -Footer '----- Continue? -----' -Object 'Yes', 'No'

if ($continue.ToLower()[0] -eq 'n') {
    return
}

step4 $selection.Package

