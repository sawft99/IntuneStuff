#Detect PS logging folder and permissions
#Folder goal(s):
# 1. To record all powershell commands ran on the system by both a user, admin, and system account
# 2. Users need to be able to write new files to the folder but not modify the existing files/folder
# 3. This allows commands to be recorded but not have the record edited

[System.IO.DirectoryInfo]$Folder = $env:SystemDrive + '\PSLogging'
$ComputerName = $env:COMPUTERNAME

#---------

#Check for folder and create if it doesn't exist
if ($Folder.Exists -ne $true) {
    Write-Output 'PSLogging folder does not exist, creating...'
    New-Item -Path $Folder.FullName -ItemType Directory | Out-Null
    [System.IO.DirectoryInfo]$Folder = $Folder.FullName
    if ($Folder.Exists -ne $true) {
        Write-Output 'Failed to create PSLogging folder'
        $LASTEXITCODE = 1
        exit $LASTEXITCODE
    }
}

#Get permissions
$Permissions = Get-Acl -Path $Folder.FullName -ErrorAction SilentlyContinue

#Desired permissions
if ($null -eq $Permissions) {
    Write-Output 'Error getting PSLogging folder permissions'
    $LASTEXITCODE = 1
} else {
    $RuleList = @(
        [PSCustomObject]@{
            ID = 'BUILTIN\Administrators'
            Principal = New-Object System.Security.Principal.NTAccount('BUILTIN', 'Administrators')
            Rights = 'FullControl'
            Inherit = 'ContainerInherit, ObjectInherit'
            Propogation = 'None'
            Type = 'Allow'
        }
        [PSCustomObject]@{
            ID = 'NT AUTHORITY\SYSTEM'
            Principal = New-Object System.Security.Principal.NTAccount('NT AUTHORITY', 'SYSTEM')
            Rights = 'FullControl'
            Inherit = 'ContainerInherit, ObjectInherit'
            Propogation = 'None'
            Type = 'Allow'
        }
        [PSCustomObject]@{
            ID = 'BUILTIN\Users'
            Principal = New-Object System.Security.Principal.NTAccount('BUILTIN', 'Users')
            Rights = 'ReadData, CreateFiles, Synchronize'
            Inherit = 'ContainerInherit, ObjectInherit'
            Propogation = 'None'
            Type = 'Allow'
        }
        [PSCustomObject]@{
            ID = 'NT AUTHORITY\Authenticated Users'
            Principal = New-Object System.Security.Principal.NTAccount('NT AUTHORITY', 'Authenticated Users')
            Rights = 'ReadData, CreateFiles, Synchronize'
            Inherit = 'ContainerInherit, ObjectInherit'
            Propogation = 'None'
            Type = 'Allow'
        }
    )
    
    # Create a new access control rule
    $FileSecurity = Get-Acl -Path $Folder.FullName
    #Set Administrators group as owners
    $FileSecurity.SetOwner($RuleList[0].Principal)
    #Remove old access rules
    $FileSecurity.SetAccessRuleProtection($true, $false)
    $FileSecurityRules = $FileSecurity.GetAccessRules($true, $true, [System.Security.Principal.NTAccount])
    foreach ($FSRule in $FileSecurityRules) {
        $FileSecurity.RemoveAccessRule($FSRule) | Out-Null
    }

    # Add each rule to the FileSecurity object
    foreach ($Rule in $RuleList) {
        $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $Rule.ID, 
            $Rule.Rights, 
            $Rule.Inherit, 
            $Rule.Propogation, 
            $Rule.Type
        )
        $FileSecurity.AddAccessRule($AccessRule) | Out-Null
    }
    Set-Acl -Path $Folder.FullName -AclObject $FileSecurity | Out-Null
}

if ($Error.Count -gt 0) {
    $LASTEXITCODE = 1
}

if ($Error.Count -gt 0 -or $LASTEXITCODE -gt 0) {
    Write-Output 'Error in script'
    exit $LASTEXITCODE
} else {
    Write-Output 'Script ran successfully'
    exit 0
}
