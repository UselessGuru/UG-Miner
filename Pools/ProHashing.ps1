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
File:           \Pools\ProHashing.ps1
Version:        6.5.16
Version date:   2025/10/19
#>

Param(
    [String]$PoolVariant
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$HostSuffix = "mining.prohashing.com"

$PoolConfig = $Session.ConfigRunning.PoolsConfig.$Name
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
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


    $Request.PSObject.Properties.Name.Where({ $Request.$_.Updated -ge $Session.PoolDataCollectedTimeStamp }).ForEach(
        { 
            $Algorithm = $Request.$_.name
            $AlgorithmNorm = Get-Algorithm $Algorithm
            $Currency = [String]$Request.$_.currency
            $Divisor = [Double]$Request.$_.mbtc_mh_factor * $DivisorMultiplier
            $Fee = If ($Currency) { $Request.$_."$($PoolConfig.MiningMode)_fee" } Else { $Request.$_."pps_fee" }
            $Pass = "a=$($Algorithm.ToLower()),n=$($PoolConfig.WorkerName)$(If ($Session.ConfigRunning.ProHashingMiningMode -eq "PPLNS" -and $Request.$_.CoinName) { ",c=$($Request.$_.CoinName.ToLower()),m=pplns" })"

            # Add coin name
            If ($Request.$_.CoinName -and $Currency) { 
                Add-CoinName -Algorithm $AlgorithmNorm -Currency $Currency -CoinName $Request.$_.CoinName
            }

            $Reasons = [System.Collections.Generic.Hashset[String]]::new()
            If (-not $PoolConfig.UserName) { $Reasons.Add("No username") | Out-Null }
            If ($Request.$_.hashrate -eq 0 -and -not ($Session.ConfigRunning.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { $Reasons.Add("No hashrate at pool") | Out-Null }
            If ($Session.PoolData.$Name.Algorithm -contains "-$AlgorithmNorm") { $Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") | Out-Null }

            $Key = "$($PoolVariant)_$($AlgorithmNorm)$(If ($Currency) { "-$Currency" })"
            $Value = $Request.$_.$PriceField / $Divisor

            $Stat = Get-Stat -Name "$($Key)_Profit"
            If ($Stat.Live -and $Value -gt ($Stat.Live * $Session.ConfigRunning.PoolAllowedPriceIncreaseFactor)) { 
                $Reasons.Add("Unrealistic price (price in pool API data is more than $($Session.ConfigRunning.PoolAllowedPriceIncreaseFactor)x higher than previous price)") | Out-Null
            }
            Else { 
                $Stat = Set-Stat -Name "$($Key)_Profit" -Value $Value -FaultDetection $false
            }

            ForEach ($RegionNorm in $Session.Regions[$Session.ConfigRunning.Region]) { 
                If ($Region = $PoolConfig.Region.Where({ (Get-Region $_) -eq $RegionNorm })) { 

                    [PSCustomObject]@{ 
                        Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1)
                        Algorithm                = $AlgorithmNorm
                        Currency                 = $Currency
                        Disabled                 = $Stat.Disabled
                        EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                        Fee                      = $Fee
                        Host                     = "$($Region.ToLower()).$HostSuffix"
                        Key                      = $Key
                        Name                     = $Name
                        Pass                     = $Pass
                        Port                     = [UInt16]$Request.$_.port
                        PortSSL                  = 0
                        Price                    = If ($null -eq $Request.$_.$PriceField) { [Double]::NaN } Else { $Stat.Live }
                        Protocol                 = If ($AlgorithmNorm -match $Session.RegexAlgoIsEthash) { "ethstratum1" } ElseIf ($AlgorithmNorm -match $Session.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                        Reasons                  = $Reasons
                        Region                   = $RegionNorm
                        SendHashrate             = $false
                        SSLselfSignedCertificate = $true
                        StablePrice              = $Stat.Week
                        Updated                  = [DateTime]$Stat.Updated
                        User                     = $PoolConfig.UserName
                        Variant                  = $PoolVariant
                        WorkerName               = $PoolConfig.WorkerName
                        Workers                  = $null
                    }
                    Break
                }
            }
        }
    )
}

Write-Message -Level Debug "Pool '$PoolVariant': End"

$Error.Clear()
[System.GC]::Collect()