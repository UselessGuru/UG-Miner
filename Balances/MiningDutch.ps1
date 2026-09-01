<#
Copyright (c) 2018-2026 UselessGuru

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
Version:        6.8.24
Version date:   2026/09/01
#>

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$DebugLevel = "Debug"

$Handler = [System.Net.Http.HttpClientHandler]::new()
$Handler.ServerCertificateCustomValidationCallback = [System.Net.Http.HttpClientHandler]::DangerousAcceptAnyServerCertificateValidator # Equivalent to -SkipCertificateCheck
$HttpClient = [System.Net.Http.HttpClient]::new($Handler)
$HttpClient.DefaultRequestHeaders.CacheControl = [System.Net.Http.Headers.CacheControlHeaderValue]::Parse("no-cache")
$HttpClient.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36")

$PoolAPIallowedFailureCount = $Config.PoolsConfig.$Name.PoolAPIallowedFailureCount
$PoolAPItimeout = $Config.PoolsConfig.$Name.PoolAPItimeout

while (-not $Currencies -and $PoolAPIallowedFailureCount -gt 0 -and $Config.MiningDutchUserName -and $Config.MiningDutchAPIKey) { 

    try { 
        $Request = "https://www.mining-dutch.nl/api/v1/public/pooldata/?method=poolstats&algorithm=all&id=$($Config.MiningDutchUserName)"
        Write-Message -Level $DebugLevel "BalancesTracker '$Name': Querying $Request"
        $CancellationTokenSource = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($PoolAPItimeout))
        $Response = $HttpClient.GetAsync($Request, $CancellationTokenSource.Token).GetAwaiter().GetResult()
        # Read response as raw string
        $JSONstring = $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()

        $Session."$($Name)APIrequestTimestamp" = [DateTime]::Now.ToUniversalTime()
        Write-Message -Level $DebugLevel "BalancesTracker '$Name': Response from 'https://www.mining-dutch.nl/api/v1/public/pooldata' received"

        if ($Config.BalancesTrackerLogAPIResponse) { 
            "$([DateTime]::Now.ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $Request | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $JSONstring | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
        }
        if ($JSONstring -and (Test-Json $JSONstring -ErrorAction Ignore)) { $APIresponse = $JSONstring | ConvertFrom-Json } else { $APIresponse = $null }

        if ($Currencies = ($APIresponse.result.Where{ $_.tag -and $_.tag -notlike "*_*" -and $_.status -ne "merged" } | Sort-Object -Property tag)) { 
            $Currencies.ForEach{ 
                $APIresponse = $null
                $Currency = $_.tag
                if ($Currency -eq "SKY") { $Currency = "SKYDOGE" }
                $PoolAPIallowedFailureCount = $Session.Config.PoolsConfig.$Name.PoolAPIallowedFailureCount

                while (-not $APIresponse -and $PoolAPIallowedFailureCount -gt 0) { 
                    try { 
                        $Request = "https://www.mining-dutch.nl/pools/$($_.Currency.ToLower()).php?page=api&action=getuserbalance&api_key=$($Config.MiningDutchAPIKey)"
                        Write-Message -Level $DebugLevel "BalancesTracker '$Name': Querying $($Request.Replace("$($Config.MiningDutchAPIKey)", "***MiningDutchAPIKey***"))"
                        $Session."$($Name)APIrequestTimestamp" = [DateTime]::Now.ToUniversalTime()
                        $CancellationTokenSource = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($PoolAPItimeout))
                        $Response = $HttpClient.GetAsync($Request, $CancellationTokenSource.Token).GetAwaiter().GetResult()
                        # Read response as raw string
                        $JSONstring = $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()

                        if ($Config.BalancesTrackerLogAPIResponse) { 
                            "$([DateTime]::Now.ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                            ($Request.replace("$($Config.MiningDutchAPIKey)", "***MiningDutchAPIKey***")) | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                            $JSONstring | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                        }

                        if ($JSONstring -match "Only \d request every ") { 
                            $WaitSeconds = [UInt16]($JSONstring -replace ".+Only \d request every " -replace " seconds allowed.+")
                            Write-Message -Level $DebugLevel "Brain '$Name': Response '$JSONstring' from '$Request' received -> waiting $WaitSeconds seconds"
                            Start-Sleep -Seconds ($WaitSeconds + 1) # Pool does not like immediate requests
                            Remove-Variable WaitSeconds
                        }
                        else { 
                            Write-Message -Level $DebugLevel "BalancesTracker '$Name': Response from '$($Request.Replace("$($Config.MiningDutchAPIKey)", "***MiningDutchAPIKey***"))' received"
                        }

                        if ($JSONstring -and (Test-Json $JSONstring -ErrorAction Ignore)) { 
                            $APIresponse = $JSONstring | ConvertFrom-Json

                            if ($APIresponse.getuserbalance.data) { 
                                $Unpaid = [Double]$APIresponse.getuserbalance.data.confirmed + [Double]$APIresponse.getuserbalance.data.unconfirmed
                                if ($Unpaid -gt 0) { 
                                    [PSCustomObject]@{ 
                                        DateTime = [DateTime]::Now.ToUniversalTime()
                                        Pool     = $Name
                                        Currency = $Currency
                                        Wallet   = $Config.MiningDutchUserName
                                        Pending  = [Double]$APIresponse.getuserbalance.data.unconfirmed
                                        Balance  = [Double]$APIresponse.getuserbalance.data.confirmed
                                        Unpaid   = $Unpaid
                                        Url      = "https://www.mining-dutch.nl/index.php?page=wallets"
                                    }
                                }
                                Remove-Variable Unpaid
                            }
                        }
                    }
                    catch { 
                        Start-Sleep 0
                    }
                    $PoolAPIallowedFailureCount--
                }
            }
        }
    }
    catch { 
        Start-Sleep -Seconds $Session.Config.PoolsConfig.$Name.PoolAPIretryInterval # Pool does not support immediate requests
    }
    $PoolAPIallowedFailureCount--
}