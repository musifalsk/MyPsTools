

winget upgrade
Start-Job -Name 'Winget' -ScriptBlock { winget upgrade --all } -OutVariable job
Get-Job -IncludeChildJob
Receive-Job -Keep -Id $job.id
Remove-Job -Id $job.id
