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
File:           \Pools\HashCryptos.ps1
Version:        6.6.3
Version date:   2025/11/06
#>

Param(
    [String]$PoolVariant
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Hostsuffix = "stratum1.hashcryptos.com"

$PoolConfig = $Session.Config.Pools.$Name
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$PayoutCurrency = $PoolConfig.PayoutCurrency
$Wallet = $PoolConfig.Wallets.$PayoutCurrency
$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

Write-Message -Level Debug "Pool '$PoolVariant': Start"

If ($DivisorMultiplier -and $PriceField) { 

    Try { 
        If ($Session.Brains.$Name) { 
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
        $Currency = "$($Request.$Algorithm.currency)" -replace "\s+"
        $Divisor = [Double]$Request.$Algorithm.mbtc_mh_factor * $DivisorMultiplier

        # Add coin name
        If ($Request.$Algorithm.CoinName -and $Currency) { 
            Add-CoinName -Algorithm $AlgorithmNorm -Currency $Currency -CoinName $Request.$Algorithm.CoinName
        }

        $Reasons = [System.Collections.Generic.Hashset[String]]::new()
        If (-not $PoolConfig.Wallets.$PayoutCurrency) { $Reasons.Add("No wallet address for [$PayoutCurrency]") | Out-Null }
        If ($Request.$Algorithm.hashrate -eq 0 -or $Request.$Algorithm.hashrate_last24h -eq 0 -and -not ($Session.Config.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { $Reasons.Add("No hashrate at pool") | Out-Null }
        If ($Session.PoolData.$Name.Algorithm -contains "-$AlgorithmNorm") { $Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") | Out-Null }
        If ($Request.$Algorithm.coins -gt 1 -and [Double]$Request.$Algorithm.$PriceField -eq 0) { $Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") | Out-Null }
        If ($PoolConfig.PayoutCurrencies -notcontains $PoolConfig.PayoutCurrency) { $Reasons.Add("Payout currency [$($PoolConfig.PayoutCurrency)] not supported by by pool") | Out-Null }

        $Key = "$($PoolVariant)_$($AlgorithmNorm)$(If ($Currency) { "-$Currency" })"
        $Value = $Request.$Algorithm.$PriceField / $Divisor

        $Stat = Get-Stat -Name "$($Key)_Profit"
        If ($Stat.Live -and $Value -gt ($Stat.Live * $Session.Config.PoolAllowedPriceIncreaseFactor)) { 
            $Reasons.Add("Unrealistic price (price in pool API data is more than $($Session.Config.PoolAllowedPriceIncreaseFactor)x higher than previous price)") | Out-Null
        }
        Else { 
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
            PortSSL                  = If (($Request.$Algorithm.port -split " ")[2]) { ($Request.$Algorithm.port -split " ")[2] } Else { $null }
            PoolUri                  = ""
            Price                    = If ($null -eq $Request.$Algorithm.$PriceField) { [Double]::NaN } Else { $Stat.Live }
            Protocol                 = If ($AlgorithmNorm -match $Session.RegexAlgoIsEthash) { "ethstratum1" } ElseIf ($AlgorithmNorm -match $Session.RegexAlgoIsProgPow) { "stratum" } Else { "" }
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

$Error.Clear()
[System.GC]::Collect()