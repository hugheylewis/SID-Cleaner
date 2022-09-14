$directories = Read-Host "Enter the UNC path to remove broken SIDs from: "
Write-Output "Script started at $(Get-Date -Format hh:mm)"
# Error handling: Returns invalid characters used in path
$illegal = [Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
$pattern = "[$illegal]"

$invalid = [Regex]::Matches($directories, $pattern, 'IgnoreCase').Value | Sort-Object -Unique
$hasInvalid = $invalid -ne $null
if ($hasInvalid) {
    Write-Host "Do not use these characters in paths: $invalid"
    Exit
}
else {
    Write-Host "The specified path is valid, proceeding to disable inheritence..."
}

foreach ($userPath in $directories) {
    $acl = Get-Acl -path $userPath
    if ($?) {
        $acl.SetAccessRuleProtection($True, $True) 
        # Disables inheritence from propagating down from the root directory. Script will not remove SIDs until inheritence is disabled
        Set-Acl -Path $directories -AclObject $acl
        Write-Host "Disabling inheritence..."
    }
    else {
    Write-Host "[-] Error disabling inheritence. Exiting..."
    Exit
    }
    $BrokenSIDSearch = $acl.Access
    foreach ($sid in $BrokenSIDSearch) {
        $value = $sid.IdentityReference.Value
        $TrimPath = $userPath.Replace('Microsoft.PowerShell.Core\filesystem::','')
        if ($value -match "S-1-5-21*") {
            $acl.RemoveAccessRuleAll($sid)
            Set-Acl -Path $userPath -AclObject $acl
            Write-Host "Removing broken SIDs..."
        }
    }
}

Write-Host "Reapplying inheritence..."
$acl.SetAccessRuleProtection($False, $True)
Set-Acl -Path $directories -AclObject $acl -Verbose

