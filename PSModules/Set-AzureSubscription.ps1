

# Set-AzContext for Powershell module & az login with az cli
function Set-AzureSubscription {
    [Alias('EzAzLogin', 'Switch-AzureSubscription')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param([switch]$Show)

    $white = $([char]27) + '[0m'
    $green = $([char]27) + '[38;5;46m'

    try { Get-AzTenant -ErrorAction Stop | Out-Null }
    catch {
        Write-Verbose 'Opening Login page for PS Module on your web browser..' -Verbose
        Start-Sleep -Seconds 1
        Connect-AzAccount -WarningAction SilentlyContinue | Out-Null
    }
    if (!(az account show)) {
        Write-Verbose 'Opening Login page for Az Cli on your web browser..' -Verbose
        Start-Sleep -Seconds 1
        az login --only-show-errors
    }
    if (!($Show)) {
        $select = Get-AzSubscription | Out-ConsoleGridView -Title 'Select Subscription' -OutputMode Single
        Set-AzContext -SubscriptionObject $select | Out-Null
        az account set --subscription $select.Id | Out-Null
    }

    Write-Output "$($green)Logged in Ps Account: $((Get-AzContext).Subscription.Name)$($white)"
    Write-Output "$($green)Logged in Cli Account: $((az account show --query 'name') -replace '\"')$($white)"
}

<#
Get-AzTenant
Get-AzRoleEligibilitySchedule -Scope '/' -Filter 'asTarget()'
Get-AzSubscription
Select-AzSubscription -SubscriptionObject $sub[-3]
Get-AzContext -ListAvailable
Clear-AzContext -Force
az account clear
#>
