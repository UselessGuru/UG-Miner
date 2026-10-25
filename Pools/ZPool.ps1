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
Version:        6.9.1
Version date:   2026/10/25
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

try { 
    $BrainData = if ($Session.Brains.$Name) { $Session.BrainData.$Name } else { [System.IO.File]::ReadAllLines($BrainDataFile) | ConvertFrom-Json -ErrorAction Ignore }
}
catch { 
    Write-Message -Level Warn "Pool '$Name': Cannot parse brain data."
    return
}
if (-not $BrainData.PSObject.Properties.Name) { 
    Write-Message -Level Warn "Pool '$Name': No brain data."
    return
}

foreach ($PoolName in ($BrainData.PSObject.Properties.Name.Where{ $BrainData.$_.Updated -ge $Session.PoolDataCollectedTimeStamp } | Sort-Object)) { 

    $PoolInfo = $BrainData.$PoolName

    if ($PoolInfo.$PriceField) { 

        $AlgorithmNorm = $PoolInfo.AlgorithmNorm
        $Currency = [String]$PoolInfo.currency
        $Divisor = [Double]$PoolInfo.mbtc_mh_factor * $DivisorMultiplier
        $PayoutCurrency = if ($Currency -and $PoolConfig.Wallets.$Currency) { $Currency } else { $PoolConfig.PayoutCurrency }
        $Reasons = [System.Collections.Generic.SortedSet[String]]::new()

        if (-not $PoolInfo.conversion_supported) { 
            if (-not $Currency) { [Void]$Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") }
            elseif (-not $PoolConfig.Wallets.$Currency) { [Void]$Reasons.Add("No wallet address for [$Currency] (conversion disabled at pool)") }
        }
        elseif (-not $PoolConfig.Wallets.$PayoutCurrency) { [Void]$Reasons.Add("No wallet address for [$PayoutCurrency]") }
        elseif ($Session.PoolData.$Name.Algorithm -contains "-$AlgorithmNorm") { [Void]$Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") }
        elseif ($Session.PoolData.$Name.Algorithm -like "+*" -and ($Session.PoolData.$Name.Algorithm -split "," -notcontains "+$($AlgorithmNorm)")) { [Void]$Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") }

        if ($PoolInfo.hashrate_last24h -eq 0 -and -not ($Session.Config.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { [Void]$Reasons.Add("No hashrate at pool") }

        $Key = "$($PoolVariant)_$($AlgorithmNorm)$(if ($Currency) { "-$Currency" })"
        $Value = $PoolInfo.$PriceField / $Divisor

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
                    Fee                      = $PoolInfo.Fees / 100
                    Host                     = "$($PoolInfo.algo).$($Region).$($HostSuffix)"
                    Key                      = $Key
                    Name                     = $Name
                    Pass                     = "$($PoolConfig.WorkerName),c=$PayoutCurrency$(if ($Currency) { ",zap=$Currency" })"
                    Port                     = $PoolInfo.port
                    PortSSL                  = 50000 + [UInt16]($PoolInfo.port)
                    PoolURL                  = $Poolinfo.URL
                    Price                    = if ($Stat.Live) { $Stat.Live } else { [Double]::NaN }
                    Protocol                 = if ($AlgorithmNorm -match $Session.RegexAlgoIsEthash) { "ethproxy" } elseif ($AlgorithmNorm -match $Session.RegexAlgoIsProgPow) { "stratum" } else { "" }
                    Reasons                  = $Reasons
                    Region                   = $RegionNorm
                    SendHashrate             = $false
                    SSLselfSignedCertificate = $true
                    StablePrice              = $Stat.Week
                    Updated                  = $PoolInfo.Updated
                    User                     = $PoolConfig.Wallets.$PayoutCurrency
                    Variant                  = $PoolVariant
                    WorkerName               = $PoolConfig.WorkerName
                    Workers                  = $PoolInfo.workers
                }
                break
            }
        }
    }
}

Write-Message -Level Debug "Pool '$PoolVariant': End"