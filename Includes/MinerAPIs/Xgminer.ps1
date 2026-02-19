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
Version:        6.7.29
Version date:   2026/02/19
#>

[NoRunspaceAffinity()]
class XgMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 # seconds
        $Data = [PSCustomObject]@{ }
        $Request = @{ command = "summary$(if ($this.Algorithms[1]) { "+summary2" })"; parameter = "" } | ConvertTo-Json -Compress
        $Response = ""

        try { 
            $Response = Invoke-TcpRequest -Server 127.0.0.1 -Port $this.Port -Request $Request -Timeout $Timeout -ErrorAction Stop
            $Data = $Response -replace ": ", ":" -replace " ", "_" | ConvertFrom-Json -ErrorAction Stop
            if (-not $Data) { return $null }

            $Hashrate = [PSCustomObject]@{ }

            $DataSummary = if ($this.Algorithms[1]) { $Data.summary.SUMMARY[0] } else { $Data.SUMMARY }
            $HashrateName = [String]$this.Algorithms[0]
            $HashrateValue = if ($DataSummary.HS_5s) { [Double]$DataSummary.HS_5s * [Math]::Pow(1000, 0) }
            elseif ($DataSummary.KHS_5s) { [Double]$DataSummary.KHS_5s * [Math]::Pow(1000, 1) }
            elseif ($DataSummary.MHS_5s) { [Double]$DataSummary.MHS_5s * [Math]::Pow(1000, 2) }
            elseif ($DataSummary.GHS_5s) { [Double]$DataSummary.GHS_5s * [Math]::Pow(1000, 3) }
            elseif ($DataSummary.THS_5s) { [Double]$DataSummary.THS_5s * [Math]::Pow(1000, 4) }
            elseif ($DataSummary.PHS_5s) { [Double]$DataSummary.PHS_5s * [Math]::Pow(1000, 5) }
            elseif ($DataSummary.KHS_30s) { [Double]$DataSummary.KHS_30s * [Math]::Pow(1000, 1) }
            elseif ($DataSummary.MHS_30s) { [Double]$DataSummary.MHS_30s * [Math]::Pow(1000, 2) }
            elseif ($DataSummary.GHS_30s) { [Double]$DataSummary.GHS_30s * [Math]::Pow(1000, 3) }
            elseif ($DataSummary.THS_30s) { [Double]$DataSummary.THS_30s * [Math]::Pow(1000, 4) }
            elseif ($DataSummary.PHS_30s) { [Double]$DataSummary.PHS_30s * [Math]::Pow(1000, 5) }
            elseif ($DataSummary.HS_av) { [Double]$DataSummary.HS_av * [Math]::Pow(1000, 0) }
            elseif ($DataSummary.KHS_av) { [Double]$DataSummary.KHS_av * [Math]::Pow(1000, 1) }
            elseif ($DataSummary.MHS_av) { [Double]$DataSummary.MHS_av * [Math]::Pow(1000, 2) }
            elseif ($DataSummary.GHS_av) { [Double]$DataSummary.GHS_av * [Math]::Pow(1000, 3) }
            elseif ($DataSummary.THS_av) { [Double]$DataSummary.THS_av * [Math]::Pow(1000, 4) }
            elseif ($DataSummary.PHS_av) { [Double]$DataSummary.PHS_av * [Math]::Pow(1000, 5) }
            if ($null -eq $HashrateValue) { return $null }
            $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

            $Shares = [PSCustomObject]@{ }
            $SharesAccepted = [Int64]$DataSummary.accepted
            $SharesRejected = [Int64]$DataSummary.rejected
            $SharesInvalid = [Int64]$DataSummary.stale
            $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

            if ($HashrateName = [String]($this.Algorithms -ne $HashrateName)) { 
                $DataSummary = $Data.summary2.SUMMARY[0]
                $HashrateValue = if ($DataSummary.HS_5s) { [Double]$DataSummary.HS_5s * [Math]::Pow(1000, 0) }
                elseif ($DataSummary.KHS_5s) { [Double]$DataSummary.KHS_5s * [Math]::Pow(1000, 1) }
                elseif ($DataSummary.MHS_5s) { [Double]$DataSummary.MHS_5s * [Math]::Pow(1000, 2) }
                elseif ($DataSummary.GHS_5s) { [Double]$DataSummary.GHS_5s * [Math]::Pow(1000, 3) }
                elseif ($DataSummary.THS_5s) { [Double]$DataSummary.THS_5s * [Math]::Pow(1000, 4) }
                elseif ($DataSummary.PHS_5s) { [Double]$DataSummary.PHS_5s * [Math]::Pow(1000, 5) }
                elseif ($DataSummary.KHS_30s) { [Double]$DataSummary.KHS_30s * [Math]::Pow(1000, 1) }
                elseif ($DataSummary.MHS_30s) { [Double]$DataSummary.MHS_30s * [Math]::Pow(1000, 2) }
                elseif ($DataSummary.GHS_30s) { [Double]$DataSummary.GHS_30s * [Math]::Pow(1000, 3) }
                elseif ($DataSummary.THS_30s) { [Double]$DataSummary.THS_30s * [Math]::Pow(1000, 4) }
                elseif ($DataSummary.PHS_30s) { [Double]$DataSummary.PHS_30s * [Math]::Pow(1000, 5) }
                elseif ($DataSummary.HS_av) { [Double]$DataSummary.HS_av * [Math]::Pow(1000, 0) }
                elseif ($DataSummary.KHS_av) { [Double]$DataSummary.KHS_av * [Math]::Pow(1000, 1) }
                elseif ($DataSummary.MHS_av) { [Double]$DataSummary.MHS_av * [Math]::Pow(1000, 2) }
                elseif ($DataSummary.GHS_av) { [Double]$DataSummary.GHS_av * [Math]::Pow(1000, 3) }
                elseif ($DataSummary.THS_av) { [Double]$DataSummary.THS_av * [Math]::Pow(1000, 4) }
                elseif ($DataSummary.PHS_av) { [Double]$DataSummary.PHS_av * [Math]::Pow(1000, 5) }
                if ($null -eq $HashrateValue) { return $null }
                $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

                $SharesAccepted = [Int64]$DataSummary.accepted
                $SharesRejected = [Int64]$DataSummary.rejected
                $SharesInvalid = [Int64]$DataSummary.stale
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