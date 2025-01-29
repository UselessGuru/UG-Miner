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
File:           \Pools\HashCryptos.ps1
Version:        6.4.6
Version date:   2025/01/29
#>

Param(
    [PSCustomObject]$Config,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Hostsuffix = "stratum1.hashcryptos.com"

$PoolConfig = $Variables.PoolsConfig.$Name
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$PayoutCurrency = $PoolConfig.PayoutCurrency
$Wallet = $PoolConfig.Wallets.$PayoutCurrency
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

    ForEach ($Algorithm in $Request.PSObject.Properties.Name.Where({ $Request.$_.Updated -ge $Variables.PoolDataCollectedTimeStamp })) { 
        $AlgorithmNorm = Get-Algorithm $Algorithm
        $Currency = "$($Request.$Algorithm.currency)" -replace ' \s+'
        $Divisor = [Double]$Request.$Algorithm.mbtc_mh_factor * $DivisorMultiplier

        # Add coin name
        If ($Request.$Algorithm.CoinName -and $Currency) { 
            [Void](Add-CoinName -Algorithm $AlgorithmNorm -Currency $Currency -CoinName $Request.$Algorithm.CoinName)
        }

        $Reasons = [System.Collections.Generic.List[String]]@()
        If (-not $PoolConfig.Wallets.$PayoutCurrency) { $Reasons.Add("No wallet address for [$PayoutCurrency]") }
        If ($Request.$Algorithm.hashrate -eq 0 -or $Request.$Algorithm.hashrate_last24h -eq 0 -and -not ($Config.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { $Reasons.Add("No hashrate at pool") }
        If ($Variables.PoolData.$Name.Algorithm -contains "-$AlgorithmNorm") { $Reasons.Add("Algorithm@Pool not supported by $($Variables.Branding.ProductLabel)") }

        $Key = "$($PoolVariant)_$($AlgorithmNorm)$(If ($Currency) { "-$Currency" })"
        $Stat = Set-Stat -Name "$($Key)_Profit" -Value ($Request.$Algorithm.$PriceField / $Divisor) -FaultDetection $false

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
            Price                    = $Stat.Live
            Protocol                 = If ($AlgorithmNorm -match $Variables.RegexAlgoIsEthash) { "ethstratum1" } ElseIf ($AlgorithmNorm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
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