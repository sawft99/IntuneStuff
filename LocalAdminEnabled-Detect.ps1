#Detects if local admin is enabled

$User = Get-LocalUser | Where-Object -Property Name -eq "AdminAccountName"

if (($null -eq $User) -or ($User.Count -eq 0)) {
    Write-Host "Admin account not found"
    exit 2
} else {
    if ($User.Enabled -eq $true) {
        Write-Host "Admin account is enabled"
        exit 0
    } elseif ($User.Enabled -eq $false) {
        Write-Host "Admin account is disabled"
        exit 1
    } else {
        Write-Host "Admin error in script"
        exit 2
    }
}
