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
File:           \Balances\ProHashing.ps1
Version:        6.6.6
Version date:   2025/11/19
#>

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Url = "https://prohashing.com/customer/dashboard"

$RetryCount = $Session.Config.Pools.$Name.PoolAPIallowedFailureCount
$RetryInterval = $Session.Config.Pools.$Name.PoolAPIretryInterval

$Request = "https://prohashing.com/api/v1/wallet?apiKey=$($Session.Config.ProHashingAPIkey)"

While (-not $APIResponse -and $RetryCount -gt 0 -and $Session.Config.ProHashingAPIkey) { 

    Try { 
        $APIResponse = Invoke-RestMethod $Request -TimeoutSec $Session.Config.PoolAPItimeout -ErrorAction Ignore

        If ($Session.Config.LogBalanceAPIResponse) { 
            "$([DateTime]::Now.ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $Request | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $APIResponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
        }

        If ($APIResponse.status -eq "success") { 
            If ($APIResponse.data.balances.PSObject.Properties.Name) { 
               $APIResponse.data.balances.PSObject.Properties.Name.ForEach(
                    { 
                        [PSCustomObject]@{ 
                            DateTime = [DateTime]::Now.ToUniversalTime()
                            Pool            = $Name
                            Currency        = $APIResponse.data.balances.$_.abbreviation
                            Wallet          = $Session.Config.ProHashingUserName
                            Pending         = 0
                            Balance         = [Double]$APIResponse.data.balances.$_.balance
                            Unpaid          = [Double]$APIResponse.data.balances.$_.unpaid
                            Paid            = [Double]$APIResponse.data.balances.$_.paid24h
                            PayoutThreshold = [Double]$APIResponse.data.balances.$_.payoutThreshold
                            # Total           = [Double]$APIResponse.data.balances.$_.total # total unpaid + total paid, reset after payout
                            Url             = $Url
                        }
                    }
                )
            }
            Else { 
                # Remove non present (paid) balances
                $Session.BalancesData = $Session.BalancesData.Where({ $_.Pool -ne $Name })
            }
        }
    }
    Catch { 
        Start-Sleep -Seconds $Retryinterval # Pool might not like immediate requests
    }

    $RetryCount--
}

$Error.Clear()
[System.GC]::Collect()