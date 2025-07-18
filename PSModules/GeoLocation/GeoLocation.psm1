﻿<#
.SYNOPSIS
    Returns the geographic location and more for a Dns or Ip
.DESCRIPTION
    This function will lookup a Dns or Ip address and show you information
    like country, region, city, organization, isp and more
.NOTES
    Provider allows 15 requests per minute from the same IP, but the script
    will send 100 entries on each request for a total of 1500.
.PARAMETER HostName
    The hostname or ip address you want to lookup
.INPUTS
    String
.EXAMPLE
    Get-GeoLocation 'vg.no'
.EXAMPLE
    '8.8.8.8' | Get-GeoLocation
.EXAMPLE
    '209.140.136.254', 'vg.no', 'http://nrk.no', '195.88.55.16' | Get-GeoLocation
.LINK
    This function use https://ip-api.com website for its lookups.
.LINK
    Report an issue: https://github.com/musifalsk/MyPsTools
#>

class GeoLocation {
    hidden [string]$Status
    [string]$Query
    [string]$Country
    hidden [string]$CountryCode
    hidden [string]$Region
    [string]$RegionName
    [string]$City
    hidden [string]$Zip
    hidden [string]$Lat
    hidden [string]$Lon
    [string]$Timezone
    [string]$ISP
    [string]$Org
    [string]$AS

    GeoLocation([pscustomobject]$response) {
        $this.Status = $response.status
        $this.Query = $response.query
        $this.Country = $response.country
        $this.CountryCode = $response.countryCode
        $this.Region = $response.region
        $this.RegionName = $response.regionName
        $this.City = $response.city
        $this.Zip = $response.zip
        $this.Lat = $response.lat
        $this.Lon = $response.lon
        $this.Timezone = $response.timezone
        $this.ISP = $response.isp
        $this.Org = $response.org
        $this.AS = $response.as
    }

    [string]ToString() {
        return "$($this.Query) - $($this.City), $($this.Country)"
    }
}

function Get-GeoLocation {
    [CmdletBinding(DefaultParameterSetName = 'Parameter Set 1')]
    [Alias('geoloc')]
    param(
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'Parameter Set 1'
        )]$HostName
    )

    begin {
        if (!($HostName)) { Write-Verbose 'Looking for hostnames in the pipeline' }
        $c = 0
        $ip = @()
    }

    process {
        # Converting hostnames to ip addresses where nededed
        foreach ($h in $HostName) {
            Write-Verbose "Processing $(($c++)) - Hostname $($h)"
            $h = $h -replace '^https?://'
            if ($h -match '^\d{1,3}(\.\d{1,3}){3}$') { $i = $h }
            else {
                try { $i = ((Resolve-DnsName $h -Type A -ErrorAction Stop)[0]).IPAddress }
                catch { $i = $h }
            }
            if ($i -notmatch '^\d{1,3}(\.\d{1,3}){3}$' -and $null -ne $i) {
                Write-Warning "$i is not a valid IPAddress." ; continue
            }
            $ip += "`"$($i)`""
            if ($i -match '.') { Remove-Variable i }
        }
    }

    end {
        # Sending requests to provider
        if ($ip) {
            if ($ip.count -gt 1500) {
                Write-Warning 'HostName list exceeds 1500 entries. The provider will punish you for this with throtling. Continue anyway?'
                if ((Read-Host -Prompt 'Y/N') -ne 'y') { Write-Output 'Wise choice. Good bye..' ; break }
                else { Write-Output 'OK then. But dont come runnin afterwards saying i didnt warn you.' }
            }
            do {
                Write-Verbose 'Sending request to provider..'
                $ipslice = $ip[0..99]
                $ip = $ip[100..$($ip.count)]
                $body = ("`[$($ipslice)`]" -replace '\s', ',')
                $results = (Invoke-WebRequest -Method Post -Uri 'http://ip-api.com/batch' -Body $body).Content | ConvertFrom-Json
                foreach ($r in $results) {
                    [GeoLocation]::new($r)
                }
            }
            until ($ip.Count -lt 1)
        }
        else {
            Write-Verbose 'Sending request for your public IP' -Verbose
            $result = Invoke-RestMethod -Method Get -Uri 'http://ip-api.com/json/'
            [GeoLocation]::new($result)
        }
        if ($HostName) { Remove-Variable HostName }
    }
}
