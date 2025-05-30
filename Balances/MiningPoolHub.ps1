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
File:           \Balances\MiningPoolHub.ps1
Version:        6.4.28
Version date:   2025/02/23
#>

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

$RetryInterval = $Config.PoolsConfig.$Name.PoolAPIretryInterval
$PoolAPItimeout = $Config.PoolsConfig.$Name.PoolAPItimeout
$RetryCount = $Config.PoolsConfig.$Name.PoolAPIretryInterval

$Headers = @{ "Cache-Control" = "no-cache" }
$Useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

While (-not $UserAllBalances -and $RetryCount -gt 0 -and $Config.MiningPoolHubAPIKey) { 
    Try { 
        $Url = "https://miningpoolhub.com/"
        $WebResponse = Invoke-WebRequest -Uri $Url -TimeoutSec $PoolAPItimeout -ErrorAction Ignore

        # PWSH 6+ no longer supports basic parsing -> parse text
        $CoinList = [System.Collections.Generic.HashSet[PSCustomObject]]@()
        $InCoinList = $false

        If ($WebResponse.statuscode -eq 200) { 
            ($WebResponse.Content -split "\n" -replace ' \s+' -replace ' $').ForEach(
                { 
                    If ($_ -like '<table id="coinList"*>') { 
                        $InCoinList = $true
                    }
                    If ($InCoinList) { 
                        If ($_ -like '</table>') { Return }
                        If ($_ -like '<td align="left"><a href="*') { 
                            $CoinList.Add($_ -replace '<td align="left"><a href="' -replace '" target="_blank">.+' -replace '^//' -replace '.miningpoolhub.com') | Out-Null
                        }
                    }
                }
            )
        }

        $UserAllBalances = (((Invoke-RestMethod "http://miningpoolhub.com/index.php?page=api&action=getuserallbalances&api_key=$($Config.MiningPoolHubAPIKey)" -Headers $Headers -TimeoutSec $PoolAPItimeout -ErrorAction Ignore).getuserallbalances).data).Where({ $_.confirmed -gt 0 -or $_.unconfirmed -gt 0 })

        If ($Config.LogBalanceAPIResponse) { 
            "$([DateTime]::Now.ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $Request | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $UserAllBalances | ConvertTo-Json -Depth 10 >> ".\Logs\BalanceAPIResponse_$Name.json"
        }

        If ($CoinList -and $UserAllBalances) { 
            ($CoinList | Sort-Object).ForEach(
                { 
                    $CoinBalance = $null
                    $RetryCount2 = $Config.PoolsConfig.$Name.PoolAPIretryInterval

                    While (-not ($CoinBalance) -and $RetryCount2 -gt 0) { 
                        $RetryCount2--
                        Try { 
                            $CoinBalance = ((Invoke-RestMethod "http://$($_).miningpoolhub.com/index.php?page=api&action=getuserbalance&api_key=$($Config.MiningPoolHubAPIKey)" -Headers $Headers -UserAgent $UserAgent -TimeoutSec $PoolAPItimeout -ErrorAction Ignore).getuserbalance).data
                            If ($Config.LogBalanceAPIResponse) { 
                                $APIResponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\CoinBalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                            }
                        }
                        Catch { 
                            Start-Sleep -Seconds $RetryInterval # Pool might not like immediate requests
                        }
                    }

                    If ($Balance = $UserAllBalances.Where({ $_.confirmed -eq $CoinBalance.confirmed -and $_.unconfirmed -eq $CoinBalance.unconfirmed })) { 
                        $Currency = ""
                        $RetryCount2 = $Config.PoolsConfig.$Name.PoolAPIretryInterval
                        $PoolInfo = $null

                        While (-not ($PoolInfo) -and $RetryCount2 -gt 0) { 
                            $RetryCount2--
                            Try { 
                                $PoolInfo = ((Invoke-RestMethod "http://$($_).miningpoolhub.com/index.php?page=api&action=getpoolinfo&api_key=$($Config.MiningPoolHubAPIKey)" -Headers $Headers -UserAgent $UserAgent -TimeoutSec $PoolAPItimeout -ErrorAction Ignore).getpoolinfo).data
                                If ($Config.LogBalanceAPIResponse) { 
                                    $APIResponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                                }
                                $Currency = $PoolInfo.currency
                            }
                            Catch { 
                                Start-Sleep -Seconds $RetryInterval # Pool might not like immediate requests
                            }
                        }

                        If ($Currency) { 
                            # Prefer custom payout threshold
                            $PayoutThreshold = $Config.PoolsConfig.$Name.PayoutThreshold.$Currency

                            If ((-not $PayoutThreshold) -and $Currency -eq "BTC" -and $Config.PoolsConfig.$Name.PayoutThreshold.mBTC) { $PayoutThreshold = $Config.PoolsConfig.$Name.PayoutThreshold.mBTC / 1000 }
                            If (-not $PayoutThreshold) { $PayoutThreshold = $PoolInfo.min_ap_threshold }

                            [PSCustomObject]@{ 
                                DateTime        = [DateTime]::Now.ToUniversalTime()
                                Pool            = $Name
                                Currency        = $Currency
                                Wallet          = $Config.MiningPoolHubUserName
                                Pending         = [Double]$CoinBalance.unconfirmed
                                Balance         = [Double]$CoinBalance.confirmed
                                Unpaid          = [Double]($CoinBalance.confirmed + $CoinBalance.unconfirmed)
                                # Total           = [Double]($CoinBalance.confirmed + $CoinBalance.unconfirmed + $CoinBalance.ae_confirmed + $CoinBalance.ae_unconfirmed + $CoinBalance.exchange)
                                PayoutThreshold = [Double]$PayoutThreshold
                                Url             = "https://$($_).miningpoolhub.com/index.php?page=account&action=pooledit"
                            }
                        }
                        Else { 
                            Write-Message -Level Warn "$($Name): Cannot determine balance for currency '$(If ($_) { $_ } Else { "unknown" })' - cannot convert some balances to BTC or other currencies."
                        }
                    }
                }
            )
        }
    }
    Catch { 
        Start-Sleep -Seconds $RetryInterval # Pool might not like immediate requests
    }

    $RetryCount--
}

$Error.Clear()
[System.GC]::Collect()