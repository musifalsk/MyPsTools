<#
.SYNOPSIS
    Sends a request to activate a role in Privileged Identity Management.
.DESCRIPTION
    Use this funtion instead of the portal when you want to elevate your Owner / Contributor role in the Privileged Identity Management.
    If your PIM is already active it will automatically extend the duration instead.

    Parameters:
        -Justification = Message to explain your purpose ,
        -Duration = The duration of the PIM (must be in whole hours. ex: 3 for three hours),
        -Subscription = The subscription you want to activate PIM for. If not specified it will ask you to select.
.NOTES
    Required modules: Az, Microsoft.PowerShell.ConsoleGuiTools
.EXAMPLE
    Activate-PIM
.EXAMPLE
    PIM -Justification 'Testing' -Duration 3
.EXAMPLE
    $subscriptions = Get-AzSubscription | Where-Object { $_.Name -match 's080|s081' }
    $subscriptions | PIM -Justification maintenance -Duration 8
#>

function Request-RoleAssignmentSchedule {
    [Alias('Activate-PIM', 'PIM', 'Set-PIM')]
    param(
        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [PSCustomObject[]]$Subscription,
        # [ValidateSet('Owner', 'Contributor', 'Reader')]$RoleDefinition,
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [ValidateLength(5, 50)]
        [string]$Justification,
        [Parameter(Mandatory)]
        [ValidateRange(1, 24)]
        [int]$Duration
    )

    begin {
        $cyan = $([char]27) + '[38;5;51m'
        $nocolor = $([char]27) + '[0m'

        # Check if az is connected to a tenant
        Write-Output "$($cyan)Please wait while I pull myself together..$($nocolor)"
        $action = @{ ErrorAction = 'Stop'; WarningAction = 'Stop' }
        try {
            Get-AzTenant @action | Out-Null
            $context = Get-AzContext @action
            $aduser = Get-AzADUser -UserPrincipalName $context.Account.Id @action
        }
        catch {
            Write-Warning 'Looks like you are not logged in to any Azure Tenants.
            Please login with the webpage that just opend in your default browser'
            $account = Connect-AzAccount
            return "$($cyan)You are now logged in as $($account.Context.Account.Id). Please re-run the command.$($nocolor)"
        }

        # Check Duration variable
        if ([int]($Duration -replace '\D') -gt 8) { $ExpirationDuration = 'PT8H' }
        else { $ExpirationDuration = "PT$($Duration -replace '\D')H" }
    }

    process {
        # Set RoleEligibilitySchedule
        $RoleEligibilitySchedule = Get-AzRoleEligibilitySchedule -Scope '/' -Filter 'asTarget()'
        if ($Subscription) {
            # $RoleEligibilitySchedule = $RoleEligibilitySchedule | Where-Object { $_.ScopeDisplayName -eq $Subscription.Name }
            # $RoleEligibilitySchedule = $RoleEligibilitySchedule | Where-Object { ($_.Scope -replace '/subscriptions/' -replace '/.*') -in $Subscription.Id }
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
        if (!($Role)) { return 'No RoleEligibilitySchedule found. Conviction canceled..' }
        Write-Output "$($cyan)I hereby sentence you to $($Role.RoleDefinitionDisplayName) in $($Role.ScopeDisplayName) for the duration of $($ExpirationDuration -replace '\D') hours!$($nocolor)"


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
            Write-Output "$($cyan)Request type will be set to $($RequestType)$($nocolor)."

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
