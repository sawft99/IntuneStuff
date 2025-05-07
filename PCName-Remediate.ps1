#Script to change PC name from default random generated name (DESKTOP-*) to a template based name. If the name is customized in some other way, it is not changed. Example: DT-ABC123 would not be changed

$Prefix = 'INTU-'
$PCInfo = Get-ComputerInfo
#Use FailBackRename if first generated PC name ends up being too long
$FailBack = $true
#Use BIOS Serial as $Suffix. PS5 has a typo for BIOSSeral which is corrected in PS7 to BIOSSerial, thus the 2 versions
if ($PCInfo.BiosSerialNumber.Length -gt 0) {
    $Suffix = $PCInfo.BiosSerialNumber
} elseif ($PCInfo.BiosSeralNumber.Length -gt 0) {
    $Suffix = $PCInfo.BiosSeralNumber
} else {
    $Suffix = $null
}

#-----------

#Check variable values
if ($Prefix.Length -lt 1) {
    Write-Output '$Prefix must be at least 1 character'
    exit 1
}
if ($null -eq $PCInfo) {
    Write-Output 'Error gettig $PCInfo'
    exit 1
}
if ($FailBack -ne $true -and $FailBack -ne $false) {
    Write-Output '$FailBack must be $true or $false'
    exit 1
}
if (($FailBack -eq $false) -and ($Suffix.Length -lt 1)) {
    Write-Output 'Error getting $Suffix or not specified'
    exit 1
}

#Check if PC name uses default scheme
if ($PCInfo.CSName -like 'DESKTOP-*') {
    Write-Output 'PC matches default scheme, changing'
} elseif ($PCInfo.CsName -eq $Prefix) {
    Write-Output 'PC name equals $Prefix, changing'
} else {
    Write-Output 'PC does not match default scheme or equal $Prefix, exiting'
}

#FailBack rename function, automatically fills out to 15 characters by subtracting difference of $Prefix
function FailBackRename {
    $Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.ToCharArray()
    $BackupSuffix = ($Chars | Get-Random -Count (15 - $Prefix.Length)) -join ''
    $BackupSuffix
}

#Rename PC function
function RenamePC {
    $Error.Clear()
    Rename-Computer $PCNameString -Force
    if ($Error.length -lt 1) {
        Write-Output "PC renamed to $PCNameString"
        exit 0
    } else {
        Write-Output 'Error renaming'
        exit 1
    }
}

#Create PC name
$PCNameString = $Prefix + $Suffix

#If new PC name is too long, $Suffix not set, or new PC name is less than or equal to $Prefix length
if (($PCNameString.Length -gt 15) -or ($Suffix.Length -lt 1) -or ($PCInfo.CsName -eq $Prefix) -or ($PCNameString -eq $Prefix) -or ($PCNameString -le $Prefix.Length)) {
    #If FailBack var is $true, generate a random suffix to fill full 15 characters
    if ($FailBack -eq $true) {
        if ($PCNameString.Length -gt 15) {
            Write-Output "PC name $PCNameString is too long, using FailBack"
        } elseif ($Suffix.Length -lt 1) {
            Write-Output '$Suffix is too short, using FailBack'
        } elseif ($PCInfo.CsName -eq $Prefix){
            Write-Output 'Original PC name matches prefix only, using FailBack'
        } elseif ($PCNameString -eq $Prefix) {
            Write-Output 'Generated PC name matches $Prefix only, using FallBack'
        } else {
            Write-Output 'Some other error occurred'
        }
        #Create valid suffix with FailBack function
        $Suffix = FailBackRename
        #Recreate valid PC name
        $PCNameString = $Prefix + $Suffix
        RenamePC
    } else {
        #If FailBack var is $false report error
        if ($PCNameString.Length -gt 15) {
            Write-Output "PC name $PCNameString is too long, not using FailBack"
        } else {
            Write-Output "PC name $PCNameString had an error getting the $Suffix, not using FailBack"
        }
        exit 1
    }
} else {
    RenamePC
}
