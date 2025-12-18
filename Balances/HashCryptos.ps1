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
Version:        6.7.11
Version date:   2025/12/18
#>

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

$PayoutCurrency = $Session.Config.Pools.$Name.PayoutCurrency
$PoolAPItimeout = $Session.Config.Pools.$Name.PoolAPItimeout
$RetryCount = $Session.Config.Pools.$Name.PoolAPIallowedFailureCount
$RetryInterval = $Session.Config.Pools.$Name.PoolAPIretryInterval
$Wallet = $Session.Config.Pools.$Name.Wallets.$PayoutCurrency

$Request = "https://www.hashcryptos.com/api/wallet/?address=$Wallet"

$Headers = @{ "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" }
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

while ($Wallet -and -not $APIresponse -and $RetryCount -gt 0) { 

    try { 
        $APIresponse = Invoke-RestMethod $Request -TimeoutSec $PoolAPItimeout -ErrorAction Ignore -Headers $Headers -UserAgent $UserAgent -SkipCertificateCheck

        if ($Session.Config.BalancesTrackerLogAPIResponse) { 
            "$([DateTime]::Now.ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $Request | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $APIresponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
        }

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
        elseif ($APIresponse.Message -like "Only 1 request *") { 
            Start-Sleep -Seconds $RetryInterval # Pool does not like immediate requests
        }
    }
    catch { 
        Start-Sleep -Seconds $RetryInterval # Pool does not like immediate requests
    }

    $RetryCount--
}

$Error.Clear()
[System.GC]::Collect()