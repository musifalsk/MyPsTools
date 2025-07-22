<#
.SYNOPSIS
    Scans the selected port(s) towards the hostname(s) you provide
.DESCRIPTION
    This function will test the selected ports / portranges towards the hostname(s) you provide.
    It will output the result to the screen and optionally export the result to an HTML file.
.NOTES
    Faster than using Test-NetConnection
.PARAMETER Hostname
    The hostname(s) you want to test
.PARAMETER Ports
    The port(s) you want to test
.PARAMETER Timeout
    The timeout in milliseconds for each port test (longer timeout = slower scan)
.PARAMETER ThrottleLimit
    The number of parallel threads to use (default is 50)
.PARAMETER HtmlExport
    Export the result to an HTML file and open in browser (DECOMISSIONED!)
.EXAMPLE
    Test-Port -hostname 'nrk.no','vg.no','google.com'-ports ((1..100) + (443,445,4433,8080))-timeout 500
.LINK
    Report an issue: https://github.com/musifalsk/MyPsTools
#>


function Test-Port {
    [CmdletBinding()]
    [OutputType([PortScan])]
    Param (
        [string[]]$Hostname = 'vg.no',
        [int[]]$Ports = (1..1024) + (1433, 3268, 3269, 3389, 5985, 9389),
        [int]$Timeout = 200,
        [int]$ThrottleLimit = 50,
        [switch]$HtmlExport
    )

    $ports | ForEach-Object -Parallel {
        $p = $_

        class PortScan {
            [string]$Hostname
            [int]$Port
            [bool]$Open

            PortScan([string]$h, [int]$p, [bool]$o) {
                $this.Hostname = $h
                $this.Port = $p
                $this.Open = $o
            }

            [string]ToString() {
                return "$($this.Hostname)`t$($this.Port)`t$($this.Open)"
            }
        }

        foreach ($h in $using:Hostname) {
            $tcpclient = New-Object System.Net.Sockets.TcpClient
            $tcpclient.BeginConnect($h, $p, $null, $null) | Out-Null
            Start-Sleep -milli $using:Timeout
            $open = $tcpclient.Connected -eq $true
            $tcpclient.Close()
            [PortScan]::new($h, $p, $open)
        }
    } -UseNewRunspace -ThrottleLimit $ThrottleLimit

    # Export Html file and open in browser
    # if ($HtmlExport) {
    #     $result | Where-Object { $_.Open -eq $true } |
    #         Sort-Object Hostname, Port, Open |
    #         ConvertTo-Html > "$env:TMP\TestPort_Result.html"
    #     & "$env:TMP\TestPort_Result.html"
    # }
}
