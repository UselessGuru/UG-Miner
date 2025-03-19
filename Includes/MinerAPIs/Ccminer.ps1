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
File:           \Includes\MinerAPIs\CCminer.ps1
Version:        6.4.17
Version date:   2025/03/19
#>

Class CcMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $Request = "summary"
        $Response = ""

        Try { 
            $Response = Invoke-TcpRequest -Server 127.0.0.1 -Port $this.Port -Request $Request -Timeout $Timeout -ErrorAction Stop
            $Data = $Response -split ";" | ConvertFrom-StringData -ErrorAction Stop
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $Hashrate = [PSCustomObject]@{ }
        $HashrateName = [String]$this.Algorithms[0]
        $HashrateValue = [Double]$Data.HS
        If (-not $HashrateValue) { $HashrateValue = [Double]$Data.KHS * 1000 }
        If ($null -eq $HashrateValue) { Return $null }
        $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

        $Shares = [PSCustomObject]@{ }
        $SharesAccepted = [Int64]($Data.ACC | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
        $SharesRejected = [Int64]($Data.REJ | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
        $SharesInvalid = [Int64]0
        $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

        $PowerConsumption = [Double]0

        If ($this.ReadPowerConsumption) { 
            $PowerConsumption = $this.GetPowerConsumption()
        }

        Return [PSCustomObject]@{ 
            Date             = [DateTime]::Now.ToUniversalTime()
            Hashrate         = $Hashrate
            PowerConsumption = $PowerConsumption
            Shares           = $Shares
        }
    }
}