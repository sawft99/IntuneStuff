#Open OneDrive for likely the first time to trigger a sync
#Also get rid of extra OneDrive folder if present

[System.IO.FileInfo]$OneDriveEXE1 = $env:ProgramFiles + '\Microsoft OneDrive\OneDrive.exe'
[System.IO.FileInfo]$OneDriveEXE2 = $env:LOCALAPPDATA + '\Microsoft\OneDrive\OneDrive.exe'
$AllOneDrives = Get-ChildItem $env:USERPROFILE | Where-Object -Property Name -Match 'OneDrive'

#--------------

if ($OneDriveEXE1.Exists -eq $true) {
    [System.IO.FileInfo]$OneDriveEXE = $OneDriveEXE1.FullName
} elseif ($OneDriveEXE2.Exists -eq $true) {
    [System.IO.FileInfo]$OneDriveEXE = $OneDriveEXE2.FullName
} else {
    Write-Output 'No OneDrive app found'
    exit 1
}

#-----------

[System.IO.DirectoryInfo]$OneDriveTest = $env:OneDrive

if ($OneDriveTest.Exists -eq $true) {
    Write-Output 'OneDrive folder exists'
    $LASTEXITCODE = 0
} else {
    Write-Output 'OneDrive folder does not exist, starting...'
    Start-Process $OneDriveEXE.FullName -WorkingDirectory $OneDriveEXE.Directory
    Write-Output 'Waiting 60 seconds...'
    Start-Sleep 60
    $LASTEXITCODE = 1
}

if ($null -ne $OneDriveTest) {
    Remove-Variable OneDriveTest
}

#Because environment variables don't reload in the same session. May not work and 2nd run will return the proper value
$OneDriveTest = Powershell -Command {(Get-ChildItem env:* | Where-Object -Property Name -eq 'OneDrive').Value | Test-Path}

if ($OneDriveTest -eq $true) {
    Write-Output 'OneDrive folder now exists'
    $LASTEXITCODE = 0
} else {
    Write-Output 'OneDrive folder still does not exist'
    Start-Process $OneDriveEXE.FullName -WorkingDirectory $OneDriveEXE.Directory
    Write-Output 'Waiting 60 seconds...'
    Start-Sleep 60
    $LASTEXITCODE = 1
    if ($null -ne $OneDriveTest) {
        Remove-Variable OneDriveTest
    }
    $OneDriveTest = Powershell -Command {(Get-ChildItem env:* | Where-Object -Property Name -eq 'OneDrive').Value | Test-Path}
    if ($OneDriveTest -eq $true) {
        Write-Output 'OneDrive folder now exists'
        $LASTEXITCODE = 0
    } else {
        Write-Output 'OneDrive folder still does not exist'
        $LASTEXITCODE = 1
    }
}

#Remove duplicate OneDrive folder if it exists
if (($AllOneDrives.Count -gt 1) -and ($LASTEXITCODE -lt 1)) {
    Write-Output 'More than 1 OneDrive folder found'
    foreach ($Folder in $AllOneDrives) {
        $Files = Get-ChildItem -Path $Folder.FullName
        if ($null -eq $Files) {
            Write-Output "Empty: $($Folder.FullName), removing..."
            Remove-Item $Folder.FullName -Force -Recurse
            [System.IO.DirectoryInfo]$DeleteConfirm = $Folder.FullName
            if ($DeleteConfirm.Exists -eq $true) {
                Write-Output "Failed to delete: $($Folder.FullName)"
                $LASTEXITCODE = 1
            } else {
                Write-Output "Removed: $($Folder.FullName)"
                $LASTEXITCODE = 0
            }
        } else {
            Write-Output "Files in folder, skipping: $($Folder.FullName)"
        }
    }
    $AllOneDrives = Get-ChildItem $env:USERPROFILE | Where-Object -Property Name -Match 'OneDrive'
    if ($AllOneDrives.Count -gt 1) {
        Write-Output 'Failed to remove extra OneDrive folders'
        $LASTEXITCODE = 1
    } else {
        Write-Output 'Extra OneDrive folders removed'
        $LASTEXITCODE = 0
    }
}

if ($Error.Count -gt 0) {
    Write-Output 'Ran into other errors'
    $LASTEXITCODE = 1
}

exit $LASTEXITCODE
