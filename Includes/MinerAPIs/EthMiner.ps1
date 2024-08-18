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
File:           \Includes\MinerAPIs\EthMiner.ps1
Version:        6.2.27
Version date:   2024/08/18
#>

Class EthMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $Request = @{ id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json -Compress
        $Response = ""

        Try { 
            $Response = Invoke-TcpRequest -Server 127.0.0.1 -Port $this.Port -Request $Request -Timeout $Timeout
            $Data = $Response | ConvertFrom-Json
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $HashRate = [PSCustomObject]@{ }
        $HashRateName = [String]$this.Algorithms[0]
        $HashRateValue = [Double]($Data.result[2] -split ";")[0]
        If ($Data.result[0] -notmatch "^TT-Miner") { 
            If ($HashRateName -eq "EtcHash")         { $HashRateValue *= 1000 }
            ElseIf ($HashRateName -eq "Ethash")      { $HashRateValue *= 1000 }
            ElseIf ($HashRateName -eq "MeowPow")     { $HashRateValue *= 1000 }
            ElseIf ($HashRateName -eq "UbqHash")     { $HashRateValue *= 1000 }
        }
        If ($HashRateName -eq "Neoscrypt")           { $HashRateValue *= 1000 }
        ElseIf ($HashRateName -eq "BitcoinInterest") { $HashRateValue *= 1000 }
        $HashRate | Add-Member @{ $HashRateName = [Double]$HashRateValue }

        $Shares = [PSCustomObject]@{ }
        $SharesAccepted = [Int64]($Data.result[2] -split ";")[1]
        $SharesRejected = [Int64]($Data.result[2] -split ";")[2]
        $SharesInvalid = [Int64]0
        $Shares | Add-Member @{ $HashRateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

        If ($HashRateName = [String]($this.Algorithms -ne $HashRateName)) { 
            $HashRateValue = [Double]($Data.result[4] -split ";")[0]
            If ($this.Algorithms[0] -eq "Blake2s") { $HashRateValue *= 1000 }
            If ($this.Algorithms[0] -eq "Keccak") { $HashRateValue *= 1000 }
            $HashRate | Add-Member @{ $HashRateName = [Double]$HashRateValue }

            $SharesAccepted = [Int64]($Data.result[4] -split ";")[1]
            $SharesRejected = [Int64]($Data.result[4] -split ";")[2]
            $SharesInvalid = [Int64]0
            $Shares | Add-Member @{ $HashRateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
        }

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