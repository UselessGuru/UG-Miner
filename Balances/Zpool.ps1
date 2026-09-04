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
File:           \Balances\Zpool.ps1
Version:        6.8.25
Version date:   2026/09/04
#>

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

$Handler = [System.Net.Http.HttpClientHandler]::new()
$Handler.ServerCertificateCustomValidationCallback = [System.Net.Http.HttpClientHandler]::DangerousAcceptAnyServerCertificateValidator # Equivalent to -SkipCertificateCheck
$HttpClient = [System.Net.Http.HttpClient]::new($Handler)
$HttpClient.DefaultRequestHeaders.CacheControl = [System.Net.Http.Headers.CacheControlHeaderValue]::Parse("no-cache")

$RetryInterval = $Config.PoolsConfig.$Name.PoolAPIretryInterval

$Config.PoolsConfig.$Name.Wallets.Keys.ForEach{ 
    $Currency = $_
    $Wallet = $Config.PoolsConfig.$Name.Wallets.$Currency

    $RetryCount = $Config.PoolsConfig.$Name.PoolAPIallowedFailureCount
    $Request = "https://zpool.ca/api/wallet?address=$Wallet"

    while (-not $APIResponse -and $RetryCount -gt 0 -and $Wallet) { 

        try { 
            $CancellationTokenSource = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($Config.PoolsConfig.$Name.PoolAPItimeout))
            $Response = $HttpClient.GetAsync($Request, $CancellationTokenSource.Token).GetAwaiter().GetResult()
            $CancellationTokenSource.Dispose()
            Remove-Variable CancellationTokenSource

            # Read response as raw string
            $JSONstring = $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()

            $Session."$($Name)APIrequestTimestamp" = [DateTime]::Now.ToUniversalTime()
            Write-Message -Level $DebugLevel "BalancesTracker '$Name': Response from '$Request' received"

            if ($Config.BalancesTrackerLogAPIResponse) { 
                "$([DateTime]::Now.ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                ($Request.Replace("$Wallet", "***Wallet***")) | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                $JSONstring | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            }

            if ($JSONstring -and (Test-Json $JSONstring -ErrorAction Ignore)) { 
                $APIresponse = $JSONstring | ConvertFrom-Json

                if ($APIResponse.currency -and $APIResponse.currency -ne "INVALID" -and ($APIResponse.unsold -or $APIResponse.balance -or $APIResponse.unpaid)) { 
                    [PSCustomObject]@{ 
                        DateTime = [DateTime]::Now.ToUniversalTime()
                        Pool     = $Name
                        Currency = $APIResponse.currency
                        Wallet   = $Wallet
                        Pending  = [Double]$APIResponse.unsold # Pending
                        Balance  = [Double]$APIResponse.balance
                        Unpaid   = [Double]$APIResponse.unpaid # Balance + unsold (pending)
                        # Paid     = [Double]$APIResponse.total # Reset after payout
                        # Total    = [Double]$APIResponse.unpaid + [Double]$APIResponse.total # Reset after payout
                        Url      = "https://zpool.ca/wallet/$Wallet"
                    }
                }
            }
            $APIResponse = $null
            $RetryCount = 0
        }
        catch { 
            Start-Sleep -Seconds $RetryInterval # Pool might not like immediate requests
            $RetryCount--
        }
    }
}