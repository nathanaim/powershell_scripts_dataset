

Describe "Test restricted language check method on scriptblocks" -Tags "CI" {
        BeforeAll {
            set-strictmode -v 2
            function list {

            $l = [System.Collections.Generic.List[String]]::new()
            $args | ForEach-Object {$l.Add($_)}
            , $l
            }
        }
        AfterAll {
            Set-StrictMode -Off
        }

        It 'Check basic expressions' {

            {{2+2}.CheckRestrictedLanguage($null, $null, $false) } | Should -Not -Throw  
        }

        It 'Check default variables' {

            {{ $PSCulture, $PSUICulture, $true, $false, $null}.CheckRestrictedLanguage($null, $null, $false) } | Should -Not -Throw
        }

        It 'Check default variables' {
            { {2+$a}.CheckRestrictedLanguage($null, $null, $false) } | Should -Throw -ErrorId 'ParseException'
        }

        It 'Check union of default + one allowed variables' {

            { { 2 + $a }.CheckRestrictedLanguage($null, (list a), $false) }| Should -Not -Throw  
        }

        It 'Check union of default + two allowed variables' {

            { { $a + $b }.CheckRestrictedLanguage($null, (list a b), $false) } | Should -Not -Throw  
        }

        It 'Check union of default + allowed variables' {

            { { $PSCulture, $PSUICulture, $true, $false, $null,  $a, $b}.CheckRestrictedLanguage($null, (list a b), $false) }| Should -Not -Throw
        }

        It 'Check union of default + one disallowed variables' {
            { { $a + $b + $c }.CheckRestrictedLanguage($null, (list a b), $false) } | Should -Throw -ErrorId 'ParseException'
        }

        It 'Check union of default + one allowed variable and but not allow environment variable' {
            { { 2 + $a + $env:foo }.CheckRestrictedLanguage($null, (list a), $false) } | Should -Throw -ErrorId 'ParseException'
        }

        It 'Check union of default + one allowed variable name and allow environment variable ' {

            {{ 2 + $a + $env:foo }.CheckRestrictedLanguage($null, (list a), $true)}   | Should -Not -Throw 
        }

        It 'Check that wildcard allows env even if the flag is set to false' {

            { { 2 + $a + $b + $c + $env:foo }.CheckRestrictedLanguage($null, (list *), $false)} | Should -Not -Throw   
        }

        It 'Check for restricted commands' {
            { {get-date}.CheckRestrictedLangauge($null, $null, $false) } | Should -Throw -ErrorId 'MethodNotFound'
        }

        It 'Check for allowed commands and variables' {

            { { get-process | where name -Match $pattern | foreach $prop }.CheckRestrictedLanguage(
                (list get-process where foreach),
                (list prop pattern)
                , $false) }| Should -Not -Throw
        }
}
