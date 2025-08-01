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
Version:        6.5.2
Version date:   2025/07/27
#>

using module .\Include.psm1

Do { 
    # Start transcript log
    If ($Config.Transcript) { Start-Transcript -Path ".\Debug\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)-Transcript_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log" -Append -Force }

    (Get-Process -Id $PID).PriorityClass = "BelowNormal"

    $Session.BalancesTrackerRunning = $true

    $Session.BalancesData = @()
    $Earnings = @()

    # Get pools last earnings
    $Session.PoolsLastEarnings = If (Test-Path -LiteralPath ".\Data\PoolsLastEarnings.json" -PathType Leaf) { [System.IO.File]::ReadAllLines("$PWD\Data\PoolsLastEarnings.json") | ConvertFrom-Json | Get-SortedObject }
    If (-not $Session.PoolsLastEarnings.Keys) { $Session.PoolsLastEarnings = @{ } }

    # Read existing earnings data, use data from last file
    ForEach ($Filename in (Get-ChildItem ".\Data\BalancesTrackerData*.json" | Sort-Object -Descending)) { 
        $Session.BalancesData = ([System.IO.File]::ReadAllLines($Filename) | ConvertFrom-Json)
        If ($Session.BalancesData.Count -gt ($Session.PoolData.Count / 2)) { Break }
    }

    If ($Session.BalancesData -isnot [Array]) { $Session.BalancesData = @() }
    $Session.BalancesData.ForEach({ $_.DateTime = [DateTime]$_.DateTime })

    # Read existing earnings data, use data from last file
    ForEach($Filename in (Get-ChildItem ".\Data\DailyEarnings*.csv" | Sort-Object -Descending)) { 
        $Earnings = @(Import-Csv $FileName -ErrorAction Ignore)
        If ($Earnings.Count -gt $Session.PoolData.Count / 2) { Break }
    }
    Remove-Variable FileName -ErrorAction Ignore

    $Balances = [Ordered]@{ } # as case insensitive hash table

    $BalanceObjects = @()

    If ($Now.Date -ne [DateTime]::Today) { 
        # Keep a copy on start & at date change
        If (Test-Path -LiteralPath ".\Data\BalancesTrackerData.json" -PathType Leaf) { Copy-Item -Path ".\Data\BalancesTrackerData.json" -Destination ".\Data\BalancesTrackerData_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").json" -ErrorAction Ignore }
        If (Test-Path -LiteralPath ".\Data\DailyEarnings.csv" -PathType Leaf) { Copy-Item -Path ".\Data\DailyEarnings.csv" -Destination ".\Data\DailyEarnings_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").csv" -ErrorAction Ignore }
        # Keep only the last 3 logs
        Get-ChildItem ".\Data\BalancesTrackerData_*.json" | Sort-Object | Select-Object -Skiplast 3 | Remove-Item -Force -Recurse -ErrorAction Ignore
        Get-ChildItem ".\Data\DailyEarnings_*.csv" | Sort-Object | Select-Object -Skiplast 3 | Remove-Item -Force -Recurse -ErrorAction Ignore
    }

    $Now = [DateTime]::Now

    # Get pools to track
    $PoolsToTrack = @((Get-ChildItem -File ".\Balances\*.ps1" -ErrorAction Ignore).BaseName.Where({ $_ -notin (Get-PoolBaseName $Config.BalancesTrackerExcludePools) }))

    # Check internet connection
    $NetworkInterface = (Get-NetConnectionProfile).Where({ $_.IPv4Connectivity -eq "Internet" }).InterfaceIndex
    $Session.MyIPaddress = If ($NetworkInterface) { (Get-NetIPAddress -InterfaceIndex $NetworkInterface -AddressFamily IPV4).IPAddress } Else { $null }
    Remove-Variable NetworkInterface

    If ($Session.MyIPaddress) { 
        # Read exchange rates
        Get-Rate

        # Fetch balances data from pools
        If ($PoolsToTrack) { 
            Write-Message -Level Info "Balances tracker is requesting data from pool$(If ($PoolsToTrack.Count -gt 1) { "s" }) $($PoolsToTrack -join ", " -replace ",([^,]*)$", " &`$1")..."
            $PoolsToTrack.ForEach(
                { 
                    $BalanceObjects += @(
                        & ".\Balances\$($_).ps1"
                        Write-Message -Level Debug "Balances tracker retrieved data for pool '$_'."
                    )
                }
            )

            # Keep most recent balance objects, keep empty balances for 7 days
            $BalanceObjects = @(($BalanceObjects + ($Session.BalancesData).Where({ $_.Pool -notin (Get-PoolBaseName $Config.BalancesTrackerExcludePool) -and $_.Unpaid -gt 0 -or $_.DateTime -gt $Now.AddDays(-7) -and $_.Wallet }) | Group-Object -Property Pool, Currency, Wallet).ForEach({ $_.Group | Sort-Object -Property DateTime -Bottom 1 }))

            ForEach ($PoolBalanceObject in $BalanceObjects) { 
                $PoolBalanceObjects = @($Session.BalancesData.Where({ $_.Pool -eq $PoolBalanceObject.Pool -and $_.Currency -eq $PoolBalanceObject.Currency -and $_.Wallet -eq $PoolBalanceObject.Wallet }) | Sort-Object -Property DateTime)

                # Get threshold currency and value
                $PayoutThreshold = $PoolBalanceObject.PayoutThreshold

                $PayoutThresholdCurrency = $PoolBalanceObject.Currency

                If (-not $PayoutThreshold) { $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool).Variant.($PoolBalanceObject.Pool).PayoutThreshold.$PayoutThresholdCurrency) -as [Double] }
                If (-not $PayoutThreshold) { $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool).PayoutThreshold.$PayoutThresholdCurrency) -as [Double] }
                If (-not $PayoutThreshold) { $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool).PayoutThreshold."*".$PayoutThresholdCurrency) -as [Double] }
                If (-not $PayoutThreshold) { $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool).PayoutThreshold."*") -as [Double] }
                If (-not $PayoutThreshold) { 
                    If ($PayoutThresholdCurrency = [String]($Config.PoolsConfig.($PoolBalanceObject.Pool).PayoutThreshold."*".Keys)) { 
                        $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool).PayoutThreshold."*".$PayoutThresholdCurrency) -as [Double]
                    }
                }

                If (-not $PayoutThreshold -and $PoolBalanceObject.Currency -eq "BTC") { 
                    $PayoutThresholdCurrency = "mBTC"
                    If (-not $PayoutThreshold) { $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool).Variant.($PoolBalanceObject.Pool).PayoutThreshold.$PayoutThresholdCurrency) -as [Double] }
                    If (-not $PayoutThreshold) { $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool).PayoutThreshold.$PayoutThresholdCurrency) -as [Double] }
                    If (-not $PayoutThreshold) { $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool).PayoutThreshold."*".$PayoutThresholdCurrency) -as [Double] }
                    If (-not $PayoutThreshold) { $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool).PayoutThreshold."*") -as [Double] }
                    If (-not $PayoutThreshold) { 
                        If ($PayoutThresholdCurrency = $Config.PoolsConfig.($PoolBalanceObject.Pool).PayoutThreshold."*".Keys[0]) { 
                            $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool).PayoutThreshold."*".$PayoutThresholdCurrency) -as [Double]
                        }
                    }
                }

                If ($PayoutThresholdCurrency -eq "mBTC") { 
                    $PayoutThresholdCurrency = "BTC"
                    $PayoutThreshold /= 1000
                }

                $Growth1 = $Growth6 = $Growth24 = $Growth168 = $Growth720 = $GrowthToday = $AvgHourlyGrowth = $AvgDailyGrowth = $AvgWeeklyGrowth = $Delta = $Payout = $HiddenPending = [Double]0

                If ($PoolBalanceObjects.Count -eq 0) { 
                    $PoolBalanceObject | Add-Member Delta ([Double]0)
                    $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObject.Unpaid))
                    $PoolBalanceObject | Add-Member Payout ([Double]0)
                    $PoolBalanceObject | Add-Member Total ([Double]($PoolBalanceObject.Unpaid))

                    $PoolBalanceObjects += $PoolBalanceObject
                    $Session.BalancesData += $PoolBalanceObject

                    $AvgHourlyGrowth = $AvgDailyGrowth = $AvgWeeklyGrowth = 0
                }
                Else { 
                    If ($PoolBalanceObject.Pool -like "NiceHash*") { 
                        If ($PoolBalanceObject.Withdrawal -gt 0) { 
                            # NiceHash temporarily reduces 'Balance' value before paying out
                            $PoolBalanceObject.Balance += $PoolBalanceObject.Withdrawal
                            $Payout = 0
                        }
                        ElseIf (($PoolBalanceObjects[-1]).Withdrawal -gt 0 -and $PoolBalanceObject.Withdrawal -eq 0) { 
                            # Payout occurred
                            $Payout = ($PoolBalanceObjects[-1]).Withdrawal
                        }
                        ElseIf ($PoolBalanceObject.Withdrawal -eq 0) { 
                            # NiceHash temporarily hides some 'pending' value while processing payouts
                            If ($PoolBalanceObject.Pending -lt ($PoolBalanceObjects[-1]).Pending) { 
                                $HiddenPending = ($PoolBalanceObjects[-1]).Pending - $PoolBalanceObject.Pending
                                $PoolBalanceObject | Add-Member HiddenPending ([Double]$HiddenPending)
                            }
                            # When payouts are processed the hidden pending value gets added to the balance
                            If (($PoolBalanceObjects[-1]).HiddenPending -gt 0) { 
                                If ($PoolBalanceObject.Balance -eq (($PoolBalanceObjects[-1]).Balance)) { 
                                    # Payout processing complete
                                    $HiddenPending *= -1
                                }
                                Else { 
                                    # Still processing payouts
                                    $HiddenPending = ($PoolBalanceObjects[-1]).HiddenPending
                                    $PoolBalanceObject | Add-Member HiddenPending ([Double]$HiddenPending)
                                }
                            }
                            $Payout = If (($PoolBalanceObjects[-1]).Unpaid -gt $PoolBalanceObject.Unpaid) { ($PoolBalanceObjects[-1]).Unpaid - $PoolBalanceObject.Unpaid } Else { 0 }
                        }
                        $Delta = $PoolBalanceObject.Unpaid - ($PoolBalanceObjects[-1]).Unpaid
                        $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects[-1]).Earnings + $Delta + $HiddenPending + $Payout) -Force
                    }
                    ElseIf ($PoolBalanceObject.Pool -eq "MiningPoolHub") { 
                        # MiningHubPool never reduces earnings
                        $Delta = $PoolBalanceObject.Unpaid - ($PoolBalanceObjects[-1]).Unpaid
                        If ($Delta -lt 0) { 
                            # Payout occured
                            $Payout = -$Delta
                            $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects[-1]).Earnings) -Force
                        }
                        Else { 
                            $Payout = 0
                            $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects[-1]).Earnings + $Delta) -Force
                        }
                    }
                    ElseIf ($PoolBalanceObject.Pool -match '^ProHashing.*') { 
                        # ProHashing never reduces earnings
                        $Delta = $PoolBalanceObject.Balance - ($PoolBalanceObjects[-1]).Balance
                        If ($PoolBalanceObject.Unpaid -lt ($PoolBalanceObjects[-1]).Unpaid) { 
                            # Payout occured
                            $Payout = ($PoolBalanceObjects[-1]).Unpaid - $PoolBalanceObject.Unpaid
                            $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects[-1]).Earnings + $PoolBalanceObject.Unpaid) -Force
                        }
                        Else { 
                            $Payout = 0
                            $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects[-1]).Earnings + $Delta) -Force
                        }
                    }
                    Else { 
                        # HashCryptos, HiveON, MiningDutch, ZergPool, ZPool
                        $Delta = $PoolBalanceObject.Unpaid - ($PoolBalanceObjects[-1]).Unpaid
                        # Current 'Unpaid' is smaller
                        If ($Delta -lt 0) { 
                            If (-$Delta -gt $PayoutThreshold * 0.5) { 
                                # Payout occured (delta -gt 50% of payout limit)
                                $Payout = -$Delta
                            }
                            Else { 
                                # Pool reduced earnings
                                $Payout = $Delta = 0
                            }
                            $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects[-1]).Earnings) -Force
                        }
                        Else { 
                            $Payout = 0
                            $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects[-1]).Earnings + $Delta) -Force
                        }
                    }
                    $PoolBalanceObject | Add-Member Payout ([Double]$Payout) -Force
                    $PoolBalanceObject | Add-Member Paid ([Double](($PoolBalanceObjects.Paid | Measure-Object -Maximum).Maximum + $Payout)) -Force
                    $PoolBalanceObject | Add-Member Delta ([Double]$Delta) -Force

                    If ((($Now - $PoolBalanceObjects[0].DateTime).TotalHours) -lt 1) { 
                        # Only calculate if current balance data
                        If ($PoolBalanceObject.DateTime -gt $Now.AddMinutes(-1)) { 
                            $Growth1 = $Growth6 = $Growth24 = $Growth168 = $Growth720 = [Double]($PoolBalanceObject.Earnings - $PoolBalanceObjects[0].Earnings)
                        }
                    }
                    Else { 
                        # Only calculate if current balance data
                        If ($PoolBalanceObjects.Where({ $_.DateTime -ge $Now.AddHours(-1) }))   { $Growth1   = [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects.Where({ $_.DateTime -ge $Now.AddHours(-1) })   | Sort-Object -Property DateTime -Top 1).Earnings) }
                        If ($PoolBalanceObjects.Where({ $_.DateTime -ge $Now.AddHours(-6) }))   { $Growth6   = [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects.Where({ $_.DateTime -ge $Now.AddHours(-6) })   | Sort-Object -Property DateTime -Top 1).Earnings) }
                        If ($PoolBalanceObjects.Where({ $_.DateTime -ge $Now.AddHours(-24) }))  { $Growth24  = [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects.Where({ $_.DateTime -ge $Now.AddHours(-24) })  | Sort-Object -Property DateTime -Top 1).Earnings) }
                        If ($PoolBalanceObjects.Where({ $_.DateTime -ge $Now.AddHours(-168) })) { $Growth168 = [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects.Where({ $_.DateTime -ge $Now.AddHours(-168) }) | Sort-Object -Property DateTime -Top 1).Earnings) }
                        If ($PoolBalanceObjects.Where({ $_.DateTime -ge $Now.AddHours(-720) })) { $Growth720 = [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects.Where({ $_.DateTime -ge $Now.AddHours(-720) }) | Sort-Object -Property DateTime -Top 1).Earnings) }
                    }

                    $AvgHourlyGrowth = If ($PoolBalanceObjects.Where({ $_.DateTime -lt $Now.AddHours(-1) })) { [Double](($PoolBalanceObject.Earnings - $PoolBalanceObjects[0].Earnings) / ($Now - $PoolBalanceObjects[0].DateTime).TotalHours) }    Else { $Growth1 }
                    $AvgDailyGrowth  = If ($PoolBalanceObjects.Where({ $_.DateTime -lt $Now.AddDays(-1) }))  { [Double](($PoolBalanceObject.Earnings - $PoolBalanceObjects[0].Earnings) / ($Now - $PoolBalanceObjects[0].DateTime).TotalDays) }     Else { $Growth24 }
                    $AvgWeeklyGrowth = If ($PoolBalanceObjects.Where({ $_.DateTime -lt $Now.AddDays(-7) }))  { [Double](($PoolBalanceObject.Earnings - $PoolBalanceObjects[0].Earnings) / ($Now - $PoolBalanceObjects[0].DateTime).TotalDays * 7) } Else { $Growth168 }

                    If ($PoolBalanceObjects.Where({ $_.DateTime.Date -eq $Now.Date })) { 
                        $GrowthToday = [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects.Where({ $_.DateTime.Date -eq $Now.Date }) | Sort-Object -Property DateTime -Top 1).Earnings)
                        If ($GrowthToday -lt 0) { $GrowthToday = 0 } # to avoid negative numbers
                    }

                    $PoolBalanceObjects += $PoolBalanceObject
                    $Session.BalancesData += $PoolBalanceObject
                }

                Try { 
                    $EarningsObject = [PSCustomObject]@{ 
                        Pool                    = $PoolBalanceObject.Pool
                        Wallet                  = $PoolBalanceObject.Wallet
                        Currency                = $PoolBalanceObject.Currency
                        Start                   = $PoolBalanceObjects[0].DateTime
                        LastUpdated             = $PoolBalanceObject.DateTime
                        Pending                 = [Double]$PoolBalanceObject.Pending
                        Balance                 = [Double]$PoolBalanceObject.Balance
                        Unpaid                  = [Double]$PoolBalanceObject.Unpaid
                        Earnings                = [Double]$PoolBalanceObject.Earnings
                        Delta                   = [Double]$PoolBalanceObject.Delta
                        Growth1                 = [Double]$Growth1
                        Growth6                 = [Double]$Growth6
                        Growth24                = [Double]$Growth24
                        Growth168               = [Double]$Growth168
                        Growth720               = [Double]$Growth720
                        GrowthToday             = [Double]$GrowthToday
                        AvgHourlyGrowth         = [Double]$AvgHourlyGrowth
                        AvgDailyGrowth          = [Double]$AvgDailyGrowth
                        AvgWeeklyGrowth         = [Double]$AvgWeeklyGrowth
                        ProjectedEndDayGrowth   = If (($Now - $PoolBalanceObjects[0].DateTime).TotalHours -ge 1) { [Double]($AvgHourlyGrowth * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $Now).Hours) } Else { [Double]($Growth1 * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $Now).Hours) }
                        ProjectedPayDate        = If ($PayoutThreshold -and $Session.Rates.$PayoutThresholdCurrency.($PoolBalanceObject.Currency)) { If ([Double]$PoolBalanceObject.Balance -lt $PayoutThreshold * $Session.Rates.$PayoutThresholdCurrency.($PoolBalanceObject.Currency)) { If (($AvgDailyGrowth, $Growth24 | Measure-Object -Maximum).Maximum -gt 1E-7) { [DateTime]$Now.AddDays(($PayoutThreshold * $Session.Rates.$PayoutThresholdCurrency.($PoolBalanceObject.Currency) - $PoolBalanceObject.Balance) / (($AvgDailyGrowth, $Growth24) | Measure-Object -Maximum).Maximum) } Else { "Unknown" } } Else { If ($PoolBalanceObject.NextPayout) { $PoolBalanceObject.NextPayout } Else { "Next pool payout" } } } Else { "Unknown" }
                        TrustLevel              = [Double]((($Now - $PoolBalanceObjects[0].DateTime).TotalHours / 168), 1 | Measure-Object -Minimum).Minimum
                        TotalHours              = [Double]($Now - $PoolBalanceObjects[0].DateTime).TotalHours
                        PayoutThreshold         = [Double]$PayoutThreshold
                        PayoutThresholdCurrency = $PayoutThresholdCurrency
                        Payout                  = [Double]$PoolBalanceObject.Payout
                        Uri                     = $PoolBalanceObject.Url
                        LastEarnings            = If ($Growth24 -gt 0) { $PoolBalanceObject.DateTime } Else { $PoolBalanceObjects[0].DateTime }
                    }
                    $Balances."$($PoolBalanceObject.Pool) ($($PoolBalanceObject.Currency):$($PoolBalanceObject.Wallet))" = $EarningsObject
                }
                Catch { 
                    Start-Sleep -Seconds 0
                }
                If ($Config.BalancesTrackerLog) { 
                    $EarningsObject | Export-Csv -NoTypeInformation -Append ".\Logs\BalancesTrackerLog.csv" -Force -ErrorAction Ignore
                }

                $PoolTodaysEarnings = $Earnings.Where({ $_.Pool -eq $PoolBalanceObject.Pool -and $_.Currency -eq $PoolBalanceObject.Currency -and $_.Wallet -eq $PoolBalanceObject.Wallet })[-1]

                If ([String]$PoolTodaysEarnings.Date -eq $Now.ToString("yyyy-MM-dd")) { 
                    $PoolTodaysEarnings.DailyEarnings = [Double]$GrowthToday
                    $PoolTodaysEarnings.EndTime = $Now.ToString("T")
                    $PoolTodaysEarnings.EndValue = [Double]$PoolBalanceObject.Earnings
                    $PoolTodaysEarnings.Balance = [Double]$PoolBalanceObject.Balance
                    $PoolTodaysEarnings.Unpaid = [Double]$PoolBalanceObject.Unpaid
                    $PoolTodaysEarnings.Payout = [Double]$PoolTodaysEarnings.Payout + [Double]$PoolBalanceObject.Payout
                }
                Else { 
                    $Earnings += [PSCustomObject]@{ 
                        Date          = $Now.ToString("yyyy-MM-dd")
                        Pool          = $EarningsObject.Pool
                        Currency      = $EarningsObject.Currency
                        Wallet        = $PoolBalanceObject.Wallet
                        DailyEarnings = [Double]$GrowthToday
                        StartTime     = $Now.ToString("T")
                        StartValue    = If ($PoolTodaysEarnings) { [Double]$PoolTodaysEarnings.EndValue } Else { [Double]$EarningsObject.Earnings }
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
        ($Balances.psbase.Keys.Where({ $Balances.$_.Pool -notin $Config.BalancesTrackerExcludePool }) | Sort-Object).ForEach(
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
        $ChartData = $Earnings.Where({ $PoolsToTrack -contains $_.Pool }) | Sort-Object -Property Date | Group-Object -Property Date | Select-Object -Last 30 # days

        # One dataset per pool
        (($ChartData.Group.Where({ $_.DailyEarnings -gt 0 })).Pool | Sort-Object -Unique).ForEach(
            { 
                $PoolChartData | Add-Member @{ $_ = [Double[]]@() }
            }
        )

        # Fill dataset
        ForEach ($PoolEarnings in $ChartData) { 
            $PoolChartData.PSObject.Properties.Name.ForEach(
                { 
                    $PoolChartData.$_ += (($PoolEarnings.Group | Where-Object Pool -EQ $_).ForEach({ [Double]$_.DailyEarnings * $Session.Rates.($_.Currency).BTC }) | Measure-Object -Sum).Sum
                }
            )
        }
        Remove-Variable PoolEarnings, PoolTodaysEarnings -ErrorAction Ignore

        $EarningsChartData = [PSCustomObject]@{ 
            Labels = @(
                ($ChartData.Group.Date | Sort-Object -Unique).ForEach(
                    { 
                        [DateTime]::parseexact($_, "yyyy-MM-dd", $null).ToShortDateString()
                    }
                )
            )
            # Use dates for x-axis label
            Earnings = $PoolChartData
        }
        Remove-Variable PoolChartData -ErrorAction Ignore

        $EarningsChartData | ConvertTo-Json | Out-File -LiteralPath ".\Data\EarningsChartData.json" -Force -ErrorAction Ignore
        $Session.Remove("EarningsChartData")
        $Session.EarningsChartData = $EarningsChartData.PSObject.Copy()

        # Keep earnings for max. 1 year
        $OldestEarningsDate = [DateTime]::Now.AddYears(-1).ToString("yyyy-MM-dd")
        $Earnings = $Earnings.Where({ $_.Date -ge $OldestEarningsDate })
        Remove-Variable OldestEarningsDate

        # At least 31 days are needed for Growth720
        If ($Session.BalancesData.Count -gt 1) { 
            $Session.BalancesData = @(
                ($Session.BalancesData.Where({ $_.DateTime -ge $Now.AddDays(-31) }) | Group-Object -Property Pool, Currency).ForEach(
                    { 
                        $Record = $null
                        ($_.Group | Sort-Object -Property DateTime).ForEach(
                            { 
                                If ($_.DateTime -ge $Now.AddDays(-1)) { $_ } # Keep all records for 1 day
                                ElseIf ($_.DateTime -ge $Now.AddDays(-7) -and $_.Delta -gt 0) { $_ } # Keep all records of the last 7 days with delta
                                ElseIf ($_.DateTime.Date -ne $Record.DateTime.Date) { $Record = $_; $_ } # Keep the newest one per day
                            }
                        )
                    }
                )
            ) | Sort-Object -Property DateTime -Descending
        }

        Try { 
            $Earnings | Export-Csv ".\Data\DailyEarnings.csv" -NoTypeInformation -Force
        }
        Catch { 
            Write-Message -Level Warn "Balances tracker failed to save earnings data to '.\Data\DailyEarnings.csv' (should have $($Earnings.count) entries)."
        }

        If ($Session.BalancesData.Count -ge 1) { $Session.BalancesData | ConvertTo-Json | Out-File -LiteralPath ".\Data\BalancesTrackerData.json" -Force -ErrorAction Ignore }
        If ($Session.Balances.Count -ge 1) { $Session.Balances | ConvertTo-Json | Out-File -LiteralPath ".\Data\Balances.json" -Force -ErrorAction Ignore }

        If ($PoolsToTrack.Count -gt 1) { 
            $Session.RefreshBalancesNeeded = $true
            Write-Message -Level Info "Balances tracker updated data for pool$(If ($PoolsToTrack.Count -gt 1) { "s" }) $($PoolsToTrack -join ", " -replace ",([^,]*)$", " &`$1")."
        }
    }

    # Sleep until next update (at least 1 minute, maximum 60 minutes) or when no internet connection
    While (-not $Session.MyIPaddress -or [DateTime]::Now -le $Now.AddMinutes((60, (1, [Int]$Config.BalancesTrackerPollInterval | Measure-Object -Maximum).Maximum | Measure-Object -Minimum ).Minimum)) { Start-Sleep -Seconds 5 }

    $Error.Clear()
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()

} While ($true)