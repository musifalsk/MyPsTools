

Get-ChildItem HKLM:\SYSTEM\

$keyPath = 'HKLM:\'
$keyPath = 'HKLM:\SYSTEM\'
$keyPath = 'HKLM:\SYSTEM\CurrentControlSet'
$keyPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\'
$keyPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\'
$keyPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'

$searchValue = 'PSModulePath'
$searchValueProperty = 'C:\\Dev\\PSModules'
$searchKey = 'Session Manager'

<#
Get-ChildItem
Get-Item
Get-ItemProperty
Get-ItemPropertyValue
#>


# Search Value
$result = Get-ChildItem $keyPath -Recurse -ErrorAction Ignore | ForEach-Object { $_ | Select-String -Pattern $searchValue }
$result = Get-ChildItem $keyPath -Recurse -ErrorAction Ignore | Where-Object { $_.property -match $searchValue }
$result = Get-ChildItem $keyPath -Recurse -ErrorAction Ignore | Where-Object { $_.property -match $searchValue }
$result
(Get-ItemProperty $result.PSPath).PSModulePath


# Search Value-property
$result = Get-ChildItem $keyPath -Recurse -ErrorAction Ignore
$result.count

Measure-Command {
    $result | ForEach-Object -Parallel {
        $r = $_
        if ($r | Out-String | Select-String -Pattern $using:searchValueProperty) {
            return (Get-ItemProperty -Path $r.PSPath)
        }
    } -ThrottleLimit 50
}

<#
Measure-Command {
    $result | ForEach-Object -Parallel {
        $r = $_
        if ($r | Out-String | Select-String -Pattern $using:searchValueProperty) {
            ($r | Get-ItemProperty | Get-Member -MemberType NoteProperty) | ForEach-Object {
                if ((Get-ItemProperty $r.PSPath).$($_.Name) | Select-String -Pattern $using:searchValueProperty) {
                    $member = $_
                    return [PSCustomObject]@{
                        Key      = (Get-ItemProperty $r.PSPath).PSPath
                        Value    = $member.Name
                        Property = (Get-ItemProperty $r.PSPath).$($member.Name)
                    }
                }
            }
        }
    } -ThrottleLimit 500
}
#>


# Search Key
$result = Get-ChildItem $keyPath -Recurse -ErrorAction Ignore | Where-Object { $_.PSChildName -match $searchKey }
$result | Select-Object PSDrive, PSParentPath, PSChildName, PSIsContainer, property


Get-Item HKLM:\ | Select-Object *
Get-Item HKLM:\SYSTEM | Select-Object *
Get-ChildItem HKLM:\SYSTEM | Select-Object PSDrive, PSParentPath, PSChildName, PSIsContainer, property




Get-Item $keyPath
Get-ItemProperty $keyPath
Test-Path $keyPath

$searchstring = 'C:\Dev\PSModules'

$prop = Get-ItemProperty "$keyPath"

$arr = $prop.PSModulePath -split ';'
$prop.PSModulePath = ($arr[0..2]).ToString()

Set-ItemProperty -Path $keyPath -Name 'PSModulePath' -Value $prop.PSModulePath




# Recursively search through subkeys
function Search-RegistryEntry {
    param(
        $registryEntry = 'PSModulePath',
        $keyPath = 'HKLM:\'
    )

    # Get the current registry key
    $key = Get-Item -LiteralPath $keyPath

    # Check if the specified entry exists in the current key
    if ($key.PSObject.Properties.Name -contains $registryEntry) {
        $searchValue = $key.$registryEntry
        Write-Host "Registry entry '$registryEntry' found at $($keyPath): $searchValue"
    }

    # Recursively search through subkeys
    $subkeys = Get-Item -LiteralPath $keyPath | Get-Item -ErrorAction SilentlyContinue | Get-Item -LiteralPath | Get-Item -ErrorAction SilentlyContinue | Get-ChildItem -ErrorAction SilentlyContinue
    if ($subkeys -ne $null) {
        foreach ($subkey in $subkeys) {
            Search-RegistryEntry $subkey.PSPath
        }
    }
}

# Start the search from the root
Search-RegistryEntry $rootPath
