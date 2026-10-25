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
Version:        6.9.1
Version date:   2026/10/25
#>

param(
    [String]$PoolVariant
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$PoolHost = "auto.nicehash.com"

$PoolConfig = $Session.Config.PoolsConfig.$Name
$PayoutCurrency = $PoolConfig.PayoutCurrency
$Wallet = $PoolConfig.Wallets.$PayoutCurrency

Write-Message -Level Debug "Pool '$PoolVariant': Start"

if (-not $Wallet) { 
    Write-Message -Level Warn "Pool '$Name': No wallet address for [$PayoutCurrency]."
    return
}

try { 
    $BrainData = if ($Session.Brains.$Name) { $Session.BrainData.$Name } else { [System.IO.File]::ReadAllLines($BrainDataFile) | ConvertFrom-Json -ErrorAction Ignore }
}
catch { 
    Write-Message -Level Warn "Pool '$Name': Cannot parse brain data."
    return
}
if (-not $BrainData) { 
        Write-Message -Level Warn "Pool '$Name': No brain data."
    return
}

foreach ($PoolInfo in ($BrainData.Where{ $_.Updated -ge $Session.PoolDataCollectedTimeStamp } | Sort-Object Algorithm)) { 

    $AlgorithmNorm = $PoolInfo.AlgorithmNorm
    $Reasons = [System.Collections.Generic.SortedSet[String]]::new()
    if ($PoolInfo.enabled -eq $false) { [Void]$Reasons.Add("Disabled at pool") }
    if ($PoolInfo.order -eq 0) { [Void]$Reasons.Add("No orders at pool") }
    if ($PoolInfo.speed -eq 0 -and -not ($Session.Config.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { [Void]$Reasons.Add("No hashrate at pool") }

    $Key = "$($Name)_$($AlgorithmNorm)"
    $Value = [Double]($PoolInfo.paying / 100000000)

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
        Host                     = "$($PoolInfo.algorithm).$PoolHost".ToLower()
        Key                      = $Key
        Name                     = $Name
        Pass                     = "x"
        Port                     = 9200
        PortSSL                  = 443
        PoolURL                  = $Poolinfo.URL
        Price                    = if ($Stat.Live) { $Stat.Live } else { [Double]::NaN }
        Protocol                 = if ($AlgorithmNorm -match $Session.RegexAlgoIsEthash) { "ethstratumnh" } elseif ($AlgorithmNorm -match $Session.RegexAlgoIsProgPow) { "stratum" } else { "" }
        Reasons                  = $Reasons
        Region                   = $PoolConfig.Region
        SendHashrate             = $false
        SSLselfSignedCertificate = $false
        StablePrice              = $Stat.Week
        Updated                  = $PoolInfo.Updated
        User                     = "$($Wallet).$($PoolConfig.WorkerName)"
        Variant                  = $Name
        WorkerName               = $PoolConfig.WorkerName
        Workers                  = $null
    }
}

Write-Message -Level Debug "Pool '$PoolVariant': End"