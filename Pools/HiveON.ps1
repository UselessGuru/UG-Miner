<#
Copyright (c) 2018-2024 UselessGuru


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
File:           \Pools\Hiveon.ps1
Version:        6.2.13
Version date:   2024/06/30
#>

Param(
    [PSCustomObject]$Config,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

$PoolConfig = $Variables.PoolsConfig.$Name

Write-Message -Level Debug "Pool '$PoolVariant': Start"

If ($PoolConfig.Wallets) { 

    $APICallFails = 0

    Do {
        Try { 
            $Request = Invoke-RestMethod -Uri $PoolConfig.PoolStatusUri -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPITimeout
        }
        Catch { 
            $APICallFails ++
            Start-Sleep -Seconds ($APICallFails * 5 + $PoolConfig.PoolAPIRetryInterval)
        }
    } While (-not $Request -and $APICallFails -lt 3)

    If (-not $Request) { Return }

    ForEach ($Pool in $Request.cryptoCurrencies.Where({ $_.name -ne "ETH" })) { 
        $Currency = $Pool.name -replace ' \s+'
        If ($AlgorithmNorm = Get-AlgorithmFromCurrency $Currency) { 
            $Divisor = [Double]$Pool.profitPerPower

            # Add coin name
            If ($Pool.title -and $Currency) { 
                [Void](Add-CoinName -Algorithm $AlgorithmNorm -Currency $Currency -CoinName $Pool.title)
            }

            $Key = "$($PoolVariant)_$($AlgorithmNorm)$(If ($Currency) { "-$Currency" })"
            $Stat = Set-Stat -Name "$($Key)_Profit" -Value ($Request.stats.($Pool.name).expectedReward24H * $Variables.Rates.$Currency.BTC / $Divisor) -FaultDetection $false

            $Reasons = [System.Collections.Generic.List[String]]@()
            If ($Request.stats.($_.name).hashrate -eq 0) { $Reasons.Add("No hashrate at pool") }
            If (-not $PoolConfig.Wallets.$Currency) { $Reasons.Add("Conversion disabled at pool, no wallet address for [$Currency] configured") }

            [PSCustomObject]@{ 
                Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1)
                Algorithm                = $AlgorithmNorm
                Currency                 = $Currency
                Disabled                 = $Stat.Disabled
                EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                Fee                      = 0.03
                Host                     = [String]$Pool.servers[0].host
                Key                      = $Key
                MiningCurrency           = ""
                Name                     = $Name
                Pass                     = "x"
                Port                     = [UInt16]$Pool.servers[0].ports[0]
                PortSSL                  = [UInt16]$Pool.servers[0].ssl_ports[0]
                PoolUri                  = "https://hiveon.net/$($Currency.ToLower())"
                Price                    = $Stat.Live
                Protocol                 = "ethproxy"
                Reasons                  = $Reasons
                Region                   = [String]$PoolConfig.Region
                SendHashrate             = $false
                SSLSelfSignedCertificate = $false
                StablePrice              = $Stat.Week
                Updated                  = [DateTime]$Stat.Updated
                User                     = If ($PoolConfig.Wallets.$Currency) { [String]$PoolConfig.Wallets.$Currency } Else { "" }
                Workers                  = [UInt]$Request.stats."$($Pool.name)".workers
                WorkerName               = $PoolConfig.WorkerName
                Variant                  = $PoolVariant
            }
        }
    }
}

Write-Message -Level Debug "Pool '$PoolVariant': End"

$Error.Clear()
[System.GC]::Collect()