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
File:           \Includes\MinerAPIs\NanoMiner.ps1
Version:        6.7.1
Version date:   2025/11/25
#>

class NanoMiner : Miner { 
    [Void]CreateConfigFiles() { 
        $Parameters = $this.Arguments | ConvertFrom-Json -ErrorAction Ignore

        try { 
            $ConfigFile = "$(Split-Path $this.Path)\$($Parameters.ConfigFile.FileName)"
            # Write config files. Do not overwrite existing files to preserve optional manual customization
            if (-not (Test-Path -LiteralPath $ConfigFile -PathType Leaf)) { 
                $Parameters.ConfigFile.Content | Out-File -LiteralPath $ConfigFile -Force -ErrorAction Ignore
            }
        }
        catch { 
            Write-Message -Level Error "Creating miner config files for '$($this.Info)' failed [Error: '$($Error | Select-Object -First 1)']."
            return
        }
    }

    [Object]GetMinerData () { 
        $Timeout = 5 # seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)/stats"

        try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
            if (-not $Data) { return $null }

            $Hashrate = [PSCustomObject]@{ }
            $HashrateName = ""
            $HashrateValue = [Double]0

            $Shares = [PSCustomObject]@{ }
            $SharesAccepted = [Int64]0
            $SharesRejected = [Int64]0

            $Algorithms = @($Data.Algorithms.ForEach({ $_.PSObject.Properties.Name }) | Select-Object -Unique)

            foreach ($Algorithm in $Algorithms) { 
                $HashrateName = $this.Algorithms[$Algorithms.IndexOf($Algorithm)]
                $HashrateValue = [Double](($Data.Algorithms.$Algorithm.Total.Hashrate | Measure-Object -Sum).Sum)
                if ($null -eq $HashrateValue) { return $null }
                $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

                $SharesAccepted = [Int64](($Data.Algorithms.$Algorithm.Total.Accepted | Measure-Object -Sum).Sum)
                $SharesRejected = [Int64](($Data.Algorithms.$Algorithm.Total.Denied | Measure-Object -Sum).Sum)
                $SharesInvalid = [Int64]0
                $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
            }

            $PowerConsumption = [Double]0

            if ($this.ReadPowerConsumption) { 
                foreach ($Device in $Data.Devices) { $PowerConsumption += [Double]$Device.PSObject.Members.Value.Power }
                if (-not $PowerConsumption -or $PowerConsumption -gt 1000 -or $PowerConsumption -lt 0) { 
                    $PowerConsumption = $this.GetPowerConsumption()
                }
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