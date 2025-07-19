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
File:           \Includes\LegacyGUI.psm1
Version:        6.5.1
Version date:   2025/07/19
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

Function Resize-Form { 

    If ($LegacyGUIform.Height -lt $LegacyGUIform.MinimumSize.Height -or $LegacyGUIform.Width -lt $LegacyGUIform.MinimumSize.Width) { Return } # Sometimes $LegacyGUIform is smaller than minimum (Why?)
    Try { 
        $LegacyGUItabControl.Height = $LegacyGUIform.ClientSize.Height - $LegacyGUIminingStatusLabel.Height - $LegacyGUIminingSummaryLabel.Height - $LegacyGUIeditConfigLink.Height - $LegacyGUIeditConfigLink.Height + 3
        $LegacyGUItabControl.Width = $LegacyGUIform.ClientSize.Width - 16

        $LegacyGUIbuttonStart.Location = [System.Drawing.Point]::new(($LegacyGUIform.ClientSize.Width - $LegacyGUIbuttonStop.Width - $LegacyGUIbuttonPause.Width - $LegacyGUIbuttonStart.Width - 40), 2)
        $LegacyGUIbuttonPause.Location = [System.Drawing.Point]::new(($LegacyGUIform.ClientSize.Width - $LegacyGUIbuttonStop.Width - $LegacyGUIbuttonPause.Width - 30), 2)
        $LegacyGUIbuttonStop.Location  = [System.Drawing.Point]::new(($LegacyGUIform.ClientSize.Width - $LegacyGUIbuttonStop.Width - 20), 2)

        # $LegacyGUIeditMonitoringLink.Location = [System.Drawing.Point]::new(($LegacyGUItabControl.Width - $LegacyGUIeditMonitoringLink.Width - 12), 6)
        $LegacyGUIminingSummaryLabel.Width = $LegacyGUIactiveMinersDGV.Width = $LegacyGUIearningsChart.Width = $LegacyGUIbalancesDGV.Width = $LegacyGUIminersPanel.Width = $LegacyGUIminersDGV.Width = $LegacyGUIpoolsPanel.Width = $LegacyGUIpoolsDGV.Width = $LegacyGUIswitchingDGV.Width = $LegacyGUIwatchdogTimersDGV.Width = $LegacyGUIform.ClientSize.Width - 44
        $Variables.TextBoxSystemLog.Width = $LegacyGUItabControl.ClientSize.Width - 20

        $LegacyGUIeditConfigLink.Location = [System.Drawing.Point]::new(18, ($LegacyGUIform.ClientSize.Height - $LegacyGUIeditConfigLink.Height - 4))
        $LegacyGUIcopyrightLabel.Location = [System.Drawing.Point]::new(($LegacyGUItabControl.ClientSize.Width - $LegacyGUIcopyrightLabel.Width - 4), ($LegacyGUIform.ClientSize.Height - $LegacyGUIeditConfigLink.Height - 4))

        If ($Config.BalancesTrackerPollInterval -gt 0 -and $LegacyGUIbalancesDGV.RowCount -gt 0) { 
            $LegacyGUIbalancesLabel.Visible = $true
            $LegacyGUIbalancesDGV.Visible = $true

            $LegacyGUIbalancesDGVHeight = $LegacyGUIbalancesDGV.RowTemplate.Height * $LegacyGUIbalancesDGV.RowCount + $LegacyGUIbalancesDGV.ColumnHeadersHeight
            If ($LegacyGUIbalancesDGVHeight -gt $LegacyGUItabControl.ClientSize.Height / 2) { 
                $LegacyGUIbalancesDGVHeight = $LegacyGUItabControl.ClientSize.Height / 2
                $LegacyGUIbalancesDGV.ScrollBars = "Vertical"
            }
            Else { 
                $LegacyGUIbalancesDGV.ScrollBars = "None"
            }
            $LegacyGUIbalancesDGV.Height = $LegacyGUIbalancesDGVHeight
            $LegacyGUIearningsChart.Height = $LegacyGUItabControl.ClientSize.Height - $LegacyGUIbalancesDGV.Height - $LegacyGUIbalancesLabel.Height - 56
            $LegacyGUIbalancesLabel.Location = [System.Drawing.Point]::new(0, $LegacyGUIearningsChart.Bottom)
            $LegacyGUIbalancesDGV.Top = $LegacyGUIbalancesLabel.Bottom
        }
        Else { 
            $LegacyGUIbalancesLabel.Visible = $false
            $LegacyGUIbalancesDGV.Visible = $false
            $LegacyGUIearningsChart.Height = $LegacyGUItabControl.ClientSize.Height - 24
        }

        $LegacyGUIactiveMinersDGVHeight = $LegacyGUIactiveMinersDGV.RowTemplate.Height * $LegacyGUIactiveMinersDGV.RowCount + $LegacyGUIactiveMinersDGV.ColumnHeadersHeight
        If ($LegacyGUIactiveMinersDGVHeight -gt $LegacyGUItabControl.ClientSize.Height / 2) { 
            $LegacyGUIactiveMinersDGVHeight = $LegacyGUItabControl.ClientSize.Height / 2
        }
        $LegacyGUIactiveMinersDGV.Height = $LegacyGUIactiveMinersDGVHeight

        $LegacyGUIsystemLogLabel.Location = [System.Drawing.Point]::new(0, ($LegacyGUIactiveMinersLabel.Height + $LegacyGUIactiveMinersDGV.Height + 30))
        $Variables.TextBoxSystemLog.Location = [System.Drawing.Point]::new(0, ($LegacyGUIactiveMinersLabel.Height + $LegacyGUIactiveMinersDGV.Height + $LegacyGUIsystemLogLabel.Height + 36))
        $Variables.TextBoxSystemLog.Height = ($LegacyGUItabControl.ClientSize.Height - $LegacyGUIactiveMinersLabel.Height - $LegacyGUIactiveMinersDGV.Height - $LegacyGUIsystemLogLabel.Height - 95)
        If (-not $Variables.TextBoxSystemLog.SelectionLength) { 
            $Variables.TextBoxSystemLog.ScrollToCaret()
        }

        $LegacyGUIminersDGV.Height = $LegacyGUItabControl.ClientSize.Height - $LegacyGUIminersLabel.Height - $LegacyGUIminersPanel.Height - 74
        $LegacyGUIpoolsDGV.Height = $LegacyGUItabControl.ClientSize.Height - $LegacyGUIpoolsLabel.Height - $LegacyGUIpoolsPanel.Height - 74
        # $LegacyGUIworkersDGV.Height = $LegacyGUItabControl.ClientSize.Height - $LegacyGUIworkersLabel.Height - 74
        $LegacyGUIswitchingDGV.Height = $LegacyGUItabControl.ClientSize.Height - $LegacyGUIswitchingLogLabel.Height - $LegacyGUIswitchingLogClearButton.Height - 78
        $LegacyGUIwatchdogTimersDGV.Height = $LegacyGUItabControl.ClientSize.Height - $LegacyGUIwatchdogTimersLabel.Height - $LegacyGUIwatchdogTimersRemoveButton.Height - 78
    }
    Catch { 
        Start-Sleep 0
    }
}

Function CheckBoxSwitching_Click { 
    $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $LegacyGUIswitchingDGV.ClearSelection()

    $SwitchingDisplayTypes = @()
    $LegacyGUIswitchingPageControls.ForEach({ If ($_.Checked) { $SwitchingDisplayTypes += $_.Tag } })
    If (Test-Path -LiteralPath ".\Logs\SwitchingLog.csv" -PathType Leaf) { 
        $LegacyGUIswitchingLogLabel.Text = "Switching log updated $((Get-ChildItem -Path ".\Logs\SwitchingLog.csv").LastWriteTime.ToString())"
        $LegacyGUIswitchingDGV.DataSource = (([System.IO.File]::ReadAllLines("$PWD\Logs\SwitchingLog.csv") | ConvertFrom-Csv).Where({ $SwitchingDisplayTypes -contains $_.Type }) | Select-Object -Last 1000).ForEach({ $_.Datetime = (Get-Date $_.DateTime); $_ }) | Sort-Object -Property DateTime -Descending | Select-Object @("DateTime", "Action", "Name", "Pools", "Algorithms", "Accounts", "Cycle", "Duration", "DeviceNames", "Type") | Out-DataTable
        If ($LegacyGUIswitchingDGV.Columns) { 
            $LegacyGUIswitchingDGV.Columns[0].FillWeight = 50; $LegacyGUIswitchingDGV.Sort($LegacyGUIswitchingDGV.Columns[0], [System.ComponentModel.ListSortDirection]::Descending)
            $LegacyGUIswitchingDGV.Columns[1].FillWeight = 50
            $LegacyGUIswitchingDGV.Columns[2].FillWeight = 90; $LegacyGUIswitchingDGV.Columns[2].HeaderText = "Miner"
            $LegacyGUIswitchingDGV.Columns[3].FillWeight = 60 + ($LegacyGUIswitchingDGV.MinersBest_Combo.ForEach({ $_.Pools.Count }) | Measure-Object -Maximum).Maximum * 40; $LegacyGUIswitchingDGV.Columns[3].HeaderText = "Pool(s)"
            $LegacyGUIswitchingDGV.Columns[4].FillWeight = 50 + ($LegacyGUIswitchingDGV.MinersBest_Combo.ForEach({ $_.Algorithms.Count }) | Measure-Object -Maximum).Maximum * 25; $LegacyGUIswitchingDGV.Columns[4].HeaderText = "Algorithm(s) (variant)"
            $LegacyGUIswitchingDGV.Columns[5].FillWeight = 90 + ($LegacyGUIswitchingDGV.MinersBest_Combo.ForEach({ $_.Accounts.Count }) | Measure-Object -Maximum).Maximum * 50; $LegacyGUIswitchingDGV.Columns[5].HeaderText = "Account(s)"
            $LegacyGUIswitchingDGV.Columns[6].FillWeight = 30; $LegacyGUIswitchingDGV.Columns[6].HeaderText = "Cycles"; $LegacyGUIswitchingDGV.Columns[6].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIswitchingDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"
            $LegacyGUIswitchingDGV.Columns[7].FillWeight = 35; $LegacyGUIswitchingDGV.Columns[7].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIswitchingDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"
            $LegacyGUIswitchingDGV.Columns[8].FillWeight = 30 + ($LegacyGUIswitchingDGV.MinersBest_Combo.ForEach({ $_.DeviceNames.Count }) | Measure-Object -Maximum).Maximum * 15; $LegacyGUIswitchingDGV.Columns[8].HeaderText = "Device(s)"
            $LegacyGUIswitchingDGV.Columns[9].FillWeight = 30
            $LegacyGUIswitchingLogClearButton.Enabled = $true
        }
        $LegacyGUIswitchingDGV.EndInit()
    }
    Else { 
        $LegacyGUIswitchingLogLabel.Text = "Waiting for switching log data..."
        $LegacyGUIswitchingLogClearButton.Enabled = $false
    }
    If ($Config.UseColorForMinerStatus) { 
        ForEach ($Row in $LegacyGUIswitchingDGV.Rows) { $Row.DefaultCellStyle.Backcolor = $LegacyGUIcolors[$Row.DataBoundItem.Action] }
    }
    $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
}

Function Set-DataGridViewDoubleBuffer { 

    Param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.DataGridView]$Grid,
        [Parameter(Mandatory = $true)]
        [Boolean]$Enabled
    )

    $Type = $Grid.GetType();
    $PropInfo = $Type.GetProperty("DoubleBuffered", ("Instance", "NonPublic"))
    $PropInfo.SetValue($Grid, $Enabled, $null)
}

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

# Function Set-WorkerColor { 
#     If ($Config.UseColorForMinerStatus) { 
#         ForEach ($Row in $LegacyGUIworkersDGV.Rows) { 
#             $Row.DefaultCellStyle.Backcolor = Switch ($Row.DataBoundItem.Status) { 
#                 "Offline" { $LegacyGUIcolors["disabled"]; Break }
#                 "Paused"  { $LegacyGUIcolors["idle"]; Break }
#                 "Running" { $LegacyGUIcolors["running"]; Break }
#                 Default   { [System.Drawing.Color]::FromArgb(255, 255, 255, 255) }
#             }
#         }
#     }
# }

Function Update-TabControl { 

    Switch ($LegacyGUItabControl.SelectedTab.Text) { 
        "System status" { 
            $LegacyGUIactiveMinersDGV.ClearSelection()

            $LegacyGUIcontextMenuStripItem1.Text = "Re-benchmark miner"
            $LegacyGUIcontextMenuStripItem1.Visible = $true
            $LegacyGUIcontextMenuStripItem2.Enabled = $Config.CalculatePowerCost
            $LegacyGUIcontextMenuStripItem2.Text = "Re-measure power consumption"
            $LegacyGUIcontextMenuStripItem2.Visible = $true
            $LegacyGUIcontextMenuStripItem3.Enabled = $true
            $LegacyGUIcontextMenuStripItem3.Text = "Mark miner as failed"
            $LegacyGUIcontextMenuStripItem4.Enabled = $true
            $LegacyGUIcontextMenuStripItem4.Text = "Disable miner"
            $LegacyGUIcontextMenuStripItem4.Visible = $true
            $LegacyGUIcontextMenuStripItem5.Enabled = $true
            $LegacyGUIcontextMenuStripItem5.Text = "Enable miner"
            $LegacyGUIcontextMenuStripItem5.Visible = $true
            $LegacyGUIcontextMenuStripItem6.Visible = $false

            If ($Variables.NewMiningStatus -eq "Idle") { 
                $LegacyGUIactiveMinersLabel.Text = "No miners running - mining is stopped"
                $LegacyGUIactiveMinersDGV.DataSource = $null
            }
            ElseIf ($Variables.NewMiningStatus -eq "Paused") { 
                $LegacyGUIactiveMinersLabel.Text = "No miners running - mining is paused"
                $LegacyGUIactiveMinersDGV.DataSource = $null
            }
            ElseIf ($Variables.NewMiningStatus -eq "Running" -and $Variables.MiningStatus -eq "Running" -and $Global:CoreRunspace.Job.IsCompleted -eq $true) { 
                $LegacyGUIactiveMinersLabel.Text = "No data - mining is suspended"
                $LegacyGUIactiveMinersDGV.DataSource = $null
            }
            ElseIf ($Variables.MinersBest) { 
                If (-not $LegacyGUIactiveMinersDGV.SelectedRows) { 
                    $LegacyGUIactiveMinersDGV.BeginInit()
                    $LegacyGUIactiveMinersDGV.ClearSelection()
                    $LegacyGUIactiveMinersDGV.DataSource = $Variables.MinersBest | Select-Object @(
                        @{ Name = "Info"; Expression = { $_.Info } }
                        @{ Name = "SubStatus"; Expression = { $_.SubStatus } }
                        @{ Name = "Device(s)"; Expression = { $_.BaseName_Version_Device -replace ".+-" } }
                        @{ Name = "Status Info"; Expression = { $_.StatusInfo } }
                        @{ Name = "Earnings (biased) $($Config.FIATcurrency)/day"; Expression = { If ([Double]::IsNaN($_.Earnings)) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Earnings * $Variables.Rates.BTC.($Config.FIATcurrency)) } } }
                        @{ Name = "Power cost $($Config.FIATcurrency)/day"; Expression = { If ([Double]::IsNaN($_.PowerCost) -or -not $Variables.CalculatePowerCost) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Powercost * $Variables.Rates.BTC.($Config.FIATcurrency)) } } }
                        @{ Name = "Profit (biased) $($Config.FIATcurrency)/day"; Expression = { If ([Double]::IsNaN($_.PowerCost) -or -not $Variables.CalculatePowerCost) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Profit * $Variables.Rates.BTC.($Config.FIATcurrency)) } } }
                        @{ Name = "Power consumption (live)"; Expression = { If ($_.MeasurePowerConsumption) { If ($_.Status -eq "Running") { "Measuring..." } Else { "Unmeasured" } } Else { If ([Double]::IsNaN($_.PowerConsumption_Live)) { "n/a" } Else { "$($_.PowerConsumption_Live.ToString("N2")) W" } } } }
                        @{ Name = "Algorithm (variant) [Currency]"; Expression = { $_.WorkersRunning.ForEach({ "$($_.Pool.AlgorithmVariant)$(If ($_.Pool.Currency) { "[$($_.Pool.Currency)]" })" }) -join " & " } },
                        @{ Name = "Pool"; Expression = { $_.WorkersRunning.Pool.Name -join " & " } }
                        @{ Name = "Hashrate (live)"; Expression = { If ($_.Benchmark) { If ($_.Status -eq "Running") { "Benchmarking..." } Else { "Benchmark pending" } } Else { $_.WorkersRunning.ForEach({ $_.Hashrates_Live | ConvertTo-Hash }) -join " & " } } }
                        @{ Name = "Running time (hhh:mm:ss)"; Expression = { "{0}:{1:mm}:{1:ss}" -f [Math]::floor(([DateTime]::Now.ToUniversalTime() - $_.BeginTime).TotalDays * 24), ([DateTime]::Now.ToUniversalTime() - $_.BeginTime) } }
                        @{ Name = "Total active (hhh:mm:ss)"; Expression = { "{0}:{1:mm}:{1:ss}" -f [Math]::floor($_.TotalMiningDuration.TotalDays * 24), $_.TotalMiningDuration } }
                    ) | Out-DataTable
                    $LegacyGUIactiveMinersDGV.Sort($LegacyGUIactiveMinersDGV.Columns[2], [System.ComponentModel.ListSortDirection]::Ascending)
                    $LegacyGUIactiveMinersDGV.ClearSelection()
                    $LegacyGUIactiveMinersLabel.Text = "Active miners updated $($Variables.MinersUpdatedTimestamp.ToLocalTime().ToString("G")) ($($LegacyGUIactiveMinersDGV.Rows.count) miner$(If ($LegacyGUIactiveMinersDGV.Rows.count -ne 1) { "s" }))"

                    $LegacyGUIactiveMinersDGV.Columns[0].Visible = $false
                    $LegacyGUIactiveMinersDGV.Columns[1].Visible = $false
                    If (-not $LegacyGUIactiveMinersDGV.ColumnWidthChanged -and $LegacyGUIactiveMinersDGV.Columns) { 
                        $LegacyGUIactiveMinersDGV.Columns[2].FillWeight = 45 + ($Variables.MinersBest.ForEach({ $_.DeviceNames.Count }) | Measure-Object -Maximum).Maximum * 20
                        $LegacyGUIactiveMinersDGV.Columns[3].FillWeight = 190
                        $LegacyGUIactiveMinersDGV.Columns[4].FillWeight = 55; $LegacyGUIactiveMinersDGV.Columns[4].DefaultCellStyle.Alignment = $LegacyGUIactiveMinersDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIactiveMinersDGV.Columns[5].FillWeight = 55; $LegacyGUIactiveMinersDGV.Columns[5].DefaultCellStyle.Alignment = $LegacyGUIactiveMinersDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIactiveMinersDGV.Columns[5].Visible = $Variables.CalculatePowerCost
                        $LegacyGUIactiveMinersDGV.Columns[6].FillWeight = 55; $LegacyGUIactiveMinersDGV.Columns[6].DefaultCellStyle.Alignment = $LegacyGUIactiveMinersDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIactiveMinersDGV.Columns[6].Visible = $Variables.CalculatePowerCost
                        $LegacyGUIactiveMinersDGV.Columns[7].FillWeight = 55; $LegacyGUIactiveMinersDGV.Columns[7].DefaultCellStyle.Alignment = $LegacyGUIactiveMinersDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIactiveMinersDGV.Columns[7].Visible = $Variables.CalculatePowerCost
                        $LegacyGUIactiveMinersDGV.Columns[8].FillWeight = 60 + ($Variables.MinersBest.ForEach({ $_.Workers.Count }) | Measure-Object -Maximum).Maximum * 30
                        $LegacyGUIactiveMinersDGV.Columns[9].FillWeight = 45 + ($Variables.MinersBest.ForEach({ $_.Workers.Count }) | Measure-Object -Maximum).Maximum * 25
                        $LegacyGUIactiveMinersDGV.Columns[10].FillWeight = 45 + ($Variables.MinersBest.ForEach({ $_.Workers.Count }) | Measure-Object -Maximum).Maximum * 25; $LegacyGUIactiveMinersDGV.Columns[10].DefaultCellStyle.Alignment = $LegacyGUIactiveMinersDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIactiveMinersDGV.Columns[11].FillWeight = 50; $LegacyGUIactiveMinersDGV.Columns[11].DefaultCellStyle.Alignment = $LegacyGUIactiveMinersDGV.Columns[11].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIactiveMinersDGV.Columns[12].FillWeight = 50; $LegacyGUIactiveMinersDGV.Columns[12].DefaultCellStyle.Alignment = $LegacyGUIactiveMinersDGV.Columns[12].HeaderCell.Style.Alignment = "MiddleRight"

                        $LegacyGUIactiveMinersDGV | Add-Member ColumnWidthChanged $true -Force
                    }
                    $LegacyGUIactiveMinersDGV.EndInit()
                    Set-TableColor -DataGridView $LegacyGUIactiveMinersDGV
                }
            }
            Else { 
                $LegacyGUIactiveMinersLabel.Text = "Waiting for active miner data..."
                $LegacyGUIactiveMinersDGV.DataSource = $null
            }
            Resize-Form # To fully show grid
            Break
        }
        "Earnings and balances" { 
            $LegacyGUIbalancesDGV.ClearSelection()

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

                    $ChartTitle = [System.Windows.Forms.DataVisualization.Charting.Title]::new()
                    $ChartTitle.Alignment = "TopCenter"
                    $ChartTitle.Font = [System.Drawing.Font]::new("Arial", 10)
                    $ChartTitle.Text = "Earnings of the past $($DataSource.Labels.Count) active days"
                    $LegacyGUIearningsChart.Titles.Clear()
                    $LegacyGUIearningsChart.Titles.Add($ChartTitle)

                    $ChartArea = [System.Windows.Forms.DataVisualization.Charting.ChartArea]::new()
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
                    $ChartArea.AxisY.Title = $Config.FIATcurrency
                    $ChartArea.AxisY.ToolTip = "Total earnings per day"
                    $ChartArea.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255) #"#2B3232" 
                    $ChartArea.BackGradientStyle = 3
                    $ChartArea.BackSecondaryColor = [System.Drawing.Color]::FromArgb(255, 224, 224, 224) #"#777E7E"

                    $LegacyGUIearningsChart.ChartAreas.Clear()
                    $LegacyGUIearningsChart.ChartAreas.Add($ChartArea)
                    $LegacyGUIearningsChart.Series.Clear()

                    $DaySum = @(0) * $DataSource.Labels.Count
                    $LegacyGUItooltipText = $DataSource.Labels.Clone()

                    $Color = @(255, 255, 255, 255) #"FFFFFF"
                    ForEach ($Pool in $DataSource.Earnings.PSObject.Properties.Name) { 

                        $Color = (Get-NextColor -Color $Color -Factors -0, -20, -20, -20)

                        $LegacyGUIearningsChart.Series.Add($Pool)
                        $LegacyGUIearningsChart.Series[$Pool].ChartType = "StackedColumn"
                        $LegacyGUIearningsChart.Series[$Pool].BorderWidth = 3
                        $LegacyGUIearningsChart.Series[$Pool].Color = [System.Drawing.Color]::FromArgb($Color[0], $Color[1], $Color[2], $Color[3])

                        $I = 0
                        $Datasource.Earnings.$Pool.ForEach(
                            { 
                                $_ *= $Variables.Rates.BTC.($Config.FIATcurrency)
                                $LegacyGUIearningsChart.Series[$Pool].Points.addxy(0, $_) | Out-Null
                                $Daysum[$I] += $_
                                If ($_) { $LegacyGUItooltipText[$I] = "$($LegacyGUItooltipText[$I])`r$($Pool): {0:N$($Config.DecimalsMax)} $($Config.FIATcurrency)" -f $_ }
                                $I ++
                            }
                        )
                    }
                    Remove-Variable Pool

                    $I = 0
                    $DataSource.Labels.ForEach(
                        { 
                            $ChartArea.AxisX.CustomLabels.Add($I +0.5, $I + 1.5, " $_ ")
                            $ChartArea.AxisX.CustomLabels[$I].ToolTip = "$($LegacyGUItooltipText[$I])`rTotal: {0:N$($Config.DecimalsMax)} $($Config.FIATcurrency)" -f $Daysum[$I]
                            ForEach ($Pool in $DataSource.Earnings.PSObject.Properties.Name) { 
                                If ($Datasource.Earnings.$Pool[$I]) { $LegacyGUIearningsChart.Series[$Pool].Points[$I].ToolTip = "$($LegacyGUItooltipText[$I])`rTotal: {0:N$($Config.DecimalsMax)} $($Config.FIATcurrency)" -f $Daysum[$I] }
                            }
                            $I ++
                        }
                    )
                    $ChartArea.AxisY.Maximum = ($DaySum | Measure-Object -Maximum).Maximum * 1.05
                }
                Catch { }
            }
            If ($Config.BalancesTrackerPollInterval -gt 0) { 
                $LegacyGUIbalancesLabel.Text = "Balances updated $(($Variables.Balances.Values.LastUpdated | Sort-Object -Bottom 1).ToLocalTime().ToString())"
                If ($Variables.Balances) { 
                    If (-not $LegacyGUIbalancesDGV.SelectedRows) { 
                        $LegacyGUIbalancesDGV.BeginInit()
                        $LegacyGUIbalancesDGV.DataSource = $Variables.Balances.Values | Select-Object @(
                            @{ Name = "Currency"; Expression = { $_.Currency } },
                            @{ Name = "Pool [Currency]"; Expression = { "$($_.Pool) [$($_.Currency)]" } },
                            @{ Name = "Balance ($($Config.FIATcurrency))"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Balance * $Variables.Rates.($_.Currency).($Config.FIATcurrency)) } },
                            @{ Name = "$($Config.FIATcurrency) in past 1 hr"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth1 * $Variables.Rates.($_.Currency).($Config.FIATcurrency)) } },
                            @{ Name = "$($Config.FIATcurrency) in past 6 hrs"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth6 * $Variables.Rates.($_.Currency).($Config.FIATcurrency)) } },
                            @{ Name = "$($Config.FIATcurrency) in past 24 hrs"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth24 * $Variables.Rates.($_.Currency).($Config.FIATcurrency)) } },
                            @{ Name = "$($Config.FIATcurrency) in past 7 days"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth168 * $Variables.Rates.($_.Currency).($Config.FIATcurrency)) } },
                            @{ Name = "$($Config.FIATcurrency) in past 30 days"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth720 * $Variables.Rates.($_.Currency).($Config.FIATcurrency)) } },
                            @{ Name = "Avg. $($Config.FIATcurrency)/1 hr"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.AvgHourlyGrowth * $Variables.Rates.($_.Currency).($Config.FIATcurrency)) } },
                            @{ Name = "Avg. $($Config.FIATcurrency)/24 hrs"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.AvgDailyGrowth * $Variables.Rates.($_.Currency).($Config.FIATcurrency)) } },
                            @{ Name = "Avg. $($Config.FIATcurrency)/7 days"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.AvgWeeklyGrowth * $Variables.Rates.($_.Currency).($Config.FIATcurrency)) } },
                            @{ Name = "Projected pay date"; Expression = { If ($_.ProjectedPayDate -is [DateTime]) { $_.ProjectedPayDate.ToShortDateString() } Else { $_.ProjectedPayDate } } },
                            @{ Name = "Payout threshold"; Expression = { If ($_.PayoutThresholdCurrency -eq "BTC" -and $Config.UsemBTC) { $PayoutThresholdCurrency = "mBTC"; $mBTCfactor = 1000 } Else { $PayoutThresholdCurrency = $_.PayoutThresholdCurrency; $mBTCfactor = 1 }; "{0:P2} of {1} {2} " -f ($_.Balance / $_.PayoutThreshold * $Variables.Rates.($_.Currency).($_.PayoutThresholdCurrency)), [String]($_.PayoutThreshold * $mBTCfactor), $PayoutThresholdCurrency } } # Cast to string to avoid extra decimal places
                        ) | Out-DataTable
                        $LegacyGUIbalancesDGV.Sort($LegacyGUIbalancesDGV.Columns[1], [System.ComponentModel.ListSortDirection]::Ascending)
                        $LegacyGUIbalancesDGV.ClearSelection()

                        If ($LegacyGUIbalancesDGV.Columns) { 
                            $LegacyGUIbalancesDGV.Columns[0].Visible = $false
                            $LegacyGUIbalancesDGV.Columns[1].FillWeight = 120
                            $LegacyGUIbalancesDGV.Columns[2].FillWeight = 70; $LegacyGUIbalancesDGV.Columns[2].DefaultCellStyle.Alignment = $LegacyGUIbalancesDGV.Columns[2].HeaderCell.Style.Alignment = "MiddleRight"
                            $LegacyGUIbalancesDGV.Columns[3].FillWeight = 70; $LegacyGUIbalancesDGV.Columns[3].DefaultCellStyle.Alignment = $LegacyGUIbalancesDGV.Columns[3].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIbalancesDGV.Columns[3].Visible = $Config.BalancesShowSums
                            $LegacyGUIbalancesDGV.Columns[4].FillWeight = 70; $LegacyGUIbalancesDGV.Columns[4].DefaultCellStyle.Alignment = $LegacyGUIbalancesDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIbalancesDGV.Columns[4].Visible = $Config.BalancesShowSums
                            $LegacyGUIbalancesDGV.Columns[5].FillWeight = 70; $LegacyGUIbalancesDGV.Columns[5].DefaultCellStyle.Alignment = $LegacyGUIbalancesDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIbalancesDGV.Columns[5].Visible = $Config.BalancesShowSums
                            $LegacyGUIbalancesDGV.Columns[6].FillWeight = 70; $LegacyGUIbalancesDGV.Columns[6].DefaultCellStyle.Alignment = $LegacyGUIbalancesDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIbalancesDGV.Columns[6].Visible = $Config.BalancesShowSums
                            $LegacyGUIbalancesDGV.Columns[7].FillWeight = 70; $LegacyGUIbalancesDGV.Columns[7].DefaultCellStyle.Alignment = $LegacyGUIbalancesDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIbalancesDGV.Columns[7].Visible = $Config.BalancesShowSums
                            $LegacyGUIbalancesDGV.Columns[8].FillWeight = 70; $LegacyGUIbalancesDGV.Columns[8].DefaultCellStyle.Alignment = $LegacyGUIbalancesDGV.Columns[8].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIbalancesDGV.Columns[8].Visible = $Config.BalancesShowAverages
                            $LegacyGUIbalancesDGV.Columns[9].FillWeight = 70; $LegacyGUIbalancesDGV.Columns[9].DefaultCellStyle.Alignment = $LegacyGUIbalancesDGV.Columns[9].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIbalancesDGV.Columns[9].Visible = $Config.BalancesShowAverages
                            $LegacyGUIbalancesDGV.Columns[10].FillWeight = 70; $LegacyGUIbalancesDGV.Columns[10].DefaultCellStyle.Alignment = $LegacyGUIbalancesDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIbalancesDGV.Columns[10].Visible = $Config.BalancesShowAverages
                            $LegacyGUIbalancesDGV.Columns[11].FillWeight = 80
                            $LegacyGUIbalancesDGV.Columns[12].FillWeight = 80
                        }
                        $LegacyGUIbalancesDGV.Rows.ForEach(
                            { 
                                $_.Cells[2].ToolTipText = "Balance {0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) })" -f ([Double]$_.Cells[2].Value * $Variables.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                                $_.Cells[3].ToolTipText = "{0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) }) in past 1hr" -f ([Double]$_.Cells[3].Value * $Variables.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                                $_.Cells[4].ToolTipText = "{0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) }) in past 6hr" -f ([Double]$_.Cells[4].Value * $Variables.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                                $_.Cells[5].ToolTipText = "{0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) }) in past 24hr" -f ([Double]$_.Cells[5].Value * $Variables.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                                $_.Cells[6].ToolTipText = "{0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) }) in past 7days" -f ([Double]$_.Cells[6].Value * $Variables.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                                $_.Cells[7].ToolTipText = "{0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) }) in past 30days" -f ([Double]$_.Cells[7].Value * $Variables.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                                $_.Cells[8].ToolTipText = "Avg. {0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) }) / 1 hr" -f ([Double]$_.Cells[8].Value * $Variables.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                                $_.Cells[9].ToolTipText = "Avg. {0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) }) / 24 hrs" -f ([Double]$_.Cells[9].Value * $Variables.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                                $_.Cells[10].ToolTipText = "Avg. {0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) }) / 7 days" -f ([Double]$_.Cells[10].Value * $Variables.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                            }
                        )
                        Resize-Form # To fully show grid
                        $LegacyGUIbalancesDGV.EndInit()
                    }
                }
                Else { 
                    $LegacyGUIbalancesLabel.Text = "Waiting for balances data..."
                    $LegacyGUIbalancesDGV.DataSource = $null
                }
            }
            Else { 
                $LegacyGUIbalancesLabel.Text = "Balances tracker is disabled (Configuration item 'BalancesTrackerPollInterval' -eq 0)"
            }
            Break
        }
        "Miners" { 
            $LegacyGUIminersDGV.ClearSelection()

            $LegacyGUIcontextMenuStripItem1.Text = "Re-benchmark miner"
            $LegacyGUIcontextMenuStripItem1.Visible = $true
            $LegacyGUIcontextMenuStripItem2.Enabled = $Config.CalculatePowerCost
            $LegacyGUIcontextMenuStripItem2.Text = "Re-measure power consumption"
            $LegacyGUIcontextMenuStripItem2.Visible = $true
            $LegacyGUIcontextMenuStripItem3.Enabled = $true
            $LegacyGUIcontextMenuStripItem3.Text = "Mark miner as failed"
            $LegacyGUIcontextMenuStripItem4.Enabled = $true
            $LegacyGUIcontextMenuStripItem4.Text = "Disable miner"
            $LegacyGUIcontextMenuStripItem4.Visible = $true
            $LegacyGUIcontextMenuStripItem5.Enabled = $true
            $LegacyGUIcontextMenuStripItem5.Text = "Enable miner"
            $LegacyGUIcontextMenuStripItem5.Visible = $true
            $LegacyGUIcontextMenuStripItem6.Enabled = $Variables.WatchdogTimers
            $LegacyGUIcontextMenuStripItem6.Text = "Remove watchdog timer"
            $LegacyGUIcontextMenuStripItem6.Visible = $true

            If ($LegacyGUIradioButtonMinersOptimal.checked) { $DataSource = $Variables.MinersOptimal }
            ElseIf ($LegacyGUIradioButtonMinersUnavailable.checked) { $DataSource = $Variables.Miners.Where({ -not $_.Available }) | Sort-Object { $_.BaseName_Version_Device -replace ".+-" }, Info }
            Else { $DataSource = $Variables.Miners }

            If ($Variables.NewMiningStatus -eq "Idle") { 
                $LegacyGUIminersLabel.Text = "No data - mining is stopped"
                $LegacyGUIminersDGV.DataSource = $null
            }
            ElseIf ($Variables.NewMiningStatus -eq "Paused" -and -not $DataSource) { 
                $LegacyGUIminersLabel.Text = "No data - mining is paused"
                $LegacyGUIminersDGV.DataSource = $null
            }
            ElseIf ($Variables.NewMiningStatus -eq "Running" -and $Variables.MiningStatus -eq "Running" -and -not $Variables.Miners -and $Global:CoreRunspace.Job.IsCompleted -eq $true) { 
                $LegacyGUIminersLabel.Text = "No data - mining is suspended"
                $LegacyGUIminersDGV.DataSource = $null
            }
            ElseIf ($Variables.Miners) { 
                If (-not $LegacyGUIminersDGV.SelectedRows) { 
                    $LegacyGUIminersDGV.BeginInit()

                    $LegacyGUIminersDGV.DataSource = $DataSource | Select-Object @(
                        @{ Name = "Info"; Expression = { $_.Info } }
                        @{ Name = "SubStatus"; Expression = { $_.SubStatus } },
                        @{ Name = "Miner"; Expression = { $_.Name } },
                        @{ Name = "Device(s)"; Expression = { $_.BaseName_Version_Device -replace ".+-" } },
                        @{ Name = "Status"; Expression = { $_.Status } },
                        @{ Name = "Earnings (biased) $($Config.FIATcurrency)/day"; Expression = { If ([Double]::IsNaN($_.Earnings_Bias)) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Earnings * $Variables.Rates.BTC.($Config.FIATcurrency)) } } },
                        @{ Name = "Power cost $($Config.FIATcurrency)/day"; Expression = { If ( [Double]::IsNaN($_.PowerCost)) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Powercost * $Variables.Rates.BTC.($Config.FIATcurrency)) } } },
                        @{ Name = "Profit (biased) $($Config.FIATcurrency)/day"; Expression = { If ([Double]::IsNaN($_.Profit_Bias) -or -not $Variables.CalculatePowerCost) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Profit * $Variables.Rates.BTC.($Config.FIATcurrency)) } } },
                        @{ Name = "Power consumption"; Expression = { If ($_.MeasurePowerConsumption) { If ($_.Status -eq "Running") { "Measuring..." } Else { "Unmeasured" } } Else { If ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } Else { "$($_.PowerConsumption.ToString("N2")) W" } } } }
                        @{ Name = "Algorithm (variant)"; Expression = { $_.Workers.Pool.AlgorithmVariant -join " & " } },
                        @{ Name = "Pool"; Expression = { $_.Workers.Pool.Name -join " & " } },
                        @{ Name = "Hashrate"; Expression = { If ($_.Benchmark) { If ($_.Status -eq "Running") { "Benchmarking..." } Else { "Benchmark pending" } } Else { $_.Workers.ForEach({ $_.Hashrate | ConvertTo-Hash }) -join " & " } } }
                        If ($LegacyGUIradioButtonMinersUnavailable.checked -or $LegacyGUIradioButtonMiners.checked) { @{ Name = "Reason(s)"; Expression = { $_.Reasons -join ", " } } }
                    ) | Out-DataTable
                    $LegacyGUIminersDGV.ClearSelection()
                    $LegacyGUIminersLabel.Text = "Miner data updated $($Variables.MinersUpdatedTimestamp.ToLocalTime().ToString("G")) ($($LegacyGUIminersDGV.Rows.count) miner$(If ($LegacyGUIminersDGV.Rows.count -ne 1) { "s" }))"

                    $LegacyGUIminersDGV.Columns[0].Visible = $false
                    $LegacyGUIminersDGV.Columns[1].Visible = $false
                    If (-not $LegacyGUIminersDGV.ColumnWidthChanged -and $LegacyGUIminersDGV.Columns) { 
                        $LegacyGUIminersDGV.Columns[2].FillWeight = 160
                        $LegacyGUIminersDGV.Columns[3].FillWeight = 35 + ($DataSource.ForEach({ $_.DeviceNames.Count }) | Measure-Object -Maximum).Maximum * 15
                        $LegacyGUIminersDGV.Columns[4].FillWeight = 40; $LegacyGUIminersDGV.Columns[4].Visible = -not $LegacyGUIradioButtonMinersUnavailable.checked
                        $LegacyGUIminersDGV.Columns[5].FillWeight = 40; $LegacyGUIminersDGV.Columns[5].DefaultCellStyle.Alignment = $LegacyGUIminersDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIminersDGV.Columns[6].FillWeight = 40; $LegacyGUIminersDGV.Columns[6].DefaultCellStyle.Alignment = $LegacyGUIminersDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIminersDGV.Columns[6].Visible = $Variables.CalculatePowerCost
                        $LegacyGUIminersDGV.Columns[7].FillWeight = 40; $LegacyGUIminersDGV.Columns[7].DefaultCellStyle.Alignment = $LegacyGUIminersDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIminersDGV.Columns[7].Visible = $Variables.CalculatePowerCost
                        $LegacyGUIminersDGV.Columns[8].FillWeight = 40; $LegacyGUIminersDGV.Columns[8].DefaultCellStyle.Alignment = $LegacyGUIminersDGV.Columns[8].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIminersDGV.Columns[8].Visible = $Variables.CalculatePowerCost
                        $LegacyGUIminersDGV.Columns[9].FillWeight = If ($LegacyGUIminersDGV.DataSource.Pool -like "* & ") { 90 } Else { 60 }
                        $LegacyGUIminersDGV.Columns[10].FillWeight = If ($LegacyGUIminersDGV.DataSource.Pool -like "* & ") { 85 } Else { 60 }
                        $LegacyGUIminersDGV.Columns[11].FillWeight = If ($LegacyGUIminersDGV.DataSource.Pool -like "* & ") { 80 } Else { 50 }; $LegacyGUIminersDGV.Columns[11].DefaultCellStyle.Alignment = $LegacyGUIminersDGV.Columns[11].HeaderCell.Style.Alignment = "MiddleRight"

                        $LegacyGUIminersDGV | Add-Member ColumnWidthChanged $true -Force
                    }
                    $LegacyGUIminersDGV.EndInit()
                    Set-TableColor -DataGridView $LegacyGUIminersDGV
                }
            }
            Else { 
                $LegacyGUIminersLabel.Text = "Waiting for miner data..."
                $LegacyGUIminersDGV.DataSource = $null
            }
            Break
        }
        "Pools" { 
            $LegacyGUIpoolsDGV.ClearSelection()

            $LegacyGUIcontextMenuStripItem1.Visible = $false
            $LegacyGUIcontextMenuStripItem2.Visible = $false
            $LegacyGUIcontextMenuStripItem3.Enabled = $true
            $LegacyGUIcontextMenuStripItem3.Text = "Reset pool stat data"
            $LegacyGUIcontextMenuStripItem3.Visible = $true
            $LegacyGUIcontextMenuStripItem4.Enabled = $Variables.WatchdogTimers
            $LegacyGUIcontextMenuStripItem4.Text = "Remove watchdog timer"
            $LegacyGUIcontextMenuStripItem5.Visible = $false
            $LegacyGUIcontextMenuStripItem6.Visible = $false

            If ($LegacyGUIradioButtonPoolsBest.checked) { $DataSource = $Variables.PoolsBest }
            ElseIf ($LegacyGUIradioButtonPoolsUnavailable.checked) { $DataSource = $Variables.Pools.Where({ -not $_.Available }) }
            Else { $DataSource = $Variables.Pools }

            If ($Variables.NewMiningStatus -eq "Idle") { 
                $LegacyGUIpoolsLabel.Text = "No data - mining is stopped"
                $LegacyGUIpoolsDGV.DataSource = $null
            }
            ElseIf ($Variables.NewMiningStatus -eq "Paused" -and -not $DataSource) { 
                $LegacyGUIpoolsLabel.Text = "No data - mining is paused"
                $LegacyGUIpoolsDGV.DataSource = $null
            }
            ElseIf ($Variables.NewMiningStatus -eq "Running" -and $Variables.MiningStatus -eq "Running" -and -not $Variables.Pools -and $Global:CoreRunspace.Job.IsCompleted -eq $true) { 
                $LegacyGUIpoolsLabel.Text = "No data - mining is suspended"
                $LegacyGUIpoolsDGV.DataSource = $null
            }
            ElseIf ($Variables.Pools) { 
                If (-not $LegacyGUIpoolsDGV.SelectedRows) { 
                    $LegacyGUIpoolsDGV.BeginInit()
                    If ($Config.UsemBTC) { 
                        $Factor = 1000
                        $Unit = "mBTC"
                    }
                    Else { 
                        $Factor = 1
                        $Unit = "BTC"
                    }
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
                        If ($LegacyGUIradioButtonPoolsUnavailable.checked -or $LegacyGUIradioButtonPools.checked) { @{ Name = "Reason(s)"; Expression = { $_.Reasons -join ", " } } }
                    ) | Out-DataTable
                    $LegacyGUIpoolsDGV.Sort($LegacyGUIpoolsDGV.Columns[0], [System.ComponentModel.ListSortDirection]::Ascending)
                    $LegacyGUIpoolsDGV.ClearSelection()
                    $LegacyGUIpoolsLabel.Text = "Pool data updated $($Variables.PoolsUpdatedTimestamp.ToLocalTime().ToString("G")) ($($LegacyGUIpoolsDGV.Rows.Count) pool$(If ($LegacyGUIpoolsDGV.Rows.count -ne 1) { "s" }))"

                    If (-not $LegacyGUIpoolsDGV.ColumnWidthChanged -and $LegacyGUIpoolsDGV.Columns) { 
                        $LegacyGUIpoolsDGV.Columns[0].FillWeight = 80
                        $LegacyGUIpoolsDGV.Columns[1].FillWeight = 40
                        $LegacyGUIpoolsDGV.Columns[2].FillWeight = 70
                        $LegacyGUIpoolsDGV.Columns[3].FillWeight = 55; $LegacyGUIpoolsDGV.Columns[3].DefaultCellStyle.Alignment = $LegacyGUIpoolsDGV.Columns[3].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIpoolsDGV.Columns[4].FillWeight = 45; $LegacyGUIpoolsDGV.Columns[4].DefaultCellStyle.Alignment = $LegacyGUIpoolsDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIpoolsDGV.Columns[5].FillWeight = 80
                        $LegacyGUIpoolsDGV.Columns[6].FillWeight = 140
                        $LegacyGUIpoolsDGV.Columns[7].FillWeight = 40; $LegacyGUIpoolsDGV.Columns[7].DefaultCellStyle.Alignment = $LegacyGUIpoolsDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIpoolsDGV.Columns[8].FillWeight = 40; $LegacyGUIpoolsDGV.Columns[8].DefaultCellStyle.Alignment = $LegacyGUIpoolsDGV.Columns[8].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIpoolsDGV.Columns[9].FillWeight = 50; $LegacyGUIpoolsDGV.Columns[9].DefaultCellStyle.Alignment = $LegacyGUIpoolsDGV.Columns[9].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIpoolsDGV.Columns[10].FillWeight = 40; $LegacyGUIpoolsDGV.Columns[10].DefaultCellStyle.Alignment = $LegacyGUIpoolsDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"

                        $LegacyGUIpoolsDGV | Add-Member ColumnWidthChanged $true
                    }
                    $LegacyGUIpoolsDGV.EndInit()
                }
            }
            Else { 
                $LegacyGUIpoolsLabel.Text = "Waiting for pool data..."
                $LegacyGUIpoolsDGV.DataSource = $null
            }
            Break
        }
        # "Rig monitor" { 
        #     $LegacyGUIworkersDGV.ClearSelection()
        # 
        #     $LegacyGUIworkersDGV.Visible = $Config.ShowWorkerStatus
        #     $LegacyGUIeditMonitoringLink.Visible = $Variables.APIRunspace.APIport
        #
        #     If ($Config.ShowWorkerStatus) { 
        #         If (-not $LegacyGUIworkersDGV.SelectedRows) { 
        #
        #             Read-MonitoringData | Out-Null
        #
        #             If ($Variables.Workers) { $LegacyGUIworkersLabel.Text = "Worker status updated $($Variables.WorkersLastUpdated.ToString())" }
        #             ElseIf ($Variables.MiningStatus -eq "Idle") { $LegacyGUIworkersLabel.Text = "No data - mining is stopped" }
        #             ElseIf ($Variables.MiningStatus -eq "Paused" -and -not $DataSource) { $LegacyGUIworkersLabel.Text = "No data - mining is paused" }
        #             ElseIf ($Variables.NewMiningStatus -eq "Running" -and $Variables.MiningStatus -eq "Running" -and $Global:CoreRunspace.Job.IsCompleted -eq $true) {  $LegacyGUIminersLabel.Text = "No data - mining is suspended" }
        #             Else  { $LegacyGUIworkersLabel.Text = "Waiting for monitoring data..." }
        #
        #             $LegacyGUIworkersDGV.BeginInit()
        #             $LegacyGUIworkersDGV.ClearSelection()
        #             $LegacyGUIworkersDGV.DataSource = $Variables.Workers | Select-Object @(
        #                 @{ Name = "Worker"; Expression = { $_.worker } },
        #                 @{ Name = "Status"; Expression = { $_.status } },
        #                 @{ Name = "Last seen"; Expression = { (Get-TimeSince $_.date) } },
        #                 @{ Name = "Version"; Expression = { $_.version } },
        #                 @{ Name = "Currency"; Expression = { $_.data.Currency | Select-Object -Unique } },
        #                 @{ Name = "Estimated earnings/day"; Expression = { If ($null -ne $_.Data) { "{0:n$($Config.DecimalsMax)}" -f (($_.Data.EarningsWhere({ -not [Double]::IsNaN($_) }) | Measure-Object -Sum).Sum * $Variables.Rates.BTC.($_.data.Currency | Select-Object -Unique)) } } },
        #                 @{ Name = "Estimated profit/day"; Expression = { If ($null -ne $_.Data) { " {0:n$($Config.DecimalsMax)}" -f (($_.Data.Profit.Where({ -not [Double]::IsNaN($_) }) | Measure-Object -Sum).Sum * $Variables.Rates.BTC.($_.data.Currency | Select-Object -Unique)) } } },
        #                 @{ Name = "Miner"; Expression = { $_.data.Name -join $nl } },
        #                 @{ Name = "Pool"; Expression = { $_.data.ForEach({ $_.Pool -split "," -join " & " }) -join $nl } },
        #                 @{ Name = "Algorithm"; Expression = { $_.data.ForEach({ $_.Algorithm -split "," -join " & " }) -join $nl } },
        #                 @{ Name = "Live hashrate"; Expression = { $_.data.ForEach({ $_.CurrentSpeed.ForEach({ If ([Double]::IsNaN($_)) { "n/a" } Else { $_ | ConvertTo-Hash } }) -join " & " }) -join $nl } },
        #                 @{ Name = "Benchmark hashrate(s)"; Expression = { $_.data.ForEach({ $_.Hashrate.ForEach({ If ([Double]::IsNaN($_)) { "n/a" } Else { $_ | ConvertTo-Hash } }) -join " & " }) -join $nl } }
        #             ) | Out-DataTable
        #             $LegacyGUIworkersDGV.Sort($LegacyGUIworkersDGV.Columns[0], [System.ComponentModel.ListSortDirection]::Ascending)
        #             $LegacyGUIworkersDGV.ClearSelection()
        #
        #             If (-not $LegacyGUIworkersDGV.ColumnWidthChanged -and $LegacyGUIworkersDGV.Columns) { 
        #                 $LegacyGUIworkersDGV.Columns[0].FillWeight = 70
        #                 $LegacyGUIworkersDGV.Columns[1].FillWeight = 60
        #                 $LegacyGUIworkersDGV.Columns[2].FillWeight = 80
        #                 $LegacyGUIworkersDGV.Columns[3].FillWeight = 70
        #                 $LegacyGUIworkersDGV.Columns[4].FillWeight = 40
        #                 $LegacyGUIworkersDGV.Columns[5].FillWeight = 65; $LegacyGUIworkersDGV.Columns[5].DefaultCellStyle.Alignment = $LegacyGUIworkersDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"
        #                 $LegacyGUIworkersDGV.Columns[6].FillWeight = 65; $LegacyGUIworkersDGV.Columns[6].DefaultCellStyle.Alignment = $LegacyGUIworkersDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"
        #                 $LegacyGUIworkersDGV.Columns[7].FillWeight = 150
        #                 $LegacyGUIworkersDGV.Columns[8].FillWeight = 95
        #                 $LegacyGUIworkersDGV.Columns[9].FillWeight = 75
        #                 $LegacyGUIworkersDGV.Columns[10].FillWeight = 65; $LegacyGUIworkersDGV.Columns[10].DefaultCellStyle.Alignment = $LegacyGUIworkersDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"
        #                 $LegacyGUIworkersDGV.Columns[11].FillWeight = 65; $LegacyGUIworkersDGV.Columns[11].DefaultCellStyle.Alignment = $LegacyGUIworkersDGV.Columns[11].HeaderCell.Style.Alignment = "MiddleRight"
        #
        #                 $LegacyGUIworkersDGV | Add-Member ColumnWidthChanged $true
        #             }
        #             Set-WorkerColor
        #             $LegacyGUIworkersDGV.EndInit()
        #         }
        #     }
        #     Else { 
        #         $LegacyGUIworkersLabel.Text = "Worker status reporting is disabled$(If (-not $Variables.APIRunspace) { " (Configuration item 'ShowWorkerStatus' -eq `$false)" })."
        #         $LegacyGUIworkersDGV.DataSource = $null
        #     }
        #     Break
        # }
        "Switching Log" { 
            CheckBoxSwitching_Click
            Break
        }
        "Watchdog timers" { 
            $LegacyGUIwatchdogTimersRemoveButton.Visible = $Config.Watchdog
            $LegacyGUIwatchdogTimersDGV.Visible = $Config.Watchdog

            If ($Config.Watchdog) { 
                If ($Variables.NewMiningStatus -eq "Idle") { 
                    $LegacyGUIwatchdogTimersLabel.Text = "No data - mining is stopped"
                    $LegacyGUIwatchdogTimersDGV.DataSource = $null
                }
                ElseIf ($Variables.NewMiningStatus -eq "Paused" -and -not $DataSource) { 
                    $LegacyGUIwatchdogTimersLabel.Text = "No data - mining is paused"
                    $LegacyGUIwatchdogTimersDGV.DataSource = $null
                }
                ElseIf ($Variables.NewMiningStatus -eq "Running" -and $Variables.MiningStatus -eq "Running" -and -not $Variables.Pools -and $Global:CoreRunspace.Job.IsCompleted -eq $true) { 
                    $LegacyGUIwatchdogTimersLabel.Text = "No data - mining is suspended"
                    $LegacyGUIwatchdogTimersDGV.DataSource = $null
                }
                ElseIf ($Variables.WatchdogTimers) { 
                    $LegacyGUIwatchdogTimersLabel.Text = "Watchdog timers updated $(($Variables.WatchdogTimers.Kicked | Sort-Object -Bottom 1).ToLocalTime().ToString("G"))"
                    $LegacyGUIwatchdogTimersDGV.BeginInit()
                    $LegacyGUIwatchdogTimersDGV.DataSource = $Variables.WatchdogTimers | Sort-Object -Property MinerName, Kicked | Select-Object @(
                        @{ Name = "Name"; Expression = { $_.MinerName } },
                        @{ Name = "Algorithm"; Expression = { $_.Algorithm } },
                        @{ Name = "Algorithm (variant)"; Expression = { $_.AlgorithmVariant } },
                        @{ Name = "Pool"; Expression = { $_.PoolName } },
                        @{ Name = "Region"; Expression = { $_.PoolRegion } },
                        @{ Name = "Device(s)"; Expression = { $_.MinerBaseName_Version_Device -replace ".+-" } },
                        @{ Name = "Last updated"; Expression = { (Get-TimeSince $_.Kicked.ToLocalTime()) } }
                    ) | Out-DataTable
                    $LegacyGUIwatchdogTimersDGV.Sort($LegacyGUIwatchdogTimersDGV.Columns[0], [System.ComponentModel.ListSortDirection]::Ascending)
                    $LegacyGUIwatchdogTimersDGV.ClearSelection()

                    If (-not $LegacyGUIwatchdogTimersDGV.ColumnWidthChanged -and $LegacyGUIwatchdogTimersDGV.Columns) { 
                        $LegacyGUIwatchdogTimersDGV.Columns[0].FillWeight = 200
                        $LegacyGUIwatchdogTimersDGV.Columns[1].FillWeight = 60
                        $LegacyGUIwatchdogTimersDGV.Columns[2].FillWeight = 60
                        $LegacyGUIwatchdogTimersDGV.Columns[3].FillWeight = 60
                        $LegacyGUIwatchdogTimersDGV.Columns[4].FillWeight = 44
                        $LegacyGUIwatchdogTimersDGV.Columns[5].FillWeight = 35 + ($Variables.WatchdogTimers.ForEach({ $_.DeviceNames.Count }) | Measure-Object -Maximum).Maximum * 20
                        $LegacyGUIwatchdogTimersDGV.Columns[6].FillWeight = 55

                        $LegacyGUIwatchdogTimersDGV | Add-Member ColumnWidthChanged $true
                    }
                    $LegacyGUIwatchdogTimersDGV.EndInit()
                }
                Else { 
                    $LegacyGUIwatchdogTimersLabel.Text = "Waiting for watchdog timer data..."
                    $LegacyGUIwatchdogTimersDGV.DataSource = $null
                }
            }
            Else { $LegacyGUIwatchdogTimersLabel.Text = "Watchdog is disabled (Configuration item 'Watchdog' -eq `$false)" }

            $LegacyGUIwatchdogTimersRemoveButton.Enabled = [Boolean]$LegacyGUIwatchdogTimersDGV.Rows
        }
    }
}

Function Update-GUIstatus { 

    $LegacyGUIform.Text = $host.UI.RawUI.WindowTitle

    Switch ($Variables.NewMiningStatus) { 
        "Idle" { 
            $LegacyGUIminingStatusLabel.ForeColor = [System.Drawing.Color]::Red
            $LegacyGUIminingStatusLabel.Text = "$($Variables.Branding.ProductLabel) is stopped"
            $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Black
            Break
        }
        "Paused" { 
            $LegacyGUIminingStatusLabel.ForeColor = [System.Drawing.Color]::Blue
            $LegacyGUIminingStatusLabel.Text = "$($Variables.Branding.ProductLabel) is paused"
            $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Black
            Break
        }
        "Running" { 
            If ($Variables.MiningStatus -eq "Running" -and -$Global:CoreRunspace.Job.IsCompleted -eq $true) { 
                $LegacyGUIminingStatusLabel.ForeColor = [System.Drawing.Color]::Blue
                $LegacyGUIminingStatusLabel.Text = "$($Variables.Branding.ProductLabel) is suspended"
                $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Black
            }
            Else { 
                $LegacyGUIminingStatusLabel.ForeColor = [System.Drawing.Color]::Green
                $LegacyGUIminingStatusLabel.Text = "$($Variables.Branding.ProductLabel) is running"

                If ($Variables.MinersRunning -and $Variables.MiningProfit -gt 0) { $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Green }
                ElseIf ($Variables.MinersRunning -and $Variables.MiningProfit -lt 0) { $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Red }
                Else { $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Black }
            }
        }
    }
    $LegacyGUIminingSummaryLabel.Text = (($Variables.Summary.Replace("$($LegacyGUIminingStatusLabel.Text). ", "") -replace "&ensp;", " " -replace "   ", "  " -replace "&", "&&") -split "<br>") -join "`r`n"
    Update-TabControl
}

$LegacyGUIcolors = @{ }
$LegacyGUIcolors["benchmarking"]                            = [System.Drawing.Color]::FromArgb(241, 255, 229)
$LegacyGUIcolors["disabled"]                                = [System.Drawing.Color]::FromArgb(255, 243, 231)
$LegacyGUIcolors["failed"]                                  = [System.Drawing.Color]::FromArgb(255, 230, 230)
$LegacyGUIcolors["idle"] = $LegacyGUIcolors["stopped"]      = [System.Drawing.Color]::FromArgb(230, 248, 252)
$LegacyGUIcolors["launched"]                                = [System.Drawing.Color]::FromArgb(229, 255, 229)
$LegacyGUIcolors["dryrun"] = $LegacyGUIcolors["running"]    = [System.Drawing.Color]::FromArgb(212, 244, 212)
$LegacyGUIcolors["starting"] = $LegacyGUIcolors["stopping"] = [System.Drawing.Color]::FromArgb(245, 255, 245)
$LegacyGUIcolors["unavailable"]                             = [System.Drawing.Color]::FromArgb(254, 245, 220)
$LegacyGUIcolors["warmingup"]                               = [System.Drawing.Color]::FromArgb(231, 255, 230)

$LegacyGUItooltip = [System.Windows.Forms.ToolTip]::new()

$LegacyGUIform = [System.Windows.Forms.Form]::new()
# For High DPI, First call SuspendLayout(), after that, Set AutoScaleDimensions, AutoScaleMode
# SuspendLayout() is very important to correctly size and position all controls!
$LegacyGUIform.SuspendLayout()
# $LegacyGUIform.AutoScaleDimensions = [System.Drawing.SizeF]::new(120, 120)
$LegacyGUIform.AutoScaleDimensions = [System.Drawing.SizeF]::new(96, 96)
$LegacyGUIform.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::DPI
$LegacyGUIform.MaximizeBox = $true
$LegacyGUIform.MinimumSize = [System.Drawing.Size]::new(800, 600) # best to keep under 800x600
$LegacyGUIform.Text = $Variables.Branding.ProductLabel
$LegacyGUIform.TopMost = $false

# Form Controls
$LegacyGUIControls = @()

$LegacyGUIstatusPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIstatusPage.Text = "System status"
$LegacyGUIstatusPage.ToolTipText = "Show active miners and system log"
$LegacyGUIearningsPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIearningsPage.Text = "Earnings and balances"
$LegacyGUIearningsPage.ToolTipText = "Information about the calculated earnings / profit"
$LegacyGUIminersPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIminersPage.Text = "Miners"
$LegacyGUIminersPage.ToolTipText = "Miner data updated in the last cycle"
$LegacyGUIpoolsPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIpoolsPage.Text = "Pools"
$LegacyGUIpoolsPage.ToolTipText = "Pool data updated in the last cycle"
# $LegacyGUIrigMonitorPage = [System.Windows.Forms.TabPage]::new()
# $LegacyGUIrigMonitorPage.Text = "Rig monitor"
# $LegacyGUIrigMonitorPage.ToolTipText = "Consolidated overview of all known mining rigs"
$LegacyGUIswitchingPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIswitchingPage.Text = "Switching log"
$LegacyGUIswitchingPage.ToolTipText = "List of the previously launched miners"
$LegacyGUIwatchdogTimersPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIwatchdogTimersPage.Text = "Watchdog timers"
$LegacyGUIwatchdogTimersPage.ToolTipText = "List of all watchdog timers"

$LegacyGUIminingStatusLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIminingStatusLabel.AutoSize = $false
$LegacyGUIminingStatusLabel.BackColor = [System.Drawing.Color]::Transparent
$LegacyGUIminingStatusLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$LegacyGUIminingStatusLabel.ForeColor = [System.Drawing.Color]::Black
$LegacyGUIminingStatusLabel.Height = 20
$LegacyGUIminingStatusLabel.Location = [System.Drawing.Point]::new(8, 10)
$LegacyGUIminingStatusLabel.Text = "$($Variables.Branding.ProductLabel)"
$LegacyGUIminingStatusLabel.TextAlign = "MiddleLeft"
$LegacyGUIminingStatusLabel.Visible = $true
$LegacyGUIminingStatusLabel.Width = 360
$LegacyGUIControls += $LegacyGUIminingStatusLabel

$LegacyGUIminingSummaryLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIminingSummaryLabel.AutoSize = $false
$LegacyGUIminingSummaryLabel.BackColor = [System.Drawing.Color]::Transparent
$LegacyGUIminingSummaryLabel.BorderStyle = 'None'
$LegacyGUIminingSummaryLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Black
$LegacyGUIminingSummaryLabel.Height = 60
$LegacyGUIminingSummaryLabel.Location = [System.Drawing.Point]::new(10, 35)
$LegacyGUIminingSummaryLabel.Tag = ""
$LegacyGUIminingSummaryLabel.TextAlign = "MiddleLeft"
$LegacyGUIminingSummaryLabel.Visible = $true
$LegacyGUIControls += $LegacyGUIminingSummaryLabel
$LegacyGUItooltip.SetToolTip($LegacyGUIminingSummaryLabel, "Color legend:`rBlack: Mining profitability is unknown`rGreen: Mining is profitable`rRed: Mining is NOT profitable")

$LegacyGUIbuttonPause = [System.Windows.Forms.Button]::new()
$LegacyGUIbuttonPause.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIbuttonPause.Height = 24
$LegacyGUIbuttonPause.Text = "Pause mining"
$LegacyGUIbuttonPause.Visible = $true
$LegacyGUIbuttonPause.Width = 100
$LegacyGUIbuttonPause.Add_Click(
    { 
        If ($Variables.NewMiningStatus -ne "Paused" -and -not $Variables.SuspendCycle) { 
            $Variables.NewMiningStatus = "Paused"
            $Variables.SuspendCycle = $false
            $Variables.RestartCycle = $true
        }
    }
)
$LegacyGUIControls += $LegacyGUIbuttonPause
$LegacyGUItooltip.SetToolTip($LegacyGUIbuttonPause, "Pause mining processes.`rBrain jobs and balances tracker remain running.")

$LegacyGUIbuttonStart = [System.Windows.Forms.Button]::new()
$LegacyGUIbuttonStart.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIbuttonStart.Height = 24
$LegacyGUIbuttonStart.Text = "Start mining"
$LegacyGUIbuttonStart.Visible = $true
$LegacyGUIbuttonStart.Width = 100
$LegacyGUIbuttonStart.Add_Click(
    { 
        If ($Variables.NewMiningStatus -ne "Running") { 
            $Variables.NewMiningStatus = "Running"
            $Variables.SuspendCycle = $false
            $Variables.RestartCycle = $true
        }
    }
)
$LegacyGUIControls += $LegacyGUIbuttonStart
$LegacyGUItooltip.SetToolTip($LegacyGUIbuttonStart, "Start the mining process.`rBrain jobs and balances tracker will also start.")

$LegacyGUIbuttonStop = [System.Windows.Forms.Button]::new()
$LegacyGUIbuttonStop.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIbuttonStop.Height = 24
$LegacyGUIbuttonStop.Text = "Stop mining"
$LegacyGUIbuttonStop.Visible = $true
$LegacyGUIbuttonStop.Width = 100
$LegacyGUIbuttonStop.Add_Click(
    { 
        If ($Variables.NewMiningStatus -ne "Idle") { 
            $Variables.NewMiningStatus = "Idle"
            $Variables.SuspendCycle = $false
            $Variables.RestartCycle = $true
        }
    }
)
$LegacyGUIControls += $LegacyGUIbuttonStop
$LegacyGUItooltip.SetToolTip($LegacyGUIbuttonStop, "Stop mining processes.`rBrain jobs and balances tracker will also stop.")

$LegacyGUIeditConfigLink = [System.Windows.Forms.LinkLabel]::new()
$LegacyGUIeditConfigLink.ActiveLinkColor = [System.Drawing.Color]::Blue
$LegacyGUIeditConfigLink.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIeditConfigLink.LinkColor = [System.Drawing.Color]::Blue
$LegacyGUIeditConfigLink.Location = [System.Drawing.Point]::new(18, ($LegacyGUIform.Bottom - 26))
$LegacyGUIeditConfigLink.TextAlign = "MiddleLeft"
$LegacyGUIeditConfigLink.Size = [System.Drawing.Size]::new(380, 26)
$LegacyGUIeditConfigLink.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        If ($LegacyGUIeditConfigLink.Tag -eq "WebGUI") { Start-Process "http://localhost:$($Variables.APIRunspace.APIport)/configedit.html" } Else { Edit-File $Variables.ConfigFile }
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)
$LegacyGUIControls += $LegacyGUIeditConfigLink
$LegacyGUItooltip.SetToolTip($LegacyGUIeditConfigLink, "Click to the edit the configuration file in notepad")

$LegacyGUIcopyrightLabel = [System.Windows.Forms.LinkLabel]::new()
$LegacyGUIcopyrightLabel.ActiveLinkColor = [System.Drawing.Color]::Blue
$LegacyGUIcopyrightLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIcopyrightLabel.Location = [System.Drawing.Point]::new(8, ($LegacyGUIform.Bottom - 26))
$LegacyGUIcopyrightLabel.LinkColor = [System.Drawing.Color]::Blue
$LegacyGUIcopyrightLabel.Size = [System.Drawing.Size]::new(380, 26)
$LegacyGUIcopyrightLabel.Text = "Copyright (c) 2018-$([DateTime]::Now.Year) UselessGuru"
$LegacyGUIcopyrightLabel.TextAlign = "MiddleRight"
$LegacyGUIcopyrightLabel.Add_Click({ Start-Process "$($Variables.Branding.BrandWebSite)" })
$LegacyGUIControls += $LegacyGUIcopyrightLabel
$LegacyGUItooltip.SetToolTip($LegacyGUIcopyrightLabel, "Click to go to the $($Variables.Branding.ProductLabel) Github page")

# Miner context menu items
$LegacyGUIcontextMenuStrip = [System.Windows.Forms.ContextMenuStrip]::new()
$LegacyGUIcontextMenuStrip.Enabled = $false

$LegacyGUIcontextMenuStripItem1 = [System.Windows.Forms.ToolStripMenuItem]::new()
[Void]$LegacyGUIcontextMenuStrip.Items.Add($LegacyGUIcontextMenuStripItem1)

$LegacyGUIcontextMenuStripItem2 = [System.Windows.Forms.ToolStripMenuItem]::new()
[Void]$LegacyGUIcontextMenuStrip.Items.Add($LegacyGUIcontextMenuStripItem2)

$LegacyGUIcontextMenuStripItem3 = [System.Windows.Forms.ToolStripMenuItem]::new()
[Void]$LegacyGUIcontextMenuStrip.Items.Add($LegacyGUIcontextMenuStripItem3)

$LegacyGUIcontextMenuStripItem4 = [System.Windows.Forms.ToolStripMenuItem]::new()
[Void]$LegacyGUIcontextMenuStrip.Items.Add($LegacyGUIcontextMenuStripItem4)

$LegacyGUIcontextMenuStripItem5 = [System.Windows.Forms.ToolStripMenuItem]::new()
[Void]$LegacyGUIcontextMenuStrip.Items.Add($LegacyGUIcontextMenuStripItem5)

$LegacyGUIcontextMenuStripItem6 = [System.Windows.Forms.ToolStripMenuItem]::new()
[Void]$LegacyGUIcontextMenuStrip.Items.Add($LegacyGUIcontextMenuStripItem6)

$LegacyGUIcontextMenuStrip.Add_ItemClicked(
    { 
        $Data = @()

        $SourceControl = $this.SourceControl
        If ($SourceControl.Name -match "LaunchedMinersDGV|MinersDGV") { 

            Switch ($_.ClickedItem.Text) { 
                "Re-benchmark miner" { 
                    $LegacyGUIcontextMenuStrip.Visible = $false
                    $Variables.Miners.Where({ $_.Info -in $SourceControl.SelectedRows.ForEach({ $_.Cells[0].Value }) }).ForEach(
                        { 
                            $Data += $_.Name
                            Set-MinerReBenchmark $_
                        }
                    )
                    $Message = "Re-benchmark triggered for $($Data.Count) miner$(If ($Data.Count -ne 1) { "s" })."
                    Write-Message -Level Verbose "GUI: $Message" -Console $false
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                    Update-TabControl
                    Break
                }
                "Re-measure power consumption" { 
                    $LegacyGUIcontextMenuStrip.Visible = $false
                    $Variables.Miners.Where({ $_.Info -in $SourceControl.SelectedRows.ForEach{ ($_.Cells[0].Value) } }).ForEach(
                        { 
                            $Data += $_.Name
                            Set-MinerMeasurePowerConsumption $_  
                        }
                    )
                    $Message = "Re-measure power consumption triggered for $($Data.Count) miner$(If ($Data.Count -ne 1) { "s" })."
                    Write-Message -Level Verbose "GUI: $Message" -Console $false
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                    Update-TabControl
                    Break
                }
                "Mark miner as failed" { 
                    $LegacyGUIcontextMenuStrip.Visible = $false
                    $Variables.Miners.Where({ $_.Info -in $SourceControl.SelectedRows.ForEach{ ($_.Cells[0].Value) } }).ForEach(
                        { 
                            Set-MinerFailed $_
                            $Data += $_.Name
                        }
                    )
                    $Message = "Marked $($Data.Count) miner$(If ($Data.Count -ne 1) { "s" }) as failed." 
                    Write-Message -Level Verbose "GUI: $Message" -Console $false
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                    Update-TabControl
                    Break
                }
                "Disable miner" { 
                    $LegacyGUIcontextMenuStrip.Visible = $false
                    $Variables.Miners.Where({ $_.Info -in $SourceControl.SelectedRows.ForEach{ ($_.Cells[0].Value) } }).Where({ -not $_.Disabled }).ForEach(
                        { 
                            $Data += $_.Name
                            Set-MinerDisabled $_
                        }
                    )
                    If ($Data.Count) { 
                        $Message = "Disabled $($Data.Count) miner$(If ($Data.Count -ne 1) { "s" })."
                        Write-Message -Level Verbose "GUI: $Message" -Console $false
                        $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                        Update-TabControl
                    }
                    Else {
                        $Data = "No matching miners found."
                    }
                    Break
                }
                "Enable miner" { 
                    $LegacyGUIcontextMenuStrip.Visible = $false
                    $Variables.Miners.Where({ $_.Info -in $SourceControl.SelectedRows.ForEach{ ($_.Cells[0].Value) } }).Where({ $_.Disabled }).ForEach(
                        { 
                            $Data += $_.Name
                            Set-MinerEnabled $_
                        }
                    )
                    If ($Data.Count) { 
                        $Message = "Enabled $($Data.Count) miner$(If ($Data.Count -ne 1) { "s" })."
                        Write-Message -Level Verbose "GUI: $Message" -Console $false
                        $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                        Update-TabControl
                    }
                    Else {
                        $Data = "No matching miners found."
                    }
                    Break
                }
                "Remove watchdog timer" { 
                    $this.SourceControl.SelectedRows.ForEach(
                        { 
                            $MinerName = $_.Cells[2].Value
                            # Update miner
                            ForEach ($Miner in $Variables.Miners.Where({ $_.Name -eq $MinerName -and $Variables.WatchdogTimers.Where({ $_.MinerName -eq $MinerName }) })) { 
                                $Data += $Miner.Name
                                $Miner.Reasons.Where({ $_ -like "Miner suspended by watchdog *" }).ForEach({ $Miner.Reasons.Remove($_) | Out-Null })
                                If (-not $Miner.Reasons.Count) { $Miner.Available = $true }
                            }

                            # Remove Watchdog timers
                            $Variables.WatchdogTimers = $Variables.WatchdogTimers.Where({ $_.MinerName -ne $MinerName })

                            Remove-Variable Miner, MinerName
                        }
                    )
                    $LegacyGUIcontextMenuStrip.Visible = $false
                    If ($Data) { 
                        $Message = "$($Data.Count) miner watchdog timer$(If ($Data.Count -ne 1) { "s" }) removed."
                        Write-Message -Level Verbose "GUI: $Message" -Console $false
                        $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                    }
                    Else { 
                        $Data = "No matching watchdog timer found."
                    }
                }
            }
            If ($Data.Count -ge 1) { [Void][System.Windows.Forms.MessageBox]::Show([String]($Data -join "`r`n"), "$($Variables.Branding.ProductLabel): $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK, 64) }

        }
        ElseIf ($this.SourceControl.Name -match "PoolsDGV") { 
            Switch ($_.ClickedItem.Text) { 
                "Reset pool stat data" { 
                    $this.SourceControl.SelectedRows.ForEach(
                        { 
                            $SelectedPoolName = $_.Cells[5].Value
                            $SelectedPoolAlgorithm = $_.Cells[0].Value
                            $Variables.Pools.Where({ $_.Name -eq $SelectedPoolName -and $_.Algorithm -eq $SelectedPoolAlgorithm }).ForEach(
                                { 
                                    $StatName = "$($_.Name)_$($_.Algorithm)$(If ($_.Currency) { "-$($_.Currency)" })"
                                    $Data += $StatName
                                    Remove-Stat -Name "$($StatName)_Profit"
                                    $_.Reasons = [System.Collections.Generic.SortedSet[String]]::New()
                                    $_.Price = $_.Price_Bias = $_.StablePrice = $_.Accuracy = [Double]::Nan
                                    $_.Available = $true
                                    $_.Disabled = $false
                                }
                            )
                        }
                    )
                    $LegacyGUIcontextMenuStrip.Visible = $false
                    $Message = "Pool stats for $($Data.Count) pool$(If ($Data.Count -ne 1) { "s" }) reset."
                    Write-Message -Level Verbose "GUI: $Message" -Console $false
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                    Update-TabControl
                    Break
                }
                "Remove watchdog timer" { 
                    $this.SourceControl.SelectedRows.ForEach(
                        { 
                            $PoolName = $_.Cells[5].Value
                            $PoolAlgorithm = $_.Cells[0].Value
                            # Update pool
                            ForEach ($Pool in ($Variables.Pools.Where({ $_.Name -eq $PoolName -and $_.Algorithm -eq $PoolAlgorithm -and $Variables.WatchdogTimers.Where({ $_.PoolName -eq $PoolName -and $_.Algorithm -eq $PoolAlgorithm }) }))) {
                                $Data += "$($Pool.Key) ($($Pool.Region))"
                                $Pool.Reasons.Where({ $_ -like "Pool suspended by watchdog *" }).ForEach({ $Pool.Reasons.Remove($_) | Out-Null })
                                If (-not $Pool.Reasons.Count) { $Pool.Available = $true }
                            }

                            # Remove Watchdog timers
                            $Variables.WatchdogTimers = $Variables.WatchdogTimers.Where({ $_.PoolName -ne $PoolName -or $_.Algorithm -ne $PoolAlgorithm })

                            Remove-Variable Pool, PoolAlgorithm, PoolAlgorithm
                        }
                    )
                    $LegacyGUIcontextMenuStrip.Visible = $false
                    If ($Data) { 
                        $Message = "$($Data.Count) pool watchdog timer$(If ($Data.Count -ne 1) { "s" }) removed."
                        Write-Message -Level Verbose "GUI: $Message" -Console $false
                        $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                    }
                    Else { 
                        $Data = "No matching watchdog timer found."
                    }
                    Break
                }
            }
            If ($Data.Count -ge 1) { [Void][System.Windows.Forms.MessageBox]::Show([String]($Data -join "`r`n"), "$($Variables.Branding.ProductLabel): $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK, 64) }

        }
        Remove-Variable SourceControl
    }
)

# CheckBox Column for DataGridView
$LegacyGUIcheckBoxColumn = [System.Windows.Forms.DataGridViewCheckBoxColumn]::new()
$LegacyGUIcheckBoxColumn.HeaderText = ""
$LegacyGUIcheckBoxColumn.Name = "CheckBoxColumn"
$LegacyGUIcheckBoxColumn.ReadOnly = $false

# Run Page Controls
$LegacyGUIstatusPageControls = @()

$LegacyGUIactiveMinersLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIactiveMinersLabel.AutoSize = $false
$LegacyGUIactiveMinersLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIactiveMinersLabel.Height = 20
$LegacyGUIactiveMinersLabel.Location = [System.Drawing.Point]::new(0, 5)
$LegacyGUIactiveMinersLabel.Width = 600
$LegacyGUIstatusPageControls += $LegacyGUIactiveMinersLabel

$LegacyGUIactiveMinersDGV = [System.Windows.Forms.DataGridView]::new()
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
$LegacyGUIactiveMinersDGV.Location = [System.Drawing.Point]::new(0, ($LegacyGUIactiveMinersLabel.Height + 6))
$LegacyGUIactiveMinersDGV.Name = "LaunchedMinersDGV"
$LegacyGUIactiveMinersDGV.ReadOnly = $true
$LegacyGUIactiveMinersDGV.RowHeadersVisible = $false
$LegacyGUIactiveMinersDGV.ScrollBars = "None"
$LegacyGUIactiveMinersDGV.SelectionMode = "FullRowSelect"
$LegacyGUIactiveMinersDGV.Add_MouseUp(
    { 
        If ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right) { 
            $LegacyGUIcontextMenuStrip.Enabled = [Boolean]$this.SelectedRows
        }
    }
)
$LegacyGUIactiveMinersDGV.Add_Sorted(
    { 
        Set-TableColor -DataGridView $LegacyGUIactiveMinersDGV
    }
)
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIactiveMinersDGV -Enabled $true
$LegacyGUIstatusPageControls += $LegacyGUIactiveMinersDGV

$LegacyGUIsystemLogLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIsystemLogLabel.AutoSize = $false
$LegacyGUIsystemLogLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIsystemLogLabel.Height = 20
$LegacyGUIsystemLogLabel.Text = "System Log"
$LegacyGUIsystemLogLabel.Width = 600
$LegacyGUIstatusPageControls += $LegacyGUIsystemLogLabel

$Variables.TextBoxSystemLog = [System.Windows.Forms.TextBox]::new()
$Variables.TextBoxSystemLog.AutoSize = $true
$Variables.TextBoxSystemLog.BorderStyle = "FixedSingle"
$Variables.TextBoxSystemLog.Font = [System.Drawing.Font]::new("Consolas", 9)
$Variables.TextBoxSystemLog.HideSelection = $false
$Variables.TextBoxSystemLog.MultiLine = $true
$Variables.TextBoxSystemLog.ReadOnly = $true
$Variables.TextBoxSystemLog.Scrollbars = "Vertical"
$Variables.TextBoxSystemLog.Text = ""
$Variables.TextBoxSystemLog.WordWrap = $true
$LegacyGUIstatusPageControls += $Variables.TextBoxSystemLog
$LegacyGUItooltip.SetToolTip($Variables.TextBoxSystemLog, "These are the last 200 lines of the system log")

# Earnings Page Controls
$LegacyGUIearningsPageControls = @()

$LegacyGUIearningsChart = [System.Windows.Forms.DataVisualization.Charting.Chart]::new()
$LegacyGUIearningsChart.BackColor = [System.Drawing.Color]::FromArgb(255, 240, 240, 240)
$LegacyGUIearningsChart.Location = [System.Drawing.Point]::new(0, 0)
$LegacyGUIearningsPageControls += $LegacyGUIearningsChart

$LegacyGUIbalancesLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIbalancesLabel.AutoSize = $false
$LegacyGUIbalancesLabel.BringToFront()
$LegacyGUIbalancesLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIbalancesLabel.Height = 20
$LegacyGUIbalancesLabel.Width = 600
$LegacyGUIearningsPageControls += $LegacyGUIbalancesLabel

$LegacyGUIbalancesDGV = [System.Windows.Forms.DataGridView]::new()
$LegacyGUIbalancesDGV.AllowUserToAddRows = $false
$LegacyGUIbalancesDGV.AllowUserToDeleteRows = $false
$LegacyGUIbalancesDGV.AllowUserToOrderColumns = $true
$LegacyGUIbalancesDGV.AllowUserToResizeColumns = $true
$LegacyGUIbalancesDGV.AllowUserToResizeRows = $false
$LegacyGUIbalancesDGV.AutoSizeColumnsMode = "Fill"
$LegacyGUIbalancesDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIbalancesDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIbalancesDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LegacyGUIbalancesDGV.DefaultCellStyle.SelectionBackColor = $LegacyGUIbalancesDGV.DefaultCellStyle.BackColor
$LegacyGUIbalancesDGV.DefaultCellStyle.SelectionForeColor = $LegacyGUIbalancesDGV.DefaultCellStyle.ForeColor
$LegacyGUIbalancesDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LegacyGUIbalancesDGV.EnableHeadersVisualStyles = $false
$LegacyGUIbalancesDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$LegacyGUIbalancesDGV.Height = 3
$LegacyGUIbalancesDGV.Location = [System.Drawing.Point]::new(0, 0)
$LegacyGUIbalancesDGV.Name = "EarningsDGV"
$LegacyGUIbalancesDGV.ReadOnly = $true
$LegacyGUIbalancesDGV.RowHeadersVisible = $false
$LegacyGUIbalancesDGV.SelectionMode = "FullRowSelect"
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIbalancesDGV -Enabled $true
$LegacyGUIearningsPageControls += $LegacyGUIbalancesDGV

# Miner page Controls
$LegacyGUIminersPageControls = @()

$LegacyGUIradioButtonMinersOptimal = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIradioButtonMinersOptimal.AutoSize = $false
$LegacyGUIradioButtonMinersOptimal.Checked = $true
$LegacyGUIradioButtonMinersOptimal.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIradioButtonMinersOptimal.Height = 22
$LegacyGUIradioButtonMinersOptimal.Location = [System.Drawing.Point]::new(0, 0)
$LegacyGUIradioButtonMinersOptimal.Text = "Optimal miners"
$LegacyGUIradioButtonMinersOptimal.Width = 150
$LegacyGUIradioButtonMinersOptimal.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $LegacyGUIminersDGV | Add-Member ColumnWidthChanged $false -Force
        $LegacyGUIminersDGV.ClearSelection()
        Update-TabControl
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)
$LegacyGUItooltip.SetToolTip($LegacyGUIradioButtonMinersOptimal, "These are all optimal miners per algorithm and device.")

$LegacyGUIradioButtonMinersUnavailable = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIradioButtonMinersUnavailable.AutoSize = $false
$LegacyGUIradioButtonMinersUnavailable.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIradioButtonMinersUnavailable.Height = $LegacyGUIradioButtonMinersOptimal.Height
$LegacyGUIradioButtonMinersUnavailable.Location = [System.Drawing.Point]::new(150, 0)
$LegacyGUIradioButtonMinersUnavailable.Text = "Unavailable miners"
$LegacyGUIradioButtonMinersUnavailable.Width = 170
$LegacyGUIradioButtonMinersUnavailable.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $LegacyGUIminersDGV | Add-Member ColumnWidthChanged $false -Force
        $LegacyGUIminersDGV.ClearSelection()
        Update-TabControl
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)
$LegacyGUItooltip.SetToolTip($LegacyGUIradioButtonMinersUnavailable, "These are all unavailable miners.`rThe column 'Reason(s)' shows the filter criteria(s) that made the miner unavailable.")

$LegacyGUIradioButtonMiners = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIradioButtonMiners.AutoSize = $false
$LegacyGUIradioButtonMiners.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIradioButtonMiners.Height = $LegacyGUIradioButtonMinersUnavailable.Height
$LegacyGUIradioButtonMiners.Location = [System.Drawing.Point]::new(320, 0)
$LegacyGUIradioButtonMiners.Text = "All miners"
$LegacyGUIradioButtonMiners.Width = 100
$LegacyGUIradioButtonMiners.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $LegacyGUIminersDGV | Add-Member ColumnWidthChanged $false -Force
        $LegacyGUIminersDGV.ClearSelection()
        Update-TabControl
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)
$LegacyGUItooltip.SetToolTip($LegacyGUIradioButtonMiners, "These are all miners.`rNote: UG-Miner will only create miners for algorithms that have at least one available pool.")

$LegacyGUIminersLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIminersLabel.AutoSize = $false
$LegacyGUIminersLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIminersLabel.Height = 20
$LegacyGUIminersLabel.Location = [System.Drawing.Point]::new(0, 6)
$LegacyGUIminersLabel.Width = 600
$LegacyGUIminersPageControls += $LegacyGUIminersLabel

$LegacyGUIminersPanel = [System.Windows.Forms.Panel]::new()
$LegacyGUIminersPanel.Height = 22
$LegacyGUIminersPanel.Location = [System.Drawing.Point]::new(0, ($LegacyGUIminersLabel.Height + 6))
$LegacyGUIminersPanel.Controls.Add($LegacyGUIradioButtonMinersOptimal)
$LegacyGUIminersPanel.Controls.Add($LegacyGUIradioButtonMinersUnavailable)
$LegacyGUIminersPanel.Controls.Add($LegacyGUIradioButtonMiners)
$LegacyGUIminersPageControls += $LegacyGUIminersPanel

$LegacyGUIminersDGV = [System.Windows.Forms.DataGridView]::new()
$LegacyGUIminersDGV.AllowUserToAddRows = $false
$LegacyGUIminersDGV.AllowUserToDeleteRows = $false
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
$LegacyGUIminersDGV.Location = [System.Drawing.Point]::new(0, ($LegacyGUIminersLabel.Height + $LegacyGUIminersPanel.Height + 10))
$LegacyGUIminersDGV.Name = "MinersDGV"
$LegacyGUIminersDGV.ReadOnly = $true
$LegacyGUIminersDGV.RowHeadersVisible = $false
$LegacyGUIminersDGV.SelectionMode = "FullRowSelect"
$LegacyGUIminersDGV.Add_MouseUp(
    { 
        If ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right) { 
            $LegacyGUIcontextMenuStrip.Enabled = [Boolean]$this.SelectedRows
        }
    }
)
$LegacyGUIminersDGV.Add_Sorted(
    { 
        Set-TableColor -DataGridView $LegacyGUIminersDGV
    }
)
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIminersDGV -Enabled $true
$LegacyGUIminersPageControls += $LegacyGUIminersDGV

# Pools page Controls
$LegacyGUIpoolsPageControls = @()

$LegacyGUIradioButtonPoolsBest = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIradioButtonPoolsBest.AutoSize = $false
$LegacyGUIradioButtonPoolsBest.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIradioButtonPoolsBest.Height = 22
$LegacyGUIradioButtonPoolsBest.Location = [System.Drawing.Point]::new(0, 0)
$LegacyGUIradioButtonPoolsBest.Tag = ""
$LegacyGUIradioButtonPoolsBest.Text = "Best pools"
$LegacyGUIradioButtonPoolsBest.Width = 120
$LegacyGUIradioButtonPoolsBest.Checked = $true
$LegacyGUIradioButtonPoolsBest.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $LegacyGUIpoolsDGV | Add-Member ColumnWidthChanged $false -Force
        $LegacyGUIpoolsDGV.ClearSelection()
        Update-TabControl
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)
$LegacyGUItooltip.SetToolTip($LegacyGUIradioButtonPoolsBest, "This is the list of the best paying pool for each algorithm.")

$LegacyGUIradioButtonPoolsUnavailable = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIradioButtonPoolsUnavailable.AutoSize = $false
$LegacyGUIradioButtonPoolsUnavailable.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIradioButtonPoolsUnavailable.Height = $LegacyGUIradioButtonPoolsBest.Height
$LegacyGUIradioButtonPoolsUnavailable.Location = [System.Drawing.Point]::new(120, 0)
$LegacyGUIradioButtonPoolsUnavailable.Tag = ""
$LegacyGUIradioButtonPoolsUnavailable.Text = "Unavailable pools"
$LegacyGUIradioButtonPoolsUnavailable.Width = 170
$LegacyGUIradioButtonPoolsUnavailable.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $LegacyGUIpoolsDGV | Add-Member ColumnWidthChanged $false -Force
        $LegacyGUIpoolsDGV.ClearSelection()
        Update-TabControl
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)
$LegacyGUItooltip.SetToolTip($LegacyGUIradioButtonPoolsUnavailable, "This is the pool of all unavailable pools.`rThe column 'Reason(s)' shows the filter criteria(s) that made the pool unavailable.")

$LegacyGUIradioButtonPools = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIradioButtonPools.AutoSize = $false
$LegacyGUIradioButtonPools.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIradioButtonPools.Height = $LegacyGUIradioButtonPoolsUnavailable.Height
$LegacyGUIradioButtonPools.Location = [System.Drawing.Point]::new((120 + 175), 0)
$LegacyGUIradioButtonPools.Tag = ""
$LegacyGUIradioButtonPools.Text = "All pools"
$LegacyGUIradioButtonPools.Width = 100
$LegacyGUIradioButtonPools.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $LegacyGUIpoolsDGV | Add-Member ColumnWidthChanged $false -Force
        $LegacyGUIpoolsDGV.ClearSelection()
        Update-TabControl
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)
$LegacyGUItooltip.SetToolTip($LegacyGUIradioButtonPools, "This is the pool data of all configured pools.")

$LegacyGUIpoolsLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIpoolsLabel.AutoSize = $false
$LegacyGUIpoolsLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIpoolsLabel.Location = [System.Drawing.Point]::new(0, 6)
$LegacyGUIpoolsLabel.Height = 20
$LegacyGUIpoolsLabel.Width = 600
$LegacyGUIpoolsPageControls += $LegacyGUIpoolsLabel

$LegacyGUIpoolsPanel = [System.Windows.Forms.Panel]::new()
$LegacyGUIpoolsPanel.Height = 22
$LegacyGUIpoolsPanel.Location = [System.Drawing.Point]::new(0, ($LegacyGUIpoolsLabel.Height + 6))
$LegacyGUIpoolsPanel.Controls.Add($LegacyGUIradioButtonPools)
$LegacyGUIpoolsPanel.Controls.Add($LegacyGUIradioButtonPoolsUnavailable)
$LegacyGUIpoolsPanel.Controls.Add($LegacyGUIradioButtonPoolsBest)
$LegacyGUIpoolsPageControls += $LegacyGUIpoolsPanel

$LegacyGUIpoolsDGV = [System.Windows.Forms.DataGridView]::new()
$LegacyGUIpoolsDGV.AllowUserToAddRows = $false
$LegacyGUIpoolsDGV.AllowUserToDeleteRows = $false
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
$LegacyGUIpoolsDGV.Location = [System.Drawing.Point]::new(0, ($LegacyGUIpoolsLabel.Height + $LegacyGUIpoolsPanel.Height + 10))
$LegacyGUIpoolsDGV.Name = "PoolsDGV"
$LegacyGUIpoolsDGV.ReadOnly = $true
$LegacyGUIpoolsDGV.RowHeadersVisible = $false
$LegacyGUIpoolsDGV.SelectionMode = "FullRowSelect"
$LegacyGUIpoolsDGV.Add_MouseUp(
    { 
        If ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right) { 
            $LegacyGUIcontextMenuStrip.Enabled = [Boolean]$this.SelectedRows
        }
    }
)
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIpoolsDGV -Enabled $true
$LegacyGUIpoolsPageControls += $LegacyGUIpoolsDGV

# Monitoring Page Controls
# $LegacyGUIrigMonitorPageControls = @()

# $LegacyGUIworkersLabel = [System.Windows.Forms.Label]::new()
# $LegacyGUIworkersLabel.AutoSize = $false
# $LegacyGUIworkersLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
# $LegacyGUIworkersLabel.Height = 20
# $LegacyGUIworkersLabel.Location = [System.Drawing.Point]::new(0, 6)
# $LegacyGUIworkersLabel.Width = 900
# $LegacyGUIrigMonitorPageControls += $LegacyGUIworkersLabel

# $LegacyGUIworkersDGV = [System.Windows.Forms.DataGridView]::new()
# $LegacyGUIworkersDGV.AllowUserToAddRows = $false
# $LegacyGUIworkersDGV.AllowUserToDeleteRows = $false
# $LegacyGUIworkersDGV.AllowUserToOrderColumns = $true
# $LegacyGUIworkersDGV.AllowUserToResizeColumns = $true
# $LegacyGUIworkersDGV.AllowUserToResizeRows = $false
# $LegacyGUIworkersDGV.AutoSizeColumnsMode = "Fill"
# $LegacyGUIworkersDGV.AutoSizeRowsMode = "AllCells"
# $LegacyGUIworkersDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
# $LegacyGUIworkersDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
# $LegacyGUIworkersDGV.ColumnHeadersHeightSizeMode = "AutoSize"
# $LegacyGUIworkersDGV.ColumnHeadersVisible = $true
# $LegacyGUIworkersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
# $LegacyGUIworkersDGV.DefaultCellStyle.WrapMode = "True"
# $LegacyGUIworkersDGV.EnableHeadersVisualStyles = $false
# $LegacyGUIworkersDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
# $LegacyGUIworkersDGV.Height = 3
# $LegacyGUIworkersDGV.Location = [System.Drawing.Point]::new(6, ($LegacyGUIworkersLabel.Height + 8))
# $LegacyGUIworkersDGV.ReadOnly = $true
# $LegacyGUIworkersDGV.RowHeadersVisible = $false
# $LegacyGUIworkersDGV.SelectionMode = "FullRowSelect"

# $LegacyGUIworkersDGV.Add_Sorted({ Set-WorkerColor -DataGridView $LegacyGUIworkersDGV })
# Set-DataGridViewDoubleBuffer -Grid $LegacyGUIworkersDGV -Enabled $true
# $LegacyGUIrigMonitorPageControls += $LegacyGUIworkersDGV

$LegacyGUIeditMonitoringLink = [System.Windows.Forms.LinkLabel]::new()
$LegacyGUIeditMonitoringLink.ActiveLinkColor = [System.Drawing.Color]::Blue
$LegacyGUIeditMonitoringLink.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIeditMonitoringLink.Height = 20
$LegacyGUIeditMonitoringLink.Location = [System.Drawing.Point]::new(0, 6)
$LegacyGUIeditMonitoringLink.LinkColor = [System.Drawing.Color]::Blue
$LegacyGUIeditMonitoringLink.Text = "Edit the monitoring configuration"
$LegacyGUIeditMonitoringLink.TextAlign = "MiddleRight"
$LegacyGUIeditMonitoringLink.Size = [System.Drawing.Size]::new(330, 26)
$LegacyGUIeditMonitoringLink.Visible = $false
$LegacyGUIeditMonitoringLink.Width = 330
$LegacyGUIeditMonitoringLink.Add_Click({ Start-Process "http://localhost:$($Variables.APIRunspace.APIport)/rigmonitor.html" })
# $LegacyGUIrigMonitorPageControls += $LegacyGUIeditMonitoringLink
$LegacyGUItooltip.SetToolTip($LegacyGUIeditMonitoringLink, "Click to the edit the monitoring configuration in the Web GUI")

# Switching Page Controls
$LegacyGUIswitchingPageControls = @()

$LegacyGUIswitchingLogLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIswitchingLogLabel.AutoSize = $false
$LegacyGUIswitchingLogLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIswitchingLogLabel.Height = 20
$LegacyGUIswitchingLogLabel.Location = [System.Drawing.Point]::new(0, 6)
$LegacyGUIswitchingLogLabel.Width = 600
$LegacyGUIswitchingPageControls += $LegacyGUIswitchingLogLabel

$LegacyGUIswitchingLogClearButton = [System.Windows.Forms.Button]::new()
$LegacyGUIswitchingLogClearButton.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIswitchingLogClearButton.Height = 24
$LegacyGUIswitchingLogClearButton.Location = [System.Drawing.Point]::new(0, ($LegacyGUIswitchingLogLabel.Height + 8))
$LegacyGUIswitchingLogClearButton.Text = "Clear switching log"
$LegacyGUIswitchingLogClearButton.Visible = $true
$LegacyGUIswitchingLogClearButton.Width = 160
$LegacyGUIswitchingLogClearButton.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

        Get-ChildItem -Path ".\Logs\SwitchingLog.csv" -File | Remove-Item -Force
        $LegacyGUIswitchingDGV.DataSource = $null
        $Data = "Switching log '.\Logs\SwitchingLog.csv' cleared."
        Write-Message -Level Verbose "GUI: $Data" -Console $false
        $LegacyGUIswitchingLogClearButton.Enabled = $false

        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal

        [Void][System.Windows.Forms.MessageBox]::Show($Data, "$($Variables.Branding.ProductLabel) $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK, 64)
    }
)
$LegacyGUIswitchingPageControls += $LegacyGUIswitchingLogClearButton
$LegacyGUItooltip.SetToolTip($LegacyGUIswitchingLogClearButton, "This will clear the switching log '.\Logs\SwitchingLog.csv'")

$LegacyGUIcheckShowSwitchingCPU = [System.Windows.Forms.CheckBox]::new()
$LegacyGUIcheckShowSwitchingCPU.AutoSize = $false
$LegacyGUIcheckShowSwitchingCPU.Enabled = [Boolean]($Variables.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Config.ExcludeDeviceName -and $_.Type -eq "CPU" }))
$LegacyGUIcheckShowSwitchingCPU.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIcheckShowSwitchingCPU.Height = 20
$LegacyGUIcheckShowSwitchingCPU.Location = [System.Drawing.Point]::new(($LegacyGUIswitchingLogClearButton.Width + 40), ($LegacyGUIswitchingLogLabel.Height + 10))
$LegacyGUIcheckShowSwitchingCPU.Tag = "CPU"
$LegacyGUIcheckShowSwitchingCPU.Text = "CPU"
$LegacyGUIcheckShowSwitchingCPU.Width = 70
$LegacyGUIswitchingPageControls += $LegacyGUIcheckShowSwitchingCPU
$LegacyGUIcheckShowSwitchingCPU.ForEach({ $_.Add_Click({ CheckBoxSwitching_Click($this) }) })

$LegacyGUIcheckShowSwitchingAMD = [System.Windows.Forms.CheckBox]::new()
$LegacyGUIcheckShowSwitchingAMD.AutoSize = $false
$LegacyGUIcheckShowSwitchingAMD.Enabled = [Boolean]($Variables.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Config.ExcludeDeviceName -and $_.Type -eq "GPU" -and $_.Vendor -eq "AMD" }))
$LegacyGUIcheckShowSwitchingAMD.Height = 20
$LegacyGUIcheckShowSwitchingAMD.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIcheckShowSwitchingAMD.Location = [System.Drawing.Point]::new(($LegacyGUIswitchingLogClearButton.Width + 40 + $LegacyGUIcheckShowSwitchingCPU.Width), ($LegacyGUIswitchingLogLabel.Height + 10))
$LegacyGUIcheckShowSwitchingAMD.Tag = "AMD"
$LegacyGUIcheckShowSwitchingAMD.Text = "AMD"
$LegacyGUIcheckShowSwitchingAMD.Width = 70
$LegacyGUIswitchingPageControls += $LegacyGUIcheckShowSwitchingAMD
$LegacyGUIcheckShowSwitchingAMD.ForEach({ $_.Add_Click({ CheckBoxSwitching_Click($this) }) })

$LegacyGUIcheckShowSwitchingINTEL = [System.Windows.Forms.CheckBox]::new()
$LegacyGUIcheckShowSwitchingINTEL.AutoSize = $false
$LegacyGUIcheckShowSwitchingINTEL.Enabled = [Boolean]($Variables.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Config.ExcludeDeviceName -and $_.Type -eq "GPU" -and $_.Vendor -eq "INTEL" }))
$LegacyGUIcheckShowSwitchingINTEL.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIcheckShowSwitchingINTEL.Height = 20
$LegacyGUIcheckShowSwitchingINTEL.Location = [System.Drawing.Point]::new(($LegacyGUIswitchingLogClearButton.Width + 40 + $LegacyGUIcheckShowSwitchingCPU.Width + $LegacyGUIcheckShowSwitchingAMD.Width), ($LegacyGUIswitchingLogLabel.Height + 10))
$LegacyGUIcheckShowSwitchingINTEL.Tag = "INTEL"
$LegacyGUIcheckShowSwitchingINTEL.Text = "INTEL"
$LegacyGUIcheckShowSwitchingINTEL.Width = 77
$LegacyGUIswitchingPageControls += $LegacyGUIcheckShowSwitchingINTEL
$LegacyGUIcheckShowSwitchingINTEL.ForEach({ $_.Add_Click({ CheckBoxSwitching_Click($this) }) })

$LegacyGUIcheckShowSwitchingNVIDIA = [System.Windows.Forms.CheckBox]::new()
$LegacyGUIcheckShowSwitchingNVIDIA.AutoSize = $false
$LegacyGUIcheckShowSwitchingNVIDIA.Enabled = [Boolean]($Variables.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Config.ExcludeDeviceName -and $_.Type -eq "GPU" -and $_.Vendor -eq "NVIDIA" }))
$LegacyGUIcheckShowSwitchingNVIDIA.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIcheckShowSwitchingNVIDIA.Height = 20
$LegacyGUIcheckShowSwitchingNVIDIA.Location = [System.Drawing.Point]::new(($LegacyGUIswitchingLogClearButton.Width + 40 + $LegacyGUIcheckShowSwitchingCPU.Width + $LegacyGUIcheckShowSwitchingAMD.Width + $LegacyGUIcheckShowSwitchingINTEL.Width), ($LegacyGUIswitchingLogLabel.Height + 10))
$LegacyGUIcheckShowSwitchingNVIDIA.Tag = "NVIDIA"
$LegacyGUIcheckShowSwitchingNVIDIA.Text = "NVIDIA"
$LegacyGUIcheckShowSwitchingNVIDIA.Width = 80
$LegacyGUIswitchingPageControls += $LegacyGUIcheckShowSwitchingNVIDIA
$LegacyGUIcheckShowSwitchingNVIDIA.ForEach({ $_.Add_Click({ CheckBoxSwitching_Click($this) }) })

$LegacyGUIswitchingDGV = [System.Windows.Forms.DataGridView]::new()
$LegacyGUIswitchingDGV.AllowUserToAddRows = $false
$LegacyGUIswitchingDGV.AllowUserToDeleteRows = $false
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
$LegacyGUIswitchingDGV.Location = [System.Drawing.Point]::new(0, ($LegacyGUIswitchingLogLabel.Height + $LegacyGUIswitchingLogClearButton.Height + 12))
$LegacyGUIswitchingDGV.Name = "SwitchingDGV"
$LegacyGUIswitchingDGV.ReadOnly = $true
$LegacyGUIswitchingDGV.RowHeadersVisible = $false
$LegacyGUIswitchingDGV.SelectionMode = "FullRowSelect"
$LegacyGUIswitchingDGV.Add_Sorted(
    { 
        If ($Config.UseColorForMinerStatus) { 
            ForEach ($Row in $LegacyGUIswitchingDGV.Rows) { 
                $Row.DefaultCellStyle.Backcolor = $Row.DefaultCellStyle.SelectionBackColor = $LegacyGUIcolors[$Row.DataBoundItem.Action]
                $Row.DefaultCellStyle.SelectionForeColor = $LegacyGUIswitchingDGV.DefaultCellStyle.ForeColor
            }
        }
     }
)
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIswitchingDGV -Enabled $true
$LegacyGUIswitchingPageControls += $LegacyGUIswitchingDGV

$LegacyGUIcheckShowSwitchingCPU.Checked = $LegacyGUIcheckShowSwitchingCPU.Enabled
$LegacyGUIcheckShowSwitchingAMD.Checked = $LegacyGUIcheckShowSwitchingAMD.Enabled
$LegacyGUIcheckShowSwitchingINTEL.Checked = $LegacyGUIcheckShowSwitchingINTEL.Enabled
$LegacyGUIcheckShowSwitchingNVIDIA.Checked = $LegacyGUIcheckShowSwitchingNVIDIA.Enabled

# Watchdog Page Controls
$LegacyGUIwatchdogTimersPageControls = @()

$LegacyGUIwatchdogTimersLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIwatchdogTimersLabel.AutoSize = $false
$LegacyGUIwatchdogTimersLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIwatchdogTimersLabel.Height = 20
$LegacyGUIwatchdogTimersLabel.Location = [System.Drawing.Point]::new(0, 6)
$LegacyGUIwatchdogTimersLabel.Width = 600
$LegacyGUIwatchdogTimersPageControls += $LegacyGUIwatchdogTimersLabel

$LegacyGUIwatchdogTimersRemoveButton = [System.Windows.Forms.Button]::new()
$LegacyGUIwatchdogTimersRemoveButton.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIwatchdogTimersRemoveButton.Height = 24
$LegacyGUIwatchdogTimersRemoveButton.Location = [System.Drawing.Point]::new(0, ($LegacyGUIwatchdogTimersLabel.Height + 8))
$LegacyGUIwatchdogTimersRemoveButton.Text = "Remove all watchdog timers"
$LegacyGUIwatchdogTimersRemoveButton.Visible = $true
$LegacyGUIwatchdogTimersRemoveButton.Width = 220
$LegacyGUIwatchdogTimersRemoveButton.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

        $Variables.WatchdogTimers = [System.Collections.Generic.List[PSCustomObject]]::new()
        $LegacyGUIwatchdogTimersDGV.DataSource = $null
        Foreach ($Miner in $Variables.Miners) { 
            $Miner.Reasons.Where({ $_ -like "Miner suspended by watchdog *" }).ForEach({ $Miner.Reasons.Remove($_) | Out-Null })
            If (-not $Miner.Reasons.Count) { $_.Available = $true }
        }
        Remove-Variable Miner

        ForEach ($Pool in $Variables.Pools.ForEach) { 
            $Pool.Reasons.Where({ $_ -like "Pool suspended by watchdog *" }).ForEach({ $Pool.Reasons.Remove($_) | Out-Null })
            If (-not $Pool.Reasons.Count) { $Pool.Available = $true }
        }
        Remove-Variable Pool

        Write-Message -Level Verbose "GUI: All watchdog timers removed." -Console $false
        Update-TabControl

        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal

        [Void][System.Windows.Forms.MessageBox]::Show("All watchdog timers removed.`nWatchdog timers will be recreated in the next cycle.", "$($Variables.Branding.ProductLabel) $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK, 64)
    }
)
$LegacyGUIwatchdogTimersPageControls += $LegacyGUIwatchdogTimersRemoveButton
$LegacyGUItooltip.SetToolTip($LegacyGUIwatchdogTimersRemoveButton, "This will remove all watchdog timers.`rWatchdog timers will be recreated in the next cycle.")

$LegacyGUIwatchdogTimersDGV = [System.Windows.Forms.DataGridView]::new()
$LegacyGUIwatchdogTimersDGV.AllowUserToAddRows = $false
$LegacyGUIwatchdogTimersDGV.AllowUserToDeleteRows = $false
$LegacyGUIwatchdogTimersDGV.AllowUserToOrderColumns = $true
$LegacyGUIwatchdogTimersDGV.AllowUserToResizeColumns = $true
$LegacyGUIwatchdogTimersDGV.AllowUserToResizeRows = $false
$LegacyGUIwatchdogTimersDGV.AutoSizeColumnsMode = "Fill"
$LegacyGUIwatchdogTimersDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIwatchdogTimersDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIwatchdogTimersDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LegacyGUIwatchdogTimersDGV.ColumnHeadersVisible = $true
$LegacyGUIwatchdogTimersDGV.DefaultCellStyle.SelectionBackColor = $LegacyGUIwatchdogTimersDGV.DefaultCellStyle.BackColor
$LegacyGUIwatchdogTimersDGV.DefaultCellStyle.SelectionForeColor = $LegacyGUIwatchdogTimersDGV.DefaultCellStyle.ForeColor
$LegacyGUIwatchdogTimersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LegacyGUIwatchdogTimersDGV.EnableHeadersVisualStyles = $false
$LegacyGUIwatchdogTimersDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$LegacyGUIwatchdogTimersDGV.Height = 3
$LegacyGUIwatchdogTimersDGV.Location = [System.Drawing.Point]::new(0, ($LegacyGUIwatchdogTimersLabel.Height + $LegacyGUIwatchdogTimersRemoveButton.Height + 12))
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
# $LegacyGUIrigMonitorPage.Controls.AddRange(@($LegacyGUIrigMonitorPageControls))
$LegacyGUIswitchingPage.Controls.AddRange(@($LegacyGUIswitchingPageControls))
$LegacyGUIwatchdogTimersPage.Controls.AddRange(@($LegacyGUIwatchdogTimersPageControls))

$LegacyGUItabControl = [System.Windows.Forms.TabControl]::new()
$LegacyGUItabControl.Appearance = "Buttons"
$LegacyGUItabControl.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUItabControl.Height = 0
$LegacyGUItabControl.Location = [System.Drawing.Point]::new(12, $LegacyGUIminingSummaryLabel.Bottom + 10)
$LegacyGUItabControl.Name = "TabControl"
$LegacyGUItabControl.ShowToolTips = $true
$LegacyGUItabControl.Padding = [System.Drawing.Point]::new(18, 6)
$LegacyGUItabControl.Width = 0
# $LegacyGUItabControl.Controls.AddRange(@($LegacyGUIstatusPage, $LegacyGUIearningsPage, $LegacyGUIminersPage, $LegacyGUIpoolsPage, $LegacyGUIrigMonitorPage, $LegacyGUIswitchingPage, $LegacyGUIwatchdogTimersPage))
$LegacyGUItabControl.Controls.AddRange(@($LegacyGUIstatusPage, $LegacyGUIearningsPage, $LegacyGUIminersPage, $LegacyGUIpoolsPage, $LegacyGUIswitchingPage, $LegacyGUIwatchdogTimersPage))
$LegacyGUItabControl.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        Update-TabControl
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)

$LegacyGUIform.Controls.Add($LegacyGUItabControl)
$LegacyGUIform.KeyPreview = $true
$LegacyGUIform.ResumeLayout()

$LegacyGUIform.Add_Load(
    { 
        # Restore window size
        If ((Test-Path -LiteralPath ".\Config\WindowSettings.json" -PathType Leaf) -and ($WindowSettings = [System.IO.File]::ReadAllLines("$PWD\Config\WindowSettings.json") | ConvertFrom-Json -AsHashtable)) { 
            # Ensure form is displayed inside the available screen space
            If ($WindowSettings.Top -gt 0 -and $WindowSettings.Top -lt [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize.Height * 0.95) { $LegacyGUIform.Top = $WindowSettings.Top }
            If ($WindowSettings.Left -gt 0 -and $WindowSettings.Left -lt [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize.Width * 0.95) { $LegacyGUIform.Left = $WindowSettings.Left }
            If ($WindowSettings.Width -gt $LegacyGUIform.MinimumSize.Width) { $LegacyGUIform.Width = $WindowSettings.Width }
            If ($WindowSettings.Height -gt $LegacyGUIform.MinimumSize.Height) { $LegacyGUIform.Height = $WindowSettings.Height }
        }
        If ($Config.LegacyGUIStartMinimized) { $LegacyGUIform.WindowState = [System.Windows.Forms.FormWindowState]::Minimized }

        Update-GUIstatus

        Switch ($Variables.MiningStatus) { 
            "Idle" { 
                $LegacyGUIbuttonPause.Enabled = $true
                $LegacyGUIbuttonStart.Enabled = $true
                $LegacyGUIbuttonStop.Enabled = $false
                Break
            }
            "Paused" { 
                $LegacyGUIbuttonPause.Enabled = $false
                $LegacyGUIbuttonStart.Enabled = $true
                $LegacyGUIbuttonStop.Enabled = $true
                Break
            }
            "Running" { 
                $LegacyGUIbuttonPause.Enabled = $true
                $LegacyGUIbuttonStart.Enabled = $false
                $LegacyGUIbuttonStop.Enabled = $true
            }
        }

        $TimerUI = [System.Windows.Forms.Timer]::new()
        $TimerUI.Interval = 500
        $TimerUI.Add_Tick(
            { 
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
                MainLoop
            }
        )
        $TimerUI.Start()
    }
)

$LegacyGUIform.Add_FormClosing(
    { 
        If ($Config.LegacyGUI) { 
            $MsgBoxInput = [System.Windows.Forms.MessageBox]::Show("Do you want to shut down $($Variables.Branding.ProductLabel)?", "$($Variables.Branding.ProductLabel)", [System.Windows.Forms.MessageBoxButtons]::YesNo, 32, "Button2")
            If ($MsgBoxInput -eq "No") { 
                $_.Cancel = $true
                Return
            }
        }
        Else { 
            $MsgBoxInput = [System.Windows.Forms.MessageBox]::Show("Do you also want to shut down $($Variables.Branding.ProductLabel)?", "$($Variables.Branding.ProductLabel)", [System.Windows.Forms.MessageBoxButtons]::YesNoCancel, 32, "Button3")
            If ($MsgBoxInput -eq "Cancel") { 
                $_.Cancel = $true
                Return
            }
        }

        # Save window settings
        If ($LegacyGUIform.DesktopBounds.Width -ge 0) { [PSCustomObject]@{ Top = $LegacyGUIform.Top; Left = $LegacyGUIform.Left; Height = $LegacyGUIform.Height; Width = $LegacyGUIform.Width } | ConvertTo-Json | Out-File -LiteralPath ".\Config\WindowSettings.json" -Force -ErrorAction Ignore }

        If ($MsgBoxInput -eq "Yes") { 
            $LegacyGUItabControl.SelectTab(0)
            $TimerUI.Stop()
            Write-Message -Level Info "Shutting down $($Variables.Branding.ProductLabel)..."
            $Variables.NewMiningStatus = "Idle"

            Stop-Core
            Stop-Brain
            Stop-BalancesTracker

            Write-Message -Level Info "$($Variables.Branding.ProductLabel) has shut down."
            Start-Sleep -Seconds 2
            Stop-Process $PID -Force
        }
    }
)

$LegacyGUIform.Add_KeyDown(
    { 
        If ($Variables.NewMiningStatus -eq "Running" -and $_.Control -and $_.Alt -and $_.KeyCode -eq "P") { 
            # '<Ctrl><Alt>P' pressed
            If (-not $Global:CoreRunspace.AsyncObject.IsCompleted -eq $false) { 
                # Core is complete / gone. Cycle cannot be suspended anymore
                $Variables.SuspendCycle = $false
            }
            Else { 
                $Variables.SuspendCycle = -not $Variables.SuspendCycle
                If ($Variables.SuspendCycle) { 
                    $Message = "'<Ctrl><Alt>P' pressed. Core cycle is suspended until you press '<Ctrl><Alt>P' again."
                    $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Blue
                    $LegacyGUIminingSummaryLabel.Text = $Message
                    $LegacyGUIbuttonPause.Enabled = $false
                    Write-Host $Message -ForegroundColor Cyan
                }
                Else { 
                    $Message = "'<Ctrl><Alt>P' pressed. Core cycle is running again."
                    $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Blue
                    $LegacyGUIminingSummaryLabel.Text = $Message
                    $LegacyGUIbuttonPause.Enabled = $true
                    Write-Host $Message -ForegroundColor Cyan
                    If ([DateTime]::Now.ToUniversalTime() -gt $Variables.EndCycleTime) { $Variables.EndCycleTime = [DateTime]::Now.ToUniversalTime() }
                }
            }
        }
        ElseIf ($_.KeyCode -eq "F5") { 
            $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
            # Clear selection, this will allow refreshing the table data
            $LegacyGUIactiveMinersDGV.ClearSelection()
            $LegacyGUIbalancesDGV.ClearSelection()
            $LegacyGUIminersDGV.ClearSelection()
            $LegacyGUIpoolsDGV.ClearSelection()
            # $LegacyGUIworkersDGV.ClearSelection()

            Update-TabControl
            $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
        }
    }
)

$LegacyGUIform.Add_SizeChanged({ Resize-Form })