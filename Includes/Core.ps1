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
File:           Core.ps1
Version:        6.2.15
Version date:   2024/07/07
#>

using module .\Include.psm1

$ErrorLogFile = "Logs\Error.txt"

If ($Config.Transcript) { Start-Transcript -Path ".\Debug\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)-Transcript_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log" }

(Get-ChildItem -Path ".\Includes\MinerAPIs" -File).ForEach({ . $_.FullName })

Do { 
    Try { 
        $Variables.EndCycleMessage = ""

        # Set master timer
        $Variables.Timer = [DateTime]::Now.ToUniversalTime()

        # Internet connection must be available
        If ($NetRoute = ((Get-NetRoute).Where({ $_.DestinationPrefix -eq "0.0.0.0/0" }) | Get-NetIPInterface).Where({ $_.ConnectionState -eq "Connected" })) { 
            $MyIP = ((Get-NetIPAddress -InterfaceIndex $NetRoute.ifIndex -AddressFamily IPV4).IPAddress)
        }
        If ($MyIP) { 
            $Variables.MyIP = $MyIP
            Remove-Variable MyIp, NetRoute -ErrorAction Ignore
        }
        Else { 
            $Variables.Summary = "No internet connection - will retry in 60 seconds..."
            Write-Message -Level Error $Variables.Summary
            $Variables.MyIP = $null
            $Variables.RefreshNeeded = $true
            $Variables.RestartCycle = $true
 
            #Stop all miners
            ForEach ($Miner in $Variables.Miners.Where({ $_.Status -ne [MinerStatus]::Idle })) { 
                $Miner.SetStatus([MinerStatus]::Idle)
                $Variables.Devices.Where({ $_.Name -in $Miner.DeviceNames }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
            }
            Remove-Variable Miner -ErrorAction Ignore
            $Variables.RunningMiners = [Miner[]]@()
            $Variables.BenchmarkingOrMeasuringMiners = [Miner[]]@()
            $Variables.FailedMiners = [Miner[]]@()
            $Variables.MinersBest = [Miner[]]@()
            $Variables.MiningEarning = $Variables.MiningProfit = $Variables.MiningPowerCost = $Variables.MiningPowerConsumption = [Double]0
            Start-Sleep -Seconds 60
            Continue
        }

        If ($Variables.NewMiningStatus -eq "Running") { 
            # Read config only if config files have changed
            If ((Test-Path -Path $Variables.PoolsConfigFile) -and (Test-Path -Path $Variables.ConfigFile)) { 
                If ($Variables.ConfigFileTimestamp -ne (Get-Item -Path $Variables.ConfigFile).LastWriteTime -or $Variables.PoolsConfigFileTimestamp -ne (Get-Item -Path $Variables.PoolsConfigFile).LastWriteTime) { 
                    [Void](Read-Config -ConfigFile $Variables.ConfigFile)
                    Write-Message -Level Verbose "Activated changed configuration."
                }
            }
        }
    
        $Variables.PoolsConfig = $Config.PoolsConfig.Clone()

        # Tuning parameters require local admin rights
        $Variables.UseMinerTweaks = $Variables.IsLocalAdmin -and $Config.UseMinerTweaks

        Write-Message -Level Info "Started new cycle."

        # Must clear all existing miners due to different miner names
        If ($Config.BenchmarkAllPoolAlgorithmCombinations -ne $Variables.BenchmarkAllPoolAlgorithmCombinations) { 
            # Stop all running miners
            ForEach ($Miner in $Variables.Miners.Where({ $_.Status -in @([MinerStatus]::DryRun, [MinerStatus]::Running) })) { 
                $Miner.SetStatus([MinerStatus]::Idle)
                $Variables.Devices.Where({ $_.Name -in $Miner.DeviceNames }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
            }
            $Variables.Miners = [Miner[]]@()
        }

        # Use values from config
        $Variables.BenchmarkAllPoolAlgorithmCombinations = $Config.BenchmarkAllPoolAlgorithmCombinations
        $Variables.PoolName = $Config.PoolName
        $Variables.NiceHashWalletIsInternal = $Config.NiceHashWalletIsInternal
        $Variables.PoolTimeout = [Math]::Floor($Config.PoolTimeout)

        If ($Variables.EnabledDevices = [Device[]]@($Variables.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Config.ExcludeDeviceName }).ForEach({ $_ | Select-Object -Property * }))) { 
            # Update enabled devices
            $Variables.EnabledDevices.ForEach(
                { 
                    # Miner name must not contain spaces
                    $_.Model = $_.Model -replace ' '
                    If ($_.Type -eq "GPU") { 
                        # For GPUs set type equal to vendor
                        $_.Type = $_.Vendor
                        # Remove model information from devices -> will create only one miner instance
                        If (-not $Config.MinerInstancePerDeviceModel) { $_.Model = $_.Vendor }
                    }
                }
            )

            # Skip some stuff when previous cycle was shorter than half of what it should
            If ((-not $Variables.Pools -or $Variables.EndCycleTime) -and (-not $Variables.Miners -or -not $Variables.BeginCycleTime -or (Compare-Object @($Config.PoolName | Select-Object) @($Variables.PoolName | Select-Object)) -or $Variables.BeginCycleTime.AddSeconds([Math]::Floor($Config.Interval / 2)) -lt [DateTime]::Now.ToUniversalTime() -or ((Compare-Object @($Config.ExtraCurrencies | Select-Object) @($Variables.AllCurrencies | Select-Object)).Where({ $_.SideIndicator -eq "<=" })))) {
                $Variables.BeginCycleTime = $Variables.Timer
                $Variables.EndCycleTime = $Variables.Timer.AddSeconds($Config.Interval)

                $Variables.CycleStarts += $Variables.Timer
                $Variables.CycleStarts = @($Variables.CycleStarts | Sort-Object -Bottom (3, ($Config.SyncWindow + 1) | Measure-Object -Maximum).Maximum)

                # Set minimum Watchdog count 3
                $Variables.WatchdogCount = (3, $Config.WatchdogCount | Measure-Object -Maximum).Maximum
                $Variables.WatchdogReset = $Variables.WatchdogCount * $Variables.WatchdogCount * $Variables.WatchdogCount * $Variables.WatchdogCount * $Config.Interval

                # Expire watchdog timers
                If ($Config.Watchdog) { $Variables.WatchdogTimers = @($Variables.WatchdogTimers.Where({ $_.Kicked -ge $Variables.Timer.AddSeconds( - $Variables.WatchdogReset) })) }
                Else { $Variables.WatchdogTimers = [PSCustomObject[]]@() }

                # Check for new version
                If ($Config.AutoUpdateCheckInterval -and $Variables.CheckedForUpdate -lt [DateTime]::Now.AddDays(-$Config.AutoUpdateCheckInterval)) { Get-Version }

                # Load unprofitable algorithms
                Try { 
                    If (-not $Variables.UnprofitableAlgorithms -or (Get-ChildItem -Path ".\Data\UnprofitableAlgorithms.json").LastWriteTime -gt $Variables.Timer.AddSeconds( - $Config.Interval)) { 
                        $Variables.UnprofitableAlgorithms = [System.IO.File]::ReadAllLines("$PWD\Data\UnprofitableAlgorithms.json") | ConvertFrom-Json -ErrorAction Stop -AsHashtable | Get-SortedObject
                        Write-Message -Level Info "Loaded list of unprofitable algorithms ($($Variables.UnprofitableAlgorithms.Count) $(If ($Variables.UnprofitableAlgorithms.Count -ne 1) { "entries" } Else { "entry" }))."
                    }
                }
                Catch { 
                    Write-Message -Level Error "Error loading list of unprofitable algorithms. File '.\Data\UnprofitableAlgorithms.json' is not a valid $($Variables.Branding.ProductLabel) JSON data file. Please restore it from your original download."
                    $Variables.UnprofitableAlgorithms = @{ }
                }

                If ($Config.Donation -gt 0) { 
                    If (-not $Variables.DonationStart) { 
                        # Re-Randomize donation start and data once per day, do not donate if remaing time for today is less than donation duration
                        If (($Variables.DonationLog.Start | Sort-Object -Bottom 1).Date -ne [DateTime]::Today) { 
                            If ($Config.Donation -lt (1440 - [Math]::Floor([DateTime]::Now.TimeOfDay.TotalMinutes))) { 
                                $Variables.DonationStart = [DateTime]::Now.AddMinutes((Get-Random -Minimum 0 -Maximum (1440 - [Math]::Floor([DateTime]::Now.TimeOfDay.TotalMinutes) - $Config.Donation)))
                            }
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
                        # Use donation pool config
                        $Variables.PoolName = $Variables.DonationRandomPoolsConfig.Keys
                        $Variables.PoolsConfig = $Variables.DonationRandomPoolsConfig
                        $Variables.NiceHashWalletIsInternal = $false
                    }
                    Else { 
                        # Donation end
                        $Variables.DonationLog = $Variables.DonationLog | Select-Object -Last 365 # Keep data for one year
                        [Array]$Variables.DonationLog += [PSCustomObject]@{ 
                            Start = $Variables.DonationStart
                            End   = $Variables.DonationEnd
                            Name  = $Variables.DonationRandom.Name
                        }
                        $Variables.DonationLog | ConvertTo-Json | Out-File -LiteralPath ".\Logs\DonateLog.json" -Force -ErrorAction Ignore
                        $Variables.DonationRandomPoolsConfig = $null
                        $Variables.DonationStart = $null
                        $Variables.DonationEnd = $null
                        $Variables.PoolsConfig = $Config.PoolsConfig.Clone()
                        Write-Message -Level Info "Donation run complete - thank you! Mining for you again. :-)"
                        $Variables.DonationRunning = $false
                    }
                }

                # Stop / Start brain background jobs
                $Brains = $Variables.Brains.psBase.Keys # Error 'Collection was modified; enumeration operation may not execute'
                [Void](Stop-Brain @($Brains.Where({ $_ -notin @(Get-PoolBaseName $Variables.PoolName) })))
                Remove-Variable Brains
                [Void](Start-Brain @(Get-PoolBaseName $Variables.PoolName))

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
                } Catch {}
                Remove-Variable Keys, StatFiles -ErrorAction Ignore

                # Load currency exchange rates
                [Void](Get-Rate)

                # Get DAG data
                [Void](Update-DAGdata)

                # Core suspended with <Ctrl><Alt>P in MainLoop
                While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

                # Power cost preparations
                If ($Variables.CalculatePowerCost = $Config.CalculatePowerCost) { 
                    If ($Variables.EnabledDevices.Count -ge 1) { 
                        # HWiNFO64 verification
                        $RegKey = "HKCU:\Software\HWiNFO64\VSB"
                        If ($RegValue = Get-ItemProperty -Path $RegKey -ErrorAction Ignore) { 
                            If ([String]$Variables.HWInfo64RegValue -eq [String]$RegValue) { 
                                Write-Message -Level Warn "Power consumption data in registry has not been updated [HWiNFO64 not running???] - disabling power consumption and profit calculations."
                                $Variables.CalculatePowerCost = $false
                            }
                            Else { 
                                $Variables.HWInfo64RegValue = $RegValue
                                $PowerConsumptionData = @{ }
                                $DeviceName = ""
                                $RegValue.PSObject.Properties.Where({ $_.Name -match '^Label[0-9]+$' -and (Compare-Object @($_.Value -split ' ' | Select-Object) @($Variables.EnabledDevices.Name) -IncludeEqual -ExcludeDifferent) }).ForEach(
                                    { 
                                        $DeviceName = ($_.Value -split ' ')[-1]
                                        Try { 
                                            $PowerConsumptionData[$DeviceName] = $RegValue.($_.Name -replace 'Label', 'Value')
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
                                            If ($_ -in $Variables.EnabledDevices.Name -and -not $PowerConsumptionData.$_) { Write-Message -Level Warn "HWiNFO64 cannot read power consumption data for device ($_). Using configured value of $ConfiguredPowerConsumption)W." }
                                            $PowerConsumptionData[$_] = "$ConfiguredPowerConsumption W"
                                        }
                                        $Variables.EnabledDevices.Where({ $_.Name -eq $DeviceName }).ForEach({ $_.ConfiguredPowerConsumption = $ConfiguredPowerConsumption })
                                        $Variables.Devices.Where({ $_.Name -eq $DeviceName }).ForEach({ $_.ConfiguredPowerConsumption = $ConfiguredPowerConsumption })
                                    }
                                )
                                If ($DeviceNamesMissingSensor = (Compare-Object @($Variables.EnabledDevices.Name) @($PowerConsumptionData.psBase.Keys) -PassThru).Where({ $_.SideIndicator -eq "<=" })) { 
                                    Write-Message -Level Warn "HWiNFO64 sensor naming is invalid [missing sensor configuration for $($DeviceNamesMissingSensor -join ', ')] - disabling power consumption and profit calculations."
                                    $Variables.CalculatePowerCost = $false
                                }
                                Remove-Variable DeviceNamesMissingSensor

                                # Enable read power consumption for configured devices
                                $Variables.EnabledDevices.ForEach({ $_.ReadPowerConsumption = $_.Name -in $PowerConsumptionData.psBase.Keys })
                                Remove-Variable ConfiguredPowerConsumption, DeviceName, PowerConsumptionData -ErrorAction Ignore
                            }
                        }
                        Else { 
                            Write-Message -Level Warn "Cannot read power consumption data from registry [Key '$RegKey' does not exist - HWiNFO64 not running???] - disabling power consumption and profit calculations."
                            $Variables.CalculatePowerCost = $false
                        }
                        Remove-Variable RegKey, RegValue -ErrorAction Ignore
                    }
                    Else { $Variables.CalculatePowerCost = $false }
                }
                Else { 
                    $Variables.EnabledDevices.ForEach({ $_.ReadPowerConsumption = $false })
                }

                # Power price
                If (-not $Config.PowerPricekWh.psBase.Keys) { $Config.PowerPricekWh."00:00" = 0 }
                ElseIf ($null -eq $Config.PowerPricekWh."00:00") { 
                    # 00:00h power price is the same as the latest price of the previous day
                    $Config.PowerPricekWh."00:00" = $Config.PowerPricekWh.($Config.PowerPricekWh.psBase.Keys | Sort-Object -Bottom 1)
                }
                $Variables.PowerPricekWh = [Double]($Config.PowerPricekWh.($Config.PowerPricekWh.psBase.Keys.Where({ $_ -le (Get-Date -Format HH:mm).ToString() }) | Sort-Object -Bottom 1))
                $Variables.PowerCostBTCperW = [Double](1 / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates.($Config.PayoutCurrency).($Config.MainCurrency))

                # Core suspended with <Ctrl><Alt>P in MainLoop
                While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

                # Collect pool data
                $Variables.PoolsCount = $Variables.Pools.Count

                If ($Variables.PoolName) { 
                    # Wait for pool data message
                    If ($Variables.Brains.psBase.Keys.Where({ $Variables.Brains[$_].StartTime -gt $Variables.Timer.AddSeconds(- $Config.Interval) })) {
                        # Newly started brains, allow extra time for brains to get ready
                        $Variables.PoolTimeout = 60
                        $Message = "Requesting initial pool data from $((Get-PoolBaseName $Variables.PoolName) -join ', ' -replace ',([^,]*)$', ' &$1').<br>This may take up to $($Variables.PoolTimeout) seconds..."
                        If ($Variables.CycleStarts.Count -le 1) { 
                            $Variables.Summary = $Message
                            $Variables.RefreshNeeded = $true
                        }
                        Write-Message -Level Info ($Message -replace '<br>', ' ')
                        Remove-Variable Message
                    }
                    Else { 
                        Write-Message -Level Info "Requesting pool data from $((Get-PoolBaseName $Variables.PoolName) -join ', ' -replace ',([^,]*)$', ' &$1')..."
                    }

                    # Wait for all brains
                    $PoolDataCollectedTimeStamp = If ($Variables.PoolDataCollectedTimeStamp) { $Variables.PoolDataCollectedTimeStamp } Else { $Variables.ScriptStartTime }
                    While ([DateTime]::Now.ToUniversalTime() -lt $Variables.Timer.AddSeconds($Variables.PoolTimeout) -and ($Variables.Brains.psBase.Keys.Where({ $Variables.Brains[$_] -and $Variables.Brains[$_].Updated -lt $PoolDataCollectedTimeStamp }))) { 
                        Start-Sleep -Seconds 1
                    }

                    $Variables.PoolsNew = $Variables.PoolName.ForEach(
                        { 
                            $PoolName = Get-PoolBaseName $_
                            If (Test-Path -LiteralPath ".\Pools\$PoolName.ps1") { 
                                Try { 
                                    & ".\Pools\$PoolName.ps1" -Config $Config -PoolVariant $_ -Variables $Variables
                                }
                                Catch { 
                                    Write-Message -Level Error "Error in pool file 'Pools\$PoolName.ps1'."
                                    "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $ErrorLogFile
                                    $_.Exception | Format-List -Force >> $ErrorLogFile
                                    $_.InvocationInfo | Format-List -Force >> $ErrorLogFile
                                }
                            }
                        }
                    ).Where(
                        { 
                            $_.Updated -gt $PoolDataCollectedTimeStamp
                        }
                    ).ForEach(
                        { 
                            $Pool = [Pool]$_
                            $Pool.Fee = If ($Config.IgnorePoolFee -or $Pool.Fee -lt 0 -or $Pool.Fee -gt 1) { 0 } Else { $Pool.Fee }
                            $Factor = $Pool.EarningsAdjustmentFactor * (1 - $Pool.Fee)
                            $Pool.Price *= $Factor
                            $Pool.Price_Bias = $Pool.Price * $Pool.Accuracy
                            $Pool.StablePrice *= $Factor
                            $Pool.CoinName = $Variables.CoinNames[$Pool.Currency]
                            $Pool
                        }
                    )
                    Remove-Variable Factor, Pool, PoolDataCollectedTimeStamp, PoolName -ErrorAction Ignore

                    If ($PoolsWithoutData = Compare-Object @($Variables.PoolName) @($Variables.PoolsNew.Variant | Sort-Object -Unique) -PassThru) { 
                        Write-Message -Level Warn "No data received from pool$(If ($PoolsWithoutData.Count -gt 1) { "s" }) $($PoolsWithoutData -join ', ' -replace ',([^,]*)$', ' &$1')."
                    }
                    Remove-Variable PoolsWithoutData
                    $Variables.PoolDataCollectedTimeStamp = [DateTime]::Now.ToUniversalTime()

                    # Expire pools that have not been updated for 1 day
                    $Timestamp = [DateTime]::Now.ToUniversalTime().AddHours(-24)
                    $Variables.PoolsExpired = @($Variables.Pools.Where({ $_.Updated -lt $Timestamp }))
                    $Variables.Pools = $Variables.Pools.Where({ $_.Updated -ge $Timestamp })
                    Remove-Variable Timestamp

                    # Remove de-configured pools
                    $PoolsDeconfiguredCount = $Variables.Pools.Where({ $_.Variant -notin $Variables.PoolName }).Count

                    If ($Pools = Compare-Object @($Variables.PoolsNew | Select-Object) @($Variables.Pools.Where({ $_.Variant -in $Variables.PoolName }) | Select-Object) -Property Algorithm, Currency, Variant -IncludeEqual -PassThru) { 
                        # Find added & updated pools
                        $Variables.PoolsAdded = $Pools.Where({ $_.SideIndicator -eq "<=" })
                        $Variables.PoolsUpdated = $Pools.Where({ $_.SideIndicator -eq "==" })

                        $Pools.ForEach(
                            { 
                                $_.Best = $false
                                $_.Prioritize = $false

                                # PoolPorts[0] = non-SSL, PoolPorts[1] = SSL
                                $_.PoolPorts = $(If ($Config.SSL -ne "Always" -and $_.Port) { [UInt16]$_.Port } Else { $null }), $(If ($Config.SSL -ne "Never" -and $_.PortSSL) { [UInt16]$_.PortSSL } Else { $null })

                                If ($_.Algorithm -notmatch $Variables.RegexAlgoHasDAG) { 
                                    $_.AlgorithmVariant = $_.Algorithm
                                }
                                ElseIf (-not $Variables.PoolData.($_.Name).ProfitSwitching -and $Variables.DAGdata.Currency.($_.Currency).BlockHeight) { 
                                    $_.BlockHeight      = $Variables.DAGdata.Currency.($_.Currency).BlockHeight
                                    $_.Epoch            = $Variables.DAGdata.Currency.($_.Currency).Epoch
                                    $_.DAGSizeGiB       = $Variables.DAGdata.Currency.($_.Currency).DAGsize / 1GB 
                                    $_.AlgorithmVariant = "$($_.Algorithm)($([Math]::Ceiling($_.DAGSizeGiB))GiB)"
                                }
                                ElseIf ($Variables.DAGdata.Algorithm.($_.Algorithm).BlockHeight) { 
                                    $_.BlockHeight = $Variables.DAGdata.Algorithm.($_.Algorithm).BlockHeight
                                    $_.Epoch       = $Variables.DAGdata.Algorithm.($_.Algorithm).Epoch
                                    $_.DAGSizeGiB  = $Variables.DAGdata.Algorithm.($_.Algorithm).DAGsize / 1GB
                                    $_.AlgorithmVariant = "$($_.Algorithm)($([Math]::Ceiling($_.DAGSizeGiB))GiB)"
                                }
                                Else { 
                                    $_.AlgorithmVariant = $_.Algorithm
                                }
                            }
                        )

                        # Lower accuracy on older pool data
                        $MaxPoolAgeMinutes = $Config.SyncWindow * $Config.SyncWindow * $Config.SyncWindow * $Config.SyncWindow * ($Variables.CycleStarts[-1] - $Variables.CycleStarts[0]).TotalMinutes
                        $Pools.Where({ $_.Updated -lt $Variables.CycleStarts[0] }).ForEach(
                            { 
                                If ([Math]::Floor(($Variables.CycleStarts[-1] - $_.Updated).TotalMinutes) -gt $MaxPoolAgeMinutes) { $_.Reasons.Add("Data too old") }
                                Else { $_.Price_Bias *= [Math]::Pow(0.9, ($Variables.CycleStarts[0] - $_.Updated).TotalMinutes) }
                            }
                        )
                        Remove-Variable MaxPoolAgeMinutes

                        # No username or wallet
                        $Pools.Where({ -not $_.User }).ForEach({ $_.Reasons.Add("No username or wallet") })
                        # Pool disabled by stat file
                        $Pools.Where({ $_.Disabled }).ForEach({ $_.Reasons.Add("Disabled (by Stat file)") })
                        # Min accuracy not reached
                        $Pools.Where({ $_.Accuracy -lt $Config.MinAccuracy }).ForEach({ $_.Reasons.Add("MinAccuracy ($($Config.MinAccuracy * 100)%) not reached") })
                        # Filter unavailable algorithms
                        If ($Config.MinerSet -lt 3) { $Pools.Where({ $Variables.UnprofitableAlgorithms[$_.Algorithm] -eq "*" }).ForEach({ $_.Reasons.Add("Unprofitable Algorithm") }) }
                        # Pool price 0
                        $Pools.Where({ $_.Price -eq 0 }).ForEach({ $_.Reasons.Add("Price -eq 0") })
                        $Pools.Where({ $_.Price_Bias -eq 0 }).ForEach({ $_.Reasons.Add("Price bias -eq 0") })
                        # No price data
                        $Pools.Where({ $_.Price -eq [Double]::NaN }).ForEach({ $_.Reasons.Add("No price data") })
                        # Ignore pool if price is more than $Config.UnrealPoolPriceFactor higher than average of all pools with same algorithm & currency; NiceHash & MiningPoolHub are always right
                        If ($Config.UnrealPoolPriceFactor -gt 1 -and ($Pools.Name | Sort-Object -Unique).Count -gt 1) { 
                            ($Pools.Where({ $_.Price_Bias -gt 0 }) | Group-Object -Property Algorithm, Currency).Where({ $_.Count -ge 2 }).ForEach(
                                { 
                                    If ($PriceThreshold = ($_.Group.Price_Bias | Measure-Object -Average).Average * $Config.UnrealPoolPriceFactor) { 
                                        $_.Group.Where({ $_.Name -notin @("NiceHash", "MiningPoolHub") -and $_.Price_Bias -gt $PriceThreshold }).ForEach({ $_.Reasons.Add("Unreal price ($($Config.UnrealPoolPriceFactor)x higher than average price)") })
                                    }
                                }
                            )
                            Remove-Variable PriceThreshold
                        }
                        If ($Config.Algorithm -like "+*") { 
                            # Filter non-enabled algorithms
                            $Pools.Where({ $Config.Algorithm -notcontains "+$($_.Algorithm)" }).ForEach({ $_.Reasons.Add("Algorithm not enabled in generic config") })
                            $Pools.Where({ $Variables.PoolsConfig[$_.Name].Algorithm -like "+*" -and $Variables.PoolsConfig.$($_.Name).Algorithm -notcontains "+$($_.Algorithm)" }).ForEach({ $_.Reasons.Add("Algorithm not enabled in $($_.Name) pool config") })
                        }
                        Else { 
                            # Filter disabled algorithms
                            $Pools.Where({ $Config.Algorithm -contains "-$($_.Algorithm)" }).ForEach({ $_.Reasons.Add("Algorithm disabled (``-$($_.Algorithm)`` in generic config)") })
                            $Pools.Where({ $Variables.PoolsConfig[$_.Name].Algorithm -contains "-$($_.Algorithm)" }).ForEach({ $_.Reasons.Add("Algorithm disabled (``-$($_.Algorithm)`` in $($_.Name) pool config)") })
                            $Pools.Where({ $Config.Algorithm -contains "-$($_.AlgorithmVariant)" }).ForEach({ $_.Reasons.Add("Algorithm disabled (``-$($_.AlgorithmVariant)`` in generic config)") })
                            $Pools.Where({ $Variables.PoolsConfig[$_.Name].Algorithm -contains "-$($_.AlgorithmVariant)" }).ForEach({ $_.Reasons.Add("Algorithm disabled (``-$($_.AlgorithmVariant)`` in $($_.Name) pool config)") })
                        }
                        If ($Config.Currency -like "+*") { 
                            # Filter non-enabled currencies
                            $Pools.Where({ $Config.Currency -notcontains "+$($_.Currency)" }).ForEach({ $_.Reasons.Add("Currency not enabled in generic config") })
                            $Pools.Where({ $Variables.PoolsConfig[$_.Name].Currency -like "+*" -and $Variables.PoolsConfig.$($_.Name).Currency -notcontains "+$($_.Currency)" }).ForEach({ $_.Reasons.Add("Currency not enabled in $($_.Name) pool config") })
                        }
                        Else {
                            # Filter disabled currencies
                            $Pools.Where({ $Config.Currency -contains "-$($_.Currency)" }).ForEach({ $_.Reasons.Add("Currency disabled (``-$($_.Currency)`` in generic config)") })
                            $Pools.Where({ $Variables.PoolsConfig[$_.Name].Currency -contains "-$($_.Currency)" }).ForEach({ $_.Reasons.Add("Currency disabled (``-$($_.Currency)`` in $($_.Name) pool config)") })
                        }
                        # MinWorkers
                        $Pools.Where({ $null -ne $_.Workers -and $_.Workers -lt $Variables.PoolsConfig[$_.Name].MinWorker }).ForEach({ $_.Reasons.Add("Not enough workers at pool (MinWorker ``$($Variables.PoolsConfig[$_.Name].MinWorker)`` in $($_.BaseName) pool config)") })
                        $Pools.Where({ $null -ne $_.Workers -and $_.Workers -lt $Config.MinWorker }).ForEach({ $_.Reasons.Add("Not enough workers at pool (MinWorker ``$($Config.MinWorker)`` in generic config)") })
                        # SSL
                        If ($Config.SSL -eq "Never") { $Pools.Where({ -not $_.PoolPorts[0] }).ForEach({ $_.Reasons.Add("Non-SSL port not available (Config.SSL -eq 'Never')") }) }
                        If ($Config.SSL -eq "Always") { $Pools.Where({ -not $_.PoolPorts[1] }).ForEach({ $_.Reasons.Add("SSL port not available (Config.SSL -eq 'Always')") }) }
                        # SSL Allow selfsigned certificate
                        If (-not $Config.SSLAllowSelfSignedCertificate) { $Pools.Where({ $_.SSLSelfSignedCertificate }).ForEach({ $_.Reasons.Add("Pool uses self signed certificate (Config.SSLAllowSelfSignedCertificate -eq '`$false')") }) }
                        # At least one port (SSL or non-SSL) must be available
                        $Pools.Where({ -not ($_.PoolPorts | Select-Object)}).ForEach({ $_.Reasons.Add("No ports available") }) 

                        # Apply watchdog to pools
                        If ($Config.Watchdog) { 
                            # We assume that miner is up and running, so watchdog timer is not relevant
                            If ($RelevantWatchdogTimers = $Variables.WatchdogTimers.Where({ $_.MinerName -notin $Variables.RunningMiners })) { 
                                # Only pools with a corresponding watchdog timer object are of interest
                                If ($RelevantPools = $Pools.Where({ -not $_.Name -in @($RelevantWatchdogTimers.PoolName) })) { 

                                    # Add miner reason "Pool suspended by watchdog 'all algorithms'"
                                    ($RelevantWatchdogTimers | Group-Object -Property PoolName).ForEach(
                                        {
                                            If ($_.Count -ge 3 * $Variables.WatchdogCount * ($_.Group.DeviceNames | Sort-Object -Unique).Count) { 
                                                $Group = $_.Group
                                                If ($PoolsToSuspend = $RelevantPools.Where({ $_.Name -eq $Group[0].PoolName })) { 
                                                    $PoolsToSuspend.ForEach({ $_.Reasons.Add("Pool suspended by watchdog [all algorithms]") })
                                                    Write-Message -Level Warn "Pool '$($Group[0].PoolName) [all algorithms]' is suspended by watchdog until $(($Group.Kicked | Sort-Object -Top 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                                                }
                                            }
                                        }
                                    )
                                    Remove-Variable Group, PoolsToSuspend -ErrorAction Ignore

                                    If ($RelevantPools = $RelevantPools.Where({ -not ($_.Reasons -match "Pool suspended .+") })) { 
                                        # Add miner reason "Pool suspended by watchdog 'Algorithm [Algorithm]'"
                                        ($RelevantWatchdogTimers | Group-Object -Property PoolName, Algorithm).ForEach(
                                            {
                                                If ($_.Count -ge 2 * $Variables.WatchdogCount * ($_.Group.DeviceNames | Sort-Object -Unique).Count) { 
                                                    $Group = $_.Group
                                                    If ($PoolsToSuspend = $RelevantPools.Where({ $_.Name -eq $Group[0].PoolName -and $_.Algorithm -eq $Group[0].Algorithm })) { 
                                                        $PoolsToSuspend.ForEach({ $_.Reasons.Add("Pool suspended by watchdog [Algorithm $($Group[0].Algorithm)]") })
                                                        Write-Message -Level Warn "Pool '$($Group[0].PoolName) [Algorithm $($Group[0].Algorithm)]' is suspended by watchdog until $(($Group.Kicked | Sort-Object -Top 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                                                    }
                                                }
                                            }
                                        )
                                        Remove-Variable Group, PoolsToSuspend -ErrorAction Ignore
                                    }
                                }
                                Remove-Variable RelevantPools
                            }
                            Remove-Variable RelevantWatchdogTimers
                        }

                        # Make pools unavailable
                        $Pools.ForEach({ $_.Available = -not [Boolean]$_.Reasons })

                        # Filter pools on miner set
                        If ($Config.MinerSet -lt 2) { 
                            $Pools.Where({ $Variables.UnprofitableAlgorithms[$_.Algorithm] -eq 1 }).ForEach({ $_.Reasons.Add("Unprofitable primary algorithm") })
                            $Pools.Where({ $Variables.UnprofitableAlgorithms[$_.Algorithm] -eq 2 }).ForEach({ $_.Reasons.Add("Unprofitable secondary algorithm") })
                        }

                        If ($Variables.Pools.Count -gt 0) { 
                            Write-Message -Level Info "Had $($Variables.PoolsCount) pool$(If ($Variables.PoolsCount -ne 1) { "s" })$(If ($Variables.PoolsExpired.Count) { ", expired $($Variables.PoolsExpired.Count) pool$(If ($Variables.PoolsExpired.Count -gt 1) { "s" })" })$(If ($PoolsDeconfiguredCount) { ", removed $PoolsDeconfiguredCount deconfigured pool$(If ($PoolsDeconfiguredCount -gt 1) { "s" })" })$(If ($Variables.PoolsAdded.Count) { ", found $($Variables.PoolsAdded.Count) new pool$(If ($Variables.PoolsAdded.Count -ne 1) { "s" })" }), updated $($Variables.PoolsUpdated.Count) pool$(If ($Variables.PoolsUpdated.Count -ne 1) { "s" })$(If ($Pools.Where({ -not $_.Available })) { ", filtered out $(@($Pools.Where({ -not $_.Available })).Count) pool$(If (@($Pools.Where({ -not $_.Available })).Count -ne 1) { "s" })" }). $(@($Pools.Where({ $_.Available })).Count) available pool$(If (@($Pools.Where({ $_.Available })).Count -ne 1) { "s" }) remain$(If (@($Pools.Where({ $_.Available })).Count -eq 1) { "s" })."
                        }
                        Else { 
                            Write-Message -Level Info "Found $($Variables.PoolsNew.Count) pool$(If ($Variables.PoolsNew.Count -ne 1) { "s" })$(If ($Variables.PoolsExpired.Count) { ", expired $($Variables.PoolsExpired.Count) pool$(If ($Variables.PoolsExpired.Count -gt 1) { "s" })" }), filtered out $(@($Pools.Where({ -not $_.Available })).Count) pool$(If (@($Pools.Where({ -not $_.Available })).Count -ne 1) { "s" }). $(@($Pools.Where({ $_.Available })).Count) available pool$(If (@($Pools.Where({ $_.Available })).Count -ne 1) { "s" }) remain$(If (@($Pools.Where({ $_.Available})).Count -eq 1) { "s" })."
                        }

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
                                        If ($_.Name -in $Variables.PoolNamesToKeepBalancesAlive) { $_.Available = $true; $_.Prioritize = $true }
                                        Else { $_.Reasons.Add("BalancesKeepAlive prioritizes other pools") }
                                    }
                                )
                            }
                        }
                        $Pools.Where({ $_.Reasons }).ForEach({ $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons | Sort-Object -Unique) })

                        # Mark best pools, allow all DAG pools (optimal pool might not fit in GPU memory)
                        ($Pools.Where({ $_.Available }) | Group-Object Algorithm).ForEach({ ($_.Group | Sort-Object -Property Prioritize, Price_Bias -Bottom $(If ($Config.MinerUseBestPoolsOnly -or $_.Group.Algorithm -notmatch $Variables.RegexAlgoHasDAG) { 1 } Else { $_.Group.Count })).ForEach({ $_.Best = $true }) })

                        $Pools.ForEach({ $_.PSObject.Properties.Remove("SideIndicator") })
                    }

                    # Update data in API
                    $Variables.Pools = $Pools

                    Remove-Variable Pools, PoolsDeconfiguredCount, PoolsExpiredCount -ErrorAction Ignore

                    # Core suspended with <Ctrl><Alt>P in MainLoop
                    While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }
                }
                Else { 
                    # No configuired pools, clear all pools
                    $Variables.Pools = [Pool[]]@()
                }

                $Variables.PoolsBest = $Variables.Pools.Where({ $_.Best }) | Sort-Object -Property Algorithm
            }
            Else { 
                Write-Message -Level Info "Using $($Variables.Pools.Count) pool$(If ($Variables.Pools.Count -ne 1) { "s" }) from previous cycle$(If ($Variables.Pools.Where({ -not $_.Available })) { ", filtered out $(@($Variables.Pools.Where({ -not $_.Available })).Count) pool$(If (@($Variables.Pools.Where({ -not $_.Available })).Count -ne 1) { "s" })" }). $(@($Variables.Pools.Where({ $_.Available })).Count) available pool$(If (@($Variables.Pools.Where({ $_.Available })).Count -ne 1) { "s" }) remain$(If (@($Variables.Pools.Where({ $_.Available })).Count -eq 1) { "s" })."
                ($Variables.Pools.Reasons.Where({ $_ -match "Pool suspended by watchdog .+" }) | Sort-Object -Unique).ForEach({ Write-Message -Level Warn  $_ })
                $Variables.EndCycleTime = [DateTime]::Now.ToUniversalTime().AddSeconds([Math]::Floor($Config.Interval / 2))
            }

            # Ensure we get the hashrate for running miners prior looking for best miner
            ForEach ($Miner in $Variables.MinersBest | Sort-Object { [String]$_.DeviceNames }) { 
                If ($Miner.DataReaderJob.HasMoreData -and $Miner.Status -ne [MinerStatus]::DryRun) { 
                    If ($Samples = @($Miner.DataReaderJob | Receive-Job | Select-Object)) { 
                        $Sample = $Samples[-1]
                        If ([Math]::Floor(($Sample.Date - $Miner.ValidDataSampleTimestamp).TotalSeconds) -ge 0) { $Miner.Data += $Samples }
                        $Miner.Hashrates_Live = $Sample.Hashrate.PSObject.Properties.Value
                        # Hashrate from primary algorithm is relevant
                        If ($Sample.Hashrate.($Miner.Algorithms[0])) { 
                            $Miner.DataSampleTimestamp = $Sample.Date
                        }
                    }
                    Remove-Variable Sample, Samples -ErrorAction Ignore
                }
                $Miner.Data = @($Miner.Data | Select-Object -Last ($Miner.MinDataSample * 5)) # Reduce data to MinDataSample * 5

                If ($Miner.Status -in @([MinerStatus]::Running, [MinerStatus]::DryRun)) { 
                    If ($Miner.Status -eq [MinerStatus]::DryRun -or $Miner.GetStatus() -eq [MinerStatus]::Running) { 
                        $Miner.ContinousCycle ++
                        If ($Config.Watchdog) { 
                            ForEach ($Worker in $Miner.WorkersRunning) { 
                                If ($WatchdogTimer = $Variables.WatchdogTimers.Where({ $_.MinerName -eq $Miner.Name -and $_.PoolName -eq $Worker.Pool.Name -and $_.PoolRegion -eq $Worker.Pool.Region -and $_.Algorithm -eq $Worker.Pool.Algorithm }) | Sort-Object -Property Kicked -Bottom 1) { 
                                    # Update watchdog timers
                                    $WatchdogTimer.Kicked = [DateTime]::Now.ToUniversalTime()
                                }
                                Else {
                                    # Create watchdog timer
                                    $Variables.WatchdogTimers += [PSCustomObject]@{ 
                                        Algorithm        = $Worker.Pool.Algorithm
                                        AlgorithmVariant = $Worker.Pool.AlgorithmVariant
                                        DeviceNames      = $Miner.DeviceNames
                                        Kicked           = [DateTime]::Now.ToUniversalTime()
                                        MinerBaseName    = $Miner.BaseName
                                        MinerName        = $Miner.Name
                                        MinerVersion     = $Miner.Version
                                        PoolName         = $Worker.Pool.Name
                                        PoolRegion       = $Worker.Pool.Region
                                        PoolVariant      = $Worker.Pool.Variant
                                    }
                                }
                            }
                            Remove-Variable WatchdogTimer, Worker -ErrorAction Ignore
                        }
                        If ($Config.BadShareRatioThreshold -gt 0) { 
                            If ($MinerData = ($Miner.Data | Select-Object -Last 1).Shares) { 
                                ForEach ($Algorithm in $Miner.Algorithms) { 
                                    If ($MinerData.$Algorithm -and $MinerData.$Algorithm[1] -gt 0 -and $MinerData.$Algorithm[3] -gt [Math]::Floor(1 / $Config.BadShareRatioThreshold) -and $MinerData.$Algorithm[1] / $MinerData.$Algorithm[3] -gt $Config.BadShareRatioThreshold) { 
                                        $Miner.StatusInfo = "'$($Miner.Info)' stopped. Too many bad shares (Shares Total = $($MinerData.$Algorithm[3]), Rejected = $($MinerData.$Algorithm[1]))"
                                        $Miner.SetStatus([MinerStatus]::Failed)
                                        $Variables.Devices.Where({ $_.Name -in $Miner.DeviceNames }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                                    }
                                }
                            }
                            Remove-Variable Algorithm, MinerData -ErrorAction Ignore
                        }
                    }
                    Else { 
                        $Miner.StatusInfo = "'$($Miner.Info)' exited unexpectedly"
                        $Miner.SetStatus([MinerStatus]::Failed)
                        $Variables.Devices.Where({ $_.Name -in $Miner.DeviceNames }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
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
                            $Miner.Hashrates_Live += $CollectedHashrate[1]
                            $MinerHashrates.$Algorithm = $CollectedHashrate[0]
                        }
                        If ($Miner.ReadPowerConsumption) { 
                            # Collect power consumption from miner, returns an array of two values (safe, unsafe)
                            $CollectedPowerConsumption = $Miner.CollectPowerConsumption(-not $Miner.MeasurePowerConsumption -and $Miner.Data.Count -lt $Miner.MinDataSample)
                            $Miner.PowerConsumption_Live = $CollectedPowerConsumption[1]
                            $MinerPowerConsumption = $CollectedPowerConsumption[0]
                        }
                    }

                    # We don't want to store hashrates if we have less than $MinDataSample
                    If ($Miner.Data.Count -ge $Miner.MinDataSample -or $Miner.Activated -gt $Variables.WatchdogCount) { 
                        $Miner.StatEnd = [DateTime]::Now.ToUniversalTime()
                        $Stat_Span = [TimeSpan]($Miner.StatEnd - $Miner.StatStart)

                        ForEach ($Worker in $Miner.Workers) { 
                            $Algorithm = $Worker.Pool.Algorithm
                            $MinerData = ($Miner.Data[-1]).Shares
                            If ($Miner.Data.Count -gt $Miner.MinDataSample -and -not $Miner.Benchmark -and $Config.SubtractBadShares -and $MinerData.$Algorithm -gt 0) { # Need $Miner.MinDataSample shares before adjusting hashrate
                                $Factor = (1 - $MinerData.$Algorithm[1] / $MinerData.$Algorithm[3])
                                $MinerHashrates.$Algorithm *= $Factor
                            } 
                            Else { 
                                $Factor = 1
                            }
                            $StatName = "$($Miner.Name)_$($Worker.Pool.Algorithm)_Hashrate"
                            $Stat = Set-Stat -Name $StatName -Value $MinerHashrates.$Algorithm -Duration $Stat_Span -FaultDetection ($Miner.Data.Count -lt $Miner.MinDataSample -or $Miner.Activated -lt $Variables.WatchdogCount) -ToleranceExceeded ($Variables.WatchdogCount + 1)
                            If ($Stat.Updated -gt $Miner.StatStart) { 
                                Write-Message -Level Info "Saved hashrate for '$($StatName -replace '_Hashrate$')': $(($MinerHashrates.$Algorithm | ConvertTo-Hash) -replace ' ')$(If ($Factor -le 0.999) { " (adjusted by factor $($Factor.ToString('N3')) [Shares total: $($MinerData.$Algorithm[2]), rejected: $($MinerData.$Algorithm[1])])" })$(If ($Miner.Benchmark) { " [Benchmark done] ($($Miner.Data.Count) Sample$(If ($Miner.Data.Count -ne 1) { "s" }))" })."
                                $Miner.StatStart = $Miner.StatEnd
                                $Variables.AlgorithmsLastUsed.($Worker.Pool.Algorithm) = @{ Updated = $Stat.Updated; Benchmark = $Miner.Benchmark; MinerName = $Miner.Name }
                                $Variables.PoolsLastUsed.($Worker.Pool.Name) = $Stat.Updated # most likely this will count at the pool to keep balances alive
                            }
                            ElseIf ($MinerHashrates.$Algorithm -gt 0 -and $Miner.Status -eq [MinerStatus]::Running -and $Stat.Week -and ($MinerHashrates.$Algorithm -gt $Stat.Week * 2 -or $MinerHashrates.$Algorithm -lt $Stat.Week / 2)) { # Stop miner if new value is outside ±200% of current value
                                $Miner.StatusInfo = "'$($Miner.Info)' reported hashrate is unreal ($($Algorithm): $(($MinerHashrates.$Algorithm | ConvertTo-Hash) -replace ' ') is not within ±200% of stored value of $(($Stat.Week | ConvertTo-Hash) -replace ' '))"
                                $Miner.SetStatus([MinerStatus]::Failed)
                                $Variables.Devices.Where({ $_.Name -in $Miner.DeviceNames }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                            }
                        }
                        Remove-Variable Factor -ErrorAction Ignore
                    }
                    If ($Miner.ReadPowerConsumption) { 
                        # We don't want to store power consumption if we have less than $MinDataSample, store even when fluctuating hash rates were recorded
                        If ($Miner.Data.Count -ge $Miner.MinDataSample -or $Miner.Activated -gt $Variables.WatchdogCount) { 
                            If ([Double]::IsNaN($MinerPowerConsumption )) { $MinerPowerConsumption = 0 }
                            $StatName = "$($Miner.Name)_PowerConsumption"
                            # Always update power consumption when benchmarking
                            $Stat = Set-Stat -Name $StatName -Value $MinerPowerConsumption -Duration $Stat_Span -FaultDetection (-not $Miner.Benchmark -and ($Miner.Data.Count -lt $Miner.MinDataSample -or $Miner.Activated -lt $Variables.WatchdogCount)) -ToleranceExceeded ($Variables.WatchdogCount + 1)
                            If ($Stat.Updated -gt $Miner.StatStart) { 
                                Write-Message -Level Info "Saved power consumption for '$($StatName -replace '_PowerConsumption$')': $($Stat.Live.ToString("N2"))W$(If ($Miner.MeasurePowerConsumption) { " [Power consumption measurement done] ($($Miner.Data.Count) Sample$(If ($Miner.Data.Count -ne 1) { "s" }))" })."
                            }
                            ElseIf ($MinerPowerConsumption -gt 0 -and $Miner.Status -eq [MinerStatus]::Running -and $Stat.Week -and ($MinerPowerConsumption -gt $Stat.Week * 2 -or $MinerPowerConsumption -lt $Stat.Week / 2)) { 
                                # Stop miner if new value is outside ±200% of current value
                                $Miner.StatusInfo = "'$($Miner.Info)' reported power consumption is unreal ($($PowerConsumption.ToString("N2"))W is not within ±200% of stored value of $(([Double]$Stat.Week).ToString("N2"))W)"
                                $Miner.SetStatus([MinerStatus]::Failed)
                                $Variables.Devices.Where({ $_.Name -in $Miner.DeviceNames }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                            }
                        }
                    }
                    Remove-Variable Algorithm, CollectedHashrateFactor, CollectedPowerConsumption, MinerData, MinerHashrates, MinerPowerConsumption, Stat, StatName, StatSpan, Worker -ErrorAction Ignore
                }
            }
            Remove-Variable Miner -ErrorAction Ignore

            # Update pools last used, required for BalancesKeepAlive
            If ($Variables.AlgorithmsLastUsed.Values.Updated -gt $Variables.BeginCycleTime) { $Variables.AlgorithmsLastUsed | Get-SortedObject | ConvertTo-Json | Out-File -LiteralPath ".\Data\AlgorithmsLastUsed.json" -Force }
            If ($Variables.PoolsLastUsed.values -gt $Variables.BeginCycleTime) { $Variables.PoolsLastUsed | Get-SortedObject | ConvertTo-Json | Out-File -LiteralPath ".\Data\PoolsLastUsed.json" -Force }

            # Send data to monitoring server
            # If ($Config.ReportToServer) { Write-MonitoringData }

            # Core suspended with <Ctrl><Alt>P in MainLoop
            While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

            # Get new miners
            If ($AvailableMinerPools = If ($Config.MinerUseBestPoolsOnly) { $Variables.Pools.Where({ $_.Available -and ($_.Best -or $_.Prioritize) }) } Else { $Variables.Pools.Where({ $_.Available }) }) { 
                $MinerPools = [Ordered]@{ }, [Ordered]@{ "" = "" } # Dummy secondary pool
                ($AvailableMinerPools.Where({ $_.Reasons -notcontains "Unprofitable primary algorithm" }) | Group-Object Algorithm).ForEach({ $MinerPools[0][$_.Name] = $_.Group })
                ($AvailableMinerPools.Where({ $_.Reasons -notcontains "Unprofitable secondary algorithm" }) | Group-Object Algorithm).ForEach({ $MinerPools[1][$_.Name] = $_.Group })

                $Message = "Loading miners.$(If (-not $Variables.Miners) { "<br>This may take a while." }).."
                If (-not $Variables.Miners) { 
                    $Variables.Summary = $Message
                    $Variables.RefreshNeeded = $true    
                }
                Write-Message -Level Info ($Message -replace '<br>', ' ')
                Remove-Variable Message

                $MinersNew = (Get-ChildItem -Path ".\Miners\*.ps1").ForEach(
                    { 
                        $MinerFileName = $_.Name
                        Try { 
                            & $_.FullName
                        }
                        Catch { 
                            Write-Message -Level Error "Error in miner file 'Miners\$MinerFileName': $_."
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
                            $Miner | Add-Member Info "$(($Miner.Name -split '-')[0..2] -join '-') {$($Miner.Workers.ForEach({ "$($_.Pool.AlgorithmVariant)$(If ($_.Pool.Currency) { "[$($_.Pool.Currency)]" })", $_.Pool.Name -join '@' }) -join ' & ')}$(If (($Miner.Name -split '-')[4]) { " (Dual Intensity $(($Miner.Name -split '-')[4]))" })"
                            If ($Config.BenchmarkAllPoolAlgorithmCombinations) { $Miner.Name = $Miner.Info -replace "\{", "(" -replace "\}", ")" -replace " " }
                            $Miner -as $_.API
                        }
                        Catch { 
                            Write-Message -Level Error "Failed to add miner '$($Miner.Name)' as '$($Miner.API)' ($($Miner | ConvertTo-Json -Compress))"
                            "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $ErrorLogFile
                            $_.Exception | Format-List -Force >> $ErrorLogFile
                            $_.InvocationInfo | Format-List -Force >> $ErrorLogFile
                        }
                    }
                )
                Remove-Variable Algorithm, Miner, MinerFileName, MinerPools -ErrorAction Ignore
            }
            Remove-Variable AvailableMinerPools -ErrorAction Ignore

            # Sometimes there are no new miners (classes broken after GC?)
            If ($MinersNew) { 
                $Miners = Compare-Object @($Variables.Miners | Select-Object) @($MinersNew | Select-Object) -Property Info -IncludeEqual -PassThru
                $MinerDevices = $Variables.EnabledDevices | Select-Object -Property Bus, ConfiguredPowerConsumption, Name, ReadPowerConsumption, Status

                # Make smaller groups for faster update
                $MinersNewGroups = $MinersNew | Group-Object -Property Name
                ($Miners.Where({ $_.SideIndicator -ne "<=" }) | Group-Object -Property Name).ForEach(
                    { 
                        $Name = $_.Name
                        $MinersNewGroup = $MinersNewGroups.Where({ $Name -eq $_.Name }).Group
                        $_.Group.ForEach(
                            { 
                                Try { 
                                    $Miner = $_
                                    If ($_.KeepRunning = $_.Status -in @([MinerStatus]::Running, [MinerStatus]::DryRun) -and ($Variables.DonationRunning -or $_.ContinousCycle -lt $Config.MinCycle)) { 
                                        # Minimum numbers of full cycles not yet reached
                                        $_.Restart = $false
                                    }
                                    Else { 
                                        If ($_.SideIndicator -eq "=>") { 
                                            $_.CommandLine = $_.GetCommandLine().Replace("$PWD\", "")
                                            # These properties need to be set only once because they are not dependent on any config or pool information
                                            $_.BaseName, $_.Version = ($_.Name -split '-')[0, 1]
                                            $_.Algorithms = $_.Workers.Pool.Algorithm
                                        }
                                        Else { 
                                            $Info = $_.Info
                                            $Miner = $MinersNewGroup.Where({ $Info -eq $_.Info })
                                            # Update existing miners
                                            If ($_.Restart = $_.Arguments -ne $Miner.Arguments) { 
                                                $_.Arguments = $Miner.Arguments
                                                $_.CommandLine = $Miner.GetCommandLine().Replace("$PWD\", "")
                                                $_.Port = $Miner.Port
                                            }
                                            $_.PrerequisitePath = $Miner.PrerequisitePath
                                            $_.PrerequisiteURI = $Miner.PrerequisiteURI
                                            $_.WarmupTimes = $Miner.WarmupTimes
                                            $_.Workers = $Miner.Workers
                                        }
                                    }
                                    $DeviceNames = $_.DeviceNames
                                    $_.Devices = $MinerDevices.Where({ $_.Name -in $DeviceNames })
                                    If ($_.ReadPowerConsumption -ne [Boolean]($_.Devices.ReadPowerConsumption -notcontains $false)) { 
                                        $_.Restart = $true
                                    }
                                    $_.Refresh($Variables.PowerCostBTCperW, $Config)
                                }
                                Catch { 
                                    Write-Message -Level Error "Failed to update miner '$($Miner.Name)': Error $_"
                                    "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $ErrorLogFile
                                    $_.Exception | Format-List -Force >> $ErrorLogFile
                                    $_.InvocationInfo | Format-List -Force >> $ErrorLogFile
                                }
                            }
                        )
                    }
                )
                Remove-Variable DeviceNames, Info, Miner, MinerDevices, MinersNewGroup, MinersNewGroups, MinersNew, Name -ErrorAction Ignore
            }
            Else { 
                $Miners = $Variables.Miners
            }

            # Core suspended with <Ctrl><Alt>P in MainLoop
            While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

            # Filter miners
            $Miners.Where({ $_.Disabled }).ForEach({ $_.Reasons.Add("Disabled by user") })
            If ($Config.ExcludeMinerName.Count) { $Miners.Where({ (Compare-Object @($Config.ExcludeMinerName | Select-Object) @($_.BaseName, "$($_.BaseName)-$($_.Version)", $_.Name | Select-Object -Unique) -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 }).ForEach({ $_.Reasons.Add("ExcludeMinerName ($($Config.ExcludeMinerName -join ', '))") }) }
            $Miners.Where({ $_.Earning -eq 0 }).ForEach({ $_.Reasons.Add("Earning -eq 0") })
            $Miners.Where({ -not $_.Benchmark -and $_.Workers.Hashrate -contains 0 }).ForEach({ $_.Reasons.Add("0 H/s Stat file") })
            If ($Config.DisableMinersWithFee) { $Miners.Where({ $_.Workers.Fee }).ForEach({ $_.Reasons.Add("Config.DisableMinersWithFee") }) }
            If ($Config.DisableDualAlgoMining) { $Miners.Where({ $_.Workers.Count -eq 2 }).ForEach({ $_.Reasons.Add("Config.DisableDualAlgoMining") }) }
            ElseIf ($Config.DisableSingleAlgoMining) { $Miners.Where({ $_.Workers.Count -eq 1 }).ForEach({ $_.Reasons.Add("Config.DisableSingleAlgoMining") }) }

            # Add reason 'Config.DisableCpuMiningOnBattery' for CPU miners when running on battery
            If ($Config.DisableCpuMiningOnBattery -and (Get-CimInstance Win32_Battery).BatteryStatus -eq 1) { $Miners.Where({ $_.Type -eq "CPU" }).ForEach({ $_.Reasons.Add("Config.DisableCpuMiningOnBattery") }) }

            # Add reason 'Unreal profit data...' for miners with unreal earning (> x times higher than average of the next best 10% or at least 5 miners)
            If ($Config.UnrealMinerEarningFactor -gt 1) { 
                ($Miners.Where({ -not $_.Reasons }) | Group-Object { [String]$_.DeviceNames }).ForEach(
                    { 
                        If ($ReasonableEarning = [Double]($_.Group | Sort-Object -Descending -Property Earning_Bias | Select-Object -Skip 1 -First (5, [Math]::Floor($_.Group.Count / 10) | Measure-Object -Maximum).Maximum | Measure-Object Earning -Average).Average * $Config.UnrealMinerEarningFactor) { 
                            ($_.Group.Where({ $_.Earning -gt $ReasonableEarning })).ForEach(
                                { $_.Reasons.Add("Unreal profit data (-gt $($Config.UnrealMinerEarningFactor)x higher than the next best miners available miners)") }
                            )
                        }
                    }
                )
                Remove-Variable ReasonableEarning -ErrorAction Ignore
            }

            If ($Config.BenchmarkAllPoolAlgorithmCombinations) { 
                # Add reason 'Not best miner in algorithm family'
                ($Miners.Where({ -not $_.Reasons }) | Group-Object { [String]$_.DeviceNames }, { [String]$_.Workers.Pool.Name }, { [String]$_.Workers.Pool.Algorithm }).ForEach(
                    {
                        ($_.Group | Select-Object -Skip 1).ForEach(
                            { 
                                $_.Reasons.Add("Not best miner in algorithm family")
                            }
                        )
                    }
                )
            }

            $Variables.MinersMissingBinary = [Miner[]]@()
            ($Miners.Where({ -not $_.Reasons }) | Group-Object Path).Where({ -not (Test-Path -LiteralPath $_.Name -Type Leaf) }).Group.ForEach(
                { 
                    $_.Reasons.Add("Binary missing")
                    $Variables.MinersMissingBinary += $_
                }
            )

            $Variables.MinersMissingPrerequisite = [Miner[]]@()
            $Miners.Where({ -not $_.Reasons -and $_.PrerequisitePath }).ForEach(
                { 
                    $_.Reasons.Add("Prerequisite missing ($(Split-Path -Path $_.PrerequisitePath -Leaf))")
                    $Variables.MinersMissingPrerequisite += $_
                }
            )

            # Apply watchdog to miners
            If ($Config.Watchdog) { 
                # We assume that miner is up and running, so watchdog timer is not relevant
                If ($RelevantWatchdogTimers = $Variables.WatchdogTimers.Where({ $_.MinerName -notin $Variables.RunningMiners.Name })) { 
                    # Only miners with a corresponding watchdog timer object are of interest
                    If ($RelevantMiners = $Variables.Miners.Where({$_.BaseName -in @($Variables.WatchdogTimers.MinerBaseName) -and $_.Version -in @($Variables.WatchdogTimers.MinerVersion) })) { 
                        # Add miner reason 'Miner suspended by watchdog [all algorithms & all devices]'
                        ($RelevantWatchdogTimers | Group-Object { ($_.MinerName -split '-')[0..1] -join '-' }).ForEach(
                            { 
                                If ($_.Count -gt 2 * $Variables.WatchdogCount * (($_.Group[0].MinerName -split '-')[3] -split '&').Count * ($_.Group.DeviceNames | Sort-Object -Unique).Count) { 
                                    $Group = $_.Group
                                    If ($MinersToSuspend = $RelevantMiners.Where({ (($_.Name -split '-')[0..1] -join '-') -eq (($Group[0].MinerName -split '-')[0..1] -join '-') })) { 
                                        $MinersToSuspend.ForEach({ $_.Reasons.Add("Miner suspended by watchdog [all algorithms & all devices]") })
                                        Write-Message -Level Warn "Miner '$(($Group[0].MinerName -split '-')[0..1] -join '-') [all algorithms & all devices]' is suspended by watchdog until $(($Group.Kicked | Sort-Object -Top 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                                    }
                                }
                            }
                        )
                        Remove-Variable Group, MinersToSuspend  -ErrorAction Ignore

                        If ($RelevantMiners = $RelevantMiners.Where({ -not ($_.Reasons -match "Miner suspended by watchdog .+") })) { 
                            # Add miner reason 'Miner suspended by watchdog [all algorithms]'
                            ($RelevantWatchdogTimers | Group-Object { ($_.MinerName -split '-')[0..2] -join '-' }).ForEach(
                                { 
                                    If ($_.Count -ge 2 * $Variables.WatchdogCount * (($_.Group[0].MinerName -split '-')[3] -split '&').Count) { 
                                        $Group = $_.Group
                                        If ($MinersToSuspend = $RelevantMiners.Where({ (($_.Name -split '-')[0..2] -join '-') -eq (($Group[0].MinerName -split '-')[0..2] -join '-') })) { 
                                            $MinersToSuspend.ForEach({ $_.Reasons.Add("Miner suspended by watchdog [all algorithms]") })
                                            Write-Message -Level Warn "Miner '$(($Group[0].MinerName -split '-')[0..2] -join '-') [all algorithms]' is suspended by watchdog until $(($Group.Kicked | Sort-Object -Top 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                                        }
                                    }
                                }
                            )
                            Remove-Variable Group, MinersToSuspend -ErrorAction Ignore

                            If ($RelevantMiners = $RelevantMiners.Where({ -not ($_.Reasons -match "Miner suspended by watchdog .+") })) { 
                                # Add miner reason 'Miner suspended by watchdog [Algorithm [Algorithm]]'
                                ($RelevantWatchdogTimers.Where({ $_.Algorithm -eq $_.AlgorithmVariant}) | Group-Object -Property MinerName).ForEach(
                                    { 
                                        If ($_.Count / (($_.Group[0].MinerName -split '-')[3] -split '&').Count -ge $Variables.WatchdogCount) { 
                                            $Group = $_.Group
                                            If ($MinersToSuspend = $RelevantMiners.Where({ (($_.Name -split '-')[0..2] -join '-') -eq (($Group[0].MinerName -split '-')[0..2] -join '-') -and [String]$_.Algorithms -eq (($Group[0].MinerName -split '-')[3] -split '&' -replace '\(.*') })) { 
                                                $Algorithms = $MinersToSuspend[0].Workers.Pool.Algorithm -join '&'
                                                $MinersToSuspend.ForEach({ $_.Reasons.Add("Miner suspended by watchdog [Algorithm $Algorithms]") })
                                                Write-Message -Level Warn "Miner '$(($Group[0].MinerName -split '-')[0..2] -join '-') [$Algorithms]' is suspended by watchdog until $(($Group.Kicked | Sort-Object -Top 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                                            }
                                        }
                                    }
                                )
                                Remove-Variable Algorithms, Group, MinersToSuspend -ErrorAction Ignore

                                If ($RelevantMiners = $RelevantMiners.Where({ -not ($_.Reasons -match "Miner suspended by watchdog .+") })) { 
                                    # Add miner reason 'Miner suspended by watchdog [Algorithm variant [AlgorithmVariant]]'
                                    ($RelevantWatchdogTimers.Where({ $_.Algorithm -ne $_.AlgorithmVariant}) | Group-Object -Property MinerName).ForEach(
                                        { 
                                            If ($_.Count / (($_.Group[0].MinerName -split '-')[3] -split '&').Count -ge $Variables.WatchdogCount ) { 
                                                $Group = $_.Group
                                                If ($MinersToSuspend = $RelevantMiners.Where({ $_.Name -eq $Group[0].MinerName })) { 
                                                    $Algorithms = $MinersToSuspend[0].Workers.Pool.AlgorithmVariant -join '&'
                                                    $MinersToSuspend.ForEach({ $_.Reasons.Add("Miner suspended by watchdog [Algorithm variant $Algorithms]") })
                                                    Write-Message -Level Warn "Miner '$(($Group[0].MinerName -split '-')[0..2] -join '-') [$Algorithms]' is suspended by watchdog until $(($Group.Kicked | Sort-Object -Top 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                                                }
                                            }
                                        }
                                    )
                                    Remove-Variable Algorithms, Group, MinersToSuspend -ErrorAction Ignore
                                }
                            }
                        }
                    }
                    Remove-Variable RelevantMiners -ErrorAction Ignore
                }
                Remove-Variable RelevantWatchdogTimers -ErrorAction Ignore
            }

            $Miners.ForEach({ $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons | Sort-Object -Unique); $_.Available = -not [Boolean]$_.Reasons })

            # Gone miners are no longer available
            $Miners.Where({ $_.SideIndicator -eq "<=" }).ForEach({ $_.Available = $false}) 

            Write-Message -Level Info "Loaded $($Miners.Where({ $_.SideIndicator -ne "<=" }).Count) miner$(If ($Miners.Where({ $_.SideIndicator -ne "<=" }).Count -ne 1) { 's' }), filtered out $($Miners.Where({ -not $_.Available }).Count) miner$(If ($Miners.Where({ -not $_.Available }).Count -ne 1) { 's' }). $($Miners.Where({ $_.Available }).Count) available miner$(If ($Miners.Where({ $_.Available }).Count -ne 1) { 's' }) remain$(If ($Miners.Where({ $_.Available }).Count -eq 1) { 's' })."

            If ($DownloadList = @($Variables.MinersMissingPrerequisite | Select-Object @{ Name = "URI"; Expression = { $_.PrerequisiteURI } }, @{ Name = "Path"; Expression = { $_.PrerequisitePath } }, @{ Name = "Searchable"; Expression = { $false } }) + @($Variables.MinersMissingBinary | Select-Object URI, Path, @{ Name = "Searchable"; Expression = { $false } }) | Select-Object * -Unique) { 
                If ($Variables.Downloader.State -ne "Running") { 
                    # Download miner binaries
                    Write-Message -Level Info "Some miners binaries are missing ($($DownloadList.Count) item$(If ($DownloadList.Count -ne 1) { "s" })), starting downloader..."
                    $DownloaderParameters = @{ 
                        Config = $Config
                        DownloadList = $DownloadList
                        Variables = $Variables
                    }
                    $Variables.Downloader = Start-ThreadJob -Name Downloader -StreamingHost $null -FilePath ".\Includes\Downloader.ps1" -InitializationScript ([ScriptBlock]::Create("Set-Location '$($Variables.MainPath)'")) -ArgumentList $DownloaderParameters -ThrottleLimit (2 * $Variables.Devices.Count + 2)
                    Remove-Variable DownloaderParameters
                }
                ElseIf (-not $Miners.Where({ $_.Available })) { 
                    Write-Message -Level Info "Waiting 30 seconds for downloader to install binaries..."
                }
            }
            Remove-Variable DownloadList

            # Open firewall ports for all miners
            If ($Config.OpenFirewallPorts) { 
                If (Get-Command "Get-MpPreference") { 
                    If ((Get-Command "Get-MpComputerStatus") -and (Get-MpComputerStatus)) { 
                        If (Get-Command "Get-NetFirewallRule") { 
                            If ($MissingMinerFirewallRules = (Compare-Object @(Get-NetFirewallApplicationFilter | Select-Object -ExpandProperty Program -Unique) @($Miners | Select-Object -ExpandProperty Path -Unique) -PassThru).Where({ $_.SideIndicator -eq "=>" })) { 
                                Start-Process "pwsh" ("-Command Import-Module NetSecurity; ('$($MissingMinerFirewallRules | ConvertTo-Json -Compress)' | ConvertFrom-Json) | ForEach-Object { New-NetFirewallRule -DisplayName (Split-Path `$_ | Split-Path -leaf) -Program `$_ -Description 'Inbound rule added by $($Variables.Branding.ProductLabel) $($Variables.Branding.Version) on $([DateTime]::Now.ToString())' -Group '$($Variables.Branding.ProductLabel)' }" -replace '"', '\"') -Verb runAs
                            }
                            Remove-Variable MissingMinerFirewallRules
                        }
                    }
                }
            }

            If ($Miners.Where({ $_.Available })) { 
                Write-Message -Level Info "Selecting best miner$(If (($Variables.EnabledDevices.Model | Select-Object -Unique).Count -gt 1) { " combinations" }) based on$(If ($Variables.CalculatePowerCost -and -not $Config.IgnorePowerCost) { " profit (power cost $($Config.MainCurrency) $($Variables.PowerPricekWh)/kW⋅h)" } Else { " earnings" })..."

                If ($Miners.Where({ $_.Available }).Count -eq 1) { 
                    $MinersBest = $Variables.MinersBestPerDevice = $Variables.MinersOptimal = $Miners.Where({ $_.Available })
                }
                Else { 
                    $Bias = If ($Variables.CalculatePowerCost -and -not $Config.IgnorePowerCost) { "Profit_Bias" } Else { "Earning_Bias" }
                    # Add running miner bonus
                    $RunningMinerBonusFactor = 1 + $Config.MinerSwitchingThreshold / 100
                    $Miners.Where({ $_.Status -eq [MinerStatus]::Running }).ForEach({ $_.$Bias *= $RunningMinerBonusFactor })

                    # Get the optimal miners per algorithm and device
                    $Variables.MinersOptimal = ($Miners.Where({ $_.Available -and -not ($_.Benchmark -or $_.MeasurePowerConsumption) }) | Group-Object { [String]$_.DeviceNames }, { [String]$_.Algorithms }).ForEach({ ($_.Group | Sort-Object -Descending -Property KeepRunning, Prioritize, $Bias, Activated, @{ Expression = { $_.WarmupTimes[1] + $_.MinDataSample }; Descending = $true }, @{ Expression = { [String]$_.Algorithms }; Descending = $false } -Top 1).ForEach({ $_.Optimal = $true; $_ }) })
                    # Get the best miners per device
                    $Variables.MinersBestPerDevice = ($Miners.Where({ $_.Available }) | Group-Object { [String]$_.DeviceNames }).ForEach({ $_.Group | Sort-Object -Descending -Property Benchmark, MeasurePowerConsumption, KeepRunning, Prioritize, $Bias, Activated, @{ Expression = { $_.WarmupTimes[1] + $_.MinDataSample }; Descending = $true } -Top 1 })
                    $Variables.MinerDeviceNamesCombinations = (Get-Combination @($Variables.MinersBestPerDevice | Select-Object DeviceNames -Unique)).Where({ (Compare-Object ($_.Combination | Select-Object -ExpandProperty DeviceNames -Unique) ($_.Combination | Select-Object -ExpandProperty DeviceNames) | Measure-Object).Count -eq 0 })

                    # Get most best miner combination i.e. AMD+INTEL+NVIDIA+CPU
                    $MinerCombinations = $Variables.MinerDeviceNamesCombinations.ForEach(
                        { 
                            $MinerDeviceNamesCombination = $_.Combination
                            [PSCustomObject]@{ 
                                Combination = $MinerDeviceNamesCombination.ForEach(
                                    { 
                                        $DeviceNames = [String]$_.DeviceNames
                                        $Variables.MinersBestPerDevice.Where({ [String]$_.DeviceNames -eq $DeviceNames })
                                    }
                                )
                            }
                        }
                    )
                    Remove-Variable DeviceNames, MinerDeviceNamesCombination -ErrorAction Ignore

                    # Get smallest $Bias
                    # Hack: Temporarily make all bias -ge 0 by adding smallest bias, MinerBest produces wrong sort order when some profits are negative
                    $SmallestBias = $Variables.MinersBestPerDevice.$Bias | Sort-Object -Top 1
                    $MinerCombinations.ForEach({ $_.Combination.ForEach({ $_.$Bias += $SmallestBias }) })
                    $MinersBest = ($MinerCombinations | Sort-Object -Descending { $_.Combination.Where({ [Double]::IsNaN($_.$Bias) }).Count }, { ($_.Combination.$Bias | Measure-Object -Sum).Sum }, { ($_.Combination.Where({ $_.$Bias -ne 0 }) | Measure-Object).Count } -Top 1).Combination
                    $MinerCombinations.ForEach({ $_.Combination.ForEach({ $_.$Bias -= $SmallestBias }) })

                    # Revert running miner bonus
                    $Miners.Where({ $_.Status -eq [MinerStatus]::Running }).ForEach({ $_.$Bias /= $RunningMinerBonusFactor })
                    Remove-Variable Bias, MinerCombinations, MinerDeviceNameCount, RunningMinerBonusFactor, SmallestBias -ErrorAction Ignore
                }

                $Variables.PowerConsumptionIdleSystemW = (($Config.PowerConsumptionIdleSystemW - ($MinersBest.Where({ $_.Type -eq "CPU" }) | Measure-Object PowerConsumption -Sum).Sum), 0 | Measure-Object -Maximum).Maximum
                $Variables.BasePowerCost = [Double]($Variables.PowerConsumptionIdleSystemW / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates.($Config.PayoutCurrency).($Config.MainCurrency))
                $Variables.MiningEarning = [Double]($MinersBest | Measure-Object Earning_Bias -Sum).Sum
                $Variables.MiningPowerCost = [Double]($MinersBest | Measure-Object PowerCost -Sum).Sum
                $Variables.MiningPowerConsumption = [Double]($MinersBest | Measure-Object PowerConsumption -Sum).Sum
                $Variables.MiningProfit = [Double](($MinersBest | Measure-Object Profit_Bias -Sum).Sum - $Variables.BasePowerCost)
            }
            Else { 
                $Variables.PowerConsumptionIdleSystemW = (($Config.PowerConsumptionIdleSystemW), 0 | Measure-Object -Maximum).Maximum
                $Variables.BasePowerCost = [Double]($Variables.PowerConsumptionIdleSystemW / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates.($Config.PayoutCurrency).($Config.MainCurrency))
                $Variables.MinersOptimal = $Variables.MinersBestPerDevice = $Variables.MinerDeviceNamesCombinations = $MinersBest = [Miner[]]@()
                $Variables.MiningEarning = $Variables.MiningProfit = $Variables.MiningPowerCost = $Variables.MiningPowerConsumption = [Double]0
            }
            Remove-Variable Bias -ErrorAction Ignore
        }

        $Variables.MinersNeedingBenchmark = $Miners.Where({ $_.Available -and $_.Benchmark }) | Sort-Object -Property Name -Unique
        $Variables.MinersNeedingPowerConsumptionMeasurement = $Miners.Where({ $_.Available -and $_.MeasurePowerConsumption }) | Sort-Object -Property Name -Unique

        # ProfitabilityThreshold check - OK to run miners?
        $Miners.ForEach({ $_.Best = $false })
        If ($Variables.DonationRunning -or $Variables.MinersNeedingBenchmark -or $Variables.MinersNeedingPowerConsumptionMeasurement -or (-not $Config.CalculatePowerCost -and $Variables.MiningEarning -ge ($Config.ProfitabilityThreshold / $Variables.Rates.BTC.($Config.MainCurrency))) -or ($Config.CalculatePowerCost -and $Variables.MiningProfit -ge ($Config.ProfitabilityThreshold / $Variables.Rates.BTC.($Config.MainCurrency)))) { 
            $MinersBest.ForEach({ $_.Best = $true })
            If ($Variables.Rates.($Config.PayoutCurrency)) { 
                If ($Variables.MinersNeedingBenchmark.Count) { 
                    $Variables.Summary = "Earning / day: n/a (Benchmarking: $($Variables.MinersNeedingBenchmark.Count) $(If ($Variables.MinersNeedingBenchmark.Count -eq 1) { "miner" } Else { "miners" }) left$(If ($Variables.EnabledDevices.Count -gt 1) { " [$((($Variables.MinersNeedingBenchmark | Group-Object { [String]$_.DeviceNames } | Sort-Object -Property Name).ForEach({ "$($_.Name): $($_.Count)" })) -join ', ')]" }))"
                }
                ElseIf ($Variables.MiningEarning -gt 0) { 
                    $Variables.Summary = "Earning / day: {0:n} {1}" -f ($Variables.MiningEarning * $Variables.Rates.($Config.PayoutCurrency).($Config.MainCurrency)), $Config.MainCurrency
                }
                Else { 
                    $Variables.Summary = ""
                }

                If ($Variables.CalculatePowerCost -and $Variables.PoolsBest) { 
                    If ($Variables.Summary -ne "") { $Variables.Summary += "&ensp;&ensp;&ensp;" }

                    If ($Variables.MinersNeedingPowerConsumptionMeasurement.Count -or [Double]::IsNaN($Variables.MiningPowerCost)) { 
                        $Variables.Summary += "Profit / day: n/a (Measuring power consumption: $($Variables.MinersNeedingPowerConsumptionMeasurement.Count) $(If ($Variables.MinersNeedingPowerConsumptionMeasurement.Count -eq 1) { "miner" } Else { "miners" }) left$(If ($Variables.EnabledDevices.Count -gt 1) { " [$((($Variables.MinersNeedingPowerConsumptionMeasurement | Group-Object { [String]$_.DeviceNames } | Sort-Object -Property Name).ForEach({ "$($_.Name): $($_.Count)" })) -join ', ')]" }))"
                    }
                    ElseIf ($Variables.MinersNeedingBenchmark.Count) { 
                        $Variables.Summary += "Profit / day: n/a"
                    }
                    ElseIf ($Variables.MiningPowerConsumption -gt 0) { 
                        $Variables.Summary += "Profit / day: {0:n} {1}" -f ($Variables.MiningProfit * $Variables.Rates.($Config.PayoutCurrency).($Config.MainCurrency)), $Config.MainCurrency
                    }
                    Else { 
                        $Variables.Summary += "Profit / day: n/a (no power data)"
                    }

                    If ($Variables.CalculatePowerCost) { 
                        If ($Variables.Summary -ne "") { $Variables.Summary += "&ensp;&ensp;&ensp;" }

                        If ([Double]::IsNaN($Variables.MiningEarning) -or [Double]::IsNaN($Variables.MiningPowerCost)) { 
                            $Variables.Summary += "Power Cost / day: n/a&ensp;[Miner$(If ($MinersBest.Count -ne 1) { "s" }): n/a; Base: {1:n} {0} ({2:n2} W)]" -f $Config.MainCurrency, ($Variables.BasePowerCost * $Variables.Rates.($Config.PayoutCurrency).($Config.MainCurrency)), $Variables.PowerConsumptionIdleSystemW
                        }
                        ElseIf ($Variables.MiningPowerConsumption -gt 0) { 
                            $Variables.Summary += "Power Cost / day: {1:n} {0}&ensp;[Miner$(If ($MinersBest.Count -ne 1) { "s" }): {2:n} {0} ({3:n2} W); Base: {4:n} {0} ({5:n2} W)]" -f $Config.MainCurrency, (($Variables.MiningPowerCost + $Variables.BasePowerCost) * $Variables.Rates.($Config.PayoutCurrency).($Config.MainCurrency)), ($Variables.MiningPowerCost * $Variables.Rates.($Config.PayoutCurrency).($Config.MainCurrency)), $Variables.MiningPowerConsumption, ($Variables.BasePowerCost * $Variables.Rates.($Config.PayoutCurrency).($Config.MainCurrency)), $Variables.PowerConsumptionIdleSystemW
                        }
                        Else { 
                            $Variables.Summary += "Power Cost / day: n/a&ensp;[Miner: n/a; Base: {1:n} {0} ({2:n2} W)]" -f $Config.MainCurrency, ($Variables.BasePowerCost * $Variables.Rates.BTC.($Config.MainCurrency)), $Variables.PowerConsumptionIdleSystemW
                        }
                    }
                }
                If ($Variables.Summary -ne "") { $Variables.Summary += "<br>" }

                # Add currency conversion rates
                @((@(If ($Config.UsemBTC) { "mBTC" } Else { ($Config.PayoutCurrency) }) + @($Config.ExtraCurrencies)) | Select-Object -Unique).Where({ $Variables.Rates.$_.($Config.MainCurrency) }).ForEach(
                    { 
                        $Variables.Summary += "1 $_ = {0:N$(Get-DecimalsFromValue -Value $Variables.Rates.$_.($Config.MainCurrency) -DecimalsMax $Config.DecimalsMax)} $($Config.MainCurrency)&ensp;&ensp;&ensp;" -f $Variables.Rates.$_.($Config.MainCurrency)
                    }
                )
            }
            Else { 
                $Variables.Summary = "Error:<br>Could not get BTC exchange rate from min-api.cryptocompare.com"
            }
        }
        Else { 
            # Mining earning/profit is below threshold
            $MinersBest = [Miner[]]@()
            $Variables.Summary = "Mining profit {0} {1:n$($Config.DecimalsMax)} / day is below the configured threshold of {0} {2:n$($Config.DecimalsMax)} / day. Mining is suspended until threshold is reached." -f $Config.MainCurrency, (($Variables.MiningEarning - $(If ($Config.CalculatePowerCost) { $Variables.MiningPowerCost - $Variables.BasePowerCost } Else { 0 })) * $Variables.Rates.($Config.PayoutCurrency).($Config.MainCurrency)), $Config.ProfitabilityThreshold
            Write-Message -Level Warn ($Variables.Summary -replace '<br>', ' ' -replace ' / day', '/day')
            If ($Variables.Rates) { 
                # Add currency conversion rates
                If ($Variables.Summary -ne "") { $Variables.Summary += "<br>" }
                @((@(If ($Config.UsemBTC) { "mBTC" } Else { $Config.PayoutCurrency }) + @($Config.ExtraCurrencies)) | Select-Object -Unique).Where({ $Variables.Rates.$_.($Config.MainCurrency) }).ForEach(
                    { 
                        $Variables.Summary += "1 $_ = {0:N$(Get-DecimalsFromValue -Value $Variables.Rates.$_.($Config.MainCurrency) -DecimalsMax $Config.DecimalsMax)} $($Config.MainCurrency)&ensp;&ensp;&ensp;" -f $Variables.Rates.$_.($Config.MainCurrency)
                    }
                )
            }
        }

        If (-not $MinersBest) { $Miners.ForEach({ $_.Best = $false }) }

        # Stop running miners
        ForEach ($Miner in @($Miners.Where({ $_.Status -in @([MinerStatus]::DryRun, [MinerStatus]::Running) }) | Sort-Object { [String]$_.DeviceNames })) { 
            If ($Miner.Status -eq [MinerStatus]::Running -and $Miner.GetStatus() -ne [MinerStatus]::Running) { 
                $Miner.StatusInfo = "'$($Miner.Info)' exited unexpectedly"
                $Miner.SetStatus([MinerStatus]::Failed)
            }
            Else { 
                If ($Miner.Benchmark -or $Miner.MeasurePowerConsumption) { 
                    If ($Miner.Activated -lt 1) { $Miner.Restart = $true } # Re-benchmark sets Activated to 0
                }
                ElseIf ($Config.DryRun -and $Miner.Status -ne [MinerStatus]::DryRun) { $Miner.Restart = $true }
                ElseIf (-not $Config.DryRun -and $Miner.Status -eq [MinerStatus]::DryRun) { $Miner.Restart = $true }
                If ($Miner.Restart -or -not $Miner.Best -or $Variables.NewMiningStatus -ne "Running") { 
                    ForEach ($Worker in $Miner.WorkersRunning) { 
                        If ($WatchdogTimers = @($Variables.WatchdogTimers.Where({ $_.MinerName -eq $Miner.Name -and $_.PoolName -eq $Worker.Pool.Name -and $_.PoolRegion -eq $Worker.Pool.Region -and $_.AlgorithmVariant -eq $Worker.Pool.AlgorithmVariant -and $_.DeviceNames -eq $Miner.DeviceNames }))) { 
                            # Remove Watchdog timers
                            $Variables.WatchdogTimers = @($Variables.WatchdogTimers.Where({ $_ -notin $WatchdogTimers }))
                        }
                    }
                    $Miner.SetStatus([MinerStatus]::Idle)
                    Remove-Variable WatchdogTimers, Worker -ErrorAction Ignore
                }
            }
            $Variables.Devices.Where({ $_.Name -in $Miner.DeviceNames }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
        }
        Remove-Variable Miner, WatchdogTimers, Worker -ErrorAction Ignore

        # Kill stuck miners on subsequent cycles when not in dry run mode
        If (-not $Config.DryRun -or $Variables.CycleStarts.Count -eq 1 -or $Variables.MinersNeedingBenchmark -or $Variables.MinersNeedingPowerConsumptionMeasurement) { 
            $Loops = 0
            # Some miners, e.g. BzMiner spawn a second executable
            While ($StuckMinerProcessIDs = (Get-CimInstance CIM_Process).Where({ $_.ExecutablePath -and ($Miners.Path | Sort-Object -Unique) -contains $_.ExecutablePath -and (Get-CimInstance win32_process -Filter "ParentProcessId = $($_.ProcessId)") -and $Miners.ProcessID -notcontains $_.ProcessID }) | Select-Object -ExpandProperty ProcessID) { 
                    $StuckMinerProcessIDs.ForEach(
                    { 
                        If ($Miner = $Miners | Where-Object ProcessID -EQ $_) { Write-Message -Level Verbose "Killing stuck miner '$($Miner.Name)'." }
                        If ($ChildProcessID = (Get-CimInstance win32_process -Filter "ParentProcessId = $_").ProcessID) { Stop-Process -Id $ChildProcessID -Force -ErrorAction Ignore }
                        Stop-Process -Id $_ -Force -ErrorAction Ignore
                    }
                )
                Start-Sleep -Milliseconds 500
                $Loops ++
                If ($Loops -gt 50) { 
                    If ($Config.AutoReboot) { 
                        Write-Message -Level Error "$(If ($StuckMinerProcessIDs.Count -eq 1) { "A miner " } Else { "Some miners are" }) stuck and cannot get stopped graciously. Restarting computer in 30 seconds..."
                        shutdown.exe /r /t 30 /c "$($Variables.Branding.ProductLabel) detected stuck miner$(If ($StuckMinerProcessIDs.Count -ne 1) { "s" }) and will reboot the computer in 30 seconds."
                        Start-Sleep -Seconds 60
                    }
                    Else { 
                        Write-Message -Level Error "$(If ($StuckMinerProcessIDs.Count -eq 1) { "A miner " } Else { "Some miners are" }) stuck and cannot get stopped graciously. It is recommended to restart the computer."
                        Start-Sleep -Seconds 30 
                    }
                }
            }
            Remove-Variable ChildProcessID, Loops, Message, Miner, StuckMinerProcessIDs -ErrorAction Ignore
        }

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
            }
        )

        # Update data in API
        $Variables.Miners = [Miner[]]@($Miners.Where({ $_.SideIndicator -ne "<=" }))
        $Variables.MinersBest = $MinersBest
        Remove-Variable Miners, MinersBest -ErrorAction Ignore

        $Variables.Miners.ForEach({ $_.PSObject.Properties.Remove("SideIndicator") })

        If (-not ($Variables.EnabledDevices -and $Variables.Miners.Where({ $_.Available }))) { 
            $Variables.Miners = [Miner[]]@()
            $Variables.RefreshNeeded = $true
            If (-not $Variables.EnabledDevices) { 
                Write-Message -Level Warn "No enabled devices - retrying in $($Config.Interval) seconds..."
                Start-Sleep -Seconds $Config.Interval
                Write-Message -Level Info "Ending cycle (No enabled devices)."
            }
            ElseIf (-not $Variables.PoolName) { 
                Write-Message -Level Warn "No configured pools - retrying in $($Config.Interval) seconds..."
                Start-Sleep -Seconds $Config.Interval
                Write-Message -Level Info "Ending cycle (No configured pools)."
            }
            ElseIf (-not $Variables.PoolsBest) { 
                Write-Message -Level Warn "No available pools - retrying in $($Config.Interval) seconds..."
                Start-Sleep -Seconds $Config.Interval
                Write-Message -Level Info "Ending cycle (No available pools)."
            }
            Else { 
                Write-Message -Level Warn "No available miners - retrying in $($Config.Interval) seconds..."
                Start-Sleep -Seconds $Config.Interval
                Write-Message -Level Info "Ending cycle (No available miners)."
            }
            Continue
        }

        If (-not $Variables.MinersBest) { 
            $Variables.Miners.ForEach({ $_.Status = [MinerStatus]::Idle; $_.StatusInfo = "Idle" })
            $Variables.Devices.Where({ $_.State -eq [DeviceState]::Enabled }).ForEach({ $_.Status = [MinerStatus]::Idle; $_.StatusInfo = "Idle" })
            $Variables.RefreshNeeded = $true
            Write-Message -Level Warn "No profitable miners - retrying in $($Config.Interval) seconds..."
            Start-Sleep -Seconds $Config.Interval
            Write-Message -Level Info "Ending cycle (No profitable miners)."
            Continue
        }

        # Core suspended with <Ctrl><Alt>P in MainLoop
        While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

        # Optional delay to avoid blue screens
        Start-Sleep -Seconds $Config.Delay

        ForEach ($Miner in $Variables.MinersBest | Sort-Object { [String]$_.DeviceNames }) { 
            If ($Miner.Status -ne [MinerStatus]::DryRun -and $Miner.GetStatus() -ne [MinerStatus]::Running) { 
                If ($Miner.Status -ne [MinerStatus]::DryRun) { 
                    # Launch prerun if exists
                    If ($Miner.Type -eq "AMD" -and (Test-Path -LiteralPath ".\Utils\Prerun\AMDPrerun.bat" -PathType Leaf)) { 
                        Start-Process ".\Utils\Prerun\AMDPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                    }
                    ElseIf ($Miner.Type -eq "CPU" -and (Test-Path -LiteralPath ".\Utils\Prerun\CPUPrerun.bat" -PathType Leaf)) { 
                        Start-Process ".\Utils\Prerun\CPUPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                    }
                    ElseIf ($Miner.Type -eq "INTEL" -and (Test-Path -LiteralPath ".\Utils\Prerun\INTELPrerun.bat" -PathType Leaf)) { 
                        Start-Process ".\Utils\Prerun\INTELPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                    }
                    ElseIf ($Miner.Type -eq "NVIDIA" -and (Test-Path -LiteralPath ".\Utils\Prerun\NVIDIAPrerun.bat" -PathType Leaf)) { 
                        Start-Process ".\Utils\Prerun\NVIDIAPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                    }
                    $MinerAlgorithmPrerunName = ".\Utils\Prerun\$($Miner.Name)$(If ($Miner.Algorithms.Count -eq 1) { "_$($Miner.Algorithms[0])" }).bat"
                    $AlgorithmPrerunName = ".\Utils\Prerun\$($Miner.Algorithms -join '-').bat"
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
                }

                If ($Miner.Workers.Pool.DAGSizeGiB) { 
                    # Add extra time when CPU mining and miner requires DAG creation
                    If ($Variables.MinersBest.Type -contains "CPU" -and -not $Config.DryRun) { $Miner.WarmupTimes[0] += 15 <# seconds #>}
                    # Add extra time when notebook runs on battery
                    If ((Get-CimInstance Win32_Battery).BatteryStatus -eq 1) { $Miner.WarmupTimes[0] += 90 <# seconds #>}
                }

                If ($Config.DryRun -and -not ($Miner.Benchmark -or $Miner.MeasurePowerConsumption)) {
                    $Miner.SetStatus([MinerStatus]::DryRun)
                }
                Else { 
                    $Miner.SetStatus([MinerStatus]::Running)
                }
                $Variables.Devices.Where({ $_.Name -in $Miner.DeviceNames }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })

                # Add watchdog timer
                If ($Config.Watchdog) { 
                    ForEach ($Worker in $Miner.Workers) { 
                        $Variables.WatchdogTimers += [PSCustomObject]@{ 
                            Algorithm        = $Worker.Pool.Algorithm
                            AlgorithmVariant = $Worker.Pool.AlgorithmVariant
                            DeviceNames      = $Miner.DeviceNames
                            Kicked           = [DateTime]::Now.ToUniversalTime()
                            MinerBaseName    = $Miner.BaseName
                            MinerName        = $Miner.Name
                            MinerVersion     = $Miner.Version
                            PoolName         = $Worker.Pool.Name
                            PoolRegion       = $Worker.Pool.Region
                            PoolVariant      = $Worker.Pool.Variant
                            CommandLine      = $Miner.CommandLine
                        }
                    }
                    Remove-Variable Worker -ErrorAction Ignore
                }
            }
            Else { 
                $DataCollectInterval = If ($Miner.Benchmark -or $Miner.MeasurePowerConsumption) { 1 } Else { 5 }
                If ($Miner.DataCollectInterval -ne $DataCollectInterval) {
                    $Miner.DataCollectInterval = $DataCollectInterval
                    $Miner.RestartDataReader()
                }
                Remove-Variable DataCollectInterval
            }
        }

        ForEach ($Miner in $Variables.MinersBest | Sort-Object { [String]$_.DeviceNames }) { 
            If ($Message = "$(If ($Miner.Benchmark) { "Benchmarking" })$(If ($Miner.Benchmark -and $Miner.MeasurePowerConsumption) { " and measuring power consumption" } ElseIf ($Miner.MeasurePowerConsumption) { "Measuring power consumption" })") { 
                Write-Message -Level Verbose "$Message for miner '$($Miner.Info)' in progress [Attempt $($Miner.Activated) of $($Variables.WatchdogCount + 1); min. $($Miner.MinDataSample) samples]..."
            }
        }
        Remove-Variable Miner, Message -ErrorAction Ignore

        ($Variables.Miners.Where({ $_.Available }) | Group-Object { [String]$_.DeviceNames }).ForEach(
            { 
                # Display benchmarking progress
                If ($MinersDeviceGroupNeedingBenchmark = $_.Group.Where({ $_.Benchmark })) { 
                    $Count = ($MinersDeviceGroupNeedingBenchmark | Select-Object -Property Name -Unique).Count
                    Write-Message -Level Info "Benchmarking for '$($_.Name)' in progress. $Count miner$(If ($Count -gt 1) { 's' }) left to complete benchmarking."
                }
                # Display power consumption measurement progress
                If ($MinersDeviceGroupNeedingPowerConsumptionMeasurement = $_.Group.Where({ $_.MeasurePowerConsumption })) { 
                    $Count = ($MinersDeviceGroupNeedingPowerConsumptionMeasurement | Select-Object -Property Name -Unique).Count
                    Write-Message -Level Info "Power consumption measurement for '$($_.Name)' in progress. $Count miner$(If ($Count -gt 1) { 's' }) left to complete measuring."
                }
            }
        )
        Remove-Variable Count, MinersDeviceGroupNeedingBenchmark, MinersDeviceGroupNeedingPowerConsumptionMeasurement -ErrorAction Ignore

        If ($Variables.CycleStarts.Count -eq 1) { 
            # Ensure a full cycle on first loop
            $Variables.EndCycleTime = [DateTime]::Now.ToUniversalTime().AddSeconds($Config.Interval)
        }

        $Variables.RunningMiners = $Variables.MinersBest | Sort-Object -Descending -Property Benchmark, MeasurePowerConsumption
        $Variables.BenchmarkingOrMeasuringMiners = [Miner[]]@()
        $Variables.FailedMiners = [Miner[]]@()

        # Core suspended with <Ctrl><Alt>P in MainLoop
        While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

        $Variables.RefreshTimestamp = [DateTime]::Now.ToUniversalTime()
        $Variables.RefreshNeeded = $true

        Write-Message -Level Info "Collecting miner data while waiting for next cycle..."
            
        Do { 
            Start-Sleep -Milliseconds 500
            Try { 
                ForEach ($Miner in $Variables.RunningMiners.Where({ $_.Status -ne [MinerStatus]::DryRun })) { 
                    If ($Miner.GetStatus() -ne [MinerStatus]::Running) { 
                        # Miner crashed
                        $Miner.StatusInfo = "'$($Miner.Info)' exited unexpectedly"
                        $Miner.SetStatus([MinerStatus]::Failed)
                        $Variables.FailedMiners += $Miner
                    }
                    ElseIf ($Miner.DataReaderJob.State -ne [MinerStatus]::Running) { 
                        # Miner data reader process failed
                        $Miner.StatusInfo = "'$($Miner.Info)' miner data reader exited unexpectedly"
                        $Miner.SetStatus([MinerStatus]::Failed)
                        $Variables.FailedMiners += $Miner
                    }
                    Else { 
                        If ($Miner.DataReaderJob.HasMoreData) { 
                            If ($Samples = @($Miner.DataReaderJob | Receive-Job | Select-Object)) { 
                                $Sample = $Samples[-1]
                                $Miner.Hashrates_Live = $Sample.Hashrate.PSObject.Properties.Value
                                $Miner.DataSampleTimestamp = $Sample.Date
                                If ($Miner.ReadPowerConsumption) { $Miner.PowerConsumption_Live = $Sample.PowerConsumption }
                                If ($Sample.Hashrate.PSObject.Properties.Value -notcontains 0) { 
                                    # Need hashrates for all algorithms to count as a valid sample
                                    If ($Miner.ValidDataSampleTimestamp -eq [DateTime]0) { 
                                        $Miner.ValidDataSampleTimestamp = $Sample.Date.AddSeconds($Miner.WarmupTimes[1])
                                    }
                                    If (($Sample.Date - $Miner.ValidDataSampleTimestamp) -ge 0) { 
                                        $Miner.Data += $Samples
                                        Write-Message -Level Verbose "$($Miner.Name) data sample collected [$(($Sample.Hashrate.PSObject.Properties.Name.ForEach({ "$($_): $(($Sample.Hashrate.$_ | ConvertTo-Hash) -replace ' ')$(If ($Config.ShowShares) { " / Shares Total: $($Sample.Shares.$_[3]), Rejected: $($Sample.Shares.$_[1]), Ignored: $($Sample.Shares.$_[2])" })" })) -join ' & ')$(If ($Sample.PowerConsumption) { " / Power consumption: $($Sample.PowerConsumption.ToString("N2"))W" })] ($($Miner.Data.Count) Sample$(If ($Miner.Data.Count -ne 1) { "s" }))"
                                        If ($Miner.Activated -gt 0 -and ($Miner.Benchmark -or $Miner.MeasurePowerConsumption)) { 
                                            $Miner.StatusInfo = "$(If ($Miner.Benchmark) { "Benchmarking" })$(If ($Miner.Benchmark -and $Miner.MeasurePowerConsumption) { " and measuring power consumption" } ElseIf ($Miner.MeasurePowerConsumption) { "Measuring power consumption" }) '$($Miner.Info)'"
                                            $Miner.SubStatus = "benchmarking"
                                        }
                                        Else {
                                            $Miner.StatusInfo = "Mining '$($Miner.Info)'"
                                            $Miner.SubStatus = "running"
                                        }
                                    }
                                    Else { 
                                        Write-Message -Level Verbose "$($Miner.Name) data sample discarded [$(($Sample.Hashrate.PSObject.Properties.Name.ForEach({ "$($_): $(($Sample.Hashrate.$_ | ConvertTo-Hash) -replace ' ')$(If ($Config.ShowShares) { " / Shares Total: $($Sample.Shares.$_[3]), Rejected: $($Sample.Shares.$_[1]), Ignored: $($Sample.Shares.$_[2])" })" })) -join ' & ')$(If ($Sample.PowerConsumption) { " / Power consumption: $($Sample.PowerConsumption.ToString("N2"))W" })] (Miner is warming up [$(([DateTime]::Now.ToUniversalTime() - $Miner.ValidDataSampleTimestamp).TotalSeconds.ToString("0") -replace '-0', '0') sec])"
                                        $Miner.StatusInfo = "Warming up '$($Miner.Info)'"
                                        $Miner.SubStatus = "warmingup"
                                    }
                                }
                            }
                        }
                        ElseIf ($Variables.NewMiningStatus -eq "Running") { 
                            # Stop miner, it has not provided hash rate on time
                            If ($Miner.ValidDataSampleTimestamp -eq [DateTime]0 -and [DateTime]::Now.ToUniversalTime() -gt $Miner.BeginTime.AddSeconds($Miner.WarmupTimes[0])) { 
                                $Miner.StatusInfo = "'$($Miner.Info)' has not provided first valid data sample in $($Miner.WarmupTimes[0]) seconds"
                                $Miner.SetStatus([MinerStatus]::Failed)
                                $Variables.FailedMiners += $Miner
                            }
                            # Miner stuck - no sample received in last few data collect intervals
                            ElseIf ($Miner.ValidDataSampleTimestamp -gt [DateTime]0 -and [DateTime]::Now.ToUniversalTime() -gt $Miner.DataSampleTimestamp.AddSeconds((($Miner.DataCollectInterval * 5), 10 | Measure-Object -Maximum).Maximum * $Miner.Algorithms.Count)) { 
                                $Miner.StatusInfo = "'$($Miner.Info)' has not updated data for more than $((($Miner.DataCollectInterval * 5), 10 | Measure-Object -Maximum).Maximum * $Miner.Algorithms.Count) seconds"
                                $Miner.SetStatus([MinerStatus]::Failed)
                                $Variables.FailedMiners += $Miner
                            }
                        }
                        Try {
                            # Set miner priority, some miners reset priority on their own
                            $Miner.Process.PriorityClass = $Global:PriorityNames.($Miner.ProcessPriority)
                            # Set window title
                            [Void][Win32]::SetWindowText($Miner.Process.MainWindowHandle, $Miner.StatusInfo)
                        } Catch { }
                    }
                    $Variables.Devices.Where({ $_.Name -in $Miner.DeviceNames }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                }
                Remove-Variable Miner, Sample, Samples -ErrorAction Ignore

                $Variables.RunningMiners = $Variables.RunningMiners.Where({ $_ -notin $Variables.FailedMiners })
                $Variables.BenchmarkingOrMeasuringMiners = $Variables.RunningMiners.Where({ $_.Activated -gt 0 -and ($_.Benchmark -or $_.MeasurePowerConsumption) })

                If ($Variables.FailedMiners) { 
                    # A miner crashed , exit loop immediately
                    $Variables.EndCycleMessage = " prematurely (miner failed)"
                }
                ElseIf ($Variables.BenchmarkingOrMeasuringMiners.Where({ $_.Data.Count -ge $_.MinDataSample })) { 
                    # Enough samples collected for this loop, exit loop immediately
                    $Variables.EndCycleMessage = " (a$(If ($Variables.BenchmarkingOrMeasuringMiners.Where({ $_.Benchmark })) { " benchmarking" })$(If ($Variables.BenchmarkingOrMeasuringMiners.Where({ $_.Benchmark -and $_.MeasurePowerConsumption })) { " and" })$(If ($Variables.BenchmarkingOrMeasuringMiners.Where({ $_.MeasurePowerConsumption })) { " power consumption measuring" }) miner has collected enough samples for this cycle)"
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
            # - a miner crashed
            # - a benchmarking miner has collected enough samples
            # - WarmupTimes[0] is reached and no readout from miner
            # - when not benchmnarking: Interval time is over
        } While ($Variables.NewMiningStatus -eq "Running" -and -not $Variables.EndCycleMessage -and ([DateTime]::Now.ToUniversalTime() -le $Variables.EndCycleTime -or $Variables.BenchmarkingOrMeasuringMiners))

        # Expire brains loop to collect data
        If ($Variables.EndCycleMessage) { 
            $Variables.EndCycleTime = [DateTime]::Now.ToUniversalTime()
            Start-Sleep -Seconds 1
        }
    }
    Catch { 
        Write-Message -Level Error "Error in file '$(($_.InvocationInfo.ScriptName -split "\\" | Select-Object -Last 2) -join "\")' line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting core..."
        "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $ErrorLogFile
        $_.Exception | Format-List -Force >> $ErrorLogFile
        $_.InvocationInfo | Format-List -Force >> $ErrorLogFile
        $Variables.EndCycleTime = $Variables.StartCycleTime.AddSeconds($Config.Interval) # Reset timers
        Continue
    }

    Get-Job -State "Completed" | Receive-Job | Out-Null
    Get-Job -State "Completed" | Remove-Job -Force -ErrorAction Ignore | Out-Null
    Get-Job -State "Failed" | Receive-Job | Out-Null
    Get-Job -State "Failed" | Remove-Job -Force -ErrorAction Ignore | Out-Null
    Get-Job -State "Stopped" | Receive-Job | Out-Null
    Get-Job -State "Stopped" | Remove-Job -Force -ErrorAction Ignore | Out-Null

    $Error.Clear()
    [System.GC]::Collect()  

    $Variables.RestartCycle = $true

    If ($Variables.NewMiningStatus -eq "Running" -and $Variables.IdleDetectionRunspace.MiningStatus -ne "Suspended") { Write-Message -Level Info "Ending cycle$($Variables.EndCycleMessage)." }

} While ($Variables.NewMiningStatus -eq "Running")

# Stop all running miners
ForEach ($Miner in $Variables.Miners.Where({ $_.Status -in @([MinerStatus]::DryRun, [MinerStatus]::Running) })) { 
    $Miner.SetStatus([MinerStatus]::Idle)
    $Variables.Devices.Where({ $_.Name -in $Miner.DeviceNames }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
}
Remove-Variable Miner -ErrorAction Ignore

If ($Variables.IdleDetectionRunspace.MiningStatus -ne "Suspended") { Write-Message -Level Info "Ending cycle$($Variables.EndCycleMessage)." }