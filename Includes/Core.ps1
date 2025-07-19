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
File:           Core.ps1
Version:        6.5.1
Version date:   2025/07/19
#>

using module .\Include.psm1

$ErrorLogFile = "Logs\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
If ($Config.Transcript) { Start-Transcript -Path ".\Debug\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)-Transcript_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log" }

$Variables.Miners = [Miner[]]@()
$Variables.Pools = [Pool[]]@()

Try { 
    (Get-ChildItem -Path ".\Includes\MinerAPIs" -File).ForEach({ . $_.FullName })

    Do { 
        # Set master timer
        $Variables.Timer = [DateTime]::Now.ToUniversalTime()

        Write-Message -Level Info "Started new cycle."

        $Variables.CoreLoopCounter ++
        $Variables.EndCycleMessage = ""

        $Variables.BeginCycleTime = $Variables.Timer
        $Variables.EndCycleTime = If ($Variables.EndCycleTime) { $Variables.EndCycleTime.AddSeconds($Config.Interval) } Else { $Variables.BeginCycleTime.AddSeconds($Config.Interval) }

        $Variables.CycleStarts += $Variables.Timer
        $Variables.CycleStarts = @($Variables.CycleStarts | Sort-Object -Bottom (3, ($Config.SyncWindow + 1) | Measure-Object -Maximum).Maximum)

        # Internet connection must be available
        If (-not $Variables.MyIPaddress) { 
            $Message = "No internet connection - will retry in $($Config.Interval) seconds..."
            Write-Message -Level Error $Message
            $Variables.Summary = $Message
            Remove-Variable Message

            Write-Message -Level Info "Ending cycle."

            Clear-PoolData
            Clear-MinerData

            $Variables.RefreshNeeded = $true

            Start-Sleep -Seconds $Config.Interval

            Continue
        }

        # Read config only if config files have changed
        If (Test-Path -Path $Variables.ConfigFile -PathType Leaf) { 
            If ($Variables.ConfigFileReadTimestamp -ne (Get-Item -Path $Variables.ConfigFile -ErrorAction Ignore).LastWriteTime -or $Variables.PoolsConfigFileReadTimestamp -ne (Get-Item -Path $Variables.PoolsConfigFile -ErrorAction Ignore).LastWriteTime) { 
                Read-Config -ConfigFile $Variables.ConfigFile
                Write-Message -Level Verbose "Activated changed configuration."
                $Variables.RefreshNeeded = $true
            }
        }

        If (-not $Config.PoolName) { 
            $Message = "No configured pools - will retry in $($Config.Interval) seconds..."
            Write-Message -Level Warn $Message
            $Variables.Summary = $Message
            Remove-Variable Message

            Clear-PoolData
            Clear-MinerData

            $Variables.RefreshNeeded = $true

            Start-Sleep -Seconds $Config.Interval

            Write-Message -Level Info "Ending cycle."
            Continue
        }

        $Variables.PoolName = $Config.PoolName
        $Variables.PoolsConfig = $Config.PoolsConfig

        # Tuning parameters require local admin rights
        $Variables.ApplyMinerTweaks = $Config.UseMinerTweaks -and $Variables.IsLocalAdmin

        # Miner naming scheme has changed. Must clear all existing miners & watchdog timers due to different miner names
        If ($Variables.Miners -and $Config.BenchmarkAllPoolAlgorithmCombinations -ne $Variables.BenchmarkAllPoolAlgorithmCombinations) { 
            Write-Message -Level Info "Miner naming scheme has changed. Stopping all running miners..."

            Clear-MinerData
        }

        # Use values from config
        $Variables.BenchmarkAllPoolAlgorithmCombinations = $Config.BenchmarkAllPoolAlgorithmCombinations
        $Variables.PoolTimeout = [Math]::Floor($Config.PoolTimeout)

        If ($Variables.EnabledDevices = [Device[]]@($Variables.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Config.ExcludeDeviceName }).ForEach({ $_ | Select-Object -Property * }))) { 
            # Update enabled devices
            $Variables.EnabledDevices.ForEach(
                { 
                    # Miner name must not contain spaces
                    $_.Model = $_.Model -replace " "
                    If ($_.Type -eq "GPU") { 
                        # For GPUs set type equal to vendor
                        $_.Type = $_.Vendor
                    }
                }
            )

            # Power cost preparations
            If ($Variables.CalculatePowerCost = $Config.CalculatePowerCost) { 
                If ($Variables.EnabledDevices.Count -ge 1) { 
                    # HWiNFO64 verification
                    $RegistryPath = "HKCU:\Software\HWiNFO64\VSB"
                    If ($RegValue = Get-ItemProperty -Path $RegistryPath -ErrorAction Ignore) { 
                        $HWiNFO64RegTime = Get-RegTime "HKCU:\Software\HWiNFO64\VSB"
                        If ($Variables.HWiNFO64RegTime -eq $HWiNFO64RegTime.AddSeconds(5)) { 
                            Write-Message -Level Warn "Power consumption data in registry has not been updated since $($Variables.HWiNFO64RegTime.ToString("yyyy-MM-dd HH:mm:ss")) [HWiNFO64 not running???] - disabling power consumption readout and profit calculations."
                            $Variables.CalculatePowerCost = $false
                        }
                        Else { 
                            $Variables.HWiNFO64RegTime = $HWiNFO64RegTime
                            $PowerConsumptionData = @{ }
                            $DeviceName = ""
                            $RegValue.PSObject.Properties.Where({ $_.Name -match "^Label[0-9]+$" -and (Compare-Object @($_.Value -split " " | Select-Object) @($Variables.EnabledDevices.Name) -IncludeEqual -ExcludeDifferent) }).ForEach(
                                { 
                                    $DeviceName = ($_.Value -split " ")[-1]
                                    Try { 
                                        $PowerConsumptionData[$DeviceName] = $RegValue.($_.Name -replace "Label", "Value")
                                    }
                                    Catch { 
                                        Write-Message -Level Warn "HWiNFO64 sensor naming is invalid [duplicate sensor for $DeviceName] - disabling power consumption and profit calculations."
                                        $Variables.CalculatePowerCost = $false
                                    }
                                }
                            )
                            # Add configured power consumption
                            $Variables.Devices.Name.ForEach(
                                { 
                                    $DeviceName = $_
                                    If ($ConfiguredPowerConsumption = $Config.PowerConsumption.$_ -as [Double]) { 
                                        If ($Variables.EnabledDevices.Name -contains $_ -and -not $PowerConsumptionData.$_) { Write-Message -Level Info "HWiNFO64 cannot read power consumption data for device ($_). Using configured value of $ConfiguredPowerConsumption W." }
                                        $PowerConsumptionData[$_] = "$ConfiguredPowerConsumption W"
                                    }
                                    $Variables.EnabledDevices.Where({ $_.Name -eq $DeviceName }).ForEach({ $_.ConfiguredPowerConsumption = $ConfiguredPowerConsumption })
                                    $Variables.Devices.Where({ $_.Name -eq $DeviceName }).ForEach({ $_.ConfiguredPowerConsumption = $ConfiguredPowerConsumption })
                                }
                            )
                            If ($DeviceNamesMissingSensor = (Compare-Object @($Variables.EnabledDevices.Name) @($PowerConsumptionData.psBase.Keys) -PassThru).Where({ $_.SideIndicator -eq "<=" })) { 
                                Write-Message -Level Warn "HWiNFO64 sensor naming is invalid [missing sensor configuration for $($DeviceNamesMissingSensor -join ", ")] - disabling power consumption and profit calculations."
                                $Variables.CalculatePowerCost = $false
                            }

                            # Enable read power consumption for configured devices
                            $Variables.EnabledDevices.ForEach({ $_.ReadPowerConsumption = $PowerConsumptionData.psBase.Keys -contains $_.Name })
                            Remove-Variable ConfiguredPowerConsumption, DeviceName, DeviceNamesMissingSensor, PowerConsumptionData, HWiNFO64RegTime -ErrorAction Ignore
                        }
                    }
                    Else { 
                        Write-Message -Level Warn "Cannot read power consumption data from registry [Key '$RegistryPath' does not exist - HWiNFO64 not running???] - disabling power consumption and profit calculations."
                        $Variables.CalculatePowerCost = $false
                    }
                    Remove-Variable RegistryPath, RegValue -ErrorAction Ignore
                }
                Else { $Variables.CalculatePowerCost = $false }
            }
            If (-not $Variables.CalculatePowerCost ) { $Variables.EnabledDevices.ForEach({ $_.ReadPowerConsumption = $false }) }

            # Power price
            If (-not $Config.PowerPricekWh.psBase.Keys) { $Config.PowerPricekWh."00:00" = 0 }
            ElseIf ($null -eq $Config.PowerPricekWh."00:00") { 
                # 00:00h power price is the same as the latest price of the previous day
                $Config.PowerPricekWh."00:00" = $Config.PowerPricekWh.($Config.PowerPricekWh.psBase.Keys | Sort-Object -Bottom 1)
            }
            $Variables.PowerPricekWh = [Double]($Config.PowerPricekWh.($Config.PowerPricekWh.psBase.Keys.Where({ $_ -le (Get-Date -Format HH:mm).ToString() }) | Sort-Object -Bottom 1))
            $Variables.PowerCostBTCperW = [Double](1 / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates.BTC.($Config.FIATcurrency))

            # Core suspended with <Ctrl><Alt>P in MainLoop
            While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

            # Set minimum Watchdog count 3
            $Variables.WatchdogCount = (3, $Config.WatchdogCount | Measure-Object -Maximum).Maximum

            # Expire watchdog timers
            $Variables.WatchdogReset = $Variables.WatchdogCount * $Variables.WatchdogCount * $Variables.WatchdogCount * $Variables.WatchdogCount * $Config.Interval
            If ($Config.Watchdog) { $Variables.WatchdogTimers = $Variables.WatchdogTimers.Where({ $_.Kicked -ge $Variables.Timer.AddSeconds(- $Variables.WatchdogReset) }) }
            Else { $Variables.WatchdogTimers = [System.Collections.Generic.List[PSCustomObject]]::new() }

            # Load unprofitable algorithms
            Try { 
                If (-not $Variables.UnprofitableAlgorithmsTimestamp -or (Get-ChildItem -Path ".\Data\UnprofitableAlgorithms.json").LastWriteTime -gt $Variables.UnprofitableAlgorithmsTimestamp) { 
                    $Variables.UnprofitableAlgorithms = [System.IO.File]::ReadAllLines("$PWD\Data\UnprofitableAlgorithms.json") | ConvertFrom-Json -ErrorAction Stop -AsHashtable | Get-SortedObject
                    Write-Message -Level Info "$(If ($Variables.UnprofitableAlgorithmsTimestamp) { "Updated" } Else { "Loaded" }) list of unprofitable algorithms ($($Variables.UnprofitableAlgorithms.Count) $(If ($Variables.UnprofitableAlgorithms.Count -ne 1) { "entries" } Else { "entry" }))."
                    $Variables.UnprofitableAlgorithmsTimestamp = (Get-ChildItem -Path ".\Data\UnprofitableAlgorithms.json").LastWriteTime
                }
            }
            Catch { 
                Write-Message -Level Error "Error loading list of unprofitable algorithms. File '.\Data\UnprofitableAlgorithms.json' is not a valid $($Variables.Branding.ProductLabel) JSON data file. Please restore it from your original download."
                $Variables.Remove("UnprofitableAlgorithms")
                $Variables.Remove("UnprofitableAlgorithmsTimestamp")
            }

            If ($Config.Donation -gt 0) { 
                If (-not $Variables.DonationStart) { 
                    # Re-Randomize donation start and data once per day
                    If ((Get-Item -Path "$PWD\Logs\DonationLog.csv" -ErrorAction Ignore).LastWriteTime -lt [DateTime]::Today) { 
                        # Do not donate if remaing time for today is less than donation duration
                        If ($Config.Donation -lt (1440 - [Math]::Floor([DateTime]::Now.TimeOfDay.TotalMinutes))) { $Variables.DonationStart = [DateTime]::Now.AddMinutes((Get-Random -Minimum 0 -Maximum (1440 - [Math]::Floor([DateTime]::Now.TimeOfDay.TotalMinutes) - $Config.Donation))) }
                    }
                }

                If ($Variables.DonationStart -and [DateTime]::Now -ge $Variables.DonationStart) { 
                    If (-not $Variables.DonationEnd) { 
                        $Variables.DonationStart = [DateTime]::Now
                        # Add pool config to config (in-memory only)
                        $Variables.DonationRandomPoolsConfig = Get-RandomDonationPoolsConfig
                        # Ensure full donation period
                        $Variables.DonationEnd = $Variables.DonationStart.AddMinutes($Config.Donation)
                        $Variables.EndCycleTime = ($Variables.DonationEnd).ToUniversalTime()
                        Write-Message -Level Info "Donation run: Mining for '$($Variables.DonationRandom.Name)' for the next $(If (($Config.Donation - ([DateTime]::Now - $Variables.DonationStart).Minutes) -gt 1) { "$($Config.Donation - ([DateTime]::Now - $Variables.DonationStart).Minutes) minutes" } Else { "minute" })."
                        $Variables.DonationRunning = $true
                    }
                }
            }

            If ($Variables.DonationRunning) { 
                If ($Config.Donation -gt 0 -and [DateTime]::Now -lt $Variables.DonationEnd) { 
                    # Use donation pool config, use same pool variant to avoid extra benchmarking
                    $Variables.PoolName = $Config.PoolName.Where({ (Get-PoolBaseName $_) -in $Variables.DonationRandomPoolsConfig.Keys})
                    $Variables.PoolsConfig = $Variables.DonationRandomPoolsConfig
                }
                Else { 
                    # Donation end
                    $Variables.DonationLog = $Variables.DonationLog | Select-Object -Last 365 # Keep data for one year
                    [Array]$Variables.DonationLog += [PSCustomObject]@{ 
                        Start = $Variables.DonationStart
                        End   = $Variables.DonationEnd
                        Name  = $Variables.DonationRandom.Name
                    }
                    $Variables.DonationLog | Export-CSV -LiteralPath ".\Logs\DonationLog.csv" -Force -ErrorAction Ignore
                    $Variables.DonationRandomPoolsConfig = $null
                    $Variables.DonationStart = $null
                    $Variables.DonationEnd = $null
                    Write-Message -Level Info "Donation run complete - thank you! Mining for you again. :-)"
                    $Variables.DonationRunning = $false
                }
            }

            # Skip some stuff when
            # - Configuration unchanged
            # - and we have pools
            # - and the previous cycle was less than half a cycle duration
            If ($Variables.ConfigReadTimestamp -gt $Variables.Timer -or -not $Variables.Pools -or $Variables.PoolDataCollectedTimeStamp.AddSeconds($Config.Interval / 2) -lt $Variables.Timer) { 

                # Check for new version
                If ($Config.AutoUpdateCheckInterval -and $Variables.CheckedForUpdate -lt [DateTime]::Now.AddDays(-$Config.AutoUpdateCheckInterval)) { Get-Version }

                # Stop / Start brain background jobs
                If ($BrainsToStop = (Compare-Object @(Get-PoolBaseName $Config.PoolName | Select-Object) @(Get-PoolBaseName $Variables.PoolName | Select-Object) | Where-Object SideIndicator -EQ "=>").InputObject) { Stop-Brain $BrainsToStop }
                Remove-Variable BrainsToStop

                Start-Brain @(Get-PoolBaseName $Variables.PoolName)

                # Core suspended with <Ctrl><Alt>P in MainLoop
                While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

                # Remove stats that have been deleted from disk
                Try { 
                    If ($StatFiles = [String[]](Get-ChildItem -Path "Stats" -File).BaseName) { 
                        If ($Keys = [String[]]($Stats.psBase.Keys)) { 
                            (Compare-Object $StatFiles $Keys -PassThru).Where({ $_.SideIndicator -eq "=>" }).ForEach(
                                { 
                                    # Remove stat if deleted on disk
                                    $Stats.Remove($_)
                                }
                            )
                        }
                    }
                }
                Catch {}
                Remove-Variable Keys, StatFiles -ErrorAction Ignore

                # Read latest DAG data from web
                $Variables.DAGdata = Get-AllDAGdata $Variables.DAGdata

                # Core suspended with <Ctrl><Alt>P in MainLoop
                While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

                # Collect pool data
                If ($Variables.PoolName) { 
                    $Variables.PoolsCount = $Variables.Pools.Count

                    # Wait for pool data message
                    If ($Variables.Brains.psBase.Keys.Where({ $Variables.Brains[$_].StartTime -gt $Variables.Timer.AddSeconds(- $Config.Interval) })) { 
                        # Newly started brains, allow extra time for brains to get ready
                        $Variables.PoolTimeout = 60
                        $Message = "Loading initial pool data from $((Get-PoolBaseName $Variables.PoolName) -join ", " -replace ",([^,]*)$", " &`$1").<br>This may take up to $($Variables.PoolTimeout) seconds..."
                        If (-not $Variables.Miners) { 
                            $Variables.Summary = $Message
                            $Variables.RefreshNeeded = $true
                        }
                        Write-Message -Level Info ($Message -replace "<br>", " ")
                        Remove-Variable Message
                    }
                    Else { 
                        Write-Message -Level Info "Loading pool data from $((Get-PoolBaseName $Variables.PoolName) -join ", " -replace ",([^,]*)$", " &`$1")..."
                    }

                    # Wait for all brains
                    $PoolDataCollectedTimeStamp = If ($Variables.PoolDataCollectedTimeStamp) { $Variables.PoolDataCollectedTimeStamp } Else { $Variables.ScriptStartTime }
                    While ([DateTime]::Now.ToUniversalTime() -lt $Variables.Timer.AddSeconds($Variables.PoolTimeout) -and ($Variables.Brains.psBase.Keys.Where({ $Variables.Brains[$_].Updated -lt $PoolDataCollectedTimeStamp }))) { 
                        Start-Sleep -Seconds 1
                    }
                    Remove-Variable PoolDataCollectedTimeStamp

                    $Variables.Remove("PoolsNew")
                    $Variables.PoolsNew = $Variables.PoolName.ForEach(
                        { 
                            $PoolName = Get-PoolBaseName $_
                            If (Test-Path -LiteralPath ".\Pools\$PoolName.ps1") { 
                                Try { 
                                    Write-Message -Level Debug "Pool definition file '$PoolName': Start building pool objects"
                                    & ".\Pools\$PoolName.ps1" -PoolVariant $_
                                    Write-Message -Level Debug "Pool definition file '$PoolName': End building pool objects"
                                }
                                Catch { 
                                    Write-Message -Level Error "Error in pool file 'Pools\$PoolName.ps1'."
                                    "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $ErrorLogFile
                                    $_.Exception | Format-List -Force >> $ErrorLogFile
                                    $_.InvocationInfo | Format-List -Force >> $ErrorLogFile
                                }
                            }
                        }
                    ).ForEach(
                        { 
                            $Pool = [Pool]$_
                            $Pool.CoinName = $Variables.CoinNames[$Pool.Currency]
                            $Pool.Fee = If ($Config.IgnorePoolFee -or $Pool.Fee -lt 0 -or $Pool.Fee -gt 1) { 0 } Else { $Pool.Fee }
                            $Factor = $Pool.EarningsAdjustmentFactor * (1 - $Pool.Fee)
                            $Pool.Price *= $Factor
                            $Pool.Price_Bias = $Pool.Price * $Pool.Accuracy
                            $Pool.StablePrice *= $Factor
                            $Pool
                        }
                    )
                    Remove-Variable Factor, Pool, PoolName -ErrorAction Ignore

                    If ($PoolsWithoutData = Compare-Object -PassThru @($Variables.PoolName) @($Variables.PoolsNew.Variant | Sort-Object -Unique)) { Write-Message -Level Warn "No data received from pool$(If ($PoolsWithoutData.Count -gt 1) { "s" }) $($PoolsWithoutData -join ", " -replace ",([^,]*)$", " &`$1")." }
                    Remove-Variable PoolsWithoutData
                    $Variables.PoolDataCollectedTimeStamp = [DateTime]::Now.ToUniversalTime()

                    # Expire pools that have not been updated for 1 day
                    $Timestamp = [DateTime]::Now.ToUniversalTime().AddHours(-24)
                    $Variables.PoolsExpired = $Variables.Pools.Where({ $_.Updated -lt $Timestamp })
                    $Variables.Pools = $Variables.Pools.Where({ $_.Updated -ge $Timestamp })
                    Remove-Variable Timestamp

                    # Count deconfigured pools
                    $PoolsDeconfiguredCount = $Variables.Pools.Where({ $_.Variant -notin $Variables.PoolName }).Count

                    If ($Pools = Compare-Object -PassThru @($Variables.PoolsNew | Select-Object) @($Variables.Pools.Where({ $Variables.PoolName -contains $_.Variant }) | Select-Object) -Property Algorithm, Variant -IncludeEqual) { 
                        # Find added & updated pools
                        $Variables.PoolsAdded = $Pools.Where({ $_.SideIndicator -eq "<=" })
                        $Variables.PoolsUpdated = $Pools.Where({ $_.SideIndicator -eq "==" })

                        $Pools.ForEach({ $_.PSObject.Properties.Remove("SideIndicator") })

                        # Reduce accuracy on older pool data
                        $Pools.Where({ $_.Updated -lt $Variables.CycleStarts[0] }).ForEach({ $_.Price_Bias *= [Math]::Pow(0.9, ($Variables.CycleStarts[0] - $_.Updated).TotalMinutes) })

                        $Pools.ForEach(
                            { 
                                $_.Best = $false
                                $_.Prioritize = $false

                                # PoolPorts[0] = non-SSL, PoolPorts[1] = SSL; must cast to array
                                $_.PoolPorts = @($(If ($Config.SSL -ne "Always" -and $_.Port) { [UInt16]$_.Port } Else { $null }), $(If ($Config.SSL -ne "Never" -and $_.PortSSL) { [UInt16]$_.PortSSL } Else { $null }))

                                If ($_.Algorithm -match $Variables.RegexAlgoHasDAG) { 
                                    If (-not $Variables.PoolData.($_.Name).ProfitSwitching -and $Variables.DAGdata.Currency.($_.Currency).BlockHeight) { 
                                        $_.BlockHeight = $Variables.DAGdata.Currency.($_.Currency).BlockHeight
                                        $_.DAGSizeGiB  = $Variables.DAGdata.Currency.($_.Currency).DAGsize / 1GB 
                                        $_.Epoch       = $Variables.DAGdata.Currency.($_.Currency).Epoch
                                    }
                                    ElseIf ($Variables.DAGdata.Algorithm.($_.Algorithm).BlockHeight) { 
                                        $_.BlockHeight = $Variables.DAGdata.Algorithm.($_.Algorithm).BlockHeight
                                        $_.DAGSizeGiB  = $Variables.DAGdata.Algorithm.($_.Algorithm).DAGsize / 1GB
                                        $_.Epoch       = $Variables.DAGdata.Algorithm.($_.Algorithm).Epoch
                                    }
                                }
                                If ($_.Algorithm -match $Variables.RegexAlgoHasDynamicDAG -and $_.DAGSizeGiB) { 
                                    $_.AlgorithmVariant = "$($_.Algorithm)($([Math]::Ceiling($_.DAGSizeGiB))GiB)"
                                }
                                Else { 
                                    $_.AlgorithmVariant = $_.Algorithm
                                }
                            }
                        )

                        # Pool disabled by stat file
                        $Pools.Where({ $_.Disabled }).ForEach({ $_.Reasons.Add("Disabled (by stat file)") | Out-Null })
                        # Min accuracy not reached
                        $Pools.Where({ $_.Accuracy -lt $Config.MinAccuracy }).ForEach({ $_.Reasons.Add("MinAccuracy ($($Config.MinAccuracy * 100)%) not reached") | Out-Null })
                        # Filter unavailable algorithms
                        If ($Config.MinerSet -lt 3) { $Pools.Where({ $Variables.UnprofitableAlgorithms[$_.Algorithm] -eq "*" }).ForEach({ $_.Reasons.Add("Unprofitable algorithm") | Out-Null }) }
                        # Pool price 0
                        $Pools.Where({ $_.Price -eq 0 -and -not ($Variables.PoolsConfig[$_.Name].PoolAllow0Price -or $Config.PoolAllow0Price) }).ForEach({ $_.Reasons.Add("Price -eq 0") | Out-Null })
                        # No price data
                        $Pools.Where({ [Double]::IsNaN($_.Price) }).ForEach({ $_.Reasons.Add("Price information not available") | Out-Null })
                        # Ignore pool if price is more than $Config.UnrealPoolPriceFactor higher than the medium price of all pools with same algorithm; NiceHash & MiningPoolHub are always right
                        If ($Config.UnrealPoolPriceFactor -gt 1) { 
                            ($Pools.Where({ $_.Price_Bias -gt 0 }) | Group-Object -Property Algorithm).Where({ $_.Count -gt 3 }).ForEach(
                                { 
                                    If ($PriceThreshold = (Get-Median $_.Group.Price_Bias) * $Config.UnrealPoolPriceFactor) { 
                                        $_.Group.Where({ $_.Name -notin @("NiceHash", "MiningPoolHub") -and $_.Price_Bias -gt $PriceThreshold }).ForEach({ $_.Reasons.Add("Unreal price ($($Config.UnrealPoolPriceFactor)x higher than median price)") | Out-Null })
                                    }
                                }
                            )
                            Remove-Variable PriceThreshold -ErrorAction Ignore
                        }
                        # Per pool config algorithm filter
                        $Pools.Where({ $Config.PoolsConfig[$_.Name].Algorithm -like "+*" -and $Config.PoolsConfig[$_.Name].Algorithm -split "," -notcontains "+$($_.AlgorithmVariant)" -and $Config.PoolsConfig[$_.Name].Algorithm -split "," -notcontains "+$($_.Algorithm)" }).ForEach({ $_.Reasons.Add("Algorithm not enabled in $($_.Name) pool config") | Out-Null })
                        $Pools.Where({ $Config.PoolsConfig[$_.Name].Algorithm -split "," -contains "-$($_.Algorithm)" -or $Config.PoolsConfig[$_.Name].Algorithm -split "," -contains "-$($_.AlgorithmVariant)" }).ForEach({ $_.Reasons.Add("Algorithm disabled (``-$($_.Algorithm)`` in $($_.Name) pool config)") | Out-Null })
                        # Filter non-enabled algorithms
                        If ($Config.Algorithm -like "+*") { 
                            $Pools.Where({ $Config.Algorithm -split "," -notcontains "+$($_.Algorithm)" -and $Config.Algorithm -split "," -notcontains "+$($_.AlgorithmVariant)" }).ForEach({ $_.Reasons.Add("Algorithm not enabled in generic config") | Out-Null })
                        }
                        # Filter disabled algorithms
                        ElseIf ($Config.Algorithm -like "-*") { 
                            $Pools.Where({ $Config.Algorithm -split "," -contains "-$($_.Algorithm)" }).ForEach({ $_.Reasons.Add("Algorithm disabled (``-$($_.Algorithm)`` in generic config)") | Out-Null })
                            $Pools.Where({ $Config.Algorithm -split "," -contains "-$($_.AlgorithmVariant)" }).ForEach({ $_.Reasons.Add("Algorithm disabled (``-$($_.AlgorithmVariant)`` in generic config)") | Out-Null })
                        }
                        # Per pool config currency filter
                        $Pools.Where({ $Variables.PoolsConfig[$_.Name].Currency -like "+*" -and $Variables.PoolsConfig[$_.Name].Currency -split "," -notcontains "+$($_.Currency)" }).ForEach({ $_.Reasons.Add("Currency not enabled in $($_.Name) pool config") | Out-Null })
                        $Pools.Where({ $Variables.PoolsConfig[$_.Name].Currency -split "," -contains "-$($_.Currency)" }).ForEach({ $_.Reasons.Add("Currency disabled (``-$($_.Currency)`` in $($_.Name) pool config)") | Out-Null })
                        # Filter non-enabled currencies
                        If ($Config.Currency -like "+*") { $Pools.Where({ $Config.Currency -split "," -notcontains "+$($_.Currency)" }).ForEach({ $_.Reasons.Add("Currency not enabled in generic config") | Out-Null }) }
                        # Filter disabled currencies
                        ElseIf ($Config.Currency -like "-*") { $Pools.Where({ $Config.Currency -split "," -contains "-$($_.Currency)" }).ForEach({ $_.Reasons.Add("Currency disabled (``-$($_.Currency)`` in generic config)") | Out-Null }) }
                        # MinWorkers
                        $Pools.Where({ $null -ne $_.Workers -and $_.Workers -lt $Variables.PoolsConfig[$_.Name].MinWorkers }).ForEach({ $_.Reasons.Add("Not enough workers at pool (MinWorker ``$($Variables.PoolsConfig[$_.Name].MinWorker)`` in $($_.Name) pool config)") | Out-Null })
                        $Pools.Where({ $null -ne $_.Workers -and $_.Workers -lt $Config.MinWorker -and $Variables.PoolsConfig[$_.Name].MinWorkers -ne 0 -and $Variables.PoolsConfig[$_.Name].MinWorkers -lt $Config.MinWorker }).ForEach({ $_.Reasons.Add("Not enough workers at pool (MinWorker ``$($Config.MinWorker)`` in generic config)") | Out-Null })
                        # SSL
                        $Pools.Where({ $Variables.PoolsConfig[$_.Name].SSL -eq "Never" }).ForEach({ $_.PoolPorts[1] = $null })
                        $Pools.Where({ $Variables.PoolsConfig[$_.Name].SSL -eq "Always" }).ForEach({ $_.PoolPorts[0] = $null })
                        $Pools.Where({ $Variables.PoolsConfig[$_.Name].SSL -eq "Never" -and -not $_.PoolPorts[0] }).ForEach({ $_.Reasons.Add("Non-SSL port not available (SSL -eq 'Never' in $($_.Name) pool config)") | Out-Null })
                        $Pools.Where({ $Variables.PoolsConfig[$_.Name].SSL -eq "Always" -and -not $_.PoolPorts[1] }).ForEach({ $_.Reasons.Add("SSL port not available (SSL -eq 'Always' in $($_.Name) pool config)") | Out-Null })
                        If ($Config.SSL -eq "Never") { $Pools.Where({ -not $_.PoolPorts[0] -and $_.Reasons -notmatch "Non-SSL port not available .+" }).ForEach({ $_.Reasons.Add("Non-SSL port not available (SSL -eq 'Never' in generic config)") | Out-Null }) }
                        ElseIf ($Config.SSL -eq "Always") { $Pools.Where({ -not $_.PoolPorts[1] -and $_.Reasons -notmatch "SSL port not available .+" }).ForEach({ $_.Reasons.Add("SSL port not available (SSL -eq 'Always' in generic config)") | Out-Null }) }
                        # SSL Allow selfsigned certificate
                        $Pools.Where({ $_.SSLselfSignedCertificate -and $null -ne $Variables.PoolsConfig[$_.Name].SSLallowSelfSignedCertificate -and $Variables.PoolsConfig[$_.Name].SSLallowSelfSignedCertificate -eq $false }).ForEach({ $_.Reasons.Add("Pool uses self signed certificate (SSLallowSelfSignedCertificate -eq '`$false' in $($_.Name) pool config)") | Out-Null })
                        If (-not $Config.SSLallowSelfSignedCertificate) { $Pools.Where({ $_.SSLselfSignedCertificate -and $null -eq $Variables.PoolsConfig[$_.Name].SSLallowSelfSignedCertificate }).ForEach({ $_.Reasons.Add("Pool uses self signed certificate (SSLallowSelfSignedCertificate -eq '`$false' in generic config)") | Out-Null }) }
                        # At least one port (SSL or non-SSL) must be available
                        $Pools.Where({ -not ($_.PoolPorts | Select-Object) }).ForEach({ $_.Reasons.Add("No ports available") | Out-Null })
                        # Apply watchdog to pools
                        If ($Pools.Count) { $Pools = Update-PoolWatchdog -Pools $Pools }
                        # Second best pools per algorithm
                        ($Pools.Where({ -not $_.Reasons.Count }) | Group-Object -Property AlgorithmVariant, Name).ForEach({ ($_.Group | Sort-Object -Property Price_Bias -Descending | Select-Object -Skip 1).ForEach({ $_.Reasons.Add("Second best algorithm") | Out-Null }) })

                        # Make pools unavailable
                        $Pools.ForEach({ $_.Available = -not $_.Reasons.Count })

                        # Filter pools on miner set
                        If ($Config.MinerSet -le 2) { 
                            $Pools.Where({ $Variables.UnprofitableAlgorithms[$_.Algorithm] -eq 1 }).ForEach({ $_.Reasons.Add("Unprofitable primary algorithm") | Out-Null })
                            $Pools.Where({ $Variables.UnprofitableAlgorithms[$_.Algorithm] -eq 2 }).ForEach({ $_.Reasons.Add("Unprofitable secondary algorithm") | Out-Null })
                        }

                        $Message = If ($Variables.Pools.Count -gt 0) { "Had $($Variables.PoolsCount) pool$(If ($Variables.PoolsCount -ne 1) { "s" }) from previous run" } Else { "Loaded $($Variables.PoolsNew.Count) pool$(If ($Variables.PoolsNew.Count -ne 1) { "s" })" }
                        If ($Variables.PoolsExpired.Count) { $Message += ", expired $($Variables.PoolsExpired.Count) pool$(If ($Variables.PoolsExpired.Count -gt 1) { "s" })" }
                        If ($PoolsDeconfiguredCount) { $Message += ", removed $PoolsDeconfiguredCount deconfigured pool$(If ($PoolsDeconfiguredCount -gt 1) { "s" })" }
                        If ($Variables.Pools.Count -and $Variables.PoolsAdded.Count) { $Message += ", found $($Variables.PoolsAdded.Count) new pool$(If ($Variables.PoolsAdded.Count -ne 1) { "s" })" }
                        If ($Variables.PoolsUpdated.Count) { $Message += ", updated $($Variables.PoolsUpdated.Count) existing pool$(If ($Variables.PoolsUpdated.Count -ne 1) { "s" })" }
                        If ($Pools.Where({ -not $_.Available })) { $Message += ", filtered out $(@($Pools.Where({ -not $_.Available })).Count) pool$(If (@($Pools.Where({ -not $_.Available })).Count -ne 1) { "s" })" }
                        $Message += ". $(@($Pools.Where({ $_.Available })).Count) available pool$(If (@($Pools.Where({ $_.Available })).Count -ne 1) { "s" }) remain$(If (@($Pools.Where({ $_.Available })).Count -eq 1) { "s" })."
                        Write-Message -Level Info $Message
                        Remove-Variable Message

                        # Keep pool balances alive; force mining at pool even if it is not the best for the algo
                        If ($Config.BalancesKeepAlive -and $Global:BalancesTrackerRunspace -and $Variables.PoolsLastEarnings.Count -gt 0 -and $Variables.PoolsLastUsed) { 
                            $Variables.PoolNamesToKeepBalancesAlive = @()
                            ForEach ($Pool in @($Pools.Where({ $_.Name -notin $Config.BalancesTrackerExcludePool }) | Sort-Object -Property Name -Unique)) { 
                                If ($Variables.PoolsLastEarnings[$Pool.Name] -and $Variables.PoolsConfig[$Pool.Name].BalancesKeepAlive -gt 0 -and ([DateTime]::Now.ToUniversalTime() - $Variables.PoolsLastEarnings[$Pool.Name]).Days -ge ($Variables.PoolsConfig[$Pool.Name].BalancesKeepAlive - 10)) { 
                                    $Variables.PoolNamesToKeepBalancesAlive += $Pool.Name
                                    Write-Message -Level Warn "Pool '$($Pool.Name)' prioritized to avoid forfeiting balance (pool would clear balance in 10 days)."
                                }
                            }
                            Remove-Variable Pool

                            If ($Variables.PoolNamesToKeepBalancesAlive) { 
                                $Pools.ForEach(
                                    { 
                                        If ($Variables.PoolNamesToKeepBalancesAlive -contains $_.Name) { $_.Available = $true; $_.Prioritize = $true }
                                        Else { $_.Reasons.Add("BalancesKeepAlive prioritizes other pools") | Out-Null }
                                    }
                                )
                            }
                        }


                        # Mark best pools, allow all DAG pools (optimal pool might not fit in GPU memory)
                        ($Pools.Where({ $_.Available }) | Group-Object -Property Algorithm).ForEach({ ($_.Group | Sort-Object -Property Prioritize, Price_Bias -Bottom $(If ($Config.MinerUseBestPoolsOnly -or $_.Group.Algorithm -notmatch $Variables.RegexAlgoHasDAG) { 1 } Else { $_.Group.Count })).ForEach({ $_.Best = $true }) })
                    }
                    $Variables.PoolsUpdatedTimestamp = [DateTime]::Now.ToUniversalTime()

                    # Update data in API
                    $Variables.Pools = $Pools
                    $Variables.PoolsBest = $Variables.Pools.Where({ $_.Best }) | Sort-Object -Property Algorithm

                    Remove-Variable Pools, PoolsDeconfiguredCount, PoolsExpiredCount -ErrorAction Ignore

                    # Core suspended with <Ctrl><Alt>P in MainLoop
                    While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

                }
            }
            If (-not $Variables.PoolsBest) { 
                $Message = "No minable pools - will retry in $($Config.Interval) seconds..."
                Write-Message -Level Warn $Message
                $Variables.Summary = $Message
                Remove-Variable Message

                Clear-PoolData
                Clear-MinerData

                $Variables.RefreshNeeded = $true

                Start-Sleep -Seconds $Config.Interval

                Write-Message -Level Info "Ending cycle."
                Continue
            }

            If ($Variables.DonationRunning) { 
                $Variables.EndCycleTime = ($Variables.DonationEnd).ToUniversalTime()
            }

            # Ensure we get the hashrate for running miners prior looking for best miner
            ForEach ($Miner in $Variables.MinersBest) { 
                If ($Miner.DataReaderJob.HasMoreData -and $Miner.Status -ne [MinerStatus]::DryRun) { 
                    If ($Samples = @($Miner.DataReaderJob | Receive-Job).Where({ $_.Date })) { 
                        $Sample = $Samples[-1]
                        If ([Math]::Floor(($Sample.Date - $Miner.ValidDataSampleTimestamp).TotalSeconds) -ge 0) { $Samples.Where({ $_.Hashrate.PSObject.Properties.Value -notcontains 0 }).ForEach({ $Miner.Data.Add($_) | Out-Null }) }
                        $Miner.Hashrates_Live = $Sample.Hashrate.PSObject.Properties.Value
                        # Hashrate from primary algorithm is relevant
                        If ($Sample.Hashrate.($Miner.Algorithms[0])) { $Miner.DataSampleTimestamp = $Sample.Date }
                    }
                    Remove-Variable Sample, Samples -ErrorAction Ignore
                }
                If ($Miner.Data.Count -gt $Miner.MinDataSample * 5) { $Miner.Data = [System.Collections.Generic.List[PSCustomObject]]($Miner.Data | Select-Object -Last ($Miner.MinDataSample * 5)) } # Reduce data to MinDataSample * 5

                If ([MinerStatus]::DryRun, [MinerStatus]::Running -contains $Miner.Status) { 
                    If ($Miner.Status -eq [MinerStatus]::DryRun -or $Miner.GetStatus() -eq [MinerStatus]::Running) { 
                        $Miner.ContinousCycle ++
                        If ($Config.Watchdog) { 
                            ForEach ($Worker in $Miner.WorkersRunning) { 
                                If ($WatchdogTimer = $Variables.WatchdogTimers.Where({ $_.MinerName -eq $Miner.Name -and $_.PoolName -eq $Worker.Pool.Name -and $_.PoolRegion -eq $Worker.Pool.Region -and $_.Algorithm -eq $Worker.Pool.Algorithm }) | Sort-Object -Property Kicked -Bottom 1) { 
                                    # Update watchdog timer
                                    $WatchdogTimer.Kicked = [DateTime]::Now.ToUniversalTime()
                                }
                                Else { 
                                    # Create watchdog timer in case it got cleared
                                    $Variables.WatchdogTimers.Add(
                                        [PSCustomObject]@{ 
                                            Algorithm                    = $Worker.Pool.Algorithm
                                            AlgorithmVariant             = $Worker.Pool.AlgorithmVariant
                                            CommandLine                  = $Miner.CommandLine
                                            DeviceNames                  = $Miner.DeviceNames
                                            Kicked                       = [DateTime]::Now.ToUniversalTime()
                                            MinerBaseName                = $Miner.BaseName
                                            MinerBaseName_Version        = $Miner.BaseName_Version
                                            MinerBaseName_Version_Device = $Miner.BaseName_Version_Device
                                            MinerName                    = $Miner.Name
                                            MinerVersion                 = $Miner.Version
                                            PoolKey                      = $Worker.Pool.Key
                                            PoolName                     = $Worker.Pool.Name
                                            PoolRegion                   = $Worker.Pool.Region
                                            PoolVariant                  = $Worker.Pool.Variant
                                        }
                                    )
                                }
                            }
                            Remove-Variable WatchdogTimer, Worker -ErrorAction Ignore
                        }
                        If ($Miner.Status -eq [MinerStatus]::Running -and $Config.BadShareRatioThreshold -gt 0) { 
                            If ($Shares = ($Miner.Data | Select-Object -Last 1).Shares) { 
                                ForEach ($Algorithm in $Miner.Algorithms) { 
                                    If ($Shares.$Algorithm -and $Shares.$Algorithm[1] -gt 0 -and $Shares.$Algorithm[3] -gt [Math]::Floor(1 / $Config.BadShareRatioThreshold) -and $Shares.$Algorithm[1] / $Shares.$Algorithm[3] -gt $Config.BadShareRatioThreshold) { 
                                        $Miner.StatusInfo = "$($Miner.Info) stopped. Too many bad shares: ($($Algorithm): A$($Shares.$Algorithm[0])+R$($Shares.$Algorithm[1])+I$($Shares.$Algorithm[2])=T$($Shares.$Algorithm[3]))"
                                        Write-Message -Level Error "Miner $($Miner.StatusInfo)"
                                        $Miner.Data = [System.Collections.Generic.HashSet[PSCustomObject]]::new()
                                        $Miner.SetStatus([MinerStatus]::Failed)
                                        $Variables.Devices.Where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                                    }
                                }
                            }
                            Remove-Variable Algorithm, Shares -ErrorAction Ignore
                        }
                    }
                    Else { 
                        $Miner.StatusInfo = "$($Miner.Info) ($($Miner.Data.Count) Sample$(If ($Miner.Data.Count -ne 1) { "s" })) exited unexpectedly"
                        Write-Message -Level Error "Miner $($Miner.StatusInfo)"
                        $Miner.SetStatus([MinerStatus]::Failed)
                        $Variables.Devices.Where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                    }
                }

                # Do not save data if stat just got removed (Miner.Activated < 1, set by API)
                If ($Miner.Activated -gt 0 -and $Miner.Status -ne [MinerStatus]::DryRun) { 
                    $MinerHashrates = @{ }
                    If ($Miner.Data.Count) { 
                        # Collect hashrate from miner, returns an array of two values (safe, unsafe)
                        $Miner.Hashrates_Live = @()
                        ForEach ($Algorithm in $Miner.Algorithms) { 
                            $CollectedHashrate = $Miner.CollectHashrate($Algorithm, (-not $Miner.Benchmark -and $Miner.Data.Count -lt $Miner.MinDataSample))
                            $MinerHashrates.$Algorithm = $CollectedHashrate[0]
                            $Miner.Hashrates_Live += $CollectedHashrate[1]
                        }
                        If ($Miner.ReadPowerConsumption) { 
                            # Collect power consumption from miner, returns an array of two values (safe, unsafe)
                            $CollectedPowerConsumption = $Miner.CollectPowerConsumption(-not $Miner.MeasurePowerConsumption -and $Miner.Data.Count -lt $Miner.MinDataSample)
                            $MinerPowerConsumption = $CollectedPowerConsumption[0]
                            $Miner.PowerConsumption_Live = $CollectedPowerConsumption[1]
                        }
                    }

                    # We don't want to store hashrates or power consumption if we have less than $MinDataSample
                    If ($Miner.Data.Count -ge $Miner.MinDataSample -or $Miner.Activated -gt $Variables.WatchdogCount) { 
                        $Miner.StatEnd = [DateTime]::Now.ToUniversalTime()
                        $StatSpan = [TimeSpan]($Miner.StatEnd - $Miner.StatStart)

                        ForEach ($Worker in $Miner.Workers) { 
                            $Algorithm = $Worker.Pool.Algorithm
                            $MinerData = ($Miner.Data | Select-Object -Last 1).Shares
                            If ($Miner.Data.Count -gt $Miner.MinDataSample -and -not $Miner.Benchmark -and $Config.SubtractBadShares -and $MinerData.$Algorithm -gt 0) { 
                                # Need $Miner.MinDataSample shares before adjusting hashrate
                                $Factor = (1 - $MinerData.$Algorithm[1] / $MinerData.$Algorithm[3])
                                $MinerHashrates.$Algorithm *= $Factor
                            }
                            Else { 
                                $Factor = 1
                            }
                            $StatName = "$($Miner.Name)_$($Worker.Pool.Algorithm)_Hashrate"
                            $Stat = Set-Stat -Name $StatName -Value $MinerHashrates.$Algorithm -Duration $StatSpan -FaultDetection ($Miner.Data.Count -lt $Miner.MinDataSample -or $Miner.Activated -lt $Variables.WatchdogCount) -ToleranceExceeded ($Variables.WatchdogCount + 1)
                            If ($Stat.Updated -gt $Miner.StatStart) { 
                                Write-Message -Level Info "Saved hashrate for '$($StatName -replace "_Hashrate$")': $(($MinerHashrates.$Algorithm | ConvertTo-Hash) -replace " ")$(If ($Factor -le 0.999) { " (adjusted by factor $($Factor.ToString("N3")) [Shares: A$($MinerData.$Algorithm[0])|R$($MinerData.$Algorithm[1])|I$($MinerData.$Algorithm[2])|T$($MinerData.$Algorithm[3])])" }) ($($Miner.Data.Count) Sample$(If ($Miner.Data.Count -ne 1) { "s" }))$(If ($Miner.Benchmark) { " [Benchmark done]" })."
                                $Miner.StatStart = $Miner.StatEnd
                                $Variables.AlgorithmsLastUsed.($Worker.Pool.Algorithm) = @{ Updated = $Stat.Updated; Benchmark = $Miner.Benchmark; MinerName = $Miner.Name }
                                $Variables.PoolsLastUsed.($Worker.Pool.Name) = $Stat.Updated # most likely this will count at the pool to keep balances alive
                            }
                            ElseIf ($Stat.Week) { 
                                If ($MinerHashrates.$Algorithm -gt 0 -and $Miner.Status -eq [MinerStatus]::Running -and ($MinerHashrates.$Algorithm -gt $Stat.Week * 2 -or $MinerHashrates.$Algorithm -lt $Stat.Week / 2)) { 
                                    # Stop miner if new value is outside ±200% of current value
                                    Write-Message -Level Warn "Reported hashrate by '$($Miner.Info)' is unreal ($($Algorithm): $(($MinerHashrates.$Algorithm | ConvertTo-Hash) -replace " ") is not within ±200% of stored value of $(($Stat.Week | ConvertTo-Hash) -replace " "))"
                                    $Miner.SetStatus([MinerStatus]::Idle)
                                    $Variables.Devices.Where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                                    If ($Stat.ToleranceExceeded -ge $Config.WatchdogCount) { Remove-Stat $StatName }
                                }
                            }
                        }
                        Remove-Variable Factor -ErrorAction Ignore

                        $Variables.MinersLastUsed.($Miner.Name) = @{ Updated = $Stat.Updated; Benchmark = $Miner.Benchmark; Info = $Miner.Info }

                        If ($Miner.ReadPowerConsumption) { 
                            If ([Double]::IsNaN($MinerPowerConsumption )) { $MinerPowerConsumption = 0 }
                            $StatName = "$($Miner.Name)_PowerConsumption"
                            # Always update power consumption when benchmarking
                            $Stat = Set-Stat -Name $StatName -Value $MinerPowerConsumption -Duration $StatSpan -FaultDetection (-not $Miner.Benchmark -and ($Miner.Data.Count -lt $Miner.MinDataSample -or $Miner.Activated -lt $Variables.WatchdogCount)) -ToleranceExceeded ($Variables.WatchdogCount + 1)
                            If ($Stat.Updated -gt $Miner.StatStart) { 
                                Write-Message -Level Info "Saved power consumption for '$($StatName -replace "_PowerConsumption$")': $($Stat.Live.ToString("N2"))W ($($Miner.Data.Count) Sample$(If ($Miner.Data.Count -ne 1) { "s" }))$(If ($Miner.MeasurePowerConsumption) { " [Power consumption measurement done]" })."
                            }
                            ElseIf ($Stat.Week) { 
                                If ($MinerPowerConsumption -gt 0 -and $Miner.Status -eq [MinerStatus]::Running -and ($MinerPowerConsumption -gt $Stat.Week * 2 -or $MinerPowerConsumption -lt $Stat.Week / 2)) { 
                                    # Stop miner if new value is outside ±200% of current value
                                    Write-Message -Level Warn "Reported power consumption by '$($Miner.Info)' is unreal ($($MinerPowerConsumption.ToString("N2"))W is not within ±200% of stored value of $(([Double]$Stat.Week).ToString("N2"))W)"
                                    $Miner.SetStatus([MinerStatus]::Idle)
                                    $Variables.Devices.Where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                                    If ($Stat.ToleranceExceeded -ge $Config.WatchdogCount) { Remove-Stat $StatName }
                                }
                            }
                        }
                    }
                    Remove-Variable Algorithm, CollectedHashrateFactor, CollectedPowerConsumption, MinerData, MinerHashrates, MinerPowerConsumption, Stat, StatName, StatSpan, Worker -ErrorAction Ignore
                }
            }
            Remove-Variable Miner -ErrorAction Ignore

            # Update pools last used, required for BalancesKeepAlive
            If ($Variables.AlgorithmsLastUsed.Values.Updated -gt $Variables.BeginCycleTime) { $Variables.AlgorithmsLastUsed | Get-SortedObject | ConvertTo-Json | Out-File -LiteralPath ".\Data\AlgorithmsLastUsed.json" -Force }
            If ($Variables.MinersLastUsed.Values.Updated -gt $Variables.BeginCycleTime) { $Variables.MinersLastUsed | Get-SortedObject | ConvertTo-Json | Out-File -LiteralPath ".\Data\MinersLastUsed.json" -Force }
            If ($Variables.PoolsLastUsed.Values -gt $Variables.BeginCycleTime) { $Variables.PoolsLastUsed | Get-SortedObject | ConvertTo-Json | Out-File -LiteralPath ".\Data\PoolsLastUsed.json" -Force }

            # Send data to monitoring server
            # If ($Config.ReportToServer) { Write-MonitoringData }

            # Core suspended with <Ctrl><Alt>P in MainLoop
            While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

            # Get new miners
            If ($AvailableMinerPools = If ($Config.MinerUseBestPoolsOnly) { $Variables.Pools.Where({ $_.Available -and ($_.Best -or $_.Prioritize) }) } Else { $Variables.Pools.Where({ $_.Available }) }) { 
                $MinerPools = [System.Collections.SortedList]::New(), [System.Collections.SortedList]::New(@{ "" = "" })
                ($AvailableMinerPools.Where({ $_.Reasons -notcontains "Unprofitable primary algorithm" }) | Group-Object -Property Algorithm).ForEach({ $MinerPools[0][$_.Name] = $_.Group })
                ($AvailableMinerPools.Where({ $_.Reasons -notcontains "Unprofitable secondary algorithm" }) | Group-Object -Property Algorithm).ForEach({ $MinerPools[1][$_.Name] = $_.Group })

                $Message = "Loading miners.$(If (-not $Variables.Miners) { "<br>This may take a while." }).."
                If (-not $Variables.Miners) { 
                    $Variables.Summary = $Message
                    $Variables.RefreshNeeded = $true
                }
                Write-Message -Level Info ($Message -replace "<br>", " ")
                Remove-Variable Message

                $MinersNew = ((Get-ChildItem -Path ".\Miners\*.ps1").ForEach(
                    { 
                        $MinerFileName = $_.Name
                        Try { 
                            Write-Message -Level Debug "Miner definition file '$MinerFileName': Start building miner objects"
                            & $_.FullName
                            Write-Message -Level Debug "Miner definition file '$MinerFileName': End building miner objects"
                        }
                        Catch { 
                            Write-Message -Level Error "Miner file 'Miners\$MinerFileName': $_."
                            "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $ErrorLogFile
                            $_.Exception | Format-List -Force >> $ErrorLogFile
                            $_.InvocationInfo | Format-List -Force >> $ErrorLogFile
                        }
                    }
                ).ForEach(
                    { 
                        $Miner = $_
                        Try { 
                            ForEach ($Worker in $Miner.Workers) { 
                                $Miner.Workers[$Miner.Workers.IndexOf($Worker)].Fee = If ($Config.IgnoreMinerFee) { 0 } Else { $Miner.Fee[$Miner.Workers.IndexOf($Worker)] }
                            }
                            $Miner.PSObject.Properties.Remove("Fee")
                            $Miner | Add-Member BaseName_Version_Device (($Miner.Name -split "-")[0..2] -join "-")
                            $Miner | Add-Member Info "$($Miner.BaseName_Version_Device) {$($Miner.Workers.ForEach({ $_.Pool.AlgorithmVariant, $_.Pool.Name -join "@" }) -join " & ")}$(If (($Miner.Name -split "-")[4]) { " ($(($Miner.Name -split "-")[4]))" })"

                            $Miner -as $_.API
                        }
                        Catch { 
                            Write-Message -Level Error "Failed to add miner '$($Miner.Name)' as '$($Miner.API)' ($($Miner | ConvertTo-Json -Compress))"
                            "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $ErrorLogFile
                            $_.Exception | Format-List -Force >> $ErrorLogFile
                            $_.InvocationInfo | Format-List -Force >> $ErrorLogFile
                        }
                    }
                ) | Sort-Object -Property Info)
                Remove-Variable Algorithm, AvailableMinerPools, Miner, MinerFileName, MinerPools -ErrorAction Ignore

                If ($Variables.BenchmarkAllPoolAlgorithmCombinations) { $MinersNew.ForEach({ $_.Name = $_.Info }) }

                $Miners = Compare-Object @($Variables.Miners | Sort-Object -Property Info) @($MinersNew) -Property Info -IncludeEqual -PassThru
                $MinerDevices = $Variables.EnabledDevices | Select-Object -Property Bus, ConfiguredPowerConsumption, Name, ReadPowerConsumption, Status

                # Make smaller groups for faster update
                $MinersNewGroups = $MinersNew | Group-Object -Property BaseName_Version
                ($Miners.Where({ $_.SideIndicator -ne "<=" }) | Group-Object -Property BaseName_Version).ForEach(
                    { 
                        $Name = $_.Name
                        $MinersNewGroup = $MinersNewGroups.Where({ $Name -eq $_.Name }).Group
                        $_.Group.ForEach(
                            { 
                                Try { 
                                    $Miner = $_
                                    If ($_.KeepRunning = [MinerStatus]::Running, [MinerStatus]::DryRun -contains $_.Status -and ($Variables.DonationRunning -or $_.ContinousCycle -lt $Config.MinCycle)) { 
                                        # Minimum numbers of cycles not yet reached
                                        $_.Restart = $false
                                    }
                                    Else { 
                                        If ($_.SideIndicator -eq "=>") { 
                                            # Newly added miners, these properties need to be set only once because they are not dependent on any config or pool information
                                            $_.Algorithms = $_.Workers.Pool.Algorithm
                                            $_.CommandLine = $_.GetCommandLine()
                                            $_.BaseName = ($_.Name -split "-")[0]
                                            $_.Version = ($_.Name -split "-")[1]
                                            $_.BaseName_Version = "$($_.BaseName)-$($_.Version)"
                                            $DeviceNames = $_.DeviceNames
                                            $_.Devices = $MinerDevices.Where({ $DeviceNames -contains $_.Name })
                                        }
                                        ElseIf ($Miner = $MinersNewGroup.Where({ $Miner.Info -eq $_.Info })) { 
                                        # ElseIf ($Miner = Compare-Object -PassThru $MinersNewGroup $_ -Property Info -IncludeEqual -ExcludeDifferent) { 
                                            # Update existing miners
                                            If ($_.Restart = $_.Arguments -ne $Miner.Arguments) { 
                                                $_.Arguments = $Miner.Arguments
                                                $_.CommandLine = $Miner.GetCommandLine()
                                                $_.Port = $Miner.Port
                                            }
                                            $_.PrerequisitePath = $Miner.PrerequisitePath
                                            $_.PrerequisiteURI = $Miner.PrerequisiteURI
                                            $_.Reasons = [System.Collections.Generic.SortedSet[String]]::New()
                                            $_.WarmupTimes = $Miner.WarmupTimes
                                            $_.Workers = $Miner.Workers
                                        }
                                    }
                                    $_.MeasurePowerConsumption = $Variables.CalculatePowerCost
                                    $_.Refresh($Variables.PowerCostBTCperW, $Config)
                                }
                                Catch { 
                                    Write-Message -Level Error "Failed to update miner '$($Miner.Name)': Error $_ ($($Miner | ConvertTo-Json -Compress)"
                                    "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $ErrorLogFile
                                    $_.Exception | Format-List -Force >> $ErrorLogFile
                                    $_.InvocationInfo | Format-List -Force >> $ErrorLogFile
                                }
                            }
                        )
                    }
                )
                Remove-Variable DeviceNames, Info, Miner, MinerDevices, MinersNew, MinersNewGroup, MinersNewGroups, Name -ErrorAction Ignore
            }
            $MinersAdded = $Miners.Where({ $_.SideIndicator -eq "=>" })
            $MinersRemoved = $Miners.Where({ $_.Updated -lt $Variables.BeginCycleTime.AddDays(-1) })
            $Miners.Where({ $_.SideIndicator -eq "<=" }).ForEach({ $_.Best = $false; $_.Reasons = [System.Collections.Generic.SortedSet[String]]::New() })

            # Core suspended with <Ctrl><Alt>P in MainLoop
            While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

            # Filter miners
            $Miners.Where({ $_.Updated -lt $Variables.CycleStarts[0] }).ForEach({ $_.Reasons.Add("No valid pool data in the last $($Config.SyncWindow) cycles") | Out-Null })
            $Miners.Where({ $_.Disabled }).ForEach({ $_.Reasons.Add("Disabled by user") | Out-Null })
            $ExcludeMinerName = @($Config.ExcludeMinerName -replace "^-" | Select-Object)
            If ($ExcludeMinerName.Count) { $Miners.Where({ Compare-Object $ExcludeMinerName ($_.BaseName, $_.BaseName_Version, $_.BaseName_Version_Device) -IncludeEqual -ExcludeDifferent }).ForEach({ $_.Reasons.Add("ExcludeMinerName ($($Config.ExcludeMinerName -join ", "))") | Out-Null }) }
            Remove-Variable ExcludeMinerName
            If (-not $Config.PoolAllow0Price) { $Miners.Where({ $_.Earnings -eq 0 }).ForEach({ $_.Reasons.Add("Earnings -eq 0") | Out-Null }) }
            $Miners.Where({ -not $_.Benchmark -and $_.Workers.Hashrate -contains 0 }).ForEach({ $_.Reasons.Add("0 H/s stat file") | Out-Null })
            If ($Config.DisableMinersWithFee) { $Miners.Where({ $_.Workers.Fee }).ForEach({ $_.Reasons.Add("Config.DisableMinersWithFee") | Out-Null }) }
            If ($Config.DisableDualAlgoMining) { $Miners.Where({ $_.Workers.Count -eq 2 }).ForEach({ $_.Reasons.Add("Config.DisableDualAlgoMining") | Out-Null }) }
            If ($Config.DisableSingleAlgoMining) { $Miners.Where({ $_.Workers.Count -eq 1 }).ForEach({ $_.Reasons.Add("Config.DisableSingleAlgoMining") | Out-Null }) }

            # Add reason 'Config.DisableCpuMiningOnBattery' for CPU miners when running on battery
            If ($Config.DisableCpuMiningOnBattery -and (Get-CimInstance Win32_Battery).BatteryStatus -eq 1) { $Miners.Where({ $_.Type -eq "CPU" }).ForEach({ $_.Reasons.Add("Config.DisableCpuMiningOnBattery") | Out-Null }) }

            # Add reason 'Unreal earning data...' for miners with unreal earnings > x times higher than average of the next best 10% or at least 5 available miners
            If ($Config.UnrealMinerEarningFactor -gt 1) { 
                ($Miners.Where({ -not $_.Reasons.Count -and -not $_.Benchmark -and -not $_.MeasurePowerConsumption }) | Group-Object { $_.BaseName_Version_Device -replace ".+-" }).ForEach(
                    { 
                        If ($ReasonableEarnings = [Double]($_.Group | Sort-Object -Descending -Property Earnings_Bias | Select-Object -Skip 1 -First (5, [Math]::Floor($_.Group.Count / 10) | Measure-Object -Maximum).Maximum | Measure-Object Earnings -Average).Average * $Config.UnrealMinerEarningFactor) { 
                            $Group = $_.Group.Where({ $_.Group.Count -ge 5 -and $_.Earnings -gt $ReasonableEarnings })
                            $Group.ForEach(
                                { $_.Reasons.Add("Unreal earning data (-gt $($Config.UnrealMinerEarningFactor)x higher than the next best $($Group.Count - 1) miners available miners)") | Out-Null }
                            )
                        }
                    }
                )
                Remove-Variable Group, ReasonableEarnings -ErrorAction Ignore
            }

            $Variables.MinersMissingBinary = ($Miners.Where({ -not $_.Reasons.Count }) | Group-Object -Property Path).Where({ -not (Test-Path -LiteralPath $_.Name -Type Leaf) }).Group.ForEach(
                { 
                    $_.Reasons.Add("Binary missing") | Out-Null
                    $_
                }
            )

            $Variables.MinersMissingPrerequisite = ($Miners.Where({ $_.PrerequisitePath }) | Group-Object -Property PrerequisitePath).Where({ -not (Test-Path -LiteralPath $_.Name -Type Leaf) }).Group.ForEach(
                { 
                    $_.Reasons.Add("Prerequisite missing ($(Split-Path -Path $_.PrerequisitePath -Leaf))") | Out-Null
                    $_
                }
            )

            If ($DownloadList = @($Variables.MinersMissingBinary | Sort-Object Uri -Unique | Select-Object URI, Path, @{ Name = "Searchable"; Expression = { $false } }, @{ Name = "Type"; Expression = { "miner binary" } }) + @($Variables.MinersMissingPrerequisite | Sort-Object PrerequisiteURI -Unique | Select-Object @{ Name = "URI"; Expression = { $_.PrerequisiteURI } }, @{ Name = "Path"; Expression = { $_.PrerequisitePath } }, @{ Name = "Searchable"; Expression = { $false } }, @{ Name = "Type"; Expression = { "miner pre-requisite" } })) { 
                If ($Variables.Downloader.State -ne "Running") { 
                    # Download miner binaries
                    Write-Message -Level Info "Some files are missing ($($DownloadList.Count) item$(If ($DownloadList.Count -ne 1) { "s" })). Starting downloader..."
                    $DownloaderParameters = @{ 
                        Config       = $Config
                        DownloadList = $DownloadList
                        Variables    = $Variables
                    }
                    $Variables.Downloader = Start-ThreadJob -Name Downloader -StreamingHost $null -FilePath ".\Includes\Downloader.ps1" -InitializationScript ([ScriptBlock]::Create("Set-Location '$($Variables.MainPath)'")) -ArgumentList $DownloaderParameters
                    Remove-Variable DownloaderParameters
                }
            }
            Remove-Variable DownloadList

            # Open firewall ports for all miners
            $Variables.MinerMissingFirewallRule = [System.Collections.Generic.SortedSet[String]]::new()
            If ($Config.OpenFirewallPorts -and ($MinersAdded -or -not $Variables.IsLocalAdmin)) { # If running as admin only needed when new miners are found
                If (Get-Command Get-MpPreference) { 
                    If ((Get-Command Get-MpComputerStatus) -and (Get-MpComputerStatus)) { 
                        If (Get-Command Get-NetFirewallRule) { 
                            If ($MissingFirewallRules = (Compare-Object @(Get-NetFirewallApplicationFilter | Select-Object -ExpandProperty Program -Unique | Sort-Object) @(($Miners.Path | Sort-Object -Unique).ForEach({ "$PWD\$($_)" })) -PassThru).Where({ $_.SideIndicator -eq "=>" })) { 
                                Try { 
                                    If (-not $Variables.IsLocalAdmin) { 
                                        Write-Message -Level Info "Initiating request to add inbound firewall rule$(If ($MissingFirewallRules.Count -ne 1) { "s" }) for $($MissingFirewallRules.Count) miner$(If ($MissingFirewallRules.Count -ne 1) { "s" })..."
                                        Start-Process "pwsh" ("-Command Write-Host 'Adding inbound firewall rule$(If ($MissingFirewallRules.Count -ne 1) { "s" }) for $($MissingFirewallRules.Count) miner$(If ($MissingFirewallRules.Count -ne 1) { "s" })...';  Write-Host ''; Start-Sleep -Seconds 3; Import-Module NetSecurity; ('$($MissingFirewallRules | ConvertTo-Json -Compress)' | ConvertFrom-Json).ForEach({ New-NetFirewallRule -DisplayName (Split-Path `$_ | Split-Path -leaf) -Program `$_ -Description 'Inbound rule added by $($Variables.Branding.ProductLabel) $($Variables.Branding.Version) on $([DateTime]::Now.ToString())' -Group '$($Variables.Branding.ProductLabel)' | Out-Null; `$Message = 'Added inbound firewall rule for ' + (Split-Path `$_ | Split-Path -leaf) + '.'; Write-Host `$Message }); Write-Host ''; Write-Host 'Added $($MissingFirewallRules.Count) inbound firewall rule$(If ($MissingFirewallRules.Count -ne 1) { "s" }).'; Start-Sleep -Seconds 3" -replace "`"", "\`"") -Verb runAs
                                    }
                                    Else { 
                                        Import-Module NetSecurity
                                        $MissingFirewallRules.ForEach({ New-NetFirewallRule -DisplayName (Split-Path $_ | Split-Path -leaf) -Program $_ -Description "Inbound rule added by $($Variables.Branding.ProductLabel) $($Variables.Branding.Version) on $([DateTime]::Now.ToString())" -Group $($Variables.Branding.ProductLabel) })
                                    }
                                    Write-Message -Level Info "Added $($MissingFirewallRules.Count) inbound firewall rule$(If ($MissingFirewallRules.Count -ne 1) { "s" }) to Windows Defender inbound rules group '$($Variables.Branding.ProductLabel)'."
                                }
                                Catch { 
                                    Write-Message -Level Error "Could not add inbound firewall rules. Some miners will not be available."
                                    $Variables.MinerMissingFirewallRule = $Miners.Where({ $MissingFirewallRules -contains $_.Path })
                                    $Variables.MinerMissingFirewallRule.ForEach({ $_.Reasons.Add("Inbound firewall rule missing") | Out-Null })
                                }
                            }
                            Remove-Variable MissingFirewallRules
                        }
                    }
                }
            }

            # Apply watchdog to miners
            If ($Config.Watchdog) { 
                # We assume that miner is up and running, so watchdog timer is not relevant
                If ($RelevantWatchdogTimers = $Variables.WatchdogTimers.Where({ $_.MinerName -notin $Variables.MinersRunning.Name })) { 
                    # Only miners with a watchdog timer object are of interest
                    If ($RelevantMiners = $Variables.Miners.Where({ $RelevantWatchdogTimers.MinerBaseName_Version -contains $_.BaseName_Version })) { 
                        # Add miner reason 'Miner suspended by watchdog [all algorithms & all devices]'
                        ($RelevantWatchdogTimers | Group-Object -Property MinerBaseName_Version).ForEach(
                            { 
                                If ($_.Count -gt 2 * $Variables.WatchdogCount * ($_.Group[0].MinerName -split "&").Count * ($_.Group.DeviceNames | Sort-Object -Unique).Count) { 
                                    $WatchdogGroup = $_.Group
                                    If ($MinersToSuspend = $RelevantMiners.Where({ $_.MinerBaseName_Version -eq $WatchdogGroup.Name })) { 
                                        $MinersToSuspend.ForEach({ $_.Reasons.Add("Miner suspended by watchdog [all algorithms & all devices]") | Out-Null })
                                        Write-Message -Level Warn "Miner '$($WatchdogGroup.Name) [all algorithms & all devices]' is suspended by watchdog until $(($WatchdogGroup.Kicked | Sort-Object -Top 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                                    }
                                }
                            }
                        )
                        Remove-Variable MinersToSuspend, WatchdogGroup -ErrorAction Ignore

                        If ($RelevantMiners = $RelevantMiners.Where({ -not ($_.Reasons -match "Miner suspended by watchdog .+") })) { 
                            # Add miner reason 'Miner suspended by watchdog [all algorithms]'
                            ($RelevantWatchdogTimers | Group-Object MinerBaseName_Version_Device).ForEach(
                                { 
                                    If ($_.Count -gt 2 * $Variables.WatchdogCount * ($_.Group[0].MinerName -split "&").Count) { 
                                        $WatchdogGroup = $_.Group
                                        If ($MinersToSuspend = $RelevantMiners.Where({ $_.BaseName_Version_Device -eq $WatchdogGroup[0].MinerBaseName_Version_Device })) { 
                                            $MinersToSuspend.ForEach({ $_.Reasons.Add("Miner suspended by watchdog [all algorithms]") | Out-Null })
                                            Write-Message -Level Warn "Miner '$($WatchdogGroup[0].MinerBaseName_Version_Device) [all algorithms]' is suspended by watchdog until $(($WatchdogGroup.Kicked | Sort-Object -Top 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                                        }
                                    }
                                }
                            )
                            Remove-Variable MinersToSuspend, WatchdogGroup -ErrorAction Ignore

                            If ($RelevantMiners = $RelevantMiners.Where({ -not ($_.Reasons -match "Miner suspended by watchdog .+") })) { 
                                # Add miner reason 'Miner suspended by watchdog [Algorithm]'
                                ($RelevantWatchdogTimers.Where({ $_.Algorithm -eq $_.AlgorithmVariant }) | Group-Object -Property MinerBaseName_Version_Device).ForEach(
                                    { 
                                        If ($_.Count / ($_.Group[0].MinerName -split "&").Count -ge $Variables.WatchdogCount) { 
                                            $WatchdogGroup = $_.Group
                                            If ($MinersToSuspend = $RelevantMiners.Where({ $_.BaseName_Version_Device -eq $WatchdogGroup[0].MinerBaseName_Version_Device -and $_.Workers.Pool.Algorithm -contains $WatchdogGroup[0].Algorithm })) { 
                                                $MinersToSuspend.ForEach({ $_.Reasons.Add("Miner suspended by watchdog [Algorithm $($WatchdogGroup[0].Algorithm)]") | Out-Null })
                                                Write-Message -Level Warn "Miner '$($WatchdogGroup[0].MinerBaseName_Version_Device) [$($WatchdogGroup[0].Algorithm)]' is suspended by watchdog until $(($WatchdogGroup.Kicked | Sort-Object -Top 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                                            }
                                        }
                                    }
                                )
                                Remove-Variable MinersToSuspend, WatchdogGroup -ErrorAction Ignore

                                If ($RelevantMiners = $RelevantMiners.Where({ -not ($_.Reasons -match "Miner suspended by watchdog .+") })) { 
                                    # Add miner reason 'Miner suspended by watchdog [AlgorithmVariant]'
                                    ($RelevantWatchdogTimers.Where({ $_.Algorithm -ne $_.AlgorithmVariant }) | Group-Object -Property MinerBaseName_Version_Device).ForEach(
                                        { 
                                            If ($_.Count / ($_.Group[0].MinerName -split "&").Count -ge $Variables.WatchdogCount) { 
                                                $WatchdogGroup = $_.Group
                                                If ($MinersToSuspend = $RelevantMiners.Where({ $_.BaseName_Version_Device -eq $WatchdogGroup[0].MinerBaseName_Version_Device -and $_.Workers.Pool.AlgorithmVariant -contains $WatchdogGroup[0].AlgorithmVariant })) { 
                                                    $MinersToSuspend.ForEach({ $_.Reasons.Add("Miner suspended by watchdog [Algorithm $($WatchdogGroup[0].AlgorithmVariant)]") | Out-Null })
                                                    Write-Message -Level Warn "Miner '$($WatchdogGroup[0].MinerBaseName_Version_Device) [$($WatchdogGroup[0].AlgorithmVariant)]' is suspended by watchdog until $(($WatchdogGroup.Kicked | Sort-Object -Top 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                                                }
                                            }
                                        }
                                    )
                                    Remove-Variable MinersToSuspend, WatchdogGroup -ErrorAction Ignore
                                }
                            }
                        }
                    }
                    Remove-Variable RelevantMiners -ErrorAction Ignore
                }
                Remove-Variable RelevantWatchdogTimers -ErrorAction Ignore
            }
            $Variables.MinersUpdatedTimestamp = [DateTime]::Now.ToUniversalTime()

            $Miners.ForEach({ $_.Available = -not $_.Reasons.Count })

            # Gone miners are no longer available
            $Miners.Where({ $_.Updated -lt $Variables.BeginCycleTime.AddDays(-1) }).ForEach({ $_.Available = $false; $_.Best = $false })

            If (-not $Miners.Where({ $_.Available })) { 
                $Message = "No available miners - will retry in $($Config.Interval) seconds..."
                Write-Message -Level Warn $Message
                $Variables.Summary = $Message
                Remove-Variable Message

                Clear-MinerData

                $Variables.RefreshNeeded = $true

                Start-Sleep -Seconds $Config.Interval

                Write-Message -Level Info "Ending cycle."
                Continue
            }

            $Message = If ($Variables.Miners) { "Had $($Variables.Miners.Count) miner$(If ($Variables.Miners.Count -ne 1) { "s" }) from previous run" } Else { "Loaded $($Miners.Count) miner$(If ($Miners.Count -ne 1) { "s" })" }
            If ($Variables.Miners.Count -and $MinersAdded.Count) { $Message += ", added $($MinersAdded.Count) miner$(If ($Miners.Where({ $_.SideIndicator -ne "=>" }).Count -ne 1) { "s" })" }
            If ($MinersRemoved.Count) { $Message += ", removed $($MinersRemoved.Count.Count) miner$(if ($MinersRemoved.Count -ne 1) { "s" })" }
            If ($Miners.Where({ $_.SideIndicator -eq "==" }).Count) { $Message += ", updated $($Miners.Where({ $_.SideIndicator -eq "==" }).Count) existing miner$(If ($Miners.Where({ $_.SideIndicator -ne "==" }).Count -ne 1) { "s" })" }
            If ($Miners.Where({ -not $_.Available -and $_.Updated -ge $Variables.BeginCycleTime.AddDays(-1) })) { $Message += ", filtered out $($Miners.Where({ -not $_.Available -and $_.Updated -ge $Variables.BeginCycleTime.AddDays(-1) }).Count) miner$(If ($Miners.Where({ -not $_.Available -and $_.Updated -ge$Variables.BeginCycleTime.AddDays(-1) }).Count -ne 1) { "s" })" }
            $Message += ". $($Miners.Where({ $_.Available }).Count) available miner$(If ($Miners.Where({ $_.Available }).Count -ne 1) { "s" }) remain$(If ($Miners.Where({ $_.Available }).Count -eq 1) { "s" })."
            Write-Message -Level Info $Message
            Remove-Variable Message, MinersAdded, MinersRemoved

            $Bias = If ($Variables.CalculatePowerCost -and -not $Config.IgnorePowerCost) { "Profit_Bias" } Else { "Earnings_Bias" }
            If ($Miners.Where({ $_.Available })) { 
                Write-Message -Level Info "Selecting best miner$(If (($Variables.EnabledDevices.Model | Select-Object -Unique).Count -gt 1) { " combinations" }) based on$(If ($Variables.CalculatePowerCost -and -not $Config.IgnorePowerCost) { " profit (power cost $($Config.FIATcurrency) $($Variables.PowerPricekWh)/kW⋅h)" } Else { " earnings" })..."

                If ($Miners.Where({ $_.Available }).Count -eq 1) { 
                    $MinersBest = $Variables.MinersBestPerDevice = $MinersOptimal = $Miners.Where({ $_.Available })
                }
                Else { 
                    # Add running miner bonus
                    $RunningMinerBonusFactor = 1 + $Config.MinerSwitchingThreshold / 100
                    $Miners.Where({ $_.Status -eq [MinerStatus]::Running }).ForEach({ $_.$Bias *= $RunningMinerBonusFactor })

                    # Get the optimal miners per algorithm and device
                    $MinersOptimal = ($Miners.Where({ $_.Available -and -not ($_.Benchmark -or $_.MeasurePowerConsumption) }) | Group-Object { $_.BaseName_Version_Device -replace ".+-" }, { $_.Algorithms -join " " }).ForEach({ ($_.Group | Sort-Object -Descending -Property KeepRunning, Prioritize, $Bias, Activated, @{ Expression = { $_.WarmupTimes[1] + $_.MinDataSample }; Descending = $true }, @{ Expression = { $_.Algorithms -join " " }; Descending = $false } -Top 1).ForEach({ $_.Optimal = $true; $_ }) })
                    # Get the best miners per device
                    $Variables.MinersBestPerDevice = ($Miners.Where({ $_.Available }) | Group-Object { $_.BaseName_Version_Device -replace ".+-" }).ForEach({ $_.Group | Sort-Object -Descending -Property Benchmark, MeasurePowerConsumption, KeepRunning, Prioritize, $Bias, Activated, @{ Expression = { $_.WarmupTimes[1] + $_.MinDataSample }; Descending = $false } -Top 1 })

                    # Hack: Temporarily make all bias -ge 0 by adding smallest bias, MinersBest produces wrong sort order when some profits are negative
                    # Get smallest $Bias
                    $SmallestBias = $Variables.MinersBestPerDevice.$Bias | Sort-Object -Top 1

                    $Variables.MinersBestPerDevice.ForEach({ $_.$Bias += $SmallestBias })
                    $MinerDeviceNamesCombinations = (Get-Combination @($Variables.MinersBestPerDevice | Select-Object DeviceNames -Unique)).Where({ (Compare-Object ($_.Combination | Select-Object -ExpandProperty DeviceNames -Unique) ($_.Combination | Select-Object -ExpandProperty DeviceNames) | Measure-Object).Count -eq 0 })

                    # Get best miner combination i.e. AMD+INTEL+NVIDIA+CPU
                    $MinerCombinations = $MinerDeviceNamesCombinations.ForEach(
                        { 
                            $DeviceNamesCombination = $_.Combination
                            [PSCustomObject]@{ 
                                Combination = $DeviceNamesCombination.ForEach(
                                    { 
                                        $DeviceNames = $_.DeviceNames -join " "
                                        $Variables.MinersBestPerDevice.Where({ ($_.DeviceNames -join " ") -eq $DeviceNames })
                                    }
                                )
                            }
                        }
                    )
                    $MinersBest = ($MinerCombinations | Sort-Object -Descending { $_.Combination.Where({ [Double]::IsNaN($_.$Bias) }).Count }, { ($_.Combination.$Bias | Measure-Object -Sum).Sum }, { ($_.Combination.Where({ $_.$Bias -ne 0 }) | Measure-Object).Count } -Top 1).Combination | Sort-Object { $_.BaseName_Version_Device -replace ".+-" }

                    # Revert smallest bias hack
                    $Variables.MinersBestPerDevice.ForEach({ $_.$Bias -= $SmallestBias })
                    # Revert running miner bonus
                    $Miners.Where({ $_.Status -eq [MinerStatus]::Running }).ForEach({ $_.$Bias /= $RunningMinerBonusFactor })

                    Remove-Variable DeviceNames, DeviceNamesCombination, MinerCombinations, MinerDeviceNamesCombinations, RunningMinerBonusFactor, SmallestBias -ErrorAction Ignore
                }

                $Variables.PowerConsumptionIdleSystemW = (($Config.PowerConsumptionIdleSystemW - ($MinersBest.Where({ $_.Type -eq "CPU" }) | Measure-Object PowerConsumption -Sum).Sum), 0 | Measure-Object -Maximum).Maximum
                $Variables.BasePowerCost = [Double]($Variables.PowerConsumptionIdleSystemW / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates.BTC.($Config.FIATcurrency))
                $Variables.MiningEarnings = [Double]($MinersBest | Measure-Object Earnings_Bias -Sum).Sum
                $Variables.MiningPowerCost = [Double]($MinersBest | Measure-Object PowerCost -Sum).Sum
                $Variables.MiningPowerConsumption = [Double]($MinersBest | Measure-Object PowerConsumption -Sum).Sum
                $Variables.MiningProfit = [Double](($MinersBest | Measure-Object Profit_Bias -Sum).Sum - $Variables.BasePowerCost)
            }
            Else { 
                $Variables.PowerConsumptionIdleSystemW = (($Config.PowerConsumptionIdleSystemW), 0 | Measure-Object -Maximum).Maximum
                $Variables.BasePowerCost = [Double]($Variables.PowerConsumptionIdleSystemW / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates.BTC.($Config.FIATcurrency))
                $Variables.MinersBestPerDevice = $MinerDeviceNamesCombinations = $MinersBest = $MinersOptimal = [Miner[]]@()
                $Variables.MiningEarnings = $Variables.MiningProfit = $Variables.MiningPowerCost = $Variables.MiningPowerConsumption = [Double]0
            }
        }
        Else { 
            $Message = "No enabled devices - will retry in $($Config.Interval) seconds..."
            Write-Message -Level Warn $Message
            $Variables.Summary = $Message
            Remove-Variable Message

            Clear-PoolData
            Clear-MinerData

            $Variables.RefreshNeeded = $true

            Start-Sleep -Seconds $Config.Interval

            Write-Message -Level Info "Ending cycle."
            Continue
        }

        $Variables.MinersNeedingBenchmark = $Miners.Where({ $_.Available -and $_.Benchmark }) | Sort-Object { $_.BaseName_Version_Device -replace ".+-" }, Info
        $Variables.MinersNeedingPowerConsumptionMeasurement = $Miners.Where({ $_.Available -and $_.MeasurePowerConsumption }) | Sort-Object { $_.BaseName_Version_Device -replace ".+-" }, Info

        $Summary = ""
        If ($Variables.Rates.($Config.PayoutCurrency)) { 
            $PayoutCurrency = If ($Config.PayoutCurrency -eq "BTC" -and $Config.UsemBTC) { "mBTC" } Else { $Config.PayoutCurrency }
            # ProfitabilityThreshold check - OK to run miners?
            If ($Variables.CalculatePowerCost -and ($Variables.MiningProfit * $Variables.Rates.BTC.($Config.FIATcurrency)) -lt $Config.ProfitabilityThreshold) { 
                # Mining earnings/profit is below threshold
                $MinersBest = [Miner[]]@()
                $Text = "Mining profit of {0} {1:n} / day is below the configured threshold of {0} {2:n} / day. Mining is suspended until the threshold is reached." -f $Config.FIATcurrency, ($Variables.MiningProfit * $Variables.Rates.BTC.($Config.FIATcurrency)), $Config.ProfitabilityThreshold
                Write-Message -Level Warn ($Text -replace " / day", "/day")
                $Summary += "$Text`n"
                Remove-Variable Text
            }
            Else { 
                $MinersBest.ForEach({ $_.Best = $true })

                If ($Variables.MinersNeedingBenchmark.Count) { 
                    $Summary += "Earnings / day: n/a (Benchmarking: $($Variables.MinersNeedingBenchmark.Count) $(If ($Variables.MinersNeedingBenchmark.Count -eq 1) { "miner" } Else { "miners" }) left [$((($Variables.MinersNeedingBenchmark | Group-Object { $_.BaseName_Version_Device -replace ".+-" }).ForEach({ "$($_.Group[0].BaseName_Version_Device -replace(".+-")): $($_.Count)" }) | Sort-Object) -join ", ")])"
                }
                ElseIf ($Variables.MiningEarnings -gt 0) { 
                    $Summary += "Earnings / day: {0:n} {1} ({2:N$(Get-DecimalsFromValue -Value ($Variables.MiningProfit * ($Variables.MiningProfit * $Variables.Rates.BTC.$PayoutCurrency)) -DecimalsMax $Config.DecimalsMax)} {3})" -f ($Variables.MiningEarnings * $Variables.Rates.BTC.($Config.FIATcurrency)), $Config.FIATcurrency, ($Variables.MiningEarnings * $Variables.Rates.BTC.$PayoutCurrency), $PayoutCurrency
                }

                If ($Variables.CalculatePowerCost) { 
                    If ($Variables.MinersNeedingPowerConsumptionMeasurement.Count -or [Double]::IsNaN($Variables.MiningPowerCost)) { 
                        $Summary += "    Profit / day: n/a (Measuring power consumption: $($Variables.MinersNeedingPowerConsumptionMeasurement.Count) $(If ($Variables.MinersNeedingPowerConsumptionMeasurement.Count -eq 1) { "miner" } Else { "miners" }) left [$((($Variables.MinersNeedingPowerConsumptionMeasurement | Group-Object { $_.BaseName_Version_Device -replace ".+-" }).ForEach({ "$($_.Group[0].BaseName_Version_Device -replace(".+-")): $($_.Count)" }) | Sort-Object) -join ", ")])"
                    }
                    ElseIf ($Variables.MinersNeedingBenchmark.Count) { 
                        $Summary += "    Profit / day: n/a"
                    }
                    ElseIf ($Variables.MiningPowerConsumption -gt 0) { 
                        $Summary += "    Profit / day: {0:n} {1} ({2:N$(Get-DecimalsFromValue -Value ($Variables.MiningProfit * $Variables.Rates.BTC.$PayoutCurrency) -DecimalsMax $Config.DecimalsMax)} {3})" -f ($Variables.MiningProfit * $Variables.Rates.BTC.($Config.FIATcurrency)), $Config.FIATcurrency, ($Variables.MiningProfit * $Variables.Rates.BTC.$PayoutCurrency), $PayoutCurrency
                    }
                    Else { 
                        $Summary += "    Profit / day: n/a (no power data)"
                    }

                    If ([Double]::IsNaN($Variables.MiningEarnings) -or [Double]::IsNaN($Variables.MiningPowerCost)) { 
                        $Summary += "`nPower cost / day: n/a [Miner$(If ($MinersBest.Count -ne 1) { "s" }): n/a; Base: {1:n} {0} ({2:n2} W)]" -f $Config.FIATcurrency, ($Variables.BasePowerCost * $Variables.Rates.BTC.($Config.FIATcurrency)), $Variables.PowerConsumptionIdleSystemW
                    }
                    ElseIf ($Variables.MiningPowerConsumption -gt 0) { 
                        $Summary += "`nPower cost / day: {1:n} {0} [Miner$(If ($MinersBest.Count -ne 1) { "s" }): {2:n} {0} ({3:n2} W)$(If ($Variables.PowerConsumptionIdleSystemW) { "; Base: {4:n} {0} ({5:n2} W)]" })" -f $Config.FIATcurrency, (($Variables.MiningPowerCost + $Variables.BasePowerCost) * $Variables.Rates.BTC.($Config.FIATcurrency)), ($Variables.MiningPowerCost * $Variables.Rates.BTC.($Config.FIATcurrency)), $Variables.MiningPowerConsumption, ($Variables.BasePowerCost * $Variables.Rates.BTC.($Config.FIATcurrency)), $Variables.PowerConsumptionIdleSystemW
                    }
                    Else { 
                        $Summary += "`nPower cost / day: n/a [Miner: n/a$(If ($Variables.PowerConsumptionIdleSystemW) { "; Base: {1:n} {0} ({2:n2} W)]" })" -f $Config.FIATcurrency, ($Variables.BasePowerCost * $Variables.Rates.BTC.($Config.FIATcurrency)), $Variables.PowerConsumptionIdleSystemW
                    }
                }
            }

            # Add currency conversion rates
            If ($Summary -ne "") { $Summary += "`n" }
            ((@(If ($Config.UsemBTC) { "mBTC" } Else { ($Config.PayoutCurrency) }) + @($Config.ExtraCurrencies)) | Select-Object -Unique).Where({ $Variables.Rates.$_.($Config.FIATcurrency) }).ForEach(
                { 
                    $Summary += "1 $_ = {0:N$(Get-DecimalsFromValue -Value $Variables.Rates.$_.($Config.FIATcurrency) -DecimalsMax $Config.DecimalsMax)} $($Config.FIATcurrency)   " -f $Variables.Rates.$_.($Config.FIATcurrency)
                }
            )
            $Variables.Summary = $Summary
            Remove-Variable PayoutCurrency, Summary
        }
        Else { 
            $Message = "Error: Could not get BTC exchange rate from 'min-api.cryptocompare.com' for currency '$($Config.PayoutCurrency)'. Cannot determine best miners to run - will retry in $($Config.Interval) seconds..."
            Write-Message -Level Warn $Message
            $Variables.Summary = $Message
            Remove-Variable Message

            Clear-PoolData
            Clear-MinerData

            $Variables.RefreshNeeded = $true

            Start-Sleep -Seconds $Config.Interval

            Write-Message -Level Info "Ending cycle."
            Continue
        }

        # Stop running miners
        ForEach ($Miner in @($Miners.Where({ [MinerStatus]::DryRun, [MinerStatus]::Running -contains $_.Status }) | Sort-Object { $_.BaseName_Version_Device -replace ".+-" })) { 
            If ($Miner.Status -eq [MinerStatus]::Running -and $Miner.GetStatus() -ne [MinerStatus]::Running) { 
                $Miner.StatusInfo = "$($Miner.Info) ($($Miner.Data.Count) Sample$(If ($Miner.Data.Count -ne 1) { "s" })) exited unexpectedly"
                Write-Message -Level Error "Miner $($Miner.StatusInfo)"
                $Miner.SetStatus([MinerStatus]::Failed)
                $Variables.Devices.Where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
            }
            Else { 
                If ($Miner.Benchmark -or $Miner.MeasurePowerConsumption) { 
                    If ($Miner.Activated -le 0) { $Miner.Restart = $true } # Re-benchmark sets Activated to 0
                }
                ElseIf ($Config.DryRun -and $Miner.Status -ne [MinerStatus]::DryRun) { $Miner.Restart = $true }
                ElseIf (-not $Config.DryRun -and $Miner.Status -eq [MinerStatus]::DryRun) { $Miner.Restart = $true }

                If ($Miner.Disabled -or $Miner.Restart -or -not $Miner.Best -or $Variables.NewMiningStatus -ne "Running") { 
                    ForEach ($Worker in $Miner.WorkersRunning) { 
                        If ($WatchdogTimers = $Variables.WatchdogTimers.Where({ $_.MinerName -eq $Miner.Name -and $_.PoolName -eq $Worker.Pool.Name -and $_.PoolRegion -eq $Worker.Pool.Region -and $_.AlgorithmVariant -eq $Worker.Pool.AlgorithmVariant -and $_.DeviceNames -eq $Miner.DeviceNames })) { 
                            # Remove Watchdog timers
                            $Variables.WatchdogTimers = $Variables.WatchdogTimers.Where({ $_ -notin $WatchdogTimers })
                        }
                    }
                    $Miner.SetStatus([MinerStatus]::Idle)
                    Remove-Variable WatchdogTimers, Worker -ErrorAction Ignore
                }
            }
            $Variables.Devices.Where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
        }
        Remove-Variable Miner, WatchdogTimers, Worker -ErrorAction Ignore

        # Kill stuck miners on subsequent cycles
        $MinerPaths = ($Miners.Path | Sort-Object -Unique).ForEach({ "$PWD\$($_)" })
        $Loops = 0
        While ($StuckMinerProcesses = (Get-CimInstance CIM_Process).Where({ $_.ExecutablePath -and $MinerPaths -contains $_.ExecutablePath -and $Miners.ProcessID -notcontains $_.ProcessID -and $Miners.ProcessID -notcontains $_.ParentProcessID}).ProcessId.ForEach({ (Get-Process -Id $_ -ErrorAction Ignore).Where({ $_.MainWindowTitle -match ".+ \{.+@.+\}" })})) { 
            ForEach ($StuckMinerProcess in $StuckMinerProcesses) { 
                Stop-Process -Id $StuckMinerProcess.Id -Force -ErrorAction Ignore | Out-Null
                # Some miners, e.g. HellMiner spawn child process(es) that may need separate killing
                $ChildProcesses = (Get-CimInstance win32_process -Filter "ParentProcessId = $($StuckMinerProcess.Id)")
                $ChildProcesses.ForEach({ Stop-Process -Id $_.ProcessId -Force -ErrorAction Ignore })
                If (-not (Get-Process -Id $StuckMinerProcess.Id -ErrorAction Ignore)) { 
                    Write-Message -Level Warn "Successfully stopped stuck miner '$($StuckMinerProcess.MainWindowTitle -replace "\} .+", "}")'."
                }
                Else { 
                    Write-Message -Level Warn "Found stuck miner '$($StuckMinerProcess.MainWindowTitle -replace "\} .+", "}")', trying to stop it..."
                }
            }
            Start-Sleep -Milliseconds 1000
            $Loops ++
            If ($Loops -gt 50) { 
                If ($Config.AutoReboot) { 
                    Write-Message -Level Error "$(If ($StuckMinerProcesses.Count -eq 1) { "A miner is" } Else { "Some miners are" }) stuck and cannot get stopped graciously. Restarting computer in 30 seconds..."
                    shutdown.exe /r /t 30 /c "$($Variables.Branding.ProductLabel) detected stuck miner$(If ($StuckMinerProcesses.Count -ne 1) { "s" }) and will reboot the computer in 30 seconds."
                    Start-Sleep -Seconds 60
                }
                Else { 
                    Write-Message -Level Error "$(If ($StuckMinerProcesses.Count -eq 1) { "A miner " } Else { "Some miners are" }) stuck and cannot get stopped graciously. It is recommended to restart the computer."
                    Start-Sleep -Seconds 30
                }
            }
        }
        Remove-Variable ChildProcesses, Loops, MinerPaths, StuckMinerProcess, StuckMinerProcesses -ErrorAction Ignore

        $Miners.ForEach(
            { 
                If ($_.Disabled) { 
                    $_.Status = [MinerStatus]::Disabled
                    $_.SubStatus = "disabled"
                }
                ElseIf (-not $_.Available) { 
                    $_.Status = [MinerStatus]::Unavailable
                    $_.SubStatus = "unavailable"
                }
                ElseIf ($_.Status -eq [MinerStatus]::Unavailable) { 
                    $_.Status = [MinerStatus]::Idle
                    $_.SubStatus = "idle"
                }
                ElseIf ($_.Status -eq [MinerStatus]::Idle) { 
                    $_.SubStatus = "idle"
                }
                ElseIf ($_.Status -eq [MinerStatus]::Failed) { 
                    $_.Status = [MinerStatus]::Idle
                    $_.StatusInfo = "Idle"
                    $_.SubStatus = "idle"
                    $Variables.Devices.Where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                }
            }
        )

        # Update data in API
        # Keep miners that have no available pool for 24hrs
        $Variables.Miners = $Miners.Where({ $_.Updated -ge $Variables.BeginCycleTime.AddDays(-1) }) | Sort-Object -Property Info
        $Variables.MinersBest = $MinersBest | Sort-Object { $_.BaseName_Version_Device -replace ".+-" }
        $Variables.MinersOptimal = $MinersOptimal | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, { $_.BaseName_Version_Device -replace ".+-" }, @{ Expression = $Bias; Descending = $true }
        Remove-Variable Bias, Miners, MinersBest, MinersOptimal -ErrorAction Ignore

        $Variables.Miners.ForEach({ $_.PSObject.Properties.Remove("SideIndicator") })

        If (-not $Variables.MinersBest) { 
            $Message = "No profitable miners - will retry in $($Config.Interval) seconds..."
            Write-Message -Level Warn $Message
            $Variables.Summary = $Message
            Remove-Variable Message

            Clear-PoolData
            Clear-MinerData

            $Variables.RefreshNeeded = $true

            Start-Sleep -Seconds $Config.Interval

            Write-Message -Level Info "Ending cycle."
            Continue
        }

        # Core suspended with <Ctrl><Alt>P in MainLoop
        While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

        # Optional delay to avoid blue screens
        Start-Sleep -Seconds $Config.Delay

        ForEach ($Miner in $Variables.MinersBest) { 

            $DataCollectInterval = If ($Miner.Benchmark -or $Miner.MeasurePowerConsumption) { If ($Config.DryRun -and $Config.BenchmarkAllPoolAlgorithmCombinations) { 0.5 } Else { 1 } } Else { 5 }

            If ($Miner.Status -ne [MinerStatus]::DryRun -and $Miner.GetStatus() -ne [MinerStatus]::Running) { 
                If ($Config.DryRun -and -not ($Miner.Benchmark -or $Miner.MeasurePowerConsumption)) { 
                    $Miner.SetStatus([MinerStatus]::DryRun)
                }
                Else { 
                    # Launch prerun if exists
                    If (Test-Path -LiteralPath ".\Utils\Prerun\$($Miner.Type)Prerun.bat" -PathType Leaf) { 
                        Write-Message -Level Info "Launching Prerun: .\Utils\Prerun\$($Miner.Type)Prerun.bat"
                        Start-Process ".\Utils\Prerun\$($Miner.Type)Prerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                        Start-Sleep -Seconds 2
                    }
                    $MinerAlgorithmPrerunName = ".\Utils\Prerun\$($Miner.BaseName_Version_Device)_$($Miner.Algorithms -join "&").bat"
                    $AlgorithmPrerunName = ".\Utils\Prerun\$($Miner.Algorithms -join "&").bat"
                    $DefaultPrerunName = ".\Utils\Prerun\default.bat"
                    If (Test-Path -LiteralPath $MinerAlgorithmPrerunName -PathType Leaf) { 
                        Write-Message -Level Info "Launching Prerun: $MinerAlgorithmPrerunName"
                        Start-Process $MinerAlgorithmPrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                        Start-Sleep -Seconds 2
                    }
                    ElseIf (Test-Path -LiteralPath $AlgorithmPrerunName -PathType Leaf) { 
                        Write-Message -Level Info "Launching Prerun: $AlgorithmPrerunName"
                        Start-Process $AlgorithmPrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                        Start-Sleep -Seconds 2
                    }
                    ElseIf (Test-Path -LiteralPath $DefaultPrerunName -PathType Leaf) { 
                        Write-Message -Level Info "Launching Prerun: $DefaultPrerunName"
                        Start-Process $DefaultPrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                        Start-Sleep -Seconds 2
                    }
                    Remove-Variable AlgorithmPrerunName, DefaultPrerunName, MinerAlgorithmPrerunName -ErrorAction Ignore

                    If ($Miner.Workers.Pool.DAGSizeGiB) { 
                        # Add extra time when CPU mining and miner requires DAG creation
                        If ($Variables.MinersBest.Type -contains "CPU") { $Miner.WarmupTimes[0] += 15 <# seconds #> }
                        # Add extra time when notebook runs on battery
                        If ((Get-CimInstance Win32_Battery).BatteryStatus -eq 1) { $Miner.WarmupTimes[0] += 60 <# seconds #> }
                    }

                    #  Do not wait for stable hash rates, for quick and dirty benchmarking
                    If ($Config.DryRun -and $Variables.BenchmarkAllPoolAlgorithmCombinations) { $Miner.WarmupTimes[1] = 0 }

                    $Miner.DataCollectInterval = $DataCollectInterval
                    $Miner.SetStatus([MinerStatus]::Running)
                }
                $Variables.Devices.Where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })

                # Add watchdog timer
                If ($Config.Watchdog) { 
                    ForEach ($Worker in $Miner.Workers) { 
                        $Variables.WatchdogTimers.Add(
                            [PSCustomObject]@{ 
                                Algorithm                    = $Worker.Pool.Algorithm
                                AlgorithmVariant             = $Worker.Pool.AlgorithmVariant
                                CommandLine                  = $Miner.CommandLine
                                DeviceNames                  = $Miner.DeviceNames
                                Kicked                       = [DateTime]::Now.ToUniversalTime()
                                MinerBaseName                = $Miner.BaseName
                                MinerBaseName_Version        = $Miner.BaseName_Version
                                MinerBaseName_Version_Device = $Miner.BaseName_Version_Device
                                MinerName                    = $Miner.Name
                                MinerVersion                 = $Miner.Version
                                PoolKey                      = $Worker.Pool.Key
                                PoolName                     = $Worker.Pool.Name
                                PoolRegion                   = $Worker.Pool.Region
                                PoolVariant                  = $Worker.Pool.Variant
                            }
                        )
                    }
                    Remove-Variable Worker -ErrorAction Ignore
                }
            }
            ElseIf ($Miner.DataCollectInterval -ne $DataCollectInterval) { 
                $Miner.DataCollectInterval = $DataCollectInterval
                $Miner.RestartDataReader()
            }
        }

        ForEach ($Miner in $Variables.MinersBest) { 
            If ($Message = "$(If ($Miner.Benchmark) { "Benchmarking" })$(If ($Miner.Benchmark -and $Miner.MeasurePowerConsumption) { " and measuring power consumption" } ElseIf ($Miner.MeasurePowerConsumption) { "Measuring power consumption" })") { 
                Write-Message -Level Verbose "$Message for miner '$($Miner.Info)' in progress [Attempt $($Miner.Activated) of $($Variables.WatchdogCount + 1); min. $($Miner.MinDataSample) sample$(If ($Miner.MinDataSample -ne 1) { "s" })]..."
            }
        }
        Remove-Variable DataCollectInterval, Miner, Message -ErrorAction Ignore

        If ($Variables.MinersNeedingBenchmark) { Write-Message -Level Info "Benchmarking: $($Variables.MinersNeedingBenchmark.Count) $(If ($Variables.MinersNeedingBenchmark.Count -eq 1) { "miner" } Else { "miners" }) left [$((($Variables.MinersNeedingBenchmark | Group-Object { $_.BaseName_Version_Device -replace ".+-" }).ForEach({ "$($_.Group[0].BaseName_Version_Device -replace(".+-")): $($_.Count)" }) | Sort-Object) -join ", ")]" }
        If ($Variables.MinersNeedingPowerConsumptionMeasurement) { Write-Message -Level Info "Measuring power consumption: $($Variables.MinersNeedingPowerConsumptionMeasurement.Count) $(If ($Variables.MinersNeedingPowerConsumptionMeasurement.Count -eq 1) { "miner" } Else { "miners" }) left [$((($Variables.MinersNeedingPowerConsumptionMeasurement | Group-Object { $_.BaseName_Version_Device -replace ".+-" }).ForEach({ "$($_.Group[0].BaseName_Version_Device -replace(".+-")): $($_.Count)" }) | Sort-Object) -join ", ")]" }

        $Variables.MinersRunning = $Variables.MinersBest
        $Variables.MinersBenchmarkingOrMeasuring = $Variables.MinersRunning.Where({ $_.Benchmark -or $_.MeasurePowerConsumption })
        $Variables.MinersFailed = [Miner[]]@()

        # Core suspended with <Ctrl><Alt>P in MainLoop
        While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

        $Variables.RefreshTimestamp = [DateTime]::Now.ToUniversalTime()
        $Variables.RefreshNeeded = $true

        Write-Message -Level Info "Collecting miner data while waiting for end of cycle..."

        # Ensure a cycle on first loop
        If ($Variables.CycleStarts.Count -eq 1) { $Variables.EndCycleTime = [DateTime]::Now.ToUniversalTime().AddSeconds($Config.Interval) }

        Do { 
            $LoopEnd = If ($Config.DryRun -and $Config.BenchmarkAllPoolAlgorithmCombinations) { [DateTime]::Now.AddSeconds(0.5) } Else { [DateTime]::Now.AddSeconds(1) }

            # Wait until 1 (0.5) second since loop start has passed
            While ([DateTime]::Now -le $LoopEnd) { Start-Sleep -Milliseconds 50 }

            Try { 
                ForEach ($Miner in $Variables.MinersRunning.Where({ $_.Status -ne [MinerStatus]::DryRun })) { 
                    If ($Miner.GetStatus() -ne [MinerStatus]::Running) { 
                        # Miner crashed
                        $Miner.StatusInfo = "$($Miner.Info) ($($Miner.Data.Count) Sample$(If ($Miner.Data.Count -ne 1) { "s" })) exited unexpectedly"
                        Write-Message -Level Error "Miner $($Miner.StatusInfo)"
                        $Miner.SetStatus([MinerStatus]::Failed)
                        $Variables.Devices.Where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                        $Variables.MinersFailed += $Miner
                    }
                    Else { 
                        If ($Miner.DataReaderJob.HasMoreData) { 
                            If ($Samples = @($Miner.DataReaderJob | Receive-Job).Where({ $_.Hashrate.PSObject.Properties.Name })) { 
                                $Sample = $Samples[-1]
                                $Miner.Hashrates_Live = $Sample.Hashrate.PSObject.Properties.Value
                                $Miner.DataSampleTimestamp = $Sample.Date
                                If ($Miner.ReadPowerConsumption) { $Miner.PowerConsumption_Live = $Sample.PowerConsumption }
                                # Need hashrates for all algorithms to count as a valid sample
                                If ($Miner.ValidDataSampleTimestamp -eq [DateTime]0 -and [Double[]]$Sample.Hashrate.PSObject.Properties.Value -notcontains 0) { $Miner.ValidDataSampleTimestamp = $Sample.Date.AddSeconds($Miner.WarmupTimes[1]) }
                                If (($Miner.ValidDataSampleTimestamp -ne [DateTime]0 -and ($Sample.Date - $Miner.ValidDataSampleTimestamp) -ge 0)) { 
                                    $Samples.Where({ $_.Date -ge $Miner.ValidDataSampleTimestamp -and [Double[]]$_.Hashrate.PSObject.Properties.Value -notcontains 0 }).ForEach({ $Miner.Data.Add($_) | Out-Null })
                                    Write-Message -Level Verbose "$($Miner.Name) data sample collected [$(($Sample.Hashrate.PSObject.Properties.Name.ForEach({ "$($_): $(([Double]$Sample.Hashrate.$_ | ConvertTo-Hash) -replace " ")$(If ($Config.ShowShares) { " (Shares: A$($Sample.Shares.$_[0])+R$($Sample.Shares.$_[1])+I$($Sample.Shares.$_[2])=T$($Sample.Shares.$_[3]))" })" })) -join " & ")$(If ($Sample.PowerConsumption) { " | Power: $($Sample.PowerConsumption.ToString("N2"))W" })] ($($Miner.Data.Count) Sample$(If ($Miner.Data.Count -ne 1) { "s" }))"
                                    If ($Miner.Activated -gt 0 -and ($Miner.Benchmark -or $Miner.MeasurePowerConsumption)) { 
                                        $Miner.StatusInfo = "$($Miner.Info) is $(If ($Miner.Benchmark) { "benchmarking" })$(If ($Miner.Benchmark -and $Miner.MeasurePowerConsumption) { " and measuring power consumption" } ElseIf ($Miner.MeasurePowerConsumption) { "measuring power consumption" })"
                                        $Miner.SubStatus = "benchmarking"
                                    }
                                    Else { 
                                        $Miner.StatusInfo = "$($Miner.Info) is mining"
                                        $Miner.SubStatus = "running"
                                    }
                                }
                                ElseIf (-not $Config.Ignore0HashrateSample -or $Miner.ValidDataSampleTimestamp -ne [DateTime]0) { 
                                    Write-Message -Level Verbose "$($Miner.Name) data sample discarded [$(($Sample.Hashrate.PSObject.Properties.Name.ForEach({ "$($_): $(([Double]$Sample.Hashrate.$_ | ConvertTo-Hash) -replace " ")$(If ($Config.ShowShares) { " (Shares: A$($Sample.Shares.$_[0])+R$($Sample.Shares.$_[1])+I$($Sample.Shares.$_[2])=T$($Sample.Shares.$_[3]))" })" })) -join " & ")$(If ($Sample.PowerConsumption) { " | Power: $($Sample.PowerConsumption.ToString("N2"))W" })]$(If ($Miner.ValidDataSampleTimestamp -ne [DateTime]0) { " (Miner is warming up [$(([DateTime]::Now.ToUniversalTime() - $Miner.ValidDataSampleTimestamp).TotalSeconds.ToString("0") -replace "-0", "0") sec])" })"
                                    $Miner.StatusInfo = "$($Miner.Info) is warming up"
                                    $Miner.SubStatus = "warmingup"
                                }
                            }
                        }

                        # Set process priority and window title
                        Try { 
                            $Miner.Process.PriorityClass = $Global:PriorityNames.($Miner.ProcessPriority)
                            [Void][Win32]::SetWindowText($Miner.Process.MainWindowHandle, $Miner.StatusInfo)
                        } Catch { }

                        # Stop miner, it has not provided hash rate on time
                        If ($Miner.ValidDataSampleTimestamp -eq [DateTime]0 -and [DateTime]::Now.ToUniversalTime() -gt $Miner.BeginTime.AddSeconds($Miner.WarmupTimes[0])) { 
                            $Miner.StatusInfo = "$($Miner.Info) has not provided first valid data sample in $($Miner.WarmupTimes[0]) seconds"
                            Write-Message -Level Error "Miner $($Miner.StatusInfo)"
                            $Miner.SetStatus([MinerStatus]::Failed)
                            $Variables.Devices.Where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                            $Variables.MinersFailed += $Miner
                        }
                        # Miner stuck - no sample received in last few data collect intervals
                        ElseIf ($Miner.ValidDataSampleTimestamp -gt [DateTime]0 -and [DateTime]::Now.ToUniversalTime() -gt $Miner.DataSampleTimestamp.AddSeconds((($Miner.DataCollectInterval * 5), 10 | Measure-Object -Maximum).Maximum * $Miner.Algorithms.Count)) { 
                            $Miner.StatusInfo = "$($Miner.Info) has not updated data for more than $((($Miner.DataCollectInterval * 5), 10 | Measure-Object -Maximum).Maximum * $Miner.Algorithms.Count) seconds"
                            Write-Message -Level Error "Miner $($Miner.StatusInfo)"
                            $Miner.SetStatus([MinerStatus]::Failed)
                            $Variables.Devices.Where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                            $Variables.MinersFailed += $Miner
                        }
                    }
                    $Variables.Devices.Where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                }
                Remove-Variable Miner, Sample, Samples -ErrorAction Ignore

                $Variables.MinersRunning = $Variables.MinersRunning.Where({ $_ -notin $Variables.MinersFailed })
                $Variables.MinersBenchmarkingOrMeasuring = $Variables.MinersRunning.Where({ $_.Benchmark -or $_.MeasurePowerConsumption })

                If ($Variables.MinersFailed) { 
                    # A miner crashed , exit loop immediately
                    $Variables.EndCycleMessage = " prematurely (miner failed)"
                }
                ElseIf ($Variables.MinersBenchmarkingOrMeasuring.Where({ $_.Data.Count -ge $_.MinDataSample })) { 
                    # Enough samples collected for this loop, exit loop immediately
                    $Variables.EndCycleMessage = " (a$(If ($Variables.MinersBenchmarkingOrMeasuring.Where({ $_.Benchmark })) { " benchmarking" })$(If ($Variables.MinersBenchmarkingOrMeasuring.Where({ $_.Benchmark -and $_.MeasurePowerConsumption })) { " and" })$(If ($Variables.MinersBenchmarkingOrMeasuring.Where({ $_.MeasurePowerConsumption })) { " power consumption measuring" }) miner has collected enough samples for this cycle)"
                }
            }
            Catch { 
                Write-Message -Level Error "Error in file '$(($_.InvocationInfo.ScriptName -split "\\" | Select-Object -Last 2) -join "\")' line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting cycle..."
                "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $ErrorLogFile
                $_.Exception | Format-List -Force >> $ErrorLogFile
                $_.InvocationInfo | Format-List -Force >> $ErrorLogFile
            }

            # Core suspended with <Ctrl><Alt>P in MainLoop
            While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

            # Exit loop when
            # - end cycle message is set
            # - when not benchmarking: Interval time is over
            # - no more running miners
        } While ($Variables.NewMiningStatus -eq "Running" -and -not $Variables.EndCycleMessage -and (([DateTime]::Now.ToUniversalTime() -le $Variables.EndCycleTime) -or $Variables.MinersBenchmarkingOrMeasuring.Where({ $_.Status -ne [MinerStatus]::DryRun })))
        Remove-Variable LoopEnd

        # Set end cycle time to end brains loop to collect data
        If ($Variables.EndCycleMessage -or $Config.DryRun) { 
            $Variables.EndCycleTime = [DateTime]::Now.ToUniversalTime()
            Start-Sleep -Seconds 1
        }

        Get-Job -State "Completed" | Receive-Job | Out-Null
        Get-Job -State "Completed" | Remove-Job -Force -ErrorAction Ignore | Out-Null
        Get-Job -State "Failed" | Receive-Job | Out-Null
        Get-Job -State "Failed" | Remove-Job -Force -ErrorAction Ignore | Out-Null
        Get-Job -State "Stopped" | Receive-Job | Out-Null
        Get-Job -State "Stopped" | Remove-Job -Force -ErrorAction Ignore | Out-Null

        If ($Error) { 
            $Variables.CoreError += $Error
            $Error.Clear()
        }
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()

        # Core suspended with <Ctrl><Alt>P in MainLoop
        While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

        $Variables.RestartCycle = $true

        If ($Variables.NewMiningStatus -eq "Running" -and $Variables.EndCycleTime) { Write-Message -Level Info "Ending cycle$($Variables.EndCycleMessage)." }

    } While ($Variables.NewMiningStatus -eq "Running")
}
Catch { 
    Write-Message -Level Error "Error in file '$(($_.InvocationInfo.ScriptName -split "\\" | Select-Object -Last 2) -join "\")' line $($_.InvocationInfo.ScriptLineNumber) detected."
    "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $ErrorLogFile
    $_.Exception | Format-List -Force >> $ErrorLogFile
    $_.InvocationInfo | Format-List -Force >> $ErrorLogFile
    # Reset timers
    $Variables.EndCycleTime = [DateTime]::Now.ToUniversalTime()
}