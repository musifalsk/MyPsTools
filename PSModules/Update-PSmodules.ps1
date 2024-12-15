
# Update all existing PSModules
function Update-PSModules {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param ([switch]$DiffCheck)

    $orange = $([char]27) + '[38;5;214m'
    $green = $([char]27) + '[38;5;46m'
    $white = $([char]27) + '[0m'

    $modules = Get-InstalledModule
    $modules | ForEach-Object {
        $m = $_
        $newest = Find-Module -Name $_.Name
        if ([version]($newest.Version) -gt [version]($m.Version)) {
            $placeholders = @(
                $($orange)
                $($newest.Name)
                $($m.Version)
                $($newest.Version)
                $($white)
            )
            Write-Output ('{0}{1} should be updated from version {2} to {3}{4}' -f $placeholders)
            if (!($DiffCheck)) {
                Start-Job -Name "Update: $($newest.Name)" -ScriptBlock {
                    Write-Output ('{0}Updating {1} from version {2} to {3}{4}' -f $using:placeholders)
                    Update-Module -Name ($using:newest).Name -AcceptLicense -Confirm:$false -Verbose
                } | Out-Null
            }
        }
        else {
            $placeholders = @(
                $($green)
                $($m.Name)
                $($m.Version)
                $($white)
            )
            Write-Output ('{0}Module {1} is already at the latest version {2}{3}' -f $placeholders)
        }
    }
}


<#
Get-Job -Name 'Update*' | Select-Object Id, Name, State, HasMoreData
Receive-Job * -keep
Remove-Job -State Completed
Get-Job -Name 'Update*' -IncludeChildJob
Get-Job -Name 'Update*' -IncludeChildJob | ForEach-Object { Receive-Job -Id $_.Id -Keep }
Update-PSModules
#>
