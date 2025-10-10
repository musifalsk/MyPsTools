<#
.SYNOPSIS
    Generates a random hex key
.DESCRIPTION
    This function generates a random hex key with a specified length (Default: 64).
    The hex key will contain lowercase letters and numbers.
    The hex key can be generated as a SecureString by using the -Secure switch.
.PARAMETER Length
    The length of the hex key in characters
.PARAMETER Secure
    Generate the hex key as a SecureString
.EXAMPLE
    New-RandomHexKey
.EXAMPLE
    New-RandomHexKey -Length 16
.EXAMPLE
    New-RandomHexKey -Length 24 -Secure
.LINK
    Report an issue: https://github.com/musifalsk/MyPsTools
#>

function Get-RandomHexKey {
    [Alias('Generate-RandomHexKey', 'New-RandomHexKey')]
    param(
        [int]$Length = 64,
        [switch]$Secure
    )

    $chars = @()
    do { $chars += ('a'..'f' | Get-SecureRandom -Count 1) } until ($chars.Length -gt ($Length * 1 / 4 - 1))
    do { $chars += ('0'..'9' | Get-SecureRandom -Count 1) } until ($chars.Length -gt ($Length * 4 / 4 - 1))
    $pw = -join ($chars | Sort-Object { Get-SecureRandom })
    if ($Secure) { $pw = $pw | ConvertTo-SecureString -AsPlainText -Force }
    return $pw
}
