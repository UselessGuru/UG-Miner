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
File:           \Includes\MinerAPIs\lolMiner.ps1
Version:        6.2.23
Version date:   2024/08/04
#>

Class lolMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)/summary"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $HashRate = [PSCustomObject]@{ }
        $HashRateName = [String]$this.Algorithms[0]
        $HashRate_Unit = [Int64]1
        Switch ($Data.Algorithms[0].Performance_Unit) { 
            "kh/s"  { $HashRate_Unit = [Math]::Pow(10,3) }
            "Mh/s"  { $HashRate_Unit = [Math]::Pow(10,6) }
            "GH/s"  { $HashRate_Unit = [Math]::Pow(10,9) }
            "TH/s"  { $HashRate_Unit = [Math]::Pow(10,12) }
            "PH/s"  { $HashRate_Unit = [Math]::Pow(10,15) }
            "EH/s"  { $HashRate_Unit = [Math]::Pow(10,18) }
            "ZH/s"  { $HashRate_Unit = [Math]::Pow(10,21) }
            "YH/s"  { $HashRate_Unit = [Math]::Pow(10,24) }
            Default { $HashRate_Unit = 1 }
        }
        $HashRateValue = [Double]($Data.Algorithms[0].Total_Performance * $HashRate_Unit)
        $HashRate | Add-Member @{ $HashRateName = [Double]$HashRateValue }

        $Shares = [PSCustomObject]@{ }
        $SharesAccepted = [Int64]$Data.Algorithms[0].Total_Accepted
        $SharesRejected = [Int64]$Data.Algorithms[0].Total_Rejected
        $SharesInvalid = [Int64]$Data.Algorithms[0].Total_Stales
        $Shares | Add-Member @{ $HashRateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

        If ($HashRateName = [String]($this.Algorithms -ne $HashRateName)) { 
            $HashRate_Unit = [Int64]1
            Switch ($Data.Algorithms[1].Performance_Unit) { 
                "kh/s"  { $HashRate_Unit = [Math]::Pow(10,3) }
                "Mh/s"  { $HashRate_Unit = [Math]::Pow(10,6) }
                "GH/s"  { $HashRate_Unit = [Math]::Pow(10,9) }
                "TH/s"  { $HashRate_Unit = [Math]::Pow(10,12) }
                "PH/s"  { $HashRate_Unit = [Math]::Pow(10,15) }
                "EH/s"  { $HashRate_Unit = [Math]::Pow(10,18) }
                "ZH/s"  { $HashRate_Unit = [Math]::Pow(10,21) }
                "YH/s"  { $HashRate_Unit = [Math]::Pow(10,24) }
                Default { $HashRate_Unit = 1 }
            }
            $HashRateValue = [Double]($Data.Algorithms[1].Total_Performance * $HashRate_Unit)
            $HashRate | Add-Member @{ $HashRateName = [Double]$HashRateValue }

            $SharesAccepted = [Int64]$Data.Algorithms[1].Total_Accepted
            $SharesRejected = [Int64]$Data.Algorithms[1].Total_Rejected
            $SharesInvalid = [Int64]$Data.Algorithms[1].Total_Stales
            $Shares | Add-Member @{ $HashRateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
        }

        $PowerConsumption = [Double]0

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            If ($this.ReadPowerConsumption) { 
                $PowerConsumption = [Double]($Data.Workers | Measure-Object Power -Sum).Sum
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