<#
Copyright (c) 2018-2026 UselessGuru


UG-Miner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

UG-Miner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        UG-Miner
File:           \Pools\NiceHash.ps1
Version:        6.8.26
Version date:   2026/10/01
#>

param(
    [String]$PoolVariant
)

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$PoolHost = "auto.nicehash.com"

$PoolConfig = $Session.Config.PoolsConfig.$Name

$Fee = $PoolConfig.Variant.$PoolVariant.Fee
$PayoutCurrency = $PoolConfig.PayoutCurrency

Write-Message -Level Debug "Pool '$PoolVariant': Start"

$APICallFails = 0
$Handler = [System.Net.Http.HttpClientHandler]::new()
$Handler.ServerCertificateCustomValidationCallback = [System.Net.Http.HttpClientHandler]::DangerousAcceptAnyServerCertificateValidator # Equivalent to -SkipCertificateCheck
$HttpClient = [System.Net.Http.HttpClient]::new($Handler)

do { 
    try { 
        if (-not $RequestInfo) { 
            $CancellationTokenSource = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($PoolConfig.PoolAPItimeout))
            $RequestMessage = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Get, "https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info/")
            $RequestMessage.Headers.CacheControl = [System.Net.Http.Headers.CacheControlHeaderValue]::Parse("no-cache")
            $Response = $HttpClient.SendAsync($RequestMessage, $CancellationTokenSource.Token).GetAwaiter().GetResult()
            # Read response as raw string
            $JSONstring = $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            $RequestInfo = ($JSONstring | ConvertFrom-Json).miningAlgorithms
            if (-not $RequestInfo) { $RequestInfo = $null }
        }
        if (-not $RequestAlgorithms) { 
            $CancellationTokenSource = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($PoolConfig.PoolAPItimeout))
            $RequestMessage = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Get, "https://api2.nicehash.com/main/api/v2/mining/algorithms/")
            $RequestMessage.Headers.CacheControl = [System.Net.Http.Headers.CacheControlHeaderValue]::Parse("no-cache")
            $Response = $HttpClient.SendAsync($RequestMessage, $CancellationTokenSource.Token).GetAwaiter().GetResult()
            # Read response as raw string
            $JSONstring = $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            $RequestAlgorithms = ($JSONstring | ConvertFrom-Json).miningAlgorithms
            if (-not $RequestAlgorithms) { $RequestAlgorithms = $null }
        }
    }
    catch { 
        $APICallFails ++
        Start-Sleep -Seconds ($APICallFails * 5 + $PoolConfig.PoolAPIretryInterval)
    }
} while (-not ($RequestInfo -and $RequestAlgorithms) -and $APICallFails -le $Session.Config.PoolAPIallowedFailureCount)
$CancellationTokenSource.Dispose()
Remove-Variable CancellationTokenSource, Handler, HttpClient, JSONstring, RequestMessage, Response

if ($APICallFails -gt $Session.Config.PoolAPIallowedFailureCount) { 
    Write-Message -Level Warn "Error '$($_.Exception.Message)' when trying to access https://api2.nicehash.com/main/api/v2."
}
elseif ($RequestInfo) { 
    $Timestamp = [DateTime]::Now.ToUniversalTime()

    $RequestInfo.ForEach{ 
        $Algorithm = $_.Algorithm
        if ($RequestAlgorithm = $RequestAlgorithms.Where{ $_.algorithm -eq $Algorithm }) { 
            $AlgorithmNorm = Get-Algorithm $Algorithm
            $Currencies = Get-CurrencyFromAlgorithm $AlgorithmNorm
            $Currency = if ($Currencies.Count -eq 1) { [String]$Currencies } else { "" }
            $Divisor = 100000000
            $Reasons = [System.Collections.Generic.SortedSet[String]]::new()
            if (-not $PoolConfig.Wallets.$PayoutCurrency) { [Void]$Reasons.Add("No wallet address for [$PayoutCurrency]") }
            if ($RequestAlgorithm.enabled -eq $false) { [Void]$Reasons.Add("Disabled at pool") }
            if ($RequestAlgorithm.order -eq 0) { [Void]$Reasons.Add("No orders at pool") }
            if ($_.speed -eq 0 -and -not ($Session.Config.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { [Void]$Reasons.Add("No hashrate at pool") }

            $Key = "$($Name)_$($AlgorithmNorm)"
            $Value = [Double]$_.paying / $Divisor

            $Stat = Get-Stat -Name "$($Key)_Profit"
            if ($Stat.Live -and $Value -gt ($Stat.Live * $Session.Config.PoolAllowedPriceIncreaseFactor)) { 
                [Void]$Reasons.Add("Unrealistic price (price in pool API data is more than $($Session.Config.PoolAllowedPriceIncreaseFactor)x higher than previous price)")
            }
            else { 
                $Stat = Set-Stat -Name "$($Key)_Profit" -Value $Value -FaultDetection $false
            }

            @{ 
                Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Minute_5_Fluctuation), 1) # Use short timespan to counter price spikes
                Algorithm                = $AlgorithmNorm
                Currency                 = $Currency
                Disabled                 = $Stat.Disabled
                EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                Fee                      = $Fee
                Host                     = "$Algorithm.$PoolHost".ToLower()
                Key                      = $Key
                Name                     = $Name
                Pass                     = "x"
                Port                     = 9200
                PortSSL                  = 443
                PoolUri                  = "https://www.nicehash.com/algorithm/$($_.Algorithm.ToLower())"
                Price                    = if ($null -eq $_.paying) { [Double]::NaN } else { $Stat.Live }
                Protocol                 = if ($AlgorithmNorm -match $Session.RegexAlgoIsEthash) { "ethstratumnh" } elseif ($AlgorithmNorm -match $Session.RegexAlgoIsProgPow) { "stratum" } else { "" }
                Region                   = $PoolConfig.Region
                Reasons                  = $Reasons
                SendHashrate             = $false
                SSLselfSignedCertificate = $false
                StablePrice              = $Stat.Week
                Updated                  = $Timestamp
                User                     = "$($PoolConfig.Wallets.$PayoutCurrency).$($PoolConfig.WorkerName)"
                Variant                  = $Name
                WorkerName               = ""
                Workers                  = $null
            }
        }
    }
}

Write-Message -Level Debug "Pool '$PoolVariant': End"