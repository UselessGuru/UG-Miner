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
File:           \Includes\MinerAPIs\GMiner.ps1
Version:        6.4.15
Version date:   2025/03/09
#>

Class GMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)/stat"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        If (-not $Data.devices) { Return $null }

        $Hashrate = [PSCustomObject]@{ }
        $HashrateName = [String]$this.Algorithms[0]
        $HashrateValue = [Double]($Data.devices.speed | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
        If (-not $HashRateValue -and $Data.devices.speed -contains $null) { Return $null }
        $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

        $Shares = [PSCustomObject]@{ }
        $SharesAccepted = [Int64]$Data.total_accepted_shares
        $SharesRejected = [Int64]$Data.total_rejected_shares
        $SharesInvalid = [Int64]$Data.total_invalid_shares
        $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

        If ($HashrateName = [String]($this.Algorithms -ne $HashrateName)) { 
            $HashrateValue = [Double]($Data.devices.speed2 | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
            If (-not $HashRateValue -and $Data.devices.speed2 -contains $null) { Return $null }
            $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

            $SharesAccepted = [Int64]$Data.total_accepted_shares2
            $SharesRejected = [Int64]$Data.total_rejected_shares2
            $SharesInvalid = [Int64]$Data.total_invalid_shares2
            $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
        }

        $PowerConsumption = [Double]0

        If ($this.ReadPowerConsumption) { 
            $PowerConsumption = [Double]($Data.devices | Measure-Object power_usage -Sum).Sum
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
}