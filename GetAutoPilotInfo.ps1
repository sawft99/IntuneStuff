#Get info needed for AutoPilot and makes a csv you can upload to the AutoPilot portal
#Does not rely on any extra PS modules
#Requires -RunAsAdministrator
#Outputs to current logged in/console session user
[System.IO.FileInfo]$CSVFile = $env:SystemDrive + '\Users\' + ((Get-CimInstance -ClassName Win32_ComputerSystem).UserName -split '\\')[1] + '\Downloads\APInfo.csv'
$AssignedUser = $null #UPNFormat@domain.com

#-------------

Clear-Host
$Error.Clear()

Write-Host '===========
Get AP Info
===========
'
Write-Host "Output file: $($CSVFile.FullName)
"
Write-Host 'Do CTRL+C now if this path is wrong and change the $CSVFile variable
'
pause
Write-Host ''

#Check if CSV directory exists
if ($CSVFile.Directory.Exists -eq $false) {
    Write-Host -ForegroundColor Red 'CSV file directory does not exist, exiting
    '
    pause
    exit 1
}

#Delete CSV file if it exists
if ($CSVFile.Exists -eq $true) {
    Write-Host -ForegroundColor Yellow 'CSV file already exists, removing
    '
    Remove-Item -Path $CSVFile.FullName -Force
    [System.IO.FileInfo]$CSVFile = $CSVFile.FullName
    if ($CSVFile.Exists -eq $true) {
        Write-Host -ForegroundColor Red 'CSV file could not be removed, exiting
        '
        pause
        exit 1
    } else {
        Write-Host -ForegroundColor Green 'CSV file removed, continuing
        '
    }
}

#Get computer info. Only need Serial and Hardware Hash
Write-Host 'Getting computer info...
'
$Serial = (Get-CimInstance -Class Win32_BIOS).SerialNumber
$HardwareHash = (Get-CimInstance -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'").DeviceHardwareData

#Check if $Serial and $HardwareHash have values
if (($null -eq $Serial) -or ($null -eq $HardwareHash) -or ($Error.Count -gt 0)) {
    Write-Host -ForegroundColor Red 'Could not get serial or hardware hash, exiting
    '
    pause
    exit 1
} else {
    Write-Host -ForegroundColor Green 'Got info with no errors
    '
}

#Create CSV object
$CSVInfo = New-Object psobject -Property @{
    'Device Serial Number' = $Serial
    'Windows Product ID' = $null
    'Hardware Hash' = $HardwareHash
    'Group Tag' = $null
    'Assigned User' = $AssignedUser
}

#Export info to CSV file
$CSVInfo | Select-Object 'Device Serial Number','Windows Product ID','Hardware Hash','Group Tag','Assigned User' | Export-Csv $CSVFile.FullName -NoClobber -NoTypeInformation -Force

#Check for file
[System.IO.FileInfo]$CSVFile = $CSVFile.FullName

if ($CSVFile.Exists -eq $true) {
    Write-Host -ForegroundColor Green 'File exported
    '
} else {
    Write-Host -ForegroundColor Red 'Failed to export file
    '
    pause
    exit 1
}

#Check for other errors
if ($Error.Length -lt 1) {
    Write-Host -ForegroundColor Green 'Done, no errors
    '
    pause
    exit 0
} else {
    Write-Host -ForegroundColor Red 'Done, but with errors
    '
    $Error
    pause
    exit 1
}
