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
File:           \Includes\MinerAPIs\Xgminer.ps1
Version:        6.5.15
Version date:   2025/10/12
#>

Class XgMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 # seconds
        $Data = [PSCustomObject]@{ }
        $Request = @{ command = "summary$(If ($this.Algorithms[1]) { "+summary2" })"; parameter = "" } | ConvertTo-Json -Compress
        $Response = ""

        Try { 
            $Response = Invoke-TcpRequest -Server 127.0.0.1 -Port $this.Port -Request $Request -Timeout $Timeout -ErrorAction Stop
            $Data = $Response -replace ": ", ":" -replace " ", "_" | ConvertFrom-Json -ErrorAction Stop
            If (-not $Data) { Return $null }

            $Hashrate = [PSCustomObject]@{ }

            $DataSummary = If ($this.Algorithms[1]) { $Data.summary.SUMMARY[0] } Else { $Data.SUMMARY }
            $HashrateName = [String]$this.Algorithms[0]
            $HashrateValue = If ($DataSummary.HS_5s) { [Double]$DataSummary.HS_5s * [Math]::Pow(1000, 0) }
            ElseIf ($DataSummary.KHS_5s) { [Double]$DataSummary.KHS_5s * [Math]::Pow(1000, 1) }
            ElseIf ($DataSummary.MHS_5s) { [Double]$DataSummary.MHS_5s * [Math]::Pow(1000, 2) }
            ElseIf ($DataSummary.GHS_5s) { [Double]$DataSummary.GHS_5s * [Math]::Pow(1000, 3) }
            ElseIf ($DataSummary.THS_5s) { [Double]$DataSummary.THS_5s * [Math]::Pow(1000, 4) }
            ElseIf ($DataSummary.PHS_5s) { [Double]$DataSummary.PHS_5s * [Math]::Pow(1000, 5) }
            ElseIf ($DataSummary.KHS_30s) { [Double]$DataSummary.KHS_30s * [Math]::Pow(1000, 1) }
            ElseIf ($DataSummary.MHS_30s) { [Double]$DataSummary.MHS_30s * [Math]::Pow(1000, 2) }
            ElseIf ($DataSummary.GHS_30s) { [Double]$DataSummary.GHS_30s * [Math]::Pow(1000, 3) }
            ElseIf ($DataSummary.THS_30s) { [Double]$DataSummary.THS_30s * [Math]::Pow(1000, 4) }
            ElseIf ($DataSummary.PHS_30s) { [Double]$DataSummary.PHS_30s * [Math]::Pow(1000, 5) }
            ElseIf ($DataSummary.HS_av) { [Double]$DataSummary.HS_av * [Math]::Pow(1000, 0) }
            ElseIf ($DataSummary.KHS_av) { [Double]$DataSummary.KHS_av * [Math]::Pow(1000, 1) }
            ElseIf ($DataSummary.MHS_av) { [Double]$DataSummary.MHS_av * [Math]::Pow(1000, 2) }
            ElseIf ($DataSummary.GHS_av) { [Double]$DataSummary.GHS_av * [Math]::Pow(1000, 3) }
            ElseIf ($DataSummary.THS_av) { [Double]$DataSummary.THS_av * [Math]::Pow(1000, 4) }
            ElseIf ($DataSummary.PHS_av) { [Double]$DataSummary.PHS_av * [Math]::Pow(1000, 5) }
            If ($null -eq $HashrateValue) { Return $null }
            $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

            $Shares = [PSCustomObject]@{ }
            $SharesAccepted = [Int64]$DataSummary.accepted
            $SharesRejected = [Int64]$DataSummary.rejected
            $SharesInvalid = [Int64]$DataSummary.stale
            $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

            If ($HashrateName = [String]($this.Algorithms -ne $HashrateName)) { 
                $DataSummary = $Data.summary2.SUMMARY[0]
                $HashrateValue = If ($DataSummary.HS_5s) { [Double]$DataSummary.HS_5s * [Math]::Pow(1000, 0) }
                ElseIf ($DataSummary.KHS_5s) { [Double]$DataSummary.KHS_5s * [Math]::Pow(1000, 1) }
                ElseIf ($DataSummary.MHS_5s) { [Double]$DataSummary.MHS_5s * [Math]::Pow(1000, 2) }
                ElseIf ($DataSummary.GHS_5s) { [Double]$DataSummary.GHS_5s * [Math]::Pow(1000, 3) }
                ElseIf ($DataSummary.THS_5s) { [Double]$DataSummary.THS_5s * [Math]::Pow(1000, 4) }
                ElseIf ($DataSummary.PHS_5s) { [Double]$DataSummary.PHS_5s * [Math]::Pow(1000, 5) }
                ElseIf ($DataSummary.KHS_30s) { [Double]$DataSummary.KHS_30s * [Math]::Pow(1000, 1) }
                ElseIf ($DataSummary.MHS_30s) { [Double]$DataSummary.MHS_30s * [Math]::Pow(1000, 2) }
                ElseIf ($DataSummary.GHS_30s) { [Double]$DataSummary.GHS_30s * [Math]::Pow(1000, 3) }
                ElseIf ($DataSummary.THS_30s) { [Double]$DataSummary.THS_30s * [Math]::Pow(1000, 4) }
                ElseIf ($DataSummary.PHS_30s) { [Double]$DataSummary.PHS_30s * [Math]::Pow(1000, 5) }
                ElseIf ($DataSummary.HS_av) { [Double]$DataSummary.HS_av * [Math]::Pow(1000, 0) }
                ElseIf ($DataSummary.KHS_av) { [Double]$DataSummary.KHS_av * [Math]::Pow(1000, 1) }
                ElseIf ($DataSummary.MHS_av) { [Double]$DataSummary.MHS_av * [Math]::Pow(1000, 2) }
                ElseIf ($DataSummary.GHS_av) { [Double]$DataSummary.GHS_av * [Math]::Pow(1000, 3) }
                ElseIf ($DataSummary.THS_av) { [Double]$DataSummary.THS_av * [Math]::Pow(1000, 4) }
                ElseIf ($DataSummary.PHS_av) { [Double]$DataSummary.PHS_av * [Math]::Pow(1000, 5) }
                If ($null -eq $HashrateValue) { Return $null }
                $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

                $SharesAccepted = [Int64]$DataSummary.accepted
                $SharesRejected = [Int64]$DataSummary.rejected
                $SharesInvalid = [Int64]$DataSummary.stale
                $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
            }

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
        Catch { 
            Return $null
        }
    }
}