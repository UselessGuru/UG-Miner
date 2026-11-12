<#
Copyright (c) 2018-2026 UselessGuru

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
Version:        6.9.4
Version date:   2026/11/12
#>

[NoRunspaceAffinity()]
class BzMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 # seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)/api/snapshot"

        try { 
            $Data = Invoke-RestMethod -Uri $Request -Method GET -ConnectionTimeoutSeconds $Timeout -OperationTimeoutSeconds $Timeout -DisableKeepAlive 2>$null 3>$null 4>$null 5>$null 6>$null
            if ($Error) { $Error.Remove($Error[0]) }

            if (-not $Data) { return $null }

            # if ($Data.Pools.Count -ne $this.Algorithms.Count) { return $null }

            $Hashrate = [PSCustomObject]@{ }
            $HashrateName = [String]$this.Algorithms[0]
            $HashrateValue = [Double]0

            $Shares = [PSCustomObject]@{ }

            $Devices = $Data.Devices.Where{ $_.pool -eq 0 }

            $HashrateValue = [Double](($Devices.ForEach{ $_.hashrate } | Measure-Object -Sum).Sum)
            if (-not $HashrateValue) { return $null }
            $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

            $SharesAccepted = [Int64](($Devices.ForEach{ $_.accepted } | Measure-Object -Sum).Sum)
            $SharesRejected = [Int64](($Devices.ForEach{ $_.rejected } | Measure-Object -Sum).Sum)
            $SharesInvalid  = [Int64](($Devices.ForEach{ $_.stale }    | Measure-Object -Sum).Sum)
            $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

            if ($HashrateName = [String]$this.Algorithms[1]) { 

                $Devices = $Data.Devices.Where{ $_.pool -eq 1 }

                $HashrateValue = [Double](($Devices.ForEach{ $_.hashrate } | Measure-Object -Sum).Sum)
                $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

                $SharesAccepted = [Int64](($Devices.ForEach{ $_.accepted } | Measure-Object -Sum).Sum)
                $SharesRejected = [Int64](($Devices.ForEach{ $_.rejected } | Measure-Object -Sum).Sum)
                $SharesInvalid  = [Int64](($Devices.ForEach{ $_.stale }    | Measure-Object -Sum).Sum)
                $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
            }

            $PowerConsumption = [Double]0

            if ($this.ReadPowerConsumption) { 
                $PowerConsumption = [Double]($Devices | Measure-Object power -Sum).Sum
                if (-not $PowerConsumption -or $PowerConsumption -gt 1000 -or $PowerConsumption -lt 0) { 
                    $PowerConsumption = $this.GetPowerConsumption()
                }
            }

            return @{ 
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