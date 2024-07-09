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
File:           \Includes\LegacyGUI.psm1
Version:        6.2.16
Version date:   2024/07/09
#>

[Void][System.Reflection.Assembly]::Load("System.Windows.Forms")
[Void][System.Reflection.Assembly]::Load("System.Windows.Forms.DataVisualization")
[Void][System.Reflection.Assembly]::Load("System.Drawing")

#--- For High DPI, Call SetProcessDPIAware(need P/Invoke) and EnableVisualStyles ---
Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class ProcessDPI {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool SetProcessDPIAware(); 
}
'@
$null = [ProcessDPI]::SetProcessDPIAware()
[System.Windows.Forms.Application]::EnableVisualStyles()

$LegacyGUIcolors = @{ }
$LegacyGUIcolors["benchmarking"]                   = [System.Drawing.Color]::FromArgb(241, 255, 229)
$LegacyGUIcolors["disabled"]                       = [System.Drawing.Color]::FromArgb(255, 243, 231)
$LegacyGUIcolors["failed"]                         = [System.Drawing.Color]::FromArgb(255, 230, 230)
$LegacyGUIcolors["idle"] = $LegacyGUIcolors["stopped"]      = [System.Drawing.Color]::FromArgb(230, 248, 252)
$LegacyGUIcolors["launched"]                       = [System.Drawing.Color]::FromArgb(229, 255, 229)
$LegacyGUIcolors["running"]                        = [System.Drawing.Color]::FromArgb(212, 244, 212)
$LegacyGUIcolors["starting"] = $LegacyGUIcolors["stopping"] = [System.Drawing.Color]::FromArgb(245, 255, 245)
$LegacyGUIcolors["unavailable"]                    = [System.Drawing.Color]::FromArgb(254, 245, 220)
$LegacyGUIcolors["warmingup"]                      = [System.Drawing.Color]::FromArgb(231, 255, 230)

Function Set-TableColor { 

    Param (
        [Parameter(Mandatory = $true)]
        $DataGridView
    )
    If ($Config.UseColorForMinerStatus) { 
        ForEach ($Row in $DataGridView.Rows) { 
            If ($LegacyGUIcolors[$Row.DataBoundItem.SubStatus]) { 
                $Row.DefaultCellStyle.Backcolor = $LegacyGUIcolors[$Row.DataBoundItem.SubStatus]
            } 
        }
    }
}

Function Set-WorkerColor { 
    If ($Config.UseColorForMinerStatus) { 
        ForEach ($Row in $LegacyGUIworkersDGV.Rows) { 
            $Row.DefaultCellStyle.Backcolor = Switch ($Row.DataBoundItem.Status) { 
                "Offline" { $LegacyGUIcolors["disabled"] }
                "Paused"  { $LegacyGUIcolors["idle"] }
                "Running" { $LegacyGUIcolors["running"] }
                Default   { [System.Drawing.Color]::FromArgb(255, 255, 255, 255) }
            }
        }
    }
}

Function CheckBoxSwitching_Click { 

    $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    $SwitchingDisplayTypes = @()
    $LegacyGUIswitchingPageControls.ForEach({ If ($_.Checked) { $SwitchingDisplayTypes += $_.Tag } })
    If (Test-Path -LiteralPath ".\Logs\SwitchingLog.csv" -PathType Leaf) { 
        $LegacyGUIswitchingLogLabel.Text = "Switching log updated $((Get-ChildItem -Path ".\Logs\SwitchingLog.csv").LastWriteTime.ToString())"
        $LegacyGUIswitchingDGV.DataSource = (([System.IO.File]::ReadAllLines("$PWD\Logs\SwitchingLog.csv") | ConvertFrom-Csv).Where({ $_.Type -in $SwitchingDisplayTypes }) | Select-Object -Last 1000).ForEach({ $_.Datetime = (Get-Date $_.DateTime); $_ }) | Sort-Object DateTime -Descending | Select-Object @("DateTime", "Action", "Name", "Pools", "Algorithms", "Accounts", "Cycle", "Duration", "DeviceNames", "Type") | Out-DataTable
        If ($LegacyGUIswitchingDGV.Columns) { 
            $LegacyGUIswitchingDGV.Columns[0].FillWeight = 50
            $LegacyGUIswitchingDGV.Columns[1].FillWeight = 50
            $LegacyGUIswitchingDGV.Columns[2].FillWeight = 90; $LegacyGUIswitchingDGV.Columns[2].HeaderText = "Miner"
            $LegacyGUIswitchingDGV.Columns[3].FillWeight = 60 + ($LegacyGUIswitchingDGV.MinersBest_Combo.ForEach({ $_.Pools.Count }) | Measure-Object -Maximum).Maximum * 40; $LegacyGUIswitchingDGV.Columns[3].HeaderText = "Pool"
            $LegacyGUIswitchingDGV.Columns[4].FillWeight = 50 + ($LegacyGUIswitchingDGV.MinersBest_Combo.ForEach({ $_.Algorithms.Count }) | Measure-Object -Maximum).Maximum * 25; $LegacyGUIswitchingDGV.Columns[4].HeaderText = "Algorithm (variant)"
            $LegacyGUIswitchingDGV.Columns[5].FillWeight = 90 + ($LegacyGUIswitchingDGV.MinersBest_Combo.ForEach({ $_.Accounts.Count }) | Measure-Object -Maximum).Maximum * 50; $LegacyGUIswitchingDGV.Columns[5].HeaderText = "Account"
            $LegacyGUIswitchingDGV.Columns[6].FillWeight = 30; $LegacyGUIswitchingDGV.Columns[6].HeaderText = "Cycles"; $LegacyGUIswitchingDGV.Columns[6].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIswitchingDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"
            $LegacyGUIswitchingDGV.Columns[7].FillWeight = 35; $LegacyGUIswitchingDGV.Columns[7].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIswitchingDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"
            $LegacyGUIswitchingDGV.Columns[8].FillWeight = 30 + ($LegacyGUIswitchingDGV.MinersBest_Combo.ForEach({ $_.DeviceNames.Count }) | Measure-Object -Maximum).Maximum * 15; $LegacyGUIswitchingDGV.Columns[8].HeaderText = "Device"
            $LegacyGUIswitchingDGV.Columns[9].FillWeight = 30
        }       If ($Config.UseColorForMinerStatus) { 
            ForEach ($Row in $LegacyGUIswitchingDGV.Rows) { $Row.DefaultCellStyle.Backcolor = $LegacyGUIcolors[$Row.DataBoundItem.Action] }
        }
        $LegacyGUIswitchingDGV.ClearSelection()
        $LegacyGUIswitchingDGV.EndInit()
    }
    Else { $LegacyGUIswitchingLogLabel.Text = "Switching log - no data" }

    $LegacyGUIswitchingLogClearButton.Enabled = [Boolean]$LegacyGUIswitchingDGV.Columns

    $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
}

Function Set-DataGridViewDoubleBuffer {
    Param (
        [Parameter(Mandatory = $true)][System.Windows.Forms.DataGridView]$Grid,
        [Parameter(Mandatory = $true)][Boolean]$Enabled
    )

    $Type = $Grid.GetType();
    $PropInfo = $Type.GetProperty("DoubleBuffered", ("Instance", "NonPublic"))
    $PropInfo.SetValue($Grid, $Enabled, $null)
}

Function Update-TabControl { 

    $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    # Keep only 100 lines, more lines impact performance
    $SelectionLength = $Variables.TextBoxSystemLog.SelectionLength
    $SelectionStart = $Variables.TextBoxSystemLog.SelectionStart
    $TextLength = $Variables.TextBoxSystemLog.TextLength
    $Variables.TextBoxSystemLog.Lines = $Variables.TextBoxSystemLog.Lines | Select-Object -Last 100
    $SelectionStart = $SelectionStart - $TextLength + $Variables.TextBoxSystemLog.TextLength
    If ($SelectionStart -gt 0) { 
        $Variables.TextBoxSystemLog.Select($SelectionStart, $SelectionLength)
    }

    Switch ($LegacyGUItabControl.SelectedTab.Text) { 
        "System status" { 
            $LegacyGUIcontextMenuStripItem1.Text = "Re-benchmark"
            $LegacyGUIcontextMenuStripItem1.Visible = $true
            $LegacyGUIcontextMenuStripItem2.Text = "Re-measure power consumption"
            $LegacyGUIcontextMenuStripItem2.Visible = $Config.CalculatePowerCost
            $LegacyGUIcontextMenuStripItem3.Text = "Mark as failed"
            $LegacyGUIcontextMenuStripItem3.Visible = $true
            $LegacyGUIcontextMenuStripItem4.Enabled = $true
            $LegacyGUIcontextMenuStripItem4.Visible = $true
            $LegacyGUIcontextMenuStripItem4.Text = "Disable"
            $LegacyGUIcontextMenuStripItem5.Enabled = $false
            $LegacyGUIcontextMenuStripItem5.Visible = $false
            $LegacyGUIcontextMenuStripItem6.Enabled = $false
            $LegacyGUIcontextMenuStripItem6.Visible = $false

            $LegacyGUIactiveMinersLabel.Text = If ($Variables.MinersBest) { "Active miners updated $([DateTime]::Now.ToString())" } Else { "No miners running." }

            If (-not ($LegacyGUIcontextMenuStrip.Visible -and $LegacyGUIcontextMenuStrip.Enabled)) { 

                $LegacyGUIactiveMinersDGV.BeginInit()
                $LegacyGUIactiveMinersDGV.ClearSelection()
                $LegacyGUIactiveMinersDGV.DataSource = $Variables.MinersBest | Select-Object @(
                    @{ Name = "Info"; Expression = { $_.info } }
                    @{ Name = "SubStatus"; Expression = { $_.SubStatus } }
                    @{ Name = "Device(s)"; Expression = { $_.DeviceNames -join '; ' } }
                    @{ Name = "Miner"; Expression = { $_.Name } }
                    @{ Name = "Status"; Expression = { $_.Status } }, 
                    @{ Name = "Earning (biased) $($Config.MainCurrency)/day"; Expression = { If ([Double]::IsNaN($_.Earning)) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Earning * $Variables.Rates.BTC.($Config.MainCurrency)) } } }
                    @{ Name = "Power cost $($Config.MainCurrency)/day"; Expression = { If ([Double]::IsNaN($_.PowerCost) -or -not $Variables.CalculatePowerCost) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Powercost * $Variables.Rates.BTC.($Config.MainCurrency)) } } }
                    @{ Name = "Profit (biased) $($Config.MainCurrency)/day"; Expression = { If ([Double]::IsNaN($_.PowerCost) -or -not $Variables.CalculatePowerCost) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Profit * $Variables.Rates.BTC.($Config.MainCurrency)) } } }
                    @{ Name = "Power consumption"; Expression = { If ($_.MeasurePowerConsumption) { If ($_.Status -eq "Running") { "Measuring..." } Else { "Unmeasured" } } Else { If ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } Else { "$($_.PowerConsumption.ToString("N2")) W" } } } }
                    @{ Name = "Algorithm [Currency]"; Expression = { $_.WorkersRunning.ForEach({ "$($_.Pool.Algorithm)$(If ($_.Pool.Currency) { "[$($_.Pool.Currency)]" })" }) -join ' & '} }, 
                    @{ Name = "Pool"; Expression = { $_.WorkersRunning.Pool.Name -join ' & ' } }
                    @{ Name = "Hashrate"; Expression = { If ($_.Benchmark) { If ($_.Status -eq "Running") { "Benchmarking..." } Else { "Benchmark pending" } } Else { $_.WorkersRunning.ForEach({ $_.Hashrate | ConvertTo-Hash }) -join ' & ' } } }
                    @{ Name = "Running time (hhh:mm:ss)"; Expression = { "{0}:{1:mm}:{1:ss}" -f [Math]::floor(([DateTime]::Now.ToUniversalTime() - $_.BeginTime).TotalDays * 24), ([DateTime]::Now.ToUniversalTime() - $_.BeginTime) } }
                    @{ Name = "Total active (hhh:mm:ss)"; Expression = { "{0}:{1:mm}:{1:ss}" -f [Math]::floor($_.TotalMiningDuration.TotalDays * 24), $_.TotalMiningDuration } }
                    If ($LegacyGUIradioButtonPoolsUnavailable.checked) { @{ Name = "Reason"; Expression = { $_.Reasons -join ', ' } } }
                ) | Sort-Object -Property "Device(s)" | Out-DataTable

                If ($LegacyGUIactiveMinersDGV.Columns) { 
                    $LegacyGUIactiveMinersDGV.Columns[0].Visible = $false
                    $LegacyGUIactiveMinersDGV.Columns[1].Visible = $false
                    $LegacyGUIactiveMinersDGV.Columns[2].FillWeight = 30 + ($Variables.MinersBest.ForEach({ $_.DeviceNames.Count }) | Measure-Object -Maximum).Maximum * 20
                    $LegacyGUIactiveMinersDGV.Columns[3].FillWeight = 160
                    $LegacyGUIactiveMinersDGV.Columns[4].FillWeight = 60
                    $LegacyGUIactiveMinersDGV.Columns[5].FillWeight = 55; $LegacyGUIactiveMinersDGV.Columns[5].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIactiveMinersDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"
                    $LegacyGUIactiveMinersDGV.Columns[6].FillWeight = 55; $LegacyGUIactiveMinersDGV.Columns[6].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIactiveMinersDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIactiveMinersDGV.Columns[6].Visible = $Variables.CalculatePowerCost
                    $LegacyGUIactiveMinersDGV.Columns[7].FillWeight = 55; $LegacyGUIactiveMinersDGV.Columns[7].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIactiveMinersDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIactiveMinersDGV.Columns[7].Visible = $Variables.CalculatePowerCost
                    $LegacyGUIactiveMinersDGV.Columns[8].FillWeight = 55; $LegacyGUIactiveMinersDGV.Columns[8].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIactiveMinersDGV.Columns[8].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIactiveMinersDGV.Columns[8].Visible = $Variables.CalculatePowerCost
                    $LegacyGUIactiveMinersDGV.Columns[9].FillWeight = 70 + ($Variables.MinersBest.({ $_.Workers.Count }) | Measure-Object -Maximum).Maximum * 35
                    $LegacyGUIactiveMinersDGV.Columns[10].FillWeight = 50 + ($Variables.MinersBest.({ $_.Workers.Count }) | Measure-Object -Maximum).Maximum * 25
                    $LegacyGUIactiveMinersDGV.Columns[11].FillWeight = 50 + ($Variables.MinersBest.({ $_.Workers.Count }) | Measure-Object -Maximum).Maximum * 25; $LegacyGUIactiveMinersDGV.Columns[11].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIactiveMinersDGV.Columns[11].HeaderCell.Style.Alignment = "MiddleRight"
                    $LegacyGUIactiveMinersDGV.Columns[12].FillWeight = 65; $LegacyGUIactiveMinersDGV.Columns[12].DefaultCellStyle.Alignment = "MiddleRight";  $LegacyGUIactiveMinersDGV.Columns[12].HeaderCell.Style.Alignment = "MiddleRight"
                    $LegacyGUIactiveMinersDGV.Columns[13].FillWeight = 65; $LegacyGUIactiveMinersDGV.Columns[13].DefaultCellStyle.Alignment = "MiddleRight";  $LegacyGUIactiveMinersDGV.Columns[13].HeaderCell.Style.Alignment = "MiddleRight"
                }
                Set-TableColor -DataGridView $LegacyGUIactiveMinersDGV
                Form-Resize # To fully show lauched miners gridview
                $LegacyGUIactiveMinersDGV.EndInit()
            }
            Break
        }
        "Earnings" { 

            Function Get-NextColor { 
                Param (
                    [Parameter(Mandatory = $true)]
                    [Byte[]]$Color, 
                    [Parameter(Mandatory = $true)]
                    [Int[]]$Factors
                )

                # Apply change Factor
                (0..($Color.Count - 1)).ForEach({ $Color[$_] = [Math]::Abs(($Color[$_] + $Factors[$_]) % 192) })
                $Color
            }

            If (Test-Path -LiteralPath ".\Data\EarningsChartData.json" -PathType Leaf) { 
                Try { 
                    $Datasource = [System.IO.File]::ReadAllLines("$PWD\Data\EarningsChartData.json") | ConvertFrom-Json -ErrorAction Ignore

                    $ChartTitle = New-Object System.Windows.Forms.DataVisualization.Charting.Title
                    $ChartTitle.Alignment = "TopCenter"
                    $ChartTitle.Font = [System.Drawing.Font]::new("Arial", 10)
                    $ChartTitle.Text = "Earnings of the past $($DataSource.Labels.Count) active days"
                    $LegacyGUIearningsChart.Titles.Clear()
                    $LegacyGUIearningsChart.Titles.Add($ChartTitle)

                    $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
                    $ChartArea.AxisX.Enabled = 0
                    $ChartArea.AxisX.Interval = 1
                    $ChartArea.AxisY.IsMarginVisible = $false
                    $ChartArea.AxisY.LabelAutoFitStyle = 16
                    $ChartArea.AxisX.LabelStyle.Enabled = $true
                    $ChartArea.AxisX.Maximum = $Datasource.Labels.Count + 1
                    $ChartArea.AxisX.Minimum = 0
                    $ChartArea.AxisX.IsMarginVisible = $false
                    $ChartArea.AxisX.MajorGrid.Enabled = $false
                    $ChartArea.AxisY.Interval = [Math]::Ceiling(($Datasource.DaySum | Measure-Object -Maximum).Maximum / 4)
                    $ChartArea.AxisY.LabelAutoFitStyle = $ChartArea.AxisY.labelAutoFitStyle - 4
                    $ChartArea.AxisY.MajorGrid.Enabled = $true
                    $ChartArea.AxisY.MajorGrid.LineColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255) #"#FFFFFF"
                    $ChartArea.AxisY.Title = $Config.MainCurrency
                    $ChartArea.AxisY.ToolTip = "Total earnings per day"
                    $ChartArea.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255) #"#2B3232" 
                    $ChartArea.BackGradientStyle = 3
                    $ChartArea.BackSecondaryColor = [System.Drawing.Color]::FromArgb(255, 224, 224, 224) #"#777E7E"

                    $LegacyGUIearningsChart.ChartAreas.Clear()
                    $LegacyGUIearningsChart.ChartAreas.Add($ChartArea)
                    $LegacyGUIearningsChart.Series.Clear()

                    $Color = @(255, 255, 255, 255) #"FFFFFF"

                    $DaySum = @(0) * $DataSource.Labels.Count
                    $LegacyGUItooltipText = $DataSource.Labels.Clone()

                    ForEach ($Pool in $DataSource.Earnings.PSObject.Properties.Name) { 

                        $Color = (Get-NextColor -Color $Color -Factors -0, -20, -20, -20)

                        $LegacyGUIearningsChart.Series.Add($Pool)
                        $LegacyGUIearningsChart.Series[$Pool].ChartType = "StackedColumn"
                        $LegacyGUIearningsChart.Series[$Pool].BorderWidth = 3
                        $LegacyGUIearningsChart.Series[$Pool].Color = [System.Drawing.Color]::FromArgb($Color[0], $Color[1], $Color[2], $Color[3])

                        $I = 0
                        $Datasource.Earnings.$Pool.ForEach(
                            { 
                                $_ *= $Variables.Rates.BTC.($Config.MainCurrency)
                                $LegacyGUIearningsChart.Series[$Pool].Points.addxy(0, $_) | Out-Null
                                $Daysum[$I] += $_
                                If ($_) { 
                                    $LegacyGUItooltipText[$I] = "$($LegacyGUItooltipText[$I])`r$($Pool): {0:N$($Config.DecimalsMax)} $($Config.MainCurrency)" -f $_
                                }
                                $I ++
                            }
                        )
                    }
                    Remove-Variable Pool

                    $I = 0
                    $DataSource.Labels.ForEach(
                        { 
                            $ChartArea.AxisX.CustomLabels.Add($I +0.5, $I + 1.5, " $_ ")
                            $ChartArea.AxisX.CustomLabels[$I].ToolTip = "$($LegacyGUItooltipText[$I])`rTotal: {0:N$($Config.DecimalsMax)} $($Config.MainCurrency)" -f $Daysum[$I]
                            ForEach ($Pool in $DataSource.Earnings.PSObject.Properties.Name) { 
                                If ($Datasource.Earnings.$Pool[$I]) { 
                                    $LegacyGUIearningsChart.Series[$Pool].Points[$I].ToolTip = "$($LegacyGUItooltipText[$I])`rTotal: {0:N$($Config.DecimalsMax)} $($Config.MainCurrency)" -f $Daysum[$I]
                                }
                            }
                            $I ++
                        }
                    )
                    $ChartArea.AxisY.Maximum = ($DaySum | Measure-Object -Maximum).Maximum * 1.05
                }
                Catch {}
            }
            If ($Config.BalancesTrackerPollInterval -gt 0) { 
                If ($Variables.Balances) { 
                    $LegacyGUIbalancesLabel.Text = "Balances data updated $(($Variables.Balances.Values.LastUpdated | Sort-Object -Bottom 1).ToLocalTime().ToString())"

                    $LegacyGUIbalancesDGV.BeginInit()
                    $LegacyGUIbalancesDGV.ClearSelection()
                    $LegacyGUIbalancesDGV.DataSource = $Variables.Balances.Values | Select-Object @(
                        @{ Name = "Currency"; Expression = { $_.Currency } }, 
                        @{ Name = "Pool [Currency]"; Expression = { "$($_.Pool) [$($_.Currency)]" } }, 
                        @{ Name = "Balance ($($Config.MainCurrency))"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Balance * $Variables.Rates.($_.Currency).($Config.MainCurrency)) } }, 
                        @{ Name = "Avg. $($Config.MainCurrency)/day"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.AvgDailyGrowth * $Variables.Rates.($_.Currency).($Config.MainCurrency)) } }, 
                        @{ Name = "$($Config.MainCurrency) in 1h"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth1 * $Variables.Rates.($_.Currency).($Config.MainCurrency)) } }, 
                        @{ Name = "$($Config.MainCurrency) in 6h"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth6 * $Variables.Rates.($_.Currency).($Config.MainCurrency)) } }, 
                        @{ Name = "$($Config.MainCurrency) in 24h"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth24 * $Variables.Rates.($_.Currency).($Config.MainCurrency)) } }, 
                        @{ Name = "Projected pay date"; Expression = { If ($_.ProjectedPayDate -is [DateTime]) { $_.ProjectedPayDate.ToShortDateString() } Else { $_.ProjectedPayDate } } }, 
                        @{ Name = "Payout threshold"; Expression = { If ($_.PayoutThresholdCurrency -eq "BTC" -and $Config.UsemBTC) { $PayoutThresholdCurrency = "mBTC"; $mBTCfactor = 1000 } Else { $PayoutThresholdCurrency = $_.PayoutThresholdCurrency; $mBTCfactor = 1 }; "{0:P2} of {1} {2} " -f ($_.Balance / $_.PayoutThreshold * $Variables.Rates.($_.Currency).($_.PayoutThresholdCurrency)), ($_.PayoutThreshold * $mBTCfactor), $PayoutThresholdCurrency } }
                    ) | Sort-Object -Property Pool | Out-DataTable

                    If ($LegacyGUIbalancesDGV.Columns) { 
                        $LegacyGUIbalancesDGV.Columns[0].Visible = $false
                        $LegacyGUIbalancesDGV.Columns[1].FillWeight = 140 
                        $LegacyGUIbalancesDGV.Columns[2].FillWeight = 90; $LegacyGUIbalancesDGV.Columns[2].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIbalancesDGV.Columns[2].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIbalancesDGV.Columns[3].FillWeight = 90; $LegacyGUIbalancesDGV.Columns[3].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIbalancesDGV.Columns[3].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIbalancesDGV.Columns[4].FillWeight = 75; $LegacyGUIbalancesDGV.Columns[4].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIbalancesDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIbalancesDGV.Columns[5].FillWeight = 75; $LegacyGUIbalancesDGV.Columns[5].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIbalancesDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIbalancesDGV.Columns[6].FillWeight = 75; $LegacyGUIbalancesDGV.Columns[6].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIbalancesDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIbalancesDGV.Columns[7].FillWeight = 80
                        $LegacyGUIbalancesDGV.Columns[8].FillWeight = 100
                    }
                    $LegacyGUIbalancesDGV.Rows.ForEach(
                        { 
                            $_.Cells[2].ToolTipText = "$($_.Cells[0].Value) {0:n$($Config.DecimalsMax)}" -f ([Double]$_.Cells[2].Value * $Variables.Rates.($Config.MainCurrency).($_.Cells[0].Value))
                            $_.Cells[3].ToolTipText = "$($_.Cells[0].Value) {0:n$($Config.DecimalsMax)}" -f ([Double]$_.Cells[3].Value * $Variables.Rates.($Config.MainCurrency).($_.Cells[0].Value))
                            $_.Cells[4].ToolTipText = "$($_.Cells[0].Value) {0:n$($Config.DecimalsMax)}" -f ([Double]$_.Cells[4].Value * $Variables.Rates.($Config.MainCurrency).($_.Cells[0].Value))
                            $_.Cells[5].ToolTipText = "$($_.Cells[0].Value) {0:n$($Config.DecimalsMax)}" -f ([Double]$_.Cells[5].Value * $Variables.Rates.($Config.MainCurrency).($_.Cells[0].Value))
                            $_.Cells[6].ToolTipText = "$($_.Cells[0].Value) {0:n$($Config.DecimalsMax)}" -f ([Double]$_.Cells[6].Value * $Variables.Rates.($Config.MainCurrency).($_.Cells[0].Value))
                        }
                    )
                    Form-Resize # To fully show lauched miners gridview
                    $LegacyGUIbalancesDGV.EndInit()
                }
                Else { 
                    $LegacyGUIbalancesLabel.Text = "Waiting for balances data..."
                }
            }
            Else { 
                $LegacyGUIbalancesLabel.Text = "BalanceTracker is disabled (Configuration item 'BalancesTrackerPollInterval' -eq 0)"
            }
            Break
        }
        "Miners" { 
            $LegacyGUIcontextMenuStripItem1.Text = "Re-benchmark"
            $LegacyGUIcontextMenuStripItem1.Visible = $true
            $LegacyGUIcontextMenuStripItem2.Enabled = $Config.CalculatePowerCost
            $LegacyGUIcontextMenuStripItem2.Text = "Re-measure power consumption"
            $LegacyGUIcontextMenuStripItem2.Visible = $true
            $LegacyGUIcontextMenuStripItem3.Enabled = $true
            $LegacyGUIcontextMenuStripItem3.Text = "Mark as failed"
            $LegacyGUIcontextMenuStripItem4.Text = "Disable"
            $LegacyGUIcontextMenuStripItem5.Enabled = $true
            $LegacyGUIcontextMenuStripItem5.Text = "Enable"
            $LegacyGUIcontextMenuStripItem5.Visible = $true
            $LegacyGUIcontextMenuStripItem6.Enabled = $Variables.WatchdogTimers
            $LegacyGUIcontextMenuStripItem6.Text = "Remove watchdog timer"
            $LegacyGUIcontextMenuStripItem6.Visible = $true

            If (-not ($LegacyGUIcontextMenuStrip.Visible -and $LegacyGUIcontextMenuStrip.Enabled)) { 

                If ($LegacyGUIradioButtonMinersOptimal.checked) { $DataSource = $Variables.MinersOptimal }
                ElseIf ($LegacyGUIradioButtonMinersUnavailable.checked) { $DataSource = $Variables.Miners.Where({ -not $_.Available }) }
                Else { $DataSource = $Variables.Miners }

                $LegacyGUIminersDGV.BeginInit()
                $LegacyGUIminersDGV.ClearSelection()
                $LegacyGUIminersDGV.DataSource = $DataSource | Select-Object @(
                    @{ Name = "Info"; Expression = { $_.Info } },
                    @{ Name = "SubStatus"; Expression = { $_.SubStatus } },
                    @{ Name = "Best"; Expression = { $_.Best } }, 
                    @{ Name = "Miner"; Expression = { $_.Name } }, 
                    @{ Name = "Device(s)"; Expression = { $_.DeviceNames -join ', ' } }, 
                    @{ Name = "Status"; Expression = { $_.Status } }, 
                    @{ Name = "Earning (biased) $($Config.MainCurrency)/day"; Expression = { If ([Double]::IsNaN($_.Earning_Bias)) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Earning * $Variables.Rates.BTC.($Config.MainCurrency)) } } }, 
                    @{ Name = "Power cost $($Config.MainCurrency)/day"; Expression = { If ( [Double]::IsNaN($_.PowerCost)) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Powercost * $Variables.Rates.BTC.($Config.MainCurrency)) } } }, 
                    @{ Name = "Profit (biased) $($Config.MainCurrency)/day"; Expression = { If ([Double]::IsNaN($_.Profit_Bias) -or -not $Variables.CalculatePowerCost ) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Profit * $Variables.Rates.BTC.($Config.MainCurrency)) } } }, 
                    @{ Name = "Power consumption"; Expression = { If ($_.MeasurePowerConsumption) { If ($_.Status -eq "Running") { "Measuring..." } Else { "Unmeasured" } } Else { If ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } Else { "$($_.PowerConsumption.ToString("N2")) W" } } } }
                    @{ Name = "Algorithm (variant)"; Expression = { $_.Workers.Pool.AlgorithmVariant -join ' & '} }, 
                    @{ Name = "Pool"; Expression = { $_.Workers.Pool.Name -join ' & ' } }, 
                    @{ Name = "Hashrate"; Expression = { If ($_.Benchmark) { If ($_.Status -eq "Running") { "Benchmarking..." } Else { "Benchmark pending" } } Else { $_.Workers.ForEach({ $_.Hashrate | ConvertTo-Hash }) -join ' & ' } } }
                    If ($LegacyGUIradioButtonMinersUnavailable.checked -or $LegacyGUIradioButtonMiners.checked) { @{ Name = "Reason(s)"; Expression = { $_.Reasons -join ', '} } }
                ) | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, "Device(s)", Info | Out-DataTable

                If ($LegacyGUIminersDGV.Columns) { 
                    $LegacyGUIminersDGV.Columns[0].Visible = $false
                    $LegacyGUIminersDGV.Columns[1].Visible = $false
                    $LegacyGUIminersDGV.Columns[2].Visible = $false
                    $LegacyGUIminersDGV.Columns[3].FillWeight = 160
                    $LegacyGUIminersDGV.Columns[4].FillWeight = 25 + ($DataSource.ForEach({ $_.DeviceNames.Count }) | Measure-Object -Maximum).Maximum * 25
                    $LegacyGUIminersDGV.Columns[5].Visible = -not $LegacyGUIradioButtonMinersUnavailable.checked; $LegacyGUIminersDGV.Columns[5].FillWeight = 50
                    $LegacyGUIminersDGV.Columns[6].FillWeight = 55; $LegacyGUIminersDGV.Columns[6].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIminersDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"
                    $LegacyGUIminersDGV.Columns[7].FillWeight = 60; $LegacyGUIminersDGV.Columns[7].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIminersDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIminersDGV.Columns[7].Visible = $Variables.CalculatePowerCost
                    $LegacyGUIminersDGV.Columns[8].FillWeight = 55; $LegacyGUIminersDGV.Columns[8].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIminersDGV.Columns[8].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIminersDGV.Columns[8].Visible = $Variables.CalculatePowerCost
                    $LegacyGUIminersDGV.Columns[9].FillWeight = 55; $LegacyGUIminersDGV.Columns[9].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIminersDGV.Columns[9].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIminersDGV.Columns[9].Visible = $Variables.CalculatePowerCost
                    $LegacyGUIminersDGV.Columns[10].FillWeight = 60  + ($DataSource.ForEach({ $_.Workers.Count }) | Measure-Object -Maximum).Maximum * 30
                    $LegacyGUIminersDGV.Columns[11].FillWeight = 60  + ($DataSource.ForEach({ $_.Workers.Count }) | Measure-Object -Maximum).Maximum * 30
                    $LegacyGUIminersDGV.Columns[12].FillWeight = 50 + ($DataSource.ForEach({ $_.Workers.Count }) | Measure-Object -Maximum).Maximum * 25; $LegacyGUIminersDGV.Columns[12].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIminersDGV.Columns[12].HeaderCell.Style.Alignment = "MiddleRight"
                }
                Set-TableColor -DataGridView $LegacyGUIminersDGV
                $LegacyGUIminersDGV.EndInit()
            }

            If ($LegacyGUIminersDGV.Columns) { $LegacyGUIminersLabel.Text = "Miner data updated $([DateTime]::Now.ToString())" }
            ElseIf ($Variables.MiningStatus -eq "Idle") { $LegacyGUIminersLabel.Text = "No data - mining is stopped"}
            ElseIf ($Variables.MiningStatus -eq "Paused") { $LegacyGUIminersLabel.Text = "No data - mining is paused"}
            Else { $LegacyGUIminersLabel.Text = "Waiting for data..." }
            Break
        }
        "Pools" { 
            $LegacyGUIcontextMenuStripItem1.Visible = $false
            $LegacyGUIcontextMenuStripItem2.Visible = $false
            $LegacyGUIcontextMenuStripItem3.Text = "Reset pool stat data"
            $LegacyGUIcontextMenuStripItem3.Visible = $true
            $LegacyGUIcontextMenuStripItem4.Enabled = $Variables.WatchdogTimers
            $LegacyGUIcontextMenuStripItem4.Text = "Remove watchdog timer"
            $LegacyGUIcontextMenuStripItem5.Visible = $false
            $LegacyGUIcontextMenuStripItem6.Visible = $false

            If (-not ($LegacyGUIcontextMenuStrip.Visible -and $LegacyGUIcontextMenuStrip.Enabled)) { 

                If ($LegacyGUIradioButtonPoolsBest.checked) { $DataSource = $Variables.PoolsBest }
                ElseIf ($LegacyGUIradioButtonPoolsUnavailable.checked) { $DataSource = $Variables.Pools.Where({ -not $_.Available }) }
                Else { $DataSource = $Variables.Pools }

                If ($Config.UsemBTC) { 
                    $Factor = 1000
                    $Unit = "mBTC"
                    }
                    Else { 
                    $Factor = 1
                    $Unit = "BTC"
                }

                $LegacyGUIpoolsDGV.BeginInit()
                $LegacyGUIpoolsDGV.ClearSelection()
                $LegacyGUIpoolsDGV.DataSource = $DataSource | Sort-Object -Property AlgorithmVariant, Currency, Name | Select-Object @(
                    @{ Name = "Algorithm (variant)"; Expression = { $_.AlgorithmVariant } }
                    @{ Name = "Currency"; Expression = { $_.Currency } }
                    @{ Name = "Coin name"; Expression = { $_.CoinName } }
                    @{ Name = "$Unit/GH/Day (biased)"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Price_Bias * [Math]::Pow(1024, 3) * $Factor) } }
                    @{ Name = "Accuracy"; Expression = { "{0:p2}" -f $_.Accuracy } }
                    @{ Name = "Pool name"; Expression = { $_.Name } }
                    @{ Name = "Host"; Expression = { $_.Host } }
                    @{ Name = "Port"; Expression = { "$(If ($_.Port) { $_.Port } Else { "-" })" } }
                    @{ Name = "SSL port"; Expression = { "$(If ($_.PortSSL) { $_.PortSSL } Else { "-" })" } }
                    @{ Name = "Earnings adjustment factor"; Expression = { $_.EarningsAdjustmentFactor } }
                    @{ Name = "Fee"; Expression = { "{0:p2}" -f $_.Fee } }
                    If ($LegacyGUIradioButtonPoolsUnavailable.checked -or $LegacyGUIradioButtonPools.checked) { @{ Name = "Reason(s)"; Expression = { $_.Reasons -join ', '} } }
                ) | Out-DataTable

                If ($LegacyGUIpoolsDGV.Columns) { 
                    $LegacyGUIpoolsDGV.Columns[0].FillWeight = 80
                    $LegacyGUIpoolsDGV.Columns[1].FillWeight = 40
                    $LegacyGUIpoolsDGV.Columns[2].FillWeight = 70
                    $LegacyGUIpoolsDGV.Columns[3].FillWeight = 55; $LegacyGUIpoolsDGV.Columns[3].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIpoolsDGV.Columns[3].HeaderCell.Style.Alignment = "MiddleRight"
                    $LegacyGUIpoolsDGV.Columns[4].FillWeight = 45; $LegacyGUIpoolsDGV.Columns[4].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIpoolsDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"
                    $LegacyGUIpoolsDGV.Columns[5].FillWeight = 80
                    $LegacyGUIpoolsDGV.Columns[6].FillWeight = 140
                    $LegacyGUIpoolsDGV.Columns[7].FillWeight = 40; $LegacyGUIpoolsDGV.Columns[7].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIpoolsDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"
                    $LegacyGUIpoolsDGV.Columns[8].FillWeight = 40; $LegacyGUIpoolsDGV.Columns[8].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIpoolsDGV.Columns[8].HeaderCell.Style.Alignment = "MiddleRight"
                    $LegacyGUIpoolsDGV.Columns[9].FillWeight = 50; $LegacyGUIpoolsDGV.Columns[9].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIpoolsDGV.Columns[9].HeaderCell.Style.Alignment = "MiddleRight"
                    $LegacyGUIpoolsDGV.Columns[10].FillWeight = 40; $LegacyGUIpoolsDGV.Columns[10].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIpoolsDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"
                }
                $LegacyGUIpoolsDGV.EndInit()
            }

            If ($LegacyGUIpoolsDGV.Columns) { $LegacyGUIpoolsLabel.Text = "Pool data updated $([DateTime]::Now.ToString())" }
            ElseIf ($Variables.MiningStatus -eq "Idle") { $LegacyGUIpoolsLabel.Text = "No data - mining is stopped"}
            ElseIf ($Variables.MiningStatus -eq "Paused") { $LegacyGUIpoolsLabel.Text = "No data - mining is paused"}
            Else { $LegacyGUIpoolsLabel.Text = "Waiting for data..." }
            Break
        }
        # "Rig monitor" { 
        #     $LegacyGUIworkersDGV.Visible = $Config.ShowWorkerStatus
        #     $LegacyGUIeditMonitoringLink.Visible = $Variables.APIRunspace.APIport

        #     If ($Config.ShowWorkerStatus) { 

        #         Read-MonitoringData | Out-Null

        #         If ($Variables.Workers) { 
        #             $nl = "`n" # Must use variable, cannot join with '`n' directly

        #             $LegacyGUIworkersDGV.BeginInit()
        #             $LegacyGUIworkersDGV.ClearSelection()
        #             $LegacyGUIworkersDGV.DataSource = $Variables.Workers | Select-Object @(
        #                 @{ Name = "Worker"; Expression = { $_.worker } }, 
        #                 @{ Name = "Status"; Expression = { $_.status } }, 
        #                 @{ Name = "Last seen"; Expression = { (Get-TimeSince $_.date) } }, 
        #                 @{ Name = "Version"; Expression = { $_.version } }, 
        #                 @{ Name = "Currency"; Expression = { $_.data.Currency | Select-Object -Unique } }, 
        #                 @{ Name = "Estimated earning/day"; Expression = { If ($null -ne $_.Data) { "{0:n$($Config.DecimalsMax)}" -f (($_.Data.Earning.Where({ -not [Double]::IsNaN($_) }) | Measure-Object -Sum).Sum * $Variables.Rates.BTC.($_.data.Currency | Select-Object -Unique)) } } }, 
        #                 @{ Name = "Estimated profit/day"; Expression = { If ($null -ne $_.Data) { " {0:n$($Config.DecimalsMax)}" -f (($_.Data.Profit.Where({ -not [Double]::IsNaN($_) }) | Measure-Object -Sum).Sum * $Variables.Rates.BTC.($_.data.Currency | Select-Object -Unique)) } } }, 
        #                 @{ Name = "Miner"; Expression = { $_.data.Name -join $nl } }, 
        #                 @{ Name = "Pool"; Expression = { $_.data.ForEach({ $_.Pool -split "," -join ' & ' }) -join $nl } }, 
        #                 @{ Name = "Algorithm"; Expression = { $_.data.ForEach({ $_.Algorithm -split "," -join ' & ' }) -join $nl } }, 
        #                 @{ Name = "Live hashrate"; Expression = { $_.data.ForEach({ $_.CurrentSpeed.ForEach({ If ([Double]::IsNaN($_)) { "n/a" } Else { $_ | ConvertTo-Hash } }) -join ' & ' }) -join $nl } }, 
        #                 @{ Name = "Benchmark hashrate(s)"; Expression = { $_.data.ForEach({ $_.EstimatedSpeed.ForEach({ If ([Double]::IsNaN($_)) { "n/a" } Else { $_ | ConvertTo-Hash } }) -join ' & ' }) -join $nl } }
        #             ) | Sort-Object -Property "Worker" | Out-DataTable
        #             If ($LegacyGUIworkersDGV.Columns) { 
        #                 $LegacyGUIworkersDGV.Columns[0].FillWeight = 70
        #                 $LegacyGUIworkersDGV.Columns[1].FillWeight = 60
        #                 $LegacyGUIworkersDGV.Columns[2].FillWeight = 80
        #                 $LegacyGUIworkersDGV.Columns[3].FillWeight = 70
        #                 $LegacyGUIworkersDGV.Columns[4].FillWeight = 40
        #                 $LegacyGUIworkersDGV.Columns[5].FillWeight = 65; $LegacyGUIworkersDGV.Columns[5].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIworkersDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"
        #                 $LegacyGUIworkersDGV.Columns[6].FillWeight = 65; $LegacyGUIworkersDGV.Columns[6].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIworkersDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"
        #                 $LegacyGUIworkersDGV.Columns[7].FillWeight = 150
        #                 $LegacyGUIworkersDGV.Columns[8].FillWeight = 95
        #                 $LegacyGUIworkersDGV.Columns[9].FillWeight = 75
        #                 $LegacyGUIworkersDGV.Columns[10].FillWeight = 65; $LegacyGUIworkersDGV.Columns[10].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIworkersDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"
        #                 $LegacyGUIworkersDGV.Columns[11].FillWeight = 65; $LegacyGUIworkersDGV.Columns[11].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIworkersDGV.Columns[11].HeaderCell.Style.Alignment = "MiddleRight"
        #             }
        #             Set-WorkerColor
        #             $LegacyGUIworkersDGV.EndInit()
        #         }
        #             If ($Variables.Workers) { $LegacyGUIworkersLabel.Text = "Worker status updated $($Variables.WorkersLastUpdated.ToString())" }
        #             ElseIf ($Variables.MiningStatus -eq "Idle") { $LegacyGUIworkersLabel.Text = "No data - mining is stopped"}
        #             ElseIf ($Variables.MiningStatus -eq "Paused") { $LegacyGUIworkersLabel.Text = "No data - mining is paused"}
        #             Else  { $LegacyGUIworkersLabel.Text = "Waiting for data..." }

        #     }
        #     Else { 
        #         $LegacyGUIworkersLabel.Text = "Worker status reporting is disabled$(If (-not $Variables.APIRunspace) { " (Configuration item 'ShowWorkerStatus' -eq `$false)" })."
        #     }
        #     Break
        # }
        "Switching Log" { 
            $LegacyGUIcheckShowSwitchingCPU.Enabled = [Boolean]($Variables.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Config.ExcludeDeviceName -and $_.Type -eq "CPU" }))
            $LegacyGUIcheckShowSwitchingAMD.Enabled = [Boolean]($Variables.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Config.ExcludeDeviceName -and $_.Type -eq "GPU" -and $_.Vendor -eq "AMD" }))
            $LegacyGUIcheckShowSwitchingINTEL.Enabled = [Boolean]($Variables.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Config.ExcludeDeviceName -and $_.Type -eq "GPU" -and $_.Vendor -eq "INTEL" }))
            $LegacyGUIcheckShowSwitchingNVIDIA.Enabled = [Boolean]($Variables.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Config.ExcludeDeviceName -and $_.Type -eq "GPU" -and $_.Vendor -eq "NVIDIA" }))

            $LegacyGUIcheckShowSwitchingCPU.Checked = $LegacyGUIcheckShowSwitchingCPU.Enabled
            $LegacyGUIcheckShowSwitchingAMD.Checked = $LegacyGUIcheckShowSwitchingAMD.Enabled
            $LegacyGUIcheckShowSwitchingINTEL.Checked = $LegacyGUIcheckShowSwitchingINTEL.Enabled
            $LegacyGUIcheckShowSwitchingNVIDIA.Checked = $LegacyGUIcheckShowSwitchingNVIDIA.Enabled

            CheckBoxSwitching_Click
            Break
        }
        "Watchdog timers" { 
            $LegacyGUIwatchdogTimersRemoveButton.Visible = $Config.Watchdog
            $LegacyGUIwatchdogTimersDGV.Visible = $Config.Watchdog

            If ($Config.Watchdog) { 
                If ($Variables.WatchdogTimers) { 
                    $LegacyGUIwatchdogTimersLabel.Text = "Watchdog timers updated $([DateTime]::Now.ToString())"

                    $LegacyGUIwatchdogTimersDGV.BeginInit()
                    $LegacyGUIwatchdogTimersDGV.ClearSelection()
                    $LegacyGUIwatchdogTimersDGV.DataSource = $Variables.WatchdogTimers | Sort-Object -Property MinerName, Kicked | Select-Object @(
                        @{ Name = "Name"; Expression = { $_.MinerName } }, 
                        @{ Name = "Algorithms"; Expression = { $_.Algorithm } }, 
                        @{ Name = "Pool name"; Expression = { $_.PoolName } }, 
                        @{ Name = "Region"; Expression = { $_.PoolRegion } }, 
                        @{ Name = "Device(s)"; Expression = { $_.DeviceNames -join ', ' } }, 
                        @{ Name = "Last updated"; Expression = { (Get-TimeSince $_.Kicked.ToLocalTime()) } }
                    ) | Out-DataTable
                    If ($LegacyGUIwatchdogTimersDGV.Columns) { 
                        $LegacyGUIwatchdogTimersDGV.Columns[0].FillWeight = 120
                        $LegacyGUIwatchdogTimersDGV.Columns[1].FillWeight = 100
                        $LegacyGUIwatchdogTimersDGV.Columns[2].FillWeight = 100
                        $LegacyGUIwatchdogTimersDGV.Columns[3].FillWeight = 60
                        $LegacyGUIwatchdogTimersDGV.Columns[4].FillWeight = 30 + ($Variables.WatchdogTimers.ForEach({ $_.DeviceNames.Count }) | Measure-Object -Maximum).Maximum * 20
                        $LegacyGUIwatchdogTimersDGV.Columns[5].FillWeight = 100
                    }
                    $LegacyGUIwatchdogTimersDGV.EndInit()
                }
                Else { $LegacyGUIwatchdogTimersLabel.Text = "Watchdog timers - no data" }
            }
            Else { 
                $LegacyGUIwatchdogTimersLabel.Text = "Watchdog is disabled (Configuration item 'Watchdog' -eq `$false)"
            }

            $LegacyGUIwatchdogTimersRemoveButton.Enabled = [Boolean]$LegacyGUIwatchdogTimersDGV.Rows
        }
    }

    $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
}

Function Form-Resize { 
    If ($LegacyGUIform.Height -lt $LegacyGUIform.MinimumSize.Height -or $LegacyGUIform.Width -lt $LegacyGUIform.MinimumSize.Width ) { Return } # Sometimes $LegacyGUIform is smalle than minimum (Why?)
    Try { 
        $LegacyGUItabControl.Width = $LegacyGUIform.Width - 40
        $LegacyGUItabControl.Height = $LegacyGUIform.Height - $LegacyGUIminingStatusLabel.Height - $LegacyGUIminingSummaryLabel.Height - $LegacyGUIeditConfigLink.Height - 72

        $LegacyGUIbuttonStart.Location = [System.Drawing.Point]::new(($LegacyGUIform.Width - $LegacyGUIbuttonStop.Width - $LegacyGUIbuttonPause.Width - $LegacyGUIbuttonStart.Width - 60), 6)
        $LegacyGUIbuttonPause.Location = [System.Drawing.Point]::new(($LegacyGUIform.Width - $LegacyGUIbuttonStop.Width - $LegacyGUIbuttonPause.Width - 50), 6)
        $LegacyGUIbuttonStop.Location  = [System.Drawing.Point]::new(($LegacyGUIform.Width - $LegacyGUIbuttonStop.Width - 40), 6)

        $LegacyGUIminingSummaryLabel.Width = $Variables.TextBoxSystemLog.Width = $LegacyGUIactiveMinersDGV.Width = $LegacyGUIearningsChart.Width = $LegacyGUIbalancesDGV.Width = $LegacyGUIminersPanel.Width = $LegacyGUIminersDGV.Width = $LegacyGUIpoolsPanel.Width = $LegacyGUIpoolsDGV.Width = $LegacyGUIworkersDGV.Width = $LegacyGUIswitchingDGV.Width = $LegacyGUIwatchdogTimersDGV.Width = $LegacyGUItabControl.Width - 26

        If ($Config.BalancesTrackerPollInterval -gt 0 -and $LegacyGUIbalancesDGV.RowCount -gt 0) { 
            $LegacyGUIbalancesDGVHeight = ($LegacyGUIbalancesDGV.Rows.Height | Measure-Object -Sum | Select-Object -ExpandProperty Sum) + $LegacyGUIbalancesDGV.ColumnHeadersHeight
            If ($LegacyGUIbalancesDGVHeight -gt $LegacyGUItabControl.Height / 2) { 
                $LegacyGUIearningsChart.Height = $LegacyGUItabControl.Height / 2
                $LegacyGUIbalancesDGV.ScrollBars = "Vertical"
                $LegacyGUIbalancesLabel.Location = [System.Drawing.Point]::new(8, ($LegacyGUItabControl.Height / 2 - 10))
            }
            Else { 
                $LegacyGUIearningsChart.Height = $LegacyGUItabControl.Height - $LegacyGUIbalancesDGVHeight - 46
                $LegacyGUIbalancesDGV.ScrollBars = "None"
                $LegacyGUIbalancesLabel.Location = [System.Drawing.Point]::new(8, ($LegacyGUIearningsChart.Bottom - 20))
            }
        }
        Else { 
            $LegacyGUIbalancesDGV.ScrollBars = "None"
            $LegacyGUIbalancesLabel.Location = [System.Drawing.Point]::new(8, ($LegacyGUItabControl.Height - $LegacyGUIbalancesLabel.Height - 50))
            $LegacyGUIearningsChart.Height = $LegacyGUIbalancesLabel.Top + 36
        }
        $LegacyGUIbalancesDGV.Location = [System.Drawing.Point]::new(10, $LegacyGUIbalancesLabel.Bottom)
        $LegacyGUIbalancesDGV.Height = $LegacyGUItabControl.Height - $LegacyGUIbalancesLabel.Bottom - 48

        $LegacyGUIactiveMinersDGV.Height = $LegacyGUIactiveMinersDGV.RowTemplate.Height * $LegacyGUIactiveMinersDGV.RowCount + $LegacyGUIactiveMinersDGV.ColumnHeadersHeight
        If ($LegacyGUIactiveMinersDGV.Height -gt $LegacyGUItabControl.Height / 2) { 
            $LegacyGUIactiveMinersDGV.Height = $LegacyGUItabControl.Height / 2
            $LegacyGUIactiveMinersDGV.ScrollBars = "Vertical"
        }
        Else { 
            $LegacyGUIactiveMinersDGV.ScrollBars = "None"
        }

        $LegacyGUIsystemLogLabel.Location = [System.Drawing.Point]::new(8, ($LegacyGUIactiveMinersLabel.Height + $LegacyGUIactiveMinersDGV.Height + 25))
        $Variables.TextBoxSystemLog.Location = [System.Drawing.Point]::new(8, ($LegacyGUIactiveMinersLabel.Height + $LegacyGUIactiveMinersDGV.Height + $LegacyGUIsystemLogLabel.Height + 24))
        $Variables.TextBoxSystemLog.Height = ($LegacyGUItabControl.Height - $LegacyGUIactiveMinersLabel.Height - $LegacyGUIactiveMinersDGV.Height - $LegacyGUIsystemLogLabel.Height - 68)
        If (-not $Variables.TextBoxSystemLog.SelectionLength) { 
            $Variables.TextBoxSystemLog.ScrollToCaret()
        }

        $LegacyGUIminersDGV.Height = $LegacyGUItabControl.Height - $LegacyGUIminersLabel.Height - $LegacyGUIminersPanel.Height - 61

        $LegacyGUIpoolsDGV.Height = $LegacyGUItabControl.Height - $LegacyGUIpoolsLabel.Height - $LegacyGUIpoolsPanel.Height - 61

        $LegacyGUIworkersDGV.Height = $LegacyGUItabControl.Height - $LegacyGUIworkersLabel.Height - 58

        $LegacyGUIswitchingDGV.Height = $LegacyGUItabControl.Height - $LegacyGUIswitchingLogLabel.Height - $LegacyGUIswitchingLogClearButton.Height - 64

        $LegacyGUIwatchdogTimersDGV.Height = $LegacyGUItabControl.Height - $LegacyGUIwatchdogTimersLabel.Height - $LegacyGUIwatchdogTimersRemoveButton.Height - 64

        $LegacyGUIeditMonitoringLink.Location = [System.Drawing.Point]::new(($LegacyGUItabControl.Width - $LegacyGUIeditMonitoringLink.Width - 12), 6)

        $LegacyGUIeditConfigLink.Location = [System.Drawing.Point]::new(10, ($LegacyGUIform.Height - $LegacyGUIeditConfigLink.Height - 58))
        $LegacyGUIcopyrightLabel.Location = [System.Drawing.Point]::new(($LegacyGUItabControl.Width - $LegacyGUIcopyrightLabel.Width + 6), ($LegacyGUIform.Height - $LegacyGUIeditConfigLink.Height - 58))
    }
    Catch { 
        Start-Sleep 0
    }
}

Function Update-GUIstatus { 

    Switch ($Variables.MiningStatus) { 
        "Idle" { 
            $LegacyGUIminingStatusLabel.Text = "$($Variables.Branding.ProductLabel) is stopped"
            $LegacyGUIminingStatusLabel.ForeColor = [System.Drawing.Color]::Red
            $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Black
            $LegacyGUIminingSummaryLabel.Text = "Click the 'Start mining' button to make money."
            $LegacyGUIbuttonPause.Enabled = $true
            $LegacyGUIbuttonStart.Enabled = $true
            $LegacyGUIbuttonStop.Enabled = $false
        }
        "Paused" { 
            $LegacyGUIminingStatusLabel.Text = "$($Variables.Branding.ProductLabel) is paused"
            $LegacyGUIminingStatusLabel.ForeColor = [System.Drawing.Color]::Blue
            $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Black
            $LegacyGUIminingSummaryLabel.Text = "Click the 'Start mining' button to make money."
            $LegacyGUIbuttonPause.Enabled = $false
            $LegacyGUIbuttonStart.Enabled = $true
            $LegacyGUIbuttonStop.Enabled = $true
        }
        "Running" { 
            If ($Variables.IdleDetectionRunspace.MiningStatus -eq "Suspended") { 
                $LegacyGUIminingStatusLabel.Text = "$($Variables.Branding.ProductLabel) is suspended"
                $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Black
                $LegacyGUIminingSummaryLabel.Text = "Mining is suspended until system is idle for $($Config.IdleSec) second$(If ($Config.IdleSec -ne 1) { "s" })."
                $LegacyGUIminingStatusLabel.ForeColor = [System.Drawing.Color]::blue
            }
            Else { 
                $LegacyGUIminingStatusLabel.Text = "$($Variables.Branding.ProductLabel) is running"
                $LegacyGUIminingStatusLabel.ForeColor = [System.Drawing.Color]::Green
            }
            $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Black
            If (-not $LegacyGUIminingSummaryLabel.Text) { $LegacyGUIminingSummaryLabel.Text = "Starting mining processes..." }
            $LegacyGUIbuttonPause.Enabled = $true
            $LegacyGUIbuttonStart.Enabled = $false
            $LegacyGUIbuttonStop.Enabled = $true
        }
    }
    Update-TabControl

    $Variables.TextBoxSystemLog.ScrollToCaret()
}

$LegacyGUItooltip = New-Object System.Windows.Forms.ToolTip

$LegacyGUIform = New-Object System.Windows.Forms.Form
#--- For High DPI, First Call SuspendLayout(), after that, Set AutoScaleDimensions, AutoScaleMode ---
# SuspendLayout() is Very important to correctly size and position all controls!
$LegacyGUIform.SuspendLayout()
$LegacyGUIform.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$LegacyGUIform.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::DPI
$LegacyGUIform.MaximizeBox = $true
$LegacyGUIform.MinimumSize = [System.Drawing.Size]::new(800, 600) # best to keep under 800x600
$LegacyGUIform.Text = $Variables.Branding.ProductLabel
$LegacyGUIform.TopMost = $false

# Form Controls
$LegacyGUIControls = @()

$LegacyGUIstatusPage = New-Object System.Windows.Forms.TabPage
$LegacyGUIstatusPage.Text = "System status"
$LegacyGUIstatusPage.ToolTipText = "Show active miners and system log"
$LegacyGUIearningsPage = New-Object System.Windows.Forms.TabPage
$LegacyGUIearningsPage.Text = "Earnings"
$LegacyGUIearningsPage.ToolTipText = "Information about the calculated earnings / profit"
$LegacyGUIminersPage = New-Object System.Windows.Forms.TabPage
$LegacyGUIminersPage.Text = "Miners"
$LegacyGUIminersPage.ToolTipText = "Miner data collected in the last cycle"
$LegacyGUIpoolsPage = New-Object System.Windows.Forms.TabPage
$LegacyGUIpoolsPage.Text = "Pools"
$LegacyGUIpoolsPage.ToolTipText = "Pool data collected in the last cycle"
$LegacyGUIrigMonitorPage = New-Object System.Windows.Forms.TabPage
$LegacyGUIrigMonitorPage.Text = "Rig monitor"
$LegacyGUIrigMonitorPage.ToolTipText = "Consolidated overview of all known mining rigs"
$LegacyGUIswitchingPage = New-Object System.Windows.Forms.TabPage
$LegacyGUIswitchingPage.Text = "Switching log"
$LegacyGUIswitchingPage.ToolTipText = "List of the previously launched miners"
$LegacyGUIwatchdogTimersPage = New-Object System.Windows.Forms.TabPage
$LegacyGUIwatchdogTimersPage.Text = "Watchdog timers"
$LegacyGUIwatchdogTimersPage.ToolTipText = "List of all watchdog timers"

$LegacyGUIminingStatusLabel = New-Object System.Windows.Forms.Label
$LegacyGUIminingStatusLabel.AutoSize = $false
$LegacyGUIminingStatusLabel.BackColor = [System.Drawing.Color]::Transparent
$LegacyGUIminingStatusLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$LegacyGUIminingStatusLabel.ForeColor = [System.Drawing.Color]::Black
$LegacyGUIminingStatusLabel.Height = 20
$LegacyGUIminingStatusLabel.Location = [System.Drawing.Point]::new(6, 10)
$LegacyGUIminingStatusLabel.Text = "$($Variables.Branding.ProductLabel)"
$LegacyGUIminingStatusLabel.TextAlign = "MiddleLeft"
$LegacyGUIminingStatusLabel.Visible = $true
$LegacyGUIminingStatusLabel.Width = 360
$LegacyGUIControls += $LegacyGUIminingStatusLabel

$LegacyGUIminingSummaryLabel = New-Object System.Windows.Forms.Label
$LegacyGUIminingSummaryLabel.AutoSize = $false
$LegacyGUIminingSummaryLabel.BackColor = [System.Drawing.Color]::Transparent
$LegacyGUIminingSummaryLabel.BorderStyle = 'None'
$LegacyGUIminingSummaryLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Black
$LegacyGUIminingSummaryLabel.Height = 80
$LegacyGUIminingSummaryLabel.Location = [System.Drawing.Point]::new(6, $LegacyGUIminingStatusLabel.Bottom)
$LegacyGUIminingSummaryLabel.Tag = ""
$LegacyGUIminingSummaryLabel.TextAlign = "MiddleLeft"
$LegacyGUIminingSummaryLabel.Visible = $true
$LegacyGUIControls += $LegacyGUIminingSummaryLabel
$LegacyGUItooltip.SetToolTip($LegacyGUIminingSummaryLabel, "Color legend:`rBlack: Mining profitability is unknown`rGreen: Mining is profitable`rRed: Mining is NOT profitable")

$LegacyGUIbuttonPause = New-Object System.Windows.Forms.Button
$LegacyGUIbuttonPause.Enabled = $true
$LegacyGUIbuttonPause.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIbuttonPause.Height = 24
$LegacyGUIbuttonPause.Text = "Pause mining"
$LegacyGUIbuttonPause.Visible = $true
$LegacyGUIbuttonPause.Width = 100
$LegacyGUIbuttonPause.Add_Click(
    { 
        If ($Variables.NewMiningStatus -ne "Paused") { 
            # $Variables.Summary = "'Pause mining' button pressed.<br>Pausing $($Variables.Branding.ProductLabel)..."
            # Write-Message -Level Info "'Pause mining' button pressed. Pausing $($Variables.Branding.ProductLabel)..."
            $Variables.NewMiningStatus = "Paused"
            $Variables.RestartCycle = $true
        }
    }
)
$LegacyGUIControls += $LegacyGUIbuttonPause
$LegacyGUItooltip.SetToolTip($LegacyGUIbuttonPause, "Pause mining processes.`rBackground processes remain running.")

$LegacyGUIbuttonStart = New-Object System.Windows.Forms.Button
$LegacyGUIbuttonStart.Enabled = $true
$LegacyGUIbuttonStart.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIbuttonStart.Height = 24
$LegacyGUIbuttonStart.Text = "Start mining"
$LegacyGUIbuttonStart.Visible = $true
$LegacyGUIbuttonStart.Width = 100
$LegacyGUIbuttonStart.Add_Click(
    { 
        If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleDetectionRunspace -eq "Idle") { 
            # $Variables.Summary = "Start mining' button clicked.<br>Starting $($Variables.Branding.ProductLabel)..."
            # Write-Message -Level Info "'Start mining' button clicked. Starting $($Variables.Branding.ProductLabel)..."
            $Variables.NewMiningStatus = "Running"
            $Variables.RestartCycle = $true
        }
    }
)
$LegacyGUIControls += $LegacyGUIbuttonStart
$LegacyGUItooltip.SetToolTip($LegacyGUIbuttonStart, "Start the mining process.")

$LegacyGUIbuttonStop = New-Object System.Windows.Forms.Button
$LegacyGUIbuttonStop.Enabled = $true
$LegacyGUIbuttonStop.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIbuttonStop.Height = 24
$LegacyGUIbuttonStop.Text = "Stop mining"
$LegacyGUIbuttonStop.Visible = $true
$LegacyGUIbuttonStop.Width = 100
$LegacyGUIbuttonStop.Add_Click(
    { 
        If ($Variables.NewMiningStatus -ne "Idle") { 
            # $Variables.Summary = "'Stop mining' button clicked.<br>Stopping $($Variables.Branding.ProductLabel)..."
            # Write-Message -Level Info "'Stop mining' button clicked. Stopping $($Variables.Branding.ProductLabel)..."
            $Variables.NewMiningStatus = "Idle"
            $Variables.RestartCycle = $true
        }
    }
)
$LegacyGUIControls += $LegacyGUIbuttonStop
$LegacyGUItooltip.SetToolTip($LegacyGUIbuttonStop, "Stop mining processes.`rBackground processes will also stop.")

$LegacyGUIeditConfigLink = New-Object System.Windows.Forms.LinkLabel
$LegacyGUIeditConfigLink.ActiveLinkColor = [System.Drawing.Color]::Blue
$LegacyGUIeditConfigLink.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIeditConfigLink.LinkColor = [System.Drawing.Color]::Blue
$LegacyGUIeditConfigLink.Location = [System.Drawing.Point]::new(10, ($LegacyGUIform.Bottom - 26))
$LegacyGUIeditConfigLink.TextAlign = "MiddleLeft"
$LegacyGUIeditConfigLink.Size = New-Object System.Drawing.Size(380, 26)
$LegacyGUIeditConfigLink.Add_Click({ If ($LegacyGUIeditConfigLink.Tag -eq "WebGUI") { Start-Process "http://localhost:$($Variables.APIRunspace.APIport)/configedit.html" } Else { Edit-File $Variables.ConfigFile } })
$LegacyGUIControls += $LegacyGUIeditConfigLink
$LegacyGUItooltip.SetToolTip($LegacyGUIeditConfigLink, "Click to the edit configuration")

$LegacyGUIcopyrightLabel = New-Object System.Windows.Forms.LinkLabel
$LegacyGUIcopyrightLabel.ActiveLinkColor = [System.Drawing.Color]::Blue
$LegacyGUIcopyrightLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIcopyrightLabel.Location = [System.Drawing.Point]::new(10, ($LegacyGUIform.Bottom - 26))
$LegacyGUIcopyrightLabel.LinkColor = [System.Drawing.Color]::Blue
$LegacyGUIcopyrightLabel.Size = New-Object System.Drawing.Size(380, 26)
$LegacyGUIcopyrightLabel.Text = "Copyright (c) 2018-$([DateTime]::Now.Year) UselessGuru"
$LegacyGUIcopyrightLabel.TextAlign = "MiddleRight"
$LegacyGUIcopyrightLabel.Add_Click({ Start-Process "https://github.com/UselessGuru/UG-Miner/blob/master/LICENSE" })
$LegacyGUIControls += $LegacyGUIcopyrightLabel
$LegacyGUItooltip.SetToolTip($LegacyGUIcopyrightLabel, "Click to go to the $($Variables.Branding.ProductLabel) Github page")

# Miner context menu items
$LegacyGUIcontextMenuStrip = New-Object System.Windows.Forms.ContextMenuStrip
$LegacyGUIcontextMenuStrip.Enabled = $false
[System.Windows.Forms.ToolStripItem]$LegacyGUIcontextMenuStripItem1 = New-Object System.Windows.Forms.ToolStripMenuItem
[Void]$LegacyGUIcontextMenuStrip.Items.Add($LegacyGUIcontextMenuStripItem1)

[System.Windows.Forms.ToolStripItem]$LegacyGUIcontextMenuStripItem2 = New-Object System.Windows.Forms.ToolStripMenuItem
[Void]$LegacyGUIcontextMenuStrip.Items.Add($LegacyGUIcontextMenuStripItem2)

[System.Windows.Forms.ToolStripItem]$LegacyGUIcontextMenuStripItem3 = New-Object System.Windows.Forms.ToolStripMenuItem
[Void]$LegacyGUIcontextMenuStrip.Items.Add($LegacyGUIcontextMenuStripItem3)

[System.Windows.Forms.ToolStripItem]$LegacyGUIcontextMenuStripItem4 = New-Object System.Windows.Forms.ToolStripMenuItem
[Void]$LegacyGUIcontextMenuStrip.Items.Add($LegacyGUIcontextMenuStripItem4)

[System.Windows.Forms.ToolStripItem]$LegacyGUIcontextMenuStripItem5 = New-Object System.Windows.Forms.ToolStripMenuItem
[Void]$LegacyGUIcontextMenuStrip.Items.Add($LegacyGUIcontextMenuStripItem5)

[System.Windows.Forms.ToolStripItem]$LegacyGUIcontextMenuStripItem6 = New-Object System.Windows.Forms.ToolStripMenuItem
[Void]$LegacyGUIcontextMenuStrip.Items.Add($LegacyGUIcontextMenuStripItem6)

$LegacyGUIcontextMenuStrip.Add_ItemClicked(
    { 
        $Data = @()

        If ($This.SourceControl.Name -match 'LaunchedMinersDGV|MinersDGV') { 

            Switch ($_.ClickedItem.Text) { 
                "Re-benchmark" { 
                    $Variables.Miners.Where({ $_.Info -in $This.SourceControl.SelectedRows.ForEach{ ($_.Cells[0].Value) } }).ForEach(
                        { 
                            If ($_.Earning -eq 0) { $_.Available = $true }
                            $_.Earning_Accuracy = [Double]::NaN
                            $_.Activated = 0 # To allow 3 attempts
                            $_.Disabled = $false
                            $_.Benchmark = $true
                            $_.Restart = $true
                            $Data += $_.Name
                            ForEach ($Worker in $_.Workers) { 
                                Remove-Stat -Name "$($_.Name)_$($Worker.Pool.Algorithm)_Hashrate"
                                $Worker.Hashrate = [Double]::NaN
                            }
                            Remove-Variable Worker
                            # Also clear power consumption
                            Remove-Stat -Name "$($_.Name)_PowerConsumption"
                            $_.PowerConsumption = $_.PowerCost = $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = [Double]::NaN
                            If ($_.Status -eq [MinerStatus]::Idle) { 
                                $_.SubStatus = "idle"
                            }
                            ElseIf ($_.Status -eq [MinerStatus]::Failed) { 
                                $_.Status = "Idle"
                                $_.SubStatus = "idle"
                            }
                            ElseIf ($_.Status -eq [MinerStatus]::Unavailable) { 
                                $_.Status = "Idle"
                                $_.SubStatus = "idle"
                            }
                            $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -ne "Disabled by user" }))
                            $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -ne "Disabled by user" }))
                            $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -ne "0 H/s stat file" }))
                            $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -notlike "Unreal profit data *" }) | Sort-Object -Unique)
                            If (-not $_.Reasons) { $_.Available = $true }
                        }
                    )
                    $LegacyGUIcontextMenuStrip.Visible = $false
                    If ($Data) { 
                        $Data = $Data | Sort-Object -Unique
                        $Message = "Re-benchmark triggered for $($Data.Count) miner$(If ($Data.Count -ne 1) { "s" })."
                        Write-Message -Level Verbose "GUI: $Message"
                        $Data = "$($Data -join "`n")`n`n$Message"
                        Update-TabControl
                    }
                    Break
                }
                "Re-measure power consumption" { 
                    $Variables.Miners.Where({ $_.Info -in $This.SourceControl.SelectedRows.ForEach{ ($_.Cells[0].Value) } }).ForEach(
                        { 
                            If ($_.Earning -eq 0) { $_.Available = $true }
                            If ($Variables.CalculatePowerCost) { 
                                $_.MeasurePowerConsumption = $true
                                $_.Activated = 0 # To allow 3 attempts
                            }
                            $_.PowerConsumption = [Double]::NaN
                            $StatName = $_.Name
                            $Data += "$StatName"
                            Remove-Stat -Name "$($StatName)_PowerConsumption"
                            $_.PowerConsumption = $_.PowerCost = $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = [Double]::NaN
                            If ($_.Status -eq "Disabled") { $_.Status = "Idle" }
                        }
                    )
                    $LegacyGUIcontextMenuStrip.Visible = $false
                    If ($Data) { 
                        $Data = $Data | Sort-Object -Unique
                        $Message = "Re-measure power consumption triggered for $($Data.Count) miner$(If ($Data.Count -ne 1) { "s" })."
                        Write-Message -Level Verbose "GUI: $Message"
                        $Data = "$($Data -join "`n")`n`n$Message"
                        Update-TabControl
                    }
                    Break
                }
                "Mark as failed" { 
                    $Variables.Miners.Where({ $_.Info -in $This.SourceControl.SelectedRows.ForEach{ ($_.Cells[0].Value) } }).ForEach(
                        { 
                            If ($Parameters.Value -le 0 -and $Parameters.Type -eq "Hashrate") { $_.Available = $false; $_.Disabled = $true }
                            $Data += $_.Name
                            ForEach ($Worker in $_.Workers) { 
                                Set-Stat -Name "$($_.Name)_$($Worker.Pool.Algorithm)_Hashrate" -Value $Parameters.Value -FaultDetection $false | Out-Null
                                $Worker.Hashrate = [Double]::NaN
                            }
                            Remove-Variable Worker
                            $_.Available = $false
                            $_.Disabled = $false
                            If ($_.GetStatus() -eq [MinerStatus]::Running) { $_.SetStatus([MinerStatus]::Idle) }
                            $_.Status = "Idle"
                            $_.SubStatus = "failed"
                            $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = $_.Earning_Accuracy = [Double]::NaN
                            If ($_.Reasons -notcontains "0 H/s stat file" ) { $_.Reasons.Add("0 H/s stat file") }
                            $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -notlike "Disabled by user" }) | Sort-Object -Unique)
                        }
                    )
                    $LegacyGUIcontextMenuStrip.Visible = $false
                    If ($Data) { 
                        $Data = $Data | Sort-Object -Unique
                        $Message = "Marked $($Data.Count) miner$(If ($Data.Count -ne 1) { "s" }) as failed."
                        Write-Message -Level Verbose "GUI: $Message"
                        $Data = "$($Data -join "`n")`n`n$Message"
                        Update-TabControl
                    }
                    Break
                }
                "Disable" { 
                    $Variables.Miners.Where({ -not $_.Disabled -and $_.Info -in $This.SourceControl.SelectedRows.ForEach{ ($_.Cells[0].Value) } }).ForEach(
                        { 
                            $Data += $_.Name
                            ForEach ($Worker in $_.Workers) { 
                                Disable-Stat -Name "$($_.Name)_$($Worker.Pool.Algorithm)_Hashrate"
                                $Worker.Hashrate = [Double]::NaN
                            }
                            Remove-Variable Worker
                            If ($_.GetStatus() -eq [MinerStatus]::Running) { $_.SetStatus([MinerStatus]::Idle) }
                            $_.Disabled = $true
                            $_.Reasons += "Disabled by user"
                            $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -ne "Disabled by user" }) | Sort-Object -Unique)
                        }
                    )
                    $LegacyGUIcontextMenuStrip.Visible = $false
                    If ($Data = $Data | Sort-Object -Unique) { 
                        $Message = "Disabled $($Data.Count) miner$(If ($Data.Count -ne 1) { "s" })."
                        Write-Message -Level Verbose "GUI: $Message"
                        $Data = "$($Data -join "`n")`n`n$Message"
                        Update-TabControl
                    }
                    Break
                }
                "Enable" { 
                    $Variables.Miners.Where({ $_.Disabled -and $_.Info -in $This.SourceControl.SelectedRows.ForEach{ ($_.Cells[0].Value) } }).ForEach(
                        { 
                            $Data += $_.Name
                            ForEach ($Worker in $_.Workers) { 
                                Enable-Stat -Name "$($_.Name)_$($Worker.Pool.Algorithm)_Hashrate"
                                $Worker.Hashrate = [Double]::NaN
                            }
                            Remove-Variable Worker
                            $_.Disabled = $false
                            $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -ne "Disabled by user" }) | Sort-Object -Unique)
                            If (-not $_.Reasons) { $_.Available = $true }
                        }
                    )
                    $LegacyGUIcontextMenuStrip.Visible = $false
                    If ($Data = $Data | Sort-Object -Unique) { 
                        $Message = "Enabled $($Data.Count) miner$(If ($Data.Count -ne 1) { "s" })."
                        Write-Message -Level Verbose "GUI: $Message"
                        $Data = "$($Data -join "`n")`n`n$Message"
                        Update-TabControl
                    }
                    Break
                }
                "Remove watchdog timer" { 
                    $This.SourceControl.SelectedRows.ForEach(
                        { 
                            $SelectedMinerName = $_.Cells[0].Value
                            # Update miner
                            $Variables.Miners.Where({ $_.Name -eq $SelectedMinerName }).ForEach(
                                { 
                                    $Data += "$($_.Name)"
                                    $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -notlike "Miner suspended by watchdog *" }) | Sort-Object -Unique)
                                    If (-not $_.Reasons) { $_.Available = $true }
                                }
                            )

                            # Remove Watchdog timers
                            $Variables.WatchdogTimers = @($Variables.WatchdogTimers.Where({ $_.MinerName -ne $Miner.Name }))
                        }
                    )
                    $LegacyGUIcontextMenuStrip.Visible = $false
                    If ($Data) { 
                        $Data = $Data | Sort-Object -Unique
                        $Message = "$($Data.Count) miner watchdog timer$(If ($Data.Count -ne 1) { "s" }) removed."
                        Write-Message -Level Verbose "GUI: $Message"
                        $Data = "$($Data -join "`n")`n`n$Message"
                    }
                    Else { 
                        $Data = "No matching watchdog timer found."
                    }
                    Break
                }
            }
            If ($Data.Count -ge 1) { [Void][System.Windows.Forms.MessageBox]::Show([String]($Data -join "`r`n"), "$($Variables.Branding.ProductLabel): $($_.ClickedItem.Text) miners", [System.Windows.Forms.MessageBoxButtons]::OK, 64) }

        }
        ElseIf ($This.SourceControl.Name -match 'PoolsDGV') { 
            Switch ($_.ClickedItem.Text) { 
                "Reset pool stat data" { 
                    $This.SourceControl.SelectedRows.ForEach(
                        { 
                            $SelectedPoolName = $_.Cells[5].Value
                            $SelectedPoolAlgorithm = $_.Cells[0].Value
                            $Variables.Pools.Where({ $_.Name -eq $SelectedPoolName -and $_.Algorithm -eq $SelectedPoolAlgorithm }).ForEach(
                                { 
                                    $StatName = "$($_.Name)_$($_.Algorithm)$(If ($_.Currency) { "-$($_.Currency)" })"
                                    $Data += $StatName
                                    Remove-Stat -Name "$($StatName)_Profit"
                                    $_.Reasons = [System.Collections.Generic.List[String]]@()
                                    $_.Price = $_.Price_Bias = $_.StablePrice = $_.Accuracy = [Double]::Nan
                                    $_.Available = $true
                                    $_.Disabled = $false
                                }
                            )
                        }
                    )
                    $LegacyGUIcontextMenuStrip.Visible = $false
                    If ($Data) { 
                        $Data = $Data | Sort-Object -Unique
                        $Message = "Pool stats for $($Data.Count) pool$(If ($Data.Count -ne 1) { "s" }) reset."
                        Write-Message -Level Verbose "GUI: $Message"
                        $Data = "$($Data -join "`n")`n`n$Message"
                        Update-TabControl
                    }
                    Break
                }
                "Remove watchdog timer" { 
                    $This.SourceControl.SelectedRows.ForEach(
                        { 
                            $SelectedPoolName = $_.Cells[5].Value
                            $SelectedPoolAlgorithm = $_.Cells[0].Value
                            # Update pool
                            $Variables.Pools.Where({ $_.Name -eq $SelectedPoolName -and $_.Algorithm -eq $SelectedPoolAlgorithm -and $_.Reason -like "Pool suspended by watchdog *" }).ForEach(
                                { 
                                    $Data += "$($_.Key) ($($_.Region))"
                                    $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -notlike "Pool suspended by watchdog *" }) | Sort-Object -Unique)
                                    If (-not $_.Reasons) { $_.Available = $true }
                                }
                            )

                            # Remove Watchdog timers
                            $Variables.WatchdogTimers = @($Variables.WatchdogTimers.Where({ $_.PoolName -ne $SelectedPoolName -or $_.Algorithm -ne $SelectedPoolAlgorithm}))
                        }
                    )
                    $LegacyGUIcontextMenuStrip.Visible = $false
                    If ($Data) { 
                        $Data = $Data | Sort-Object -Unique
                        $Message = "$($Data.Count) pool watchdog timer$(If ($Data.Count -ne 1) { "s" }) removed."
                        Write-Message -Level Verbose "GUI: $Message"
                        $Data = "$($Data -join "`n")`n`n$Message"
                    }
                    Else { 
                        $Data = "No matching watchdog timer found."
                    }
                    Break
                }
            }
            If ($Data.Count -ge 1) { [Void][System.Windows.Forms.MessageBox]::Show([String]($Data -join "`r`n"), "$($Variables.Branding.ProductLabel): $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK, 64) }

        }
    }
)

# CheckBox Column for DataGridView
$LegacyGUIcheckBoxColumn = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$LegacyGUIcheckBoxColumn.HeaderText = ""
$LegacyGUIcheckBoxColumn.Name = "CheckBoxColumn"
$LegacyGUIcheckBoxColumn.ReadOnly = $false

# Run Page Controls
$LegacyGUIstatusPageControls = @()

$LegacyGUIactiveMinersLabel = New-Object System.Windows.Forms.Label
$LegacyGUIactiveMinersLabel.AutoSize = $false
$LegacyGUIactiveMinersLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIactiveMinersLabel.Height = 20
$LegacyGUIactiveMinersLabel.Location = [System.Drawing.Point]::new(6, 6)
$LegacyGUIactiveMinersLabel.Width = 600
$LegacyGUIstatusPageControls += $LegacyGUIactiveMinersLabel

$LegacyGUIactiveMinersDGV = New-Object System.Windows.Forms.DataGridView
$LegacyGUIactiveMinersDGV.AllowUserToAddRows = $false
$LegacyGUIactiveMinersDGV.AllowUserToDeleteRows = $false
$LegacyGUIactiveMinersDGV.AllowUserToOrderColumns = $true
$LegacyGUIactiveMinersDGV.AllowUserToResizeColumns = $true
$LegacyGUIactiveMinersDGV.AllowUserToResizeRows = $false
$LegacyGUIactiveMinersDGV.AutoSizeColumnsMode = "Fill"
$LegacyGUIactiveMinersDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIactiveMinersDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIactiveMinersDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LegacyGUIactiveMinersDGV.ContextMenuStrip = $LegacyGUIcontextMenuStrip
$LegacyGUIactiveMinersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LegacyGUIactiveMinersDGV.EnableHeadersVisualStyles = $false
$LegacyGUIactiveMinersDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$LegacyGUIactiveMinersDGV.Height = 3
$LegacyGUIactiveMinersDGV.Location = [System.Drawing.Point]::new(6, ($LegacyGUIactiveMinersLabel.Height + 6))
$LegacyGUIactiveMinersDGV.Name = "LaunchedMinersDGV"
$LegacyGUIactiveMinersDGV.ReadOnly = $true
$LegacyGUIactiveMinersDGV.RowHeadersVisible = $false
$LegacyGUIactiveMinersDGV.ScrollBars = "None"
$LegacyGUIactiveMinersDGV.SelectionMode = "FullRowSelect"
$LegacyGUIactiveMinersDGV.Add_MouseUP(
    { 
        If ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right) { 
            $LegacyGUIcontextMenuStrip.Enabled = [Boolean]$This.SelectedRows
        }
    }
)
$LegacyGUIactiveMinersDGV.Add_Sorted({ Set-TableColor -DataGridView $LegacyGUIactiveMinersDGV })
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIactiveMinersDGV -Enabled $true
$LegacyGUIstatusPageControls += $LegacyGUIactiveMinersDGV

$LegacyGUIsystemLogLabel = New-Object System.Windows.Forms.Label
$LegacyGUIsystemLogLabel.AutoSize = $false
$LegacyGUIsystemLogLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIsystemLogLabel.Height = 20
$LegacyGUIsystemLogLabel.Text = "System Log"
$LegacyGUIsystemLogLabel.Width = 600
$LegacyGUIstatusPageControls += $LegacyGUIsystemLogLabel

$Variables.TextBoxSystemLog = New-Object System.Windows.Forms.TextBox
$Variables.TextBoxSystemLog.AutoSize = $true
$Variables.TextBoxSystemLog.Font = [System.Drawing.Font]::new("Consolas", 9)
$Variables.TextBoxSystemLog.MultiLine = $true
$Variables.TextBoxSystemLog.ReadOnly = $true
$Variables.TextBoxSystemLog.Scrollbars = "Vertical"
$Variables.TextBoxSystemLog.Text = ""
$Variables.TextBoxSystemLog.WordWrap = $true
$LegacyGUIstatusPageControls += $Variables.TextBoxSystemLog
$LegacyGUItooltip.SetToolTip($Variables.TextBoxSystemLog, "These are the last 100 lines of the system log")

# Earnings Page Controls
$LegacyGUIearningsPageControls = @()

$LegacyGUIearningsChart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
$LegacyGUIearningsChart.BackColor = [System.Drawing.Color]::FromArgb(255, 240, 240, 240)
$LegacyGUIearningsChart.Location = [System.Drawing.Point]::new(-10, -5)
$LegacyGUIearningsPageControls += $LegacyGUIearningsChart

$LegacyGUIbalancesLabel = New-Object System.Windows.Forms.Label
$LegacyGUIbalancesLabel.AutoSize = $false
$LegacyGUIbalancesLabel.BringToFront()
$LegacyGUIbalancesLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIbalancesLabel.Height = 20
$LegacyGUIbalancesLabel.Width = 600
$LegacyGUIearningsPageControls += $LegacyGUIbalancesLabel

$LegacyGUIbalancesDGV = New-Object System.Windows.Forms.DataGridView
$LegacyGUIbalancesDGV.AllowUserToAddRows = $false
$LegacyGUIbalancesDGV.AllowUserToDeleteRows = $false
$LegacyGUIbalancesDGV.AllowUserToOrderColumns = $true
$LegacyGUIbalancesDGV.AllowUserToResizeColumns = $true
$LegacyGUIbalancesDGV.AllowUserToResizeRows = $false
$LegacyGUIbalancesDGV.AutoSizeColumnsMode = "Fill"
$LegacyGUIbalancesDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIbalancesDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIbalancesDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LegacyGUIbalancesDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LegacyGUIbalancesDGV.EnableHeadersVisualStyles = $false
$LegacyGUIbalancesDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$LegacyGUIbalancesDGV.Height = 3
$LegacyGUIbalancesDGV.Location = [System.Drawing.Point]::new(8, 187)
$LegacyGUIbalancesDGV.Name = "EarningsDGV"
$LegacyGUIbalancesDGV.ReadOnly = $true
$LegacyGUIbalancesDGV.RowHeadersVisible = $false
$LegacyGUIbalancesDGV.ScrollBars = "None"
$LegacyGUIbalancesDGV.SelectionMode = "FullRowSelect"
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIbalancesDGV -Enabled $true
$LegacyGUIearningsPageControls += $LegacyGUIbalancesDGV

# Miner page Controls
$LegacyGUIminersPageControls = @()

$LegacyGUIradioButtonMinersOptimal = New-Object System.Windows.Forms.RadioButton
$LegacyGUIradioButtonMinersOptimal.AutoSize = $false
$LegacyGUIradioButtonMinersOptimal.Checked = $true
$LegacyGUIradioButtonMinersOptimal.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIradioButtonMinersOptimal.Height = 22
$LegacyGUIradioButtonMinersOptimal.Location = [System.Drawing.Point]::new(0, 0)
$LegacyGUIradioButtonMinersOptimal.Text = "Optimal miners"
$LegacyGUIradioButtonMinersOptimal.Width = 150
$LegacyGUIradioButtonMinersOptimal.Add_Click({ Update-TabControl })
$LegacyGUItooltip.SetToolTip($LegacyGUIradioButtonMinersOptimal, "These are all optimal miners per algorithm and device.")

$LegacyGUIradioButtonMinersUnavailable = New-Object System.Windows.Forms.RadioButton
$LegacyGUIradioButtonMinersUnavailable.AutoSize = $false
$LegacyGUIradioButtonMinersUnavailable.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIradioButtonMinersUnavailable.Height = $LegacyGUIradioButtonMinersOptimal.Height
$LegacyGUIradioButtonMinersUnavailable.Location = [System.Drawing.Point]::new(150, 0)
$LegacyGUIradioButtonMinersUnavailable.Text = "Unavailable miners"
$LegacyGUIradioButtonMinersUnavailable.Width = 170
$LegacyGUIradioButtonMinersUnavailable.Add_Click({ Update-TabControl })
$LegacyGUItooltip.SetToolTip($LegacyGUIradioButtonMinersUnavailable, "These are all unavailable miners.`rThe column 'Reason(s)' shows the filter criteria(s) that made the miner unavailable.")

$LegacyGUIradioButtonMiners = New-Object System.Windows.Forms.RadioButton
$LegacyGUIradioButtonMiners.AutoSize = $false
$LegacyGUIradioButtonMiners.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIradioButtonMiners.Height = $LegacyGUIradioButtonMinersUnavailable.Height
$LegacyGUIradioButtonMiners.Location = [System.Drawing.Point]::new(320, 0)
$LegacyGUIradioButtonMiners.Text = "All miners"
$LegacyGUIradioButtonMiners.Width = 100
$LegacyGUIradioButtonMiners.Add_Click({ Update-TabControl })
$LegacyGUItooltip.SetToolTip($LegacyGUIradioButtonMiners, "These are all miners.`rNote: UG-Miner will only create miners for algorithms that have at least one available pool.")

$LegacyGUIminersLabel = New-Object System.Windows.Forms.Label
$LegacyGUIminersLabel.AutoSize = $false
$LegacyGUIminersLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIminersLabel.Height = 20
$LegacyGUIminersLabel.Location = [System.Drawing.Point]::new(6, 6)
$LegacyGUIminersLabel.Width = 600
$LegacyGUIminersPageControls += $LegacyGUIminersLabel

$LegacyGUIminersPanel = New-Object System.Windows.Forms.Panel
$LegacyGUIminersPanel.Height = 22
$LegacyGUIminersPanel.Location = [System.Drawing.Point]::new(8, ($LegacyGUIminersLabel.Height + 6))
$LegacyGUIminersPanel.Controls.Add($LegacyGUIradioButtonMinersOptimal)
$LegacyGUIminersPanel.Controls.Add($LegacyGUIradioButtonMinersUnavailable)
$LegacyGUIminersPanel.Controls.Add($LegacyGUIradioButtonMiners)
$LegacyGUIminersPageControls += $LegacyGUIminersPanel

$LegacyGUIminersDGV = New-Object System.Windows.Forms.DataGridView
$LegacyGUIminersDGV.AllowUserToAddRows = $false
$LegacyGUIminersDGV.AllowUserToOrderColumns = $true
$LegacyGUIminersDGV.AllowUserToResizeColumns = $true
$LegacyGUIminersDGV.AllowUserToResizeRows = $false
$LegacyGUIminersDGV.AutoSizeColumnsMode = "Fill"
$LegacyGUIminersDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIminersDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIminersDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LegacyGUIminersDGV.ColumnHeadersVisible = $true
$LegacyGUIminersDGV.ContextMenuStrip = $LegacyGUIcontextMenuStrip
$LegacyGUIminersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LegacyGUIminersDGV.EnableHeadersVisualStyles = $false
$LegacyGUIminersDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$LegacyGUIminersDGV.Height = 3
$LegacyGUIminersDGV.Location = [System.Drawing.Point]::new(6, ($LegacyGUIminersLabel.Height + $LegacyGUIminersPanel.Height + 10))
$LegacyGUIminersDGV.Name = "MinersDGV"
$LegacyGUIminersDGV.ReadOnly = $true
$LegacyGUIminersDGV.RowHeadersVisible = $false
$LegacyGUIminersDGV.SelectionMode = "FullRowSelect"
$LegacyGUIminersDGV.Add_MouseUP(
    { 
        If ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right ) { 
            $LegacyGUIcontextMenuStrip.Enabled = [Boolean]$This.SelectedRows
        }
    }
)
$LegacyGUIminersDGV.Add_Sorted({ Set-TableColor -DataGridView $LegacyGUIminersDGV })
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIminersDGV -Enabled $true
$LegacyGUIminersPageControls += $LegacyGUIminersDGV

# Pools page Controls
$LegacyGUIpoolsPageControls = @()

$LegacyGUIradioButtonPoolsBest = New-Object System.Windows.Forms.RadioButton
$LegacyGUIradioButtonPoolsBest.AutoSize = $false
$LegacyGUIradioButtonPoolsBest.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIradioButtonPoolsBest.Height = 22
$LegacyGUIradioButtonPoolsBest.Location = [System.Drawing.Point]::new(0, 0)
$LegacyGUIradioButtonPoolsBest.Tag = ""
$LegacyGUIradioButtonPoolsBest.Text = "Best pools"
$LegacyGUIradioButtonPoolsBest.Width = 120
$LegacyGUIradioButtonPoolsBest.Checked = $true
$LegacyGUIradioButtonPoolsBest.Add_Click({ Update-TabControl })
$LegacyGUItooltip.SetToolTip($LegacyGUIradioButtonPoolsBest, "This is the list of the best paying pool for each algorithm.")

$LegacyGUIradioButtonPoolsUnavailable = New-Object System.Windows.Forms.RadioButton
$LegacyGUIradioButtonPoolsUnavailable.AutoSize = $false
$LegacyGUIradioButtonPoolsUnavailable.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIradioButtonPoolsUnavailable.Height = $LegacyGUIradioButtonPoolsBest.Height
$LegacyGUIradioButtonPoolsUnavailable.Location = [System.Drawing.Point]::new(120, 0)
$LegacyGUIradioButtonPoolsUnavailable.Tag = ""
$LegacyGUIradioButtonPoolsUnavailable.Text = "Unavailable pools"
$LegacyGUIradioButtonPoolsUnavailable.Width = 170
$LegacyGUIradioButtonPoolsUnavailable.Add_Click({ Update-TabControl })
$LegacyGUItooltip.SetToolTip($LegacyGUIradioButtonPoolsUnavailable, "This is the pool data of all unavailable pools.`rThe column 'Reason(s)' shows the filter criteria(s) that made the pool unavailable.")

$LegacyGUIradioButtonPools = New-Object System.Windows.Forms.RadioButton
$LegacyGUIradioButtonPools.AutoSize = $false
$LegacyGUIradioButtonPools.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIradioButtonPools.Height = $LegacyGUIradioButtonPoolsUnavailable.Height
$LegacyGUIradioButtonPools.Location = [System.Drawing.Point]::new((120 + 175), 0)
$LegacyGUIradioButtonPools.Tag = ""
$LegacyGUIradioButtonPools.Text = "All pools"
$LegacyGUIradioButtonPools.Width = 100
$LegacyGUIradioButtonPools.Add_Click({ Update-TabControl })
$LegacyGUItooltip.SetToolTip($LegacyGUIradioButtonPools, "This is the pool data of all configured pools.")

$LegacyGUIpoolsLabel = New-Object System.Windows.Forms.Label
$LegacyGUIpoolsLabel.AutoSize = $false
$LegacyGUIpoolsLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIpoolsLabel.Location = [System.Drawing.Point]::new(6, 6)
$LegacyGUIpoolsLabel.Height = 20
$LegacyGUIpoolsLabel.Width = 600
$LegacyGUIpoolsPageControls += $LegacyGUIpoolsLabel

$LegacyGUIpoolsPanel = New-Object System.Windows.Forms.Panel
$LegacyGUIpoolsPanel.Height = 22
$LegacyGUIpoolsPanel.Location = [System.Drawing.Point]::new(8, ($LegacyGUIpoolsLabel.Height + 6))
$LegacyGUIpoolsPanel.Controls.Add($LegacyGUIradioButtonPools)
$LegacyGUIpoolsPanel.Controls.Add($LegacyGUIradioButtonPoolsUnavailable)
$LegacyGUIpoolsPanel.Controls.Add($LegacyGUIradioButtonPoolsBest)
$LegacyGUIpoolsPageControls += $LegacyGUIpoolsPanel

$LegacyGUIpoolsDGV = New-Object System.Windows.Forms.DataGridView
$LegacyGUIpoolsDGV.AllowUserToAddRows = $false
$LegacyGUIpoolsDGV.AllowUserToOrderColumns = $true
$LegacyGUIpoolsDGV.AllowUserToResizeColumns = $true
$LegacyGUIpoolsDGV.AllowUserToResizeRows = $false
$LegacyGUIpoolsDGV.AutoSizeColumnsMode = "Fill"
$LegacyGUIpoolsDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIpoolsDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIpoolsDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LegacyGUIpoolsDGV.ColumnHeadersVisible = $true
$LegacyGUIpoolsDGV.ContextMenuStrip = $LegacyGUIcontextMenuStrip
$LegacyGUIpoolsDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LegacyGUIpoolsDGV.EnableHeadersVisualStyles = $false
$LegacyGUIpoolsDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$LegacyGUIpoolsDGV.Height = 3
$LegacyGUIpoolsDGV.Location = [System.Drawing.Point]::new(6, ($LegacyGUIpoolsLabel.Height + $LegacyGUIpoolsPanel.Height + 10))
$LegacyGUIpoolsDGV.Name = "PoolsDGV"
$LegacyGUIpoolsDGV.ReadOnly = $true
$LegacyGUIpoolsDGV.RowHeadersVisible = $false
$LegacyGUIpoolsDGV.SelectionMode = "FullRowSelect"
$LegacyGUIpoolsDGV.Add_MouseUP(
    { 
        If ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right ) { 
            $LegacyGUIcontextMenuStrip.Enabled = [Boolean]$This.SelectedRows
        }
    }
)
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIpoolsDGV -Enabled $true
$LegacyGUIpoolsPageControls += $LegacyGUIpoolsDGV

# Monitoring Page Controls
$LegacyGUIrigMonitorPageControls = @()

$LegacyGUIworkersLabel = New-Object System.Windows.Forms.Label
$LegacyGUIworkersLabel.AutoSize = $false
$LegacyGUIworkersLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIworkersLabel.Height = 20
$LegacyGUIworkersLabel.Location = [System.Drawing.Point]::new(6, 6)
$LegacyGUIworkersLabel.Width = 900
$LegacyGUIrigMonitorPageControls += $LegacyGUIworkersLabel

$LegacyGUIworkersDGV = New-Object System.Windows.Forms.DataGridView
$LegacyGUIworkersDGV.AllowUserToAddRows = $false
$LegacyGUIworkersDGV.AllowUserToOrderColumns = $true
$LegacyGUIworkersDGV.AllowUserToResizeColumns = $true
$LegacyGUIworkersDGV.AllowUserToResizeRows = $false
$LegacyGUIworkersDGV.AutoSizeColumnsMode = "Fill"
$LegacyGUIworkersDGV.AutoSizeRowsMode = "AllCells"
$LegacyGUIworkersDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIworkersDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIworkersDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LegacyGUIworkersDGV.ColumnHeadersVisible = $true
$LegacyGUIworkersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LegacyGUIworkersDGV.DefaultCellStyle.WrapMode = "True"
$LegacyGUIworkersDGV.EnableHeadersVisualStyles = $false
$LegacyGUIworkersDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$LegacyGUIworkersDGV.Height = 3
$LegacyGUIworkersDGV.Location = [System.Drawing.Point]::new(6, ($LegacyGUIworkersLabel.Height + 8))
$LegacyGUIworkersDGV.ReadOnly = $true
$LegacyGUIworkersDGV.RowHeadersVisible = $false
$LegacyGUIworkersDGV.SelectionMode = "FullRowSelect"

$LegacyGUIworkersDGV.Add_Sorted({ Set-WorkerColor -DataGridView $LegacyGUIworkersDGV })
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIworkersDGV -Enabled $true
$LegacyGUIrigMonitorPageControls += $LegacyGUIworkersDGV

$LegacyGUIeditMonitoringLink = New-Object System.Windows.Forms.LinkLabel
$LegacyGUIeditMonitoringLink.ActiveLinkColor = [System.Drawing.Color]::Blue
$LegacyGUIeditMonitoringLink.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIeditMonitoringLink.Height = 20
$LegacyGUIeditMonitoringLink.Location = [System.Drawing.Point]::new(6, 6)
$LegacyGUIeditMonitoringLink.LinkColor = [System.Drawing.Color]::Blue
$LegacyGUIeditMonitoringLink.Text = "Edit the monitoring configuration"
$LegacyGUIeditMonitoringLink.TextAlign = "MiddleRight"
$LegacyGUIeditMonitoringLink.Size = New-Object System.Drawing.Size(330, 26)
$LegacyGUIeditMonitoringLink.Visible = $false
$LegacyGUIeditMonitoringLink.Width = 330
$LegacyGUIeditMonitoringLink.Add_Click({ Start-Process "http://localhost:$($Variables.APIRunspace.APIport)/rigmonitor.html" })
$LegacyGUIrigMonitorPageControls += $LegacyGUIeditMonitoringLink
$LegacyGUItooltip.SetToolTip($LegacyGUIeditMonitoringLink, "Click to the edit the monitoring configuration in the Web GUI")

# Switching Page Controls
$LegacyGUIswitchingPageControls = @()

$LegacyGUIswitchingLogLabel = New-Object System.Windows.Forms.Label
$LegacyGUIswitchingLogLabel.AutoSize = $false
$LegacyGUIswitchingLogLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIswitchingLogLabel.Height = 20
$LegacyGUIswitchingLogLabel.Location = [System.Drawing.Point]::new(6, 6)
$LegacyGUIswitchingLogLabel.Width = 600
$LegacyGUIswitchingPageControls += $LegacyGUIswitchingLogLabel

$LegacyGUIswitchingLogClearButton = New-Object System.Windows.Forms.Button
$LegacyGUIswitchingLogClearButton.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIswitchingLogClearButton.Height = 24
$LegacyGUIswitchingLogClearButton.Location = [System.Drawing.Point]::new(6, ($LegacyGUIswitchingLogLabel.Height + 8))
$LegacyGUIswitchingLogClearButton.Text = "Clear switching log"
$LegacyGUIswitchingLogClearButton.Visible = $true
$LegacyGUIswitchingLogClearButton.Width = 160
$LegacyGUIswitchingLogClearButton.Add_Click(
    { 
        Get-ChildItem -Path ".\Logs\switchinglog.csv" -File | Remove-Item -Force
        $LegacyGUIswitchingDGV.DataSource = $null
        $Data = "Switching log '.\Logs\switchinglog.csv' cleared."
        Write-Message -Level Verbose "GUI: $Data"
        $LegacyGUIswitchingLogClearButton.Enabled = $false
        [Void][System.Windows.Forms.MessageBox]::Show($Data, "$($Variables.Branding.ProductLabel) $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK, 64)
    }
)
$LegacyGUIswitchingPageControls += $LegacyGUIswitchingLogClearButton
$LegacyGUItooltip.SetToolTip($LegacyGUIswitchingLogClearButton, "This will clear the switching log '.\Logs\switchinglog.csv'")

$LegacyGUIcheckShowSwitchingCPU = New-Object System.Windows.Forms.CheckBox
$LegacyGUIcheckShowSwitchingCPU.AutoSize = $false
$LegacyGUIcheckShowSwitchingCPU.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIcheckShowSwitchingCPU.Height = 20
$LegacyGUIcheckShowSwitchingCPU.Location = [System.Drawing.Point]::new(($LegacyGUIswitchingLogClearButton.Width + 40), ($LegacyGUIswitchingLogLabel.Height + 10))
$LegacyGUIcheckShowSwitchingCPU.Tag = "CPU"
$LegacyGUIcheckShowSwitchingCPU.Text = "CPU"
$LegacyGUIcheckShowSwitchingCPU.Width = 70
$LegacyGUIswitchingPageControls += $LegacyGUIcheckShowSwitchingCPU
$LegacyGUIcheckShowSwitchingCPU.ForEach({ $_.Add_Click({ CheckBoxSwitching_Click($this) }) })

$LegacyGUIcheckShowSwitchingAMD = New-Object System.Windows.Forms.CheckBox
$LegacyGUIcheckShowSwitchingAMD.AutoSize = $false
$LegacyGUIcheckShowSwitchingAMD.Height = 20
$LegacyGUIcheckShowSwitchingAMD.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIcheckShowSwitchingAMD.Location = [System.Drawing.Point]::new(($LegacyGUIswitchingLogClearButton.Width + 40 + $LegacyGUIcheckShowSwitchingCPU.Width), ($LegacyGUIswitchingLogLabel.Height + 10))
$LegacyGUIcheckShowSwitchingAMD.Tag = "AMD"
$LegacyGUIcheckShowSwitchingAMD.Text = "AMD"
$LegacyGUIcheckShowSwitchingAMD.Width = 70
$LegacyGUIswitchingPageControls += $LegacyGUIcheckShowSwitchingAMD
$LegacyGUIcheckShowSwitchingAMD.ForEach({ $_.Add_Click({ CheckBoxSwitching_Click($this) }) })

$LegacyGUIcheckShowSwitchingINTEL = New-Object System.Windows.Forms.CheckBox
$LegacyGUIcheckShowSwitchingINTEL.AutoSize = $false
$LegacyGUIcheckShowSwitchingINTEL.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIcheckShowSwitchingINTEL.Height = 20
$LegacyGUIcheckShowSwitchingINTEL.Location = [System.Drawing.Point]::new(($LegacyGUIswitchingLogClearButton.Width + 40 + $LegacyGUIcheckShowSwitchingCPU.Width + $LegacyGUIcheckShowSwitchingAMD.Width), ($LegacyGUIswitchingLogLabel.Height + 10))
$LegacyGUIcheckShowSwitchingINTEL.Tag = "INTEL"
$LegacyGUIcheckShowSwitchingINTEL.Text = "INTEL"
$LegacyGUIcheckShowSwitchingINTEL.Width = 77
$LegacyGUIswitchingPageControls += $LegacyGUIcheckShowSwitchingINTEL
$LegacyGUIcheckShowSwitchingINTEL.ForEach({ $_.Add_Click({ CheckBoxSwitching_Click($this) }) })

$LegacyGUIcheckShowSwitchingNVIDIA = New-Object System.Windows.Forms.CheckBox
$LegacyGUIcheckShowSwitchingNVIDIA.AutoSize = $false
$LegacyGUIcheckShowSwitchingNVIDIA.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIcheckShowSwitchingNVIDIA.Height = 20
$LegacyGUIcheckShowSwitchingNVIDIA.Location = [System.Drawing.Point]::new(($LegacyGUIswitchingLogClearButton.Width + 40 + $LegacyGUIcheckShowSwitchingCPU.Width + $LegacyGUIcheckShowSwitchingAMD.Width + $LegacyGUIcheckShowSwitchingINTEL.Width), ($LegacyGUIswitchingLogLabel.Height + 10))
$LegacyGUIcheckShowSwitchingNVIDIA.Tag = "NVIDIA"
$LegacyGUIcheckShowSwitchingNVIDIA.Text = "NVIDIA"
$LegacyGUIcheckShowSwitchingNVIDIA.Width = 80
$LegacyGUIswitchingPageControls += $LegacyGUIcheckShowSwitchingNVIDIA
$LegacyGUIcheckShowSwitchingNVIDIA.ForEach({ $_.Add_Click({ CheckBoxSwitching_Click($this) }) })

$LegacyGUIswitchingDGV = New-Object System.Windows.Forms.DataGridView
$LegacyGUIswitchingDGV.AllowUserToAddRows = $false
$LegacyGUIswitchingDGV.AllowUserToOrderColumns = $true
$LegacyGUIswitchingDGV.AllowUserToResizeColumns = $true
$LegacyGUIswitchingDGV.AllowUserToResizeRows = $false
$LegacyGUIswitchingDGV.AutoSizeColumnsMode = "Fill"
$LegacyGUIswitchingDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIswitchingDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIswitchingDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LegacyGUIswitchingDGV.ColumnHeadersVisible = $true
$LegacyGUIswitchingDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LegacyGUIswitchingDGV.EnableHeadersVisualStyles = $false
$LegacyGUIswitchingDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$LegacyGUIswitchingDGV.Height = 3
$LegacyGUIswitchingDGV.Location = [System.Drawing.Point]::new(6, ($LegacyGUIswitchingLogLabel.Height + $LegacyGUIswitchingLogClearButton.Height + 12))
$LegacyGUIswitchingDGV.Name = "SwitchingDGV"
$LegacyGUIswitchingDGV.ReadOnly = $true
$LegacyGUIswitchingDGV.RowHeadersVisible = $false
$LegacyGUIswitchingDGV.SelectionMode = "FullRowSelect"

$LegacyGUIswitchingDGV.Add_Sorted(
    {
        If ($Config.UseColorForMinerStatus) { 
            ForEach ($Row in $LegacyGUIswitchingDGV.Rows) { $Row.DefaultCellStyle.Backcolor = $LegacyGUIcolors[$Row.DataBoundItem.Action] }
        }
     }
)
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIswitchingDGV -Enabled $true
$LegacyGUIswitchingPageControls += $LegacyGUIswitchingDGV

# Watchdog Page Controls
$LegacyGUIwatchdogTimersPageControls = @()

$LegacyGUIwatchdogTimersLabel = New-Object System.Windows.Forms.Label
$LegacyGUIwatchdogTimersLabel.AutoSize = $false
$LegacyGUIwatchdogTimersLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIwatchdogTimersLabel.Height = 20
$LegacyGUIwatchdogTimersLabel.Location = [System.Drawing.Point]::new(6, 6)
$LegacyGUIwatchdogTimersLabel.Width = 600
$LegacyGUIwatchdogTimersPageControls += $LegacyGUIwatchdogTimersLabel

$LegacyGUIwatchdogTimersRemoveButton = New-Object System.Windows.Forms.Button
$LegacyGUIwatchdogTimersRemoveButton.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIwatchdogTimersRemoveButton.Height = 24
$LegacyGUIwatchdogTimersRemoveButton.Location = [System.Drawing.Point]::new(6, ($LegacyGUIwatchdogTimersLabel.Height + 8))
$LegacyGUIwatchdogTimersRemoveButton.Text = "Remove all watchdog timers"
$LegacyGUIwatchdogTimersRemoveButton.Visible = $true
$LegacyGUIwatchdogTimersRemoveButton.Width = 220
$LegacyGUIwatchdogTimersRemoveButton.Add_Click(
    { 
        $Variables.WatchDogTimers = @()
        $LegacyGUIwatchdogTimersDGV.DataSource = $null
        $Variables.Miners.ForEach(
            { 
                $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -notlike "Miner suspended by watchdog *" }) | Sort-Object -Unique)
                $_.Where({ -not $_.Reasons }).ForEach({ $_.Available = $true })
            }
        )
        $Variables.Pools.ForEach(
            { 
                $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -notlike "*Pool suspended by watchdog" }) | Sort-Object -Unique)
                $_.Where({ -not $_.Reasons }).ForEach({ $_.Available = $true })
            }
        )
        Write-Message -Level Verbose "GUI: All watchdog timers reset."
        $LegacyGUIwatchdogTimersRemoveButton.Enabled = $false
        [Void][System.Windows.Forms.MessageBox]::Show("Watchdog timers will be recreated in next cycle.", "$($Variables.Branding.ProductLabel) $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK, 64)
    }
)
$LegacyGUIwatchdogTimersPageControls += $LegacyGUIwatchdogTimersRemoveButton
$LegacyGUItooltip.SetToolTip($LegacyGUIwatchdogTimersRemoveButton, "This will remove all watchdog timers.`rWatchdog timers will be recreated in next cycle.")

$LegacyGUIwatchdogTimersDGV = New-Object System.Windows.Forms.DataGridView
$LegacyGUIwatchdogTimersDGV.AllowUserToAddRows = $false
$LegacyGUIwatchdogTimersDGV.AllowUserToOrderColumns = $true
$LegacyGUIwatchdogTimersDGV.AllowUserToResizeColumns = $true
$LegacyGUIwatchdogTimersDGV.AllowUserToResizeRows = $false
$LegacyGUIwatchdogTimersDGV.AutoSizeColumnsMode = "Fill"
$LegacyGUIwatchdogTimersDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIwatchdogTimersDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIwatchdogTimersDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LegacyGUIwatchdogTimersDGV.ColumnHeadersVisible = $true
$LegacyGUIwatchdogTimersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LegacyGUIwatchdogTimersDGV.EnableHeadersVisualStyles = $false
$LegacyGUIwatchdogTimersDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$LegacyGUIwatchdogTimersDGV.Height = 3
$LegacyGUIwatchdogTimersDGV.Location = [System.Drawing.Point]::new(6, ($LegacyGUIwatchdogTimersLabel.Height + $LegacyGUIwatchdogTimersRemoveButton.Height + 12))
$LegacyGUIwatchdogTimersDGV.Name = "WatchdogTimersDGV"
$LegacyGUIwatchdogTimersDGV.ReadOnly = $true
$LegacyGUIwatchdogTimersDGV.RowHeadersVisible = $false
$LegacyGUIwatchdogTimersDGV.SelectionMode = "FullRowSelect"

Set-DataGridViewDoubleBuffer -Grid $LegacyGUIwatchdogTimersDGV -Enabled $true
$LegacyGUIwatchdogTimersPageControls += $LegacyGUIwatchdogTimersDGV

$LegacyGUIform.Controls.AddRange(@($LegacyGUIControls))
$LegacyGUIstatusPage.Controls.AddRange(@($LegacyGUIstatusPageControls))
$LegacyGUIearningsPage.Controls.AddRange(@($LegacyGUIearningsPageControls))
$LegacyGUIminersPage.Controls.AddRange(@($LegacyGUIminersPageControls))
$LegacyGUIpoolsPage.Controls.AddRange(@($LegacyGUIpoolsPageControls))
$LegacyGUIrigMonitorPage.Controls.AddRange(@($LegacyGUIrigMonitorPageControls))
$LegacyGUIswitchingPage.Controls.AddRange(@($LegacyGUIswitchingPageControls))
$LegacyGUIwatchdogTimersPage.Controls.AddRange(@($LegacyGUIwatchdogTimersPageControls))

$LegacyGUItabControl = New-Object System.Windows.Forms.TabControl
$LegacyGUItabControl.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUItabControl.Location = [System.Drawing.Point]::new(6, $LegacyGUIminingSummaryLabel.Bottom)
$LegacyGUItabControl.Name = "TabControl"
$LegacyGUItabControl.ShowToolTips = $true
$LegacyGUItabControl.Height = 0
$LegacyGUItabControl.Width = 0
# $LegacyGUItabControl.Controls.AddRange(@($LegacyGUIstatusPage, $LegacyGUIearningsPage, $LegacyGUIminersPage, $LegacyGUIpoolsPage, $LegacyGUIrigMonitorPage, $LegacyGUIswitchingPage, $LegacyGUIwatchdogTimersPage))
$LegacyGUItabControl.Controls.AddRange(@($LegacyGUIstatusPage, $LegacyGUIearningsPage, $LegacyGUIminersPage, $LegacyGUIpoolsPage, $LegacyGUIswitchingPage, $LegacyGUIwatchdogTimersPage))
$LegacyGUItabControl.Add_Click({ Update-TabControl })

$LegacyGUIform.Controls.Add($LegacyGUItabControl)
$LegacyGUIform.KeyPreview = $true
$LegacyGUIform.ResumeLayout()

$LegacyGUIform.Add_Load(
    { 
         If (Test-Path -LiteralPath ".\Config\WindowSettings.json" -PathType Leaf) { 
            $WindowSettings = [System.IO.File]::ReadAllLines("$PWD\Config\WindowSettings.json") | ConvertFrom-Json -AsHashtable
            # Restore window size
            If ($WindowSettings.Width -gt $LegacyGUIform.MinimumSize.Width) { $LegacyGUIform.Width = $WindowSettings.Width }
            If ($WindowSettings.Height -gt $LegacyGUIform.MinimumSize.Height) { $LegacyGUIform.Height = $WindowSettings.Height }
            If ($WindowSettings.Top -gt 0) { $LegacyGUIform.Top = $WindowSettings.Top }
            If ($WindowSettings.Left -gt 0) { $LegacyGUIform.Left = $WindowSettings.Left }
        }

        $LegacyGUIformWindowState = If ($Config.LegacyGUIStartMinimized) { [System.Windows.Forms.FormWindowState]::Minimized } Else { [System.Windows.Forms.FormWindowState]::Normal }

        Update-GUIstatus

        $LegacyGUIminingSummaryLabel.Text = ""
        $LegacyGUIminingSummaryLabel.SendToBack()
        (($Variables.Summary -replace 'Power Cost', '<br>Power Cost' -replace ' / ', '/' -replace '&ensp;', ' ' -replace '   ', '  ') -split '<br>').ForEach({ $LegacyGUIminingSummaryLabel.Text += "`r`n$_" })
        $LegacyGUIminingSummaryLabel.Text += "`r`n "
        If (-not $Variables.MinersBest) { $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Black }
        ElseIf ($Variables.MiningProfit -ge 0) { $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Green }
        ElseIf ($Variables.MiningProfit -lt 0) { $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Red }

        $TimerUI = New-Object System.Windows.Forms.Timer
        $TimerUI.Interval = 100
        $TimerUI.Add_Tick(
            { 
                If ($LegacyGUIform.CanSelect) {
                    If ($Variables.APIRunspace) { 
                        If ($LegacyGUIeditConfigLink.Tag -ne "WebGUI") { 
                            $LegacyGUIeditConfigLink.Tag = "WebGUI"
                            $LegacyGUIeditConfigLink.Text = "Edit configuration in the Web GUI"
                        }
                    }
                    ElseIf ($LegacyGUIeditConfigLink.Tag -ne "Edit-File") { 
                        $LegacyGUIeditConfigLink.Tag = "Edit-File"
                        $LegacyGUIeditConfigLink.Text = "Edit configuration file '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))' in notepad"
                    }
                    [Void](MainLoop)
                }
            }
        )
        $TimerUI.Start()
    }
)

$LegacyGUIform.Add_FormClosing(
    {
        If ($Config.LegacyGUI) { 
            $MsgBoxInput = [System.Windows.Forms.MessageBox]::Show("Do you want to shut down $($Variables.Branding.ProductLabel)?", "$($Variables.Branding.ProductLabel)", [System.Windows.Forms.MessageBoxButtons]::YesNo, 32, "Button2")
        }
        Else { 
            $MsgBoxInput = [System.Windows.Forms.MessageBox]::Show("Do you also want to shut down $($Variables.Branding.ProductLabel)?", "$($Variables.Branding.ProductLabel)", [System.Windows.Forms.MessageBoxButtons]::YesNoCancel, 32, "Button3")
        }
        If ($MsgBoxInput -eq "Yes") { 
            $TimerUI.Stop()
            Write-Message -Level Info "Shutting down $($Variables.Branding.ProductLabel)..."
            $Variables.NewMiningStatus = "Idle"

            Stop-IdleDetection
            Stop-Core
            Stop-Brain
            Stop-BalancesTracker

            If ($LegacyGUIform.DesktopBounds.Width -ge 0) { 
                # Save window settings
                $LegacyGUIform.DesktopBounds | ConvertTo-Json | Out-File -LiteralPath ".\Config\WindowSettings.json" -Force -ErrorAction Ignore
            }

            Write-Message -Level Info "$($Variables.Branding.ProductLabel) has shut down."
            Start-Sleep -Seconds 2
            Stop-Process $PID -Force
        }
        If ($Config.LegacyGUI -or $MsgBoxInput -eq "Cancel") { 
            $_.Cancel = $true
        }
    }
)

$LegacyGUIform.Add_KeyDown(
    {
        If ($PSItem.KeyCode -eq "F5") { Update-TabControl }
    }
)

$LegacyGUIform.Add_ResizeEnd({ Form-Resize })

$LegacyGUIform.Add_SizeChanged(
    { 
        If ($this.WindowState -ne $LegacyGUIformWindowState) { 
            $LegacyGUIformWindowState = $this.WindowState
            Form-Resize
        }
    }
)