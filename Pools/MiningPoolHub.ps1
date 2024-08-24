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
File:           \Pools\MiningPoolHub.ps1
Version:        6.2.28
Version date:   2024/08/24
#>

Param(
    [PSCustomObject]$Config,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$ProgressPreference = "SilentlyContinue"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

$PoolConfig = $Variables.PoolsConfig.$Name

$Headers = @{ "Cache-Control" = "no-cache" }
$Useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

Write-Message -Level Debug "Pool '$PoolVariant': Start"

$APICallFails = 0

Do { 
    Try { 
        $Request = Invoke-RestMethod -Uri "https://miningpoolhub.com/index.php?page=api&action=getminingandprofitsstatistics" -Headers $Headers -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPItimeout # -UserAgent $UserAgent 
    }
    Catch { 
        $APICallFails ++
        Start-Sleep -Seconds ($APICallFails * 5 + $PoolConfig.PoolAPIretryInterval)
    }
} While (-not $Request -and $APICallFails -lt $Config.PoolAPIallowedFailureCount)

If (-not $Request) { Return }

$Divisor = 1000000000

ForEach ($Pool in $Request.return) { 
    $AlgorithmNorm = Get-Algorithm $Pool.algo
    $Currency = "$($Pool.symbol)" -replace ' \s+'

    # Add coin name
    If ($Pool.coin_name -and $Currency) { 
        [Void](Add-CoinName -Algorithm $AlgorithmNorm -Currency $Currency -CoinName $Pool.coin_name)
    }

    # Temp fix
    $Regions = If ($Pool.host_list.split(";").count -eq 1) { @("n/a") } Else { $PoolConfig.Region }

    $Reasons = [System.Collections.Generic.List[String]]@()
    If (-not $PoolConfig.UserName) { $Reasons.Add("No username") }
    If ($Pool.pool_hash -eq "-" -or $_.pool_hash -eq "0" -and -not ($Config.PoolAllow0Hashrate -or $PoolConfig.PoolAllow0Hashrate)) { $Reasons.Add("No hashrate at pool") }
    If ($Pool.host -eq "hub.miningpoolhub.com") { $Pool.host_list = "hub.miningpoolhub.com" }

    $Key = "$($PoolVariant)_$($AlgorithmNorm)-$($Currency)"
    $Stat = Set-Stat -Name "$($Key)_Profit" -Value ($Pool.profit / $Divisor) -FaultDetection $false

    ForEach ($RegionNorm in $Variables.Regions[$Config.Region]) { 
        If ($Region = $Regions.Where({ $_ -eq "n/a" -or (Get-Region $_) -eq $RegionNorm })) { 

            If ($Region -eq "n/a") { $RegionNorm = $Region }

            [PSCustomObject]@{ 
                Accuracy                 = 1 - $Stat.Week_Fluctuation
                Algorithm                = $AlgorithmNorm
                Currency                 = $Currency
                Disabled                 = $Stat.Disabled
                EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                Fee                      = $Pool.Fee / 100
                Host                     = [String]($Pool.host_list.split(";") | Sort-Object -Descending { $_ -ilike "$Region*" } -Top 1)
                Key                      = $Key
                Name                     = $Name
                Pass                     = "x"
                Port                     = [UInt16]$Pool.port
                PortSSL                  = 0
                PoolUri                  = "https://$($Pool.coin_name).miningpoolhub.com"
                Price                    = $Stat.Live * (1 - [Math]::Min($Stat.Day_Fluctuation, 1)) + $Stat.Day * [Math]::Min($Stat.Day_Fluctuation, 1)
                Protocol                 = If ($AlgorithmNorm -match $Variables.RegexAlgoIsEthash) { "ethstratumnh" } ElseIf ($AlgorithmNorm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                Reasons                  = $Reasons
                Region                   = $RegionNorm
                SendHashrate             = $false
                SSLselfSignedCertificate = $true
                StablePrice              = $Stat.Week
                Updated                  = [DateTime]$Stat.Updated
                User                     = "$($PoolConfig.UserName).$($PoolConfig.WorkerName)"
                WorkerName               = $PoolConfig.WorkerName
                Workers                  = [UInt]$Pool.workers
                Variant                  = $PoolVariant
            }
            Break
        }
    }
}

Write-Message -Level Debug "Pool '$PoolVariant': End"

$Error.Clear()
[System.GC]::Collect()