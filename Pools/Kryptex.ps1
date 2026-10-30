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
File:           \Pools\Kryptex.ps1
Version:        6.9.2
Version date:   2026/10/30
#>

param(
    [String]$PoolVariant
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

$PoolConfig = $Session.Config.PoolsConfig.$Name
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

# Loop through each available pool
foreach ($Pool in ($BrainData.Where{ $_.Updated -ge $Session.PoolDataCollectedTimeStamp } | Sort-Object)) { 

    $AlgorithmNorm = $Pool.AlgorithmNorm
    $Currency = $Pool.Currency

    $Reasons = [System.Collections.Generic.SortedSet[String]]::new()
    if ($PoolConfig.UserName) { 
        $User = $PoolConfig.UserName
    }
    elseif ($PoolConfig.Wallets.$Currency) { 
        $User = $PoolConfig.Wallets.$Currency
    }
    else { 
        [Void]$Reasons.Add("No wallet for [$Currency] or no Kryptex username")
        $User = ""
    }

    $Key = "$($PoolVariant)_$($AlgorithmNorm)$(if ($Currency) { "-$Currency" })"

    if ($Pool.estimated_profit_day) { 
        if ($Session.Rates[$Currency]) { 
            $Value = [Double]($Pool.estimated_profit_day * $Session.Rates[$Currency]["BTC"])

            $Stat = Get-Stat -Name "$($Key)_Profit"
            if ($Stat.Live -and $Value -gt ($Stat.Live * $Session.Config.PoolAllowedPriceIncreaseFactor)) { 
                [Void]$Reasons.Add("Unrealistic price (price in pool API data is more than $($Session.Config.PoolAllowedPriceIncreaseFactor)x higher than previous price)")
            }
            else { 
                $Stat = Set-Stat -Name "$($Key)_Profit" -Value $Value -FaultDetection $false
            }
        }
        else { 
            $Value = $null
            [Void]$Reasons.Add("Cannot calculate BTC equivalent (no exchange rate available)")
        }
    }

    $Pool.Servers.ForEach{ 
        $RegionNorm = Get-Region $_.Geo
        if ($Session.Config.Region -eq $RegionNorm) { 
            @{
                Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Minute_5_Fluctuation), 1) # Use short timespan to counter price spikes
                Algorithm                = $AlgorithmNorm
                Currency                 = $Currency
                Disabled                 = $Stat.Disabled
                EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                Fee                      = $Pool.fee
                Host                     = $_.urls[0] -replace ":.+"
                Key                      = $Key
                Name                     = $Name
                Pass                     = "x"
                Port                     = if ($_.urls[0]) { $_.urls[0] -replace ".+:" } else { $null }
                PortSSL                  = if ($_.ssl_urls[0]) { $_.ssl_urls[0] -replace ".+:" } else { $null }
                PoolURL                  = $Pool.URL
                Price                    = if ($null -eq $Pool.estimated_profit_day) { [Double]::NaN } else { $Stat.Live }
                Protocol                 = if ($AlgorithmNorm -match $Session.RegexAlgoIsEthash) { "ethstratum1" } elseif ($AlgorithmNorm -match $Session.RegexAlgoIsProgPow) { "stratum" } else { "" }
                Reasons                  = $Reasons
                Region                   = $RegionNorm
                SendHashrate             = $false
                SSLselfSignedCertificate = $false
                StablePrice              = $Stat.Week
                User                     = "$User.$($PoolConfig.WorkerName)"
                Updated                  = $Pool.Updated
                Variant                  = $Name
                WorkerName               = $PoolConfig.WorkerName
                Workers                  = $Pool.workers
            }
        }
    }
}

Write-Message -Level Debug "Pool '$PoolVariant': End"