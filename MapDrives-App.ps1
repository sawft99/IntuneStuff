#Map drives for users
$DriveLetters = @('E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')
$UsedDrives = Get-PSDrive | Where-Object -Property Name -in $DriveLetters
#Folder for script to copy itself to & run from
[System.IO.DirectoryInfo]$IntuneScriptFolder = $env:SystemDrive + '\' + 'IntuneScripts'
$CurrentLoggedInUser = (Get-WmiObject -Class Win32_Computersystem | Select-Object -Property Username).UserName
$CurrentLoggedInUserShort = ($CurrentLoggedInUser -split '\\')[1]
[System.IO.FileInfo]$IntuneErrorLog = "$($IntuneScriptFolder.FullName)\MapDriveErrors.txt"

#--------

Write-Output '
==========
Map Drives
==========
'

#If script folder does not exist, exit
if ($IntuneScriptFolder.Exists -ne $true) {
    Write-Output 'Intune script folder does not exist' | Out-File $IntuneErrorLog -Append
    $LASTEXITCODE = 1
}

#Copy self to script folder
[System.IO.FileInfo]$ScriptLocation = $PSScriptRoot + '\MappedDrives-App.ps1'

if (!($ScriptLocation.FullName.StartsWith($IntuneScriptFolder.FullName)) -and ($LASTEXITCODE -lt 1)) {
    Copy-Item $ScriptLocation.FullName "$($IntuneScriptFolder.FullName)" -Force
    [System.IO.FileInfo]$ScriptLocation = "$($IntuneScriptFolder.FullName)\MappedDrives-App.ps1"
    if (($ScriptLocation.Exists -ne $true)) {
        Write-Output 'Script not found' | Out-File $IntuneErrorLog -Append
        $LASTEXITCODE = 1
    }
} else {
    [System.IO.FileInfo]$ScriptLocation = $IntuneScriptFolder.FullName + '\MappedDrives-App.ps1'
}

#Create scheduled task
if (!($Error.Count -gt 0 -or $LASTEXITCODE -gt 0)) {
    $CurrentTasks = Get-ScheduledTask | Select-Object -Property * | Where-Object -Property TaskName -EQ "Map_Network_Drives_$CurrentLoggedInUserShort"
    if ($null -eq $CurrentTasks) {
        Write-Output 'Task not found, creating...' | Out-File $IntuneErrorLog -Append
        if ($ScriptLocation.Exists -ne $true) {
            Write-Output 'Script not found' | Out-File $IntuneErrorLog -Append
            $LASTEXITCODE = 1
        } else {
            $Trigger = New-ScheduledTaskTrigger -AtLogOn -User $CurrentLoggedInUser
            $Action = New-ScheduledTaskAction -Execute "Powershell" -Argument "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File $($ScriptLocation.FullName)" -WorkingDirectory $IntuneScriptFolder.FullName
            Register-ScheduledTask -TaskName "Map_Network_Drives_$CurrentLoggedInUserShort" -Action $Action -Trigger $Trigger -User $CurrentLoggedInUser -Description 'Maps drives for users' #-TaskPath '\*'
            $CurrentTasks = Get-ScheduledTask | Select-Object -Property * | Where-Object -Property TaskName -EQ "Map_Network_Drives_$CurrentLoggedInUserShort"
            if ($null -eq $CurrentTasks) {
                Write-Output 'Task not created for some reason' | Out-File $IntuneErrorLog -Append
                $LASTEXITCODE = 1
            } else {
                Write-Output 'Task created' | Out-File $IntuneErrorLog -Append
                $LASTEXITCODE = 0
            }
        }
    }
} else {
    Write-Output 'Some other error occurred, exiting...' | Out-File $IntuneErrorLog -Append
    $LASTEXITCODE = 1
}

if ((($Error.Count -lt 1) -or ($LASTEXITCODE -lt 1)) -and ($env:USERNAME -eq $CurrentTasks.Principal.UserID)) {
    #Mapped drives info
    $Drives = @(
        [PSCustomObject]@{
            Name = 'Share1'
            Letter = 'F'
            Location = '\\Server\Share1'
        }
        [PSCustomObject]@{
            Name = 'Share2'
            Letter = 'G'
            Location = '\\Server\Share2'
        }
        [PSCustomObject]@{
            Name = 'Share3'
            Letter = 'H'
            Location = '\\Server\Share3'
        }
        [PSCustomObject]@{
            Name = $env:USERNAME
            Letter = 'P'
            Location = "\\Server\home\$($env:USERNAME)"
        }
    )

    #Find drives already mapped and drives that need to be mapped
    $AlreadyMappedDrives = $Drives | Where-Object {($_.Letter -in $UsedDrives.Name) -or ($_.Location -in $UsedDrives.DisplayRoot)}
    $NotMappedDrives = $Drives | Where-Object {($_.Letter -notin $UsedDrives.Name) -and ($_.Location -notin $UsedDrives.DisplayRoot)}

    Write-Output 'Skipping drives'
    Write-Output '---------------'

    if ($null -ne $AlreadyMappedDrives) {
        $AlreadyMappedDrives
        Write-Output ''
    } else {
        Write-Output ''
        Write-Output 'Not skipping any drives
        '
    }
    Write-Output 'Mapping drives'
    Write-Output '--------------
    '
    if ($null -eq $NotMappedDrives) {
        Write-Output 'All drives mapped or there are conflicting names/locations
        '
    } else {
        foreach ($Drive in $NotMappedDrives) {
            Write-Output "Mapping $($Drive.Letter) to $($Drive.Location)"
            New-PSDrive -Name $Drive.Letter -PSProvider 'FileSystem' -Root $Drive.Location -Persist -Description $Drive.Name | Out-Null
            $Rename = New-Object -ComObject Shell.Application
            $Rename.NameSpace("$($Drive.Letter):").Self.Name = $Drive.Name
            if ($null -ne $Rename) {
                Remove-Variable Rename -ErrorAction SilentlyContinue
            }
        }
        Write-Output ''
    }
    Write-Output 'Done'
}

# Error logging & cleanup
if (($LASTEXITCODE -eq 0) -and ($IntuneErrorLog.Exists -eq $true)) {
    Remove-Item $IntuneErrorLog.FullName -Force
}
if ($TaskXMLLocation.Exists -eq $true) {
    Remove-Item $TaskXMLLocation.FullName -Force
}
if ($NewXMLLocation.Exists -eq $true) {
    Remove-Item $NewXMLLocation.FullName -Force
}
if ($Error.Count -gt 0) {
    $Error | Out-File $IntuneErrorLog -Append
    $LASTEXITCODE = 1
} else {
    $LASTEXITCODE = 0
}

exit $LASTEXITCODE
