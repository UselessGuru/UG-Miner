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
File:           \Includes\MinerAPIs\EthMiner.ps1
Version:        6.7.21
Version date:   2026/01/13
#>

[NoRunspaceAffinity()]
class EthMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 # seconds
        $Data = [PSCustomObject]@{ }
        $Request = @{ id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json -Compress
        $Response = ""

        try { 
            $Response = Invoke-TcpRequest -Server 127.0.0.1 -Port $this.Port -Request $Request -Timeout $Timeout
            $Data = $Response | ConvertFrom-Json -ErrorAction Stop
            if (-not $Data.result -or ($null -eq ($Data.result[2] -split ";")[0])) { return $null }

            $Hashrate = [PSCustomObject]@{ }
            $HashrateName = [String]$this.Algorithms[0]
            $HashrateValue = [Double]($Data.result[2] -split ";")[0]

            if ($Data.result[0] -notmatch "^TT-Miner" -and $HashrateName -match "^Blake2s|^Ethash|^EtcHash|^Firopow|^Kawpow|^Keccak|^MeowPow|^Neoscrypt|^ProgPow|^SCCpow|^Ubqhash") { $HashrateValue *= 1000 }
            $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

            $Shares = [PSCustomObject]@{ }
            $SharesAccepted = [Int64]($Data.result[2] -split ";")[1]
            $SharesRejected = [Int64]($Data.result[2] -split ";")[2]
            $SharesInvalid = [Int64]0
            $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

            if ($HashrateName = [String]($this.Algorithms -ne $HashrateName)) { 
                if ($null -eq (($Data.result[4] -split ";")[0])) { return $null }
                $HashrateValue = [Double]($Data.result[4] -split ";")[0]
                if ($HashrateName -match "^Blake2s|^Ethash|^EtcHash|^Firopow|^Kawpow|^Keccak|^MeowPow|^Neoscrypt|^ProgPow|^SCCpow|^Ubqhash") { $HashrateValue *= 1000 }
                $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

                $SharesAccepted = [Int64]($Data.result[4] -split ";")[1]
                $SharesRejected = [Int64]($Data.result[4] -split ";")[2]
                $SharesInvalid = [Int64]0
                $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
            }

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