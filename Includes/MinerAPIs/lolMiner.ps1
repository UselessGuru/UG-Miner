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
File:           \Includes\MinerAPIs\lolMiner.ps1
Version:        6.5.13
Version date:   2025/09/30
#>

Class lolMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 # seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)/summary"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
            If (-not $Data.Algorithms -or $null -eq $Data.Algorithms[0].Total_Performance) { Return $null }

            $Hashrate = [PSCustomObject]@{ }
            $HashrateName = [String]$this.Algorithms[0]
            $HashrateUnit = [UInt64]1

            Switch ($Data.Algorithms[0].Performance_Unit) { 
                "kh/s"  { $HashrateUnit = [Math]::Pow(10,3); Break }
                "Mh/s"  { $HashrateUnit = [Math]::Pow(10,6); Break }
                "GH/s"  { $HashrateUnit = [Math]::Pow(10,9); Break }
                "TH/s"  { $HashrateUnit = [Math]::Pow(10,12); Break }
                "PH/s"  { $HashrateUnit = [Math]::Pow(10,15); Break }
                "EH/s"  { $HashrateUnit = [Math]::Pow(10,18); Break }
                "ZH/s"  { $HashrateUnit = [Math]::Pow(10,21); Break }
                "YH/s"  { $HashrateUnit = [Math]::Pow(10,24); Break }
                Default { $HashrateUnit = 1 }
            }
            $HashrateValue = [Double]($Data.Algorithms[0].Total_Performance * $HashrateUnit)
            $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

            $Shares = [PSCustomObject]@{ }
            $SharesAccepted = [Int64]$Data.Algorithms[0].Total_Accepted
            $SharesRejected = [Int64]$Data.Algorithms[0].Total_Rejected
            $SharesInvalid = [Int64]$Data.Algorithms[0].Total_Stales
            $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

            If ($HashrateName = [String]($this.Algorithms -ne $HashrateName)) { 
                If ($null -eq $Data.Algorithms[1].Total_Performance) { Return $null }
                $HashrateUnit = [Int64]1
                Switch ($Data.Algorithms[1].Performance_Unit) { 
                    "kh/s"  { $HashrateUnit = [Math]::Pow(10,3); Break }
                    "Mh/s"  { $HashrateUnit = [Math]::Pow(10,6); Break }
                    "GH/s"  { $HashrateUnit = [Math]::Pow(10,9); Break }
                    "TH/s"  { $HashrateUnit = [Math]::Pow(10,12); Break }
                    "PH/s"  { $HashrateUnit = [Math]::Pow(10,15); Break }
                    "EH/s"  { $HashrateUnit = [Math]::Pow(10,18); Break }
                    "ZH/s"  { $HashrateUnit = [Math]::Pow(10,21); Break }
                    "YH/s"  { $HashrateUnit = [Math]::Pow(10,24); Break }
                    Default { $HashrateUnit = 1 }
                }
                $HashrateValue = [Double]($Data.Algorithms[1].Total_Performance * $HashrateUnit)
                $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

                $SharesAccepted = [Int64]$Data.Algorithms[1].Total_Accepted
                $SharesRejected = [Int64]$Data.Algorithms[1].Total_Rejected
                $SharesInvalid = [Int64]$Data.Algorithms[1].Total_Stales
                $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
            }

            $PowerConsumption = [Double]0

            If ($this.ReadPowerConsumption) { 
                $PowerConsumption = [Double]($Data.Workers | Measure-Object Power -Sum).Sum
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