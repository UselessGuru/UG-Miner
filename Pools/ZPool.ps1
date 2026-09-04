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
File:           \Pools\ZPool.ps1
Version:        6.7.16
Version date:   2025/12/31
#>

param(
    [String]$PoolVariant
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$HostSuffix = "mine.zpool.ca"

$PoolConfig = $Session.Config.PoolsConfig.$Name
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

Write-Message -Level Debug "Pool '$PoolVariant': Start"

if ($PriceField) { 

    try { 
        $Request = if ($Session.Brains.$Name) { $Session.BrainData.$Name } else { [System.IO.File]::ReadAllLines($BrainDataFile) | ConvertFrom-Json }
    }
    catch { return }

    if (-not $Request.PSObject.Properties.Name) { return }

    foreach ($Algorithm in $Request.PSObject.Properties.Name.Where{ $Request.$_.Updated -ge $Session.PoolDataCollectedTimeStamp }) { 
        $AlgorithmNorm = Get-Algorithm $Algorithm
        $Currency = [String]$Request.$Algorithm.currency
        $Divisor = [Double]$Request.$Algorithm.mbtc_mh_factor * $DivisorMultiplier
        $PayoutCurrency = if ($Currency -and $PoolConfig.Wallets.$Currency) { $Currency } else { $PoolConfig.PayoutCurrency }
        $Reasons = [System.Collections.Generic.SortedSet[String]]::new()

        if (-not $Request.$Algorithm.conversion_supported) { 
            if (-not $Currency) { [Void]$Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") }
            elseif (-not $PoolConfig.Wallets.$Currency) { [Void]$Reasons.Add("No wallet address for [$Currency] (conversion disabled at pool)") }
        }
        elseif (-not $PoolConfig.Wallets.$PayoutCurrency) { [Void]$Reasons.Add("No wallet address for [$PayoutCurrency]") }
        elseif ($Session.PoolData.$Name.Algorithm -contains "-$AlgorithmNorm") { [Void]$Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") }
        elseif ($Session.PoolData.$Name.Algorithm -like "+*" -and ($Session.PoolData.$Name.Algorithm -split "," -notcontains "+$($AlgorithmNorm)")) { [Void]$Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") }

        if ($Request.$Algorithm.hashrate_last24h -eq 0 -and -not ($Session.Config.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { [Void]$Reasons.Add("No hashrate at pool") }

        $Key = "$($PoolVariant)_$($AlgorithmNorm)$(if ($Currency) { "-$Currency" })"
        $Value = $Request.$Algorithm.$PriceField / $Divisor

        $Stat = Get-Stat -Name "$($Key)_Profit"
        if ($Stat.Live -and $Value -gt ($Stat.Live * $Session.Config.PoolAllowedPriceIncreaseFactor)) { 
            [Void]$Reasons.Add("Unrealistic price (price in pool API data is more than $($Session.Config.PoolAllowedPriceIncreaseFactor)x higher than previous price)")
        }
        else { 
            $Stat = Set-Stat -Name "$($Key)_Profit" -Value $Value -FaultDetection $false
        }

        foreach ($RegionNorm in $Session.Regions[$Session.Config.Region]) { 
            if ($Region = $PoolConfig.Region.Where{ (Get-Region $_) -eq $RegionNorm }) { 

                @{ 
                    Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1)
                    Algorithm                = $AlgorithmNorm
                    Currency                 = $Currency
                    Disabled                 = $Stat.Disabled
                    EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                    Fee                      = $Request.$Algorithm.Fees / 100
                    Host                     = "$($Algorithm).$($Region).$($HostSuffix)"
                    Key                      = $Key
                    Name                     = $Name
                    Pass                     = "$($PoolConfig.WorkerName),c=$PayoutCurrency$(if ($Currency) { ",zap=$Currency" })"
                    Port                     = $Request.$Algorithm.port
                    PortSSL                  = 50000 + [UInt16]($Request.$Algorithm.port)
                    PoolUri                  = "https://zpool.ca/algo/$($Algorithm)"
                    Price                    = if ($null -eq $Request.$Algorithm.$PriceField) { [Double]::NaN } else { $Stat.Live }
                    Protocol                 = if ($AlgorithmNorm -match $Session.RegexAlgoIsEthash) { "ethproxy" } elseif ($AlgorithmNorm -match $Session.RegexAlgoIsProgPow) { "stratum" } else { "" }
                    Reasons                  = $Reasons
                    Region                   = $RegionNorm
                    SendHashrate             = $false
                    SSLselfSignedCertificate = $true
                    StablePrice              = $Stat.Week
                    Updated                  = $Request.$Algorithm.Updated
                    User                     = $PoolConfig.Wallets.$PayoutCurrency
                    Variant                  = $PoolVariant
                    WorkerName               = ""
                    Workers                  = $Request.$Algorithm.workers
                }
                break
            }
        }
    }
}

Write-Message -Level Debug "Pool '$PoolVariant': End"