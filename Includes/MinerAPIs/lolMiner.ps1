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
Version:        6.7.9
Version date:   2025/12/15
#>

[NoRunspaceAffinity()]
class lolMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 # seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)/summary"

        try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
            if (-not $Data.Algorithms -or $null -eq $Data.Algorithms[0].Total_Performance) { return $null }

            $Hashrate = [PSCustomObject]@{ }
            $HashrateName = [String]$this.Algorithms[0]
            $HashrateUnit = [UInt64]1

            switch ($Data.Algorithms[0].Performance_Unit) { 
                "kh/s" { $HashrateUnit = [Math]::Pow(10, 3); break }
                "Mh/s" { $HashrateUnit = [Math]::Pow(10, 6); break }
                "GH/s" { $HashrateUnit = [Math]::Pow(10, 9); break }
                "TH/s" { $HashrateUnit = [Math]::Pow(10, 12); break }
                "PH/s" { $HashrateUnit = [Math]::Pow(10, 15); break }
                "EH/s" { $HashrateUnit = [Math]::Pow(10, 18); break }
                "ZH/s" { $HashrateUnit = [Math]::Pow(10, 21); break }
                "YH/s" { $HashrateUnit = [Math]::Pow(10, 24); break }
                default { $HashrateUnit = 1 }
            }
            $HashrateValue = [Double]($Data.Algorithms[0].Total_Performance * $HashrateUnit)
            $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

            $Shares = [PSCustomObject]@{ }
            $SharesAccepted = [Int64]$Data.Algorithms[0].Total_Accepted
            $SharesRejected = [Int64]$Data.Algorithms[0].Total_Rejected
            $SharesInvalid = [Int64]$Data.Algorithms[0].Total_Stales
            $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

            if ($HashrateName = [String]($this.Algorithms -ne $HashrateName)) { 
                if ($null -eq $Data.Algorithms[1].Total_Performance) { return $null }
                $HashrateUnit = [Int64]1
                switch ($Data.Algorithms[1].Performance_Unit) { 
                    "kh/s" { $HashrateUnit = [Math]::Pow(10, 3); break }
                    "Mh/s" { $HashrateUnit = [Math]::Pow(10, 6); break }
                    "GH/s" { $HashrateUnit = [Math]::Pow(10, 9); break }
                    "TH/s" { $HashrateUnit = [Math]::Pow(10, 12); break }
                    "PH/s" { $HashrateUnit = [Math]::Pow(10, 15); break }
                    "EH/s" { $HashrateUnit = [Math]::Pow(10, 18); break }
                    "ZH/s" { $HashrateUnit = [Math]::Pow(10, 21); break }
                    "YH/s" { $HashrateUnit = [Math]::Pow(10, 24); break }
                    default { $HashrateUnit = 1 }
                }
                $HashrateValue = [Double]($Data.Algorithms[1].Total_Performance * $HashrateUnit)
                $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

                $SharesAccepted = [Int64]$Data.Algorithms[1].Total_Accepted
                $SharesRejected = [Int64]$Data.Algorithms[1].Total_Rejected
                $SharesInvalid = [Int64]$Data.Algorithms[1].Total_Stales
                $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
            }

            $PowerConsumption = [Double]0

            if ($this.ReadPowerConsumption) { 
                $PowerConsumption = [Double]($Data.Workers | Measure-Object Power -Sum).Sum
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