#Check if PC name is a default name

$PCInfo = Get-ComputerInfo
$Prefix = 'INTU-'

#-----------

if ($null -eq $PCInfo) {
    Write-Output 'Error getting $PCInfo'
    exit 1
}

#Check if PC name uses default scheme
if ($PCInfo.CSName -like 'DESKTOP-*') {
    Write-Output 'PC matches default scheme, need to change'
    exit 1
} elseif ($PCInfo.CsName -eq $Prefix) {
    Write-Output 'PC name equals $Prefix, need to change'
    exit 1
} else {
    Write-Output 'PC does not match default scheme or equal $Prefix, exiting'
    exit 0
}
