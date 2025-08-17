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
File:           \Pools\NiceHash.ps1
Version:        6.5.6
Version date:   2025/08/17
#>

Param(
    [String]$PoolVariant
)

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$PoolHost = "auto.nicehash.com"

$PoolConfig = $Session.ConfigRunning.PoolsConfig.$Name

$Fee = $PoolConfig.Variant.$PoolVariant.Fee
$PayoutCurrency = $PoolConfig.PayoutCurrency

Write-Message -Level Debug "Pool '$PoolVariant': Start"

$APICallFails = 0

Do { 
    Try { 
        If (-not $Request) { 
            $Request = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info/" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPItimeout
            If ($RequestAlgodetails -like "<!DOCTYPE html>*") { $Request = $null }
        }
        If (-not $RequestAlgodetails) { 
            $RequestAlgodetails = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/mining/algorithms/" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPItimeout
            If ($RequestAlgodetails -like "<!DOCTYPE html>*") { $Request = $null }
        }
    }
    Catch { 
        $APICallFails ++
        Start-Sleep -Seconds ($APICallFails * 5 + $PoolConfig.PoolAPIretryInterval)
    }
} While (-not ($Request -and $RequestAlgodetails) -and $APICallFails -le $Session.ConfigRunning.PoolAPIallowedFailureCount)

If ($APICallFails -gt $Session.ConfigRunning.PoolAPIallowedFailureCount) { 
    Write-Message -Level Warn "Error '$($_.Exception.Message)' when trying to access https://api2.nicehash.com/main/api/v2."
}
ElseIf ($Request.miningAlgorithms) { 
    $Request.miningAlgorithms.ForEach(
        { 
            $Algorithm = $_.Algorithm
            $AlgorithmNorm = Get-Algorithm $Algorithm
            $Currencies = Get-CurrencyFromAlgorithm $AlgorithmNorm
            $Currency = If ($Currencies.Count -eq 1) { [String]$Currencies } Else { "" }
            $Divisor = 100000000

            $Reasons = [System.Collections.Generic.Hashset[String]]::new()
            If (-not $PoolConfig.Wallets.$PayoutCurrency) { $Reasons.Add("No wallet address for [$PayoutCurrency]") | Out-Null }
            If ($RequestAlgodetails.miningAlgorithms.Where({ $_.Algorithm -eq $Algorithm }).order -eq 0) { $Reasons.Add("No orders at pool") | Out-Null }
            If ($_.speed -eq 0 -and -not ($Session.ConfigRunning.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { $Reasons.Add("No hashrate at pool") | Out-Null }
            If ($Session.PoolData.$Name.Algorithm -contains "-$AlgorithmNorm") { $Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") | Out-Null }

            $Key = "$($Name)_$($AlgorithmNorm)"
            $Value = [Double]$_.paying / $Divisor

        $Stat = Get-Stat -Name "$($Key)_Profit"
        If ($Stat.Live -and $Value -gt 10 * $Session.ConfigRunning.PoolAllowedPriceIncreaseFactor) { 
            # New price should never spike more than 10x
            $Reasons.Add("Price data is more than 10x higher than previous price data (Error in pool API data?)") | Out-Null
        }
        Else { 
            $Stat = Set-Stat -Name "$($Key)_Profit" -Value $Value -FaultDetection $false
        }

            [PSCustomObject]@{ 
                Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Minute_5_Fluctuation), 1) # Use short timespan to counter price spikes
                Algorithm                = $AlgorithmNorm
                Currency                 = $Currency
                Disabled                 = $Stat.Disabled
                EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                Fee                      = $Fee
                Host                     = "$Algorithm.$PoolHost".ToLower()
                Key                      = $Key
                Name                     = $Name
                Pass                     = "x"
                Port                     = 9200
                PortSSL                  = 443
                PoolUri                  = "https://www.nicehash.com/algorithm/$($_.Algorithm.ToLower())"
                Price                    = If ($null -eq $_.paying) { [Double]::NaN } Else { $Stat.Live }
                Protocol                 = If ($AlgorithmNorm -match $Session.RegexAlgoIsEthash) { "ethstratumnh" } ElseIf ($AlgorithmNorm -match $Session.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                Region                   = [String]$PoolConfig.Region
                Reasons                  = $Reasons
                SendHashrate             = $false
                SSLselfSignedCertificate = $false
                StablePrice              = $Stat.Week
                Updated                  = [DateTime]$Stat.Updated
                User                     = "$($PoolConfig.Wallets.$PayoutCurrency).$($PoolConfig.WorkerName)"
                Variant                  = $Name
                WorkerName               = ""
                Workers                  = $null
            }
        }
    )
}

Write-Message -Level Debug "Pool '$PoolVariant': End"

$Error.Clear()
[System.GC]::Collect()