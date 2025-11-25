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
File:           \Balances\MiningDutch.ps1
Version:        6.7.1
Version date:   2025/11/25
#>

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

$PoolAPItimeout = $Session.Config.Pools.$Name.PoolAPItimeout
$RetryCount = $Session.Config.Pools.$Name.PoolAPIallowedFailureCount
$RetryInterval = $Session.Config.Pools.$Name.PoolAPIretryInterval

$Headers = @{ "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" }
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

while (-not $Currencies -and $RetryCount -gt 0 -and $Session.Config.MiningDutchUserName -and $Session.Config.MiningDutchAPIKey) { 

    try { 
        $APIResponse = Invoke-RestMethod "https://www.mining-dutch.nl/api/v1/public/pooldata/?method=poolstats&algorithm=all&id=$($Session.Config.MiningDutchUserName)" -UserAgent $UserAgent -Headers $Headers -TimeoutSec $PoolAPItimeout -ErrorAction Ignore

        if ($Session.Config.LogBalanceAPIResponse) { 
            "$([DateTime]::Now.ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $Request | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $APIResponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
        }

        if ($APIResponse.Message -like "Only 1 request *") { 
            Start-Sleep -Seconds $RetryInterval # Pool does not like immediate requests
        }
        elseif ($Currencies = ($APIResponse.result.Where({ $_.tag -and $_.tag -notlike "*_*" }) | Sort-Object -Property tag)) { 
            $Currencies.ForEach(
                { 
                    $Currency = $_.tag
                    $RetryCount = $Session.Config.Pools.$Name.PoolAPIallowedFailureCount

                    Start-Sleep -Seconds $RetryInterval # Pool does not support immediate requests

                    while (-not $APIResponse -and $RetryCount -gt 0) { 
                        try { 
                            $APIResponse = Invoke-RestMethod "https://www.mining-dutch.nl/pools/$($_.Currency.ToLower()).php?page=api&action=getuserbalance&api_key=$($Session.Config.MiningDutchAPIKey)" -UserAgent $UserAgent -Headers $Headers -TimeoutSec $PoolAPItimeout -ErrorAction Ignore

                            if ($Session.Config.LogBalanceAPIResponse) { 
                                "$([DateTime]::Now.ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                                $Request | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                                $APIResponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                            }

                            if ($APIResponse.Message -like "Only 1 request *") { 
                                Start-Sleep -Seconds $RetryInterval # Pool does not like immediate requests
                            }
                            elseif ($APIResponse.getuserbalance.data) { 

                                $Unpaid = [Double]$APIResponse.getuserbalance.data.confirmed + [Double]$APIResponse.getuserbalance.data.unconfirmed
                                if ($Unpaid -gt 0) { 
                                    [PSCustomObject]@{ 
                                        DateTime = [DateTime]::Now.ToUniversalTime()
                                        Pool     = $Name
                                        Currency = $Currency
                                        Wallet   = $Session.Config.MiningDutchUserName
                                        Pending  = [Double]$APIResponse.getuserbalance.data.unconfirmed
                                        Balance  = [Double]$APIResponse.getuserbalance.data.confirmed
                                        Unpaid   = $Unpaid
                                        Url      = "https://www.mining-dutch.nl/index.php?page=earnings"
                                    }
                                }
                            }
                        }
                        catch { 
                        }
                        $RetryCount--
                    }
                }
            )
        }
        else { 
            Start-Sleep -Seconds $RetryInterval # Pool does not support immediate requests
        }
    }
    catch { 
        Start-Sleep -Seconds $RetryInterval # Pool does not support immediate requests
    }
    $RetryCount--
}

$Error.Clear()
[System.GC]::Collect()