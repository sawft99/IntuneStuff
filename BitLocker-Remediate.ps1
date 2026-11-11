#Check if Bitlocker is set to policy settings and undo encryption if it's not. Allows for policy to correct on its own
#Make sure to use run as 64 bit option in Intune remediation script

#https://learn.microsoft.com/en-us/windows/win32/secprov/getencryptionmethod-win32-encryptablevolume#parameters
$EncryptionLevel = 'XtsAes256'
$DiskEncryptType = 'Fully Encrypted' #Or "Used Space Only Encrypted"
$Drive = $Env:SystemDrive

#--------

$BLStatus1 = Get-BitLockerVolume -MountPoint $Drive
$BLStatus2 = manage-bde -status $Drive | Select-String "Conversion Status:"

if (($BLStatus1.EncryptionMethod -eq $EncryptionLevel) -and ($BLStatus2 -match $DiskEncryptType) -and ($BLStatus1.VolumeStatus -notmatch 'InProgress')) {
    Write-Host "Bitlocker settings for $Drive matches requirements."
    exit 0
} elseif ($BLStatus1.VolumeStatus -match 'InProgress') {
    Write-Host "Bitlocker has $($BLStatus1.VolumeStatus) for $Drive at $($BLStatus1.EncryptionPercentage)%. Check later."
    exit 1
} elseif ($BLStatus1.VolumeStatus -eq 'FullyDecrypted') {
    Write-Host "Encryption already undone for $Drive, wait for policy to take effect"
    exit 1
} else {
    Write-Host "Removing encryption for $Drive"
    Disable-BitLocker -MountPoint $Drive
    Start-Sleep -Seconds 5
    $BLStatus1 = Get-BitLockerVolume -MountPoint $Drive
    if ($BLStatus1.VolumeStatus -match 'InProgress') {
        Write-Host "Decryption for $Drive in progress"
        exit 1
    } else {
        Write-Host "Decryption did not start for $Drive for some reason"
        exit 1
    }
}
