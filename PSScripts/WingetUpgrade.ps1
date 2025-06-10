

winget upgrade | Out-Default -OutVariable updateList

# Convert $updateList to PSObjects
$strings = $updateList -split "`n" | Where-Object { $_ -notmatch '^\s+' -and $_ -notmatch '^\s*$' -and $_ -notmatch '^-+$' }
$header = $strings[0]
$csv = @($header -replace '\s+', ',')
$strings[1..($strings.Count - 2)] | ForEach-Object {
    $name = $_.Substring($header.IndexOf('Name'), $header.IndexOf('Id'))
    $id = $_.Substring($header.IndexOf('Id'), ($header.IndexOf('Version') - $header.IndexOf('Id')))
    $version = $_.Substring($header.IndexOf('Version'), ($header.IndexOf('Available') - $header.IndexOf('Version')))
    $available = $_.Substring($header.IndexOf('Available'), ($header.IndexOf('Source') - $header.IndexOf('Available')))
    $source = $_.Substring($header.IndexOf('Source'))
    $csv += "$($name), $($id), $($version), $($available), $($source)"
}
$csv | ConvertFrom-Csv


Start-Job -Name 'Winget' -ScriptBlock { winget upgrade --all --silent --accept-package-agreements --accept-source-agreements --authentication-mode silentPreferred } -OutVariable job


Get-Job -IncludeChildJob
Receive-Job -Keep -Id $job.id
Remove-Job -Id $job.id
