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
Version:        6.5.2
Version date:   2025/07/27
#>

Class NBMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 # seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)/api/v1/status"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
            If ($null -eq $Data.miner.total_hashrate_raw) { Return $null }

            $Hashrate = [PSCustomObject]@{ }
            $HashrateName = [String]$this.Algorithms[0]
            $HashrateValue = [Double]$Data.miner.total_hashrate_raw
            $Hashrate | Add-Member @{ $HashrateName = [Double]$HashrateValue }

            $Shares = [PSCustomObject]@{ }
            $SharesAccepted = [Int64]$Data.stratum.accepted_shares
            $SharesRejected = [Int64]$Data.stratum.rejected_shares
            $SharesInvalid = [Int64]$Data.stratum.invalid_shares
            $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

            If ($Data.stratum.dual_mine) { 
                If ($null -eq $Data.miner.total_hashrate2_raw) { Return $null }
                $HashrateName = [String]($this.Algorithms -ne $HashrateName)
                $Hashrate | Add-Member @{ $HashrateName = [Double]$Data.miner.total_hashrate2_raw }

                $SharesAccepted = [Int64]$Data.stratum.accepted_shares2
                $SharesRejected = [Int64]$Data.stratum.rejected_shares2
                $SharesInvalid = [Int64]$Data.stratum.invalid_shares2
                $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
            }

            $PowerConsumption = [Double]0

            If ($this.ReadPowerConsumption) { 
                $PowerConsumption = [Double]($Data.miner | Measure-Object total_power_consume -Sum).Sum
                If (-not $PowerConsumption) { 
                    $PowerConsumption = $this.GetPowerConsumption()
                }
            }

            Return [PSCustomObject]@{ 
                Date             = [DateTime]::Now.ToUniversalTime()
                Hashrate         = $Hashrate
                PowerConsumption = $PowerConsumption
                Shares           = $Shares
            }
        }
        Catch { 
            Return $null
        }
    }
}