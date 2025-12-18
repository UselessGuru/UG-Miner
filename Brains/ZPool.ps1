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
File:           \Brains\ZPool.ps1
Version:        6.7.11
Version date:   2025/12/18
#>

using module ..\Includes\Include.psm1

# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

$PoolObjects = @()
$Durations = [TimeSpan[]]@()

$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

while ($PoolConfig = $Session.Config.Pools.$Name) { 

    $APICallFails = 0
    $PoolVariant = [String]$Session.Config.PoolName.where({ $_ -like "$Name*" })
    $StartTime = [DateTime]::Now

    if ($Session.MyIPaddress) { 
        try { 

            Write-Message -Level Debug "Brain '$Name': Start loop$(if ($Duration) { " (Previous loop duration: $Duration sec.)" })"

            do { 
                try { 
                    if (-not $AlgoData) { 
                        $AlgoData = Invoke-RestMethod -Uri "https://www.zpool.ca/api/status" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPItimeout
                        if ($AlgoData -like "<!DOCTYPE html>*") { $AlgoData = $null }
                    }
                    if (-not $CurrenciesData) { 
                        $CurrenciesData = Invoke-RestMethod -Uri "https://www.zpool.ca/api/currencies" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPItimeout
                        if ($CurrenciesData -like "<!DOCTYPE html>*") { $CurrenciesData = $null }
                    }
                }
                catch { 
                    $APICallFails ++
                    $APIerror = $_.Exception.Message
                    if ($APICallFails -lt $PoolConfig.PoolAPIallowedFailureCount) { Start-Sleep -Seconds ([Math]::max(60, ($APICallFails * 5 + $PoolConfig.PoolAPIretryInterval))) }
                }
            } while (-not ($AlgoData -and $CurrenciesData) -and $APICallFails -le $Session.Config.PoolAPIallowedFailureCount)

            $Timestamp = [DateTime]::Now.ToUniversalTime()

            if ($APICallFails -gt $Session.Config.PoolAPIallowedFailureCount) { 
                Write-Message -Level Warn "Brain $($Name): Problem when trying to access https://www.zpool.ca/api [$($APIerror -replace '\.$')]."
            }
            elseif ($AlgoData -and $CurrenciesData) { 
                # Change numeric string to numbers, some values are null
                $AlgoData = ($AlgoData | ConvertTo-Json) -replace ": `"(\d+\.?\d*)`"", ": `$1" -replace "`": null", "`": 0" | ConvertFrom-Json
                $CurrenciesData = ($CurrenciesData | ConvertTo-Json) -replace ": `"(\d+\.?\d*)`"", ": `$1" -replace "`": null", "`": 0" | ConvertFrom-Json

                # Add currency and convert to array for easy sorting
                $CurrenciesArray = [PSCustomObject[]]@()
                $CurrenciesData.PSObject.Properties.Name.where({ $CurrenciesData.$_.algo -and $CurrenciesData.$_.name -notcontains "Hashtap" }).ForEach(
                    { 
                        $CurrenciesData.$_ | Add-Member Currency $(if ($CurrenciesData.$_.symbol) { $CurrenciesData.$_.symbol -replace "-.+$" } else { $_ -replace "-.+$" })
                        try { 
                            # Add coin name
                            Add-CoinName -Algorithm $CurrenciesData.$_.algo -Currency $CurrenciesData.$_.Currency -CoinName $CurrenciesData.$_.name
                        }
                        catch { }
                        $CurrenciesData.$_ | Add-Member CoinName ([String]$Session.CoinNames[$CurrenciesData.$_.Currency]) -Force
                        $CurrenciesData.$_ | Add-Member conversion_supported ([Boolean]($PoolConfig.Wallets.($CurrenciesData.$_.Currency) -or -not $CurrenciesData.$_.only_direct))

                        $CurrenciesData.$_.PSObject.Properties.Remove("symbol")
                        $CurrenciesData.$_.PSObject.Properties.Remove("name")
                        $CurrenciesArray += $CurrenciesData.$_
                    }
                )

                # Get best currency
                ($CurrenciesArray | Group-Object -Property Algo).ForEach(
                    { 
                        if ($AlgoData.($_.name)) { 
                            $BestCurrency = ($_.Group | Sort-Object -Property conversion_supported, estimate -Descending -Top 1)
                            $AlgoData.($_.name) | Add-Member Currency $BestCurrency.currency -Force
                            $AlgoData.($_.name) | Add-Member CoinName $BestCurrency.coinname -Force
                            $AlgoData.($_.name) | Add-Member conversion_supported $BestCurrency.conversion_supported -Force
                        }
                    }
                )

                foreach ($Algorithm in $AlgoData.PSObject.Properties.Name) { 
                    $AlgorithmNorm = Get-Algorithm $Algorithm
                    if ($AlgoData.$Algorithm.actual_last24h) { $AlgoData.$Algorithm.actual_last24h /= 1000 }
                    $BasePrice = if ($AlgoData.$Algorithm.actual_last24h) { $AlgoData.$Algorithm.actual_last24h } else { $AlgoData.$Algorithm.estimate_last24h }

                    if ($Currency = $AlgoData.$Algorithm.Currency -replace "\s.*") { 
                        if ($AlgorithmNorm -match $Session.RegexAlgoHasDAG -and $CurrenciesData.$Currency.height -gt $Session.DAGdata.Currency.$Currency.BlockHeight) { 
                            # Keep DAG data data up to date
                            $DAGdata = (Get-DAGData -BlockHeight $CurrenciesData.$Currency.height -Currency $Currency -EpochReserve 2)
                            $DAGdata | Add-Member Date ([DateTime]::Now).ToUniversalTime() -Force
                            $DAGdata | Add-Member Url "https://www.zpool.ca/api/currencies"
                            $Session.DAGdata.Currency | Add-Member $Currency $DAGdata -Force
                            $Session.DAGdata.Updated | Add-Member "https://www.zpool.ca/api/currencies" ([DateTime]::Now.ToUniversalTime()) -Force
                        }
                        $AlgoData.$Algorithm | Add-Member conversion_supported $CurrenciesData.$Currency.conversion_supported -Force
                        if ($CurrenciesData.$Currency.error) { 
                            $AlgoData.$Algorithm | Add-Member error "Pool error msg: $($CurrenciesData.$Currency.error)" -Force
                        }
                        else { 
                            $AlgoData.$Algorithm | Add-Member error "" -Force
                        }
                    }
                    else { 
                        $AlgoData.$Algorithm | Add-Member error "" -Force
                        $AlgoData.$Algorithm | Add-Member conversion_supported 0 -Force

                    }
                    $AlgoData.$Algorithm | Add-Member Updated $Timestamp -Force

                    # Reset history when stat file got removed
                    if ($PoolVariant -like "*Plus") { 
                        $StatName = if ($Currency) { "$($PoolVariant)_$($AlgorithmNorm)-$($Currency)_Profit" } else { "$($PoolVariant)_$($AlgorithmNorm)_Profit" }
                        if (-not ($Stat = Get-Stat -Name $StatName) -and $PoolObjects.where({ $_.Name -eq $PoolName })) { 
                            $PoolObjects = $PoolObjects.where({ $_.Name -ne $Algorithm })
                            Write-Message -Level Debug "Pool brain '$Name': PlusPrice history cleared for $($StatName -replace "_Profit")"
                        }
                    }

                    $PoolObjects += [PSCustomObject]@{ 
                        actual_last24h      = $BasePrice
                        currency            = $Currency
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
                $CurrentPoolObjects = $PoolObjects.where({ $_.Date -eq $Timestamp })
                $SampleSizets = New-TimeSpan -Minutes $PoolConfig.BrainConfig.SampleSizeMinutes
                $SampleSizeHalfts = New-TimeSpan -Minutes ($PoolConfig.BrainConfig.SampleSizeMinutes / 2)
                $GroupAvgSampleSize = $PoolObjects.where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object -Property Name, Last24hDriftSign | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
                $GroupMedSampleSize = $PoolObjects.where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object -Property Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
                $GroupAvgSampleSizeHalf = $PoolObjects.where({ $_.Date -ge ($Timestamp - $SampleSizeHalfts) }) | Group-Object -Property Name, Last24hDriftSign | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
                $GroupMedSampleSizeHalf = $PoolObjects.where({ $_.Date -ge ($Timestamp - $SampleSizeHalfts) }) | Group-Object -Property Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
                $GroupMedSampleSizeNoPercent = $PoolObjects.where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object -Property Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDrift } }

                foreach ($Algorithm in ($PoolObjects.Name | Select-Object -Unique).where({ $AlgoData.PSObject.Properties.Name -contains $_ })) { 
                    $PenaltySampleSizeHalf = ((($GroupAvgSampleSizeHalf.where({ $_.Name -eq $Algorithm + ", Up" })).Count - ($GroupAvgSampleSizeHalf.where({ $_.Name -eq $Algorithm + ", Down" })).Count) / (($GroupMedSampleSizeHalf.where({ $_.Name -eq $Algorithm })).Count)) * [Math]::abs(($GroupMedSampleSizeHalf.where({ $_.Name -eq $Algorithm })).Median)
                    $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize.where({ $_.Name -eq $Algorithm + ", Up" })).Count - ($GroupAvgSampleSize.where({ $_.Name -eq $Algorithm + ", Down" })).Count) / (($GroupMedSampleSize.where({ $_.Name -eq $Algorithm })).Count)) * [Math]::abs(($GroupMedSampleSizeNoPercent.where({ $_.Name -eq $Algorithm })).Median)
                    $Penalty = ($PenaltySampleSizeHalf * $PoolConfig.BrainConfig.SampleHalfPower + $PenaltySampleSizeNoPercent) / ($PoolConfig.BrainConfig.SampleHalfPower + 1)
                    $CurPoolObject = $CurrentPoolObjects.where({ $_.Name -eq $Algorithm })
                    $Currency = $CurPoolObject.currency
                    $LastPrice = [Double]$CurPoolObject.estimate_current
                    $PlusPrice = [Math]::max(0, [Double]($LastPrice + $Penalty))

                    $StatName = if ($Currency) { "$($PoolVariant)_$(Get-Algorithm $Algorithm)-$($Currency)_Profit" } else { "$($PoolVariant)_$(Get-Algorithm $Algorithm)_Profit" }
                    # Reset history if current estimate is not within +/- 1000% of 24hr stat price
                    if ($Stat = Get-Stat -Name $StatName) { 
                        $Divisor = $PoolConfig.Variant."$PoolVariant".DivisorMultiplier * $AlgoData.$Algorithm.mbtc_mh_factor
                        if ($Stat.Day -and $LastPrice -gt 0 -and ($AlgoData.$Algorithm.estimate_current / $Divisor -lt $Stat.Day / 10 -or $AlgoData.$Algorithm.estimate_current / $Divisor -gt $Stat.Day * 10)) { 
                            Remove-Stat -Name $StatName
                            $PoolObjects = $PoolObjects.where({ $_.Name -ne $Algorithm })
                            $PlusPrice = $LastPrice
                            Write-Message -Level Debug "Pool brain '$Name': PlusPrice history cleared for $($StatName -replace "_Profit") (stat day price: $($Stat.Day) vs. estimate current price: $($AlgoData.$Algorithm.estimate_current / $Divisor))"
                        }
                    }
                    $AlgoData.$Algorithm | Add-Member PlusPrice $PlusPrice -Force
                }
                Remove-Variable Algo, AlgorithmNorm, BasePrice, BestCurrency, CurrenciesArray, Currency, CurrentPoolObjects, DAGdata, GroupAvgSampleSize, GroupMedSampleSize, GroupAvgSampleSizeHalf, GroupMedSampleSizeHalf, GroupMedSampleSizeNoPercent, LastPrice, Penalty, PenaltySampleSizeHalf, PenaltySampleSizeNoPercent, PlusPrice, PoolName, SampleSizeHalfts, SampleSizets, Stat, StatName -ErrorAction Ignore

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
            $PoolObjects = @($PoolObjects.where({ $_.Date -ge $Timestamp.AddMinutes( - ($PoolConfig.BrainConfig.SampleSizeMinutes + 10)) }))
        }
        catch { 
            Write-Message -Level Error "Error in file '$(($_.InvocationInfo.ScriptName -split "\\" | Select-Object -Last 2) -join "\")' line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting core..."
            "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Brain_$($Name)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
            $_.Exception | Format-List -Force >> "Logs\Brain_$($Name)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
            $_.InvocationInfo | Format-List -Force >> "Logs\Brain_$($Name)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
        }
        Remove-Variable AlgoData, CurrenciesData -ErrorAction Ignore

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

$Session.Brains.Remove($Name)
$Session.BrainData.Remove($Name)