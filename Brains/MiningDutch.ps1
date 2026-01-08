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
File:           \Brains\MiningDutch.ps1
Version:        6.7.19
Version date:   2026/01/08
#>

using module ..\Includes\Include.psm1

# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

$PoolObjects = @()
$Durations = [TimeSpan[]]@()

$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

$Headers = @{ "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"; "Cache-Control" = "no-cache" }
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

# Get mutex. Mutexes are shared across all threads and processes.
# This lets us ensure only one thread is trying to query the pool API
$Mutex = [System.Threading.Mutex]::new($false, "$($Session.Branding.ProductLabel)_MiningDutchPoolAPI")

while ($PoolConfig = $Session.Config.Pools.$Name) { 

    $APICallFails = 0
    $PoolVariant = $Session.Config.PoolName.Where({ $_ -like "$Name*" })
    $RetryInterval = $Session.Config.Pools.$Name.PoolAPIretryInterval
    $StartTime = [DateTime]::Now

    if ($Session.MyIPaddress) { 
        try { 

            Write-Message -Level Debug "Brain '$Name': Start loop$(if ($Duration) { " (Previous loop duration: $Duration sec.)" })"

            do { 
                try { 
                    if (-not $AlgoData) { 
                        # Attempt to aquire mutex
                        if ($Mutex.WaitOne(1000)) { 
                            $URI = "https://www.mining-dutch.nl/api/status"
                            Write-Message -Level Debug "Brain '$Name': Querying $URI"
                            $AlgoData = Invoke-RestMethod -Uri $URI -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPItimeout
                            $Session."$($Name)APIrequestTimestamp" = [DateTime]::Now.ToUniversalTime()
                            $Session.Brains.$Name | Add-Member "APIresponseAlgoData" ($AlgoData | ConvertTo-Json -Compress) -Force
                            Write-Message -Level Debug "Brain '$Name': Response from $URI received"
                            if ($AlgoData -like "<!DOCTYPE html>*") { $AlgoData = $null }
                            elseif ($AlgoData.message -match "^Only \d request every ") { 
                                Write-Message -Level Debug "Brain '$Name': Response '$($AlgoData.message)' from $URI received"
                                Start-Sleep -Seconds [Int](($AlgoData.message -replace "^Only \d request every " -replace " seconds allowed$") + 1)
                                $AlgoData = $null
                            }
                            $Mutex.ReleaseMutex()
                        }
                    }
                    if (-not $TotalStats) { 
                        # Attempt to aquire mutex
                        if ($Mutex.WaitOne(1000)) { 
                            $URI = "https://www.mining-dutch.nl/api/v1/public/pooldata/?method=totalstats"
                            Write-Message -Level Debug "Brain '$Name': Querying $URI"
                            $TotalStats = Invoke-RestMethod -Uri $URI -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPItimeout
                            $Session."$($Name)APIrequestTimestamp" = [DateTime]::Now.ToUniversalTime()
                            $Session.Brains.$Name | Add-Member "APIresponseTotalStats" ($TotalStats | ConvertTo-Json -Compress) -Force
                            Write-Message -Level Debug "Brain '$Name': Response from $URI received"
                            if ($TotalStats -like "<!DOCTYPE html>*") { $TotalStats = $null }
                            elseif ($TotalStats.message -match "^Only \d request every ") { 
                                Write-Message -Level Debug "Brain '$Name': Response '$($TotalStats.message)' from $URI received"
                                Start-Sleep -Seconds [Int](($TotalStats.message -replace "^Only \d request every " -replace " seconds allowed$") + 1)
                                $TotalStats = $null
                            }
                            $Mutex.ReleaseMutex()
                        }
                    }
                    Remove-Variable URI -ErrorAction Ignore
                }
                catch { 
                    $APICallFails ++
                    $APIerror = $_.Exception.Message
                    Write-Message -Level Debug "Brain '$Name': Query to $URI failed"
                    if ($APICallFails -lt $PoolConfig.PoolAPIallowedFailureCount) { Start-Sleep -Seconds ([Math]::max(15, $PoolConfig.PoolAPIretryInterval)) }
                }
            } while (-not ($AlgoData -and $TotalStats) -and $APICallFails -le $Session.Config.PoolAPIallowedFailureCount)

            $Timestamp = [DateTime]::Now.ToUniversalTime()

            if ($APICallFails -gt $Session.Config.PoolAPIallowedFailureCount) { 
                Write-Message -Level Warn "Brain $($Name): Problem when trying to access https://www.mining-dutch.nl/api [$($APIerror -replace '\.$')]."
            }
            else {
                ($AlgoData.PSObject.Properties.Name).Where({ $TotalStats.result.algorithm -notcontains $_ }).foreach({ $AlgoData.PSObject.Properties.Remove($_) })
            }

            if ($AlgoData -and $TotalStats) { 

                # Change numeric string to numbers, some values are null
                $AlgoData = ($AlgoData | ConvertTo-Json) -replace ": `"(\d+\.?\d*)`"", ": `$1" -replace "`": null", "`": 0" | ConvertFrom-Json
                $TotalStats = ($TotalStats | ConvertTo-Json) -replace ": `"(\d+\.?\d*)`"", ": `$1" -replace "`": null", "`": 0" | ConvertFrom-Json

                foreach ($Algorithm in $AlgoData.PSObject.Properties.Name) { 
                    $AlgorithmNorm = Get-Algorithm $Algorithm
                    $BasePrice = if ($AlgoData.$Algorithm.actual_last24h) { $AlgoData.$Algorithm.actual_last24h } else { $AlgoData.$Algorithm.estimate_last24h }

                    # Temp fix, incorrect data in API
                    if ($AlgorithmNorm -eq "Neoscrypt" -and $AlgoData.$Algorithm.mbtc_mh_factor -eq 1) { $AlgoData.$Algorithm.mbtc_mh_factor = 1000 }

                    $AlgoData.$Algorithm | Add-Member Updated $Timestamp -Force
                    if ($AlgoStats = $TotalStats.result.Where({ $_.Algorithm -eq $Algorithm })) { 
                        $AlgoData.$Algorithm | Add-Member hashrate_shared $AlgoStats.hashrate -Force
                        $AlgoData.$Algorithm | Add-Member hashrate_solo $AlgoStats.hashrate_solo -Force
                        $AlgoData.$Algorithm | Add-Member workers_shared $AlgoStats.workers -Force
                        $AlgoData.$Algorithm | Add-Member workers_solo $AlgoStats.workers_solo -Force
                    }
                    Remove-Variable AlgoStats -ErrorAction Ignore

                    # Reset history when stat file got removed
                    if ($PoolVariant -like "*Plus") { 
                        $StatName = "$($PoolVariant)_$($AlgorithmNorm)_Profit"
                        if (-not ($Stat = Get-Stat -Name $StatName) -and $PoolObjects.Where({ $_.Name -eq $PoolName })) { 
                            $PoolObjects = $PoolObjects.Where({ $_.Name -ne $PoolName })
                            Write-Message -Level Debug "Pool brain '$Name': PlusPrice history cleared for $($StatName -replace "_Profit")"
                        }
                    }

                    $PoolObjects += [PSCustomObject]@{ 
                        actual_last24h      = $BasePrice
                        Date                = $Timestamp
                        estimate_current    = $AlgoData.$Algorithm.estimate_current
                        estimate_last24h    = $AlgoData.$Algorithm.estimate_last24h
                        Last24hDrift        = $AlgoData.$Algorithm.estimate_current - $BasePrice
                        Last24hDriftPercent = if ($BasePrice -gt 0) { ($AlgoData.$Algorithm.estimate_current - $BasePrice) / $BasePrice } else { 0 }
                        Last24hDriftSign    = if ($AlgoData.$Algorithm.estimate_current -ge $BasePrice) { "Up" } else { "Down" }
                        Name                = $Algorithm
                    }
                }

                # Created here for performance optimization, minimize # of lookups
                $CurrentPoolObjects = $PoolObjects.Where({ $_.Date -eq $Timestamp })
                $SampleSizets = New-TimeSpan -Minutes $PoolConfig.BrainConfig.SampleSizeMinutes
                $SampleSizeHalfts = New-TimeSpan -Minutes ($PoolConfig.BrainConfig.SampleSizeMinutes / 2)
                $GroupAvgSampleSize = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object -Property Name, Last24hDriftSign | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
                $GroupMedSampleSize = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object -Property Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
                $GroupAvgSampleSizeHalf = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizeHalfts) }) | Group-Object -Property Name, Last24hDriftSign | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
                $GroupMedSampleSizeHalf = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizeHalfts) }) | Group-Object -Property Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
                $GroupMedSampleSizeNoPercent = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object -Property Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDrift } }

                foreach ($Algorithm in ($PoolObjects.Name | Select-Object -Unique).Where({ $AlgoData.PSObject.Properties.Name -contains $_ })) { 
                    $PenaltySampleSizeHalf = ((($GroupAvgSampleSizeHalf.Where({ $_.Name -eq $Algorithm + ", Up" })).Count - ($GroupAvgSampleSizeHalf.Where({ $_.Name -eq $Algorithm + ", Down" })).Count) / (($GroupMedSampleSizeHalf.Where({ $_.Name -eq $Algorithm })).Count)) * [Math]::abs(($GroupMedSampleSizeHalf.Where({ $_.Name -eq $Algorithm })).Median)
                    $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize.Where({ $_.Name -eq $Algorithm + ", Up" })).Count - ($GroupAvgSampleSize.Where({ $_.Name -eq $Algorithm + ", Down" })).Count) / (($GroupMedSampleSize.Where({ $_.Name -eq $Algorithm })).Count)) * [Math]::abs(($GroupMedSampleSizeNoPercent.Where({ $_.Name -eq $Algorithm })).Median)
                    $Penalty = ($PenaltySampleSizeHalf * $PoolConfig.BrainConfig.SampleHalfPower + $PenaltySampleSizeNoPercent) / ($PoolConfig.BrainConfig.SampleHalfPower + 1)
                    $LastPrice = [Double]$CurrentPoolObjects.Where({ $_.Name -eq $Algorithm }).estimate_current
                    $PlusPrice = [Math]::max(0, [Double]($LastPrice + $Penalty))

                    $StatName = if ($Currency) { "$($PoolVariant)_$(Get-Algorithm $Algorithm)-$($Currency)_Profit" } else { "$($PoolVariant)_$(Get-Algorithm $Algorithm)_Profit" }
                    # Reset history if current estimate is not within +/- 1000% of 24hr stat price
                    if ($Stat = Get-Stat -Name $StatName) { 
                        $Divisor = $PoolConfig.Variant."$PoolVariant".DivisorMultiplier * $AlgoData.$Algorithm.mbtc_mh_factor
                        if ($Stat.Day -and $LastPrice -gt 0 -and ($AlgoData.$Algorithm.estimate_current / $Divisor -lt $Stat.Day / 10 -or $AlgoData.$Algorithm.estimate_current / $Divisor -gt $Stat.Day * 10)) { 
                            Remove-Stat -Name $StatName
                            $PoolObjects = $PoolObjects.Where({ $_.Name -ne $Algorithm })
                            $PlusPrice = $LastPrice
                            Write-Message -Level Debug "Pool brain '$Name': PlusPrice history cleared for $($StatName -replace "_Profit") (stat day price: $($Stat.Day) vs. estimate current price: $($AlgoData.$Algorithm.estimate_current / $Divisor))"
                        }
                    }
                    $AlgoData.$Algorithm | Add-Member PlusPrice $PlusPrice -Force
                }
                Remove-Variable Algo, AlgorithmNorm, Baseprice, CurrentPoolObjects, GroupAvgSampleSize, GroupMedSampleSize, GroupAvgSampleSizeHalf, GroupMedSampleSizeHalf, GroupMedSampleSizeNoPercent, LastPrice, Penalty, PenaltySampleSizeHalf, PenaltySampleSizeNoPercent, PlusPrice, PoolName, SampleSizeHalfts, SampleSizets, Stat, StatName -ErrorAction Ignore

                if ($PoolConfig.BrainConfig.UseTransferFile -or $Session.Config.Pools.$Name.BrainDebug) { 
                    ($AlgoData | ConvertTo-Json).replace("NaN", 0) | Out-File -LiteralPath $BrainDataFile -Force -ErrorAction Ignore
                }
            }
            else { 
                $AlgoData = [PSCustomObject]@{ }
            }

            $Session.BrainData.$Name = $AlgoData
            $Session.Brains.$Name | Add-Member "Updated" $Timestamp -Force

            # Limit to only sample size + 10 minutes history
            $PoolObjects = @($PoolObjects.Where({ $_.Date -ge $Timestamp.AddMinutes( - ($PoolConfig.BrainConfig.SampleSizeMinutes + 10)) }))
        }
        catch { 
            Write-Message -Level Error "Error in file '$(($_.InvocationInfo.ScriptName -split "\\" | Select-Object -Last 2) -join "\")' line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting core..."
            "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Brain_$($Name)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
            $_.Exception | Format-List -Force >> "Logs\Brain_$($Name)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
            $_.InvocationInfo | Format-List -Force >> "Logs\Brain_$($Name)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
        }
        Remove-Variable AlgoData, TotalStats -ErrorAction Ignore

        $Duration = ([DateTime]::Now - $StartTime).TotalSeconds
        $Durations += ($Duration, $Session.Interval | Measure-Object -Minimum).Minimum
        $Durations = @($Durations | Select-Object -Last 20)
        $DurationsAvg = ($Durations | Measure-Object -Average).Average

        Write-Message -Level Debug "Brain '$Name': End loop (Duration $Duration sec. / Avg. loop duration: $DurationsAvg sec.); Price history $($PoolObjects.Count) objects; found $($Session.BrainData.$Name.PSObject.Properties.Name.Count) valid pools."

        $Error.Clear()
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()
    }

    while (-not $Session.EndCycleMessage -and -not $Session.MyIPaddress -or ($Timestamp -ge $Session.PoolDataCollectedTimeStamp -or ($Session.EndCycleTime -and [DateTime]::Now.ToUniversalTime().AddSeconds($DurationsAvg + 3) -le $Session.EndCycleTime))) { 
        Start-Sleep -Milliseconds 250
    }
}

Stop-Brain $Name