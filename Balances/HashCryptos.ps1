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
File:           \Balances\HashCryptos.ps1
Version:        6.5.2
Version date:   2025/07/27
#>

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$PayoutCurrency = $Config.PoolsConfig.$Name.PayoutCurrency
$Wallet = $Config.PoolsConfig.$Name.Wallets.$PayoutCurrency
$RetryCount = $Config.PoolsConfig.$Name.PoolAPIallowedFailureCount
$RetryInterval = $Config.PoolsConfig.$Name.PoolAPIretryInterval

$Request = "https://www.hashcryptos.com/api/wallet/?address=$Wallet"

$Headers = @{ "Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" }
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

While (-not $APIResponse -and $RetryCount -gt 0 -and $Wallet) { 

    Try { 
        $APIResponse = Invoke-RestMethod $Request -TimeoutSec $Config.PoolAPItimeout -ErrorAction Ignore -Headers $Headers -UserAgent $UserAgent -SkipCertificateCheck

        If ($Config.LogBalanceAPIResponse) { 
            "$([DateTime]::Now.ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $Request | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $APIResponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
        }

        If ($APIResponse.symbol) { 
            Return [PSCustomObject]@{ 
                DateTime = [DateTime]::Now.ToUniversalTime()
                Pool     = $Name
                Currency = $APIResponse.symbol
                Wallet   = $Wallet
                Pending  = [Double]$APIResponse.unsold # Pending
                Balance  = [Double]$APIResponse.balance
                Unpaid   = [Double]$APIResponse.unpaid # Balance + unsold (pending)
                # Paid     = [Double]$APIResponse.total # Reset after payout
                # Total    = [Double]$APIResponse.unpaid + [Double]$APIResponse.total # Reset after payout
                Url      = "https://hashcryptos.com/?address=$Wallet"
            }
        }
    }
    Catch { 
        Start-Sleep -Seconds $RetryInterval # Pool might not like immediate requests
    }

    $RetryCount--
}

$Error.Clear()
[System.GC]::Collect()