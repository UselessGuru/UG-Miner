<#
Copyright (c) 2018-2025 UselessGuru


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
File:           \Pools\ZergPool.ps1
Version:        6.5.6
Version date:   2025/08/17
#>

Param(
    [String]$PoolVariant
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$HostSuffix = "mine.zergpool.com"

$PoolConfig = $Session.ConfigRunning.PoolsConfig.$Name
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$Regions = If ($Session.ConfigRunning.UseAnycast -and $PoolConfig.Region -contains "n/a (Anycast)") { "n/a (Anycast)" } Else { $PoolConfig.Region.Where({ $_ -ne "n/a (Anycast)" }) }
$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

$WorkerName = $PoolConfig.WorkerName -replace "^ID="

Write-Message -Level Debug "Pool '$PoolVariant': Start"

If ($DivisorMultiplier -and $Regions) { 

    Try { 
        If ($Session.BrainData.$Name.PSObject.Properties) { 
            $Request = $Session.BrainData.$Name
        }
        Else { 
            $Request = [System.IO.File]::ReadAllLines($BrainDataFile) | ConvertFrom-Json
        }
    }
    Catch { Return }

    If (-not $Request.PSObject.Properties.Name) { Return }

    ForEach ($Algorithm in $Request.PSObject.Properties.Name.Where({ $Request.$_.Updated -ge $Session.PoolDataCollectedTimeStamp })) { 
        $AlgorithmNorm = Get-Algorithm $Algorithm
        $Currency = If ([String]$Request.$Algorithm.Currency) { [String]$Request.$Algorithm.Currency } Else { "" }
        $Divisor = [Double]$Request.$Algorithm.mbtc_mh_factor * $DivisorMultiplier

        $PayoutCurrency = If ($Currency -and $PoolConfig.Wallets.$Currency -and -not $PoolConfig.ProfitSwitching) { $Currency } Else { $PoolConfig.PayoutCurrency }
        $PayoutThreshold = $PoolConfig.PayoutThreshold.$PayoutCurrency
        If ($PayoutThreshold -gt $Request.$Algorithm.minpay) { $PayoutThreshold = $Request.$Algorithm.minpay }
        If (-not $PayoutThreshold -and $PayoutCurrency -eq "BTC" -and $PoolConfig.PayoutThreshold.mBTC) { $PayoutThreshold = $PoolConfig.PayoutThreshold.mBTC / 1000 }
        If ($PayoutThreshold) { $PayoutThresholdParameter = ",pl=$([Double]$PayoutThreshold)" }

        $Reasons = [System.Collections.Generic.Hashset[String]]::new()
        If (-not $PoolConfig.Wallets.$PayoutCurrency) { $Reasons.Add("No wallet address for [$PayoutCurrency]") | Out-Null }
        If ($Request.$Algorithm.NoAutotrade -eq 1 -and $Currency -ne $PayoutCurrency) { $Reasons.Add("No wallet address for [$Currency] (conversion disabled at pool)") | Out-Null }
        If ($Request.$Algorithm.hashrate_shared -eq 0 -and -not ($Session.ConfigRunning.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { $Reasons.Add("No hashrate at pool") | Out-Null }
        If ($Session.PoolData.$Name.Algorithm -contains "-$AlgorithmNorm") { $Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") | Out-Null }

        # Cannot cast negative values to [UInt]
        If ($Request.$Algorithm.workers_shared -lt 0) { $Request.$Algorithm.workers_shared = 0 }

        $Key = "$($PoolVariant)_$($AlgorithmNorm)$(If ($Currency) { "-$($Currency)" })"
        $Value = $Request.$Algorithm.$PriceField / $Divisor

        $Stat = Get-Stat -Name "$($Key)_Profit"
        If ($Stat.Live -and $Value -gt 10 * $Session.ConfigRunning.PoolAllowedPriceIncreaseFactor) { 
            # New price should never spike more than 10x
            $Reasons.Add("Price data is more than 10x higher than previous price data (Error in pool API data?)") | Out-Null
        }
        Else { 
            $Stat = Set-Stat -Name "$($Key)_Profit" -Value $Value -FaultDetection $false
        }

        ForEach ($RegionNorm in $Session.Regions[$Session.ConfigRunning.Region]) { 
            If ($Region = $Regions.Where({ $_ -eq "n/a (Anycast)" -or (Get-Region $_) -eq $RegionNorm })) { 

                If ($Region -eq "n/a (Anycast)") { 
                    $PoolHost = "$Algorithm.$HostSuffix"
                    $RegionNorm = $Region
                }
                Else { 
                    $PoolHost = "$Algorithm.$Region.$HostSuffix"
                }

                [PSCustomObject]@{ 
                    Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1)
                    Algorithm                = $AlgorithmNorm
                    Currency                 = $Currency
                    Disabled                 = $Stat.Disabled
                    EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                    Fee                      = $Request.$Algorithm.Fees / 100
                    Host                     = $PoolHost.toLower()
                    Key                      = $Key
                    Name                     = $Name
                    Pass                     = "c=$PayoutCurrency$(If ($Currency) { ",mc=$Currency" }),ID=$WorkerName$PayoutThresholdParameter" # Pool profit switching breaks option 2 (static coin), instead it will still send DAG data for any coin
                    Port                     = [UInt16]$Request.$Algorithm.port
                    PortSSL                  = [UInt16]$Request.$Algorithm.tls_port
                    PoolUri                  = "https://zergpool.com/pool/$($Algorithm)"
                    Price                    = If ($null -eq $Request.$Algorithm.$PriceField) { [Double]::NaN } Else { $Stat.Live }
                    Protocol                 = If ($AlgorithmNorm -match $Session.RegexAlgoIsEthash) { "ethstratum2" } ElseIf ($AlgorithmNorm -match $Session.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                    Reasons                  = $Reasons
                    Region                   = $RegionNorm
                    SendHashrate             = $false
                    SSLselfSignedCertificate = $false
                    StablePrice              = $Stat.Week
                    Updated                  = [DateTime]$Request.$Algorithm.Updated
                    User                     = $PoolConfig.Wallets.$PayoutCurrency
                    Variant                  = $PoolVariant
                    WorkerName               = ""
                    Workers                  = [UInt]$Request.$Algorithm.workers_shared
                }
                Break
            }
        }
    }
}

Write-Message -Level Debug "Pool '$PoolVariant': End"

$Error.Clear()
[System.GC]::Collect()