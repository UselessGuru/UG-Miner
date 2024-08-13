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
File:           \Includes\MinerAPIs\NBMiner.ps1
Version:        6.2.25
Version date:   2024/08/13
#>

Class NBMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)/api/v1/status"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $HashRate = [PSCustomObject]@{ }
        $HashRateName = [String]$this.Algorithms[0]
        $HashRateValue = [Double]$Data.miner.total_hashrate_raw
        $HashRate | Add-Member @{ $HashRateName = [Double]$HashRateValue }

        $Shares = [PSCustomObject]@{ }
        $SharesAccepted = [Int64]$Data.stratum.accepted_shares
        $SharesRejected = [Int64]$Data.stratum.rejected_shares
        $SharesInvalid = [Int64]$Data.stratum.invalid_shares
        $Shares | Add-Member @{ $HashRateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

        If ($Data.stratum.dual_mine) { 
            $HashRateName = [String]($this.Algorithms -ne $HashRateName)
            $HashRate | Add-Member @{ $HashRateName = [Double]$Data.miner.total_hashrate2_raw }

            $SharesAccepted = [Int64]$Data.stratum.accepted_shares2
            $SharesRejected = [Int64]$Data.stratum.rejected_shares2
            $SharesInvalid = [Int64]$Data.stratum.invalid_shares2
            $Shares | Add-Member @{ $HashRateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
        }

        $PowerConsumption = [Double]0

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            If ($this.ReadPowerConsumption) { 
                $PowerConsumption = [Double]($Data.miner | Measure-Object total_power_consume -Sum).Sum
                If (-not $PowerConsumption) { 
                    $PowerConsumption = $this.GetPowerConsumption()
                }
            }

            Return [PSCustomObject]@{ 
                Date             = [DateTime]::Now.ToUniversalTime()
                HashRate         = $HashRate
                PowerConsumption = $PowerConsumption
                Shares           = $Shares
            }
        }
        Return $null
    }
}