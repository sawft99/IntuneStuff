#Remediates by enabling local admin

$User = Get-LocalUser | Where-Object -Property Name -eq "LocalAdminName"

if (($null -eq $User) -or ($User.Count -eq 0)) {
    Write-Host "LocalAdminName account not found"
    exit 2
} else {
    if ($User.Enabled -eq $true) {
        Write-Host "LocalAdminName account is already enabled"
        exit 0
    } elseif ($User.Enabled -eq $false) {
        Write-Host "LocalAdminName account is disabled"
        exit 1
    } else {
        Write-Host "Unknown error in script"
        exit 2
    }
}

if ($EXITCODE -eq 1) {
    Enable-LocalUser $User.Name
    $User = Get-LocalUser | Where-Object -Property Name -eq "LocalAdminName"
    if (($null -eq $User) -or ($User.Count -eq 0)) {
        Write-Host "LocalAdminName account not found"
        exit 2
    } else {
        if ($User.Enabled -eq $true) {
            Write-Host "LocalAdminName account is now enabled"
            exit 0
        } elseif ($User.Enabled -eq $false) {
            Write-Host "LocalAdminName account is still disabled"
            exit 2
        } else {
            Write-Host "Unknown error in script"
            exit 2
        }
    }
}
