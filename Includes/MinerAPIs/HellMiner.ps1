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
Version:        6.2.17
Version date:   2024/07/13
#>

Class HellMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)/stats"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $HashRate = [PSCustomObject]@{ }
        $HashRateName = [String]$this.Algorithms[0]
        $HashRateValue = [Double]($Data.total_mhs * [Math]::Pow(10,6))
        $HashRate | Add-Member @{ $HashRateName = [Double]$HashRateValue }

        $Shares = [PSCustomObject]@{ }
        $SharesAccepted = [Int64]$Data.total_accepted
        $SharesRejected = [Int64]$Data.total_rejected
        $SharesInvalid = [Int64]0
        $Shares | Add-Member @{ $HashRateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
        $PowerConsumption = [Double]0

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            If ($this.ReadPowerConsumption) { 
                $PowerConsumption = $this.GetPowerConsumption()
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