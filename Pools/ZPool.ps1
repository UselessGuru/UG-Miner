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
File:           \Pools\ZPool.ps1
Version:        6.5.2
Version date:   2025/07/27
#>

Param(
    [String]$PoolVariant
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$HostSuffix = "mine.zpool.ca"

$PoolConfig = $Session.PoolsConfig.$Name
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

Write-Message -Level Debug "Pool '$PoolVariant': Start"

If ($PriceField) { 

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
        $Currency = If ([String]$Request.$Algorithm.currency) { [String]$Request.$Algorithm.currency } Else { "" }
        $Divisor = [Double]$Request.$Algorithm.mbtc_mh_factor * $DivisorMultiplier
        $PayoutCurrency = If ($Currency -and $PoolConfig.Wallets.$Currency -and -not $PoolConfig.ProfitSwitching) { $Currency } Else { $PoolConfig.PayoutCurrency }

        $Reasons = [System.Collections.Generic.Hashset[String]]::new()
        If (-not $PoolConfig.Wallets.$PayoutCurrency) { $Reasons.Add("No wallet address for [$PayoutCurrency]") | Out-Null }
        If (-not $Request.$Algorithm.conversion_supported) { $Reasons.Add("No wallet address for [$Currency] (conversion disabled at pool)") | Out-Null }
        If ($Request.$Algorithm.hashrate_last24h -eq 0 -and -not ($Config.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { $Reasons.Add("No hashrate at pool") | Out-Null }
        If ($Session.PoolData.$Name.Algorithm -contains "-$AlgorithmNorm") { $Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") | Out-Null }

        # SCC firo variant is a separate algorithm (SCCPow)
        If ($Algorithm -eq "firopow" -and $Currency -eq "SCC") { continue }

        $Key = "$($PoolVariant)_$($AlgorithmNorm)$(If ($Currency) { "-$Currency" })"
        $Stat = Set-Stat -Name "$($Key)_Profit" -Value ($Request.$Algorithm.$PriceField / $Divisor) -FaultDetection $false

        ForEach ($RegionNorm in $Session.Regions[$Config.Region]) { 
            If ($Region = $PoolConfig.Region.Where({ (Get-Region $_) -eq $RegionNorm })) { 

                [PSCustomObject]@{ 
                    Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1)
                    Algorithm                = $AlgorithmNorm
                    Currency                 = $Currency
                    Disabled                 = $Stat.Disabled
                    EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                    Fee                      = $Request.$Algorithm.Fees / 100
                    Host                     = "$($Algorithm).$($Region).$($HostSuffix)"
                    Key                      = $Key
                    Name                     = $Name
                    Pass                     = "$($PoolConfig.WorkerName),c=$PayoutCurrency$(If ($Currency -eq $PayoutCurrency) { ",zap=$PayoutCurrency" })"
                    Port                     = [UInt16]$Request.$Algorithm.port
                    PortSSL                  = [UInt16](50000 + $Request.$Algorithm.port)
                    PoolUri                  = "https://zpool.ca/algo/$($Algorithm)"
                    Price                    = If ($null -eq $Request.$Algorithm.$PriceField) { [Double]::NaN } Else { $Stat.Live }
                    Protocol                 = If ($AlgorithmNorm -match $Session.RegexAlgoIsEthash) { "ethproxy" } ElseIf ($AlgorithmNorm -match $Session.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                    Reasons                  = $Reasons
                    Region                   = $RegionNorm
                    SendHashrate             = $false
                    SSLselfSignedCertificate = $true
                    StablePrice              = $Stat.Week
                    Updated                  = [DateTime]$Request.$Algorithm.Updated
                    User                     = $PoolConfig.Wallets.$PayoutCurrency
                    Variant                  = $PoolVariant
                    WorkerName               = ""
                    Workers                  = [UInt]$Request.$Algorithm.workers
                }
                Break
            }
        }
    }
}

Write-Message -Level Debug "Pool '$PoolVariant': End"

$Error.Clear()
[System.GC]::Collect()