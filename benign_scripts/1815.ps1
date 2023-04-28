





$computerInfoAll = $null
$testStartTime = Get-Date

function Get-ComputerInfoForTest
{
    
    param([string[]] $properties = $null, [switch] $forceRefresh)

    
    
    if ( ! $IsWindows )
    {
        return $null
    }

    $computerInfo = $null
    if ( $properties )
    {
        return Get-ComputerInfo -Property $properties
    }
    else
    {
        
        if ( $forceRefresh -or $null -eq $script:computerInfoAll)
        {
            $script:computerInfoAll = Get-ComputerInfo
        }
        return $script:computerInfoAll
    }
}

function Get-StringValuesFromValueMap
{
    param([string[]] $values, [hashtable] $valuemap)

    [string] $stringValues = [string]::Empty

    foreach ($value in $values)
    {
        if ($stringValues -ne [string]::Empty)
        {
            $stringValues += ","
        }
        $stringValues += $valuemap[$value]
    }
    $stringValues
}

function Get-PropertyNamesForComputerInfoTest
{
    $propertyNames = @()

    $propertyNames += @("BiosBIOSVersion",
        "BiosBuildNumber",
        "BiosCaption",
        "BiosCharacteristics",
        "BiosCodeSet",
        "BiosCurrentLanguage",
        "BiosDescription",
        "BiosEmbeddedControllerMajorVersion",
        "BiosEmbeddedControllerMinorVersion",
        "BiosFirmwareType",
        "BiosIdentificationCode",
        "BiosInstallableLanguages",
        "BiosInstallDate",
        "BiosLanguageEdition",
        "BiosListOfLanguages",
        "BiosManufacturer",
        "BiosName",
        "BiosOtherTargetOS",
        "BiosPrimaryBIOS",
        "BiosReleaseDate",
        "BiosSerialNumber",
        "BiosSMBIOSBIOSVersion",
        "BiosSMBIOSPresent",
        "BiosSMBIOSMajorVersion",
        "BiosSMBIOSMinorVersion",
        "BiosSoftwareElementState",
        "BiosStatus",
        "BiosTargetOperatingSystem",
        "BiosVersion")

    $propertyNames += @("CsAdminPasswordStatus",
        "CsAutomaticManagedPagefile",
        "CsAutomaticResetBootOption",
        "CsAutomaticResetCapability",
        "CsBootOptionOnLimit",
        "CsBootOptionOnWatchDog",
        "CsBootROMSupported",
        "CsBootStatus",
        "CsBootupState",
        "CsCaption",
        "CsChassisBootupState",
        "CsChassisSKUNumber",
        "CsCurrentTimeZone",
        "CsDaylightInEffect",
        "CsDescription",
        "CsDNSHostName",
        "CsDomain",
        "CsDomainRole",
        "CsEnableDaylightSavingsTime",
        "CsFrontPanelResetStatus",
        "CsHypervisorPresent",
        "CsInfraredSupported",
        "CsInitialLoadInfo",
        "CsInstallDate",
        "CsKeyboardPasswordStatus",
        "CsLastLoadInfo",
        "CsManufacturer",
        "CsModel",
        "CsName",
        "CsNetworkAdapters",
        "CsNetworkServerModeEnabled",
        "CsNumberOfLogicalProcessors",
        "CsNumberOfProcessors",
        "CsOEMStringArray",
        "CsPartOfDomain",
        "CsPauseAfterReset",
        "CsPCSystemType",
        "CsPCSystemTypeEx",
        "CsPhysicallyInstalledMemory",
        "CsPowerManagementCapabilities",
        "CsPowerManagementSupported",
        "CsPowerOnPasswordStatus",
        "CsPowerState",
        "CsPowerSupplyState",
        "CsPrimaryOwnerContact",
        "CsPrimaryOwnerName",
        "CsProcessors",
        "CsResetCapability",
        "CsResetCount",
        "CsResetLimit",
        "CsRoles",
        "CsStatus",
        "CsSupportContactDescription",
        "CsSystemFamily",
        "CsSystemSKUNumber",
        "CsSystemType",
        "CsThermalState",
        "CsTotalPhysicalMemory",
        "CsUserName",
        "CsWakeUpType",
        "CsWorkgroup")

    $propertyNames += @("HyperVisorPresent",
        "HyperVRequirementDataExecutionPreventionAvailable",
        "HyperVRequirementSecondLevelAddressTranslation",
        "HyperVRequirementVirtualizationFirmwareEnabled",
        "HyperVRequirementVMMonitorModeExtensions")

    $propertyNames += @("OsArchitecture",
        "OsBootDevice",
        "OsBuildNumber",
        "OsBuildType",
        "OsCodeSet",
        "OsCountryCode",
        "OsCSDVersion",
        "OsCurrentTimeZone",
        "OsDataExecutionPrevention32BitApplications",
        "OsDataExecutionPreventionAvailable",
        "OsDataExecutionPreventionDrivers",
        "OsDataExecutionPreventionSupportPolicy",
        "OsDebug",
        "OsDistributed",
        "OsEncryptionLevel",
        "OsForegroundApplicationBoost",
        "OsHardwareAbstractionLayer",
        "OsHotFixes",
        "OsInstallDate",
        "OsLanguage",
        "OsLastBootUpTime",
        "OsLocale",
        "OsLocaleID",
        "OsManufacturer",
        "OsMaxProcessMemorySize",
        "OsMuiLanguages",
        "OsName",
        "OsNumberOfLicensedUsers",
        "OsNumberOfUsers",
        "OsOperatingSystemSKU",
        "OsOrganization",
        "OsOtherTypeDescription",
        "OsPAEEnabled",
        "OsPagingFiles",
        "OsPortableOperatingSystem",
        "OsPrimary",
        "OsProductSuites",
        "OsProductType",
        "OsRegisteredUser",
        "OsSerialNumber",
        "OsServerLevel",
        "OsServicePackMajorVersion",
        "OsServicePackMinorVersion",
        "OsSizeStoredInPagingFiles",
        "OsStatus",
        "OsSuites",
        "OsSystemDevice",
        "OsSystemDirectory",
        "OsSystemDrive",
        "OsTotalSwapSpaceSize",
        "OsTotalVirtualMemorySize",
        "OsTotalVisibleMemorySize",
        "OsType",
        "OsVersion",
        "OsWindowsDirectory")

    $propertyNames += @("KeyboardLayout",
        "LogonServer",
        "PowerPlatformRole",
        "TimeZone")

    $WindowsPropertyArray = @("WindowsBuildLabEx",
        "WindowsCurrentVersion",
        "WindowsEditionId",
        "WindowsInstallationType",
        "WindowsProductId",
        "WindowsProductName",
        "WindowsRegisteredOrganization",
        "WindowsRegisteredOwner",
        "WindowsSystemRoot",
        "WindowsVersion",
        "WindowsUBR")

    if ([System.Management.Automation.Platform]::IsIoT)
    {
        Write-Verbose -Verbose -Message "WindowsInstallDateFromRegistry is not supported on IoT."
    }
    else
    {
        $WindowsPropertyArray += "WindowsInstallDateFromRegistry"
    }

    $propertyNames += $WindowsPropertyArray

    return $propertyNames
}

function New-ExpectedComputerInfo
{
    param([string[]]$propertyNames)

    
    if ( ! $IsWindows )
    {
        $expected = New-Object -TypeName PSObject
        foreach ($propertyName in [string[]]$propertyNames)
        {
            Add-Member -MemberType NoteProperty -Name $propertyName -Value $null -InputObject $expected
        }
        return $expected
    }

    
    function Get-FirmwareType
    {
$signature = @"
[DllImport("kernel32.dll")]
public static extern bool GetFirmwareType(ref uint firmwareType);
"@
        Add-Type -MemberDefinition $signature -Name "Win32BiosFirmwareType" -Namespace Win32Functions -PassThru
    }

    function Get-PhysicallyInstalledSystemMemory
    {
$signature = @"
[DllImport("kernel32.dll")]
[return: MarshalAs(UnmanagedType.Bool)]
public static extern bool GetPhysicallyInstalledSystemMemory(out ulong MemoryInKilobytes);
"@
        Add-Type -MemberDefinition $signature -Name "Win32PhyicallyInstalledMemory" -Namespace Win32Functions -PassThru
    }

    function Get-PhysicallyInstalledSystemMemoryCore
    {
$signature = @"
[DllImport("api-ms-win-core-sysinfo-l1-2-1.dll")]
[return: MarshalAs(UnmanagedType.Bool)]
public static extern bool GetPhysicallyInstalledSystemMemory(out ulong MemoryInKilobytes);
"@
        Add-Type -MemberDefinition $signature -Name "Win32PhyicallyInstalledMemory" -Namespace Win32Functions -PassThru
    }

    function Get-PowerDeterminePlatformRole
    {
$signature = @"
[DllImport("Powrprof", EntryPoint = "PowerDeterminePlatformRoleEx", CharSet = CharSet.Ansi)]
public static extern uint PowerDeterminePlatformRoleEx(uint version);
"@
        Add-Type -MemberDefinition $signature -Name "Win32PowerDeterminePlatformRole" -Namespace Win32Functions -PassThru
    }

    function Get-LCIDToLocaleName
    {
$signature = @"
[DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern int LCIDToLocaleName(uint localeID, System.Text.StringBuilder localeName, int localeNameSize, int flags);
"@
        Add-Type -MemberDefinition $signature -Name "Win32LCIDToLocaleNameDllName" -Namespace Win32Functions -PassThru
    }

    

    
    function Get-BiosFirmwareType
    {
        [int]$firmwareType = 0
        $null = (Get-FirmwareType)::GetFirmwareType([ref]$firmwareType)
        return $firmwareType
    }

    function Get-CsPhysicallyInstalledSystemMemory
    {
        param([bool]$isCore = $false)

        
        
        [int] $memoryInKilobytes = 0
        if ($isCore)
        {
            $null = (Get-PhysicallyInstalledSystemMemoryCore)::GetPhysicallyInstalledSystemMemory([ref]$memoryInKilobytes)
        }
        else
        {
            $null = (Get-PhysicallyInstalledSystemMemory)::GetPhysicallyInstalledSystemMemory([ref]$memoryInKilobytes)
        }

        return $memoryInKilobytes
    }

    function Get-PowerPlatformRole
    {
        $version = 0x2
        $powerRole = (Get-PowerDeterminePlatformRole)::PowerDeterminePlatformRoleEx($version)
        if ($powerRole -gt 9)
        {
            $powerRole = 0
        }
        return $powerRole
    }
    

    $cimClassList = @{}
    function Get-CimClass
    {
        param([string]$className, [string] $namespace = "root\cimv2")

        if (-not $cimClassList.ContainsKey($className))
        {
            $cimClassInstance = Get-CimInstance -ClassName $className -Namespace $namespace
            $cimClassList.Add($className, $cimClassInstance)
        }

        return $cimClassList.Get_Item($className)
    }

    function Get-CimClassPropVal
    {
        param([string]$className, [string]$propertyName, [string] $namespace = "root\cimv2")

        $cimClassInstance = Get-CimClass $className $namespace
        $cimClassInstance.$propertyName
    }

    function Get-CsNetworkAdapters
    {
        $networkAdapters = @()

        $adapters = Get-CimClass Win32_NetworkAdapter
        $configs = Get-CimClass Win32_NetworkAdapterConfiguration
        
        if (!$adapters -or !$configs) { return $null }

        
        $configHash = @{}
        foreach ($config in $configs)
        {
            if ($null -ne $config.Index)
            {
                $configHash.Add([string]$config.Index,$config)
            }
        }
        
        if ($configHash.Count -eq 0)  { return $null }

        foreach ($adapter in $adapters)
        {
            
            if (!$adapter.NetConnectionStatus) { continue }

            
            if (!$configHash.ContainsKey([string]$adapter.Index))  { continue }

            $connectionStatus = 13 
            if ($adapter.NetConnectionStatus) { $connectionStatus = $adapter.NetConnectionStatus}

            $config =$configHash.Item([string]$adapter.Index)

            $dHCPEnabled = $null
            $dHCPServer = $null
            $ipAddresses = $null
            if ($connectionStatus -eq 2) 
            {
                $dHCPEnabled = $config.DHCPEnabled
                $dHCPServer = $config.DHCPServer;
                $ipAddresses = $config.IPAddress;
            }

            
            $properties =
                @{
                    'Description'=$adapter.Description;
                    'ConnectionID'=$adapter.NetConnectionID;
                    'ConnectionStatus' = $connectionStatus;
                    'DHCPEnabled' = $dHCPEnabled;
                    'DHCPServer' = $dHCPServer;
                    'IPAddresses' = $ipAddresses;

                }
            $networkAdapter = New-Object -TypeName PSObject -Prop $properties

            
            $networkAdapters += $networkAdapter
        }
        return $networkAdapters
    }

    function Get-CsProcessors
    {
        $processors = Get-CimClass Win32_Processor
        if (!$processors) {return $null }
        $csProcessors = @()
        foreach ($processor in $processors)
        {
            
            $properties =
                @{
                    'Name'=$processor.Name;
                    'Manufacturer'=$processor.Manufacturer;
                    'Description'=$processor.Description;
                    'Architecture'=$processor.Architecture;
                    'AddressWidth'=$processor.AddressWidth;

                    'Availability'=$processor.Availability;
                    'CpuStatus'=$processor.CpuStatus;
                    'CurrentClockSpeed'=$processor.CurrentClockSpeed;
                    'DataWidth'=$processor.DataWidth;

                    'MaxClockSpeed'=$processor.MaxClockSpeed;
                    'NumberOfCores'=$processor.NumberOfCores;
                    'NumberOfLogicalProcessors'=$processor.NumberOfLogicalProcessors;
                    'ProcessorID'=$processor.ProcessorID;
                    'ProcessorType'=$processor.ProcessorType;
                    'Role'=$processor.Role;
                    'SocketDesignation'=$processor.SocketDesignation;
                    'Status'=$processor.Status;
                }
            $csProcessor = New-Object -TypeName PSObject -Prop $properties

            
            $csProcessors += $csProcessor
        }
        $csProcessors
    }

    function Get-OsHardwareAbstractionLayer
    {
        $hal = $null
        $systemDirectory =  Get-CimClassPropVal Win32_OperatingSystem SystemDirectory
        $halPath = Join-Path -path $systemDirectory -ChildPath "hal.dll"
        $query = 'SELECT * FROM CIM_DataFile Where Name="C:\WINDOWS\system32\hal.dll"'
        $query = $query -replace '\\','\\'
        $instance = Get-CimInstance -Query $query
        if ($instance)
        {
            $hal = [string]$instance[0].CimInstanceProperties["Version"].Value
        }
        return $hal
    }

    function Get-OsHotFixes
    {
        $hotfixes = Get-CimClass Win32_QuickFixEngineering | Select-Object -Property HotFixID,Description,InstalledOn,FixComments
        if (!$hotfixes) {return $null }

        $osHotFixes = @()

        foreach ($hotfix in $hotfixes)
        {
            $installedOn = $null
            if ($hotfix.InstalledOn)
            {
                $installedOn = $hotfix.InstalledOn.ToString("M/d/yyyy")
            }
            
            $properties =
                @{
                    'HotFixID'=$hotfix.HotFixID;
                    'Description'=$hotfix.Description;
                    'InstalledOn'=$installedOn;
                    'FixComments'=$hotfix.FixComments;
                }
            $osHotFix = New-Object -TypeName PSObject -Prop $properties

            
            $osHotFixes += $osHotFix
        }
        $osHotFixes
    }

    function Get-OsInUseVirtualMemory
    {
        $osInUseVirtualMemory  = $null
        $os = Get-CimClass Win32_OperatingSystem
        $totalVirtualMemorySize = $os.TotalVirtualMemorySize
        $freeVirtualMemory = $os.FreeVirtualMemory

        if (($totalVirtualMemorySize) -and ($freeVirtualMemory))
        {
            $osInUseVirtualMemory = $totalVirtualMemorySize - $freeVirtualMemory
        }
        return $osInUseVirtualMemory
    }

    function Get-OsServerLevel
    {
        
        $subkey = 'Software\Microsoft\Windows NT\CurrentVersion\Server\ServerLevels'
        $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($subkey)
        $serverLevels = @{}
        try
        {
            if ($null -ne $regKey)
            {
                $serverLevelNames = $regKey.GetValueNames()

                foreach ($serverLevelName in $serverLevelNames)
                {
                    if ($regKey.GetValueKind($serverLevelName) -eq 4) 
                    {
                        $val = $regKey.GetValue($serverLevelName)
                        $serverLevels.Add($serverLevelName, [System.Convert]::ToUInt32($val))
                    }
                }
            }
        }
        finally
        {
            if ($null -ne $regKey) { $regKey.Dispose()}
        }

        if ($null -eq $serverLevels -or $serverLevels.Count -eq 0)
        {
            return $null
        }

        [uint32]$rv
        
        
        
        
        
        
        if ($serverLevels.ContainsKey("NanoServer") -and $serverLevels["NanoServer"] -eq 1)
        {
            $rv = 1 
        }
        elseif ($serverLevels.ContainsKey("ServerCore") -and $serverLevels["ServerCore"] -eq 1)
        {
            $rv = 2 
            if ($serverLevels.ContainsKey("Server-Gui-Mgmt") -and $serverLevels["Server-Gui-Mgmt"] -eq 1)
            {
                $rv = 3 
                if ($serverLevels.ContainsKey("Server-Gui-Shell") -and $serverLevels["Server-Gui-Shell"] -eq 1)
                {
                    $rv = 4 
                }
            }
        }

        return $rv
    }

    function Get-OsSuites
    {
        param($propertyName)

        $osProductSuites = @()
        $suiteMask = Get-CimClassPropVal Win32_OperatingSystem $propertyName
        if ($suiteMask)
        {
            foreach($suite in [System.Enum]::GetValues('Microsoft.PowerShell.Commands.OSProductSuite'))
            {
                if (($suiteMask -band $suite) -ne 0)
                {
                    $osProductSuites += $suite
                }
            }

        }
        return $osProductSuites
    }

    function Get-HyperVProperty
    {
        param([string]$propertyName)

        $hypervisorPresent = Get-CimClassPropVal Win32_ComputerSystem HypervisorPresent

        $dataExecutionPrevention_Available = $null
        $secondLevelAddressTranslationExtensions  = $null
        $virtualizationFirmwareEnabled  = $null
        $vMMonitorModeExtensions  = $null

        if (($null -ne $hypervisorPresent) -and ($hypervisorPresent -ne $true))
        {
            $dataExecutionPrevention_Available = Get-CimClassPropVal Win32_OperatingSystem DataExecutionPrevention_Available

            $secondLevelAddressTranslationExtensions = Get-CimClassPropVal Win32_Processor SecondLevelAddressTranslationExtensions
            $virtualizationFirmwareEnabled = Get-CimClassPropVal Win32_Processor VirtualizationFirmwareEnabled
            $vMMonitorModeExtensions = Get-CimClassPropVal Win32_Processor VMMonitorModeExtensions
        }
        switch ($propertyName)
        {
            "HyperVisorPresent" { return $hypervisorPresent }
            "HyperVRequirementDataExecutionPreventionAvailable" { return $dataExecutionPrevention_Available }
            "HyperVRequirementSecondLevelAddressTranslation"{ return $secondLevelAddressTranslationExtensions }
            "HyperVRequirementVirtualizationFirmwareEnabled"{ return $virtualizationFirmwareEnabled }
            "HyperVRequirementVMMonitorModeExtensions" { return $vMMonitorModeExtensions }
        }
    }

    function Get-KeyboardLayout
    {
        $keyboards = Get-CimClass Win32_Keyboard
        $result = $null
        if ($keyboards)
        {
            
            
            
            $layout = $keyboards[0].Layout
            try
            {
                $layoutAsHex = [System.Convert]::ToUInt32($layout, 16)
                if ($null -ne $layoutAsHex)
                {
                    $result = Convert-LocaleIdToLocaleName $layoutAsHex
                }
            }
            catch
            {
              
            }
        }
        return $result
    }

    function Get-OsLanguageName
    {
        
        $localeID = Get-CimClassPropVal Win32_OperatingSystem OSLanguage
        return Convert-LocaleIdToLocaleName $localeID
    }

    function Convert-LocaleIdToLocaleName
    {
        
        
        
        
        
        param($localeID)

        $sb = (New-Object System.Text.StringBuilder([int]85)) 
        $len = (Get-LCIDToLocaleName)::LCIDToLocaleName($localeID, $sb, $sb.Capacity, 0)
        if (($len -gt 0) -and ($sb.Length -gt 0))
        {
            return $sb.ToString()
        }
        return $null
    }

    function Get-Locale
    {
        
        
        
        
        

        $localeName = $null

        $locale =  Get-CimClassPropVal Win32_OperatingSystem Locale

        if ($null -ne $locale)
        {
            
            $localeAsHex = [System.Convert]::ToUInt32($locale, 16)
            if ($null -ne $localeAsHex)
            {

                try
                {
                    $localeName = Convert-LocaleIdToLocaleName $localeAsHex
                }
                catch
                {
                    
                        
                        
                }
            }

            if ($null -eq $localeName)
            {
                try
                {
                    $cultureInfo = (New-Object System.Globalization.CultureInfo($locale))
                    $localeName = $cultureInfo.Name
                }
                catch
                {
                    
                }
            }
        }
        return $localeName
    }

    function Get-OsPagingFiles
    {
        $osPagingFiles = @()
        $pageFileUsage =  Get-CimClass Win32_PageFileUsage
        if ($null -ne $pageFileUsage)
        {
            foreach ($pageFileItem in $pageFileUsage)
            {
                $osPagingFiles += $pageFileItem.Caption
            }
        }

        return [string[]]$osPagingFiles
    }

    function Get-UnixSecondsToDateTime
    {
        param([string]$seconds)

        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
        $origin.AddSeconds($seconds)
    }

    function Get-WinNtCurrentVersion
    {
        
        param([string]$propertyName)

        $key = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\'
        $regValue = (Get-ItemProperty -Path $key -Name $propertyName -ErrorAction SilentlyContinue).$propertyName

        if ($propertyName -eq "InstallDate")
        {
            
            if ($regValue)
            {
                return Get-UnixSecondsToDateTime $regValue
            }
        }
        else
        {
            return $regValue
        }

        return $null
    }

    function Get-ExpectedComputerInfoValue
    {
        param([string]$propertyName)

        switch ($propertyName)
        {
            "BiosBIOSVersion" {return Get-CimClassPropVal Win32_bios BiosVersion}
            "BiosBuildNumber" {return Get-CimClassPropVal Win32_bios BuildNumber}
            "BiosCaption" {return Get-CimClassPropVal Win32_bios Caption}
            "BiosCharacteristics" {return Get-CimClassPropVal Win32_bios BiosCharacteristics}
            "BiosCodeSet" {return Get-CimClassPropVal Win32_bios CodeSet}
            "BiosCurrentLanguage" {return Get-CimClassPropVal Win32_bios CurrentLanguage}
            "BiosDescription" {return Get-CimClassPropVal Win32_bios Description}
            "BiosEmbeddedControllerMajorVersion" {return Get-CimClassPropVal Win32_bios EmbeddedControllerMajorVersion}
            "BiosEmbeddedControllerMinorVersion" {return Get-CimClassPropVal Win32_bios EmbeddedControllerMinorVersion}
            "BiosFirmwareType" {return Get-BiosFirmwareType}
            "BiosIdentificationCode" {return Get-CimClassPropVal Win32_bios IdentificationCode}
            "BiosInstallableLanguages" {return Get-CimClassPropVal Win32_bios InstallableLanguages}
            "BiosInstallDate" {return Get-CimClassPropVal Win32_bios InstallDate}
            "BiosLanguageEdition" {return Get-CimClassPropVal Win32_bios LanguageEdition}
            "BiosListOfLanguages" {return Get-CimClassPropVal Win32_bios ListOfLanguages}
            "BiosManufacturer" {return Get-CimClassPropVal Win32_bios Manufacturer}
            "BiosName" {return Get-CimClassPropVal Win32_bios Name}
            "BiosOtherTargetOS" {return Get-CimClassPropVal Win32_bios OtherTargetOS}
            "BiosPrimaryBIOS" {return Get-CimClassPropVal Win32_bios PrimaryBIOS}
            "BiosReleaseDate" {return Get-CimClassPropVal Win32_bios ReleaseDate}
            "BiosSerialNumber" {return Get-CimClassPropVal Win32_bios SerialNumber}
            "BiosSMBIOSBIOSVersion" {return Get-CimClassPropVal Win32_bios SMBIOSBIOSVersion}
            "BiosSMBIOSPresent" {return Get-CimClassPropVal Win32_bios SMBIOSPresent}
            "BiosSMBIOSMajorVersion" {return Get-CimClassPropVal Win32_bios SMBIOSMajorVersion}
            "BiosSMBIOSMinorVersion" {return Get-CimClassPropVal Win32_bios SMBIOSMinorVersion}
            "BiosSoftwareElementState" {return Get-CimClassPropVal Win32_bios SoftwareElementState}
            "BiosStatus" {return Get-CimClassPropVal Win32_bios Status}
            "BiosSystemBiosMajorVersion" {return Get-CimClassPropVal Win32_bios SystemBiosMajorVersion}
            "BiosSystemBiosMinorVersion" {return Get-CimClassPropVal Win32_bios SystemBiosMinorVersion}
            "BiosTargetOperatingSystem" {return Get-CimClassPropVal Win32_bios TargetOperatingSystem}
            "BiosVersion" {return Get-CimClassPropVal Win32_bios Version}

            "CsAdminPasswordStatus" {return Get-CimClassPropVal Win32_ComputerSystem AdminPasswordStatus}
            "CsAutomaticManagedPagefile" {return Get-CimClassPropVal Win32_ComputerSystem AutomaticManagedPagefile}
            "CsAutomaticResetBootOption" {return Get-CimClassPropVal Win32_ComputerSystem AutomaticResetBootOption}
            "CsAutomaticResetCapability" {return Get-CimClassPropVal Win32_ComputerSystem AutomaticResetCapability}
            "CsBootOptionOnLimit" {return Get-CimClassPropVal Win32_ComputerSystem BootOptionOnLimit}
            "CsBootOptionOnWatchDog" {return Get-CimClassPropVal Win32_ComputerSystem BootOptionOnWatchDog}
            "CsBootROMSupported" {return Get-CimClassPropVal Win32_ComputerSystem BootROMSupported}
            "CsBootStatus" {return Get-CimClassPropVal Win32_ComputerSystem BootStatus}
            "CsBootupState" {return Get-CimClassPropVal Win32_ComputerSystem BootupState}
            "CsCaption" {return Get-CimClassPropVal Win32_ComputerSystem Caption}
            "CsChassisBootupState" {return Get-CimClassPropVal Win32_ComputerSystem ChassisBootupState}
            "CsChassisSKUNumber" {return Get-CimClassPropVal Win32_ComputerSystem ChassisSKUNumber}
            "CsCurrentTimeZone" {return Get-CimClassPropVal Win32_ComputerSystem CurrentTimeZone}
            "CsDaylightInEffect" {return Get-CimClassPropVal Win32_ComputerSystem DaylightInEffect}
            "CsDescription" {return Get-CimClassPropVal Win32_ComputerSystem Description}
            "CsDNSHostName" {return Get-CimClassPropVal Win32_ComputerSystem DNSHostName}
            "CsDomain" {return Get-CimClassPropVal Win32_ComputerSystem Domain}
            "CsDomainRole" {return Get-CimClassPropVal Win32_ComputerSystem DomainRole}
            "CsEnableDaylightSavingsTime" {return Get-CimClassPropVal Win32_ComputerSystem EnableDaylightSavingsTime}
            "CsFrontPanelResetStatus" {return Get-CimClassPropVal Win32_ComputerSystem FrontPanelResetStatus}
            "CsHypervisorPresent" {return Get-CimClassPropVal Win32_ComputerSystem HypervisorPresent}
            "CsInfraredSupported" {return Get-CimClassPropVal Win32_ComputerSystem InfraredSupported}
            "CsInitialLoadInfo" {return Get-CimClassPropVal Win32_ComputerSystem InitialLoadInfo}
            "CsInstallDate" {return Get-CimClassPropVal Win32_ComputerSystem InstallDate}
            "CsKeyboardPasswordStatus" {return Get-CimClassPropVal Win32_ComputerSystem KeyboardPasswordStatus}
            "CsLastLoadInfo" {return Get-CimClassPropVal Win32_ComputerSystem LastLoadInfo}
            "CsManufacturer" {return Get-CimClassPropVal Win32_ComputerSystem Manufacturer}
            "CsModel" {return Get-CimClassPropVal Win32_ComputerSystem Model}
            "CsName" {return Get-CimClassPropVal Win32_ComputerSystem Name}
            "CsNetworkAdapters" { return Get-CsNetworkAdapters }
            "CsNetworkServerModeEnabled" {return Get-CimClassPropVal Win32_ComputerSystem NetworkServerModeEnabled}
            "CsNumberOfLogicalProcessors" {return [System.Environment]::GetEnvironmentVariable("NUMBER_OF_PROCESSORS")}
            "CsNumberOfProcessors" {return Get-CimClassPropVal Win32_ComputerSystem NumberOfProcessors }
            "CsOEMStringArray" {return Get-CimClassPropVal Win32_ComputerSystem OEMStringArray}
            "CsPartOfDomain" {return Get-CimClassPropVal Win32_ComputerSystem PartOfDomain}
            "CsPauseAfterReset" {return Get-CimClassPropVal Win32_ComputerSystem PauseAfterReset}
            "CsPCSystemType" {return Get-CimClassPropVal Win32_ComputerSystem PCSystemType}
            "CsPCSystemTypeEx" {return Get-CimClassPropVal Win32_ComputerSystem PCSystemTypeEx}
            "CsPhysicallyInstalledMemory" {return Get-CsPhysicallyInstalledSystemMemory}
            "CsPowerManagementCapabilities" {return Get-CimClassPropVal Win32_ComputerSystem PowerManagementCapabilities}
            "CsPowerManagementSupported" {return Get-CimClassPropVal Win32_ComputerSystem PowerManagementSupported}
            "CsPowerOnPasswordStatus" {return Get-CimClassPropVal Win32_ComputerSystem PowerOnPasswordStatus}
            "CsPowerState" {return Get-CimClassPropVal Win32_ComputerSystem PowerState}
            "CsPowerSupplyState" {return Get-CimClassPropVal Win32_ComputerSystem PowerSupplyState}
            "CsPrimaryOwnerContact" {return Get-CimClassPropVal Win32_ComputerSystem PrimaryOwnerContact}
            "CsPrimaryOwnerName" {return Get-CimClassPropVal Win32_ComputerSystem PrimaryOwnerName}
            "CsProcessors" { return Get-CsProcessors }
            "CsResetCapability" {return Get-CimClassPropVal Win32_ComputerSystem ResetCapability}
            "CsResetCount" {return Get-CimClassPropVal Win32_ComputerSystem ResetCount}
            "CsResetLimit" {return Get-CimClassPropVal Win32_ComputerSystem ResetLimit}
            "CsRoles" {return Get-CimClassPropVal Win32_ComputerSystem Roles}
            "CsStatus" {return Get-CimClassPropVal Win32_ComputerSystem Status}
            "CsSupportContactDescription" {return Get-CimClassPropVal Win32_ComputerSystem SupportContactDescription}
            "CsSystemFamily" {return Get-CimClassPropVal Win32_ComputerSystem SystemFamily}
            "CsSystemSKUNumber" {return Get-CimClassPropVal Win32_ComputerSystem SystemSKUNumber}
            "CsSystemType" {return Get-CimClassPropVal Win32_ComputerSystem SystemType}
            "CsThermalState" {return Get-CimClassPropVal Win32_ComputerSystem ThermalState}
            "CsTotalPhysicalMemory" {return Get-CimClassPropVal Win32_ComputerSystem TotalPhysicalMemory}
            "CsUserName" {return Get-CimClassPropVal Win32_ComputerSystem UserName}
            "CsWakeUpType" {return Get-CimClassPropVal Win32_ComputerSystem WakeUpType}
            "CsWorkgroup" {return Get-CimClassPropVal Win32_ComputerSystem Workgroup}

            "HyperVisorPresent" {return Get-HyperVProperty $propertyName}
            "HyperVRequirementDataExecutionPreventionAvailable" {return Get-HyperVProperty $propertyName}
            "HyperVRequirementSecondLevelAddressTranslation" {return Get-HyperVProperty $propertyName}
            "HyperVRequirementVirtualizationFirmwareEnabled" {return Get-HyperVProperty $propertyName}
            "HyperVRequirementVMMonitorModeExtensions" {return Get-HyperVProperty $propertyName}
            "KeyboardLayout" {return Get-KeyboardLayout}
            "LogonServer" {return [Microsoft.Win32.Registry]::GetValue("HKEY_Current_User\Volatile Environment", "LOGONSERVER", "")}

            "OsArchitecture" {return Get-CimClassPropVal Win32_OperatingSystem OsArchitecture}
            "OsBootDevice" {return Get-CimClassPropVal Win32_OperatingSystem BootDevice}
            "OsBuildNumber" {return Get-CimClassPropVal Win32_OperatingSystem BuildNumber}
            "OsBuildType" {return Get-CimClassPropVal Win32_OperatingSystem BuildType}
            "OsCodeSet" {return Get-CimClassPropVal Win32_OperatingSystem CodeSet}
            "OsCountryCode" {return Get-CimClassPropVal Win32_OperatingSystem CountryCode}
            "OsCSDVersion" {return Get-CimClassPropVal Win32_OperatingSystem CSDVersion}
            "OsCurrentTimeZone" {return Get-CimClassPropVal Win32_OperatingSystem CurrentTimeZone}
            "OsDataExecutionPrevention32BitApplications" {return Get-CimClassPropVal Win32_OperatingSystem DataExecutionPrevention_32BitApplications}
            "OsDataExecutionPreventionAvailable" {return Get-CimClassPropVal Win32_OperatingSystem DataExecutionPrevention_Available}
            "OsDataExecutionPreventionDrivers" {return Get-CimClassPropVal Win32_OperatingSystem DataExecutionPrevention_Drivers}
            "OsDataExecutionPreventionSupportPolicy" {return Get-CimClassPropVal Win32_OperatingSystem DataExecutionPrevention_SupportPolicy}
            "OsDebug" {return Get-CimClassPropVal Win32_OperatingSystem Debug}
            "OsDistributed" {return Get-CimClassPropVal Win32_OperatingSystem Distributed}
            "OsEncryptionLevel" {return Get-CimClassPropVal Win32_OperatingSystem EncryptionLevel}
            "OsForegroundApplicationBoost" {return Get-CimClassPropVal Win32_OperatingSystem ForegroundApplicationBoost}

            
            
            
            
            
            

            "OsHardwareAbstractionLayer" {return Get-OsHardwareAbstractionLayer}
            "OsHotFixes" {return Get-OsHotFixes }
            "OsInstallDate" {return Get-CimClassPropVal Win32_OperatingSystem InstallDate}
            "OsInUseVirtualMemory"  { return Get-OsInUseVirtualMemory }
            "OsLanguage" {return Get-OsLanguageName}
            "OsLastBootUpTime" {return Get-CimClassPropVal Win32_OperatingSystem LastBootUpTime}

            
            

            "OsLocale" {return Get-Locale}
            "OsLocaleID" {return Get-CimClassPropVal Win32_OperatingSystem Locale}
            "OsManufacturer" {return Get-CimClassPropVal Win32_OperatingSystem Manufacturer}
            "OsMaxNumberOfProcesses" {return Get-CimClassPropVal Win32_OperatingSystem MaxNumberOfProcesses}
            "OsMaxProcessMemorySize" {return Get-CimClassPropVal Win32_OperatingSystem MaxProcessMemorySize}
            "OsMuiLanguages" {return Get-CimClassPropVal Win32_OperatingSystem MuiLanguages}
            "OsName" {return Get-CimClassPropVal Win32_OperatingSystem Caption}
            "OsNumberOfLicensedUsers" {return Get-CimClassPropVal Win32_OperatingSystem NumberOfLicensedUsers}

            
            

            "OsNumberOfUsers" {return Get-CimClassPropVal Win32_OperatingSystem NumberOfUsers}
            "OsOperatingSystemSKU" {return Get-CimClassPropVal Win32_OperatingSystem OperatingSystemSKU}
            "OsOrganization" {return Get-CimClassPropVal Win32_OperatingSystem Organization}
            "OsOtherTypeDescription" {return Get-CimClassPropVal Win32_OperatingSystem OtherTypeDescription}
            "OsPAEEnabled" {return Get-CimClassPropVal Win32_OperatingSystem PAEEnabled}
            "OsPagingFiles" {return Get-OsPagingFiles}
            "OsPortableOperatingSystem" {return Get-CimClassPropVal Win32_OperatingSystem PortableOperatingSystem}
            "OsPrimary" {return Get-CimClassPropVal Win32_OperatingSystem Primary}
            "OsProductSuites" {return Get-OsSuites OSProductSuite }
            "OsProductType" {return Get-CimClassPropVal Win32_OperatingSystem ProductType}

            "OsRegisteredUser" {return Get-CimClassPropVal Win32_OperatingSystem RegisteredUser}
            "OsSerialNumber" {return Get-CimClassPropVal Win32_OperatingSystem SerialNumber}

            "OsServerLevel" {return Get-OsServerLevel}

            "OsServicePackMajorVersion" {return Get-CimClassPropVal Win32_OperatingSystem ServicePackMajorVersion}
            "OsServicePackMinorVersion" {return Get-CimClassPropVal Win32_OperatingSystem ServicePackMinorVersion}

            "OsSizeStoredInPagingFiles" {return Get-CimClassPropVal Win32_OperatingSystem SizeStoredInPagingFiles}
            "OsStatus" {return Get-CimClassPropVal Win32_OperatingSystem Status}
            "OsSuites" {return Get-OsSuites SuiteMask }
            "OsSystemDevice" {return Get-CimClassPropVal Win32_OperatingSystem SystemDevice}
            "OsSystemDirectory" {return Get-CimClassPropVal Win32_OperatingSystem SystemDirectory}
            "OsSystemDrive" {return Get-CimClassPropVal Win32_OperatingSystem SystemDrive}
            "OsTotalSwapSpaceSize" {return Get-CimClassPropVal Win32_OperatingSystem TotalSwapSpaceSize}
            "OsTotalVirtualMemorySize" {return Get-CimClassPropVal Win32_OperatingSystem TotalVirtualMemorySize}
            "OsTotalVisibleMemorySize" {return Get-CimClassPropVal Win32_OperatingSystem TotalVisibleMemorySize}
            "OsType" {return Get-CimClassPropVal Win32_OperatingSystem OSType }

            
            

            "OsVersion" {return Get-CimClassPropVal Win32_OperatingSystem Version}
            "OsWindowsDirectory" {return [System.Environment]::GetEnvironmentVariable("windir")}

            "PowerPlatformRole" { return Get-PowerPlatformRole }
            "TimeZone" {return ([System.TimeZoneInfo]::Local).DisplayName}

            "WindowsBuildLabEx" { return Get-WinNtCurrentVersion BuildLabEx }
            "WindowsCurrentVersion" { return Get-WinNtCurrentVersion CurrentVersion}
            "WindowsEditionId" { return Get-WinNtCurrentVersion EditionID}
            "WindowsInstallationType" { return Get-WinNtCurrentVersion InstallationType}
            "WindowsInstallDateFromRegistry" { return Get-WinNtCurrentVersion InstallDate}
            "WindowsProductId" { return Get-WinNtCurrentVersion ProductId}
            "WindowsProductName" { return Get-WinNtCurrentVersion ProductName}
            "WindowsRegisteredOrganization" {return Get-WinNtCurrentVersion RegisteredOrganization}
            "WindowsRegisteredOwner" {return Get-WinNtCurrentVersion RegisteredOwner}
            "WindowsVersion" {return Get-WinNtCurrentVersion ReleaseId}
            "WindowsUBR" {return Get-WinNtCurrentVersion UBR}

            "WindowsSystemRoot" {return [System.Environment]::GetEnvironmentVariable("SystemRoot")}

            default {return "Unknown/unsupported propertyName = $propertyName"}
        }
    }

    $expected = New-Object -TypeName PSObject
    foreach ($propertyName in [string[]]$propertyNames)
    {
        $expected | Add-Member -MemberType NoteProperty -Name $propertyName -Value (Get-ExpectedComputerInfoValue $propertyName)
    }
    return $expected
}

try {
    
    $originalDefaultParameterValues = $PSDefaultParameterValues.Clone()
    $PSDefaultParameterValues["it:skip"] = !$IsWindows

    Describe "Tests for Get-ComputerInfo: Ensure Type returned" -tags "CI", "RequireAdminOnWindows" {

        It "Verify type returned by Get-ComputerInfo" {
            $computerInfo = Get-ComputerInfo
            $computerInfo | Should -BeOfType 'Microsoft.PowerShell.Commands.ComputerInfo'
        }

        It "Verify progress records in Get-ComputerInfo" {
            try {
                $j = Start-Job { Get-ComputerInfo }
                $j | Wait-Job
                $j.ChildJobs[0].Progress | Should -HaveCount 9
                $j.ChildJobs[0].Progress[-1].RecordType | Should -Be ([System.Management.Automation.ProgressRecordType]::Completed)
            }
            finally {
                $j | Remove-Job
            }
        }
    }

    Describe "Tests for Get-ComputerInfo" -tags "Feature", "RequireAdminOnWindows" {
        Context "Validate All Properties" {
            BeforeAll {
                
                $computerInformation = Get-ComputerInfoForTest
                $propertyNames = Get-PropertyNamesForComputerInfoTest
                $Expected = New-ExpectedComputerInfo $propertyNames
                $testCases = $propertyNames | ForEach-Object { @{ "Property" = $_ } }
            }

            
            
            
            
            
            
            
            It "Test 01. Standard Property test - all properties (<property>)" -testcase $testCases -Pending {
                param ( $property )
                $specialProperties = "CsNetworkAdapters","CsProcessors","OsHotFixes"
                if ( $specialProperties -contains $property )
                {
                    $ObservedList = $ComputerInformation.$property
                    $ExpectedList = $Expected.$property
                    $SpecialPropertyList = ($ObservedList)[0].psobject.properties.name
                    Compare-Object $ObservedList $ExpectedList -property $SpecialPropertyList | Should -BeNullOrEmpty
                }
                else
                {
                    $left = $computerInformation.$property
                    $right = $Expected.$Property
                    
                    if ( $left -is [Collections.IList] )
                    {
                        $left = $left -join ":"
                        $right = $right -join ":"
                    }
                    $left | Should -Be $right
                }
            }
        }

        Context "Filter Variations" {
            
            
            
            It "Test 02.001 Filter Property - Property filter with one valid item" {
                $propertyNames =  @("BiosBIOSVersion")
                $expectedProperties = @("BiosBIOSVersion")
                $propertyFilter = "BiosBIOSVersion"
                $computerInfoWithProp = Get-ComputerInfoForTest -properties $propertyFilter
                $computerInfoWithProp | Should -BeOfType [pscustomobject]
                @($computerInfoWithProp.psobject.properties).count | Should -Be 1
                $computerInfoWithProp.$propertyFilter | Should -Be $expected.$propertyFilter
            }

            
            
            
            It "Test 02.002 Filter Property - Property filter with three valid items" {
                $propertyNames =  @("BiosBIOSVersion","BiosBuildNumber","BiosCaption")
                $expectedProperties = @("BiosBIOSVersion","BiosBuildNumber","BiosCaption")
                $propertyFilter = @("BiosBIOSVersion","BiosBuildNumber","BiosCaption")
                $computerInfoWithProp = Get-ComputerInfoForTest -properties $propertyFilter
                $computerInfoWithProp | Should -BeOfType [pscustomobject]
                @($computerInfoWithProp.psobject.properties).count | Should -Be 3
                foreach($property in $propertyFilter) {
                    $ComputerInfoWithProp.$property | Should -Be $Expected.$property
                }
            }

            
            
            
            It "Test 02.003 Filter Property - Property filter with one invalid item" {
                $propertyNames =  $null
                $expectedProperties = $null
                $propertyFilter = @("BiosBIOSVersionXXX")
                $computerInfoWithProp = Get-ComputerInfoForTest -properties $propertyFilter
                $computerInfoWithProp | Should -BeOfType [pscustomobject]
                @($computerInfoWithProp.psobject.properties).count | Should -Be 0
            }

            
            
            
            It "Test 02.004 Filter Property - Property filter with four invalid items" {
                $propertyNames =  $null
                $expectedProperties = $null
                $propertyFilter = @("BiosBIOSVersionXXX","InvalidProperty1","InvalidProperty2","InvalidProperty3")
                $computerInfoWithProp = Get-ComputerInfoForTest -properties $propertyFilter
                $computerInfoWithProp | Should -BeOfType [pscustomobject]
                @($computerInfoWithProp.psobject.properties).count | Should -Be 0
            }

            
            
            
            It "Test 02.005 Filter Property - Property filter with valid and invalid items: ver 
                $propertyNames =  @("BiosCodeSet","BiosCurrentLanguage","BiosDescription")
                $expectedProperties = @("BiosCodeSet","BiosCurrentLanguage","BiosDescription")
                $propertyFilter = @("InvalidProperty1","BiosCodeSet","BiosCurrentLanguage","BiosDescription")
                $computerInfoWithProp = Get-ComputerInfoForTest -properties $propertyFilter
                $computerInfoWithProp | Should -BeOfType [pscustomobject]
                $realProperties  = $propertyFilter | Where-Object { $_ -notmatch "^InvalidProperty[0-9]+" }
                @($computerInfoWithProp.psobject.properties).count | Should -Be $realProperties.Count
                foreach ( $property in $realProperties )
                {
                    $computerInfoWithProp.$property | Should -Be $expected.$property
                }
            }

            
            
            
            It "Test 02.006 Filter Property - Property filter with valid and invalid items: ver 
                $propertyNames =  @("BiosCodeSet","BiosCurrentLanguage","BiosDescription")
                $expectedProperties = @("BiosCodeSet","BiosCurrentLanguage","BiosDescription")
                $propertyFilter = @("BiosCodeSet","InvalidProperty1","BiosCurrentLanguage","BiosDescription","InvalidProperty2")
                $computerInfoWithProp = Get-ComputerInfoForTest -properties $propertyFilter
                $computerInfoWithProp | Should -BeOfType [pscustomobject]
                $realProperties  = $propertyFilter | Where-Object { $_ -notmatch "^InvalidProperty[0-9]+" }
                @($computerInfoWithProp.psobject.properties).count | Should -Be $realProperties.Count
                foreach ( $property in $realProperties )
                {
                    $computerInfoWithProp.$property | Should -Be $expected.$property
                }
            }

            
            
            
            It "Test 02.007 Filter Property - Property filter with wild card: ver 
                $propertyNames =  @("BiosCaption","BiosCharacteristics","BiosCodeSet","BiosCurrentLanguage")
                $expectedProperties = @("BiosCaption","BiosCharacteristics","BiosCodeSet","BiosCurrentLanguage")
                $propertyFilter = @("BiosC*")
                $computerInfoWithProp = Get-ComputerInfoForTest -properties $propertyFilter
                $computerInfoWithProp | Should -BeOfType [pscustomobject]
                @($computerInfoWithProp.psobject.properties).count | Should -Be $expectedProperties.Count
                foreach ( $property in $expectedProperties )
                {
                    $computerInfoWithProp.$property | Should -Be $expected.$property
                }
            }

            
            
            
            It "Test 02.008 Filter Property - Property filter with wild card and fixed" {
                $propertyNames =  @("BiosCaption","BiosCharacteristics","BiosCodeSet","BiosCurrentLanguage","CsCaption")
                $expectedProperties = @("BiosCaption","BiosCharacteristics","BiosCodeSet","BiosCurrentLanguage","CsCaption")
                $propertyFilter = @("BiosC*","CsCaption")
                $computerInfoWithProp = Get-ComputerInfoForTest -properties $propertyFilter
                $computerInfoWithProp | Should -BeOfType [pscustomobject]
                @($computerInfoWithProp.psobject.properties).count | Should -Be $expectedProperties.Count
                foreach ( $property in $expectedProperties )
                {
                    $computerInfoWithProp.$property | Should -Be $expected.$property
                }
            }

            
            
            
            It "Test 02.009 Filter Property - Property filter with wild card, fixed and invalid" {
                $propertyNames =  @("BiosCaption","BiosCharacteristics","BiosCodeSet","BiosCurrentLanguage","CsCaption")
                $expectedProperties = @("BiosCaption","BiosCharacteristics","BiosCodeSet","BiosCurrentLanguage","CsCaption")
                $propertyFilter = @("CsCaption","InvalidProperty1","BiosC*")
                $computerInfoWithProp = Get-ComputerInfoForTest -properties $propertyFilter
                $computerInfoWithProp | Should -BeOfType [pscustomobject]
                @($computerInfoWithProp.psobject.properties).count | Should -Be $expectedProperties.Count
                foreach ( $property in $expectedProperties )
                {
                    $computerInfoWithProp.$property | Should -Be $expected.$property
                }
            }

            
            
            
            It "Test 02.010 Filter Property - Property filter with wild card invalid" {
                $propertyNames =  $null
                $expectedProperties = $null
                $propertyFilter = @("BiosBIOSVersionX*")
                $computerInfoWithProp = Get-ComputerInfoForTest -properties $propertyFilter
                $computerInfoWithProp | Should -BeOfType [pscustomobject]
                @($computerInfoWithProp.psobject.properties).count | Should -Be 0
            }
        }

    }

    Describe "Special Case Tests for Get-ComputerInfo" -tags "Feature", "RequireAdminOnWindows" {

        BeforeAll {
            if ($IsWindows)
            {
                Add-Type -Name 'slc' -Namespace Win32Functions -MemberDefinition @'
                    [DllImport("slc.dll", CharSet = CharSet.Unicode)]
                    public static extern int SLGetWindowsInformationDWORD(string licenseProperty, out int propertyValue);
'@
                
                function HasDeviceGuardLicense
                {
                    try
                    {
                        $policy = $null
                        if ([Win32Functions.slc]::SLGetWindowsInformationDWORD("CodeIntegrity-AllowConfigurablePolicy", [Ref]$policy) -eq 0 -and $policy -eq 1)
                        {
                            return $true
                        }
                    }
                    catch
                    {
                        
                    }

                    return $false
                }

                function Get-DeviceGuard
                {
                    $returnValue = @{
                        SmartStatus = 0     
                        AvailableSecurityProperties = $null
                        CodeIntegrityPolicyEnforcementStatus = $null
                        RequiredSecurityProperties = $null
                        SecurityServicesConfigured = $null
                        SecurityServicesRunning = $null
                        UserModeCodeIntegrityPolicyEnforcementStatus = $null
                    }
                    try
                    {
                        $instance = Get-CimInstance Win32_DeviceGuard -Namespace 'root\Microsoft\Windows\DeviceGuard' -ErrorAction Stop
                        $ss = $instance.VirtualizationBasedSecurityStatus;
                        if ($null -ne $ss)
                        {
                            $returnValue.SmartStatus = $ss;
                        }
                        $returnValue.AvailableSecurityProperties = $instance.AvailableSecurityProperties
                        $returnValue.CodeIntegrityPolicyEnforcementStatus = $instance.CodeIntegrityPolicyEnforcementStatus
                        $returnValue.RequiredSecurityProperties = $instance.RequiredSecurityProperties
                        $returnValue.SecurityServicesConfigured = $instance.SecurityServicesConfigured
                        $returnValue.SecurityServicesRunning = $instance.SecurityServicesRunning
                        $returnValue.UserModeCodeIntegrityPolicyEnforcementStatus = $instance.UserModeCodeIntegrityPolicyEnforcementStatus
                    }
                    catch
                    {
                        
                        
                    }

                    return $returnValue
                }

                $observed = Get-ComputerInfoForTest
            }
        }

        It "Test for DeviceGuard properties" -Pending {
            if (-not (HasDeviceGuardLicense))
            {
                $observed.DeviceGuardSmartStatus | Should -Be 0
                $observed.DeviceGuardRequiredSecurityProperties | Should -BeNullOrEmpty
                $observed.DeviceGuardAvailableSecurityProperties | Should -BeNullOrEmpty
                $observed.DeviceGuardSecurityServicesConfigured | Should -BeNullOrEmpty
                $observed.DeviceGuardSecurityServicesRunning | Should -BeNullOrEmpty
                $observed.DeviceGuardCodeIntegrityPolicyEnforcementStatus | Should -BeNullOrEmpty
                $observed.DeviceGuardUserModeCodeIntegrityPolicyEnforcementStatus | Should -BeNullOrEmpty
            }
            else
            {
                $deviceGuard = Get-DeviceGuard
                
                $requiredSecurityPropertiesValues = @{
                    "1" = "BaseVirtualizationSupport"
                    "2" = "SecureBoot"
                    "3" = "DMAProtection"
                    "4" = "SecureMemoryOverwrite"
                    "5" = "UEFICodeReadonly"
                    "6" = "SMMSecurityMitigations1.0"
                }
                $smartStatusValues = @{
                    "0" = "Off"
                    "1" = "Enabled"
                    "2" = "Running"
                }
                $securityServicesRunningValues = @{
                    "0" = "0"
                    "1" = "CredentialGuard"
                    "2" = "HypervisorEnforcedCodeIntegrity"
                }
                $observed.DeviceGuardSmartStatus | Should -Be (Get-StringValuesFromValueMap -valuemap $smartStatusValues -values $deviceGuard.SmartStatus)
                if ($deviceGuard.RequiredSecurityProperties -eq $null)
                {
                    $observed.DeviceGuardRequiredSecurityProperties | Should -BeNullOrEmpty
                }
                else
                {
                    $observed.DeviceGuardRequiredSecurityProperties | Should -Not -BeNullOrEmpty
                    [string]::Join(",", $observed.DeviceGuardRequiredSecurityProperties) | Should -Be (Get-StringValuesFromValueMap -valuemap $requiredSecurityPropertiesValues -values $deviceGuard.RequiredSecurityProperties)
                }
                $observed.DeviceGuardAvailableSecurityProperties | Should -Be $deviceGuard.AvailableSecurityProperties
                $observed.DeviceGuardSecurityServicesConfigured | Should -Be $deviceGuard.SecurityServicesConfigured
                if ($deviceGuard.SecurityServicesRunning -eq $null)
                {
                    $observed.DeviceGuardSecurityServicesRunning | Should -BeNullOrEmpty
                }
                else
                {
                    $observed.DeviceGuardSecurityServicesRunning | Should -Not -BeNullOrEmpty
                    [string]::Join(",", $observed.DeviceGuardSecurityServicesRunning) | Should -Be (Get-StringValuesFromValueMap -valuemap $securityServicesRunningValues -values $deviceGuard.SecurityServicesRunning)
                }
                $observed.DeviceGuardCodeIntegrityPolicyEnforcementStatus | Should -Be $deviceGuard.CodeIntegrityPolicyEnforcementStatus
                $observed.DeviceGuardUserModeCodeIntegrityPolicyEnforcementStatus | Should -Be $deviceGuard.UserModeCodeIntegrityPolicyEnforcementStatus
            }
        }

        
        
        

        It "(special case) Test for property = OsFreePhysicalMemory" {
            ($observed.OsFreePhysicalMemory -gt 0) | Should -BeTrue
        }

        It "(special case) Test for property = OsFreeSpaceInPagingFiles" -Skip:([System.Management.Automation.Platform]::IsIoT -or !$IsWindows) {
            ($observed.OsFreeSpaceInPagingFiles -gt 0) | Should -BeTrue
        }

        It "(special case) Test for property = OsFreeVirtualMemory" {
            ($observed.OsFreeVirtualMemory -gt 0) | Should -BeTrue
        }


        It "(special case) Test for property = OsLocalDateTime" {
            $computerInfo = Get-ComputerInfoForTest
            $testEndTime = Get-Date
            $computerInfo.OsLocalDateTime | Should -BeGreaterThan $testStartTime
            $computerInfo.OsLocalDateTime | Should -BeLessThan $testEndTime
        }

        It "(special case) Test for property = OsMaxNumberOfProcesses" {
            ($observed.OsMaxNumberOfProcesses -gt 0) | Should -BeTrue
        }

        It "(special case) Test for property = OsNumberOfProcesses" {
            ($observed.OsNumberOfProcesses -gt 0) | Should -BeTrue
        }

        It "(special case) Test for property = OsUptime" {
            ($observed.OsUptime.Ticks -gt 0) | Should -BeTrue
        }

        It "(special case) Test for property = OsInUseVirtualMemory" {
            ($observed.OsInUseVirtualMemory -gt 0) | Should -BeTrue
        }

        It "(special case) Test for Filter Property - Property filter with special wild card * and fixed" {
            $propertyFilter = @("BiosC*","*")
            $computerInfo = Get-ComputerInfo -Property $propertyFilter
            $computerInfo | Should -BeOfType Microsoft.PowerShell.Commands.ComputerInfo
        }
    }
}
finally
{
    $global:PSDefaultParameterValues = $originalDefaultParameterValues
}
