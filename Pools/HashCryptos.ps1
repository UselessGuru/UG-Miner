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
File:           \Pools\HashCryptos.ps1
Version:        6.8.21
Version date:   2026/08/21
#>

param(
    [String]$PoolVariant
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Hostsuffix = "stratum1.hashcryptos.com"

$PoolConfig = $Session.Config.PoolsConfig.$Name
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$PayoutCurrency = $PoolConfig.PayoutCurrency
$Wallet = $PoolConfig.Wallets.$PayoutCurrency
$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

Write-Message -Level Debug "Pool '$PoolVariant': Start"

if ($DivisorMultiplier -and $PriceField) { 

    try { 
        $Request = if ($Session.Brains.$Name) { $Session.BrainData.$Name } else { [System.IO.File]::ReadAllLines($BrainDataFile) | ConvertFrom-Json }
    }
    catch { return }

    if (-not $Request.PSObject.Properties.Name) { return }

    foreach ($Algorithm in $Request.PSObject.Properties.Name.Where{ $Request.$_.Updated -ge $Session.PoolDataCollectedTimeStamp }) { 
        $AlgorithmNorm = Get-Algorithm $Algorithm
        $Currency = "$($Request.$Algorithm.currency)" -replace "\s+"
        $Divisor = [Double]$Request.$Algorithm.mbtc_mh_factor * $DivisorMultiplier

        # Add coin name
        if ($Request.$Algorithm.CoinName -and $Currency) { 
            Add-CoinName -Currency $Currency -CoinName $Request.$Algorithm.CoinName
            Add-CurrencyAlgorithm -Algorithm $AlgorithmNorm -Currency $Currency
        }

        $Reasons = [System.Collections.Generic.Hashset[String]]::new()
        if (-not $PoolConfig.Wallets.$PayoutCurrency) { [Void]$Reasons.Add("No wallet address for [$PayoutCurrency]") }
        if ($Request.$Algorithm.hashrate -eq 0 -or $Request.$Algorithm.hashrate_last24h -eq 0 -and -not ($Session.Config.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { [Void]$Reasons.Add("No hashrate at pool") }
        if ($PoolConfig.PayoutCurrencies -notcontains $PoolConfig.PayoutCurrency) { [Void]$Reasons.Add("Payout currency [$($PoolConfig.PayoutCurrency)] not supported by by pool") }

        $Key = "$($PoolVariant)_$($AlgorithmNorm)$(if ($Currency) { "-$Currency" })"
        $Value = $Request.$Algorithm.$PriceField / $Divisor

        $Stat = Get-Stat -Name "$($Key)_Profit"
        if ($Stat.Live -and $Value -gt ($Stat.Live * $Session.Config.PoolAllowedPriceIncreaseFactor)) { 
            [Void]$Reasons.Add("Unrealistic price (price in pool API data is more than $($Session.Config.PoolAllowedPriceIncreaseFactor)x higher than previous price)")
        }
        else { 
            $Stat = Set-Stat -Name "$($Key)_Profit" -Value $Value -FaultDetection $false
        }

        [PSCustomObject]@{ 
            Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1)
            Algorithm                = $AlgorithmNorm
            Currency                 = $Currency
            Disabled                 = $Stat.Disabled
            EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
            Fee                      = $Request.$Algorithm.Fees / 100
            Host                     = $HostSuffix
            Key                      = $Key
            Name                     = $Name
            Pass                     = "x"
            Port                     = [UInt16]($Request.$Algorithm.port -split " ")[0]
            PortSSL                  = if (($Request.$Algorithm.port -split " ")[2]) { ($Request.$Algorithm.port -split " ")[2] } else { $null }
            PoolUri                  = ""
            Price                    = if ($null -eq $Request.$Algorithm.$PriceField) { [Double]::NaN } else { $Stat.Live }
            Protocol                 = if ($AlgorithmNorm -match $Session.RegexAlgoIsEthash) { "ethstratum1" } elseif ($AlgorithmNorm -match $Session.RegexAlgoIsProgPow) { "stratum" } else { "" }
            Reasons                  = $Reasons
            Region                   = [String]$PoolConfig.Region
            SendHashrate             = $false
            SSLselfSignedCertificate = $true
            StablePrice              = $Stat.Week
            Updated                  = [DateTime]$Request.$Algorithm.Updated
            User                     = $Wallet
            Variant                  = $PoolVariant
            WorkerName               = $PoolConfig.WorkerName
            Workers                  = [UInt]$Request.$Algorithm.workers
        }
    }
}

Write-Message -Level Debug "Pool '$PoolVariant': End"