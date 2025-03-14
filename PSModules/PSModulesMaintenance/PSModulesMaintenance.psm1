<#
.SYNOPSIS
    Update all existing PSModules to the latest version.
.DESCRIPTION
    This function will update all installed PowerShell modules to the latest version.
    Each module will be updated in a separate job. Use Get-Job to see the progress. Use Receive-Job to see the output.
.EXAMPLE
    Update-PSModules
.EXAMPLE
    Update-PSModules -DiffCheck
    # (This will only show the modules that need to be updated without actually updating them.)
#>

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
.SYNOPSIS
    Removes old versions of installed PowerShell modules.
.DESCRIPTION
    This function will remove all but the latest version of installed PowerShell modules.
    Each module will be removed in a separate job. Use Get-Job to see the progress. Use Receive-Job to see the output.
.EXAMPLE
    Remove-OldPsModuleVersions
.EXAMPLE
    Remove-OldPsModuleVersions -DryRun
#>

# Remove Old PSModuleVersions
function Remove-OldPsModuleVersions {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param ([switch]$DryRun)

    $orange = $([char]27) + '[38;5;214m'
    $yellow = $([char]27) + '[38;5;11m'
    $green = $([char]27) + '[38;5;46m'
    $blue = $([char]27) + '[38;5;75m'
    $white = $([char]27) + '[0m'

    $modules = Get-InstalledModule
    foreach ($m in $modules) {
        Import-Module -Name PowerShellGet
        $versions = Get-InstalledModule -Name $m.Name -AllVersions
        if (($versions | Measure-Object).Count -gt 1) {
            ($versions | Sort-Object { [System.Version]$_.Version } -Descending)[1..($versions.Count - 1)] | ForEach-Object {
                $v = $_
                $placeholders = @(
                    $($orange)
                    $($m.Name)
                    $((($versions).Version | Sort-Object { [System.Version]$_ } -Descending)[0])
                    $($_.Version)
                    $($white)
                )
                Write-Output ('{0}{1}: Newest version: v{2} - Uninstalling v{3}{4}' -f $placeholders)
                if (!($DryRun)) {
                    if (Get-Module -Name $m.Name) { Remove-Module -Name $m.Name -Confirm:$false }
                    Start-Job -Name "Uninstall: $($m.Name) v$($_.Version)" -ScriptBlock {
                        Write-Output ('{0}{1}: Newest version: v{2} - Uninstalling v{3}{4}' -f $using:placeholders)
                        Uninstall-Module -Name ($using:m).Name -MaximumVersion ($using:v).Version -Confirm:$false -Verbose:$true -Force
                    } | Out-Null
                }
            }
        }
        else { Write-Output "$($green)No Action on $($m.Name) Version: $($m.Version)$($white)" }
    }
}
