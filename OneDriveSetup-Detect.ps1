#Check if Onedrive folder exists and if there is a duplicate one

[System.IO.DirectoryInfo]$OneDriveTest = $env:OneDrive
$AllOneDrives = Get-ChildItem $env:USERPROFILE | Where-Object -Property Name -Match 'OneDrive'

#---------------

if ($OneDriveTest.Exists -eq $true) {
    Write-Output 'OneDrive folder exists'
    $LASTEXITCODE = 0
} else {
    Write-Output 'OneDrive folder does not exist'
    $LASTEXITCODE = 1
}
if ($AllOneDrives.Count -gt 1) {
    Write-Output 'More than 1 OneDrive folder found'
    $LASTEXITCODE = 1
}

exit $LASTEXITCODE
