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
File:           \Pools\MiningDutch.ps1
Version:        6.9.2
Version date:   2026/10/30
#>

param(
    [String]$PoolVariant
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Hostsuffix = "mining-dutch.nl"

$PoolConfig = $Session.Config.PoolsConfig.$Name
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$PayoutCurrency = $PoolConfig.PayoutCurrency
$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

Write-Message -Level Debug "Pool '$PoolVariant': Start"

if ($DivisorMultiplier -and $PriceField) { 

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

    foreach ($Pool in $BrainData.Where{ $_.Updated -ge $Session.PoolDataCollectedTimeStamp }) { 

        $Currency = $Pool.currency
        $Divisor = [Double]$Pool.mbtc_mh_factor * $DivisorMultiplier

        $Reasons = [System.Collections.Generic.SortedSet[String]]::new()
        if (-not $PoolConfig.UserName) { [Void]$Reasons.Add("No username") }
        # Sometimes pool returns $null hashrate for all algorithms
        if (-not $Pool.hashrate_shared -and -not ($Session.Config.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { [Void]$Reasons.Add("No hashrate at pool") }
        # if ($Pool.coins -gt 1 -and [Double]$Pool.$PriceField -eq 0) { [Void]$Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") }
 
        $Key = "$($PoolVariant)_$($Pool.AlgorithmNorm)$(if ($Currency) { "-$Currency" })"
        $Value = $Pool.$PriceField / $Divisor

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
                    Algorithm                = $Pool.AlgorithmNorm
                    Currency                 = $Currency
                    Disabled                 = $Stat.Disabled
                    EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                    Fee                      = $Pool.Fees / 100
                    Host                     = "$($Region).$($HostSuffix)"
                    Key                      = $Key
                    Name                     = $Name
                    Pass                     = "$($PoolConfig.WorkerName),c=$PayoutCurrency"
                    Port                     = [UInt16]$Pool.port
                    PortSSL                  = 0
                    PoolURL                  = "https://www.mining-dutch.nl/?page=pools"
                    Price                    = if ($null -eq $Pool.$PriceField) { [Double]::NaN } else { $Stat.Live }
                    Protocol                 = if ($Pool.AlgorithmNorm -match $Session.RegexAlgoIsEthash) { "ethstratum1" } elseif ($Pool.AlgorithmNorm -match $Session.RegexAlgoIsProgPow) { "stratum" } else { "" }
                    Reasons                  = $Reasons
                    Region                   = $RegionNorm
                    SendHashrate             = $false
                    SSLselfSignedCertificate = $true
                    StablePrice              = $Stat.Week
                    Updated                  = $Pool.Updated
                    User                     = $PoolConfig.UserName
                    Variant                  = $PoolVariant
                    WorkerName               = $PoolConfig.WorkerName
                    Workers                  = $Pool.workers_shared
                }
                break
            }
        }
    }
}

Write-Message -Level Debug "Pool '$PoolVariant': End"