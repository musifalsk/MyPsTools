<#
.SYNOPSIS
    Scans the selected ports / portranges towards the hostname(s) you provide
.DESCRIPTION
    This function will test the selected ports / portranges towards the hostname(s) you provide.
    It will output the result to the screen and optionally export the result to an HTML file.
.NOTES
    Faster than using Test-NetConnection
.EXAMPLE
    Test-Ports -hostname 'nrk.no','vg.no','google.com'-ports 80,81,443,444 -timeout 500
#>

function Test-Port {
    Param (
        $Hostname = 'vg.no',
        $Ports = (1..1024) + (1433, 3268, 3269, 3389, 5985, 9389),
        $Timeout = 200,
        $ThrottleLimit = 50,
        [switch]$HtmlExport
    )

    $result = $ports | ForEach-Object -Parallel {
        $p = $_
        foreach ($h in $using:Hostname) {
            $tcpclient = New-Object System.Net.Sockets.TcpClient
            $tcpclient.BeginConnect($h, $p, $null, $null) | Out-Null
            Start-Sleep -milli $using:Timeout
            if ($tcpclient.Connected) { $open = $true } else { $open = $false }
            $tcpclient.Close()
            $r = [pscustomobject]@{
                Hostname = $h
                Port     = $p
                Open     = $open
            }

            # Output to screen
            $white = $([char]27) + '[0m'
            $green = $([char]27) + '[38;5;46m'
            if (!($r.open)) { Remove-Variable green }
            Write-Output "$($green)$($r.Hostname)`t$($r.Port)`t$($r.Open)$($white)"

            # Output to variable
            Write-Output $r
        }
    } -UseNewRunspace -ThrottleLimit $ThrottleLimit

    # Output Result
    if ($result | Where-Object { $_.Open -eq $true }) {
        $result | Where-Object { $_.Open -eq $true } |
            Sort-Object Hostname, Port |
            Format-Table
    }
    else { Write-Output 'Result: Found no open ports!' }

    # Export Html file and open in browser
    if ($HtmlExport) {
        $result | Where-Object { $_.Open -eq $true } |
            Sort-Object Hostname, Port |
            ConvertTo-Html > "$env:TMP\TestPort_Result.html"
        & "$env:TMP\TestPort_Result.html"
    }
}
