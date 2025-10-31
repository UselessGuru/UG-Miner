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
File:           \Pools\MiningPoolHub.ps1
Version:        6.6.0
Version date:   2025/02/23
#>

Param(
    [String]$PoolVariant
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

$PoolConfig = $Session.Config.Pools.$Name

$Headers = @{ "Cache-Control" = "no-cache" }
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

Write-Message -Level Debug "Pool '$PoolVariant': Start"

$APICallFails = 0

Do { 
    Try { 
        $Request = Invoke-RestMethod -Uri "https://miningpoolhub.com/index.php?page=api&action=getminingandprofitsstatistics" -Headers $Headers -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPItimeout -UserAgent $UserAgent
        If ($Request -like "<!DOCTYPE html>*") { $Request = $null }
    }
    Catch { 
        $APICallFails ++
        Start-Sleep -Seconds ($APICallFails * 5 + $PoolConfig.PoolAPIretryInterval)
    }
} While (-not $Request -and $APICallFails -lt $Session.Config.PoolAPIallowedFailureCount)

If (-not $Request) { Return }

$Divisor = 1000000000

ForEach ($Algorithm in $Request.return) { 
    $AlgorithmNorm = Get-Algorithm $Algorithm.algo
    $Currency = "$($Algorithm.symbol)" -replace "\s+"

    # Add coin name
    If ($Algorithm.coin_name -and $Currency) { 
        Add-CoinName -Algorithm $AlgorithmNorm -Currency $Currency -CoinName $Algorithm.coin_name
    }

    # Temp fix
    $Regions = If ($Algorithm.host_list.split(";").count -eq 1) { @("n/a") } Else { $PoolConfig.Region }

    $Reasons = [System.Collections.Generic.Hashset[String]]::new()
    If (-not $PoolConfig.UserName) { $Reasons.Add("No username") | Out-Null }
    If ($Algorithm.pool_hash -eq "-" -or $_.pool_hash -eq "0" -and -not ($Session.Config.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { $Reasons.Add("No hashrate at pool") | Out-Null }
    If ($Session.PoolData.$Name.Algorithm -contains "-$AlgorithmNorm") { $Reasons.Add("Algorithm@Pool not supported by $($Session.Branding.ProductLabel)") | Out-Null }

    If ($AlgorithmNorm -eq "Equihash1445") { $Algorithm.host_list = "hub.miningpoolhub.com" }
    ElseIf ($Algorithm.host -eq "hub.miningpoolhub.com") { $Algorithm.host_list = $Algorithm.host }

    $Key = "$($PoolVariant)_$($AlgorithmNorm)-$($Currency)"
    $Value = $Algorithm.profit / $Divisor

    $Stat = Get-Stat -Name "$($Key)_Profit"
        If ($Stat.Live -and $Value -gt ($Stat.Live * $Session.Config.PoolAllowedPriceIncreaseFactor)) { 
        $Reasons.Add("Unrealistic price (price in pool API data is more than $($Session.Config.PoolAllowedPriceIncreaseFactor)x higher than previous price)") | Out-Null
    }
    Else { 
        $Stat = Set-Stat -Name "$($Key)_Profit" -Value $Value -FaultDetection $false
    }

    ForEach ($RegionNorm in $Session.Regions[$Session.Config.Region]) { 
        If ($Region = $Regions.Where({ $_ -eq "n/a" -or (Get-Region $_) -eq $RegionNorm })) { 

            If ($Region -eq "n/a") { $RegionNorm = $Region }

            [PSCustomObject]@{ 
                Accuracy                 = 1 - $Stat.Week_Fluctuation
                Algorithm                = $AlgorithmNorm
                Currency                 = $Currency
                Disabled                 = $Stat.Disabled
                EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                Fee                      = $Algorithm.Fee / 100
                Host                     = [String]($Algorithm.host_list.split(";") | Sort-Object -Descending { $_ -ilike "$Region*" } -Top 1)
                Key                      = $Key
                Name                     = $Name
                Pass                     = "x"
                Port                     = [UInt16]$Algorithm.port
                PortSSL                  = 0
                PoolUri                  = "https://$($Algorithm.coin_name).miningpoolhub.com"
                Price                    = $Stat.Live * (1 - [Math]::Min($Stat.Day_Fluctuation, 1)) + $Stat.Day * [Math]::Min($Stat.Day_Fluctuation, 1)
                Protocol                 = If ($AlgorithmNorm -match $Session.RegexAlgoIsEthash) { "ethstratumnh" } ElseIf ($AlgorithmNorm -match $Session.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                Reasons                  = $Reasons
                Region                   = $RegionNorm
                SendHashrate             = $false
                SSLselfSignedCertificate = $true
                StablePrice              = $Stat.Week
                Updated                  = [DateTime]$Stat.Updated
                User                     = "$($PoolConfig.UserName).$($PoolConfig.WorkerName)"
                Variant                  = $PoolVariant
                WorkerName               = $PoolConfig.WorkerName
                Workers                  = [UInt]$Algorithm.workers
            }
            Break
        }
    }
}

Write-Message -Level Debug "Pool '$PoolVariant': End"

$Error.Clear()
[System.GC]::Collect()