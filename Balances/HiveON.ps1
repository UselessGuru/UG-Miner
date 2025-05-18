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
File:           \Balances\HiveON.ps1
Version:        6.4.25
Version date:   2025/05/18
#>

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

$PoolConfig = $Config.PoolsConfig.$Name
$PoolConfig.Wallets.psBase.Keys.Where({ "ETC", "RVN" -contains $_ }).ForEach(
    { 
        $APIResponse = $null
        $Currency = $_.ToUpper()
        $Wallet = ($PoolConfig.Wallets.$_ -replace '^0x').ToLower()
        $RetryCount = $PoolConfig.PoolAPIAllowedFailureCount
        $RetryInterval = $PoolConfig.PoolAPIretryInterval

        $Request = "https://HiveON.net/api/v1/stats/miner/$Wallet/$Currency/billing-acc"

        While (-not $APIResponse -and $RetryCount -gt 0 -and $Wallet) { 

            Try { 
                $APIResponse = Invoke-RestMethod $Request -TimeoutSec $PoolConfig.PoolAPItimeout -ErrorAction Ignore

                If ($Config.LogBalanceAPIResponse) { 
                    "$([DateTime]::Now.ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                    $Request | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                    $APIResponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                }

                If ($APIResponse.earningStats) { 
                    [PSCustomObject]@{ 
                        DateTime = [DateTime]::Now.ToUniversalTime()
                        Pool     = $Name
                        Currency = $_
                        Wallet   = $Wallet
                        Pending  = [Double]0
                        Balance  = [Double]$APIResponse.totalUnpaid
                        Unpaid   = [Double]$APIResponse.totalUnpaid
                        # Paid     = [Double]$APIResponse.stats.totalPaid
                        # Total    = [Double]$APIResponse.stats.balance + [Decimal]$APIResponse.stats.penddingBalance
                        Url      = "https://HiveON.net/$($Currency.ToLower())?miner=$Wallet"
                    }
                }
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