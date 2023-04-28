﻿
Register-PSFTeppArgumentCompleter -Command Export-PSFConfig -Parameter FullName -Name 'PSFramework-config-fullname'
Register-PSFTeppArgumentCompleter -Command Export-PSFConfig -Parameter Module -Name 'PSFramework-config-module'
Register-PSFTeppArgumentCompleter -Command Export-PSFConfig -Parameter Name -Name 'PSFramework-config-name'

Register-PSFTeppArgumentCompleter -Command Get-PSFConfig -Parameter FullName -Name 'PSFramework-config-fullname'
Register-PSFTeppArgumentCompleter -Command Get-PSFConfig -Parameter Module -Name 'PSFramework-config-module'
Register-PSFTeppArgumentCompleter -Command Get-PSFConfig -Parameter Name -Name 'PSFramework-config-name'

Register-PSFTeppArgumentCompleter -Command Import-PSFConfig -Parameter Schema -Name 'PSFramework-Config-Schema'

Register-PSFTeppArgumentCompleter -Command Set-PSFConfig -Parameter FullName -Name 'PSFramework-config-fullname'
Register-PSFTeppArgumentCompleter -Command Set-PSFConfig -Parameter Module -Name 'PSFramework-config-module'
Register-PSFTeppArgumentCompleter -Command Set-PSFConfig -Parameter Name -Name 'PSFramework-config-name'
Register-PSFTeppArgumentCompleter -Command Set-PSFConfig -Parameter Validation -Name 'PSFramework-config-validation'

Register-PSFTeppArgumentCompleter -Command Register-PSFConfig -Parameter FullName -Name 'PSFramework-config-fullname'
Register-PSFTeppArgumentCompleter -Command Register-PSFConfig -Parameter Module -Name 'PSFramework-config-module'
Register-PSFTeppArgumentCompleter -Command Register-PSFConfig -Parameter Name -Name 'PSFramework-config-name'

Register-PSFTeppArgumentCompleter -Command Get-PSFConfigValue -Parameter FullName -Name 'PSFramework-config-fullname'

Register-PSFTeppArgumentCompleter -Command Unregister-PSFConfig -Parameter FullName -Name 'PSFramework-Unregister-PSFConfig-FullName'
Register-PSFTeppArgumentCompleter -Command Unregister-PSFConfig -Parameter Module -Name 'PSFramework-Unregister-PSFConfig-Module'



Register-PSFTeppArgumentCompleter -Command Get-PSFFeature -Parameter Name -Name 'PSFramework.Feature.Name'
Register-PSFTeppArgumentCompleter -Command Set-PSFFeature -Parameter Name -Name 'PSFramework.Feature.Name'
Register-PSFTeppArgumentCompleter -Command Test-PSFFeature -Parameter Name -Name 'PSFramework.Feature.Name'



Register-PSFTeppArgumentCompleter -Command Get-PSFCallback -Parameter Name -Name 'PSFramework.Callback.Name'
Register-PSFTeppArgumentCompleter -Command Unregister-PSFCallback -Parameter Name -Name 'PSFramework.Callback.Name'



Register-PSFTeppArgumentCompleter -Command Get-PSFLicense -Parameter Filter -Name 'PSFramework-license-name'



Register-PSFTeppArgumentCompleter -Command Import-PSFLocalizedString -Parameter Language -Name 'PSFramework-LanguageNames'
Register-PSFTeppArgumentCompleter -Command Get-PSFLocalizedString -Parameter Module -Name 'PSFramework-LocalizedStrings-Modules'
Register-PSFTeppArgumentCompleter -Command Get-PSFLocalizedString -Parameter Name -Name 'PSFramework-LocalizedStrings-Names'



Register-PSFTeppArgumentCompleter -Command Get-PSFLoggingProvider -Parameter Name -Name 'PSFramework-logging-provider'
Register-PSFTeppArgumentCompleter -Command Install-PSFLoggingProvider -Parameter Name -Name 'PSFramework-logging-provider'
Register-PSFTeppArgumentCompleter -Command Set-PSFLoggingProvider -Parameter Name -Name 'PSFramework-logging-provider'



Register-PSFTeppArgumentCompleter -Command Get-PSFMessage -Parameter ModuleName -Name 'PSFramework.Message.Module'
Register-PSFTeppArgumentCompleter -Command Get-PSFMessage -Parameter FunctionName -Name 'PSFramework.Message.Function'
Register-PSFTeppArgumentCompleter -Command Get-PSFMessage -Parameter Tag -Name 'PSFramework.Message.Tags'
Register-PSFTeppArgumentCompleter -Command Get-PSFMessage -Parameter Runspace -Name 'PSFramework.Message.Runspace'
Register-PSFTeppArgumentCompleter -Command Get-PSFMessage -Parameter Level -Name 'PSFramework.Message.Level'



Register-PSFTeppArgumentCompleter -Command Get-PSFRunspace -Parameter Name -Name 'PSFramework-runspace-name'
Register-PSFTeppArgumentCompleter -Command Register-PSFRunspace -Parameter Name -Name 'PSFramework-runspace-name'
Register-PSFTeppArgumentCompleter -Command Stop-PSFRunspace -Parameter Name -Name 'PSFramework-runspace-name'
Register-PSFTeppArgumentCompleter -Command Start-PSFRunspace -Parameter Name -Name 'PSFramework-runspace-name'

Register-PSFTeppArgumentCompleter -Command Get-PSFDynamicContentObject -Parameter Name -Name 'PSFramework-dynamiccontentobject-name'
Register-PSFTeppArgumentCompleter -Command Set-PSFDynamicContentObject -Parameter Name -Name 'PSFramework-dynamiccontentobject-name'



Register-PSFTeppArgumentCompleter -Command Export-PSFClixml -Parameter Encoding -Name 'PSFramework-Encoding'
Register-PSFTeppArgumentCompleter -Command Import-PSFClixml -Parameter Encoding -Name 'PSFramework-Encoding'



Register-PSFTeppArgumentCompleter -Command Set-PSFTeppResult -Parameter TabCompletion -Name 'PSFramework-tepp-scriptblockname'
Register-PSFTeppArgumentCompleter -Command Register-PSFTeppArgumentCompleter -Parameter Name -Name 'PSFramework-tepp-scriptblockname'
Register-PSFTeppArgumentCompleter -Command Register-PSFTeppArgumentCompleter -Parameter Parameter -Name 'PSFramework-tepp-parametername'



Register-PSFTeppArgumentCompleter -Command ConvertFrom-PSFArray -Parameter PropertyName -Name PSFramework-Input-ObjectProperty

Register-PSFTeppArgumentCompleter -Command ConvertTo-PSFHashtable -Parameter Include -Name PSFramework-Input-ObjectProperty
Register-PSFTeppArgumentCompleter -Command ConvertTo-PSFHashtable -Parameter Exclude -Name PSFramework-Input-ObjectProperty

Register-PSFTeppArgumentCompleter -Command Resolve-PSFPath -Parameter Provider -Name PSFramework-utility-psprovider
Register-PSFTeppArgumentCompleter -Command Get-PSFPath -Parameter Name -Name 'PSFramework.Utility.PathName'
Register-PSFTeppArgumentCompleter -Command Set-PSFPath -Parameter Name -Name 'PSFramework.Utility.PathName'

Register-PSFTeppArgumentCompleter -Command Select-PSFObject -Parameter Property -Name PSFramework-Input-ObjectProperty
Register-PSFTeppArgumentCompleter -Command Select-PSFObject -Parameter ExpandProperty -Name PSFramework-Input-ObjectProperty
Register-PSFTeppArgumentCompleter -Command Select-PSFObject -Parameter ExcludeProperty -Name PSFramework-Input-ObjectProperty
Register-PSFTeppArgumentCompleter -Command Select-PSFObject -Parameter ShowProperty -Name PSFramework-Input-ObjectProperty
Register-PSFTeppArgumentCompleter -Command Select-PSFObject -Parameter ShowExcludeProperty -Name PSFramework-Input-ObjectProperty
