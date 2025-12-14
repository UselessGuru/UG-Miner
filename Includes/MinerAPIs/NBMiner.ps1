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
File:           \Includes\MinerAPIs\NBMiner.ps1
Version:        6.7.8
Version date:   2025/12/14
#>

[NoRunspaceAffinity()]
class NBMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 # seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)/api/v1/status"

        try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
            if ($null -eq $Data.miner.total_hashrate_raw) { return $null }

            $Hashrate = [PSCustomObject]@{ }
            $HashrateName = [String]$this.Algorithms[0]
            $HashrateValue = [Double]$Data.miner.total_hashrate_raw
            $Hashrate | Add-Member @{ $HashrateName = [Double]$HashrateValue }

            $Shares = [PSCustomObject]@{ }
            $SharesAccepted = [Int64]$Data.stratum.accepted_shares
            $SharesRejected = [Int64]$Data.stratum.rejected_shares
            $SharesInvalid = [Int64]$Data.stratum.invalid_shares
            $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

            if ($Data.stratum.dual_mine) { 
                if ($null -eq $Data.miner.total_hashrate2_raw) { return $null }
                $HashrateName = [String]($this.Algorithms -ne $HashrateName)
                $Hashrate | Add-Member @{ $HashrateName = [Double]$Data.miner.total_hashrate2_raw }

                $SharesAccepted = [Int64]$Data.stratum.accepted_shares2
                $SharesRejected = [Int64]$Data.stratum.rejected_shares2
                $SharesInvalid = [Int64]$Data.stratum.invalid_shares2
                $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
            }

            $PowerConsumption = [Double]0

            if ($this.ReadPowerConsumption) { 
                $PowerConsumption = [Double]($Data.miner | Measure-Object total_power_consume -Sum).Sum
                if (-not $PowerConsumption -or $PowerConsumption -gt 1000 -or $PowerConsumption -lt 0) { 
                    $PowerConsumption = $this.GetPowerConsumption()
                }
            }

            return [PSCustomObject]@{ 
                Date             = [DateTime]::Now.ToUniversalTime()
                Hashrate         = $Hashrate
                PowerConsumption = $PowerConsumption
                Shares           = $Shares
            }
        }
        catch { 
            return $null
        }
    }
}