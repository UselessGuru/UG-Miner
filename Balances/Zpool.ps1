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
File:           \Balances\Zpool.ps1
Version:        6.3.4
Version date:   2024/09/13
#>

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$RetryInterval = $Config.PoolsConfig.$Name.PoolAPIretryInterval

$Config.PoolsConfig.$Name.Wallets.Keys.ForEach(
    { 
        $Currency = $_
        $Wallet = $Config.PoolsConfig.$Name.Wallets.$Currency

        $RetryCount = $Config.PoolsConfig.$Name.PoolAPIAllowedFailureCount
        $Request = "https://zpool.ca/api/wallet?address=$Wallet"

        While (-not $APIResponse -and $RetryCount -gt 0 -and $Wallet) { 

            Try { 
                $APIResponse = Invoke-RestMethod $Request -TimeoutSec $Config.PoolAPItimeout -ErrorAction Ignore

                If ($Config.LogBalanceAPIResponse) { 
                    "$([DateTime]::Now.ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                    $Request | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                    $APIResponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                }

                If ($APIResponse.currency -ne "INVALID" -and $APIResponse.currency -and ($APIResponse.unsold -or $APIResponse.balance -or $APIResponse.unpaid)) { 
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
                $APIResponse = $null
                $RetryCount = 0
            }
            Catch { 
                Start-Sleep -Seconds $RetryInterval # Pool might not like immediate requests
            }

            $RetryCount--
        }
    }
)

$Error.Clear()
[System.GC]::Collect()