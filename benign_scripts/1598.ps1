



filter propmatch ([string]$match='') {
    $props = @()
    $obj = $_
    $obj | gm -m *property | % { if ($obj.$($_.name) -match $match) {$props += [string]$_.name} }
    $obj | select $props
}
