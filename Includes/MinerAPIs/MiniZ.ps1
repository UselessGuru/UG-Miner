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
File:           \Includes\MinerAPIs\MiniZ.ps1
Version:        6.3.3
Version date:   2024/09/11
#>

Class MiniZ : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $Request = '{ "id":"0", "method":"getstat" }'
        $Response = ""

        Try { 
            $Response = Invoke-TcpRequest 127.0.0.1 -Port $this.Port -Request $Request -Timeout $Timeout -ReadToEnd $true -ErrorAction Stop
            $Data = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $HashRate = [PSCustomObject]@{ }
        $HashRateName = [String]$this.Algorithms[0]
        $HashRateValue = [Double]($Data.result.speed_sps | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
        If (-not $HashRateValue) { $HashRateValue = [Double]($Data.result.sol_ps | Measure-Object -Sum | Select-Object -ExpandProperty Sum) } #fix
        $HashRate | Add-Member @{ $HashRateName = [Double]$HashRateValue }

        $Shares = [PSCustomObject]@{ }
        $SharesAccepted = [Int64]($Data.result.accepted_shares | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
        $SharesRejected = [Int64]($Data.result.rejected_shares | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
        $SharesInvalid = [Int64]0
        $Shares | Add-Member @{ $HashRateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

        $PowerConsumption = [Double]0

        If ($this.ReadPowerConsumption) { 
            $PowerConsumption = [Double]($Data.result | Measure-Object gpu_power_usage -Sum).Sum
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
}