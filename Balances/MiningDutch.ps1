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
Version:        6.7.4
Version date:   2025/12/06
#>

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

$PoolAPItimeout = $Session.Config.Pools.$Name.PoolAPItimeout
$RetryCount = $Session.Config.Pools.$Name.PoolAPIallowedFailureCount
$RetryInterval = $Session.Config.Pools.$Name.PoolAPIretryInterval

$Headers = @{ "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" }
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

while (-not $Currencies -and $RetryCount -gt 0 -and $Session.Config.MiningDutchUserName -and $Session.Config.MiningDutchAPIKey) { 

    try { 
        # Get mutex. Mutexes are shared across all threads and processes.
        # This lets us ensure only one thread is trying to query the pool API
        # $Mutex = [System.Threading.Mutex]::new($false, "$($Session.Branding.ProductLabel)_MiningDutchPoolAPI")
        # Attempt to aquire mutex
        # if ($Mutex.WaitOne($RetryInterval * 2000)) { 
            # if ($Session."$($Name)APIrequestTimestamp" -and [DateTime]::Now.ToUniversalTime() -lt $Session."$($Name)APIrequestTimestamp".AddSeconds($RetryInterval)) { 
            #     Start-Sleep -Seconds ($Session."$($Name)APIrequestTimestamp".AddSeconds($RetryInterval) - [DateTime]::Now.ToUniversalTime()).TotalSeconds
            # }
            $Session."$($Name)APIrequestTimestamp" = [DateTime]::Now.ToUniversalTime()
            $Request = "https://www.mining-dutch.nl/api/v1/public/pooldata/?method=poolstats&algorithm=all&id=$($Session.Config.MiningDutchUserName)"
            Write-Message -Level Debug "BalancesTracker '$Name': Querying https://www.mining-dutch.nl/api/v1/public/pooldata/?method=poolstats&algorithm=all&id=$($Session.Config.MiningDutchUserName)"
            $APIresponse = Invoke-RestMethod $Request -UserAgent $UserAgent -Headers $Headers -TimeoutSec $PoolAPItimeout -ErrorAction Ignore
            Write-Message -Level Debug "BalancesTracker '$Name': Response from https://www.mining-dutch.nl/api/status received"
            # $Mutex.ReleaseMutex()
        # }
        # Remove-Variable Mutex

        if ($Session.Config.BalancesTrackerLogAPIResponse) { 
            "$([DateTime]::Now.ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $Request | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $APIresponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
        }

        if ($Currencies = ($APIresponse.result.where({ $_.tag -and $_.tag -notlike "*_*" -and $_.status -ne "merged" }) | Sort-Object -Property tag)) { 
            $Currencies.ForEach(
                { 
                    $Currency = $_.tag
                    $RetryCount = $Session.Config.Pools.$Name.PoolAPIallowedFailureCount
                    $APIresponse = $null

                    while (-not $APIresponse -and $RetryCount -gt 0) { 
                        try { 
                            # Get mutex. Mutexes are shared across all threads and processes.
                            # This lets us ensure only one thread is trying to query the pool API
                            # $Mutex = [System.Threading.Mutex]::new($false, "$($Session.Branding.ProductLabel)_MiningDutchPoolAPI")
                            # Attempt to aquire mutex
                            # if ($Mutex.WaitOne($RetryInterval * 2000)) { 
                                # if ($Session."$($Name)APIrequestTimestamp" -and [DateTime]::Now.ToUniversalTime() -lt $Session."$($Name)APIrequestTimestamp".AddSeconds($RetryInterval)) { 
                                #     Start-Sleep -Seconds ($Session."$($Name)APIrequestTimestamp".AddSeconds($RetryInterval) - [DateTime]::Now.ToUniversalTime()).TotalSeconds
                                # }
                                $Session."$($Name)APIrequestTimestamp" = [DateTime]::Now.ToUniversalTime()
                                $Request = "https://www.mining-dutch.nl/pools/$($_.Currency.ToLower()).php?page=api&action=getuserbalance&api_key=$($Session.Config.MiningDutchAPIKey)"
                                Write-Message -Level Debug "BalancesTracker '$Name': Querying https://www.mining-dutch.nl/pools/$($_.Currency.ToLower()).php?page=api&action=getuserbalance&api_key=$($Session.Config.MiningDutchAPIKey)"
                                $APIresponse = Invoke-RestMethod $Request -UserAgent $UserAgent -Headers $Headers -TimeoutSec $PoolAPItimeout -ErrorAction Ignore
                                Write-Message -Level Debug "BalancesTracker '$Name': Response from https://www.mining-dutch.nl/pools/$($_.Currency.ToLower()).php?page=api&action=getuserbalance&api_key=$($Session.Config.MiningDutchAPIKey) received"
                                # $Mutex.ReleaseMutex()
                            # }
                            # Remove-Variable Mutex

                            if ($Session.Config.BalancesTrackerLogAPIResponse) { 
                                "$([DateTime]::Now.ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                                $Request | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                                $APIresponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                            }

                            if ($APIresponse.getuserbalance.data) { 
                                $Unpaid = [Double]$APIresponse.getuserbalance.data.confirmed + [Double]$APIresponse.getuserbalance.data.unconfirmed
                                if ($Unpaid -gt 0) { 
                                    [PSCustomObject]@{ 
                                        DateTime = [DateTime]::Now.ToUniversalTime()
                                        Pool     = $Name
                                        Currency = $Currency
                                        Wallet   = $Session.Config.MiningDutchUserName
                                        Pending  = [Double]$APIresponse.getuserbalance.data.unconfirmed
                                        Balance  = [Double]$APIresponse.getuserbalance.data.confirmed
                                        Unpaid   = $Unpaid
                                        Url      = "https://www.mining-dutch.nl/index.php?page=earnings"
                                    }
                                }
                                Remove-Variable Unpaid
                            }
                        }
                        catch { 
                            Start-Sleep 0
                        }
                        $RetryCount--
                    }
                }
            )
        }
    }
    catch { 
        Start-Sleep -Seconds $RetryInterval # Pool does not support immediate requests
    }
    $RetryCount--
}

$Error.Clear()
[System.GC]::Collect()