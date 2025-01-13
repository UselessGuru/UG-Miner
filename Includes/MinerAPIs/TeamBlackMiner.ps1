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
Version:        6.4.1
Version date:   2025/01/13
#>

Class TeamBlackMiner : Miner { 
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

        $Hashrate = [PSCustomObject]@{ }
        $HashrateName = [String]""
        $HashrateValue = [Double]0

        $Shares = [PSCustomObject]@{ }
        $SharesAccepted = [Int64]0
        $SharesRejected = [Int64]0
        $SharesInvalid = [Int64]0

        ForEach ($Algorithm in $this.Algorithms) { 
            $Data.pool.PSObject.Properties.Name.ForEach(
                { 
                    If ($Data.pool.$_.total_hashrate -eq $null) { Return $null }
                    If ($Data.pool.$_.Algo -eq $Algorithm) { 
                        $HashrateName = [String]$Algorithm
                        $HashrateValue = [Double]($Data.pool.$_.total_hashrate)
                        $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

                        $SharesAccepted = [Int64]($Data.pool.$_.total_accepted)
                        $SharesRejected = [Int64]($Data.pool.$_.total_rejected)
                        $SharesInvalid  = [Int64]($Data.pool.$_.total_stale)
                        $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
                    }
                }
            )
        }

        $PowerConsumption = [Double]0

        If ($this.ReadPowerConsumption) { 
            $Data.Devices.ForEach({ $PowerConsumption += [Double]$_.PSObject.Properties.Value.watt })
            $PowerConsumption = [Double]($Data.result | Measure-Object gpu_power_usage -Sum).Sum
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
}