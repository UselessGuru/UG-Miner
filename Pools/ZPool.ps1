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
File:           \Pools\ZPool.ps1
Version:        6.3.17
Version date:   2024/11/26
#>

Param(
    [PSCustomObject]$Config,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$HostSuffix = "mine.zpool.ca"

$PoolConfig = $Variables.PoolsConfig.$Name
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

Write-Message -Level Debug "Pool '$PoolVariant': Start"

If ($PriceField) { 

    Try { 
        If ($Variables.Brains.$Name) { 
            $Request = $Variables.BrainData.$Name
        }
        Else { 
            $Request = $Request = [System.IO.File]::ReadAllLines($BrainDataFile) | ConvertFrom-Json
        }
    }
    Catch { Return }

    If (-not $Request.PSObject.Properties.Name) { Return }

    ForEach ($Algorithm in $Request.PSObject.Properties.Name.Where({ $Request.$_.Updated -ge $Variables.PoolDataCollectedTimeStamp })) { 
        $AlgorithmNorm = Get-Algorithm $Algorithm
        $Currency = [String]$Request.$Algorithm.currency
        $Divisor = [Double]$Request.$Algorithm.mbtc_mh_factor * $DivisorMultiplier
        $PayoutCurrency = If ($Currency -and $PoolConfig.Wallets.$Currency -and -not $PoolConfig.ProfitSwitching) { $Currency } Else { $PoolConfig.PayoutCurrency }

        $Reasons = [System.Collections.Generic.List[String]]@()
        If (-not $PoolConfig.Wallets.$PayoutCurrency) { $Reasons.Add("No wallet address for [$PayoutCurrency]") }
        If (-not $Request.$Algorithm.conversion_supported) { $Reasons.Add("No wallet address for [$Currency] (conversion disabled at pool)") }
        If ($Request.$Algorithm.hashrate_last24h -eq 0 -and -not ($Config.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { $Reasons.Add("No hashrate at pool") }
        If ($Variables.PoolData.$Name.Algorithm -contains "-$AlgorithmNorm") { $Reasons.Add("Algorithm@Pool not supported by $($Variables.Branding.ProductLabel)") }

        # SCC firo variant is a separate algorithm
        If ($Algorithm -eq "firopow" -and $Currency -eq "SCC") { continue }

        $Key = "$($PoolVariant)_$($AlgorithmNorm)$(If ($Currency) { "-$Currency" })"
        $Stat = Set-Stat -Name "$($Key)_Profit" -Value ($Request.$Algorithm.$PriceField / $Divisor) -FaultDetection $false

        ForEach ($RegionNorm in $Variables.Regions[$Config.Region]) { 
            If ($Region = $PoolConfig.Region.Where({ (Get-Region $_) -eq $RegionNorm })) { 

                [PSCustomObject]@{ 
                    Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1)
                    Algorithm                = $AlgorithmNorm
                    Currency                 = If ($Currency) { $Currency } Else { "" }
                    Disabled                 = $Stat.Disabled
                    EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                    Fee                      = $Request.$Algorithm.Fees / 100
                    Host                     = "$($Algorithm).$($Region).$($HostSuffix)"
                    Key                      = $Key
                    Name                     = $Name
                    Pass                     = "$($PoolConfig.WorkerName),c=$PayoutCurrency$(If ($Currency -eq $PayoutCurrency) { ",zap=$PayoutCurrency" })"
                    Port                     = [UInt16]$Request.$Algorithm.port
                    PortSSL                  = [UInt16]("5$([String]$Request.$Algorithm.port)")
                    PoolUri                  = "https://zpool.ca/algo/$($Algorithm)"
                    Price                    = $Stat.Live
                    Protocol                 = If ($AlgorithmNorm -match $Variables.RegexAlgoIsEthash) { "ethproxy" } ElseIf ($AlgorithmNorm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
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