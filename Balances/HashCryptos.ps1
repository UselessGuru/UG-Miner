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
File:           \Balances\HashCryptos.ps1
Version:        6.8.25
Version date:   2026/09/04
#>

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

$PayoutCurrency = $Config.PoolsConfig.$Name.PayoutCurrency
$PoolAPItimeout = $Config.PoolsConfig.$Name.PoolAPItimeout
$RetryCount = $Config.PoolsConfig.$Name.PoolAPIallowedFailureCount
$RetryInterval = $Config.PoolsConfig.$Name.PoolAPIretryInterval
$Wallet = $Config.PoolsConfig.$Name.Wallets.$PayoutCurrency

$Handler = [System.Net.Http.HttpClientHandler]::new()
$Handler.ServerCertificateCustomValidationCallback = [System.Net.Http.HttpClientHandler]::DangerousAcceptAnyServerCertificateValidator # Equivalent to -SkipCertificateCheck
$HttpClient = [System.Net.Http.HttpClient]::new($Handler)
$HttpClient.DefaultRequestHeaders.CacheControl = [System.Net.Http.Headers.CacheControlHeaderValue]::Parse("no-cache")
$HttpClient.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36")

while ($Wallet -and -not $APIresponse -and $RetryCount -gt 0) { 

    $Request = "https://www.hashcryptos.com/api/wallet/?address=$Wallet"

    try { 
        Write-Message -Level $DebugLevel "BalancesTracker '$Name': Querying $Request"
        $CancellationTokenSource = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($PoolAPItimeout))
        $Response = $HttpClient.GetAsync($Request, $CancellationTokenSource.Token).GetAwaiter().GetResult()
        # Read response as raw string
        $JSONstring = $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()

        if ($Session.Config.BalancesTrackerLogAPIResponse) { 
            "$([DateTime]::Now.ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            ($Request.Replace("$Wallet", "***Wallet***")) | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $APIresponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
        }
        if ($JSONstring -match "Only \d request every ") { 
            $WaitSeconds = [UInt16]($JSONstring -replace ".+Only \d request every " -replace " seconds allowed.+")
            Write-Message -Level $DebugLevel "Brain '$Name': Response '$JSONstring' from '$Request' received -> waiting $WaitSeconds seconds"
            Start-Sleep -Seconds ($WaitSeconds + 1) # Pool does not like immediate requests
            Remove-Variable WaitSeconds
        }
        else { 
            Write-Message -Level $DebugLevel "BalancesTracker '$Name': Response from '$Request' received"
        }

        if ($JSONstring -and (Test-Json $JSONstring -ErrorAction Ignore)) { 
            $APIresponse = $JSONstring | ConvertFrom-Json
            if ($APIresponse.symbol) { 
                return [PSCustomObject]@{ 
                    DateTime = [DateTime]::Now.ToUniversalTime()
                    Pool     = $Name
                    Currency = $APIresponse.symbol
                    Wallet   = $Wallet
                    Pending  = [Double]$APIresponse.unsold # Pending
                    Balance  = [Double]$APIresponse.balance
                    Unpaid   = [Double]$APIresponse.unpaid # Balance + unsold (pending)
                    # Paid     = [Double]$APIresponse.total # Reset after payout
                    # Total    = [Double]$APIresponse.unpaid + [Double]$APIresponse.total # Reset after payout
                    Url      = "https://hashcryptos.com/?address=$Wallet"
                }
            }
        }
    }
    catch { 
        Start-Sleep -Seconds $RetryInterval # Pool does not like immediate requests
    }

    $RetryCount--
}