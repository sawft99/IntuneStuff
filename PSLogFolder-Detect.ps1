#Detect PS logging folder and permissions
#Folder goal(s):
# 1. To record all powershell commands ran on the system by both a user, admin, and system account
# 2. Users need to be able to write new files to the folder but not modify the existing files/folder
# 3. This allows commands to be recorded but not have the record edited

[System.IO.DirectoryInfo]$Folder = $env:SystemDrive + '\PSLogging'

#---------

#Check if folder exists
if ($Folder.Exists -ne $true) {
    Write-Output 'PSLogging folder does not exist'
    exit 1
} else {
    Write-Output 'PSLogging folder exists'
    #exit 0
}

#Get current permissions
$Permissions = Get-Acl $Folder.FullName

#Desired permissions
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

#Check if there are extra permissions
if ($Permissions.Access.Count -ne $RuleList.Count) {
    Write-Host 'Extra permissions detected'
    $LASTEXITCODE = 1
}

#Check that all permissions match
foreach ($Rule in $RuleList) {
    $GroupTest = $Permissions.Access | Where-Object -Property IdentityReference -eq $Rule.ID
    if ($GroupTest.Count -lt 1) {
        Write-Host "Could not find an entry for $($Rule.ID)"
        $LASTEXITCODE = 1
    } else {
        Write-Host "Found entry for $($Rule.ID)"
        if ($GroupTest.FileSystemRights -ne $Rule.Rights) {
            Write-Host "Permissions did not match for $($Rule.ID)"
            $LASTEXITCODE = 1
        } else {
            Write-Host "Permissions match for $($Rule.ID)"
            $LASTEXITCODE = 0
        }
    }
}

exit $LASTEXITCODE
