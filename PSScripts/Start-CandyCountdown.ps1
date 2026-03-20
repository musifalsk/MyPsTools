param(
    [string]$Webhook
)

# Calculate UTC
$tzOslo = Get-TimeZone -Id 'Europe/Oslo'
$timeOslo = (Get-Date -Date 11:00:00)
$timeUtc = [System.TimeZoneInfo]::ConvertTimeToUtc($timeOslo, $tzOslo)

# Countdown Until Next Delivery
for ($i = 0; $i -le 7; $i++) {
    if (($i -eq 0) -and ((Get-Date -AsUTC) -gt [datetime]::Parse($timeUtc.TimeOfDay))) { continue }
    if (($timeUtc.AddDays($i).DayOfWeek -eq 'Friday')) {
        $nextFriday = $timeUtc.AddDays($i)
        break
    }
}
$span = New-TimeSpan -Start (Get-Date -AsUTC) -End $nextFriday
if ($span -gt [timespan]::new(6, 22, 0, 0)) {
    $msg = 'Hurra!! Det er godteritid 🎉🍬🍭😊'
}
else {
    $msg = ('Det er {0} dag{1}, {2} time{3} og {4} minutt{5} igjen til godteri. 🍬🍭' -f @(
            $span.Days, ($span.Days -ne 1 ? 'er' : $null),
            $span.Hours, ($span.Hours -ne 1 ? 'r'  : $null),
            $span.Minutes, ($span.Minutes -ne 1 ? 'er' : $null)
        )
    )
}
Write-Output $msg

if ($Webhook) {
    $json = @{
        blocks = @(
            @{
                type = 'section'
                text = @{
                    type  = 'plain_text'
                    text  = $msg
                    emoji = $true
                }
            }
        )
    } | ConvertTo-Json -Depth 3
    Invoke-RestMethod -Uri $Webhook -Method Post -Body $json -ContentType 'application/json'
}
