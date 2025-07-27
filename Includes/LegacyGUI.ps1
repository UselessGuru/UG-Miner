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
Version:        6.5.2
Version date:   2025/07/27
#>

[Void][System.Reflection.Assembly]::Load("System.Windows.Forms")
[Void][System.Reflection.Assembly]::Load("System.Windows.Forms.DataVisualization")
[Void][System.Reflection.Assembly]::Load("System.Drawing")

# For High DPI, Call SetProcessDPIAware(need P/Invoke) and EnableVisualStyles
Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class ProcessDPI { 
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool SetProcessDPIAware(); 
}
'@
$null = [ProcessDPI]::SetProcessDPIAware()
[System.Windows.Forms.Application]::EnableVisualStyles()

$LegacyGUIelements = [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase) # as case insensitve sorted hashtable

Function Resize-Form { 

    If ($LegacyGUIform.Height -lt $LegacyGUIform.MinimumSize.Height -or $LegacyGUIform.Width -lt $LegacyGUIform.MinimumSize.Width) { Return } # Sometimes $LegacyGUIform is smaller than minimum (Why?)
    Try { 
        $LegacyGUIelements.TabControl.Height = $LegacyGUIform.ClientSize.Height - $LegacyGUIelements.MiningStatusLabel.Height - $LegacyGUIelements.MiningSummaryLabel.Height - $LegacyGUIelements.EditConfigLink.Height - $LegacyGUIelements.EditConfigLink.Height + 3
        $LegacyGUIelements.TabControl.Width = $LegacyGUIform.ClientSize.Width - 16

        $LegacyGUIelements.ButtonStart.Location = [System.Drawing.Point]::new(($LegacyGUIform.ClientSize.Width - $LegacyGUIelements.ButtonStop.Width - $LegacyGUIelements.ButtonPause.Width - $LegacyGUIelements.ButtonStart.Width - 42), 2)
        $LegacyGUIelements.ButtonPause.Location = [System.Drawing.Point]::new(($LegacyGUIform.ClientSize.Width - $LegacyGUIelements.ButtonStop.Width - $LegacyGUIelements.ButtonPause.Width - 32), 2)
        $LegacyGUIelements.ButtonStop.Location  = [System.Drawing.Point]::new(($LegacyGUIform.ClientSize.Width - $LegacyGUIelements.ButtonStop.Width - 22), 2)

        # $LegacyGUIelements.EditMonitoringLink.Location = [System.Drawing.Point]::new(($LegacyGUIelements.TabControl.Width - $LegacyGUIelements.EditMonitoringLink.Width - 12), 6)
        $LegacyGUIelements.MiningSummaryLabel.Width = $LegacyGUIelements.ActiveMinersDGV.Width = $LegacyGUIelements.EarningsChart.Width = $LegacyGUIelements.BalancesDGV.Width = $LegacyGUIelements.MinersPanel.Width = $LegacyGUIelements.MinersDGV.Width = $LegacyGUIelements.PoolsPanel.Width = $LegacyGUIelements.PoolsDGV.Width = $LegacyGUIelements.SwitchingDGV.Width = $LegacyGUIelements.WatchdogTimersDGV.Width = $LegacyGUIform.ClientSize.Width - 44
        $Session.TextBoxSystemLog.Width = $LegacyGUIelements.TabControl.ClientSize.Width - 20

        $LegacyGUIelements.EditConfigLink.Location = [System.Drawing.Point]::new(18, ($LegacyGUIform.ClientSize.Height - $LegacyGUIelements.EditConfigLink.Height - 4))
        $LegacyGUIelements.CopyrightLabel.Location = [System.Drawing.Point]::new(($LegacyGUIelements.TabControl.ClientSize.Width - $LegacyGUIelements.CopyrightLabel.Width - 4), ($LegacyGUIform.ClientSize.Height - $LegacyGUIelements.EditConfigLink.Height - 4))

        If ($Config.BalancesTrackerPollInterval -gt 0) { 
            $LegacyGUIelements.BalancesDGV.Visible = $true
            $LegacyGUIelements.EarningsChart.Visible = $true

            $BalancesDGVHeight = $LegacyGUIelements.BalancesDGV.RowTemplate.Height * $LegacyGUIelements.BalancesDGV.RowCount + $LegacyGUIelements.BalancesDGV.ColumnHeadersHeight
            If ($BalancesDGVHeight -gt $LegacyGUIelements.TabControl.ClientSize.Height / 2) { 
                $BalancesDGVHeight = $LegacyGUIelements.TabControl.ClientSize.Height / 2
                $LegacyGUIelements.BalancesDGV.ScrollBars = "Vertical"
            }
            Else { 
                $LegacyGUIelements.BalancesDGV.ScrollBars = "None"
            }
            $LegacyGUIelements.BalancesDGV.Height = $BalancesDGVHeight
            $LegacyGUIelements.EarningsChart.Height = $LegacyGUIelements.TabControl.ClientSize.Height - $LegacyGUIelements.BalancesDGV.Height - $LegacyGUIelements.BalancesLabel.Height - 59
            $LegacyGUIelements.BalancesLabel.Location = [System.Drawing.Point]::new(0, $LegacyGUIelements.EarningsChart.Bottom)
            $LegacyGUIelements.BalancesDGV.Top = $LegacyGUIelements.BalancesLabel.Bottom
        }
        Else { 
            $LegacyGUIelements.BalancesDGV.Visible = $false
            $LegacyGUIelements.BalancesLabel.Location = [System.Drawing.Point]::new(0, 20)
            $LegacyGUIelements.EarningsChart.Visible = $false
            $LegacyGUIelements.EarningsChart.Height = 0
        }

        $ActiveMinersDGVHeight = $LegacyGUIelements.ActiveMinersDGV.RowTemplate.Height * $LegacyGUIelements.ActiveMinersDGV.RowCount + $LegacyGUIelements.ActiveMinersDGV.ColumnHeadersHeight
        If ($ActiveMinersDGVHeight -gt $LegacyGUIelements.TabControl.ClientSize.Height / 2) { $ActiveMinersDGVHeight = $LegacyGUIelements.TabControl.ClientSize.Height / 2 }
        $LegacyGUIelements.ActiveMinersDGV.Height = $ActiveMinersDGVHeight

        $LegacyGUIelements.SystemLogLabel.Location = [System.Drawing.Point]::new(1, ($LegacyGUIelements.ActiveMinersLabel.Height + $LegacyGUIelements.ActiveMinersDGV.Height + 30))
        $Session.TextBoxSystemLog.Location = [System.Drawing.Point]::new(0, ($LegacyGUIelements.ActiveMinersLabel.Height + $LegacyGUIelements.ActiveMinersDGV.Height + $LegacyGUIelements.SystemLogLabel.Height + 36))
        $Session.TextBoxSystemLog.Height = ($LegacyGUIelements.TabControl.ClientSize.Height - $LegacyGUIelements.ActiveMinersLabel.Height - $LegacyGUIelements.ActiveMinersDGV.Height - $LegacyGUIelements.SystemLogLabel.Height - 95)
        If (-not $Session.TextBoxSystemLog.SelectionLength) { $Session.TextBoxSystemLog.ScrollToCaret() }

        $LegacyGUIelements.MinersDGV.Height = $LegacyGUIelements.TabControl.ClientSize.Height - $LegacyGUIelements.MinersLabel.Height - $LegacyGUIelements.MinersPanel.Height - 74
        $LegacyGUIelements.PoolsDGV.Height = $LegacyGUIelements.TabControl.ClientSize.Height - $LegacyGUIelements.PoolsLabel.Height - $LegacyGUIelements.PoolsPanel.Height - 74
        # $LegacyGUIelements.WorkersDGV.Height = $LegacyGUIelements.TabControl.ClientSize.Height - $LegacyGUIelements.WorkersLabel.Height - 74
        $LegacyGUIelements.SwitchingDGV.Height = $LegacyGUIelements.TabControl.ClientSize.Height - $LegacyGUIelements.SwitchingLogLabel.Height - $LegacyGUIelements.SwitchingLogClearButton.Height - 77
        $LegacyGUIelements.WatchdogTimersDGV.Height = $LegacyGUIelements.TabControl.ClientSize.Height - $LegacyGUIelements.WatchdogTimersLabel.Height - $LegacyGUIelements.WatchdogTimersRemoveButton.Height - 77
    }
    Catch { 
        Start-Sleep 0
    }
}

Function CheckBoxSwitching_Click { 
    $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $LegacyGUIelements.SwitchingDGV.ClearSelection()

    $SwitchingDisplayTypes = @()
    $LegacyGUIelements.SwitchingPageControls.ForEach({ If ($_.Checked) { $SwitchingDisplayTypes += $_.Tag } })
    If (Test-Path -LiteralPath ".\Logs\SwitchingLog.csv" -PathType Leaf) { 
        $LegacyGUIelements.SwitchingLogLabel.Text = "Switching log updated $((Get-ChildItem -Path ".\Logs\SwitchingLog.csv").LastWriteTime.ToString())"
        $LegacyGUIelements.SwitchingDGV.DataSource = (([System.IO.File]::ReadAllLines("$PWD\Logs\SwitchingLog.csv") | ConvertFrom-Csv).Where({ $SwitchingDisplayTypes -contains $_.Type }) | Select-Object -Last 1000).ForEach({ $_.Datetime = (Get-Date $_.DateTime); $_ }) | Sort-Object -Property DateTime -Descending | Select-Object @("DateTime", "Action", "Name", "Pools", "Algorithms", "Accounts", "Cycle", "Duration", "DeviceNames", "Type") | Out-DataTable
        If ($LegacyGUIelements.SwitchingDGV.Columns) { 
            $LegacyGUIelements.SwitchingDGV.Columns[0].FillWeight = 50; $LegacyGUIelements.SwitchingDGV.Sort($LegacyGUIelements.SwitchingDGV.Columns[0], [System.ComponentModel.ListSortDirection]::Descending)
            $LegacyGUIelements.SwitchingDGV.Columns[1].FillWeight = 50
            $LegacyGUIelements.SwitchingDGV.Columns[2].FillWeight = 90; $LegacyGUIelements.SwitchingDGV.Columns[2].HeaderText = "Miner"
            $LegacyGUIelements.SwitchingDGV.Columns[3].FillWeight = 60 + ($LegacyGUIelements.SwitchingDGV.MinersBest_Combo.ForEach({ $_.Pools.Count }) | Measure-Object -Maximum).Maximum * 40; $LegacyGUIelements.SwitchingDGV.Columns[3].HeaderText = "Pool(s)"
            $LegacyGUIelements.SwitchingDGV.Columns[4].FillWeight = 50 + ($LegacyGUIelements.SwitchingDGV.MinersBest_Combo.ForEach({ $_.Algorithms.Count }) | Measure-Object -Maximum).Maximum * 25; $LegacyGUIelements.SwitchingDGV.Columns[4].HeaderText = "Algorithm(s) (variant)"
            $LegacyGUIelements.SwitchingDGV.Columns[5].FillWeight = 90 + ($LegacyGUIelements.SwitchingDGV.MinersBest_Combo.ForEach({ $_.Accounts.Count }) | Measure-Object -Maximum).Maximum * 50; $LegacyGUIelements.SwitchingDGV.Columns[5].HeaderText = "Account(s)"
            $LegacyGUIelements.SwitchingDGV.Columns[6].FillWeight = 30; $LegacyGUIelements.SwitchingDGV.Columns[6].HeaderText = "Cycles"; $LegacyGUIelements.SwitchingDGV.Columns[6].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIelements.SwitchingDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"
            $LegacyGUIelements.SwitchingDGV.Columns[7].FillWeight = 35; $LegacyGUIelements.SwitchingDGV.Columns[7].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIelements.SwitchingDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"
            $LegacyGUIelements.SwitchingDGV.Columns[8].FillWeight = 30 + ($LegacyGUIelements.SwitchingDGV.MinersBest_Combo.ForEach({ $_.DeviceNames.Count }) | Measure-Object -Maximum).Maximum * 15; $LegacyGUIelements.SwitchingDGV.Columns[8].HeaderText = "Device(s)"
            $LegacyGUIelements.SwitchingDGV.Columns[9].FillWeight = 30
            $LegacyGUIelements.SwitchingLogClearButton.Enabled = $true
        }
        $LegacyGUIelements.SwitchingDGV.EndInit()
    }
    Else { 
        $LegacyGUIelements.SwitchingLogLabel.Text = "Waiting for switching log data..."
        $LegacyGUIelements.SwitchingLogClearButton.Enabled = $false
    }
    If ($Config.UseColorForMinerStatus) { 
        ForEach ($Row in $LegacyGUIelements.SwitchingDGV.Rows) { $Row.DefaultCellStyle.Backcolor = $LegacyGUIelements.Colors[$Row.DataBoundItem.Action] }
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
            If ($LegacyGUIelements.Colors[$Row.DataBoundItem.SubStatus]) { 
                $Row.DefaultCellStyle.Backcolor = $LegacyGUIelements.Colors[$Row.DataBoundItem.SubStatus]
            }
        }
    }
}

# Function Set-WorkerColor { 
#     If ($Config.UseColorForMinerStatus) { 
#         ForEach ($Row in $LegacyGUIelements.WorkersDGV.Rows) { 
#             $Row.DefaultCellStyle.Backcolor = Switch ($Row.DataBoundItem.Status) { 
#                 "Offline" { $LegacyGUIelements.Colors["disabled"]; Break }
#                 "Paused"  { $LegacyGUIelements.Colors["idle"]; Break }
#                 "Running" { $LegacyGUIelements.Colors["running"]; Break }
#                 Default   { [System.Drawing.Color]::FromArgb(255, 255, 255, 255) }
#             }
#         }
#     }
# }

Function Update-TabControl { 

    Switch ($LegacyGUIelements.TabControl.SelectedTab.Text) { 
        "System status" { 
            $LegacyGUIelements.ActiveMinersDGV.ClearSelection()

            $LegacyGUIelements.ContextMenuStripItem1.Text = "Re-benchmark miner"
            $LegacyGUIelements.ContextMenuStripItem1.Visible = $true
            $LegacyGUIelements.ContextMenuStripItem2.Enabled = $Config.CalculatePowerCost
            $LegacyGUIelements.ContextMenuStripItem2.Text = "Re-measure power consumption"
            $LegacyGUIelements.ContextMenuStripItem2.Visible = $true
            $LegacyGUIelements.ContextMenuStripItem3.Enabled = $true
            $LegacyGUIelements.ContextMenuStripItem3.Text = "Mark miner as failed"
            $LegacyGUIelements.ContextMenuStripItem4.Enabled = $true
            $LegacyGUIelements.ContextMenuStripItem4.Text = "Disable miner"
            $LegacyGUIelements.ContextMenuStripItem4.Visible = $true
            $LegacyGUIelements.ContextMenuStripItem5.Enabled = $true
            $LegacyGUIelements.ContextMenuStripItem5.Text = "Enable miner"
            $LegacyGUIelements.ContextMenuStripItem5.Visible = $true
            $LegacyGUIelements.ContextMenuStripItem6.Visible = $false

            If ($Session.NewMiningStatus -eq "Idle") { 
                $LegacyGUIelements.ActiveMinersLabel.Text = "No miners running - mining is stopped"
                $LegacyGUIelements.ActiveMinersDGV.DataSource = $null
            }
            ElseIf ($Session.NewMiningStatus -eq "Paused") { 
                $LegacyGUIelements.ActiveMinersLabel.Text = "No miners running - mining is paused"
                $LegacyGUIelements.ActiveMinersDGV.DataSource = $null
            }
            ElseIf ($Session.NewMiningStatus -eq "Running" -and $Session.MiningStatus -eq "Running" -and $Global:CoreRunspace.Job.IsCompleted -eq $true) { 
                $LegacyGUIelements.ActiveMinersLabel.Text = "No data - mining is suspended"
                $LegacyGUIelements.ActiveMinersDGV.DataSource = $null
            }
            ElseIf ($Session.MinersBest) { 
                If (-not $LegacyGUIelements.ActiveMinersDGV.SelectedRows) { 
                    $LegacyGUIelements.ActiveMinersDGV.BeginInit()
                    $LegacyGUIelements.ActiveMinersDGV.ClearSelection()
                    $LegacyGUIelements.ActiveMinersDGV.DataSource = $Session.MinersBest | Select-Object @(
                        @{ Name = "Info"; Expression = { $_.Info } }
                        @{ Name = "SubStatus"; Expression = { $_.SubStatus } }
                        @{ Name = "Device(s)"; Expression = { $_.BaseName_Version_Device -replace ".+-" } }
                        @{ Name = "Status Info"; Expression = { $_.StatusInfo } }
                        @{ Name = "Earnings (biased) $($Config.FIATcurrency)/day"; Expression = { If ([Double]::IsNaN($_.Earnings)) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Earnings * $Session.Rates.BTC.($Config.FIATcurrency)) } } }
                        @{ Name = "Power cost $($Config.FIATcurrency)/day"; Expression = { If ([Double]::IsNaN($_.PowerCost) -or -not $Session.CalculatePowerCost) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Powercost * $Session.Rates.BTC.($Config.FIATcurrency)) } } }
                        @{ Name = "Profit (biased) $($Config.FIATcurrency)/day"; Expression = { If ([Double]::IsNaN($_.PowerCost) -or -not $Session.CalculatePowerCost) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Profit * $Session.Rates.BTC.($Config.FIATcurrency)) } } }
                        @{ Name = "Power consumption (live)"; Expression = { If ($_.MeasurePowerConsumption) { If ($_.Status -eq "Running") { "Measuring..." } Else { "Unmeasured" } } Else { If ([Double]::IsNaN($_.PowerConsumption_Live)) { "n/a" } Else { "$($_.PowerConsumption_Live.ToString("N2")) W" } } } }
                        @{ Name = "Algorithm (variant) [Currency]"; Expression = { $_.WorkersRunning.ForEach({ "$($_.Pool.AlgorithmVariant)$(If ($_.Pool.Currency) { "[$($_.Pool.Currency)]" })" }) -join " & " } },
                        @{ Name = "Pool"; Expression = { $_.WorkersRunning.Pool.Name -join " & " } }
                        @{ Name = "Hashrate (live)"; Expression = { If ($_.Benchmark) { If ($_.Status -eq "Running") { "Benchmarking..." } Else { "Benchmark pending" } } Else { $_.WorkersRunning.ForEach({ $_.Hashrates_Live | ConvertTo-Hash }) -join " & " } } }
                        @{ Name = "Running time (hhh:mm:ss)"; Expression = { "{0}:{1:mm}:{1:ss}" -f [Math]::floor(([DateTime]::Now.ToUniversalTime() - $_.BeginTime).TotalDays * 24), ([DateTime]::Now.ToUniversalTime() - $_.BeginTime) } }
                        @{ Name = "Total active (hhh:mm:ss)"; Expression = { "{0}:{1:mm}:{1:ss}" -f [Math]::floor($_.TotalMiningDuration.TotalDays * 24), $_.TotalMiningDuration } }
                    ) | Out-DataTable
                    $LegacyGUIelements.ActiveMinersDGV.Sort($LegacyGUIelements.ActiveMinersDGV.Columns[2], [System.ComponentModel.ListSortDirection]::Ascending)
                    $LegacyGUIelements.ActiveMinersDGV.ClearSelection()
                    $LegacyGUIelements.ActiveMinersLabel.Text = "Active miners updated $($Session.MinersUpdatedTimestamp.ToLocalTime().ToString("G")) ($($LegacyGUIelements.ActiveMinersDGV.Rows.count) miner$(If ($LegacyGUIelements.ActiveMinersDGV.Rows.count -ne 1) { "s" }))"

                    $LegacyGUIelements.ActiveMinersDGV.Columns[0].Visible = $false
                    $LegacyGUIelements.ActiveMinersDGV.Columns[1].Visible = $false
                    If (-not $LegacyGUIelements.ActiveMinersDGV.ColumnWidthChanged -and $LegacyGUIelements.ActiveMinersDGV.Columns) { 
                        $LegacyGUIelements.ActiveMinersDGV.Columns[2].FillWeight = 45 + ($Session.MinersBest.ForEach({ $_.DeviceNames.Count }) | Measure-Object -Maximum).Maximum * 20
                        $LegacyGUIelements.ActiveMinersDGV.Columns[3].FillWeight = 190
                        $LegacyGUIelements.ActiveMinersDGV.Columns[4].FillWeight = 55; $LegacyGUIelements.ActiveMinersDGV.Columns[4].DefaultCellStyle.Alignment = $LegacyGUIelements.ActiveMinersDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.ActiveMinersDGV.Columns[5].FillWeight = 55; $LegacyGUIelements.ActiveMinersDGV.Columns[5].DefaultCellStyle.Alignment = $LegacyGUIelements.ActiveMinersDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.ActiveMinersDGV.Columns[5].Visible = $Session.CalculatePowerCost
                        $LegacyGUIelements.ActiveMinersDGV.Columns[6].FillWeight = 55; $LegacyGUIelements.ActiveMinersDGV.Columns[6].DefaultCellStyle.Alignment = $LegacyGUIelements.ActiveMinersDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.ActiveMinersDGV.Columns[6].Visible = $Session.CalculatePowerCost
                        $LegacyGUIelements.ActiveMinersDGV.Columns[7].FillWeight = 55; $LegacyGUIelements.ActiveMinersDGV.Columns[7].DefaultCellStyle.Alignment = $LegacyGUIelements.ActiveMinersDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.ActiveMinersDGV.Columns[7].Visible = $Session.CalculatePowerCost
                        $LegacyGUIelements.ActiveMinersDGV.Columns[8].FillWeight = 60 + ($Session.MinersBest.ForEach({ $_.Workers.Count }) | Measure-Object -Maximum).Maximum * 30
                        $LegacyGUIelements.ActiveMinersDGV.Columns[9].FillWeight = 45 + ($Session.MinersBest.ForEach({ $_.Workers.Count }) | Measure-Object -Maximum).Maximum * 25
                        $LegacyGUIelements.ActiveMinersDGV.Columns[10].FillWeight = 45 + ($Session.MinersBest.ForEach({ $_.Workers.Count }) | Measure-Object -Maximum).Maximum * 25; $LegacyGUIelements.ActiveMinersDGV.Columns[10].DefaultCellStyle.Alignment = $LegacyGUIelements.ActiveMinersDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.ActiveMinersDGV.Columns[11].FillWeight = 50; $LegacyGUIelements.ActiveMinersDGV.Columns[11].DefaultCellStyle.Alignment = $LegacyGUIelements.ActiveMinersDGV.Columns[11].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.ActiveMinersDGV.Columns[12].FillWeight = 50; $LegacyGUIelements.ActiveMinersDGV.Columns[12].DefaultCellStyle.Alignment = $LegacyGUIelements.ActiveMinersDGV.Columns[12].HeaderCell.Style.Alignment = "MiddleRight"

                        $LegacyGUIelements.ActiveMinersDGV | Add-Member ColumnWidthChanged $true -Force
                    }
                    $LegacyGUIelements.ActiveMinersDGV.EndInit()
                    Set-TableColor -DataGridView $LegacyGUIelements.ActiveMinersDGV
                }
            }
            Else { 
                $LegacyGUIelements.ActiveMinersLabel.Text = "Waiting for active miner data..."
                $LegacyGUIelements.ActiveMinersDGV.DataSource = $null
            }
            Break
        }
        "Earnings and balances" { 

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

            If ($Config.BalancesTrackerPollInterval -gt 0) { 
                If ($Datasource = [System.IO.File]::ReadAllLines("$PWD\Data\EarningsChartData.json") | ConvertFrom-Json -ErrorAction Ignore) { 
                    Try { 
                        $ChartTitle = [System.Windows.Forms.DataVisualization.Charting.Title]::new()
                        $ChartTitle.Alignment = "TopCenter"
                        $ChartTitle.Font = [System.Drawing.Font]::new("Arial", 10)
                        $ChartTitle.Text = "Earnings of the past $($DataSource.Labels.Count) active days"
                        $LegacyGUIelements.EarningsChart.Titles.Clear()
                        $LegacyGUIelements.EarningsChart.Titles.Add($ChartTitle)

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

                        $LegacyGUIelements.EarningsChart.ChartAreas.Clear()
                        $LegacyGUIelements.EarningsChart.ChartAreas.Add($ChartArea)
                        $LegacyGUIelements.EarningsChart.Series.Clear()

                        $DaySum = @(0) * $DataSource.Labels.Count
                        $LegacyGUIelements.TooltipText = $DataSource.Labels.Clone()

                        $Color = @(255, 255, 255, 255) #"FFFFFF"
                        ForEach ($Pool in $DataSource.Earnings.PSObject.Properties.Name) { 

                            $Color = (Get-NextColor -Color $Color -Factors -0, -20, -20, -20)

                            $LegacyGUIelements.EarningsChart.Series.Add($Pool)
                            $LegacyGUIelements.EarningsChart.Series[$Pool].ChartType = "StackedColumn"
                            $LegacyGUIelements.EarningsChart.Series[$Pool].BorderWidth = 3
                            $LegacyGUIelements.EarningsChart.Series[$Pool].Color = [System.Drawing.Color]::FromArgb($Color[0], $Color[1], $Color[2], $Color[3])

                            $I = 0
                            $Datasource.Earnings.$Pool.ForEach(
                                { 
                                    $_ *= $Session.Rates.BTC.($Config.FIATcurrency)
                                    $LegacyGUIelements.EarningsChart.Series[$Pool].Points.addxy(0, $_) | Out-Null
                                    $Daysum[$I] += $_
                                    If ($_) { $LegacyGUIelements.TooltipText[$I] = "$($LegacyGUIelements.TooltipText[$I])`r$($Pool): {0:N$($Config.DecimalsMax)} $($Config.FIATcurrency)" -f $_ }
                                    $I ++
                                }
                            )
                        }

                        $I = 0
                        $DataSource.Labels.ForEach(
                            { 
                                $ChartArea.AxisX.CustomLabels.Add($I +0.5, $I + 1.5, " $_ ")
                                $ChartArea.AxisX.CustomLabels[$I].ToolTip = "$($LegacyGUIelements.TooltipText[$I])`rTotal: {0:N$($Config.DecimalsMax)} $($Config.FIATcurrency)" -f $Daysum[$I]
                                ForEach ($Pool in $DataSource.Earnings.PSObject.Properties.Name) { 
                                    If ($Datasource.Earnings.$Pool[$I]) { $LegacyGUIelements.EarningsChart.Series[$Pool].Points[$I].ToolTip = "$($LegacyGUIelements.TooltipText[$I])`rTotal: {0:N$($Config.DecimalsMax)} $($Config.FIATcurrency)" -f $Daysum[$I] }
                                }
                                $I ++
                            }
                        )
                        $ChartArea.AxisY.Maximum = ($DaySum | Measure-Object -Maximum).Maximum * 1.05

                        Remove-Variable I, Pool
                    }
                    Catch { }
                }

                $DataSource = $Session.Balances.Values
                If ($Session.Balances.Values.LastUpdated) { 
                    $LegacyGUIelements.BalancesLabel.Text = "Balances updated $(($Session.Balances.Values.LastUpdated | Sort-Object -Bottom 1).ToLocalTime().ToString())"

                    $LegacyGUIelements.BalancesDGV.BeginInit()
                    $LegacyGUIelements.BalancesDGV.DataSource = $DataSource | Select-Object @(
                        @{ Name = "Currency"; Expression = { $_.Currency } },
                        @{ Name = "Pool [Currency]"; Expression = { "$($_.Pool) [$($_.Currency)]" } },
                        @{ Name = "Balance ($($Config.FIATcurrency))"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Balance * $Session.Rates.($_.Currency).($Config.FIATcurrency)) } },
                        @{ Name = "$($Config.FIATcurrency) in past 1 hr"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth1 * $Session.Rates.($_.Currency).($Config.FIATcurrency)) } },
                        @{ Name = "$($Config.FIATcurrency) in past 6 hrs"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth6 * $Session.Rates.($_.Currency).($Config.FIATcurrency)) } },
                        @{ Name = "$($Config.FIATcurrency) in past 24 hrs"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth24 * $Session.Rates.($_.Currency).($Config.FIATcurrency)) } },
                        @{ Name = "$($Config.FIATcurrency) in past 7 days"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth168 * $Session.Rates.($_.Currency).($Config.FIATcurrency)) } },
                        @{ Name = "$($Config.FIATcurrency) in past 30 days"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth720 * $Session.Rates.($_.Currency).($Config.FIATcurrency)) } },
                        @{ Name = "Avg. $($Config.FIATcurrency)/1 hr"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.AvgHourlyGrowth * $Session.Rates.($_.Currency).($Config.FIATcurrency)) } },
                        @{ Name = "Avg. $($Config.FIATcurrency)/24 hrs"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.AvgDailyGrowth * $Session.Rates.($_.Currency).($Config.FIATcurrency)) } },
                        @{ Name = "Avg. $($Config.FIATcurrency)/7 days"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.AvgWeeklyGrowth * $Session.Rates.($_.Currency).($Config.FIATcurrency)) } },
                        @{ Name = "Projected pay date"; Expression = { If ($_.ProjectedPayDate -is [DateTime]) { $_.ProjectedPayDate.ToShortDateString() } Else { $_.ProjectedPayDate } } },
                        @{ Name = "Payout threshold"; Expression = { If ($_.PayoutThresholdCurrency -eq "BTC" -and $Config.UsemBTC) { $PayoutThresholdCurrency = "mBTC"; $mBTCfactor = 1000 } Else { $PayoutThresholdCurrency = $_.PayoutThresholdCurrency; $mBTCfactor = 1 }; "{0:P2} of {1} {2} " -f ($_.Balance / $_.PayoutThreshold * $Session.Rates.($_.Currency).($_.PayoutThresholdCurrency)), [String]($_.PayoutThreshold * $mBTCfactor), $PayoutThresholdCurrency } } # Cast to string to avoid extra decimal places
                    ) | Out-DataTable

                    $LegacyGUIelements.BalancesDGV.Sort($LegacyGUIelements.BalancesDGV.Columns[1], [System.ComponentModel.ListSortDirection]::Ascending)

                    If ($LegacyGUIelements.BalancesDGV.Columns) { 
                        $LegacyGUIelements.BalancesDGV.Columns[0].Visible = $false
                        $LegacyGUIelements.BalancesDGV.Columns[1].FillWeight = 120
                        $LegacyGUIelements.BalancesDGV.Columns[2].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[2].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[2].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.BalancesDGV.Columns[3].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[3].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[3].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.BalancesDGV.Columns[3].Visible = $Config.BalancesShowSums
                        $LegacyGUIelements.BalancesDGV.Columns[4].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[4].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.BalancesDGV.Columns[4].Visible = $Config.BalancesShowSums
                        $LegacyGUIelements.BalancesDGV.Columns[5].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[5].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.BalancesDGV.Columns[5].Visible = $Config.BalancesShowSums
                        $LegacyGUIelements.BalancesDGV.Columns[6].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[6].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.BalancesDGV.Columns[6].Visible = $Config.BalancesShowSums
                        $LegacyGUIelements.BalancesDGV.Columns[7].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[7].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.BalancesDGV.Columns[7].Visible = $Config.BalancesShowSums
                        $LegacyGUIelements.BalancesDGV.Columns[8].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[8].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[8].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.BalancesDGV.Columns[8].Visible = $Config.BalancesShowAverages
                        $LegacyGUIelements.BalancesDGV.Columns[9].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[9].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[9].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.BalancesDGV.Columns[9].Visible = $Config.BalancesShowAverages
                        $LegacyGUIelements.BalancesDGV.Columns[10].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[10].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.BalancesDGV.Columns[10].Visible = $Config.BalancesShowAverages
                        $LegacyGUIelements.BalancesDGV.Columns[11].FillWeight = 80
                        $LegacyGUIelements.BalancesDGV.Columns[12].FillWeight = 80
                    }
                    $LegacyGUIelements.BalancesDGV.Rows.ForEach(
                        { 
                            $_.Cells[2].ToolTipText = "Balance {0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) })" -f ([Double]$_.Cells[2].Value * $Session.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                            $_.Cells[3].ToolTipText = "{0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) }) in past 1hr" -f ([Double]$_.Cells[3].Value * $Session.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                            $_.Cells[4].ToolTipText = "{0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) }) in past 6hr" -f ([Double]$_.Cells[4].Value * $Session.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                            $_.Cells[5].ToolTipText = "{0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) }) in past 24hr" -f ([Double]$_.Cells[5].Value * $Session.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                            $_.Cells[6].ToolTipText = "{0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) }) in past 7days" -f ([Double]$_.Cells[6].Value * $Session.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                            $_.Cells[7].ToolTipText = "{0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) }) in past 30days" -f ([Double]$_.Cells[7].Value * $Session.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                            $_.Cells[8].ToolTipText = "Avg. {0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) }) / 1 hr" -f ([Double]$_.Cells[8].Value * $Session.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                            $_.Cells[9].ToolTipText = "Avg. {0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) }) / 24 hrs" -f ([Double]$_.Cells[9].Value * $Session.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                            $_.Cells[10].ToolTipText = "Avg. {0:n$($Config.DecimalsMax)} $(If ($_.Cells[0].Value -eq "BTC" -and $Config.UsemBTC) { $Factor = 1000; "mBTC" } Else { $Factor = 1; $($_.Cells[0].Value) }) / 7 days" -f ([Double]$_.Cells[10].Value * $Session.Rates.($Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                        }
                    )
                    $LegacyGUIelements.BalancesDGV.EndInit()
                }
                Else { 
                    $LegacyGUIelements.BalancesLabel.Text = "Balances tracker is running - waiting for balances data..."
                }
            }
            Else { 
                $LegacyGUIelements.BalancesLabel.Text = "Balances tracker is disabled (configuration item 'BalancesTrackerPollInterval' -eq 0)"
            }
            Break
        }
        "Miners" { 
            $LegacyGUIelements.MinersDGV.ClearSelection()

            $LegacyGUIelements.ContextMenuStripItem1.Text = "Re-benchmark miner"
            $LegacyGUIelements.ContextMenuStripItem1.Visible = $true
            $LegacyGUIelements.ContextMenuStripItem2.Enabled = $Config.CalculatePowerCost
            $LegacyGUIelements.ContextMenuStripItem2.Text = "Re-measure power consumption"
            $LegacyGUIelements.ContextMenuStripItem2.Visible = $true
            $LegacyGUIelements.ContextMenuStripItem3.Enabled = $true
            $LegacyGUIelements.ContextMenuStripItem3.Text = "Mark miner as failed"
            $LegacyGUIelements.ContextMenuStripItem4.Enabled = $true
            $LegacyGUIelements.ContextMenuStripItem4.Text = "Disable miner"
            $LegacyGUIelements.ContextMenuStripItem4.Visible = $true
            $LegacyGUIelements.ContextMenuStripItem5.Enabled = $true
            $LegacyGUIelements.ContextMenuStripItem5.Text = "Enable miner"
            $LegacyGUIelements.ContextMenuStripItem5.Visible = $true
            $LegacyGUIelements.ContextMenuStripItem6.Enabled = $Session.WatchdogTimers
            $LegacyGUIelements.ContextMenuStripItem6.Text = "Remove watchdog timer"
            $LegacyGUIelements.ContextMenuStripItem6.Visible = $true

            If ($LegacyGUIelements.RadioButtonMinersOptimal.checked) { 
                $Bias = If ($Session.CalculatePowerCost -and -not $Config.IgnorePowerCost) { "Profit_Bias" } Else { "Earnings_Bias" }
                $DataSource = $Session.MinersOptimal.PsObject.Copy().ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, { $_.BaseName_Version_Device -replace ".+-" }, @{ Expression = $Bias; Descending = $true }
                Remove-Variable Bias
                $Session.MinersOptimal
            }
            ElseIf ($LegacyGUIelements.RadioButtonMinersUnavailable.checked) { 
                $DataSource = $Session.Miners.Where({ $_.Available -ne $true }).PsObject.Copy().ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Sort-Object { $_.BaseName_Version_Device -replace ".+-" }, Info, Algorithm
            }
            Else { 
                $Bias = If ($Session.CalculatePowerCost -and -not $Config.IgnorePowerCost) { "Profit_Bias" } Else { "Earnings_Bias" }
                $DataSource = $Session.Miners.PsObject.Copy().ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, { $_.BaseName_Version_Device -replace ".+-" }, @{ Expression = $Bias; Descending = $true }
                Remove-Variable Bias
            }

            If ($Session.NewMiningStatus -eq "Idle") { 
                $LegacyGUIelements.MinersLabel.Text = "No data - mining is stopped"
                $LegacyGUIelements.MinersDGV.DataSource = $null
            }
            ElseIf ($Session.NewMiningStatus -eq "Paused") { 
                $LegacyGUIelements.MinersLabel.Text = "No data - mining is paused"
                $LegacyGUIelements.MinersDGV.DataSource = $null
            }
            ElseIf ($Session.NewMiningStatus -eq "Running" -and $Session.MiningStatus -eq "Running" -and -not $Session.Miners -and $Global:CoreRunspace.Job.IsCompleted -eq $true) { 
                $LegacyGUIelements.MinersLabel.Text = "No data - mining is suspended"
                $LegacyGUIelements.MinersDGV.DataSource = $null
            }
            ElseIf ($Session.Miners) { 
                If (-not $LegacyGUIelements.MinersDGV.SelectedRows) { 
                    $LegacyGUIelements.MinersDGV.BeginInit()

                    $LegacyGUIelements.MinersDGV.DataSource = $DataSource | Select-Object @(
                        @{ Name = "Info"; Expression = { $_.Info } }
                        @{ Name = "SubStatus"; Expression = { $_.SubStatus } },
                        @{ Name = "Miner"; Expression = { $_.Name } },
                        @{ Name = "Device(s)"; Expression = { $_.BaseName_Version_Device -replace ".+-" } },
                        @{ Name = "Status"; Expression = { $_.Status } },
                        @{ Name = "Earnings (biased) $($Config.FIATcurrency)/day"; Expression = { If ([Double]::IsNaN($_.Earnings_Bias)) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Earnings * $Session.Rates.BTC.($Config.FIATcurrency)) } } },
                        @{ Name = "Power cost $($Config.FIATcurrency)/day"; Expression = { If ( [Double]::IsNaN($_.PowerCost)) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Powercost * $Session.Rates.BTC.($Config.FIATcurrency)) } } },
                        @{ Name = "Profit (biased) $($Config.FIATcurrency)/day"; Expression = { If ([Double]::IsNaN($_.Profit_Bias) -or -not $Session.CalculatePowerCost) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Profit * $Session.Rates.BTC.($Config.FIATcurrency)) } } },
                        @{ Name = "Power consumption"; Expression = { If ($_.MeasurePowerConsumption) { If ($_.Status -eq "Running") { "Measuring..." } Else { "Unmeasured" } } Else { If ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } Else { "$($_.PowerConsumption.ToString("N2")) W" } } } }
                        @{ Name = "Algorithm (variant)"; Expression = { $_.Workers.Pool.AlgorithmVariant -join " & " } },
                        @{ Name = "Pool"; Expression = { $_.Workers.Pool.Name -join " & " } },
                        @{ Name = "Hashrate"; Expression = { If ($_.Benchmark) { If ($_.Status -eq "Running") { "Benchmarking..." } Else { "Benchmark pending" } } Else { $_.Workers.ForEach({ $_.Hashrate | ConvertTo-Hash }) -join " & " } } }
                        If ($LegacyGUIelements.RadioButtonMinersUnavailable.checked -or $LegacyGUIelements.RadioButtonMiners.checked) { @{ Name = "Reason(s)"; Expression = { $_.Reasons -join ", " } } }
                    ) | Out-DataTable
                    $LegacyGUIelements.MinersDGV.ClearSelection()
                    $LegacyGUIelements.MinersLabel.Text = "Miner data updated $($Session.MinersUpdatedTimestamp.ToLocalTime().ToString("G")) ($($LegacyGUIelements.MinersDGV.Rows.count) miner$(If ($LegacyGUIelements.MinersDGV.Rows.count -ne 1) { "s" }))"

                    $LegacyGUIelements.MinersDGV.Columns[0].Visible = $false
                    $LegacyGUIelements.MinersDGV.Columns[1].Visible = $false
                    If (-not $LegacyGUIelements.MinersDGV.ColumnWidthChanged -and $LegacyGUIelements.MinersDGV.Columns) { 
                        $LegacyGUIelements.MinersDGV.Columns[2].FillWeight = 160
                        $LegacyGUIelements.MinersDGV.Columns[3].FillWeight = 35 + ($DataSource.ForEach({ $_.DeviceNames.Count }) | Measure-Object -Maximum).Maximum * 15
                        $LegacyGUIelements.MinersDGV.Columns[4].FillWeight = 40; $LegacyGUIelements.MinersDGV.Columns[4].Visible = -not $LegacyGUIelements.RadioButtonMinersUnavailable.checked
                        $LegacyGUIelements.MinersDGV.Columns[5].FillWeight = 40; $LegacyGUIelements.MinersDGV.Columns[5].DefaultCellStyle.Alignment = $LegacyGUIelements.MinersDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.MinersDGV.Columns[6].FillWeight = 40; $LegacyGUIelements.MinersDGV.Columns[6].DefaultCellStyle.Alignment = $LegacyGUIelements.MinersDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.MinersDGV.Columns[6].Visible = $Session.CalculatePowerCost
                        $LegacyGUIelements.MinersDGV.Columns[7].FillWeight = 40; $LegacyGUIelements.MinersDGV.Columns[7].DefaultCellStyle.Alignment = $LegacyGUIelements.MinersDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.MinersDGV.Columns[7].Visible = $Session.CalculatePowerCost
                        $LegacyGUIelements.MinersDGV.Columns[8].FillWeight = 40; $LegacyGUIelements.MinersDGV.Columns[8].DefaultCellStyle.Alignment = $LegacyGUIelements.MinersDGV.Columns[8].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.MinersDGV.Columns[8].Visible = $Session.CalculatePowerCost
                        $LegacyGUIelements.MinersDGV.Columns[9].FillWeight = If ($LegacyGUIelements.MinersDGV.DataSource.Pool -like "* & ") { 90 } Else { 60 }
                        $LegacyGUIelements.MinersDGV.Columns[10].FillWeight = If ($LegacyGUIelements.MinersDGV.DataSource.Pool -like "* & ") { 85 } Else { 60 }
                        $LegacyGUIelements.MinersDGV.Columns[11].FillWeight = If ($LegacyGUIelements.MinersDGV.DataSource.Pool -like "* & ") { 80 } Else { 50 }; $LegacyGUIelements.MinersDGV.Columns[11].DefaultCellStyle.Alignment = $LegacyGUIelements.MinersDGV.Columns[11].HeaderCell.Style.Alignment = "MiddleRight"

                        $LegacyGUIelements.MinersDGV | Add-Member ColumnWidthChanged $true -Force
                    }
                    $LegacyGUIelements.MinersDGV.EndInit()
                    Set-TableColor -DataGridView $LegacyGUIelements.MinersDGV
                }
            }
            Else { 
                $LegacyGUIelements.MinersLabel.Text = "Waiting for miner data..."
                $LegacyGUIelements.MinersDGV.DataSource = $null
            }
            Break
        }
        "Pools" { 
            $LegacyGUIelements.PoolsDGV.ClearSelection()

            $LegacyGUIelements.ContextMenuStripItem1.Visible = $false
            $LegacyGUIelements.ContextMenuStripItem2.Visible = $false
            $LegacyGUIelements.ContextMenuStripItem3.Enabled = $true
            $LegacyGUIelements.ContextMenuStripItem3.Text = "Reset pool stat data"
            $LegacyGUIelements.ContextMenuStripItem3.Visible = $true
            $LegacyGUIelements.ContextMenuStripItem4.Enabled = $Session.WatchdogTimers
            $LegacyGUIelements.ContextMenuStripItem4.Text = "Remove watchdog timer"
            $LegacyGUIelements.ContextMenuStripItem5.Visible = $false
            $LegacyGUIelements.ContextMenuStripItem6.Visible = $false

            If ($LegacyGUIelements.RadioButtonPoolsBest.checked) { $DataSource = $Session.PoolsBest }
            ElseIf ($LegacyGUIelements.RadioButtonPoolsUnavailable.checked) { $DataSource = $Session.Pools.Where({ -not $_.Available }) }
            Else { $DataSource = $Session.Pools }

            If ($Session.NewMiningStatus -eq "Idle") { 
                $LegacyGUIelements.PoolsLabel.Text = "No data - mining is stopped"
                $LegacyGUIelements.PoolsDGV.DataSource = $null
            }
            ElseIf ($Session.NewMiningStatus -eq "Paused") { 
                $LegacyGUIelements.PoolsLabel.Text = "No data - mining is paused"
                $LegacyGUIelements.PoolsDGV.DataSource = $null
            }
            ElseIf ($Session.NewMiningStatus -eq "Running" -and $Session.MiningStatus -eq "Running" -and -not $Session.Pools -and $Global:CoreRunspace.Job.IsCompleted -eq $true) { 
                $LegacyGUIelements.PoolsLabel.Text = "No data - mining is suspended"
                $LegacyGUIelements.PoolsDGV.DataSource = $null
            }
            ElseIf ($Session.Pools) { 
                If (-not $LegacyGUIelements.PoolsDGV.SelectedRows) { 
                    $LegacyGUIelements.PoolsDGV.BeginInit()
                    If ($Config.UsemBTC) { 
                        $Factor = 1000
                        $Unit = "mBTC"
                    }
                    Else { 
                        $Factor = 1
                        $Unit = "BTC"
                    }
                    $LegacyGUIelements.PoolsDGV.DataSource = $DataSource | Sort-Object -Property AlgorithmVariant, Currency, Name | Select-Object @(
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
                        If ($LegacyGUIelements.RadioButtonPoolsUnavailable.checked -or $LegacyGUIelements.RadioButtonPools.checked) { @{ Name = "Reason(s)"; Expression = { $_.Reasons -join ", " } } }
                    ) | Out-DataTable
                    $LegacyGUIelements.PoolsDGV.Sort($LegacyGUIelements.PoolsDGV.Columns[0], [System.ComponentModel.ListSortDirection]::Ascending)
                    $LegacyGUIelements.PoolsDGV.ClearSelection()
                    $LegacyGUIelements.PoolsLabel.Text = "Pool data updated $($Session.PoolsUpdatedTimestamp.ToLocalTime().ToString("G")) ($($LegacyGUIelements.PoolsDGV.Rows.Count) pool$(If ($LegacyGUIelements.PoolsDGV.Rows.count -ne 1) { "s" }))"

                    If (-not $LegacyGUIelements.PoolsDGV.ColumnWidthChanged -and $LegacyGUIelements.PoolsDGV.Columns) { 
                        $LegacyGUIelements.PoolsDGV.Columns[0].FillWeight = 80
                        $LegacyGUIelements.PoolsDGV.Columns[1].FillWeight = 40
                        $LegacyGUIelements.PoolsDGV.Columns[2].FillWeight = 70
                        $LegacyGUIelements.PoolsDGV.Columns[3].FillWeight = 55; $LegacyGUIelements.PoolsDGV.Columns[3].DefaultCellStyle.Alignment = $LegacyGUIelements.PoolsDGV.Columns[3].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.PoolsDGV.Columns[4].FillWeight = 45; $LegacyGUIelements.PoolsDGV.Columns[4].DefaultCellStyle.Alignment = $LegacyGUIelements.PoolsDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.PoolsDGV.Columns[5].FillWeight = 80
                        $LegacyGUIelements.PoolsDGV.Columns[6].FillWeight = 140
                        $LegacyGUIelements.PoolsDGV.Columns[7].FillWeight = 40; $LegacyGUIelements.PoolsDGV.Columns[7].DefaultCellStyle.Alignment = $LegacyGUIelements.PoolsDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.PoolsDGV.Columns[8].FillWeight = 40; $LegacyGUIelements.PoolsDGV.Columns[8].DefaultCellStyle.Alignment = $LegacyGUIelements.PoolsDGV.Columns[8].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.PoolsDGV.Columns[9].FillWeight = 50; $LegacyGUIelements.PoolsDGV.Columns[9].DefaultCellStyle.Alignment = $LegacyGUIelements.PoolsDGV.Columns[9].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.PoolsDGV.Columns[10].FillWeight = 40; $LegacyGUIelements.PoolsDGV.Columns[10].DefaultCellStyle.Alignment = $LegacyGUIelements.PoolsDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"

                        $LegacyGUIelements.PoolsDGV | Add-Member ColumnWidthChanged $true
                    }
                    $LegacyGUIelements.PoolsDGV.EndInit()
                }
            }
            Else { 
                $LegacyGUIelements.PoolsLabel.Text = "Waiting for pool data..."
                $LegacyGUIelements.PoolsDGV.DataSource = $null
            }
            Break
        }
        # "Rig monitor" { 
        #     $LegacyGUIelements.WorkersDGV.ClearSelection()
        # 
        #     $LegacyGUIelements.WorkersDGV.Visible = $Config.ShowWorkerStatus
        #     $LegacyGUIelements.EditMonitoringLink.Visible = $Session.APIRunspace.APIport
        #
        #     If ($Config.ShowWorkerStatus) { 
        #         If (-not $LegacyGUIelements.WorkersDGV.SelectedRows) { 
        #
        #             Read-MonitoringData | Out-Null
        #
        #             If ($Session.Workers) { $LegacyGUIelements.WorkersLabel.Text = "Worker status updated $($Session.WorkersLastUpdated.ToString())" }
        #             ElseIf ($Session.MiningStatus -eq "Idle") { $LegacyGUIelements.WorkersLabel.Text = "No data - mining is stopped" }
        #             ElseIf ($Session.MiningStatus -eq "Paused" -and -not $DataSource) { $LegacyGUIelements.WorkersLabel.Text = "No data - mining is paused" }
        #             ElseIf ($Session.NewMiningStatus -eq "Running" -and $Session.MiningStatus -eq "Running" -and $Global:CoreRunspace.Job.IsCompleted -eq $true) {  $LegacyGUIelements.MinersLabel.Text = "No data - mining is suspended" }
        #             Else  { $LegacyGUIelements.WorkersLabel.Text = "Waiting for monitoring data..." }
        #
        #             $LegacyGUIelements.WorkersDGV.BeginInit()
        #             $LegacyGUIelements.WorkersDGV.ClearSelection()
        #             $LegacyGUIelements.WorkersDGV.DataSource = $Session.Workers | Select-Object @(
        #                 @{ Name = "Worker"; Expression = { $_.worker } },
        #                 @{ Name = "Status"; Expression = { $_.status } },
        #                 @{ Name = "Last seen"; Expression = { (Get-TimeSince $_.date) } },
        #                 @{ Name = "Version"; Expression = { $_.version } },
        #                 @{ Name = "Currency"; Expression = { $_.data.Currency | Select-Object -Unique } },
        #                 @{ Name = "Estimated earnings/day"; Expression = { If ($null -ne $_.Data) { "{0:n$($Config.DecimalsMax)}" -f (($_.Data.EarningsWhere({ -not [Double]::IsNaN($_) }) | Measure-Object -Sum).Sum * $Session.Rates.BTC.($_.data.Currency | Select-Object -Unique)) } } },
        #                 @{ Name = "Estimated profit/day"; Expression = { If ($null -ne $_.Data) { " {0:n$($Config.DecimalsMax)}" -f (($_.Data.Profit.Where({ -not [Double]::IsNaN($_) }) | Measure-Object -Sum).Sum * $Session.Rates.BTC.($_.data.Currency | Select-Object -Unique)) } } },
        #                 @{ Name = "Miner"; Expression = { $_.data.Name -join $nl } },
        #                 @{ Name = "Pool"; Expression = { $_.data.ForEach({ $_.Pool -split "," -join " & " }) -join $nl } },
        #                 @{ Name = "Algorithm"; Expression = { $_.data.ForEach({ $_.Algorithm -split "," -join " & " }) -join $nl } },
        #                 @{ Name = "Live hashrate"; Expression = { $_.data.ForEach({ $_.CurrentSpeed.ForEach({ If ([Double]::IsNaN($_)) { "n/a" } Else { $_ | ConvertTo-Hash } }) -join " & " }) -join $nl } },
        #                 @{ Name = "Benchmark hashrate(s)"; Expression = { $_.data.ForEach({ $_.Hashrate.ForEach({ If ([Double]::IsNaN($_)) { "n/a" } Else { $_ | ConvertTo-Hash } }) -join " & " }) -join $nl } }
        #             ) | Out-DataTable
        #             $LegacyGUIelements.WorkersDGV.Sort($LegacyGUIelements.WorkersDGV.Columns[0], [System.ComponentModel.ListSortDirection]::Ascending)
        #             $LegacyGUIelements.WorkersDGV.ClearSelection()
        #
        #             If (-not $LegacyGUIelements.WorkersDGV.ColumnWidthChanged -and $LegacyGUIelements.WorkersDGV.Columns) { 
        #                 $LegacyGUIelements.WorkersDGV.Columns[0].FillWeight = 70
        #                 $LegacyGUIelements.WorkersDGV.Columns[1].FillWeight = 60
        #                 $LegacyGUIelements.WorkersDGV.Columns[2].FillWeight = 80
        #                 $LegacyGUIelements.WorkersDGV.Columns[3].FillWeight = 70
        #                 $LegacyGUIelements.WorkersDGV.Columns[4].FillWeight = 40
        #                 $LegacyGUIelements.WorkersDGV.Columns[5].FillWeight = 65; $LegacyGUIelements.WorkersDGV.Columns[5].DefaultCellStyle.Alignment = $LegacyGUIelements.WorkersDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"
        #                 $LegacyGUIelements.WorkersDGV.Columns[6].FillWeight = 65; $LegacyGUIelements.WorkersDGV.Columns[6].DefaultCellStyle.Alignment = $LegacyGUIelements.WorkersDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"
        #                 $LegacyGUIelements.WorkersDGV.Columns[7].FillWeight = 150
        #                 $LegacyGUIelements.WorkersDGV.Columns[8].FillWeight = 95
        #                 $LegacyGUIelements.WorkersDGV.Columns[9].FillWeight = 75
        #                 $LegacyGUIelements.WorkersDGV.Columns[10].FillWeight = 65; $LegacyGUIelements.WorkersDGV.Columns[10].DefaultCellStyle.Alignment = $LegacyGUIelements.WorkersDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"
        #                 $LegacyGUIelements.WorkersDGV.Columns[11].FillWeight = 65; $LegacyGUIelements.WorkersDGV.Columns[11].DefaultCellStyle.Alignment = $LegacyGUIelements.WorkersDGV.Columns[11].HeaderCell.Style.Alignment = "MiddleRight"
        #
        #                 $LegacyGUIelements.WorkersDGV | Add-Member ColumnWidthChanged $true
        #             }
        #             Set-WorkerColor
        #             $LegacyGUIelements.WorkersDGV.EndInit()
        #         }
        #     }
        #     Else { 
        #         $LegacyGUIelements.WorkersLabel.Text = "Worker status reporting is disabled$(If (-not $Session.APIRunspace) { " (Configuration item 'ShowWorkerStatus' -eq `$false)" })."
        #         $LegacyGUIelements.WorkersDGV.DataSource = $null
        #     }
        #     Break
        # }
        "Switching Log" { 
            CheckBoxSwitching_Click
            Break
        }
        "Watchdog timers" { 
            $LegacyGUIelements.WatchdogTimersRemoveButton.Visible = $Config.Watchdog
            $LegacyGUIelements.WatchdogTimersDGV.Visible = $Config.Watchdog

            If ($Config.Watchdog) { 
                If ($Session.NewMiningStatus -eq "Idle") { 
                    $LegacyGUIelements.WatchdogTimersLabel.Text = "No data - mining is stopped"
                    $LegacyGUIelements.WatchdogTimersDGV.DataSource = $null
                }
                ElseIf ($Session.NewMiningStatus -eq "Paused") { 
                    $LegacyGUIelements.WatchdogTimersLabel.Text = "No data - mining is paused"
                    $LegacyGUIelements.WatchdogTimersDGV.DataSource = $null
                }
                ElseIf ($Session.NewMiningStatus -eq "Running" -and $Session.MiningStatus -eq "Running" -and -not $Session.Pools -and $Global:CoreRunspace.Job.IsCompleted -eq $true) { 
                    $LegacyGUIelements.WatchdogTimersLabel.Text = "No data - mining is suspended"
                    $LegacyGUIelements.WatchdogTimersDGV.DataSource = $null
                }
                ElseIf ($Session.WatchdogTimers) { 
                    $LegacyGUIelements.WatchdogTimersLabel.Text = "Watchdog timers updated $(($Session.WatchdogTimers.Kicked | Sort-Object -Bottom 1).ToLocalTime().ToString("G"))"
                    $LegacyGUIelements.WatchdogTimersDGV.BeginInit()
                    $LegacyGUIelements.WatchdogTimersDGV.DataSource = $Session.WatchdogTimers | Sort-Object -Property MinerName, Kicked | Select-Object @(
                        @{ Name = "Name"; Expression = { $_.MinerName } },
                        @{ Name = "Algorithm"; Expression = { $_.Algorithm } },
                        @{ Name = "Algorithm (variant)"; Expression = { $_.AlgorithmVariant } },
                        @{ Name = "Pool"; Expression = { $_.PoolName } },
                        @{ Name = "Region"; Expression = { $_.PoolRegion } },
                        @{ Name = "Device(s)"; Expression = { $_.MinerBaseName_Version_Device -replace ".+-" } },
                        @{ Name = "Last updated"; Expression = { (Get-TimeSince $_.Kicked.ToLocalTime()) } }
                    ) | Out-DataTable
                    $LegacyGUIelements.WatchdogTimersDGV.Sort($LegacyGUIelements.WatchdogTimersDGV.Columns[0], [System.ComponentModel.ListSortDirection]::Ascending)
                    $LegacyGUIelements.WatchdogTimersDGV.ClearSelection()

                    If (-not $LegacyGUIelements.WatchdogTimersDGV.ColumnWidthChanged -and $LegacyGUIelements.WatchdogTimersDGV.Columns) { 
                        $LegacyGUIelements.WatchdogTimersDGV.Columns[0].FillWeight = 200
                        $LegacyGUIelements.WatchdogTimersDGV.Columns[1].FillWeight = 60
                        $LegacyGUIelements.WatchdogTimersDGV.Columns[2].FillWeight = 60
                        $LegacyGUIelements.WatchdogTimersDGV.Columns[3].FillWeight = 60
                        $LegacyGUIelements.WatchdogTimersDGV.Columns[4].FillWeight = 44
                        $LegacyGUIelements.WatchdogTimersDGV.Columns[5].FillWeight = 35 + ($Session.WatchdogTimers.ForEach({ $_.DeviceNames.Count }) | Measure-Object -Maximum).Maximum * 20
                        $LegacyGUIelements.WatchdogTimersDGV.Columns[6].FillWeight = 55

                        $LegacyGUIelements.WatchdogTimersDGV | Add-Member ColumnWidthChanged $true
                    }
                    $LegacyGUIelements.WatchdogTimersDGV.EndInit()
                }
                Else { 
                    $LegacyGUIelements.WatchdogTimersLabel.Text = "Waiting for watchdog timer data..."
                    $LegacyGUIelements.WatchdogTimersDGV.DataSource = $null
                }
            }
            Else { $LegacyGUIelements.WatchdogTimersLabel.Text = "Watchdog is disabled (Configuration item 'Watchdog' -eq `$false)" }

            $LegacyGUIelements.WatchdogTimersRemoveButton.Enabled = [Boolean]$LegacyGUIelements.WatchdogTimersDGV.Rows
        }
    }
}

Function Update-GUIstatus { 

    $LegacyGUIform.Text = $host.UI.RawUI.WindowTitle

    Switch ($Session.NewMiningStatus) { 
        "Idle" { 
            $LegacyGUIelements.MiningStatusLabel.ForeColor = [System.Drawing.Color]::Red
            $LegacyGUIelements.MiningStatusLabel.Text = "$($Session.Branding.ProductLabel) is stopped"
            $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Black
            Break
        }
        "Paused" { 
            $LegacyGUIelements.MiningStatusLabel.ForeColor = [System.Drawing.Color]::Blue
            $LegacyGUIelements.MiningStatusLabel.Text = "$($Session.Branding.ProductLabel) is paused"
            $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Black
            Break
        }
        "Running" { 
            If ($Session.MiningStatus -eq "Running" -and -$Global:CoreRunspace.Job.IsCompleted -eq $true) { 
                $LegacyGUIelements.MiningStatusLabel.ForeColor = [System.Drawing.Color]::Blue
                $LegacyGUIelements.MiningStatusLabel.Text = "$($Session.Branding.ProductLabel) is suspended"
                $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Black
            }
            Else { 
                $LegacyGUIelements.MiningStatusLabel.ForeColor = [System.Drawing.Color]::Green
                $LegacyGUIelements.MiningStatusLabel.Text = "$($Session.Branding.ProductLabel) is running"

                If ($Session.MinersRunning -and $Session.MiningProfit -gt 0) { $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Green }
                ElseIf ($Session.MinersRunning -and $Session.MiningProfit -lt 0) { $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Red }
                Else { $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Black }
            }
        }
    }
    $LegacyGUIelements.MiningSummaryLabel.Text = (($Session.Summary.Replace("$($LegacyGUIelements.MiningStatusLabel.Text). ", "") -replace "&ensp;", " " -replace "   ", "  " -replace "&", "&&") -split "<br>") -join "`r`n"
    Update-TabControl
}

$LegacyGUIelements.Colors = @{ }
$LegacyGUIelements.Colors["benchmarking"]                            = [System.Drawing.Color]::FromArgb(241, 255, 229)
$LegacyGUIelements.Colors["disabled"]                                = [System.Drawing.Color]::FromArgb(255, 243, 231)
$LegacyGUIelements.Colors["failed"]                                  = [System.Drawing.Color]::FromArgb(255, 230, 230)
$LegacyGUIelements.Colors["idle"] = $LegacyGUIelements.Colors["stopped"]      = [System.Drawing.Color]::FromArgb(230, 248, 252)
$LegacyGUIelements.Colors["launched"]                                = [System.Drawing.Color]::FromArgb(229, 255, 229)
$LegacyGUIelements.Colors["dryrun"] = $LegacyGUIelements.Colors["running"]    = [System.Drawing.Color]::FromArgb(212, 244, 212)
$LegacyGUIelements.Colors["starting"] = $LegacyGUIelements.Colors["stopping"] = [System.Drawing.Color]::FromArgb(245, 255, 245)
$LegacyGUIelements.Colors["unavailable"]                             = [System.Drawing.Color]::FromArgb(254, 245, 220)
$LegacyGUIelements.Colors["warmingup"]                               = [System.Drawing.Color]::FromArgb(231, 255, 230)

$LegacyGUIelements.Tooltip = [System.Windows.Forms.ToolTip]::new()

$LegacyGUIform = [System.Windows.Forms.Form]::new()
# For High DPI, First call SuspendLayout(), after that, Set AutoScaleDimensions, AutoScaleMode
# SuspendLayout() is very important to correctly size and position all controls!
$LegacyGUIform.SuspendLayout()
# $LegacyGUIform.AutoScaleDimensions = [System.Drawing.SizeF]::new(120, 120)
$LegacyGUIform.AutoScaleDimensions = [System.Drawing.SizeF]::new(96, 96)
$LegacyGUIform.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::DPI
$LegacyGUIform.MaximizeBox = $true
$LegacyGUIform.MinimumSize = [System.Drawing.Size]::new(800, 600) # best to keep under 800x600
$LegacyGUIform.Text = $Session.Branding.ProductLabel
$LegacyGUIform.TopMost = $false

# Form Controls
$LegacyGUIelements.Controls = @()

$LegacyGUIelements.StatusPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIelements.StatusPage.Text = "System status"
$LegacyGUIelements.StatusPage.ToolTipText = "Show active miners and system log"
$LegacyGUIelements.EarningsPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIelements.EarningsPage.Text = "Earnings and balances"
$LegacyGUIelements.EarningsPage.ToolTipText = "Information about the calculated earnings / profit"
$LegacyGUIelements.MinersPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIelements.MinersPage.Text = "Miners"
$LegacyGUIelements.MinersPage.ToolTipText = "Miner data updated in the last cycle"
$LegacyGUIelements.PoolsPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIelements.PoolsPage.Text = "Pools"
$LegacyGUIelements.PoolsPage.ToolTipText = "Pool data updated in the last cycle"
# $LegacyGUIelements.RigMonitorPage = [System.Windows.Forms.TabPage]::new()
# $LegacyGUIelements.RigMonitorPage.Text = "Rig monitor"
# $LegacyGUIelements.RigMonitorPage.ToolTipText = "Consolidated overview of all known mining rigs"
$LegacyGUIelements.SwitchingPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIelements.SwitchingPage.Text = "Switching log"
$LegacyGUIelements.SwitchingPage.ToolTipText = "List of the previously launched miners"
$LegacyGUIelements.WatchdogTimersPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIelements.WatchdogTimersPage.Text = "Watchdog timers"
$LegacyGUIelements.WatchdogTimersPage.ToolTipText = "List of all watchdog timers"

$LegacyGUIelements.MiningStatusLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIelements.MiningStatusLabel.AutoSize = $false
$LegacyGUIelements.MiningStatusLabel.BackColor = [System.Drawing.Color]::Transparent
$LegacyGUIelements.MiningStatusLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$LegacyGUIelements.MiningStatusLabel.ForeColor = [System.Drawing.Color]::Black
$LegacyGUIelements.MiningStatusLabel.Height = 20
$LegacyGUIelements.MiningStatusLabel.Location = [System.Drawing.Point]::new(11, 10)
$LegacyGUIelements.MiningStatusLabel.Text = "$($Session.Branding.ProductLabel)"
$LegacyGUIelements.MiningStatusLabel.TextAlign = "MiddleLeft"
$LegacyGUIelements.MiningStatusLabel.Visible = $true
$LegacyGUIelements.MiningStatusLabel.Width = 360
$LegacyGUIelements.Controls += $LegacyGUIelements.MiningStatusLabel

$LegacyGUIelements.MiningSummaryLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIelements.MiningSummaryLabel.AutoSize = $false
$LegacyGUIelements.MiningSummaryLabel.BackColor = [System.Drawing.Color]::Transparent
$LegacyGUIelements.MiningSummaryLabel.BorderStyle = 'None'
$LegacyGUIelements.MiningSummaryLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Black
$LegacyGUIelements.MiningSummaryLabel.Height = 60
$LegacyGUIelements.MiningSummaryLabel.Location = [System.Drawing.Point]::new(12, 36)
$LegacyGUIelements.MiningSummaryLabel.Tag = ""
$LegacyGUIelements.MiningSummaryLabel.TextAlign = "MiddleLeft"
$LegacyGUIelements.MiningSummaryLabel.Visible = $true
$LegacyGUIelements.Controls += $LegacyGUIelements.MiningSummaryLabel
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.MiningSummaryLabel, "Color legend:`rBlack: Mining profitability is unknown`rGreen: Mining is profitable`rRed: Mining is NOT profitable")

$LegacyGUIelements.ButtonPause = [System.Windows.Forms.Button]::new()
$LegacyGUIelements.ButtonPause.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.ButtonPause.Height = 24
$LegacyGUIelements.ButtonPause.Text = "Pause mining"
$LegacyGUIelements.ButtonPause.Visible = $true
$LegacyGUIelements.ButtonPause.Width = 100
$LegacyGUIelements.ButtonPause.Add_Click(
    { 
        If ($Session.NewMiningStatus -ne "Paused" -and -not $Session.SuspendCycle) { 
            $Session.NewMiningStatus = "Paused"
            $Session.SuspendCycle = $false
            $Session.RestartCycle = $true
        }
    }
)
$LegacyGUIelements.Controls += $LegacyGUIelements.ButtonPause
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.ButtonPause, "Pause mining processes.`rBrain jobs and balances tracker remain running.")

$LegacyGUIelements.ButtonStart = [System.Windows.Forms.Button]::new()
$LegacyGUIelements.ButtonStart.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.ButtonStart.Height = 24
$LegacyGUIelements.ButtonStart.Text = "Start mining"
$LegacyGUIelements.ButtonStart.Visible = $true
$LegacyGUIelements.ButtonStart.Width = 100
$LegacyGUIelements.ButtonStart.Add_Click(
    { 
        If ($Session.NewMiningStatus -ne "Running") { 
            $Session.NewMiningStatus = "Running"
            $Session.SuspendCycle = $false
            $Session.RestartCycle = $true
        }
    }
)
$LegacyGUIelements.Controls += $LegacyGUIelements.ButtonStart
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.ButtonStart, "Start the mining process.`rBrain jobs and balances tracker will also start.")

$LegacyGUIelements.ButtonStop = [System.Windows.Forms.Button]::new()
$LegacyGUIelements.ButtonStop.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.ButtonStop.Height = 24
$LegacyGUIelements.ButtonStop.Text = "Stop mining"
$LegacyGUIelements.ButtonStop.Visible = $true
$LegacyGUIelements.ButtonStop.Width = 100
$LegacyGUIelements.ButtonStop.Add_Click(
    { 
        If ($Session.NewMiningStatus -ne "Idle") { 
            $Session.NewMiningStatus = "Idle"
            $Session.SuspendCycle = $false
            $Session.RestartCycle = $true
        }
    }
)
$LegacyGUIelements.Controls += $LegacyGUIelements.ButtonStop
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.ButtonStop, "Stop mining processes.`rBrain jobs and balances tracker will also stop.")

$LegacyGUIelements.EditConfigLink = [System.Windows.Forms.LinkLabel]::new()
$LegacyGUIelements.EditConfigLink.ActiveLinkColor = [System.Drawing.Color]::Blue
$LegacyGUIelements.EditConfigLink.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.EditConfigLink.LinkColor = [System.Drawing.Color]::Blue
$LegacyGUIelements.EditConfigLink.Location = [System.Drawing.Point]::new(18, ($LegacyGUIform.Bottom - 26))
$LegacyGUIelements.EditConfigLink.TextAlign = "MiddleLeft"
$LegacyGUIelements.EditConfigLink.Size = [System.Drawing.Size]::new(380, 26)
$LegacyGUIelements.EditConfigLink.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        If ($LegacyGUIelements.EditConfigLink.Tag -eq "WebGUI") { Start-Process "http://localhost:$($Session.APIRunspace.APIport)/configedit.html" } Else { Edit-File $Session.ConfigFile }
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)
$LegacyGUIelements.Controls += $LegacyGUIelements.EditConfigLink
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.EditConfigLink, "Click to the edit the configuration file in notepad")

$LegacyGUIelements.CopyrightLabel = [System.Windows.Forms.LinkLabel]::new()
$LegacyGUIelements.CopyrightLabel.ActiveLinkColor = [System.Drawing.Color]::Blue
$LegacyGUIelements.CopyrightLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.CopyrightLabel.Location = [System.Drawing.Point]::new(8, ($LegacyGUIform.Bottom - 26))
$LegacyGUIelements.CopyrightLabel.LinkColor = [System.Drawing.Color]::Blue
$LegacyGUIelements.CopyrightLabel.Size = [System.Drawing.Size]::new(380, 26)
$LegacyGUIelements.CopyrightLabel.Text = "Copyright (c) 2018-$([DateTime]::Now.Year) UselessGuru"
$LegacyGUIelements.CopyrightLabel.TextAlign = "MiddleRight"
$LegacyGUIelements.CopyrightLabel.Add_Click({ Start-Process "$($Session.Branding.BrandWebSite)" })
$LegacyGUIelements.Controls += $LegacyGUIelements.CopyrightLabel
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.CopyrightLabel, "Click to go to the $($Session.Branding.ProductLabel) page on Github")

# Miner context menu items
$LegacyGUIelements.ContextMenuStrip = [System.Windows.Forms.ContextMenuStrip]::new()
$LegacyGUIelements.ContextMenuStrip.Enabled = $false

$LegacyGUIelements.ContextMenuStripItem1 = [System.Windows.Forms.ToolStripMenuItem]::new()
[Void]$LegacyGUIelements.ContextMenuStrip.Items.Add($LegacyGUIelements.ContextMenuStripItem1)

$LegacyGUIelements.ContextMenuStripItem2 = [System.Windows.Forms.ToolStripMenuItem]::new()
[Void]$LegacyGUIelements.ContextMenuStrip.Items.Add($LegacyGUIelements.ContextMenuStripItem2)

$LegacyGUIelements.ContextMenuStripItem3 = [System.Windows.Forms.ToolStripMenuItem]::new()
[Void]$LegacyGUIelements.ContextMenuStrip.Items.Add($LegacyGUIelements.ContextMenuStripItem3)

$LegacyGUIelements.ContextMenuStripItem4 = [System.Windows.Forms.ToolStripMenuItem]::new()
[Void]$LegacyGUIelements.ContextMenuStrip.Items.Add($LegacyGUIelements.ContextMenuStripItem4)

$LegacyGUIelements.ContextMenuStripItem5 = [System.Windows.Forms.ToolStripMenuItem]::new()
[Void]$LegacyGUIelements.ContextMenuStrip.Items.Add($LegacyGUIelements.ContextMenuStripItem5)

$LegacyGUIelements.ContextMenuStripItem6 = [System.Windows.Forms.ToolStripMenuItem]::new()
[Void]$LegacyGUIelements.ContextMenuStrip.Items.Add($LegacyGUIelements.ContextMenuStripItem6)

$LegacyGUIelements.ContextMenuStrip.Add_ItemClicked(
    { 
        $Data = @()

        $SourceControl = $this.SourceControl
        If ($SourceControl.Name -match "LaunchedMinersDGV|MinersDGV") { 

            Switch ($_.ClickedItem.Text) { 
                "Re-benchmark miner" { 
                    $LegacyGUIelements.ContextMenuStrip.Visible = $false
                    $Session.Miners.Where({ $_.Info -in $SourceControl.SelectedRows.ForEach({ $_.Cells[0].Value }) }).ForEach(
                        { 
                            $Data += $_.Name
                            Set-MinerReBenchmark $_
                        }
                    )
                    $Message = "Re-benchmark triggered for $($Data.Count) miner$(If ($Data.Count -ne 1) { "s" })."
                    Write-Message -Level Verbose "GUI: $Message" -Console $false
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                    If ($Session.DryRun -and $Session.NewMiningStatus -eq "Running") { $Session.EndCycleTime = [DateTime]::Now.ToUniversalTime() }
                    Update-TabControl
                    Break
                }
                "Re-measure power consumption" { 
                    $LegacyGUIelements.ContextMenuStrip.Visible = $false
                    $Session.Miners.Where({ $_.Info -in $SourceControl.SelectedRows.ForEach{ ($_.Cells[0].Value) } }).ForEach(
                        { 
                            $Data += $_.Name
                            Set-MinerMeasurePowerConsumption $_  
                        }
                    )
                    $Message = "Re-measure power consumption triggered for $($Data.Count) miner$(If ($Data.Count -ne 1) { "s" })."
                    Write-Message -Level Verbose "GUI: $Message" -Console $false
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                    If ($Session.DryRun -and $Session.NewMiningStatus -eq "Running") { $Session.EndCycleTime = [DateTime]::Now.ToUniversalTime() }
                    Update-TabControl
                    Break
                }
                "Mark miner as failed" { 
                    $LegacyGUIelements.ContextMenuStrip.Visible = $false
                    $Session.Miners.Where({ $_.Info -in $SourceControl.SelectedRows.ForEach{ ($_.Cells[0].Value) } }).ForEach(
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
                    $LegacyGUIelements.ContextMenuStrip.Visible = $false
                    $Session.Miners.Where({ $_.Info -in $SourceControl.SelectedRows.ForEach{ ($_.Cells[0].Value) } }).Where({ -not $_.Disabled }).ForEach(
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
                    $LegacyGUIelements.ContextMenuStrip.Visible = $false
                    $Session.Miners.Where({ $_.Info -in $SourceControl.SelectedRows.ForEach{ ($_.Cells[0].Value) } }).Where({ $_.Disabled }).ForEach(
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
                            ForEach ($Miner in $Session.Miners.Where({ $_.Name -eq $MinerName -and $Session.WatchdogTimers.Where({ $_.MinerName -eq $MinerName }) })) { 
                                $Data += $Miner.Name
                                $Miner.Reasons.Where({ $_ -like "Miner suspended by watchdog *" }).ForEach({ $Miner.Reasons.Remove($_) | Out-Null })
                                If (-not $Miner.Reasons.Count) { $Miner.Available = $true }
                            }

                            # Remove Watchdog timers
                            $Session.WatchdogTimers = $Session.WatchdogTimers.Where({ $_.MinerName -ne $MinerName })

                            Remove-Variable Miner, MinerName
                        }
                    )
                    $LegacyGUIelements.ContextMenuStrip.Visible = $false
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
            If ($Data.Count -ge 1) { [Void][System.Windows.Forms.MessageBox]::Show([String]($Data -join "`r`n"), "$($Session.Branding.ProductLabel): $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK, 64) }

        }
        ElseIf ($this.SourceControl.Name -match "PoolsDGV") { 
            Switch ($_.ClickedItem.Text) { 
                "Reset pool stat data" { 
                    $this.SourceControl.SelectedRows.ForEach(
                        { 
                            $SelectedPoolName = $_.Cells[5].Value
                            $SelectedPoolAlgorithm = $_.Cells[0].Value
                            $Session.Pools.Where({ $_.Name -eq $SelectedPoolName -and $_.Algorithm -eq $SelectedPoolAlgorithm }).ForEach(
                                { 
                                    $StatName = "$($_.Name)_$($_.Algorithm)$(If ($_.Currency) { "-$($_.Currency)" })"
                                    $Data += $StatName
                                    Remove-Stat -Name "$($StatName)_Profit"
                                    $_.Reasons = [System.Collections.Generic.SortedSet[String]]::new()
                                    $_.Price = $_.Price_Bias = $_.StablePrice = $_.Accuracy = [Double]::Nan
                                    $_.Available = $true
                                    $_.Disabled = $false
                                }
                            )
                        }
                    )
                    $LegacyGUIelements.ContextMenuStrip.Visible = $false
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
                            ForEach ($Pool in ($Session.Pools.Where({ $_.Name -eq $PoolName -and $_.Algorithm -eq $PoolAlgorithm -and $Session.WatchdogTimers.Where({ $_.PoolName -eq $PoolName -and $_.Algorithm -eq $PoolAlgorithm }) }))) {
                                $Data += "$($Pool.Key) ($($Pool.Region))"
                                $Pool.Reasons.Where({ $_ -like "Pool suspended by watchdog *" }).ForEach({ $Pool.Reasons.Remove($_) | Out-Null })
                                If (-not $Pool.Reasons.Count) { $Pool.Available = $true }
                            }

                            # Remove Watchdog timers
                            $Session.WatchdogTimers = $Session.WatchdogTimers.Where({ $_.PoolName -ne $PoolName -or $_.Algorithm -ne $PoolAlgorithm })

                            Remove-Variable Pool, PoolAlgorithm, PoolAlgorithm
                        }
                    )
                    $LegacyGUIelements.ContextMenuStrip.Visible = $false
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
            If ($Data.Count -ge 1) { [Void][System.Windows.Forms.MessageBox]::Show([String]($Data -join "`r`n"), "$($Session.Branding.ProductLabel): $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK, 64) }

        }
        Remove-Variable SourceControl
    }
)

# CheckBox Column for DataGridView
$LegacyGUIelements.CheckBoxColumn = [System.Windows.Forms.DataGridViewCheckBoxColumn]::new()
$LegacyGUIelements.CheckBoxColumn.HeaderText = ""
$LegacyGUIelements.CheckBoxColumn.Name = "CheckBoxColumn"
$LegacyGUIelements.CheckBoxColumn.ReadOnly = $false

# Run Page Controls
$LegacyGUIelements.StatusPageControls = @()

$LegacyGUIelements.ActiveMinersLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIelements.ActiveMinersLabel.AutoSize = $false
$LegacyGUIelements.ActiveMinersLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.ActiveMinersLabel.Height = 20
$LegacyGUIelements.ActiveMinersLabel.Location = [System.Drawing.Point]::new(0, 5)
$LegacyGUIelements.ActiveMinersLabel.Width = 600
$LegacyGUIelements.StatusPageControls += $LegacyGUIelements.ActiveMinersLabel

$LegacyGUIelements.ActiveMinersDGV = [System.Windows.Forms.DataGridView]::new()
$LegacyGUIelements.ActiveMinersDGV.AllowUserToAddRows = $false
$LegacyGUIelements.ActiveMinersDGV.AllowUserToDeleteRows = $false
$LegacyGUIelements.ActiveMinersDGV.AllowUserToOrderColumns = $true
$LegacyGUIelements.ActiveMinersDGV.AllowUserToResizeColumns = $true
$LegacyGUIelements.ActiveMinersDGV.AllowUserToResizeRows = $false
$LegacyGUIelements.ActiveMinersDGV.AutoSizeColumnsMode = "Fill"
$LegacyGUIelements.ActiveMinersDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIelements.ActiveMinersDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIelements.ActiveMinersDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LegacyGUIelements.ActiveMinersDGV.ContextMenuStrip = $LegacyGUIelements.ContextMenuStrip
$LegacyGUIelements.ActiveMinersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LegacyGUIelements.ActiveMinersDGV.EnableHeadersVisualStyles = $false
$LegacyGUIelements.ActiveMinersDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$LegacyGUIelements.ActiveMinersDGV.Height = 3
$LegacyGUIelements.ActiveMinersDGV.Location = [System.Drawing.Point]::new(0, ($LegacyGUIelements.ActiveMinersLabel.Height + 6))
$LegacyGUIelements.ActiveMinersDGV.Name = "LaunchedMinersDGV"
$LegacyGUIelements.ActiveMinersDGV.ReadOnly = $true
$LegacyGUIelements.ActiveMinersDGV.RowHeadersVisible = $false
$LegacyGUIelements.ActiveMinersDGV.ScrollBars = "None"
$LegacyGUIelements.ActiveMinersDGV.SelectionMode = "FullRowSelect"
$LegacyGUIelements.ActiveMinersDGV.Add_DataSourceChanged({ If ($LegacyGUIelements.TabControl.SelectedTab.Text -eq "System status" ) { Resize-Form } }) # To fully show grid
$LegacyGUIelements.ActiveMinersDGV.Add_MouseUp({ If ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right) { $LegacyGUIelements.ContextMenuStrip.Enabled = [Boolean]$this.SelectedRows } })
$LegacyGUIelements.ActiveMinersDGV.Add_Sorted({ Set-TableColor -DataGridView $LegacyGUIelements.ActiveMinersDGV }) # Re-apply colors after sort
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIelements.ActiveMinersDGV -Enabled $true
$LegacyGUIelements.StatusPageControls += $LegacyGUIelements.ActiveMinersDGV

$LegacyGUIelements.SystemLogLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIelements.SystemLogLabel.AutoSize = $false
$LegacyGUIelements.SystemLogLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.SystemLogLabel.Height = 20
$LegacyGUIelements.SystemLogLabel.Text = "System Log"
$LegacyGUIelements.SystemLogLabel.Width = 600
$LegacyGUIelements.StatusPageControls += $LegacyGUIelements.SystemLogLabel

$Session.TextBoxSystemLog = [System.Windows.Forms.TextBox]::new()
$Session.TextBoxSystemLog.AutoSize = $true
$Session.TextBoxSystemLog.BorderStyle = "FixedSingle"
$Session.TextBoxSystemLog.Font = [System.Drawing.Font]::new("Consolas", 9)
$Session.TextBoxSystemLog.HideSelection = $false
$Session.TextBoxSystemLog.MultiLine = $true
$Session.TextBoxSystemLog.ReadOnly = $true
$Session.TextBoxSystemLog.Scrollbars = "Vertical"
$Session.TextBoxSystemLog.Text = ""
$Session.TextBoxSystemLog.WordWrap = $true
$LegacyGUIelements.StatusPageControls += $Session.TextBoxSystemLog
$LegacyGUIelements.Tooltip.SetToolTip($Session.TextBoxSystemLog, "These are the last 200 lines of the system log")

# Earnings Page Controls
$LegacyGUIelements.EarningsPageControls = @()

$LegacyGUIelements.EarningsChart = [System.Windows.Forms.DataVisualization.Charting.Chart]::new()
$LegacyGUIelements.EarningsChart.BackColor = [System.Drawing.Color]::FromArgb(255, 240, 240, 240)
$LegacyGUIelements.EarningsChart.Location = [System.Drawing.Point]::new(0, 0)
$LegacyGUIelements.EarningsPageControls += $LegacyGUIelements.EarningsChart

$LegacyGUIelements.BalancesLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIelements.BalancesLabel.AutoSize = $false
$LegacyGUIelements.BalancesLabel.BringToFront()
$LegacyGUIelements.BalancesLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.BalancesLabel.Height = 20
$LegacyGUIelements.BalancesLabel.Width = 600
$LegacyGUIelements.EarningsPageControls += $LegacyGUIelements.BalancesLabel

$LegacyGUIelements.BalancesDGV = [System.Windows.Forms.DataGridView]::new()
$LegacyGUIelements.BalancesDGV.AllowUserToAddRows = $false
$LegacyGUIelements.BalancesDGV.AllowUserToDeleteRows = $false
$LegacyGUIelements.BalancesDGV.AllowUserToOrderColumns = $true
$LegacyGUIelements.BalancesDGV.AllowUserToResizeColumns = $true
$LegacyGUIelements.BalancesDGV.AllowUserToResizeRows = $false
$LegacyGUIelements.BalancesDGV.AutoSizeColumnsMode = "Fill"
$LegacyGUIelements.BalancesDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIelements.BalancesDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIelements.BalancesDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LegacyGUIelements.BalancesDGV.DefaultCellStyle.SelectionBackColor = $LegacyGUIelements.BalancesDGV.DefaultCellStyle.BackColor
$LegacyGUIelements.BalancesDGV.DefaultCellStyle.SelectionForeColor = $LegacyGUIelements.BalancesDGV.DefaultCellStyle.ForeColor
$LegacyGUIelements.BalancesDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LegacyGUIelements.BalancesDGV.EnableHeadersVisualStyles = $false
$LegacyGUIelements.BalancesDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$LegacyGUIelements.BalancesDGV.Height = 3
$LegacyGUIelements.BalancesDGV.Location = [System.Drawing.Point]::new(0, 0)
$LegacyGUIelements.BalancesDGV.Name = "EarningsDGV"
$LegacyGUIelements.BalancesDGV.ReadOnly = $true
$LegacyGUIelements.BalancesDGV.RowHeadersVisible = $false
$LegacyGUIelements.BalancesDGV.SelectionMode = "FullRowSelect"
$LegacyGUIelements.BalancesDGV.Add_DataSourceChanged({ If ($LegacyGUIelements.TabControl.SelectedTab.Text -eq "Earnings and balances" ) { Resize-Form } }) # To fully show grid
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIelements.BalancesDGV -Enabled $true
$LegacyGUIelements.EarningsPageControls += $LegacyGUIelements.BalancesDGV

# Miner page Controls
$LegacyGUIelements.MinersPageControls = @()

$LegacyGUIelements.RadioButtonMinersOptimal = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIelements.RadioButtonMinersOptimal.AutoSize = $false
$LegacyGUIelements.RadioButtonMinersOptimal.Checked = $true
$LegacyGUIelements.RadioButtonMinersOptimal.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.RadioButtonMinersOptimal.Height = 22
$LegacyGUIelements.RadioButtonMinersOptimal.Location = [System.Drawing.Point]::new(0, 0)
$LegacyGUIelements.RadioButtonMinersOptimal.Text = "Optimal miners"
$LegacyGUIelements.RadioButtonMinersOptimal.Width = 150
$LegacyGUIelements.RadioButtonMinersOptimal.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $LegacyGUIelements.MinersDGV | Add-Member ColumnWidthChanged $false -Force
        $LegacyGUIelements.MinersDGV.ClearSelection()
        Update-TabControl
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.RadioButtonMinersOptimal, "These are all optimal miners per algorithm and device.")

$LegacyGUIelements.RadioButtonMinersUnavailable = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIelements.RadioButtonMinersUnavailable.AutoSize = $false
$LegacyGUIelements.RadioButtonMinersUnavailable.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.RadioButtonMinersUnavailable.Height = $LegacyGUIelements.RadioButtonMinersOptimal.Height
$LegacyGUIelements.RadioButtonMinersUnavailable.Location = [System.Drawing.Point]::new(150, 0)
$LegacyGUIelements.RadioButtonMinersUnavailable.Text = "Unavailable miners"
$LegacyGUIelements.RadioButtonMinersUnavailable.Width = 170
$LegacyGUIelements.RadioButtonMinersUnavailable.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $LegacyGUIelements.MinersDGV | Add-Member ColumnWidthChanged $false -Force
        $LegacyGUIelements.MinersDGV.ClearSelection()
        Update-TabControl
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.RadioButtonMinersUnavailable, "These are all unavailable miners.`rThe column 'Reason(s)' shows the filter criteria(s) that made the miner unavailable.")

$LegacyGUIelements.RadioButtonMiners = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIelements.RadioButtonMiners.AutoSize = $false
$LegacyGUIelements.RadioButtonMiners.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.RadioButtonMiners.Height = $LegacyGUIelements.RadioButtonMinersUnavailable.Height
$LegacyGUIelements.RadioButtonMiners.Location = [System.Drawing.Point]::new(320, 0)
$LegacyGUIelements.RadioButtonMiners.Text = "All miners"
$LegacyGUIelements.RadioButtonMiners.Width = 100
$LegacyGUIelements.RadioButtonMiners.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $LegacyGUIelements.MinersDGV | Add-Member ColumnWidthChanged $false -Force
        $LegacyGUIelements.MinersDGV.ClearSelection()
        Update-TabControl
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.RadioButtonMiners, "These are all miners.`rNote: UG-Miner will only create miners for algorithms that have at least one available pool.")

$LegacyGUIelements.MinersLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIelements.MinersLabel.AutoSize = $false
$LegacyGUIelements.MinersLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.MinersLabel.Height = 20
$LegacyGUIelements.MinersLabel.Location = [System.Drawing.Point]::new(0, 6)
$LegacyGUIelements.MinersLabel.Width = 600
$LegacyGUIelements.MinersPageControls += $LegacyGUIelements.MinersLabel

$LegacyGUIelements.MinersPanel = [System.Windows.Forms.Panel]::new()
$LegacyGUIelements.MinersPanel.Height = 22
$LegacyGUIelements.MinersPanel.Location = [System.Drawing.Point]::new(0, ($LegacyGUIelements.MinersLabel.Height + 6))
$LegacyGUIelements.MinersPanel.Controls.Add($LegacyGUIelements.RadioButtonMinersOptimal)
$LegacyGUIelements.MinersPanel.Controls.Add($LegacyGUIelements.RadioButtonMinersUnavailable)
$LegacyGUIelements.MinersPanel.Controls.Add($LegacyGUIelements.RadioButtonMiners)
$LegacyGUIelements.MinersPageControls += $LegacyGUIelements.MinersPanel

$LegacyGUIelements.MinersDGV = [System.Windows.Forms.DataGridView]::new()
$LegacyGUIelements.MinersDGV.AllowUserToAddRows = $false
$LegacyGUIelements.MinersDGV.AllowUserToDeleteRows = $false
$LegacyGUIelements.MinersDGV.AllowUserToOrderColumns = $true
$LegacyGUIelements.MinersDGV.AllowUserToResizeColumns = $true
$LegacyGUIelements.MinersDGV.AllowUserToResizeRows = $false
$LegacyGUIelements.MinersDGV.AutoSizeColumnsMode = "Fill"
$LegacyGUIelements.MinersDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIelements.MinersDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIelements.MinersDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LegacyGUIelements.MinersDGV.ColumnHeadersVisible = $true
$LegacyGUIelements.MinersDGV.ContextMenuStrip = $LegacyGUIelements.ContextMenuStrip
$LegacyGUIelements.MinersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LegacyGUIelements.MinersDGV.EnableHeadersVisualStyles = $false
$LegacyGUIelements.MinersDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$LegacyGUIelements.MinersDGV.Height = 3
$LegacyGUIelements.MinersDGV.Location = [System.Drawing.Point]::new(0, ($LegacyGUIelements.MinersLabel.Height + $LegacyGUIelements.MinersPanel.Height + 10))
$LegacyGUIelements.MinersDGV.Name = "MinersDGV"
$LegacyGUIelements.MinersDGV.ReadOnly = $true
$LegacyGUIelements.MinersDGV.RowHeadersVisible = $false
$LegacyGUIelements.MinersDGV.SelectionMode = "FullRowSelect"
$LegacyGUIelements.MinersDGV.Add_MouseUp(
    { 
        If ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right) { 
            $LegacyGUIelements.ContextMenuStrip.Enabled = [Boolean]$this.SelectedRows
        }
    }
)
$LegacyGUIelements.MinersDGV.Add_Sorted({ Set-TableColor -DataGridView $LegacyGUIelements.MinersDGV }) # Re-apply colors after sort
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIelements.MinersDGV -Enabled $true
$LegacyGUIelements.MinersPageControls += $LegacyGUIelements.MinersDGV

# Pools page Controls
$LegacyGUIelements.PoolsPageControls = @()

$LegacyGUIelements.RadioButtonPoolsBest = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIelements.RadioButtonPoolsBest.AutoSize = $false
$LegacyGUIelements.RadioButtonPoolsBest.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.RadioButtonPoolsBest.Height = 22
$LegacyGUIelements.RadioButtonPoolsBest.Location = [System.Drawing.Point]::new(0, 0)
$LegacyGUIelements.RadioButtonPoolsBest.Tag = ""
$LegacyGUIelements.RadioButtonPoolsBest.Text = "Best pools"
$LegacyGUIelements.RadioButtonPoolsBest.Width = 120
$LegacyGUIelements.RadioButtonPoolsBest.Checked = $true
$LegacyGUIelements.RadioButtonPoolsBest.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $LegacyGUIelements.PoolsDGV | Add-Member ColumnWidthChanged $false -Force
        $LegacyGUIelements.PoolsDGV.ClearSelection()
        Update-TabControl
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.RadioButtonPoolsBest, "This is the list of the best paying pool for each algorithm.")

$LegacyGUIelements.RadioButtonPoolsUnavailable = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIelements.RadioButtonPoolsUnavailable.AutoSize = $false
$LegacyGUIelements.RadioButtonPoolsUnavailable.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.RadioButtonPoolsUnavailable.Height = $LegacyGUIelements.RadioButtonPoolsBest.Height
$LegacyGUIelements.RadioButtonPoolsUnavailable.Location = [System.Drawing.Point]::new(120, 0)
$LegacyGUIelements.RadioButtonPoolsUnavailable.Tag = ""
$LegacyGUIelements.RadioButtonPoolsUnavailable.Text = "Unavailable pools"
$LegacyGUIelements.RadioButtonPoolsUnavailable.Width = 170
$LegacyGUIelements.RadioButtonPoolsUnavailable.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $LegacyGUIelements.PoolsDGV | Add-Member ColumnWidthChanged $false -Force
        $LegacyGUIelements.PoolsDGV.ClearSelection()
        Update-TabControl
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.RadioButtonPoolsUnavailable, "This is the pool of all unavailable pools.`rThe column 'Reason(s)' shows the filter criteria(s) that made the pool unavailable.")

$LegacyGUIelements.RadioButtonPools = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIelements.RadioButtonPools.AutoSize = $false
$LegacyGUIelements.RadioButtonPools.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.RadioButtonPools.Height = $LegacyGUIelements.RadioButtonPoolsUnavailable.Height
$LegacyGUIelements.RadioButtonPools.Location = [System.Drawing.Point]::new((120 + 175), 0)
$LegacyGUIelements.RadioButtonPools.Tag = ""
$LegacyGUIelements.RadioButtonPools.Text = "All pools"
$LegacyGUIelements.RadioButtonPools.Width = 100
$LegacyGUIelements.RadioButtonPools.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $LegacyGUIelements.PoolsDGV | Add-Member ColumnWidthChanged $false -Force
        $LegacyGUIelements.PoolsDGV.ClearSelection()
        Update-TabControl
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.RadioButtonPools, "This is the pool data of all configured pools.")

$LegacyGUIelements.PoolsLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIelements.PoolsLabel.AutoSize = $false
$LegacyGUIelements.PoolsLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.PoolsLabel.Location = [System.Drawing.Point]::new(0, 6)
$LegacyGUIelements.PoolsLabel.Height = 20
$LegacyGUIelements.PoolsLabel.Width = 600
$LegacyGUIelements.PoolsPageControls += $LegacyGUIelements.PoolsLabel

$LegacyGUIelements.PoolsPanel = [System.Windows.Forms.Panel]::new()
$LegacyGUIelements.PoolsPanel.Height = 22
$LegacyGUIelements.PoolsPanel.Location = [System.Drawing.Point]::new(0, ($LegacyGUIelements.PoolsLabel.Height + 6))
$LegacyGUIelements.PoolsPanel.Controls.Add($LegacyGUIelements.RadioButtonPools)
$LegacyGUIelements.PoolsPanel.Controls.Add($LegacyGUIelements.RadioButtonPoolsUnavailable)
$LegacyGUIelements.PoolsPanel.Controls.Add($LegacyGUIelements.RadioButtonPoolsBest)
$LegacyGUIelements.PoolsPageControls += $LegacyGUIelements.PoolsPanel

$LegacyGUIelements.PoolsDGV = [System.Windows.Forms.DataGridView]::new()
$LegacyGUIelements.PoolsDGV.AllowUserToAddRows = $false
$LegacyGUIelements.PoolsDGV.AllowUserToDeleteRows = $false
$LegacyGUIelements.PoolsDGV.AllowUserToOrderColumns = $true
$LegacyGUIelements.PoolsDGV.AllowUserToResizeColumns = $true
$LegacyGUIelements.PoolsDGV.AllowUserToResizeRows = $false
$LegacyGUIelements.PoolsDGV.AutoSizeColumnsMode = "Fill"
$LegacyGUIelements.PoolsDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIelements.PoolsDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIelements.PoolsDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LegacyGUIelements.PoolsDGV.ColumnHeadersVisible = $true
$LegacyGUIelements.PoolsDGV.ContextMenuStrip = $LegacyGUIelements.ContextMenuStrip
$LegacyGUIelements.PoolsDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LegacyGUIelements.PoolsDGV.EnableHeadersVisualStyles = $false
$LegacyGUIelements.PoolsDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$LegacyGUIelements.PoolsDGV.Height = 3
$LegacyGUIelements.PoolsDGV.Location = [System.Drawing.Point]::new(0, ($LegacyGUIelements.PoolsLabel.Height + $LegacyGUIelements.PoolsPanel.Height + 10))
$LegacyGUIelements.PoolsDGV.Name = "PoolsDGV"
$LegacyGUIelements.PoolsDGV.ReadOnly = $true
$LegacyGUIelements.PoolsDGV.RowHeadersVisible = $false
$LegacyGUIelements.PoolsDGV.SelectionMode = "FullRowSelect"
$LegacyGUIelements.PoolsDGV.Add_MouseUp(
    { 
        If ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right) { 
            $LegacyGUIelements.ContextMenuStrip.Enabled = [Boolean]$this.SelectedRows
        }
    }
)
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIelements.PoolsDGV -Enabled $true
$LegacyGUIelements.PoolsPageControls += $LegacyGUIelements.PoolsDGV

# Monitoring Page Controls
# $LegacyGUIelements.RigMonitorPageControls = @()

# $LegacyGUIelements.WorkersLabel = [System.Windows.Forms.Label]::new()
# $LegacyGUIelements.WorkersLabel.AutoSize = $false
# $LegacyGUIelements.WorkersLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
# $LegacyGUIelements.WorkersLabel.Height = 20
# $LegacyGUIelements.WorkersLabel.Location = [System.Drawing.Point]::new(0, 6)
# $LegacyGUIelements.WorkersLabel.Width = 900
# $LegacyGUIelements.RigMonitorPageControls += $LegacyGUIelements.WorkersLabel

# $LegacyGUIelements.WorkersDGV = [System.Windows.Forms.DataGridView]::new()
# $LegacyGUIelements.WorkersDGV.AllowUserToAddRows = $false
# $LegacyGUIelements.WorkersDGV.AllowUserToDeleteRows = $false
# $LegacyGUIelements.WorkersDGV.AllowUserToOrderColumns = $true
# $LegacyGUIelements.WorkersDGV.AllowUserToResizeColumns = $true
# $LegacyGUIelements.WorkersDGV.AllowUserToResizeRows = $false
# $LegacyGUIelements.WorkersDGV.AutoSizeColumnsMode = "Fill"
# $LegacyGUIelements.WorkersDGV.AutoSizeRowsMode = "AllCells"
# $LegacyGUIelements.WorkersDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
# $LegacyGUIelements.WorkersDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
# $LegacyGUIelements.WorkersDGV.ColumnHeadersHeightSizeMode = "AutoSize"
# $LegacyGUIelements.WorkersDGV.ColumnHeadersVisible = $true
# $LegacyGUIelements.WorkersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
# $LegacyGUIelements.WorkersDGV.DefaultCellStyle.WrapMode = "True"
# $LegacyGUIelements.WorkersDGV.EnableHeadersVisualStyles = $false
# $LegacyGUIelements.WorkersDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
# $LegacyGUIelements.WorkersDGV.Height = 3
# $LegacyGUIelements.WorkersDGV.Location = [System.Drawing.Point]::new(6, ($LegacyGUIelements.WorkersLabel.Height + 8))
# $LegacyGUIelements.WorkersDGV.ReadOnly = $true
# $LegacyGUIelements.WorkersDGV.RowHeadersVisible = $false
# $LegacyGUIelements.WorkersDGV.SelectionMode = "FullRowSelect"

# $LegacyGUIelements.WorkersDGV.Add_Sorted({ Set-WorkerColor -DataGridView $LegacyGUIelements.WorkersDGV })
# Set-DataGridViewDoubleBuffer -Grid $LegacyGUIelements.WorkersDGV -Enabled $true
# $LegacyGUIelements.RigMonitorPageControls += $LegacyGUIelements.WorkersDGV

$LegacyGUIelements.EditMonitoringLink = [System.Windows.Forms.LinkLabel]::new()
$LegacyGUIelements.EditMonitoringLink.ActiveLinkColor = [System.Drawing.Color]::Blue
$LegacyGUIelements.EditMonitoringLink.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.EditMonitoringLink.Height = 20
$LegacyGUIelements.EditMonitoringLink.Location = [System.Drawing.Point]::new(0, 6)
$LegacyGUIelements.EditMonitoringLink.LinkColor = [System.Drawing.Color]::Blue
$LegacyGUIelements.EditMonitoringLink.Text = "Edit the monitoring configuration"
$LegacyGUIelements.EditMonitoringLink.TextAlign = "MiddleRight"
$LegacyGUIelements.EditMonitoringLink.Size = [System.Drawing.Size]::new(330, 26)
$LegacyGUIelements.EditMonitoringLink.Visible = $false
$LegacyGUIelements.EditMonitoringLink.Width = 330
$LegacyGUIelements.EditMonitoringLink.Add_Click({ Start-Process "http://localhost:$($Session.APIRunspace.APIport)/rigmonitor.html" })
# $LegacyGUIelements.RigMonitorPageControls += $LegacyGUIelements.EditMonitoringLink
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.EditMonitoringLink, "Click to the edit the monitoring configuration in the Web GUI")

# Switching Page Controls
$LegacyGUIelements.SwitchingPageControls = @()

$LegacyGUIelements.SwitchingLogLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIelements.SwitchingLogLabel.AutoSize = $false
$LegacyGUIelements.SwitchingLogLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.SwitchingLogLabel.Height = 20
$LegacyGUIelements.SwitchingLogLabel.Location = [System.Drawing.Point]::new(0, 6)
$LegacyGUIelements.SwitchingLogLabel.Width = 600
$LegacyGUIelements.SwitchingPageControls += $LegacyGUIelements.SwitchingLogLabel

$LegacyGUIelements.SwitchingLogClearButton = [System.Windows.Forms.Button]::new()
$LegacyGUIelements.SwitchingLogClearButton.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.SwitchingLogClearButton.Height = 24
$LegacyGUIelements.SwitchingLogClearButton.Location = [System.Drawing.Point]::new(0, ($LegacyGUIelements.SwitchingLogLabel.Height + 8))
$LegacyGUIelements.SwitchingLogClearButton.Text = "Clear switching log"
$LegacyGUIelements.SwitchingLogClearButton.Visible = $true
$LegacyGUIelements.SwitchingLogClearButton.Width = 160
$LegacyGUIelements.SwitchingLogClearButton.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

        Get-ChildItem -Path ".\Logs\SwitchingLog.csv" -File | Remove-Item -Force
        $LegacyGUIelements.SwitchingDGV.DataSource = $null
        $Data = "Switching log '.\Logs\SwitchingLog.csv' cleared."
        Write-Message -Level Verbose "GUI: $Data" -Console $false
        $LegacyGUIelements.SwitchingLogClearButton.Enabled = $false

        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal

        [Void][System.Windows.Forms.MessageBox]::Show($Data, "$($Session.Branding.ProductLabel) $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK, 64)
    }
)
$LegacyGUIelements.SwitchingPageControls += $LegacyGUIelements.SwitchingLogClearButton
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.SwitchingLogClearButton, "This will clear the switching log '.\Logs\SwitchingLog.csv'")

$LegacyGUIelements.CheckShowSwitchingCPU = [System.Windows.Forms.CheckBox]::new()
$LegacyGUIelements.CheckShowSwitchingCPU.AutoSize = $false
$LegacyGUIelements.CheckShowSwitchingCPU.Enabled = [Boolean]($Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Config.ExcludeDeviceName -and $_.Type -eq "CPU" }))
$LegacyGUIelements.CheckShowSwitchingCPU.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.CheckShowSwitchingCPU.Height = 20
$LegacyGUIelements.CheckShowSwitchingCPU.Location = [System.Drawing.Point]::new(($LegacyGUIelements.SwitchingLogClearButton.Width + 40), ($LegacyGUIelements.SwitchingLogLabel.Height + 10))
$LegacyGUIelements.CheckShowSwitchingCPU.Tag = "CPU"
$LegacyGUIelements.CheckShowSwitchingCPU.Text = "CPU"
$LegacyGUIelements.CheckShowSwitchingCPU.Width = 70
$LegacyGUIelements.SwitchingPageControls += $LegacyGUIelements.CheckShowSwitchingCPU
$LegacyGUIelements.CheckShowSwitchingCPU.ForEach({ $_.Add_Click({ CheckBoxSwitching_Click($this) }) })

$LegacyGUIelements.CheckShowSwitchingAMD = [System.Windows.Forms.CheckBox]::new()
$LegacyGUIelements.CheckShowSwitchingAMD.AutoSize = $false
$LegacyGUIelements.CheckShowSwitchingAMD.Enabled = [Boolean]($Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Config.ExcludeDeviceName -and $_.Type -eq "GPU" -and $_.Vendor -eq "AMD" }))
$LegacyGUIelements.CheckShowSwitchingAMD.Height = 20
$LegacyGUIelements.CheckShowSwitchingAMD.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.CheckShowSwitchingAMD.Location = [System.Drawing.Point]::new(($LegacyGUIelements.SwitchingLogClearButton.Width + 40 + $LegacyGUIelements.CheckShowSwitchingCPU.Width), ($LegacyGUIelements.SwitchingLogLabel.Height + 10))
$LegacyGUIelements.CheckShowSwitchingAMD.Tag = "AMD"
$LegacyGUIelements.CheckShowSwitchingAMD.Text = "AMD"
$LegacyGUIelements.CheckShowSwitchingAMD.Width = 70
$LegacyGUIelements.SwitchingPageControls += $LegacyGUIelements.CheckShowSwitchingAMD
$LegacyGUIelements.CheckShowSwitchingAMD.ForEach({ $_.Add_Click({ CheckBoxSwitching_Click($this) }) })

$LegacyGUIelements.CheckShowSwitchingINTEL = [System.Windows.Forms.CheckBox]::new()
$LegacyGUIelements.CheckShowSwitchingINTEL.AutoSize = $false
$LegacyGUIelements.CheckShowSwitchingINTEL.Enabled = [Boolean]($Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Config.ExcludeDeviceName -and $_.Type -eq "GPU" -and $_.Vendor -eq "INTEL" }))
$LegacyGUIelements.CheckShowSwitchingINTEL.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.CheckShowSwitchingINTEL.Height = 20
$LegacyGUIelements.CheckShowSwitchingINTEL.Location = [System.Drawing.Point]::new(($LegacyGUIelements.SwitchingLogClearButton.Width + 40 + $LegacyGUIelements.CheckShowSwitchingCPU.Width + $LegacyGUIelements.CheckShowSwitchingAMD.Width), ($LegacyGUIelements.SwitchingLogLabel.Height + 10))
$LegacyGUIelements.CheckShowSwitchingINTEL.Tag = "INTEL"
$LegacyGUIelements.CheckShowSwitchingINTEL.Text = "INTEL"
$LegacyGUIelements.CheckShowSwitchingINTEL.Width = 77
$LegacyGUIelements.SwitchingPageControls += $LegacyGUIelements.CheckShowSwitchingINTEL
$LegacyGUIelements.CheckShowSwitchingINTEL.ForEach({ $_.Add_Click({ CheckBoxSwitching_Click($this) }) })

$LegacyGUIelements.CheckShowSwitchingNVIDIA = [System.Windows.Forms.CheckBox]::new()
$LegacyGUIelements.CheckShowSwitchingNVIDIA.AutoSize = $false
$LegacyGUIelements.CheckShowSwitchingNVIDIA.Enabled = [Boolean]($Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Config.ExcludeDeviceName -and $_.Type -eq "GPU" -and $_.Vendor -eq "NVIDIA" }))
$LegacyGUIelements.CheckShowSwitchingNVIDIA.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.CheckShowSwitchingNVIDIA.Height = 20
$LegacyGUIelements.CheckShowSwitchingNVIDIA.Location = [System.Drawing.Point]::new(($LegacyGUIelements.SwitchingLogClearButton.Width + 40 + $LegacyGUIelements.CheckShowSwitchingCPU.Width + $LegacyGUIelements.CheckShowSwitchingAMD.Width + $LegacyGUIelements.CheckShowSwitchingINTEL.Width), ($LegacyGUIelements.SwitchingLogLabel.Height + 10))
$LegacyGUIelements.CheckShowSwitchingNVIDIA.Tag = "NVIDIA"
$LegacyGUIelements.CheckShowSwitchingNVIDIA.Text = "NVIDIA"
$LegacyGUIelements.CheckShowSwitchingNVIDIA.Width = 80
$LegacyGUIelements.SwitchingPageControls += $LegacyGUIelements.CheckShowSwitchingNVIDIA
$LegacyGUIelements.CheckShowSwitchingNVIDIA.ForEach({ $_.Add_Click({ CheckBoxSwitching_Click($this) }) })

$LegacyGUIelements.SwitchingDGV = [System.Windows.Forms.DataGridView]::new()
$LegacyGUIelements.SwitchingDGV.AllowUserToAddRows = $false
$LegacyGUIelements.SwitchingDGV.AllowUserToDeleteRows = $false
$LegacyGUIelements.SwitchingDGV.AllowUserToOrderColumns = $true
$LegacyGUIelements.SwitchingDGV.AllowUserToResizeColumns = $true
$LegacyGUIelements.SwitchingDGV.AllowUserToResizeRows = $false
$LegacyGUIelements.SwitchingDGV.AutoSizeColumnsMode = "Fill"
$LegacyGUIelements.SwitchingDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIelements.SwitchingDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIelements.SwitchingDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LegacyGUIelements.SwitchingDGV.ColumnHeadersVisible = $true
$LegacyGUIelements.SwitchingDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LegacyGUIelements.SwitchingDGV.EnableHeadersVisualStyles = $false
$LegacyGUIelements.SwitchingDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$LegacyGUIelements.SwitchingDGV.Height = 3
$LegacyGUIelements.SwitchingDGV.Location = [System.Drawing.Point]::new(0, ($LegacyGUIelements.SwitchingLogLabel.Height + $LegacyGUIelements.SwitchingLogClearButton.Height + 12))
$LegacyGUIelements.SwitchingDGV.Name = "SwitchingDGV"
$LegacyGUIelements.SwitchingDGV.ReadOnly = $true
$LegacyGUIelements.SwitchingDGV.RowHeadersVisible = $false
$LegacyGUIelements.SwitchingDGV.SelectionMode = "FullRowSelect"
$LegacyGUIelements.SwitchingDGV.Add_Sorted(
    { 
        If ($Config.UseColorForMinerStatus) { 
            ForEach ($Row in $LegacyGUIelements.SwitchingDGV.Rows) { 
                $Row.DefaultCellStyle.Backcolor = $Row.DefaultCellStyle.SelectionBackColor = $LegacyGUIelements.Colors[$Row.DataBoundItem.Action]
                $Row.DefaultCellStyle.SelectionForeColor = $LegacyGUIelements.SwitchingDGV.DefaultCellStyle.ForeColor
            }
        }
     }
)
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIelements.SwitchingDGV -Enabled $true
$LegacyGUIelements.SwitchingPageControls += $LegacyGUIelements.SwitchingDGV

$LegacyGUIelements.CheckShowSwitchingCPU.Checked = $LegacyGUIelements.CheckShowSwitchingCPU.Enabled
$LegacyGUIelements.CheckShowSwitchingAMD.Checked = $LegacyGUIelements.CheckShowSwitchingAMD.Enabled
$LegacyGUIelements.CheckShowSwitchingINTEL.Checked = $LegacyGUIelements.CheckShowSwitchingINTEL.Enabled
$LegacyGUIelements.CheckShowSwitchingNVIDIA.Checked = $LegacyGUIelements.CheckShowSwitchingNVIDIA.Enabled

# Watchdog Page Controls
$LegacyGUIelements.WatchdogTimersPageControls = @()

$LegacyGUIelements.WatchdogTimersLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIelements.WatchdogTimersLabel.AutoSize = $false
$LegacyGUIelements.WatchdogTimersLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.WatchdogTimersLabel.Height = 20
$LegacyGUIelements.WatchdogTimersLabel.Location = [System.Drawing.Point]::new(0, 6)
$LegacyGUIelements.WatchdogTimersLabel.Width = 600
$LegacyGUIelements.WatchdogTimersPageControls += $LegacyGUIelements.WatchdogTimersLabel

$LegacyGUIelements.WatchdogTimersRemoveButton = [System.Windows.Forms.Button]::new()
$LegacyGUIelements.WatchdogTimersRemoveButton.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.WatchdogTimersRemoveButton.Height = 24
$LegacyGUIelements.WatchdogTimersRemoveButton.Location = [System.Drawing.Point]::new(0, ($LegacyGUIelements.WatchdogTimersLabel.Height + 8))
$LegacyGUIelements.WatchdogTimersRemoveButton.Text = "Remove all watchdog timers"
$LegacyGUIelements.WatchdogTimersRemoveButton.Visible = $true
$LegacyGUIelements.WatchdogTimersRemoveButton.Width = 220
$LegacyGUIelements.WatchdogTimersRemoveButton.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

        $Session.WatchdogTimers = [System.Collections.Generic.List[PSCustomObject]]::new()
        $LegacyGUIelements.WatchdogTimersDGV.DataSource = $null
        Foreach ($Miner in $Session.Miners) { 
            $Miner.Reasons.Where({ $_ -like "Miner suspended by watchdog *" }).ForEach({ $Miner.Reasons.Remove($_) | Out-Null })
            If (-not $Miner.Reasons.Count) { $_.Available = $true }
        }
        Remove-Variable Miner

        ForEach ($Pool in $Session.Pools.ForEach) { 
            $Pool.Reasons.Where({ $_ -like "Pool suspended by watchdog *" }).ForEach({ $Pool.Reasons.Remove($_) | Out-Null })
            If (-not $Pool.Reasons.Count) { $Pool.Available = $true }
        }
        Remove-Variable Pool

        Write-Message -Level Verbose "GUI: All watchdog timers removed." -Console $false
        Update-TabControl

        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal

        [Void][System.Windows.Forms.MessageBox]::Show("All watchdog timers removed.`nWatchdog timers will be recreated in the next cycle.", "$($Session.Branding.ProductLabel) $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK, 64)
    }
)
$LegacyGUIelements.WatchdogTimersPageControls += $LegacyGUIelements.WatchdogTimersRemoveButton
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.WatchdogTimersRemoveButton, "This will remove all watchdog timers.`rWatchdog timers will be recreated in the next cycle.")

$LegacyGUIelements.WatchdogTimersDGV = [System.Windows.Forms.DataGridView]::new()
$LegacyGUIelements.WatchdogTimersDGV.AllowUserToAddRows = $false
$LegacyGUIelements.WatchdogTimersDGV.AllowUserToDeleteRows = $false
$LegacyGUIelements.WatchdogTimersDGV.AllowUserToOrderColumns = $true
$LegacyGUIelements.WatchdogTimersDGV.AllowUserToResizeColumns = $true
$LegacyGUIelements.WatchdogTimersDGV.AllowUserToResizeRows = $false
$LegacyGUIelements.WatchdogTimersDGV.AutoSizeColumnsMode = "Fill"
$LegacyGUIelements.WatchdogTimersDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIelements.WatchdogTimersDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIelements.WatchdogTimersDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LegacyGUIelements.WatchdogTimersDGV.ColumnHeadersVisible = $true
$LegacyGUIelements.WatchdogTimersDGV.DefaultCellStyle.SelectionBackColor = $LegacyGUIelements.WatchdogTimersDGV.DefaultCellStyle.BackColor
$LegacyGUIelements.WatchdogTimersDGV.DefaultCellStyle.SelectionForeColor = $LegacyGUIelements.WatchdogTimersDGV.DefaultCellStyle.ForeColor
$LegacyGUIelements.WatchdogTimersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LegacyGUIelements.WatchdogTimersDGV.EnableHeadersVisualStyles = $false
$LegacyGUIelements.WatchdogTimersDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$LegacyGUIelements.WatchdogTimersDGV.Height = 3
$LegacyGUIelements.WatchdogTimersDGV.Location = [System.Drawing.Point]::new(0, ($LegacyGUIelements.WatchdogTimersLabel.Height + $LegacyGUIelements.WatchdogTimersRemoveButton.Height + 12))
$LegacyGUIelements.WatchdogTimersDGV.Name = "WatchdogTimersDGV"
$LegacyGUIelements.WatchdogTimersDGV.ReadOnly = $true
$LegacyGUIelements.WatchdogTimersDGV.RowHeadersVisible = $false
$LegacyGUIelements.WatchdogTimersDGV.SelectionMode = "FullRowSelect"
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIelements.WatchdogTimersDGV -Enabled $true
$LegacyGUIelements.WatchdogTimersPageControls += $LegacyGUIelements.WatchdogTimersDGV

$LegacyGUIform.Controls.AddRange(@($LegacyGUIelements.Controls))
$LegacyGUIelements.StatusPage.Controls.AddRange(@($LegacyGUIelements.StatusPageControls))
$LegacyGUIelements.EarningsPage.Controls.AddRange(@($LegacyGUIelements.EarningsPageControls))
$LegacyGUIelements.MinersPage.Controls.AddRange(@($LegacyGUIelements.MinersPageControls))
$LegacyGUIelements.PoolsPage.Controls.AddRange(@($LegacyGUIelements.PoolsPageControls))
# $LegacyGUIelements.RigMonitorPage.Controls.AddRange(@($LegacyGUIelements.RigMonitorPageControls))
$LegacyGUIelements.SwitchingPage.Controls.AddRange(@($LegacyGUIelements.SwitchingPageControls))
$LegacyGUIelements.WatchdogTimersPage.Controls.AddRange(@($LegacyGUIelements.WatchdogTimersPageControls))

$LegacyGUIelements.TabControl = [System.Windows.Forms.TabControl]::new()
$LegacyGUIelements.TabControl.Appearance = "Buttons"
$LegacyGUIelements.TabControl.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LegacyGUIelements.TabControl.Height = 0
$LegacyGUIelements.TabControl.Location = [System.Drawing.Point]::new(12, $LegacyGUIelements.MiningSummaryLabel.Bottom + 10)
$LegacyGUIelements.TabControl.Name = "TabControl"
$LegacyGUIelements.TabControl.ShowToolTips = $true
$LegacyGUIelements.TabControl.Padding = [System.Drawing.Point]::new(18, 6)
$LegacyGUIelements.TabControl.Width = 0
# $LegacyGUIelements.TabControl.Controls.AddRange(@($LegacyGUIelements.StatusPage, $LegacyGUIelements.EarningsPage, $LegacyGUIelements.MinersPage, $LegacyGUIelements.PoolsPage, $LegacyGUIelements.RigMonitorPage, $LegacyGUIelements.SwitchingPage, $LegacyGUIelements.WatchdogTimersPage))
$LegacyGUIelements.TabControl.Controls.AddRange(@($LegacyGUIelements.StatusPage, $LegacyGUIelements.EarningsPage, $LegacyGUIelements.MinersPage, $LegacyGUIelements.PoolsPage, $LegacyGUIelements.SwitchingPage, $LegacyGUIelements.WatchdogTimersPage))
$LegacyGUIelements.TabControl.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        Update-TabControl
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)

$LegacyGUIform.Controls.Add($LegacyGUIelements.TabControl)
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

        Switch ($Session.MiningStatus) { 
            "Idle" { 
                $LegacyGUIelements.ButtonPause.Enabled = $true
                $LegacyGUIelements.ButtonStart.Enabled = $true
                $LegacyGUIelements.ButtonStop.Enabled = $false
                Break
            }
            "Paused" { 
                $LegacyGUIelements.ButtonPause.Enabled = $false
                $LegacyGUIelements.ButtonStart.Enabled = $true
                $LegacyGUIelements.ButtonStop.Enabled = $true
                Break
            }
            "Running" { 
                $LegacyGUIelements.ButtonPause.Enabled = $true
                $LegacyGUIelements.ButtonStart.Enabled = $false
                $LegacyGUIelements.ButtonStop.Enabled = $true
            }
        }

        $TimerUI = [System.Windows.Forms.Timer]::new()
        $TimerUI.Interval = 500
        $TimerUI.Add_Tick(
            { 
                If ($Session.APIRunspace) { 
                    If ($LegacyGUIelements.EditConfigLink.Tag -ne "WebGUI") { 
                        $LegacyGUIelements.EditConfigLink.Tag = "WebGUI"
                        $LegacyGUIelements.EditConfigLink.Text = "Edit configuration in the Web GUI"
                    }
                }
                ElseIf ($LegacyGUIelements.EditConfigLink.Tag -ne "Edit-File") { 
                    $LegacyGUIelements.EditConfigLink.Tag = "Edit-File"
                    $LegacyGUIelements.EditConfigLink.Text = "Edit configuration file '$($Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))' in notepad"
                }
                MainLoop
            }
        )
        $TimerUI.Start()
    }
)

$LegacyGUIform.Add_FormClosing(
    { 
        If ($KeyPressed.KeyChar -ne "4") { # 4: Closing triggered via console window
            If (-not $Config.ShowConsole) { # If console is not visible there is no user friendly way to end script
                $MsgBoxInput = [System.Windows.Forms.MessageBox]::Show("Do you want to shut down $($Session.Branding.ProductLabel)?", "$($Session.Branding.ProductLabel)", [System.Windows.Forms.MessageBoxButtons]::YesNo, 32, "Button2")
                If ($MsgBoxInput -eq "No") { 
                    $_.Cancel = $true
                    Return
                }
            }
            Else { 
                $MsgBoxInput = [System.Windows.Forms.MessageBox]::Show("Do you also want to shut down $($Session.Branding.ProductLabel)?", "$($Session.Branding.ProductLabel)", [System.Windows.Forms.MessageBoxButtons]::YesNoCancel, 32, "Button3")
                If ($MsgBoxInput -eq "Cancel") { 
                    $_.Cancel = $true
                    Return
                }
            }
            $Session.LegacyGUI = $false
        }

        # Save window settings
        If ($LegacyGUIform.DesktopBounds.Width -ge 0) { [PSCustomObject]@{ Top = $LegacyGUIform.Top; Left = $LegacyGUIform.Left; Height = $LegacyGUIform.Height; Width = $LegacyGUIform.Width } | ConvertTo-Json | Out-File -LiteralPath ".\Config\WindowSettings.json" -Force -ErrorAction Ignore }

        $TimerUI.Stop()

        If ($MsgBoxInput -eq "Yes") { 
            $LegacyGUIelements.TabControl.SelectTab(0)
            
            Write-Message -Level Info "Shutting down $($Session.Branding.ProductLabel)..."
            $Session.NewMiningStatus = "Idle"

            Stop-Core
            Stop-Brain
            Stop-BalancesTracker

            Write-Message -Level Info "$($Session.Branding.ProductLabel) has shut down."
            Start-Sleep -Seconds 2
            Stop-Process $PID -Force
        }
    }
)

$LegacyGUIform.Add_KeyDown(
    { 
        If ($Session.NewMiningStatus -eq "Running" -and $_.Control -and $_.Alt -and $_.KeyCode -eq "P") { 
            # '<Ctrl><Alt>P' pressed
            If (-not $Global:CoreRunspace.AsyncObject.IsCompleted -eq $false) { 
                # Core is complete / gone. Cycle cannot be suspended anymore
                $Session.SuspendCycle = $false
            }
            Else { 
                $Session.SuspendCycle = -not $Session.SuspendCycle
                If ($Session.SuspendCycle) { 
                    $Message = "'<Ctrl><Alt>P' pressed. Core cycle is suspended until you press '<Ctrl><Alt>P' again."
                    $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Blue
                    $LegacyGUIelements.MiningSummaryLabel.Text = $Message
                    $LegacyGUIelements.ButtonPause.Enabled = $false
                    Write-Host $Message -ForegroundColor Cyan
                }
                Else { 
                    $Message = "'<Ctrl><Alt>P' pressed. Core cycle is running again."
                    $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Blue
                    $LegacyGUIelements.MiningSummaryLabel.Text = $Message
                    $LegacyGUIelements.ButtonPause.Enabled = $true
                    Write-Host $Message -ForegroundColor Cyan
                    If ([DateTime]::Now.ToUniversalTime() -gt $Session.EndCycleTime) { $Session.EndCycleTime = [DateTime]::Now.ToUniversalTime() }
                }
            }
        }
        ElseIf ($_.KeyCode -eq "F5") { 
            $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
            # Clear selection, this will allow refreshing the table data
            $LegacyGUIelements.ActiveMinersDGV.ClearSelection()
            $LegacyGUIelements.BalancesDGV.ClearSelection()
            $LegacyGUIelements.MinersDGV.ClearSelection()
            $LegacyGUIelements.PoolsDGV.ClearSelection()
            # $LegacyGUIelements.WorkersDGV.ClearSelection()

            Update-TabControl
            $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
        }
    }
)

$LegacyGUIform.Add_SizeChanged({ Resize-Form })