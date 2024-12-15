# Requires -Modules Az.Accounts, Az.Resources, Microsoft.PowerShell.ConsoleGuiTools

<#
.SYNOPSIS
    Check if your PIM is still active
.DESCRIPTION
    Check if your PIM is still active
.NOTES
    Make sure that you are logged into the correct tenant (Set-AzContext) before running this script.
.EXAMPLE
    Get-IMRoleAssignmentSchedule
    Get-PIM
#>

function Get-RoleAssignmentSchedule {
    [CmdletBinding()]
    [Alias('Get-PIM', 'PIMCheck')]
    param(
        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Microsoft.Azure.Commands.Profile.Models.PSAzureSubscription[]]$Subscription
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
    }

    process {
        # List available RoleEligibilitySchedule
        $RoleEligibilitySchedule = Get-AzRoleEligibilitySchedule -Scope '/' -Filter 'asTarget()'
        if ($Subscription) {
            $Role = $RoleEligibilitySchedule | Where-Object { $_.ScopeDisplayName -eq $Subscription.Name }
        }
        else {
            $selection = $RoleEligibilitySchedule |
                Select-Object ScopeDisplayName, RoleDefinitionDisplayName, ScopeType, EndDateTime |
                Out-ConsoleGridView -Title "Hey $($aduser.DisplayName)! Please select the scope you want to boss araound in." -OutputMode Single
            $Role = $RoleEligibilitySchedule | Where-Object {
                $_.ScopeDisplayName -eq $selection.ScopeDisplayName -and
                $_.RoleDefinitionDisplayName -eq $selection.RoleDefinitionDisplayName
            }
        }

        # Get RoleAssignmentSchedule
        $param = @{
            Scope  = $Role.Scope
            Filter = "principalId eq $($aduser.Id) and roleDefinitionId eq '$($Role.RoleDefinitionId)'"
        }
        $RoleAssignmentSchedule = Get-AzRoleAssignmentSchedule @param

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
        return $RoleAssignmentSchedule | Select-Object $properties
    }
}
