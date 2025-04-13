<#
.SYNOPSIS
    Checks if az is connected to a tenant
.DESCRIPTION
    This function is used by the other functions in this module to check if az is connected to a tenant.
    It also sets the global variable $aduser to the current logged in user.
    If az is not connected to a tenant it will prompt the user to login.
.NOTES
    Required modules: az.Accounts
.LINK
    Report an issue: https://github.com/musifalsk/MyPsTools
#>

function Test-TenantConnection {
    $default = "$([char]27)[0m"
    $cyan = "$([char]27)[38;5;51m"
    $orange = "$([char]27)[38;5;214m"
    $action = @{ ErrorAction = 'Stop'; WarningAction = 'Stop' }

    Write-Output "$($cyan)Please wait while I pull myself together..$($default)"

    # Checks if az is connected to a tenant
    try {
        Get-AzTenant @action | Out-Null
        $context = Get-AzContext @action
        $aduser = (Get-AzADUser -UserPrincipalName $context.Account.Id @action)
        Write-Output "$($cyan)Hi $($aduser.DisplayName)! You are logged in to the tenant $($context.Tenant.Id).$($default)"
    }
    catch {
        Write-Warning 'Looks like you are not logged in to any Azure Tenants.'
        Write-Output "$($orange)Please login with the webpage that just opend in your default browser$($default)"
        $account = Connect-AzAccount
        return "$($cyan)You are now logged in as $($account.Context.Account.Id).$($default)"
    }
}

<#
.SYNOPSIS
    Sends a request to activate a role in Privileged Identity Management.
.DESCRIPTION
    Use this funtion instead of the portal when you want to elevate your Owner / Contributor role in the Privileged Identity Management.
    If your PIM is already active it will automatically extend the duration instead.
.NOTES
    Required modules: az.resources, Microsoft.PowerShell.ConsoleGuiTools
.PARAMETER Subscription
    Subscription object(s) you want to activate PIM for. If not specified it will ask you to select.
.PARAMETER Justification
    Message to explain your purpose
.PARAMETER Duration
    The duration of the PIM (must be in whole hours. ex: 3 for three hours)
.INPUTS
    [PSCustomObject[]]
.EXAMPLE
    Activate-PIM
.EXAMPLE
    PIM -Justification 'Testing' -Duration 3
.EXAMPLE
    $subscriptions = Get-AzSubscription | Where-Object { $_.Name -match 's080|s081' }
    $subscriptions | PIM -Justification maintenance -Duration 8
.LINK
    Report an issue: https://github.com/musifalsk/MyPsTools
#>

function Request-RoleAssignmentSchedule {
    [Alias('Activate-PIM', 'PIM', 'Set-PIM')]
    param(
        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [PSCustomObject[]]$Subscription,
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [ValidateLength(5, 50)]
        [string]$Justification,
        [Parameter(Mandatory)]
        [ValidateRange(1, 24)]
        [int]$Duration
    )

    begin {
        # Test tenant connection
        Test-TenantConnection
        if (!($aduser)) { break }

        # Check Duration variable
        if ([int]($Duration -replace '\D') -gt 8) { $ExpirationDuration = 'PT8H' }
        else { $ExpirationDuration = "PT$($Duration -replace '\D')H" }
    }

    process {
        # Set RoleEligibilitySchedule
        $RoleEligibilitySchedule = Get-AzRoleEligibilitySchedule -Scope '/' -Filter 'asTarget()'
        if ($Subscription) {
            $RoleEligibilitySchedule = $RoleEligibilitySchedule | Where-Object { ($_.Scope -replace '/subscriptions/|/.*') -in $Subscription.Id }
        }
        if ($RoleEligibilitySchedule.Count -gt 1) {
            $selection = $RoleEligibilitySchedule |
                Select-Object ScopeDisplayName, RoleDefinitionDisplayName, ScopeType, EndDateTime |
                Sort-Object -Property 'ScopeDisplayName', 'RoleDefinitionDisplayName' |
                Out-ConsoleGridView -Title "Hey $($aduser.DisplayName)! Please select the scope you want to boss araound in." -OutputMode Multiple
            $Role = $RoleEligibilitySchedule | Where-Object {
                $_.ScopeDisplayName -in $selection.ScopeDisplayName -and
                $_.RoleDefinitionDisplayName -in $selection.RoleDefinitionDisplayName
            }
        }
        else { $Role = $RoleEligibilitySchedule }
        if (!($Role)) { return "$($orange)No roles selected. Conviction canceled..$($default)" }
        Write-Output "$($cyan)I hereby sentence you to $($Role.RoleDefinitionDisplayName) in $($Role.ScopeDisplayName) for the duration of $($ExpirationDuration -replace '\D') hours!$($default)"

        $Role | ForEach-Object {
            $r = $_

            # Check if RoleAssignmentSchedule is already active
            $param = @{
                Scope  = $r.Scope
                Filter = "principalId eq $($aduser.Id) and roleDefinitionId eq '$($r.RoleDefinitionId)'"
            }
            $RoleAssignmentSchedule = Get-AzRoleAssignmentSchedule @param
            if ($RoleAssignmentSchedule) {
                $RequestType = 'SelfExtend'
                Write-Warning 'AzRoleAssignmentSchedule is still active. This tenant does not support SelfExtend without AdminConsent. Conviction canceled..'
                break
            }
            else { $RequestType = 'SelfActivate' }
            Write-Output "$($cyan)Request type will be set to $($RequestType)$($default)."

            # Send RoleAssignmentScheduleRequest
            $param = @{
                Name                      = New-Guid
                Scope                     = $r.Scope
                PrincipalId               = $aduser.Id
                RequestType               = $RequestType
                Justification             = $Justification
                ScheduleInfoStartDateTime = Get-Date -Format o
                ExpirationType            = 'AfterDuration'
                ExpirationDuration        = $ExpirationDuration
                RoleDefinitionId          = $r.RoleDefinitionId
            }
            $response = New-AzRoleAssignmentScheduleRequest @param

            # Return something so that it looks like something has happened
            $properties = @(
                'ScopeDisplayName'
                'RoleDefinitionDisplayName'
                'PrincipalEmail'
                'Status'
                @{ N = 'CreatedOn'; E = { $_.CreatedOn.ToLocalTime() } }
                @{ N = 'EndDateTime'; E = { $_.CreatedOn.ToLocalTime().AddHours($_.ExpirationDuration -replace '\D') } }
                'ExpirationDuration'
                'Justification'
                'RequestType'
                'RequestorId'
                @{ N = 'RoleAssignmentScheduleName'; E = { $_.Name } }
            )
            $response | Select-Object $properties
        }
    }
}

<#
.SYNOPSIS
    Check if your PIM is still active
.DESCRIPTION
    Check if your PIM is still active
.NOTES
    Required modules: az.resources, Microsoft.PowerShell.ConsoleGuiTools
.PARAMETER Subscription
    Subscription object(s) you want to activate PIM for. If not specified it will ask you to select.
.INPUTS
    [PSCustomObject[]]
.EXAMPLE
    Get-IMRoleAssignmentSchedule
.EXAMPLE
    Get-PIM
.LINK
    Report an issue: https://github.com/musifalsk/MyPsTools
#>

function Get-RoleAssignmentSchedule {
    [OutputType([string])]
    [OutputType([PSCustomObject])]
    [Alias('Get-PIM', 'PIMCheck')]
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [PSCustomObject[]]$Subscription
        # [Microsoft.Azure.Commands.Profile.Models.PSAzureSubscription[]]$Subscription
    )

    begin {
        # Test tenant connection
        Test-TenantConnection
        if (!($aduser)) { break }
    }

    process {
        # List available RoleEligibilitySchedule
        $RoleEligibilitySchedule = Get-AzRoleEligibilitySchedule -Scope '/' -Filter 'asTarget()'
        if ($Subscription) {
            $RoleEligibilitySchedule = $RoleEligibilitySchedule | Where-Object { ($_.Scope -replace '/subscriptions/|/.*') -in $Subscription.Id }
        }
        if ($RoleEligibilitySchedule.Count -gt 1) {
            $selection = $RoleEligibilitySchedule |
                Select-Object ScopeDisplayName, RoleDefinitionDisplayName, ScopeType, EndDateTime |
                Sort-Object -Property 'ScopeDisplayName', 'RoleDefinitionDisplayName' |
                Out-ConsoleGridView -Title "Hey $($aduser.DisplayName)! Please select the scope you want to boss araound in." -OutputMode Multiple
            $Role = $RoleEligibilitySchedule | Where-Object {
                $_.ScopeDisplayName -in $selection.ScopeDisplayName -and
                $_.RoleDefinitionDisplayName -in $selection.RoleDefinitionDisplayName
            }
        }
        else { $Role = $RoleEligibilitySchedule }
        if (!($Role)) { return "$($orange)No roles selected. Process canceled..$($default)" }

        $Role | ForEach-Object {
            $r = $_

            # Get RoleAssignmentSchedule
            $param = @{
                Scope  = $r.Scope
                Filter = "principalId eq $($aduser.Id) and roleDefinitionId eq '$($r.RoleDefinitionId)'"
            }
            $RoleAssignmentSchedule = Get-AzRoleAssignmentSchedule @param
            if (!($RoleAssignmentSchedule)) {
                $placeHolders = @(
                    $($orange)
                    $($r.RoleDefinitionDisplayName)
                    $($r.ScopeDisplayName)
                    $($default)
                )
                return "{0}No active RoleAssignmentSchedule found for the role `"{1}`" in {2}{3}" -f $placeHolders
            }

            # Return something
            $properties = @(
                'ScopeDisplayName'
                'RoleDefinitionDisplayName'
                'PrincipalEmail'
                'Status'
                @{ N = 'CreatedOn'; E = { $_.CreatedOn.ToLocalTime() } }
                @{ N = 'EndDateTime'; E = { $_.EndDateTime.ToLocalTime() } }
                @{ N = 'ExpirationDuration'; E = { ($_.EndDateTime.ToLocalTime() - (Get-Date)).TotalHours } }
                'Justification'
                'RequestType'
                @{ N = 'RequestorId'; E = { $_.PrincipalId } }
                @{ N = 'RoleAssignmentScheduleName'; E = { $_.Name } }
            )
            $RoleAssignmentSchedule | Select-Object $properties
        }
    }
}

<#
.SYNOPSIS
    Deactivate a RoleAssignmentSchedule in Privileged Identity Management.
.DESCRIPTION
    Use this funtion instead of the portal when you want to revoke a role assignment schedule in the Privileged Identity Management.
.NOTES
    Required modules: az.Resources, Microsoft.PowerShell.ConsoleGuiTools
.PARAMETER Subscription
    Subscription object(s) you want to activate PIM for. If not specified it will ask you to select.
.INPUTS
    [PSCustomObject[]]
.EXAMPLE
    Revoke-RoleAssignmentSchedule
.EXAMPLE
    Stop-PIM
.LINK
    Report an issue: https://github.com/musifalsk/MyPsTools
#>

function Revoke-RoleAssignmentSchedule {
    [Alias('Stop-PIM')]
    param(
        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [PSCustomObject[]]$Subscription
    )

    begin {
        # Test tenant connection
        Test-TenantConnection
        if (!($aduser)) { break }
    }

    process {
        # List available RoleEligibilitySchedule
        $RoleEligibilitySchedule = Get-AzRoleEligibilitySchedule -Scope '/' -Filter 'asTarget()'
        if ($Subscription) {
            $RoleEligibilitySchedule = $RoleEligibilitySchedule | Where-Object { ($_.Scope -replace '/subscriptions/|/.*') -in $Subscription.Id }
        }
        if ($RoleEligibilitySchedule.Count -gt 1) {
            $selection = $RoleEligibilitySchedule |
                Select-Object ScopeDisplayName, RoleDefinitionDisplayName, ScopeType, EndDateTime |
                Out-ConsoleGridView -Title "Hei $($aduser.DisplayName)!" -OutputMode Multiple

            $Role = $RoleEligibilitySchedule | Where-Object {
                $_.ScopeDisplayName -eq $selection.ScopeDisplayName -and
                $_.RoleDefinitionDisplayName -eq $selection.RoleDefinitionDisplayName
            }
        }
        else { $Role = $RoleEligibilitySchedule }
        if (!($Role)) { return "$($orange)No roles selected. Revoking canceled..$($default)" }

        $Role | ForEach-Object {
            $r = $_

            # Get RoleAssignmentSchedule
            $param = @{
                Scope  = $r.Scope
                Filter = "principalId eq $($aduser.Id) and roleDefinitionId eq '$($r.RoleDefinitionId)'"
            }
            $RoleAssignmentSchedule = Get-AzRoleAssignmentSchedule @param
            if (!($RoleAssignmentSchedule)) {
                $placeHolders = @(
                    $($orange)
                    $($r.RoleDefinitionDisplayName)
                    $($r.ScopeDisplayName)
                    $($default)
                )
                return "{0}No active RoleAssignmentSchedule found for the role `"{1}`" in {2}{3}" -f $placeHolders
            }

            # Deactivate RoleAssignmentSchedule
            $param = @{
                Name                      = New-Guid
                Scope                     = $r.Scope
                ExpirationType            = 'AfterDuration'
                PrincipalId               = $aduser.Id
                RequestType               = 'SelfDeactivate'
                RoleDefinitionId          = $r.RoleDefinitionId
                ScheduleInfoStartDateTime = Get-Date -Format o
            }
            $response = New-AzRoleAssignmentScheduleRequest @param
            $properties = @(
                'ScopeDisplayName'
                'RoleDefinitionDisplayName'
                'PrincipalEmail'
                'Status'
                @{ N = 'CreatedOn'; E = { $_.CreatedOn.ToLocalTime() } }
                @{ N = 'EndDateTime'; E = { $_.ExpirationEndDateTime.ToLocalTime() } }
                @{ N = 'ExpirationDuration'; E = { ($_.ExpirationEndDateTime.ToLocalTime() - (Get-Date)).TotalHours } }
                'Justification'
                'RequestType'
                @{ N = 'RequestorId'; E = { $_.PrincipalId } }
                @{ N = 'RoleAssignmentScheduleName'; E = { $_.Name } }
            )
            $response | Select-Object $properties
        }
    }
}
