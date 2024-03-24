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
File:           \Pools\NiceHash.ps1
Version:        6.2.1
Version date:   2024/03/24
#>

param(
    [PSCustomObject]$Config,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$PoolHost = "auto.nicehash.com"

$PoolConfig = $Variables.PoolsConfig.$Name
$PoolVariant = If ($Variables.NiceHashWalletIsInternal) { "NiceHash Internal" } Else { "NiceHash External" }

$Fee = $PoolConfig.Variant.$PoolVariant.Fee
$PayoutCurrency = $PoolConfig.Variant.$PoolVariant.PayoutCurrency
$Wallet = $PoolConfig.Variant.$PoolVariant.Wallets.$PayoutCurrency

Write-Message -Level Debug "Pool '$PoolVariant': Start"

If ($Wallet) { 

    $APICallFails = 0

    Do {
        Try { 
            If (-not $Request) { 
                $Request = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info/" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPITimeout
            }
            If (-not $RequestAlgodetails) { 
                $RequestAlgodetails = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/mining/algorithms/" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPITimeout
            }
            $Request.miningAlgorithms.ForEach(
                { 
                    $Algorithm = $_.Algorithm
                    $_ | Add-Member -Force @{ algodetails = $RequestAlgodetails.miningAlgorithms.Where({ $_.Algorithm -eq $Algorithm }) }
                }
            )
        }
        Catch { 
            $APICallFails ++
            Start-Sleep -Seconds ($APICallFails * 5 + $PoolConfig.PoolAPIRetryInterval)
        }
    } While (-not ($Request -and $RequestAlgodetails) -and $APICallFails -lt 3)

    If ($Request.miningAlgorithms) { 

        $Request.miningAlgorithms.ForEach(
            { 
                $Algorithm = $_.Algorithm
                $Algorithm_Norm = Get-Algorithm $Algorithm
                $Currencies = Get-CurrencyFromAlgorithm $Algorithm_Norm
                $Currency = If ($Currencies.Count -eq 1) { [String]$Currencies } Else { "" }

                $Divisor = 100000000

                $Key = "$($Name)_$($Algorithm_Norm)"
                $Stat = Set-Stat -Name "$($Key)_Profit" -Value ([Double]$_.paying / $Divisor) -FaultDetection $false

                $Reasons = [System.Collections.Generic.List[String]]@()
                If ($_.algodetails.order -eq 0) { $Reasons.Add("No orders at pool") }
                If ($_.speed -eq 0) { $Reasons.Add("No hashrate at pool") }

                [PSCustomObject]@{ 
                    Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Minute_5_Fluctuation), 1) # Use short timespan to counter price spikes
                    Algorithm                = $Algorithm_Norm
                    Currency                 = $Currency
                    Disabled                 = $Stat.Disabled
                    EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                    Fee                      = $Fee
                    Host                     = "$Algorithm.$PoolHost".ToLower()
                    Key                      = $Key
                    MiningCurrency           = ""
                    Name                     = $Name
                    Pass                     = "x"
                    Port                     = 9200
                    PortSSL                  = 443
                    PoolUri                  = "https://www.nicehash.com/algorithm/$($_.Algorithm.ToLower())"
                    Price                    = $Stat.Live
                    Protocol                 = If ($Algorithm_Norm -match $Variables.RegexAlgoIsEthash) { "ethstratumnh" } ElseIf ($Algorithm_Norm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                    Region                   = [String]$PoolConfig.Region
                    Reasons                  = $Reasons
                    SendHashrate             = $false
                    SSLSelfSignedCertificate = $false
                    StablePrice              = $Stat.Week
                    Updated                  = [DateTime]$Stat.Updated
                    User                     = "$Wallet.$($PoolConfig.WorkerName)"
                    WorkerName               = ""
                    Variant                  = $Name
                }
            }
        )
    }
}

Write-Message -Level Debug "Pool '$PoolVariant': End"

$Error.Clear()
[System.GC]::Collect()