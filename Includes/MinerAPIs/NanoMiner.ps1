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
Version:        6.4.33
Version date:   2025/06/25
#>

Class NanoMiner : Miner { 
    [Void]CreateConfigFiles() { 
        $Parameters = $this.Arguments | ConvertFrom-Json -ErrorAction Ignore

        Try { 
            $ConfigFile = "$(Split-Path $this.Path)\$($Parameters.ConfigFile.FileName)"
            # Write config files. Do not overwrite existing files to preserve optional manual customization
            If (-not (Test-Path -LiteralPath $ConfigFile -PathType Leaf)) { 
                $Parameters.ConfigFile.Content | Out-File -LiteralPath $ConfigFile -Force -ErrorAction Ignore
            }
        }
        Catch { 
            Write-Message -Level Error "Creating miner config files for '$($this.Info)' failed [Error: '$($Error | Select-Object -First 1)']."
            Return
        }
    }

    [Object]GetMinerData () { 
        $Timeout = 5 # seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)/stats"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $Hashrate = [PSCustomObject]@{ }
        $HashrateName = ""
        $HashrateValue = [Double]0

        $Shares = [PSCustomObject]@{ }
        $SharesAccepted = [Int64]0
        $SharesRejected = [Int64]0

        $Algorithms = @($Data.Algorithms.ForEach({ ($_ | Get-Member -MemberType NoteProperty).Name }) | Select-Object -Unique)

        ForEach ($Algorithm in $Algorithms) { 
            $HashrateName = $this.Algorithms[$Algorithms.IndexOf($Algorithm)]
            $HashrateValue = [Double]($Data.Algorithms.$Algorithm.Total.Hashrate | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
            If ($null -eq $HashrateValue) { Return $null }
            $Hashrate | Add-Member @{ $HashrateName = $HashrateValue }

            $SharesAccepted = [Int64]($Data.Algorithms.$Algorithm.Total.Accepted | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
            $SharesRejected = [Int64]($Data.Algorithms.$Algorithm.Total.Denied | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
            $SharesInvalid = [Int64]0
            $Shares | Add-Member @{ $HashrateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }
        }

        $PowerConsumption = [Double]0

        If ($this.ReadPowerConsumption) { 
            ForEach ($Device in $Data.Devices) { $PowerConsumption += [Double]$Device.PSObject.Members.Value.Power }
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