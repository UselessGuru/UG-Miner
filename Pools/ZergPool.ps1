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
File:           \Pools\ZergPool.ps1
Version:        6.3.8
Version date:   2024/10/12
#>

Param(
    [PSCustomObject]$Config,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$HostSuffix = "mine.zergpool.com"

$PoolConfig = $Variables.PoolsConfig.$Name
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$Regions = If ($Config.UseAnycast -and $PoolConfig.Region -contains "n/a (Anycast)") { "n/a (Anycast)" } Else { $PoolConfig.Region.Where({ $_ -ne "n/a (Anycast)" }) }
$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

$WorkerName = $PoolConfig.WorkerName -replace '^ID='

Write-Message -Level Debug "Pool '$PoolVariant': Start"

If ($DivisorMultiplier -and $Regions) { 

    Try { 
        If ($Variables.BrainData.$Name.PSObject.Properties) { 
            $Request = $Variables.BrainData.$Name
        }
        Else { 
            $Request = $Request = [System.IO.File]::ReadAllLines($BrainDataFile) | ConvertFrom-Json
        }
    }
    Catch { Return }

    If (-not $Request.PSObject.Properties.Name) { Return }

    ForEach ($Pool in $Request.PSObject.Properties.Name.Where({ $Request.$_.Updated -ge $Variables.PoolDataCollectedTimeStamp })) { 
        $Algorithm = $Request.$Pool.algo
        $AlgorithmNorm = Get-Algorithm $Algorithm
        $Currency = [String]$Request.$Pool.Currency
        $Divisor = [Double]$Request.$Pool.mbtc_mh_factor * $DivisorMultiplier

        $PayoutCurrency = If ($Currency -and $PoolConfig.Wallets.$Pool -and -not $PoolConfig.ProfitSwitching) { $Currency } Else { $PoolConfig.PayoutCurrency }
        $PayoutThreshold = $PoolConfig.PayoutThreshold.$PayoutCurrency
        If ($PayoutThreshold -gt $Request.$Pool.minpay) { $PayoutThreshold = $Request.$Pool.minpay }
        If (-not $PayoutThreshold -and $PayoutCurrency -eq "BTC" -and $PoolConfig.PayoutThreshold.mBTC) { $PayoutThreshold = $PoolConfig.PayoutThreshold.mBTC / 1000 }
        If ($PayoutThreshold) { $PayoutThresholdParameter = ",pl=$([Double]$PayoutThreshold)" }

        $Reasons = [System.Collections.Generic.List[String]]@()
        If (-not $PoolConfig.Wallets.$PayoutCurrency) { $Reasons.Add("No wallet address for [$PayoutCurrency]") }
        If ($Request.$Pool.noautotrade -eq 1 -and $Pool -ne $PayoutCurrency) { $Reasons.Add("No wallet address for [$Pool] (conversion disabled at pool)") }
        If ($Request.$Pool.hashrate_shared -eq 0 -and -not ($Config.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { $Reasons.Add("No hashrate at pool") }

        # Cannot cast negative values to [UInt]
        If ($Request.$Pool.workers_shared -lt 0) { $Request.$Pool.workers_shared = 0 }

        $Key = "$($PoolVariant)_$($AlgorithmNorm)$(If ($Currency) { "-$($Currency)" })"
        $Stat = Set-Stat -Name "$($Key)_Profit" -Value ($Request.$Pool.$PriceField / $Divisor) -FaultDetection $false

        ForEach ($RegionNorm in $Variables.Regions[$Config.Region]) { 
            If ($Region = $Regions.Where({ $_ -eq "n/a (Anycast)" -or (Get-Region $_) -eq $RegionNorm })) { 

                If ($Region -eq "n/a (Anycast)") { 
                    $PoolHost = "$Algorithm.$HostSuffix"
                    $RegionNorm = $Region
                }
                Else { 
                    $PoolHost = "$Algorithm.$Region.$HostSuffix"
                }

                [PSCustomObject]@{ 
                    Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1)
                    Algorithm                = $AlgorithmNorm
                    Currency                 = If ($Currency) { $Currency } Else { "" }
                    Disabled                 = $Stat.Disabled
                    EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                    Fee                      = $Request.$Pool.Fees / 100
                    Host                     = $PoolHost.toLower()
                    Key                      = $Key
                    Name                     = $Name
                    Pass                     = "c=$PayoutCurrency$(If ($Currency) { ",mc=$Currency" }),ID=$WorkerName$PayoutThresholdParameter" # Pool profit switching breaks Option 2 (static coin), instead it will still send DAG data for any coin
                    Port                     = [UInt16]$Request.$Pool.port
                    PortSSL                  = [UInt16]$Request.$Pool.tls_port
                    PoolUri                  = "https://zergpool.com/pool/$($Algorithm)"
                    Price                    = $Stat.Live
                    Protocol                 = If ($AlgorithmNorm -match $Variables.RegexAlgoIsEthash) { "ethstratum2" } ElseIf ($AlgorithmNorm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                    Reasons                  = $Reasons
                    Region                   = $RegionNorm
                    SendHashrate             = $false
                    SSLselfSignedCertificate = $false
                    StablePrice              = $Stat.Week
                    Updated                  = [DateTime]$Request.$Pool.Updated
                    User                     = $PoolConfig.Wallets.$PayoutCurrency
                    Variant                  = $PoolVariant
                    WorkerName               = ""
                    Workers                  = [UInt]$Request.$Pool.workers_shared
                }
                Break
            }
        }
    }
}

Write-Message -Level Debug "Pool '$PoolVariant': End"

$Error.Clear()
[System.GC]::Collect()