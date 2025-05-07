#Detect folder and permissions for scripts

[System.IO.DirectoryInfo]$Folder = $env:SystemDrive + '\IntuneScripts'

#---------

if ($Folder.Exists -ne $true) {
    Write-Output 'Folder does not exist'
    exit 1
} else {
    Write-Output 'Folder exists'
    exit 0
}
