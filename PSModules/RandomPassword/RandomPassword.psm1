<#
.SYNOPSIS
    Generates a random password
.DESCRIPTION
    This function generates a random password with a specified length (Default: 32).
    The password will contain lowercase letters, uppercase letters, numbers and special characters.
    The password can be generated as a SecureString by using the -Secure switch.
.PARAMETER Length
    The length of the password in characters
.PARAMETER Secure
    Generate the password as a SecureString
.EXAMPLE
    New-RandomPassword
.EXAMPLE
    New-RandomPassword -Length 16
.EXAMPLE
    New-RandomPassword -Length 24 -Secure
.LINK
    Report an issue: https://github.com/musifalsk/MyPsTools
#>

function Get-RandomPassword {
    [Alias('Generate-RandomPassword', 'New-RandomPassword')]
    param(
        [int]$Length = 32,
        [switch]$Secure
    )

    $chars = @()
    do { $chars += ('a'..'z' | Get-Random -Count 1) } until ($chars.Length -gt ($Length * 1 / 4 - 1))
    do { $chars += ('A'..'Z' | Get-Random -Count 1) } until ($chars.Length -gt ($Length * 2 / 4 - 1))
    do { $chars += ('0'..'9' | Get-Random -Count 1) } until ($chars.Length -gt ($Length * 3 / 4 - 1))
    do { $chars += ('!', '@', '#', '$', '%', '&', '=', '+', '-', '?', '^', '*', '.', ',' | Get-Random -Count 1) }
    until ($chars.Length -gt ($Length - 1))
    $pw = -join ($chars | Sort-Object { Get-Random })
    if ($Secure) { $pw = $pw | ConvertTo-SecureString -AsPlainText -Force }
    return $pw
}
