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
Version:        6.9.0
Version date:   2026/10/24
#>

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

$Headers = @{ "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"; "Cache-Control" = "no-cache" }
$Useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

$PayoutCurrency = $Config.PoolsConfig.$Name.PayoutCurrency
$Wallet = $Config.PoolsConfig.$Name.Wallets.$PayoutCurrency

if ($Wallet) { 

    $URL = "https://www.hashcryptos.com/api/wallet/?address=$Wallet"

    Write-Message -Level Debug "Brain '$Name': Querying '$URL'"

    $APIallowedFailureCount = $Config.PoolsConfig.$Name.PoolAPIAllowedFailureCount
    do { 
        try { Remove-Variable APIerror -ErrorAction Ignore; $APIdata = Invoke-WebRequest -Uri $URL -TimeoutSec $Config.PoolsConfig.$Name.PoolAPItimeout -Headers $Headers -UserAgent $UserAgent -SkipCertificateCheck -ErrorAction Ignore -ErrorVariable APIerror 2>$null 3>$null 4>$null 5>$null 6>$null } catch { }
        $APIallowedFailureCount --
    } until ($APIdata.StatusCode -in @(200, 404) -or $APIerror.Message -eq "The response ended prematurely. (ResponseEnded)" -or $APIallowedFailureCount -eq 0)

    if ($APIerror) { 
        Write-Message -Level Error "BalancesTracker '$Name': Query to '$URL' failed ($($APIerror.Message))"
    }
    elseif ($APIdata.Content -and (Test-Json $APIdata.Content -ErrorAction Ignore)) { 
        if($BalanceInfo = $APIdata.Content | ConvertFrom-Json) {
            if ($BalanceInfo.symbol) { 
                return [PSCustomObject]@{ 
                    DateTime = [DateTime]::Now.ToUniversalTime()
                    Pool     = $Name
                    Currency = $BalanceInfo.symbol
                    Wallet   = $Wallet
                    Pending  = [Double]$BalanceInfo.unsold # Pending
                    Balance  = [Double]$BalanceInfo.balance
                    Unpaid   = [Double]$BalanceInfo.unpaid # Balance + unsold (pending)
                    # Paid     = [Double]$BalanceInfo.total # Reset after payout
                    # Total    = [Double]$BalanceInfo.unpaid + [Double]$BalanceInfo.total # Reset after payout
                    Url      = "https://hashcryptos.com/?address=$Wallet"
                }
            }
        }
    }
}