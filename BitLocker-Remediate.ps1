#Check if Bitlocker is set to policy settings and undo encryption if it's not
#Allows for policy to correct on its own

$EncryptionLevel = 'XtsAes256'
$DriveType = 'FullyEncrypted'
$Drive = $Env:SystemDrive

#--------

$BLStatus = Get-BitLockerVolume -MountPoint $Drive

if (($BLStatus.EncryptionMethod -eq $EncryptionLevel) -and ($BLStatus.VolumeStatus -ne $DriveType) -and ($BLStatus.VolumeStatus -notmatch 'InProgress')) {
    Write-Host "Bitlocker settings for $Drive matches requirements."
    exit 0
} elseif ($BLStatus.VolumeStatus -match 'InProgress') {
    Write-Host "Bitlocker is encrypting or decrypting for $Drive at $($BLStatus.EncryptionPercentage)%. Check later." 
    exit 1
} elseif ($BLStatus.VolumeStatus -eq 'FullyDecrypted') {
    Write-Host "Encryption already undone for $Drive, wait for policy to take effect"
    exit 1
} else {
    Write-Host "Removing encryption for $Drive"
    Disable-BitLocker -MountPoint $Drive
    Start-Sleep -Seconds 5
    $BLStatus = Get-BitLockerVolume -MountPoint $Drive
    if ($BLStatus.VolumeStatus -match 'InProgress') {
        Write-Host "Decryption for $Drive in progress"
        exit 1
    } else {
        Write-Host "Decryption did not start for $Drive for some reason"
        exit 1
    }
}
