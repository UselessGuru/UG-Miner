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
File:           \Includes\MinerAPIs\Trex.ps1
Version:        6.6.4
Version date:   2025/11/17
#>

Class Trex : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 # seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)/summary"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
            If (-not $Data) { Return $null }

            $Hashrate = [PSCustomObject]@{ }
            $HashrateName = [String]$this.Algorithms[0]
            $HashrateValue = $Data.hashrate_minute
            If (-not $Data.hashrate_minute) { $HashrateValue = $Data.hashrate }
            If ($null -eq $HashrateValue) { Return $null }
            $Hashrate | Add-Member @{ $HashrateName = [Double]$HashrateValue }

            $Shares = [PSCustomObject]@{ }
            $SharesAccepted = [Int64]$Data.accepted_count
            $SharesRejected = [Int64]$Data.rejected_count
            $SharesInvalid = [Int64]0
            $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

            If ($HashrateName = [String]($this.Algorithms -ne $HashrateName)) { 
                $HashrateValue = $Data.dual_stat.hashrate_minute
                If (-not $HashrateValue) { $HashrateValue = $Data.dual_stat.hashrate }
                If ($null -eq $HashrateValue) { Return $null }
                $Hashrate | Add-Member @{ $HashrateName = [Double]$HashrateValue }

                $SharesAccepted = [Int64]$Data.dual_stat.accepted_count
                $SharesRejected = [Int64]$Data.dual_stat.rejected_count
                $SharesInvalid = [Int64]0
                $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
            }

            $PowerConsumption = [Double]0

            If ($this.ReadPowerConsumption) { 
                $PowerConsumption = [Double]($Data.gpus | Measure-Object power -Sum).Sum
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