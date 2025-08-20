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
File:           \Includes\MinerAPIs\SRBminer.ps1
Version:        6.5.7
Version date:   2025/08/20
#>

Class SRBMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 # seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
            If (-not $Data) { Return $null }

            $Type = If ($Data.total_cpu_workers -gt 0) { "cpu" } Else { "gpu" }

            If (-not $Data.algorithms -or $null -eq $Data.algorithms[0].hashrate.$Type.total) { Return $null }

            $Hashrate = [PSCustomObject]@{ }
            $HashrateName = [String]$this.algorithms[0]
            $HashrateValue = [Double]$Data.algorithms[0].hashrate.$Type.total
            $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

            $Shares = [PSCustomObject]@{ }
            $SharesAccepted = [Int64]$Data.algorithms[0].shares.accepted
            $SharesRejected = [Int64]$Data.algorithms[0].shares.rejected
            $SharesInvalid = [Int64]0
            $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

            If ($HashrateName = [String]($this.Algorithms -ne $HashrateName)) { 
                $HashrateValue = [Double]$Data.algorithms[1].hashrate.$Type.total

                $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

                $SharesAccepted = [Int64]$Data.algorithms[1].shares.accepted
                $SharesRejected = [Int64]$Data.algorithms[1].shares.rejected 
                $SharesInvalid = [Int64]0
                $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
            }

            $PowerConsumption = [Double]0

            If ($this.ReadPowerConsumption) { 
                $PowerConsumption = [Double]($Data.gpu_devices | Measure-Object asic_power -Sum).Sum
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