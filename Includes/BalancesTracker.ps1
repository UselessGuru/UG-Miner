<#
Copyright (c) 2018-2025 UselessGuru
BalancesTrackerJob.ps1 Written by MrPlusGH https://github.com/MrPlusGH & UseLessGuru

UG-Miner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

UG-Miner is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        UG-Miner
File:           \Includes\BalancesTracker.ps1
Version:        6.7.0
Version date:   2025/11/23
#>

using module .\Include.psm1

do { 
    (Get-Process -Id $PID).PriorityClass = "BelowNormal"

    $Session.BalancesTrackerRunning = $true

    $Session.BalancesData = @()
    $Earnings = @()

    # Get pools last earnings
    $Session.PoolsLastEarnings = if (Test-Path -LiteralPath ".\Data\PoolsLastEarnings.json" -PathType Leaf) { [System.IO.File]::ReadAllLines("$PWD\Data\PoolsLastEarnings.json") | ConvertFrom-Json | Get-SortedObject }
    if (-not $Session.PoolsLastEarnings.Keys) { $Session.PoolsLastEarnings = @{ } }

    # Read existing earnings data, use data from last file
    foreach ($Filename in (Get-ChildItem ".\Data\BalancesTrackerData*.json" | Sort-Object -Descending)) { 
        $Session.BalancesData = ([System.IO.File]::ReadAllLines($Filename) | ConvertFrom-Json)
        if ($Session.BalancesData.Count -gt ($Session.PoolData.Count / 2)) { break }
    }

    if ($Session.BalancesData -isnot [Array]) { $Session.BalancesData = @() }
    $Session.BalancesData.ForEach({ $_.DateTime = [DateTime]$_.DateTime })

    # Read existing earnings data, use data from last file
    foreach ($Filename in (Get-ChildItem ".\Data\DailyEarnings*.csv" | Sort-Object -Descending)) { 
        $Earnings = @(Import-Csv $FileName -ErrorAction Ignore)
        if ($Earnings.Count -gt $Session.PoolData.Count / 2) { break }
    }
    Remove-Variable FileName -ErrorAction Ignore

    $Balances = [Ordered]@{ } # as case insensitive hash table

    $BalanceObjects = @()

    if ($Now.Date -ne [DateTime]::Today) { 
        # Keep a copy on start & at date change
        if (Test-Path -LiteralPath ".\Data\BalancesTrackerData.json" -PathType Leaf) { Copy-Item -Path ".\Data\BalancesTrackerData.json" -Destination ".\Data\BalancesTrackerData_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").json" -ErrorAction Ignore }
        if (Test-Path -LiteralPath ".\Data\DailyEarnings.csv" -PathType Leaf) { Copy-Item -Path ".\Data\DailyEarnings.csv" -Destination ".\Data\DailyEarnings_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").csv" -ErrorAction Ignore }
        # Keep only the last 3 logs
        Get-ChildItem ".\Data\BalancesTrackerData_*.json" | Sort-Object | Select-Object -SkipLast 3 | Remove-Item -Force -Recurse -ErrorAction Ignore
        Get-ChildItem ".\Data\DailyEarnings_*.csv" | Sort-Object | Select-Object -SkipLast 3 | Remove-Item -Force -Recurse -ErrorAction Ignore
    }

    $Now = [DateTime]::Now

    # Get pools to track
    $PoolsToTrack = @((Get-ChildItem -File ".\Balances\*.ps1" -ErrorAction Ignore).BaseName.Where({ $_ -notin (Get-PoolBaseName $Session.Config.BalancesTrackerExcludePools) }))

    # Check internet connection
    $NetworkInterface = (Get-NetConnectionProfile).Where({ $_.IPv4Connectivity -eq "Internet" }).InterfaceIndex
    $Session.MyIPaddress = if ($NetworkInterface) { (Get-NetIPAddress -InterfaceIndex $NetworkInterface -AddressFamily IPV4).IPAddress } else { $null }
    Remove-Variable NetworkInterface

    if ($Session.MyIPaddress) { 
        # Fetch balances data from pools
        if ($PoolsToTrack) { 
            Write-Message -Level Info "Balances tracker is requesting data from pool$(If ($PoolsToTrack.Count -gt 1) { "s" }) $($PoolsToTrack -join ", " -replace ",([^,]*)$", " &`$1")..."
            if ($PoolsToTrack -contains "MiningDutch") { $PoolsToTrack = [String[]]($PoolsToTrack -notmatch "MiningDutch"); $PoolsToTrack += "MiningDutch" } # MiningDutch takes a very long time, get data last
            $PoolsToTrack.ForEach(
                { 
                    try { 
                        Write-Message -Level Debug "Balances tracker for pool '$_': Start building balances objects"
                        $BalanceObjects += @(
                            & ".\Balances\$($_).ps1"
                        )
                        Write-Message -Level Debug "Balances tracker for pool '$_': End building balances objects"
                    }
                    catch {
                        Write-Message -Level Debug "Balances tracker for pool '$_': Error building balances objects"
                    }
                }
            )

            # Only keep non excluded balances
            $BalancesTrackerExcludePool = @(Get-PoolBaseName $Session.Config.BalancesTrackerExcludePool)
            $BalanceObjects = @(@($BalanceObjects) + @($Session.BalancesData))
            $BalanceObjects = $BalanceObjects.Where({ $_.Wallet -and $_.Pool -notin $BalancesTrackerExcludePool })
            Remove-Variable BalancesTrackerExcludePool

            # Group balances by pool, currency and wallet
            $BalanceObjectGroups = $BalanceObjects | Group-Object -Property Pool, Currency, Wallet

            # Keep most recent balance objects
            $BalanceObjects = $BalanceObjectGroups.ForEach({ $_.Group | Sort-Object -Property DateTime -Bottom 1 })
            Remove-Variable BalanceObjectGroups

            # Keep empty balances for 7 days
            $BalanceObjects = $BalanceObjects.Where({ $_.Unpaid -gt 0 -or $_.Balance -gt 0 -or $_.DateTime -gt $Now.AddDays(-7) })

            $Session.BalancesCurrencies = @(@($Session.BalancesCurrencies) + @($BalanceObjects.Currency) | Sort-Object -Unique)

            # Read exchange rates every at least 15 minutes
            if ((Compare-Object $Session.AllCurrencies $Session.BalancesCurrencies).where({ $_.SideIndicator -eq "=>"}) -or $Session.RatesUpdated -lt $Now.ToUniversalTime().AddMinutes(-15)) { Get-Rate }

            foreach ($BalanceObject in $BalanceObjects) { 
                $BalanceDataObjects = @($Session.BalancesData.Where({ $_.Pool -eq $BalanceObject.Pool -and $_.Currency -eq $BalanceObject.Currency -and $_.Wallet -eq $BalanceObject.Wallet }) | Sort-Object -Property DateTime)

                # Get threshold currency and value
                $PayoutThreshold = $BalanceObject.PayoutThreshold
                $PayoutThresholdCurrency = $BalanceObject.Currency

                if (-not $PayoutThreshold) { $PayoutThreshold = ($Session.Config.Pools.($BalanceObject.Pool).Variant.($BalanceObject.Pool).PayoutThreshold.$PayoutThresholdCurrency) -as [Double] }
                if (-not $PayoutThreshold) { $PayoutThreshold = ($Session.Config.Pools.($BalanceObject.Pool).PayoutThreshold.$PayoutThresholdCurrency) -as [Double] }
                if (-not $PayoutThreshold) { $PayoutThreshold = ($Session.Config.Pools.($BalanceObject.Pool).PayoutThreshold."*".$PayoutThresholdCurrency) -as [Double] }
                if (-not $PayoutThreshold) { $PayoutThreshold = ($Session.Config.Pools.($BalanceObject.Pool).PayoutThreshold."*") -as [Double] }
                if (-not $PayoutThreshold) { 
                    if ($PayoutThresholdCurrency = [String]($Session.Config.Pools.($BalanceObject.Pool).PayoutThreshold."*".Keys)) { 
                        $PayoutThreshold = ($Session.Config.Pools.($BalanceObject.Pool).PayoutThreshold."*".$PayoutThresholdCurrency) -as [Double]
                    }
                }

                if (-not $PayoutThreshold -and $BalanceObject.Currency -eq "BTC") { 
                    $PayoutThresholdCurrency = "mBTC"
                    if (-not $PayoutThreshold) { $PayoutThreshold = ($Session.Config.Pools.($BalanceObject.Pool).Variant.($BalanceObject.Pool).PayoutThreshold.$PayoutThresholdCurrency) -as [Double] }
                    if (-not $PayoutThreshold) { $PayoutThreshold = ($Session.Config.Pools.($BalanceObject.Pool).PayoutThreshold.$PayoutThresholdCurrency) -as [Double] }
                    if (-not $PayoutThreshold) { $PayoutThreshold = ($Session.Config.Pools.($BalanceObject.Pool).PayoutThreshold."*".$PayoutThresholdCurrency) -as [Double] }
                    if (-not $PayoutThreshold) { $PayoutThreshold = ($Session.Config.Pools.($BalanceObject.Pool).PayoutThreshold."*") -as [Double] }
                    if (-not $PayoutThreshold) { 
                        if ($PayoutThresholdCurrency = $Session.Config.Pools.($BalanceObject.Pool).PayoutThreshold."*".Keys[0]) { 
                            $PayoutThreshold = ($Session.Config.Pools.($BalanceObject.Pool).PayoutThreshold."*".$PayoutThresholdCurrency) -as [Double]
                        }
                    }
                }

                if ($PayoutThresholdCurrency -eq "mBTC") { 
                    $PayoutThresholdCurrency = "BTC"
                    $PayoutThreshold /= 1000
                }

                $Growth1 = $Growth6 = $Growth24 = $Growth168 = $Growth720 = $GrowthToday = $AvgHourlyGrowth = $AvgDailyGrowth = $AvgWeeklyGrowth = $Delta = $Payout = $HiddenPending = [Double]0

                if ($BalanceDataObjects.Count -eq 0) { 
                    $BalanceObject | Add-Member Delta ([Double]0)
                    $BalanceObject | Add-Member Earnings ([Double]($BalanceObject.Unpaid))
                    $BalanceObject | Add-Member Payout ([Double]0)
                    $BalanceObject | Add-Member Total ([Double]($BalanceObject.Unpaid))

                    $AvgHourlyGrowth = $AvgDailyGrowth = $AvgWeeklyGrowth = 0
                }
                else { 
                    if ($BalanceObject.Pool -like "NiceHash*") { 
                        if ($BalanceObject.Withdrawal -gt 0) { 
                            # NiceHash temporarily reduces 'Balance' value before paying out
                            $BalanceObject.Balance += $BalanceObject.Withdrawal
                            $Payout = 0
                        }
                        elseif (($BalanceDataObjects[-1]).Withdrawal -gt 0 -and $BalanceObject.Withdrawal -eq 0) { 
                            # Payout occurred
                            $Payout = ($BalanceDataObjects[-1]).Withdrawal
                        }
                        elseif ($BalanceObject.Withdrawal -eq 0) { 
                            # NiceHash temporarily hides some 'pending' value while processing payouts
                            if ($BalanceObject.Pending -lt ($BalanceDataObjects[-1]).Pending) { 
                                $HiddenPending = ($BalanceDataObjects[-1]).Pending - $BalanceObject.Pending
                                $BalanceObject | Add-Member HiddenPending ([Double]$HiddenPending)
                            }
                            # When payouts are processed the hidden pending value gets added to the balance
                            if (($BalanceDataObjects[-1]).HiddenPending -gt 0) { 
                                if ($BalanceObject.Balance -eq (($BalanceDataObjects[-1]).Balance)) { 
                                    # Payout processing complete
                                    $HiddenPending *= -1
                                }
                                else { 
                                    # Still processing payouts
                                    $HiddenPending = ($BalanceDataObjects[-1]).HiddenPending
                                    $BalanceObject | Add-Member HiddenPending ([Double]$HiddenPending)
                                }
                            }
                            $Payout = if (($BalanceDataObjects[-1]).Unpaid -gt $BalanceObject.Unpaid) { ($BalanceDataObjects[-1]).Unpaid - $BalanceObject.Unpaid } else { 0 }
                        }
                        $Delta = $BalanceObject.Unpaid - ($BalanceDataObjects[-1]).Unpaid
                        $BalanceObject | Add-Member Earnings ([Double]($BalanceDataObjects[-1]).Earnings + $Delta + $HiddenPending + $Payout) -Force
                    }
                    elseif ($BalanceObject.Pool -eq "MiningPoolHub") { 
                        # MiningHubPool never reduces earnings
                        $Delta = $BalanceObject.Unpaid - ($BalanceDataObjects[-1]).Unpaid
                        if ($Delta -lt 0) { 
                            # Payout occured
                            $Payout = - $Delta
                            $BalanceObject | Add-Member Earnings ([Double]($BalanceDataObjects[-1]).Earnings) -Force
                        }
                        else { 
                            $Payout = 0
                            $BalanceObject | Add-Member Earnings ([Double]($BalanceDataObjects[-1]).Earnings + $Delta) -Force
                        }
                    }
                    else { 
                        # HashCryptos, HiveON, MiningDutch, ZPool
                        $Delta = $BalanceObject.Unpaid - ($BalanceDataObjects[-1]).Unpaid
                        # Current 'Unpaid' is smaller
                        if ($Delta -lt 0) { 
                            if (-$Delta -gt $PayoutThreshold * 0.5) { 
                                # Payout occured (delta -gt 50% of payout limit)
                                $Payout = - $Delta
                            }
                            else { 
                                # Pool reduced earnings
                                $Payout = $Delta = 0
                            }
                            $BalanceObject | Add-Member Earnings ([Double]($BalanceDataObjects[-1]).Earnings) -Force
                        }
                        else { 
                            $Payout = 0
                            $BalanceObject | Add-Member Earnings ([Double]($BalanceDataObjects[-1]).Earnings + $Delta) -Force
                        }
                    }
                    $BalanceObject | Add-Member Payout ([Double]$Payout) -Force
                    $BalanceObject | Add-Member Paid ([Double](($BalanceDataObjects.Paid | Measure-Object -Maximum).Maximum + $Payout)) -Force
                    $BalanceObject | Add-Member Delta ([Double]$Delta) -Force

                    if ((($Now - $BalanceDataObjects[0].DateTime).TotalHours) -lt 1) { 
                        # Only calculate if current balance data
                        if ($BalanceObject.DateTime -gt $Now.AddMinutes(-1)) { 
                            $Growth1 = $Growth6 = $Growth24 = $Growth168 = $Growth720 = [Double]($BalanceObject.Earnings - $BalanceDataObjects[0].Earnings)
                        }
                    }
                    else { 
                        # Only calculate if current balance data
                        if ($BalanceDataObjects.Where({ $_.DateTime -ge $Now.AddHours(-1) })) { $Growth1 = [Double]($BalanceObject.Earnings - ($BalanceDataObjects.Where({ $_.DateTime -ge $Now.AddHours(-1) }) | Sort-Object -Property DateTime -Top 1).Earnings) }
                        if ($BalanceDataObjects.Where({ $_.DateTime -ge $Now.AddHours(-6) })) { $Growth6 = [Double]($BalanceObject.Earnings - ($BalanceDataObjects.Where({ $_.DateTime -ge $Now.AddHours(-6) }) | Sort-Object -Property DateTime -Top 1).Earnings) }
                        if ($BalanceDataObjects.Where({ $_.DateTime -ge $Now.AddHours(-24) })) { $Growth24 = [Double]($BalanceObject.Earnings - ($BalanceDataObjects.Where({ $_.DateTime -ge $Now.AddHours(-24) }) | Sort-Object -Property DateTime -Top 1).Earnings) }
                        if ($BalanceDataObjects.Where({ $_.DateTime -ge $Now.AddHours(-168) })) { $Growth168 = [Double]($BalanceObject.Earnings - ($BalanceDataObjects.Where({ $_.DateTime -ge $Now.AddHours(-168) }) | Sort-Object -Property DateTime -Top 1).Earnings) }
                        if ($BalanceDataObjects.Where({ $_.DateTime -ge $Now.AddHours(-720) })) { $Growth720 = [Double]($BalanceObject.Earnings - ($BalanceDataObjects.Where({ $_.DateTime -ge $Now.AddHours(-720) }) | Sort-Object -Property DateTime -Top 1).Earnings) }
                    }

                    $AvgHourlyGrowth = if ($BalanceDataObjects.Where({ $_.DateTime -lt $Now.AddHours(-1) })) { [Double](($BalanceObject.Earnings - $BalanceDataObjects[0].Earnings) / ($Now - $BalanceDataObjects[0].DateTime).TotalHours) }    else { $Growth1 }
                    $AvgDailyGrowth = if ($BalanceDataObjects.Where({ $_.DateTime -lt $Now.AddDays(-1) })) { [Double](($BalanceObject.Earnings - $BalanceDataObjects[0].Earnings) / ($Now - $BalanceDataObjects[0].DateTime).TotalDays) }     else { $Growth24 }
                    $AvgWeeklyGrowth = if ($BalanceDataObjects.Where({ $_.DateTime -lt $Now.AddDays(-7) })) { [Double](($BalanceObject.Earnings - $BalanceDataObjects[0].Earnings) / ($Now - $BalanceDataObjects[0].DateTime).TotalDays * 7) } else { $Growth168 }

                    if ($BalanceDataObjects.Where({ $_.DateTime.Date -eq $Now.Date })) { 
                        $GrowthToday = [Double]($BalanceObject.Earnings - ($BalanceDataObjects.Where({ $_.DateTime.Date -eq $Now.Date }) | Sort-Object -Property DateTime -Top 1).Earnings)
                        if ($GrowthToday -lt 0) { $GrowthToday = 0 } # to avoid negative numbers
                    }
                }

                $BalanceDataObjects += $BalanceObject
                $Session.BalancesData += $BalanceObject

                try { 
                    $EarningsObject = [PSCustomObject]@{ 
                        Pool                    = $BalanceObject.Pool
                        Wallet                  = $BalanceObject.Wallet
                        Currency                = $BalanceObject.Currency
                        Start                   = $BalanceDataObjects[0].DateTime
                        LastUpdated             = $BalanceObject.DateTime
                        Pending                 = [Double]$BalanceObject.Pending
                        Balance                 = [Double]$BalanceObject.Balance
                        Unpaid                  = [Double]$BalanceObject.Unpaid
                        Earnings                = [Double]$BalanceObject.Earnings
                        Delta                   = [Double]$BalanceObject.Delta
                        Growth1                 = [Double]$Growth1
                        Growth6                 = [Double]$Growth6
                        Growth24                = [Double]$Growth24
                        Growth168               = [Double]$Growth168
                        Growth720               = [Double]$Growth720
                        GrowthToday             = [Double]$GrowthToday
                        AvgHourlyGrowth         = [Double]$AvgHourlyGrowth
                        AvgDailyGrowth          = [Double]$AvgDailyGrowth
                        AvgWeeklyGrowth         = [Double]$AvgWeeklyGrowth
                        ProjectedEndDayGrowth   = if (($Now - $BalanceDataObjects[0].DateTime).TotalHours -ge 1) { [Double]($AvgHourlyGrowth * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $Now).Hours) } else { [Double]($Growth1 * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $Now).Hours) }
                        ProjectedPayDate        = if ($PayoutThreshold -and $Session.Rates.$PayoutThresholdCurrency.($BalanceObject.Currency)) { if ([Double]$BalanceObject.Balance -lt $PayoutThreshold * $Session.Rates.$PayoutThresholdCurrency.($BalanceObject.Currency)) { if (($AvgDailyGrowth, $Growth24 | Measure-Object -Maximum).Maximum -gt 1E-7) { [DateTime]$Now.AddDays(($PayoutThreshold * $Session.Rates.$PayoutThresholdCurrency.($BalanceObject.Currency) - $BalanceObject.Balance) / (($AvgDailyGrowth, $Growth24) | Measure-Object -Maximum).Maximum) } else { "Unknown" } } else { if ($BalanceObject.NextPayout) { $BalanceObject.NextPayout } else { "Next pool payout" } } } else { "Unknown" }
                        TrustLevel              = [Double]((($Now - $BalanceDataObjects[0].DateTime).TotalHours / 168), 1 | Measure-Object -Minimum).Minimum
                        TotalHours              = [Double]($Now - $BalanceDataObjects[0].DateTime).TotalHours
                        PayoutThreshold         = [Double]$PayoutThreshold
                        PayoutThresholdCurrency = $PayoutThresholdCurrency
                        Payout                  = [Double]$BalanceObject.Payout
                        Uri                     = $BalanceObject.Url
                        LastEarnings            = if ($Growth24 -gt 0) { $BalanceObject.DateTime } else { $BalanceDataObjects[0].DateTime }
                    }
                    $Balances."$($BalanceObject.Pool) ($($BalanceObject.Currency):$($BalanceObject.Wallet))" = $EarningsObject
                }
                catch { 
                    Start-Sleep -Seconds 0
                }
                if ($Session.Config.BalancesTrackerLog) { 
                    $EarningsObject | Export-Csv -NoTypeInformation -Append ".\Logs\BalancesTrackerLog.csv" -Force -ErrorAction Ignore
                }

                $PoolTodaysEarnings = $Earnings.Where({ $_.Pool -eq $BalanceObject.Pool -and $_.Currency -eq $BalanceObject.Currency -and $_.Wallet -eq $BalanceObject.Wallet })[-1]

                if ([String]$PoolTodaysEarnings.Date -eq $Now.ToString("yyyy-MM-dd")) { 
                    $PoolTodaysEarnings.DailyEarnings = [Double]$GrowthToday
                    $PoolTodaysEarnings.EndTime = $Now.ToString("T")
                    $PoolTodaysEarnings.EndValue = [Double]$BalanceObject.Earnings
                    $PoolTodaysEarnings.Balance = [Double]$BalanceObject.Balance
                    $PoolTodaysEarnings.Unpaid = [Double]$BalanceObject.Unpaid
                    $PoolTodaysEarnings.Payout = [Double]$PoolTodaysEarnings.Payout + [Double]$BalanceObject.Payout
                }
                else { 
                    $Earnings += [PSCustomObject]@{ 
                        Date          = $Now.ToString("yyyy-MM-dd")
                        Pool          = $EarningsObject.Pool
                        Currency      = $EarningsObject.Currency
                        Wallet        = $BalanceObject.Wallet
                        DailyEarnings = [Double]$GrowthToday
                        StartTime     = $Now.ToString("T")
                        StartValue    = if ($PoolTodaysEarnings) { [Double]$PoolTodaysEarnings.EndValue } else { [Double]$EarningsObject.Earnings }
                        EndTime       = $Now.ToString("T")
                        EndValue      = [Double]$EarningsObject.Earnings
                        Balance       = [Double]$EarningsObject.Balance
                        Pending       = [Double]$EarningsObject.Pending
                        Unpaid        = [Double]$EarningsObject.Unpaid
                        Payout        = [Double]0
                    }
                }
            }
        }

        # Always keep pools sorted, even when new pools were added
        $Session.Balances = [Ordered]@{ } # as case insensitive hash table
        ($Balances.psbase.Keys.Where({ $Balances.$_.Pool -in $PoolsToTrack }) | Sort-Object).foreach(
            { 
                $Session.Balances.Remove($_)
                $Session.Balances.$_ = $Balances.$_
                $Session.PoolsLastEarnings.($_ -replace " \(.+") = ($Balances.$_.LastEarnings | Measure-Object -Maximum).Maximum
            }
        )
        $Session.BalancesCurrencies = @($Session.Balances.psBase.Keys.ForEach({ $Session.Balances.$_.Currency }) | Sort-Object -Unique)

        $Session.PoolsLastEarnings = $Session.PoolsLastEarnings | Get-SortedObject
        $Session.PoolsLastEarnings | ConvertTo-Json | Out-File -LiteralPath ".\Data\PoolsLastEarnings.json" -Force -ErrorAction Ignore

        # Build chart data (used in GUI) for last 30 days
        $PoolChartData = [PSCustomObject]@{ }
        $ChartData = $Earnings.Where({ $_.Pool -in $PoolsToTrack }) | Sort-Object -Property Date | Group-Object -Property Date | Select-Object -Last 30 # days

        # One dataset per pool
        (($ChartData.Group.Where({ $_.DailyEarnings -gt 0 })).Pool | Sort-Object -Unique).foreach(
            { 
                $PoolChartData | Add-Member @{ $_ = [Double[]]@() }
            }
        )

        # Fill dataset
        foreach ($PoolEarnings in $ChartData) { 
            $PoolChartData.PSObject.Properties.Name.ForEach(
                { 
                    $PoolChartData.$_ += (($PoolEarnings.Group | Where-Object Pool -EQ $_).foreach({ [Double]$_.DailyEarnings * $Session.Rates.($_.Currency).BTC }) | Measure-Object -Sum).Sum
                }
            )
        }
        Remove-Variable PoolEarnings, PoolTodaysEarnings -ErrorAction Ignore

        $EarningsChartData = [PSCustomObject]@{ 
            Labels   = @(
                ($ChartData.Group.Date | Sort-Object -Unique).foreach(
                    { 
                        [DateTime]::parseexact($_, "yyyy-MM-dd", $null).ToShortDateString()
                    }
                )
            )
            # Use dates for x-axis label
            Earnings = $PoolChartData
        }
        Remove-Variable PoolChartData -ErrorAction Ignore

        $EarningsChartData | ConvertTo-Json | Out-File -LiteralPath ".\Cache\EarningsChartData.json" -Force -ErrorAction Ignore
        $Session.Remove("EarningsChartData")
        $Session.EarningsChartData = $EarningsChartData.PSObject.Copy()

        # Keep earnings for max. 1 year
        $OldestEarningsDate = [DateTime]::Now.AddYears(-1).ToString("yyyy-MM-dd")
        $Earnings = $Earnings.Where({ $_.Date -ge $OldestEarningsDate })
        Remove-Variable OldestEarningsDate

        # At least 31 days are needed for Growth720
        if ($Session.BalancesData.Count -gt 1) { 
            $Session.BalancesData = @(
                ($Session.BalancesData.Where({ $_.DateTime -ge $Now.AddDays(-31) }) | Group-Object -Property Pool, Currency).foreach(
                    { 
                        $Record = $null
                        ($_.Group | Sort-Object -Property DateTime).foreach(
                            { 
                                if ($_.DateTime -ge $Now.AddDays(-1)) { $_ } # Keep all records for 1 day
                                elseif ($_.DateTime -ge $Now.AddDays(-7) -and $_.Delta -gt 0) { $_ } # Keep all records of the last 7 days with delta
                                elseif ($_.DateTime.Date -ne $Record.DateTime.Date) { $Record = $_; $_ } # Keep the newest one per day
                            }
                        )
                    }
                )
            ) | Sort-Object -Property DateTime -Descending
        }

        try { 
            $Earnings | Export-Csv ".\Data\DailyEarnings.csv" -NoTypeInformation -Force
        }
        catch { 
            Write-Message -Level Warn "Balances tracker failed to save earnings data to '.\Data\DailyEarnings.csv' (should have $($Earnings.count) entries)."
        }

        if ($Session.BalancesData.Count -ge 1) { $Session.BalancesData | ConvertTo-Json | Out-File -LiteralPath ".\Data\BalancesTrackerData.json" -Force -ErrorAction Ignore }
        if ($Session.Balances.Count -ge 1) { $Session.Balances | ConvertTo-Json | Out-File -LiteralPath ".\Cache\Balances.json" -Force -ErrorAction Ignore }

        if ($PoolsToTrack.Count -gt 1) { 
            $Session.RefreshBalancesNeeded = $true
            $Session.BalancesUpdatedTimestamp = (Get-Date -Format "G")
            Write-Message -Level Info "Balances tracker updated data for pool$(If ($PoolsToTrack.Count -gt 1) { "s" }) $($PoolsToTrack -join ", " -replace ",([^,]*)$", " &`$1")."
        }
    }

    $Error.Clear()
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()

    # Sleep until next update (at least 5 minutes, maximum 60 minutes) or when no internet connection
    while (-not $Session.MyIPaddress -or [DateTime]::Now -le $Now.AddMinutes((60, (5, [Int]$Session.Config.BalancesTrackerPollInterval | Measure-Object -Maximum).Maximum | Measure-Object -Minimum ).Minimum)) { Start-Sleep -Seconds 5 }
} while ($true)