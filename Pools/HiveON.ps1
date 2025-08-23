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
File:           \Pools\HiveON.ps1
Version:        6.5.8
Version date:   2025/08/23
#>

Param(
    [String]$PoolVariant
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

$PoolConfig = $Session.ConfigRunning.PoolsConfig.$Name

Write-Message -Level Debug "Pool '$PoolVariant': Start"

$APICallFails = 0

Do { 
    Try { 
        $Request = Invoke-RestMethod -Uri "https://HiveON.net/api/v1/stats/pool" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPItimeout
        If ($Request -like "<!DOCTYPE html>*") { $Request = $null }
    }
    Catch { 
        $APICallFails ++
        Start-Sleep -Seconds ($APICallFails * 5 + $PoolConfig.PoolAPIretryInterval)
    }
} While (-not $Request -and $APICallFails -lt $Session.ConfigRunning.PoolAPIallowedFailureCount)

ForEach ($Pool in $Request.cryptoCurrencies.Where({ $_.name -ne "ETH" })) { 
    $Currency = $Pool.name -replace "\s+"
    If ($AlgorithmNorm = $Session.CurrencyAlgorithm[$Currency]) { 
        $Divisor = [Double]$Pool.profitPerPower

        # Add coin name
        If ($Pool.title -and $Currency) { 
            Add-CoinName -Algorithm $AlgorithmNorm -Currency $Currency -CoinName $Pool.title
        }

        $Reasons = [System.Collections.Generic.Hashset[String]]::new()
        If (-not $PoolConfig.Wallets.$Currency) { $Reasons.Add("No wallet address for [$Currency] (conversion disabled at pool)") | Out-Null }
        If ($Request.stats.($_.name).hashrate -eq 0 -and -not ($Session.ConfigRunning.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { $Reasons.Add("No hashrate at pool") | Out-Null }
        If ($Session.PoolData.$Name.Algorithm -contains "-$AlgorithmNorm") { $Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") | Out-Null }

        $Key = "$($PoolVariant)_$($AlgorithmNorm)$(If ($Currency) { "-$Currency" })"
        $Value = $Request.stats.($Pool.name).expectedReward24H * $Session.Rates.$Currency.BTC / $Divisor
        $Stat = Get-Stat -Name "$($Key)_Profit"
        If ($Stat.Live -and $Value -gt ($Stat.Live * $Session.ConfigRunning.PoolAllowedPriceIncreaseFactor)) { 
            $Reasons.Add("Unrealistic price (price in pool API data is more than $($Session.ConfigRunning.PoolAllowedPriceIncreaseFactor)x higher than previous price)") | Out-Null
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
            Fee                      = 0.03
            Host                     = [String]$Pool.servers[0].host
            Key                      = $Key
            Name                     = $Name
            Pass                     = "x"
            Port                     = [UInt16]$Pool.servers[0].ports[0]
            PortSSL                  = [UInt16]$Pool.servers[0].SSL_ports[0]
            PoolUri                  = "https://hiveon.net/$($Currency.ToLower())"
            Price                    = $Stat.Live
            Protocol                 = "ethproxy"
            Reasons                  = $Reasons
            Region                   = [String]$PoolConfig.Region
            SendHashrate             = $false
            SSLselfSignedCertificate = $false
            StablePrice              = $Stat.Week
            Updated                  = [DateTime]$Stat.Updated
            User                     = If ($PoolConfig.Wallets.$Currency) { [String]$PoolConfig.Wallets.$Currency } Else { "" }
            Variant                  = $PoolVariant
            WorkerName               = $PoolConfig.WorkerName
            Workers                  = [UInt]$Request.stats.$($Pool.name).workers
        }
    }
}

Write-Message -Level Debug "Pool '$PoolVariant': End"

$Error.Clear()
[System.GC]::Collect()