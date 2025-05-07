#Detect scheduled task for user, used as detection script for win32 app
[System.IO.DirectoryInfo]$IntuneScriptFolder = $env:SystemDrive + '\' + 'IntuneScripts'
[System.IO.FileInfo]$MapDriveScript = $IntuneScriptFolder.FullName + '\MappedDrives-App.ps1'
$CurrentLoggedInUser = (Get-WmiObject -Class Win32_Computersystem | Select-Object -Property Username).UserName
$CurrentLoggedInUserShort = ($CurrentLoggedInUser -split '\\')[1]
$TaskRoot = Get-ChildItem 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks'

#---------

#Find mapped drive task for specific user
$Tasks = $TaskRoot | Where-Object {$_.GetValue('URI') -match "\\Map_Network_Drives_$CurrentLoggedInUserShort"}

if ($Tasks.Count -gt 0) {
    Write-Output "Mapped drive task for user $CurrentLoggedInUserShort found"
    $LASTEXITCODE = 0
} else {
    Write-Output "Mapped drive task for user $CurrentLoggedInUserShort not found"
    $LASTEXITCODE = 1
}

#Check if script folder exists
if ($IntuneScriptFolder.Exists -ne $true) {
    Write-Output 'Intune script folder does not exist'
    $LASTEXITCODE = 1
}

#Check if script exists
if ($MapDriveScript.Exists -ne $true) {
    Write-Output 'Mapped drive script not found'
    $LASTEXITCODE = 1
}

exit $LASTEXITCODE
