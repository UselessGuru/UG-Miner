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
File:           \Includes\MinerAPIs\Rigel.ps1
Version:        6.7.29
Version date:   2026/02/19
#>

[NoRunspaceAffinity()]
class Rigel : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 # seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)/stat"

        try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
            if (-not $Data) { return $null }

            $Hashrate = [PSCustomObject]@{ }
            $HashrateName = ""
            $HashrateValue = [Double]0
            $Algorithms = [String[]]@($Data.algorithm -split "\+")
            $Algorithm = $Algorithms[0]

            $Shares = [PSCustomObject]@{ }
            $SharesAccepted = $SharesRejected = $SharesInvalid = [Int64]0

            foreach ($Algorithm in $Algorithms) { 
                if ($null -eq $Data.hashrate.$Algorithm) { return $null }
                $HashrateName = $this.Algorithms[$Algorithms.IndexOf($Algorithm)]
                $HashrateValue = [Double]$Data.hashrate.$Algorithm
                $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

                $SharesAccepted = [Int64]$Data.solution_stat.$Algorithm.accepted
                $SharesRejected = [Int64]$Data.solution_stat.$Algorithm.rejected
                $SharesInvalid = [Int64]$Data.solution_stat.$Algorithm.invalid
                $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
            }

            $PowerConsumption = [Double]0

            if ($this.ReadPowerConsumption) { 
                $PowerConsumption = [Double]$Data.power_usage
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