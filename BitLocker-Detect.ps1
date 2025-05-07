#Check if Bitlocker is set to policy settings

# https://learn.microsoft.com/en-us/windows/win32/secprov/getencryptionmethod-win32-encryptablevolume#parameters
$EncryptionLevel = 'XtsAes256'
#$DriveType = 'FullyEncrypted'
$Drive = $Env:SystemDrive

#--------

$BLStatus = Get-BitLockerVolume -MountPoint $Drive

if (($BLStatus.EncryptionMethod -eq $EncryptionLevel) -and ($BLStatus.VolumeStatus -ne $DriveType) -and ($BLStatus.VolumeStatus -notmatch 'InProgress')) {
    Write-Host "Bitlocker settings for $Drive matches requirements."
    exit 0
} elseif ($BLStatus.VolumeStatus -match 'InProgress') {
    Write-Host "Bitlocker is encrypting or decrypting for $Drive at $($BLStatus.EncryptionPercentage)%. Check later." 
    exit 0
} else {
    Write-Host "Bitlocker settings for $Drive does not match requirements."
    exit 1
}
