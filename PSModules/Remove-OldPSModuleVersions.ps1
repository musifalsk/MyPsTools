<#
.SYNOPSIS
    Removes old versions of installed PowerShell modules.
.DESCRIPTION
    This function will remove all but the latest version of installed PowerShell modules.
    It will also remove the module from the current session if it is loaded.
.EXAMPLE
    Remove-OldPsModuleVersions
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


<#
Get-Job
Receive-Job * -Keep
Remove-Job -State Completed

Remove-OldPsModuleVersions -DryRun
#>
