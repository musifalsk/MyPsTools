<#
.SYNOPSIS
    Tests the SSL certificate of a website.
.DESCRIPTION
    This function connects to a specified URI and retrieves the SSL certificate information.
    It returns details such as the subject, validity period, thumbprint, Uri names, issuer, type, and format of the certificate.
    The function uses a TCP client to establish a connection and an SSL stream to authenticate the client
    against the server's SSL certificate.
    If the connection fails, it will write a warning message.
.PARAMETER Uri
    The URI of the website to test. Default is 'https://vg.no/test'.
.PARAMETER Port
    The port to connect to. Default is 443.
.EXAMPLE
    Test-MyTestFunction -Uri 'https://example.com' -Port 443
.LINK
    https://github.com/musifalsk/MyPsTools
#>

class SslCertificate {
    [string]$Hostname
    [string]$Subject
    [string]$Issuer
    [string]$Thumbprint
    [datetime]$NotBefore
    [datetime]$NotAfter
    [string[]]$DnsNameList
    [string]$Type
    [string]$Format

    # Constructor
    SslCertificate($hostname, $subject, $issuer, $thumbprint, $notBefore, $notAfter, $dnsNameList, $type, $format) {
        $this.Hostname = $hostname
        $this.Subject = $subject
        $this.Issuer = $issuer
        $this.Thumbprint = $thumbprint
        $this.NotBefore = $notBefore
        $this.NotAfter = $notAfter
        $this.DnsNameList = $dnsNameList
        $this.Type = $type
        $this.Format = $format
    }
}

function Get-SslRemoteCertificate {
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Hostname,
        [Parameter(Mandatory = $false, Position = 1)]
        [int]$Port = 443
    )

    [string]$Hostname = $Hostname -replace '^https?://' -replace '/.*'
    $ErrorActionPreference = 'Stop'
    try {
        $tcpclient = [System.Net.Sockets.TcpClient]::new($Hostname, $Port)
        $sslstream = [System.Net.Security.SslStream]::new($tcpclient.GetStream())
        $sslstream.AuthenticateAsClient($Hostname)
    }
    catch {
        Write-Warning $_
    }
    $ErrorActionPreference = 'Continue'

    $result = [SslCertificate]::new(
        $sslstream.TargetHostName,
        $sslstream.RemoteCertificate.Subject,
        $sslstream.RemoteCertificate.Issuer,
        $sslstream.RemoteCertificate.Thumbprint,
        $sslstream.RemoteCertificate.NotBefore,
        $sslstream.RemoteCertificate.NotAfter,
        $sslstream.RemoteCertificate.DnsNameList,
        $sslstream.RemoteCertificate.GetType().Name,
        $sslstream.RemoteCertificate.GetFormat()
    )
    $tcpclient.Dispose()
    $sslstream.Dispose()
    return($result)
}

Export-ModuleMember -Function Get-SslRemoteCertificate
