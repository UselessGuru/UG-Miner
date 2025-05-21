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
File:           \Brains\ZergPool.ps1
Version:        6.4.26
Version date:   2025/05/21
#>

using module ..\Includes\Include.psm1

# Start transcript log
If ($Config.Transcript) { Start-Transcript -Path ".\Debug\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)-Transcript_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log" }

# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$BrainName = (Get-Item $MyInvocation.MyCommand.Path).BaseName

$PoolObjects = @()
$APICallFails = 0
$Durations = [TimeSpan[]]@()
$PoolConfig = $Variables.PoolsConfig.$BrainName

$BrainDataFile = "$PWD\Data\BrainData_$BrainName.json"

While ($PoolConfig = $Config.PoolsConfig.$BrainName) { 

    $PoolVariant = [String]$Config.PoolName.Where({ $_ -like "$BrainName*" })
    $StartTime = [DateTime]::Now

    If ($Variables.MyIp) { 
        Try { 

            Write-Message -Level Debug "Brain '$BrainName': Start loop$(If ($Duration) { " (Previous loop duration: $Duration sec.)" })"
            Do { 
                Try { 
                    If (-not $AlgoData) { 
                        $AlgoData = Invoke-RestMethod -Uri "https://zergpool.com/api/status" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPItimeout
                        If ($AlgoData -like "<!DOCTYPE html>*") { $AlgoData = $null }
                    }
                    If (-not $CurrenciesData) { 
                        $CurrenciesData = Invoke-RestMethod -Uri "https://zergpool.com/api/currencies" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPItimeout
                        If ($CurrenciesData -like "<!DOCTYPE html>*") { $CurrenciesData = $null }
                    }
                    $APICallFails = 0
                }
                Catch { 
                    If ($APICallFails -lt $PoolConfig.PoolAPIAllowedFailureCount) { $APICallFails ++ }
                    Start-Sleep -Seconds ([Math]::max(60, ($APICallFails * 5 + $PoolConfig.PoolAPIretryInterval)))
                }
            } While (-not ($AlgoData -and $CurrenciesData) -and $APICallFails -lt $Config.PoolAPIallowedFailureCount)

            $Timestamp = [DateTime]::Now.ToUniversalTime()

            If ($AlgoData -and $CurrenciesData) { 
                $AlgoData.PSObject.Properties.Name.Where({ $AlgoData.$_.algo -eq "Token" -or $_ -like "*-*" }).ForEach({ $AlgoData.PSObject.Properties.Remove($_) })
                $AlgoData.PSObject.Properties.Name.Where({ -not $AlgoData.$_.algo }).ForEach(
                    { 
                        $AlgoData.$_ | Add-Member @{ algo = $AlgoData.$_.name }
                        $AlgoData.$_.PSObject.Properties.Remove("name")
                    }
                )

                # Change numeric string to numbers, some values are null
                $AlgoData = ($AlgoData | ConvertTo-Json) -replace ': "(\d+\.?\d*)"', ': $1' -replace '": null', '": 0' | ConvertFrom-Json
                $CurrenciesData = ($CurrenciesData | ConvertTo-Json) -replace ': "(\d+\.?\d*)"', ': $1' -replace '": null', '": 0' | ConvertFrom-Json

                # Add currency and convert to array for easy sorting
                $CurrenciesArray = [PSCustomObject[]]@()
                $CurrenciesData.PSObject.Properties.Name.Where({ $CurrenciesData.$_.algo -and $CurrenciesData.$_.name -notcontains "Hashtap" }).ForEach(
                    { 
                        $CurrenciesData.$_ | Add-Member Currency $(If ($CurrenciesData.$_.symbol) { $CurrenciesData.$_.symbol -replace '-.+$' } Else { $_ -replace '-.+$' })
                        $CurrenciesData.$_ | Add-Member CoinName ([String]$Variables.CoinNames[$CurrenciesData.$_.Currency]) -Force

                        $CurrenciesData.$_.PSObject.Properties.Remove("symbol")
                        $CurrenciesData.$_.PSObject.Properties.Remove("name")
                        $CurrenciesArray += $CurrenciesData.$_

                        Try { 
                            # Add coin name
                            [Void](Add-CoinName -Algorithm $CurrenciesData.$_.algo -Currency $CurrenciesData.$_.Currency -CoinName $CurrenciesData.$_.CoinName)
                        }
                        Catch { }
                    }
                )

                # Get best currency
                ($CurrenciesArray | Group-Object Algo).ForEach(
                    { 
                        If ($AlgoData.($_.name)) { 
                            $BestCurrency = ($_.Group | Sort-Object -Property estimate -Descending -Top 1)
                            $AlgoData.($_.name) | Add-Member Currency $BestCurrency.currency -Force
                            $AlgoData.($_.name) | Add-Member CoinName $BestCurrency.coinname -Force
                        }
                    }
                )

                ForEach ($Algorithm in $AlgoData.PSObject.Properties.Name) { 
                    $AlgorithmNorm = Get-Algorithm $Algorithm
                    $Currency = [String]$AlgoData.$Algorithm.Currency
                    If ($AlgoData.$Algorithm.actual_last24h_shared) { $AlgoData.$Algorithm.actual_last24h_shared /= 1000 }
                    $BasePrice = If ($AlgoData.$Algorithm.actual_last24h_shared) { $AlgoData.$Algorithm.actual_last24h_shared } Else { $AlgoData.$Algorithm.estimate_last24h }

                    # Keep DAG data up to date
                    If ($AlgorithmNorm -match $Variables.RegexAlgoHasDAG -and $CurrenciesData.$Currency.height -gt $Variables.DAGdata.Currency.$Currency.BlockHeight) { 
                        $DAGdata = (Get-DAGData -BlockHeight $CurrenciesData.$Currency.height -Currency $Currency -EpochReserve 2)
                        $DAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                        $DAGdata | Add-Member Url "https://zergpool.com/api/currencies"
                        $Variables.DAGdata.Currency | Add-Member $Currency $DAGdata -Force
                        $Variables.DAGdata.Updated | Add-Member "https://zergpool.com/api/currencies" ([DateTime]::Now).ToUniversalTime() -Force
                    }

                    $AlgoData.$Algorithm | Add-Member Fees $Config.PoolsConfig.$BrainName.DefaultFee -Force
                    $AlgoData.$Algorithm | Add-Member Updated $Timestamp -Force

                    # Reset history when stat file got removed
                    If ($PoolVariant -like "*Plus") { 
                        $StatName = If ($Currency) { "$($PoolVariant)_$($AlgorithmNorm)-$($Currency)_Profit" } Else { "$($PoolVariant)_$($AlgorithmNorm)_Profit" }
                        If (-not ($Stat = Get-Stat -Name $StatName) -and $PoolObjects.Where({ $_.Name -eq $PoolName })) { 
                            $PoolObjects = $PoolObjects.Where({ $_.Name -ne $Algorithm })
                            Write-Message -Level Debug "Pool brain '$BrainName': PlusPrice history cleared for $($StatName -replace '_Profit')"
                        }
                    }

                    $PoolObjects += [PSCustomObject]@{ 
                        actual_last24h      = $BasePrice
                        currency            = $Currency
                        Date                = $Timestamp
                        estimate_current    = $AlgoData.$Algorithm.estimate_current
                        estimate_last24h    = $AlgoData.$Algorithm.estimate_last24h
                        Last24hDrift        = $AlgoData.$Algorithm.estimate_current - $BasePrice
                        Last24hDriftPercent = If ($BasePrice -gt 0) { ($AlgoData.$Algorithm.estimate_current - $BasePrice) / $BasePrice } Else { 0 }
                        Last24hDriftSign    = If ($AlgoData.$Algorithm.estimate_current -ge $BasePrice) { "Up" } Else { "Down" }
                        Name                = $Algorithm
                    }
                }

                # Created here for performance optimization, minimize # of lookups
                $CurrentPoolObjects = $PoolObjects.Where({ $_.Date -eq $Timestamp })
                $SampleSizets = New-TimeSpan -Minutes $PoolConfig.BrainConfig.SampleSizeMinutes
                $SampleSizeHalfts = New-TimeSpan -Minutes ($PoolConfig.BrainConfig.SampleSizeMinutes / 2)
                $GroupAvgSampleSize = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
                $GroupMedSampleSize = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
                $GroupAvgSampleSizeHalf = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizeHalfts) }) | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
                $GroupMedSampleSizeHalf = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizeHalfts) }) | Group-Object Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
                $GroupMedSampleSizeNoPercent = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDrift } }

                ForEach ($Algorithm in ($PoolObjects.Name | Select-Object -Unique).Where({ $AlgoData.PSObject.Properties.Name -contains $_ })) { 
                    $PenaltySampleSizeHalf = ((($GroupAvgSampleSizeHalf.Where({ $_.Name -eq $Algorithm + ", Up" })).Count - ($GroupAvgSampleSizeHalf.Where({ $_.Name -eq $Algorithm + ", Down" })).Count) / (($GroupMedSampleSizeHalf.Where({ $_.Name -eq $Algorithm })).Count)) * [Math]::abs(($GroupMedSampleSizeHalf.Where({ $_.Name -eq $Algorithm })).Median)
                    $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize.Where({ $_.Name -eq $Algorithm + ", Up" })).Count - ($GroupAvgSampleSize.Where({ $_.Name -eq $Algorithm + ", Down" })).Count) / (($GroupMedSampleSize.Where({ $_.Name -eq $Algorithm })).Count)) * [Math]::abs(($GroupMedSampleSizeNoPercent.Where({ $_.Name -eq $Algorithm })).Median)
                    $Penalty = ($PenaltySampleSizeHalf * $PoolConfig.BrainConfig.SampleHalfPower + $PenaltySampleSizeNoPercent) / ($PoolConfig.BrainConfig.SampleHalfPower + 1)
                    $CurPoolObject = $CurrentPoolObjects.Where({ $_.Name -eq $Algorithm })
                    $Currency = $CurPoolObject.currency
                    $LastPrice = [Double]$CurPoolObject.estimate_current
                    $PlusPrice = [Math]::max(0, [Double]($LastPrice + $Penalty))

                    $StatName = If ($Currency) { "$($PoolVariant)_$(Get-Algorithm $Algorithm)-$($Currency)_Profit" } Else { "$($PoolVariant)_$(Get-Algorithm $Algorithm)_Profit" }
                    # Reset history if current estimate is not within +/- 1000% of 24hr stat price
                    If ($Stat = Get-Stat -Name $StatName) { 
                        $Divisor = $PoolConfig.Variant."$PoolVariant".DivisorMultiplier * $AlgoData.$Algorithm.mbtc_mh_factor
                        If ($Stat.Day -and $LastPrice -gt 0 -and ($AlgoData.$Algorithm.estimate_current / $Divisor -lt $Stat.Day / 10 -or $AlgoData.$Algorithm.estimate_current / $Divisor -gt $Stat.Day * 10)) { 
                            [Void](Remove-Stat -Name $StatName)
                            $PoolObjects = $PoolObjects.Where({ $_.Name -ne $Algorithm })
                            $PlusPrice = $LastPrice
                            Write-Message -Level Debug "Pool brain '$BrainName': PlusPrice history cleared for $($StatName -replace '_Profit') (stat day price: $($Stat.Day) vs. estimate current price: $($AlgoData.$Algorithm.estimate_current / $Divisor))"
                        }
                    }
                    $AlgoData.$Algorithm | Add-Member PlusPrice $PlusPrice -Force
                }
                Remove-Variable Algo, AlgorithmNorm, BasePrice, CurPoolObject, Currency, CurrentPoolObjects, DAGdata, GroupAvgSampleSize, GroupMedSampleSize, GroupAvgSampleSizeHalf, GroupMedSampleSizeHalf, GroupMedSampleSizeNoPercent, LastPrice, Penalty, PenaltySampleSizeHalf, PenaltySampleSizeNoPercent, PlusPrice, SampleSizeHalfts, SampleSizets, Stat, StatName -ErrorAction Ignore

                If ($PoolConfig.BrainConfig.UseTransferFile -or $Config.PoolsConfig.$BrainName.BrainDebug) { 
                    ($AlgoData | ConvertTo-Json).replace("NaN", 0) | Out-File -LiteralPath $BrainDataFile -Force -ErrorAction Ignore
                }
            }
            Else {
                $AlgoData = [PSCustomObject]@{ }
            }

            $Variables.BrainData.$BrainName = $AlgoData
            $Variables.Brains.$BrainName | Add-Member "Updated" $Timestamp -Force

            # Limit to only sample size + 10 minutes history
            $PoolObjects = @($PoolObjects.Where({ $_.Date -ge $Timestamp.AddMinutes( - ($PoolConfig.BrainConfig.SampleSizeMinutes + 10)) }))
        }
        Catch { 
            Write-Message -Level Error "Error in file '$(($_.InvocationInfo.ScriptName -split "\\" | Select-Object -Last 2) -join "\")' line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting core..."
            "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Brain_$($BrainName)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
            $_.Exception | Format-List -Force >> "Logs\Brain_$($BrainName)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
            $_.InvocationInfo | Format-List -Force >> "Logs\Brain_$($BrainName)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
        }
        Remove-Variable AlgoData -ErrorAction Ignore

        $Duration = ([DateTime]::Now - $StartTime).TotalSeconds
        $Durations += ($Duration, $Variables.Interval | Measure-Object -Minimum).Minimum
        $Durations = @($Durations | Select-Object -Last 20)
        $DurationsAvg = ($Durations | Measure-Object -Average).Average

        Write-Message -Level Debug "Brain '$BrainName': End loop (Duration $Duration sec. / Avg. loop duration: $DurationsAvg sec.); Price history $($PoolObjects.Count) objects; found $($Variables.BrainData.$BrainName.PSObject.Properties.Name.Count) valid pools."

        $Error.Clear()
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()
    }

    While (-not $Variables.MyIP -or $Timestamp -ge $Variables.PoolDataCollectedTimeStamp -or ($Variables.EndCycleTime -and [DateTime]::Now.ToUniversalTime().AddSeconds($DurationsAvg + 3) -le $Variables.EndCycleTime -and [DateTime]::Now.ToUniversalTime() -lt $Variables.EndCycleTime)) { 
        Start-Sleep -Seconds 1
    }
}

$Variables.Brains.Remove($BrainName)
$Variables.BrainData.Remove($BrainName)