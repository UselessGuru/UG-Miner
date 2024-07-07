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
File:           \Includes\MinerAPIs\BzMiner.ps1
Version:        6.2.15
Version date:   2024/07/07
#>

Class BzMiner : Miner {
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)/status"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $Devices = $Data.devices.Where({ $_.message[0] })

        $HashRate = [PSCustomObject]@{ }
        $HashRateName = [String]$this.Algorithms[0]
        $HashRateValue = [Double]0

        $Shares = [PSCustomObject]@{ }

        If ($Devices.Hashrate.Count -eq $this.Algorithms.Count) { 

            $HashRateValue = [Double]($Devices.ForEach({ $_.hashrate[0] }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
            $HashRate | Add-Member @{$HashRateName = [Double]$HashRateValue}

            $SharesAccepted = [Int64]($Devices.ForEach({ $_.valid_solutions[0] }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
            $SharesRejected = [Int64]($Devices.ForEach({ $_.rejected_solutions[0] }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
            $SharesInvalid = [Int64]($Devices.ForEach({ $_.stale_solutions[0] }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
            $Shares | Add-Member @{ $HashRateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

            If ($HashRateName = [String]($this.Algorithms -ne $HashRateName)) {
                $HashRateValue = [Double]($Devices.ForEach({ $_.hashrate[1] }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
                $HashRate | Add-Member @{$HashRateName = [Double]$HashRateValue}

                $SharesAccepted = [Int64]($Devices.ForEach({ $_.valid_solutions[1] }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
                $SharesRejected = [Int64]($Devices.ForEach({ $_.rejected_solutions[1] }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
                $SharesInvalid = [Int64]($Devices.ForEach({ $_.stale_solutions[1] }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
                $Shares | Add-Member @{ $HashRateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
            }
        }

        $PowerConsumption = [Double]0

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            If ($this.ReadPowerConsumption) { 
                $PowerConsumption = [Double]($Devices | Measure-Object power -Sum).Sum
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