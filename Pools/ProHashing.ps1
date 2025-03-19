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
File:           \Pools\ProHashing.ps1
Version:        6.4.17
Version date:   2025/03/19
#>

Param(
    [PSCustomObject]$Config,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$HostSuffix = "mining.prohashing.com"

$PoolConfig = $Variables.PoolsConfig.$Name
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

Write-Message -Level Debug "Pool '$PoolVariant': Start"

If ($DivisorMultiplier -and $PriceField) { 

    Try { 
        If ($Variables.Brains.$Name) { 
            $Request = $Variables.BrainData.$Name
        }
        Else { 
            $Request = [System.IO.File]::ReadAllLines($BrainDataFile) | ConvertFrom-Json
        }
    }
    Catch { Return }

    If (-not $Request.PSObject.Properties.Name) { Return }


    $Request.PSObject.Properties.Name.Where({ $Request.$_.Updated -ge $Variables.PoolDataCollectedTimeStamp }).ForEach(
        { 
            $Algorithm = $Request.$_.name
            $AlgorithmNorm = Get-Algorithm $Algorithm
            $Currency = [String]$Request.$_.currency
            $Divisor = [Double]$Request.$_.mbtc_mh_factor * $DivisorMultiplier
            $Fee = If ($Currency) { $Request.$_."$($PoolConfig.MiningMode)_fee" } Else { $Request.$_."pps_fee" }
            $Pass = "a=$($Algorithm.ToLower()),n=$($PoolConfig.WorkerName)$(If ($Config.ProHashingMiningMode -eq "PPLNS" -and $Request.$_.CoinName) { ",c=$($Request.$_.CoinName.ToLower()),m=pplns" })"

            # Add coin name
            If ($Request.$_.CoinName -and $Currency) { 
                [Void](Add-CoinName -Algorithm $AlgorithmNorm -Currency $Currency -CoinName $Request.$_.CoinName)
            }

            $Reasons = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            If (-not $PoolConfig.UserName) { $Reasons.Add("No username") | Out-Null }
            If ($Request.$_.hashrate -eq 0 -and -not ($Config.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { $Reasons.Add("No hashrate at pool") | Out-Null }
            If ($Variables.PoolData.$Name.Algorithm -contains "-$AlgorithmNorm") { $Reasons.Add("Algorithm@Pool not supported by $($Variables.Branding.ProductLabel)") | Out-Null }

            $Key = "$($PoolVariant)_$($AlgorithmNorm)$(If ($Currency) { "-$Currency" })"
            $Stat = Set-Stat -Name "$($Key)_Profit" -Value ($Request.$_.$PriceField / $Divisor) -FaultDetection $false

            ForEach ($RegionNorm in $Variables.Regions[$Config.Region]) { 
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
                        Price                    = If ($Request.$_.actual_last24h -eq 0) { [Double]::NaN } Else { $Stat.Live }
                        Protocol                 = If ($AlgorithmNorm -match $Variables.RegexAlgoIsEthash) { "ethstratum1" } ElseIf ($AlgorithmNorm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
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