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
File:           \Pools\MiningDutch.ps1
Version:        6.7.15
Version date:   2025/12/29
#>

param(
    [String]$PoolVariant
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Hostsuffix = "mining-dutch.nl"

$PoolConfig = $Session.Config.Pools.$Name
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$PayoutCurrency = $PoolConfig.PayoutCurrency
$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

Write-Message -Level Debug "Pool '$PoolVariant': Start"

if ($DivisorMultiplier -and $PriceField) { 

    try { 
        if ($Session.Brains.$Name) { 
            $Request = $Session.BrainData.$Name
        }
        else { 
            $Request = [System.IO.File]::ReadAllLines($BrainDataFile) | ConvertFrom-Json
        }
    }
    catch { return }

    if (-not $Request.PSObject.Properties.Name) { return }

    foreach ($Algorithm in $Request.PSObject.Properties.Name.Where({ $Request.$_.Updated -ge $Session.PoolDataCollectedTimeStamp })) { 
        $AlgorithmNorm = Get-Algorithm $Algorithm
        $Currency = "$($Request.$Algorithm.currency)" -replace "\s+"
        $Divisor = [Double]$Request.$Algorithm.mbtc_mh_factor * $DivisorMultiplier

        # Add coin name
        if ($Request.$Algorithm.CoinName -and $Currency) { 
            Add-CoinName -Algorithm $AlgorithmNorm -Currency $Currency -CoinName $Request.$Algorithm.CoinName
        }

        $Reasons = [System.Collections.Generic.Hashset[String]]::new()
        if (-not $PoolConfig.UserName) { $Reasons.Add("No username") | Out-Null }
        # Sometimes pool returns $null hashrate for all algorithms
        if (-not $Request.$Algorithm.hashrate_shared -and -not ($Session.Config.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { $Reasons.Add("No hashrate at pool") | Out-Null }
        if ($Request.$Algorithm.coins -gt 1 -and [Double]$Request.$Algorithm.$PriceField -eq 0) { $Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") | Out-Null }
        elseif ($Session.PoolData.$Name.Algorithm -contains "-$AlgorithmNorm") { $Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") | Out-Null }
        elseif ($Session.PoolData.$Name.Algorithm -like "+*" -and ($Session.PoolData.$Name.Algorithm -split "," -notcontains "+$($AlgorithmNorm)")) { $Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") | Out-Null }

        $Key = "$($PoolVariant)_$($AlgorithmNorm)$(if ($Currency) { "-$Currency" })"
        $Value = $Request.$Algorithm.$PriceField / $Divisor

        $Stat = Get-Stat -Name "$($Key)_Profit"
        if ($Stat.Live -and $Value -gt ($Stat.Live * $Session.Config.PoolAllowedPriceIncreaseFactor)) { 
            $Reasons.Add("Unrealistic price (price in pool API data is more than $($Session.Config.PoolAllowedPriceIncreaseFactor)x higher than previous price)") | Out-Null
        }
        else { 
            $Stat = Set-Stat -Name "$($Key)_Profit" -Value $Value -FaultDetection $false
        }

        foreach ($RegionNorm in $Session.Regions[$Session.Config.Region]) { 
            if ($Region = $PoolConfig.Region.Where({ (Get-Region $_) -eq $RegionNorm })) { 

                [PSCustomObject]@{ 
                    Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1)
                    Algorithm                = $AlgorithmNorm
                    Currency                 = $Currency
                    Disabled                 = $Stat.Disabled
                    EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                    Fee                      = $Request.$Algorithm.Fees / 100
                    Host                     = "$($Region).$($HostSuffix)"
                    Key                      = $Key
                    Name                     = $Name
                    Pass                     = "$($PoolConfig.WorkerName),c=$PayoutCurrency"
                    Port                     = [UInt16]$Request.$Algorithm.port
                    PortSSL                  = 0
                    PoolUri                  = "https://www.mining-dutch.nl/?page=pools"
                    Price                    = if ($null -eq $Request.$Algorithm.$PriceField) { [Double]::NaN } else { $Stat.Live }
                    Protocol                 = if ($AlgorithmNorm -match $Session.RegexAlgoIsEthash) { "ethstratum1" } elseif ($AlgorithmNorm -match $Session.RegexAlgoIsProgPow) { "stratum" } else { "" }
                    Reasons                  = $Reasons
                    Region                   = $RegionNorm
                    SendHashrate             = $false
                    SSLselfSignedCertificate = $true
                    StablePrice              = $Stat.Week
                    Updated                  = [DateTime]$Request.$Algorithm.Updated
                    User                     = "$($PoolConfig.UserName).$($PoolConfig.WorkerName)"
                    Variant                  = $PoolVariant
                    WorkerName               = ""
                    Workers                  = [UInt]$Request.$Algorithm.workers_shared
                }
                break
            }
        }
    }
}

Write-Message -Level Debug "Pool '$PoolVariant': End"

$Error.Clear()
[System.GC]::Collect()