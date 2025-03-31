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
Version:        6.4.21
Version date:   2025/03/31
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

$Headers = @{ "Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8";"Cache-Control"="no-cache" }
$Useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

While ($PoolConfig = $Config.PoolsConfig.$BrainName) { 

    $PoolVariant = $Config.PoolName.Where({ $_ -like "$BrainName*" })
    $StartTime = [DateTime]::Now

    Try { 

        Write-Message -Level Debug "Brain '$BrainName': Start loop$(If ($Duration) { " (Previous loop duration: $Duration sec.)" })"

        
        Do { 
            Try { 
                If (-not $AlgoData) { 
                    $AlgoData = Invoke-RestMethod -Uri "https://www.mining-dutch.nl/api/status" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPItimeout
                    If ($AlgoData -like "<!DOCTYPE html>*") { $AlgoData = $null }
                }
                If (-not $TotalStats) { 
                    $TotalStats = Invoke-RestMethod -Uri "https://www.mining-dutch.nl/api/v1/public/pooldata/?method=totalstats" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPItimeout
                    If ($TotalStats -like "<!DOCTYPE html>*") { $AlgTotalStatsoData = $null }
                }
                $APICallFails = 0
            }
            Catch { 
                If ($APICallFails -lt $PoolConfig.PoolAPIAllowedFailureCount) { $APICallFails ++ }
                Start-Sleep -Seconds ([Math]::max(60, ($APICallFails * 5 + $PoolConfig.PoolAPIretryInterval)))
            }
        } While (-not ($AlgoData -and $TotalStats) -and $APICallFails -lt $Config.PoolAPIallowedFailureCount)

        ($AlgoData.PSObject.Properties.Name).Where({ $TotalStats.result.algorithm -notcontains $_ }).ForEach({ $AlgoData.PSObject.Properties.Remove($_) })
        $Timestamp = [DateTime]::Now.ToUniversalTime()

        If ($AlgoData -and $TotalStats) { 
            # Change numeric string to numbers, some values are null
            $AlgoData = ($AlgoData | ConvertTo-Json) -replace ': "(\d+\.?\d*)"', ': $1' -replace '": null', '": 0' | ConvertFrom-Json
            $TotalStats = ($TotalStats | ConvertTo-Json) -replace ': "(\d+\.?\d*)"', ': $1' -replace '": null', '": 0' | ConvertFrom-Json

            ForEach ($Algorithm in $AlgoData.PSObject.Properties.Name) { 
                $AlgorithmNorm = Get-Algorithm $Algo
                $BasePrice = If ($AlgoData.$Algorithm.actual_last24h) { $AlgoData.$Algorithm.actual_last24h } Else { $AlgoData.$Algorithm.estimate_last24h }

                # Temp fix, incorrect data in API
                If ($AlgorithmNorm -eq "Neoscrypt" -and $AlgoData.$Algorithm.mbtc_mh_factor -eq 1) { $AlgoData.$Algorithm.mbtc_mh_factor = 1000 }

                $AlgoData.$Algorithm | Add-Member Updated $Timestamp -Force
                If ($AlgoStats = $TotalStats.result.Where({ $_.Algorithm -eq $Algorithm })) { 
                    $AlgoData.$Algorithm | Add-Member hashrate_shared $AlgoStats.hashrate -Force
                    $AlgoData.$Algorithm | Add-Member hashrate_solo $AlgoStats.hashrate_solo -Force
                    $AlgoData.$Algorithm | Add-Member workers_shared $AlgoStats.workers -Force
                    $AlgoData.$Algorithm | Add-Member workers_solo $AlgoStats.workers_solo -Force
                }
                Remove-Variable AlgoStats

                # Reset history when stat file got removed
                If ($PoolVariant -like "*Plus") { 
                    $StatName = "$($PoolVariant)_$($AlgorithmNorm)_Profit"
                    If (-not ($Stat = Get-Stat -Name $StatName) -and $PoolObjects.Where({ $_.Name -eq $PoolName })) { 
                        $PoolObjects = $PoolObjects.Where({ $_.Name -ne $PoolName })
                        Write-Message -Level Debug "Pool brain '$BrainName': PlusPrice history cleared for $($StatName -replace '_Profit')"
                    }
                }

                $PoolObjects += [PSCustomObject]@{ 
                    actual_last24h      = $BasePrice
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
                $LastPrice = [Double]$CurrentPoolObjects.Where({ $_.Name -eq $Algorithm }).estimate_current
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
            Remove-Variable Algo, AlgorithmNorm, Baseprice, CurrentPoolObjects, GroupAvgSampleSize, GroupMedSampleSize, GroupAvgSampleSizeHalf, GroupMedSampleSizeHalf, GroupMedSampleSizeNoPercent, LastPrice, Penalty, PenaltySampleSizeHalf, PenaltySampleSizeNoPercent, PlusPrice, PoolName, SampleSizeHalfts, SampleSizets, Stat, StatName -ErrorAction Ignore

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
    Remove-Variable AlgoData, TotalStats -ErrorAction Ignore

    $Duration = ([DateTime]::Now - $StartTime).TotalSeconds
    $Durations += ($Duration, $Variables.Interval | Measure-Object -Minimum).Minimum
    $Durations = @($Durations | Select-Object -Last 20)
    $DurationsAvg = ($Durations | Measure-Object -Average).Average

    Write-Message -Level Debug "Brain '$BrainName': End loop (Duration $Duration sec. / Avg. loop duration: $DurationsAvg sec.); Price history $($PoolObjects.Count) objects; found $($Variables.BrainData.$BrainName.PSObject.Properties.Name.Count) valid pools."

    $Error.Clear()
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()

    While (-not $Variables.MyIP -or $Timestamp -ge $Variables.PoolDataCollectedTimeStamp -or ($Variables.EndCycleTime -and [DateTime]::Now.ToUniversalTime().AddSeconds($DurationsAvg + 3) -le $Variables.EndCycleTime -and [DateTime]::Now.ToUniversalTime() -lt $Variables.EndCycleTime)) { 
        Start-Sleep -Seconds 1
    }
}

$Variables.Brains.Remove($BrainName)
$Variables.BrainData.Remove($BrainName)