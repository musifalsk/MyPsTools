param(
    [string]$Webhook
)

$response = Invoke-WebRequest -Uri 'https://i74qu6dp3m.execute-api.us-east-2.amazonaws.com/' -Method Get -ContentType 'application/json'
if (!($response)) { throw }
$menu = $response.Content | ConvertFrom-Json
if (!($response)) { throw }
$today = [int](Get-Date).DayOfWeek - 1

if ($Webhook) {
    $json = @{
        'blocks' = @(
            @{
                'type' = 'section'
                'text' = @{
                    'type'  = 'plain_text'
                    'text'  = 'mmmm.. I dag serveres dette i kantina 😋'
                    'emoji' = $true
                }
            },
            @{
                'type'   = 'section'
                'fields' = @(
                    @{
                        'type'  = 'plain_text'
                        'text'  = "$($menu.days[$today].day)"
                        'emoji' = $true
                    },
                    @{
                        'type'  = 'plain_text'
                        'text'  = "$($menu.days[$today].dishes)"
                        'emoji' = $true
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 4
    Invoke-RestMethod -Uri $Webhook -Method Post -Body $json -ContentType 'application/json'
}
