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
File:           \Includes\MinerAPIs\CCminer.ps1
Version:        6.7.18
Version date:   2026/01/06
#>

[NoRunspaceAffinity()]
class CcMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 # seconds
        $Data = [PSCustomObject]@{ }
        $Request = "summary"
        $Response = ""

        try { 
            $Response = Invoke-TcpRequest -Server 127.0.0.1 -Port $this.Port -Request $Request -Timeout $Timeout
            $Data = $Response -split ";" | ConvertFrom-StringData -ErrorAction Stop
            if (-not $Data.Keys.Count) { return $null }

            $Hashrate = [PSCustomObject]@{ }
            $HashrateName = [String]$this.Algorithms[0]
            $HashrateValue = [Double]$Data.HS
            if (-not $HashrateValue) { $HashrateValue = [Double]$Data.KHS * 1000 }
            if ($null -eq $HashrateValue) { return $null }
            $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

            $Shares = [PSCustomObject]@{ }
            $SharesAccepted = [Int64](($Data.ACC | Measure-Object -Sum).Sum)
            $SharesRejected = [Int64](($Data.REJ | Measure-Object -Sum).Sum)
            $SharesInvalid = [Int64]0
            $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

            $PowerConsumption = [Double]0

            if ($this.ReadPowerConsumption) { 
                $PowerConsumption = $this.GetPowerConsumption()
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