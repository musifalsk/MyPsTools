<#
.SYNOPSIS
    Set-AzContext for Powershell module & az login with az cli
.DESCRIPTION
    This function will set the Azure context for both Powershell module and az cli.
    If the Powershell module is not logged in, it will open a login page for the Powershell module.
    If the az cli is not logged in, it will open a login page for the az cli.
    If the -Show switch is used, it will show the current logged in account for both Powershell module and az cli.
.NOTES
    This function requires the Az module and the Az CLI to be installed.
.EXAMPLE
    Set-AzureSubscription
.EXAMPLE
    Set-AzureSubscription -Show
#>

function Set-AzureSubscription {
    [Alias('EzAzLogin', 'Switch-AzureSubscription')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param([switch]$Show)

    # Color Codes
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

    # Sets the context for the Powershell module and the az cli
    if (!($Show)) {
        $select = Get-AzSubscription | Out-ConsoleGridView -Title 'Select Subscription' -OutputMode Single
        Set-AzContext -SubscriptionObject $select | Out-Null
        az account set --subscription $select.Id | Out-Null
    }

    Write-Output "$($green)Logged in Ps Account: $((Get-AzContext).Subscription.Name)$($white)"
    Write-Output "$($green)Logged in Cli Account: $((az account show --query 'name') -replace '\"')$($white)"
}
