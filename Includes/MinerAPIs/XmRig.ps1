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
File:           \Includes\MinerAPIs\XmRig.ps1
Version:        6.3.9
Version date:   2024/10/17
#>

Class XmRig : Miner { 
    [Void]CreateConfigFiles() { 
        $Parameters = $this.Arguments | ConvertFrom-Json -ErrorAction Ignore

        Try { 
            $ConfigFile = "$(Split-Path $this.Path)\$($Parameters.ConfigFile.FileName)"

            $ThreadsConfig = [PSCustomObject]@{ }
            $ThreadsConfigFile = "$(Split-Path $this.Path)\$($Parameters.ThreadsConfigFileName)"

            If ($Parameters.ConfigFile.Content.threads) { 
                #Write full config file, ignore possible hw change
                $Parameters.ConfigFile.Content | ConvertTo-Json -Depth 10 | Out-File -LiteralPath $ConfigFile -Force -ErrorAction Ignore
            }
            Else { 
                #Check if we have a valid hw file for all installed hardware. If hardware / device order has changed we need to re-create the config files. 
                $ThreadsConfig = [System.IO.File]::ReadAllLines($ThreadsConfigFile) | ConvertFrom-Json -ErrorAction Ignore
                If ($ThreadsConfig.Count -lt 1) { 
                    If (Test-Path -LiteralPath "$(Split-Path $this.Path)\$($this.Algorithms[0] | Select-Object -First 1)-*.json" -PathType Leaf) { 
                        #Remove old config files, thread info is no longer valid
                        Write-Message -Level Warn "Hardware change detected. Deleting existing configuration files for miner '$($this.Info)'."
                        Remove-Item "$(Split-Path $this.Path)\ThreadsConfig-$($this.Algorithms[0] | Select-Object -First 1)-*.json" -Force -ErrorAction Ignore
                    }
                    #Temporarily start miner with pre-config file (without threads config). Miner will then update hw config file with threads info
                    $Parameters.ConfigFile.Content | ConvertTo-Json -Depth 10 | Out-File -LiteralPath $ThreadsConfigFile -Force -ErrorAction Ignore
                    $this.ProcessJob = Invoke-CreateProcess -BinaryPath "$PWD\$($this.Path)" -ArgumentList $Parameters.HwDetectArguments -WorkingDirectory (Split-Path "$PWD\$($this.Path)") -MinerWindowStyle $this.MinerWindowStyle -Priority $this.ProcessPriority -EnvBlock $this.Environment -JobName $this.Info -LogFile $this.LogFile

                    # Sometimes the process cannot be found instantly
                    $Loops = 100
                    Do { 
                        If ($this.ProcessId = ($this.ProcessJob | Receive-Job -Keep | Select-Object -ExpandProperty ProcessId)) { 
                            If (Test-Path -LiteralPath $ThreadsConfigFile -PathType Leaf) { 
                                If ($ThreadsConfig = @([System.IO.File]::ReadAllLines($ThreadsConfigFile) | ConvertFrom-Json -ErrorAction Ignore).threads) { 
                                    If ($this.Type -contains "CPU") { 
                                        ConvertTo-Json -InputObject @($ThreadsConfig | Select-Object -Unique) -Depth 10 | Out-File -LiteralPath $ThreadsConfigFile -Force -Encoding -ErrorAction Ignore
                                    }
                                    Else { 
                                        ConvertTo-Json -InputObject @($ThreadsConfig | Sort-Object -Property Index -Unique) -Depth 10 | Out-File -LiteralPath $ThreadsConfigFile -Force -ErrorAction Ignore
                                    }
                                    Break
                                }
                            }
                        }
                        $Loops --
                        Start-Sleep -Milliseconds 50
                    } While ($Loops -gt 0)
                    Remove-Variable Loops
                }

                If (-not (([System.IO.File]::ReadAllLines($ConfigFile) | ConvertFrom-Json -ErrorAction Ignore).threads)) { 
                    #Threads config in config file is invalid, retrieve from threads config file
                    $ThreadsConfig = [System.IO.File]::ReadAllLines($ThreadsConfigFile) | ConvertFrom-Json
                    If ($ThreadsConfig.Count -ge 1) { 
                        #Write config files. Overwrite because we need to add thread info
                        If ($this.Type -contains "CPU") { 
                            #CPU thread config does not contain index information
                            $Parameters.ConfigFile.Content | Add-Member threads ([Array]($ThreadsConfig * $Parameters.Threads)) -Force
                        }
                        Else { 
                            $Parameters.ConfigFile.Content | Add-Member threads ([Array](($ThreadsConfig.Where({ $Parameters.Devices -contains $_.index }))) * $Parameters.Threads) -Force
                        }
                        $Parameters.ConfigFile.Content | ConvertTo-Json -Depth 10 | Out-File -LiteralPath $ConfigFile -Force -ErrorAction Ignore
                    }
                    Else { 
                        Write-Message -Level Error "Error parsing threads config file - cannot create miner config files for '$($this.Info)' [Error: '$($Error | Select-Object -First 1)']."
                        Return
                    }
                }
            }
        }
        Catch { 
            Write-Message -Level Error "Creating miner config files for '$($this.Info)' failed [Error: '$($Error | Select-Object -First 1)']."
            Return
        }
    }

    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }

        $Request = "http://127.0.0.1:$($this.Port)/api.json"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
            # temp fix for https://github.com/scala-network/XLArig/issues/59
            If ($Data -is [String] -and $Data -match "(?smi)^({.+?`"total`":\s*\[.+?\])") { 
                $Data = "$($Matches[1])}}" | ConvertFrom-Json -ErrorAction Stop
            }
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $HashRate = [PSCustomObject]@{ }
        $HashRateName = [String]$this.Algorithms[0]
        $HashRateValue = [Double]$Data.hashrate.total[0]
        If (-not $HashRateValue) { $HashRateValue = [Double]$Data.hashrate.total[1] } #fix
        If (-not $HashRateValue) { $HashRateValue = [Double]$Data.hashrate.total[2] } #fix
        $HashRate | Add-Member @{ $HashRateName = $HashRateValue }

        $Shares = [PSCustomObject]@{ }
        $SharesAccepted = [Int64]$Data.results.shares_good
        $SharesRejected = [Int64]($Data.results.shares_total - $Data.results.shares_good)
        $SharesInvalid = [Int64]0
        $Shares | Add-Member @{ $HashRateName = @($SharesAccepted, $SharesRejected, $SharesInvalid, ($SharesAccepted + $SharesRejected + $SharesInvalid)) }

        $PowerConsumption = [Double]0

        If ($this.ReadPowerConsumption) { 
            $PowerConsumption = [Double]($Data.hwmon.power | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
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