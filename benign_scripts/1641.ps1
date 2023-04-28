



function Get-MAC ($comp = $env:computername) {
    $ping = New-Object System.Net.NetworkInformation.Ping
    $result = $ping.Send($comp)
    if ($result.Status -eq 'Success') {
        $ip = $result.Address
        $port = 137
        $ipEP = New-Object System.Net.IPEndPoint ([ipaddress]::Parse($ip), $port)
        $udpconn = New-Object System.Net.Sockets.UdpClient
        [byte[]]$sendbytes = 0xf4,0x53,00,00,00,01,00,00,00,00,00,00,0x20,0x43,0x4b,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,00,00,0x21,00,01
        $udpconn.Client.ReceiveTimeout = 1000
        $bytesSent = $udpconn.Send($sendbytes, 50, $ipEP)
        $rcvbytes = $udpconn.Receive([ref]$ipEP)

        $mac = 0,0,0,0,0,0
        $j = 5
        for ($i = $rcvbytes.length - 1; $i -gt 0; $i--) {
            if ($rcvbytes[$i] -ne 0x0) {
                $mac[$j] = $rcvbytes[$i]
                $j--
                if ($j -eq -1) { $i = -1 }
            }
        }

        $macstring = New-Object System.Text.StringBuilder
        foreach ($byte in $mac) {
            [void]$macstring.Append(('{0:X2}' -f $byte) + '-')
        }

        [pscustomobject]@{
            Computer = $comp
            IP = $ip
            MacAddress = $macstring.ToString().Trim('-')
        }
    }
}



