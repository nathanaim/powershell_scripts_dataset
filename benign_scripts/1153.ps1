











$username = 'CarbonInstallUser'
$password = 'IM33tRequ!rem$'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Remove-TestUser
}

function Stop-Test
{
    Remove-TestUser
}

function Remove-TestUser
{
    Uninstall-User -Username $username
}

function Test-ShouldCreateNewUser
{
    $warnings = @()
    $fullName = 'Carbon Install User'
    $description = "Test user for testing the Carbon Install-User function."
    $user = Install-User -UserName $username -Password $password -Description $description -FullName $fullName -PassThru -WarningVariable 'warnings'
    Assert-NotNull $user
    try
    {
        Assert-Is $user ([DirectoryServices.AccountManagement.UserPrincipal])
        Assert-True (Test-User -Username $username)
    }
    finally
    {
        $user.Dispose()
    }

    [DirectoryServices.AccountManagement.UserPrincipal]$user = Get-User -Username $username
    Assert-NotNull $user
    try
    {
        Assert-Equal $description $user.Description
        Assert-True $user.PasswordNeverExpires 
        Assert-True $user.Enabled
        Assert-Equal $username $user.SamAccountName
        Assert-False $user.UserCannotChangePassword
        Assert-Equal $fullName $user.DisplayName
        Assert-Credential -Password $password
        Assert-Equal 1 $warnings.Count
        Assert-Like $warnings[0] '*obsolete*'
    }
    finally
    {
        $user.Dispose()
    }
}


function Test-ShouldCreateNewUserWithCredential
{
    $fullName = 'Carbon Install User'
    $description = "Test user for testing the Carbon Install-User function."
    $c = New-Credential -UserName $username -Password $password
    $user = Install-User -Credential $c -Description $description -FullName $fullName -PassThru
    Assert-NotNull $user
    try
    {
        Assert-Is $user ([DirectoryServices.AccountManagement.UserPrincipal])
        Assert-True (Test-User -Username $username)
    }
    finally
    {
        $user.Dispose()
    }

    [DirectoryServices.AccountManagement.UserPrincipal]$user = Get-User -Username $username
    Assert-NotNull $user
    try
    {
        Assert-Equal $description $user.Description
        Assert-True $user.PasswordNeverExpires 
        Assert-True $user.Enabled
        Assert-Equal $username $user.SamAccountName
        Assert-False $user.UserCannotChangePassword
        Assert-Equal $fullName $user.DisplayName
        Assert-Credential -Password $password
    }
    finally
    {
        $user.Dispose()
    }
}

function Test-ShouldUpdateExistingUsersProperties
{
    $fullName = 'Carbon Install User'
    $result = Install-User -Username $username -Password $password -Description "Original description" -FullName $fullName
    Assert-Null $result

    $originalUser = Get-User -Username $username
    Assert-NotNull $originalUser
    try
    {
    
        $newFullName = 'New {0}' -f $fullName
        $newDescription = "New description"
        $newPassword = 'IM33tRequ!re$2'
        $result = Install-User -Username $username `
                               -Password $newPassword `
                               -Description $newDescription `
                               -FullName $newFullName `
                               -UserCannotChangePassword `
                               -PasswordExpires 
        try
        {
            Assert-Null $result
        }
        finally
        {
            if( $result )
            {
                $result.Dispose()
            }
        }

        [DirectoryServices.AccountManagement.UserPrincipal]$newUser = Get-User -Username $username
        Assert-NotNull $newUser
        try
        {
            Assert-Equal $originalUser.SID $newUser.SID
            Assert-Equal $newDescription $newUser.Description
            Assert-Equal $newFullName $newUser.DisplayName
            Assert-False $newUser.PasswordNeverExpires
            Assert-True $newUser.UserCannotChangePassword
            Assert-Credential -Password $newPassword
        }
        finally
        {
            $newUser.Dispose()
        }
    }
    finally
    {
        $originalUser.Dispose()
    }
}

function Test-ShouldUpdateExistingUsersPropertiesWithCredential
{
    $fullName = 'Carbon Install User'
    $credential = New-Credential -Username $username -Password $password
    $result = Install-User -Credential $credential -Description "Original description" -FullName $fullName
    try
    {
        Assert-Null $result
    }
    finally
    {
        if( $result )
        {
            $result.Dispose()
        }
    }

    $originalUser = Get-User -Username $username
    Assert-NotNull $originalUser
    try
    {
    
        $newFullName = 'New {0}' -f $fullName
        $newDescription = "New description"
        $newPassword = [Guid]::NewGuid().ToString().Substring(0,14)
        $credential = New-Credential -UserName $username -Password $newPassword
        
        $result = Install-User -Credential $credential `
                               -Description $newDescription `
                               -FullName $newFullName `
                               -UserCannotChangePassword `
                               -PasswordExpires 
        try
        {
            Assert-Null $result
        }
        finally
        {
            if( $result )
            {
                $result.Dispose()
            }
        }

        [DirectoryServices.AccountManagement.UserPrincipal]$newUser = Get-User -Username $username
        Assert-NotNull $newUser
        try
        {
            Assert-Equal $originalUser.SID $newUser.SID
            Assert-Equal $newDescription $newUser.Description
            Assert-Equal $newFullName $newUser.DisplayName
            Assert-False $newUser.PasswordNeverExpires
            Assert-True $newUser.UserCannotChangePassword
            Assert-Credential -Password $newPassword
        }
        finally
        {
            $newUser.Dispose()
        }
    }
    finally
    {
        $originalUser.Dispose()
    }
}

function Test-ShouldAllowOptionalFullName
{
    $fullName = 'Carbon Install User'
    $description = "Test user for testing the Carbon Install-User function."
    $result = Install-User -Username $username -Password $password -Description $description
    try
    {
        Assert-Null $result
    }
    finally
    {
        if( $result )
        {
            $result.Dispose()
        }
    }

    $user = Get-User -Username $Username
    try
    {
        Assert-Null $user.DisplayName
    }
    finally
    {
        $user.Dispose()
    }
}

function Test-ShouldSupportWhatIf
{
    $user = Install-User -Username $username -Password $password -WhatIf -PassThru
    try
    {
        Assert-NotNull $user
    }
    finally
    {
        $user.Dispose()
    }

    $user = Get-User -Username $username -ErrorAction SilentlyContinue
    try
    {
        Assert-Null $user
    }
    finally
    {
        if( $user )
        {
            $user.Dispose()
        }
    }
}

function Assert-Credential
{
    param(
        $Password
    )

    try
    {
        $ctx = [DirectoryServices.AccountManagement.ContextType]::Machine
        $px = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' $ctx,$env:COMPUTERNAME
        Assert-True ($px.ValidateCredentials( $username, $password ))
    }
    finally
    {
        $px.Dispose()
    }
}

