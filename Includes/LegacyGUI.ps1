<#
Copyright (c) 2018-2026 UselessGuru

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
Version:        6.8.6
Version date:   2026/05/03
#>

[Void][System.Reflection.Assembly]::Load("System.Windows.Forms")
[Void][System.Reflection.Assembly]::Load("System.Windows.Forms.DataVisualization")
[Void][System.Reflection.Assembly]::Load("System.Drawing")

$Font = "Segoe UI"
$Font2 = "Microsoft Sans Serif"

function Disable-X {
    # Taken from https://stackoverflow.com/questions/73746912/disable-the-close-x-button-in-powershell

    # Calling user32.dll methods for Windows and Menus
    $MethodsCall = '
    [DllImport("user32.dll")] public static extern long GetSystemMenu(IntPtr hWnd, bool bRevert);
    [DllImport("user32.dll")] public static extern bool EnableMenuItem(long hMenuItem, long wIDEnableItem, long wEnable);
    [DllImport("user32.dll")] public static extern long SetWindowLongPtr(long hWnd, long nIndex, long dwNewLong);
    [DllImport("user32.dll")] public static extern bool EnableWindow(long hWnd, int bEnable);
    '

    $SC_CLOSE = 0xF060
    $MF_DISABLED = 0x00000002L

    # Create a new namespace for the Methods to be able to call them
    Add-Type -MemberDefinition $MethodsCall -Name NativeMethods -Namespace Win32

    $PSWindow = Get-Process -Id $PID -ErrorAction Ignore
    $hwnd = $PSWindow.MainWindowHandle

    # Get System menu of windows handled
    $hMenu = [Win32.NativeMethods]::GetSystemMenu($hwnd, 0)

    # Disable X Button
    $null = [Win32.NativeMethods]::EnableMenuItem($hMenu, $SC_CLOSE, $MF_DISABLED)
}

# For High DPI, Call SetProcessDPIAware(need P/Invoke) and EnableVisualStyles
Add-Type -TypeDefinition '
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

public class DPIAware
{
    public static readonly IntPtr UNAWARE              = (IntPtr) (-1);
    public static readonly IntPtr SYSTEM_AWARE         = (IntPtr) (-2);
    public static readonly IntPtr PER_MONITOR_AWARE    = (IntPtr) (-3);
    public static readonly IntPtr PER_MONITOR_AWARE_V2 = (IntPtr) (-4);
    public static readonly IntPtr UNAWARE_GDISCALED    = (IntPtr) (-5);

    [DllImport("user32.dll", EntryPoint = "SetProcessDpiAwarenessContext", SetLastError = true)]
    private static extern bool NativeSetProcessDpiAwarenessContext(IntPtr Value);

    public static void SetProcessDpiAwarenessContext(IntPtr Value)
    {
        if (!NativeSetProcessDpiAwarenessContext(Value))
        {
            throw new Win32Exception();
        }
    }
}
'
[DPIAware]::SetProcessDpiAwarenessContext([DPIAware]::PER_MONITOR_AWARE_V2)

function Resize-Form { 

    if ($LegacyGUIform.WindowState -eq "Minimized") { return }
    $LegacyGUIelements.TabControl.Height = $LegacyGUIform.ClientSize.Height - $LegacyGUIelements.MiningStatusLabel.Height - $LegacyGUIelements.MiningSummaryLabel.Height - $LegacyGUIelements.EditConfigLink.Height - $LegacyGUIelements.EditConfigLink.Height + 3
    $LegacyGUIelements.TabControl.Width = $LegacyGUIform.ClientSize.Width - 20

    $LegacyGUIelements.ButtonStart.Location = [System.Drawing.Point]::new(($LegacyGUIform.ClientSize.Width - $LegacyGUIelements.ButtonStop.Width - $LegacyGUIelements.ButtonPause.Width - $LegacyGUIelements.ButtonStart.Width - 44), 10)
    $LegacyGUIelements.ButtonPause.Location = [System.Drawing.Point]::new(($LegacyGUIform.ClientSize.Width - $LegacyGUIelements.ButtonStop.Width - $LegacyGUIelements.ButtonPause.Width - 34), $LegacyGUIelements.ButtonStart.Top)
    $LegacyGUIelements.ButtonStop.Location = [System.Drawing.Point]::new(($LegacyGUIform.ClientSize.Width - $LegacyGUIelements.ButtonStop.Width - 24), $LegacyGUIelements.ButtonStart.Top)

    # $LegacyGUIelements.EditMonitoringLink.Location = [System.Drawing.Point]::new(($LegacyGUIelements.TabControl.Width - $LegacyGUIelements.EditMonitoringLink.Width - 12), 6)
    $LegacyGUIelements.MiningSummaryLabel.Width = $LegacyGUIelements.ActiveMinersDGV.Width = $LegacyGUIelements.EarningsChart.Width = $LegacyGUIelements.BalancesDGV.Width = $LegacyGUIelements.MinersPanel.Width = $LegacyGUIelements.MinersDGV.Width = $LegacyGUIelements.PoolsPanel.Width = $LegacyGUIelements.PoolsDGV.Width = $LegacyGUIelements.SwitchingLogDGV.Width = $LegacyGUIelements.WatchdogTimersDGV.Width = $LegacyGUIform.ClientSize.Width - 44
    $Session.TextBoxSystemLog.Width = $LegacyGUIelements.TabControl.ClientSize.Width - 16

    $LegacyGUIelements.EditConfigLink.Location = [System.Drawing.Point]::new(18, ($LegacyGUIform.ClientSize.Height - $LegacyGUIelements.EditConfigLink.Height - 2))
    $LegacyGUIelements.CopyrightLabel.Location = [System.Drawing.Point]::new(($LegacyGUIelements.TabControl.ClientSize.Width - $LegacyGUIelements.CopyrightLabel.Width - 4), $LegacyGUIelements.EditConfigLink.Top)

    # System status panel height
    $ActiveMinersDGVheight = $LegacyGUIelements.ActiveMinersDGV.RowTemplate.Height * $LegacyGUIelements.ActiveMinersDGV.RowCount + $LegacyGUIelements.ActiveMinersDGV.ColumnHeadersHeight
    if ($ActiveMinersDGVheight -gt $LegacyGUIelements.TabControl.ClientSize.Height / 2) { $ActiveMinersDGVheight = $LegacyGUIelements.TabControl.ClientSize.Height / 2 }
    $LegacyGUIelements.ActiveMinersDGV.Height = $ActiveMinersDGVheight
    $LegacyGUIelements.SystemLogLabel.Location = [System.Drawing.Point]::new(0, ($LegacyGUIelements.ActiveMinersDGV.Bottom + 8))
    $Session.TextBoxSystemLog.Location = [System.Drawing.Point]::new(0, $LegacyGUIelements.SystemLogLabel.Bottom)
    if (-not $Session.TextBoxSystemLog.SelectionLength) { $Session.TextBoxSystemLog.ScrollToCaret() }

    if ($LegacyGUIelements.TabControl.SelectedTab.Name -eq "EarningsAndBalances") { 
        # Earnings and balances panel height
        if ($Session.Config.BalancesTrackerPollInterval -gt 0) { 
            $LegacyGUIelements.BalancesDGV.Visible = $true
            $LegacyGUIelements.EarningsChart.Visible = $true

            $BalancesDGVheight = $LegacyGUIelements.BalancesDGV.RowTemplate.Height * $LegacyGUIelements.BalancesDGV.RowCount + $LegacyGUIelements.BalancesDGV.ColumnHeadersHeight
            if ($BalancesDGVheight -gt $LegacyGUIelements.TabControl.ClientSize.Height / 2) { 
                $BalancesDGVheight = $LegacyGUIelements.TabControl.ClientSize.Height / 2
                $LegacyGUIelements.BalancesDGV.ScrollBars = "Vertical"
            }
            else { 
                $LegacyGUIelements.BalancesDGV.ScrollBars = "None"
            }
            $LegacyGUIelements.BalancesDGV.Height = $BalancesDGVheight
            $LegacyGUIelements.EarningsChart.Height = $LegacyGUIelements.TabControl.ClientSize.Height - $LegacyGUIelements.BalancesDGV.Height - $LegacyGUIelements.BalancesLabel.Height - 62
            $LegacyGUIelements.BalancesLabel.Location = [System.Drawing.Point]::new(0, $LegacyGUIelements.EarningsChart.Bottom)
            $LegacyGUIelements.BalancesDGV.Top = $LegacyGUIelements.BalancesLabel.Bottom
        }
        else { 
            $LegacyGUIelements.BalancesDGV.Visible = $false
            $LegacyGUIelements.BalancesLabel.Location = [System.Drawing.Point]::new(0, 20)
            $LegacyGUIelements.EarningsChart.Visible = $false
            $LegacyGUIelements.EarningsChart.Height = 0
        }
    }
    else { 
        $Session.TextBoxSystemLog.Height = $LegacyGUIelements.StatusPage.Bottom - $LegacyGUIelements.SystemLogLabel.Bottom - 58
        $LegacyGUIelements.MinersDGV.Height = $LegacyGUIelements.MinersPage.Bottom - $LegacyGUIelements.MinersPanel.Bottom - 64
        $LegacyGUIelements.PoolsDGV.Height = $LegacyGUIelements.PoolsPage.Bottom - $LegacyGUIelements.PoolsPanel.Bottom - 64
        # $LegacyGUIelements.WorkersDGV.Height = $LegacyGUIelements.WorkersPage.Bottom - $LegacyGUIelements.WorkersLabel.Bottom - 64
        $LegacyGUIelements.SwitchingLogDGV.Height = $LegacyGUIelements.SwitchingLogPage.Bottom - $LegacyGUIelements.SwitchingLogClearButton.Bottom - 64
        $LegacyGUIelements.WatchdogTimersDGV.Height = $LegacyGUIelements.WatchdogTimersPage.Bottom - $LegacyGUIelements.WatchdogTimersRemoveButton.Bottom - 64
    }
}

function CheckBoxSwitchingLog_Click { 
    $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $LegacyGUIelements.SwitchingLogDGV.ClearSelection()

    $LegacyGUIelements.ContextMenuStripItem1.Enabled = $true
    $LegacyGUIelements.ContextMenuStripItem1.Text = "Re-benchmark miner"
    $LegacyGUIelements.ContextMenuStripItem1.Visible = $true
    $LegacyGUIelements.ContextMenuStripItem2.Enabled = $Session.Config.CalculatePowerCost
    $LegacyGUIelements.ContextMenuStripItem2.Text = "Re-measure power consumption"
    $LegacyGUIelements.ContextMenuStripItem2.Visible = $true
    $LegacyGUIelements.ContextMenuStripItem3.Enabled = $true
    $LegacyGUIelements.ContextMenuStripItem3.Text = "Mark miner as failed"
    $LegacyGUIelements.ContextMenuStripItem4.Enabled = $true
    $LegacyGUIelements.ContextMenuStripItem4.Text = "Disable miner"
    $LegacyGUIelements.ContextMenuStripItem4.Visible = $true
    $LegacyGUIelements.ContextMenuStripItem6.Visible = $false
    $LegacyGUIelements.ContextMenuStripItem7.Enabled = $true
    $LegacyGUIelements.ContextMenuStripItem7.Text = "Copy miner command line to clipboard"
    $LegacyGUIelements.ContextMenuStripItem7.Visible = $true

    $SwitchingLogDisplayTypes = $LegacyGUIelements.SwitchingLogPageControls.Where({ $_.Checked }).Tag
    if (Test-Path -LiteralPath ".\Logs\SwitchingLog.csv" -PathType Leaf) { 
        $LegacyGUIelements.SwitchingLogLabel.Text = "Switching log updated $((Get-ChildItem -Path ".\Logs\SwitchingLog.csv").LastWriteTime.ToString())"
        $LegacyGUIelements.SwitchingLogDGV.DataSource = (([System.IO.File]::ReadAllLines(".\Logs\SwitchingLog.csv") | ConvertFrom-Csv).Where({ $SwitchingLogDisplayTypes -contains $_.Type }) | Select-Object -Last 1000).ForEach({ $_.Datetime = (Get-Date $_.DateTime); $_ }) | Sort-Object -Property DateTime -Descending | Select-Object -Property "DateTime", "Action", "Name", "Pools", "Algorithms", "Accounts", "Cycle", "Duration", "DeviceNames", "Type", "CommandLine" | Out-DataTable
        if (-not $LegacyGUIelements.ColumnWidthChanged -and $LegacyGUIelements.SwitchingLogDGV.Columns) { 
            $LegacyGUIelements.SwitchingLogDGV.Columns[0].FillWeight = 50; $LegacyGUIelements.SwitchingLogDGV.Sort($LegacyGUIelements.SwitchingLogDGV.Columns[0], [System.ComponentModel.ListSortDirection]::Descending)
            $LegacyGUIelements.SwitchingLogDGV.Columns[1].FillWeight = 50
            $LegacyGUIelements.SwitchingLogDGV.Columns[2].FillWeight = 90; $LegacyGUIelements.SwitchingLogDGV.Columns[2].HeaderText = "Miner"
            $LegacyGUIelements.SwitchingLogDGV.Columns[3].FillWeight = 60 + ($LegacyGUIelements.SwitchingLogDGV.MinersBest_Combo.ForEach({ $_.Pools.Count }) | Measure-Object -Maximum).Maximum * 40; $LegacyGUIelements.SwitchingLogDGV.Columns[3].HeaderText = "Pool(s)"
            $LegacyGUIelements.SwitchingLogDGV.Columns[4].FillWeight = 50 + ($LegacyGUIelements.SwitchingLogDGV.MinersBest_Combo.ForEach({ $_.Algorithms.Count }) | Measure-Object -Maximum).Maximum * 25; $LegacyGUIelements.SwitchingLogDGV.Columns[4].HeaderText = "Algorithm(s) (variant)"
            $LegacyGUIelements.SwitchingLogDGV.Columns[5].FillWeight = 90 + ($LegacyGUIelements.SwitchingLogDGV.MinersBest_Combo.ForEach({ $_.Accounts.Count }) | Measure-Object -Maximum).Maximum * 50; $LegacyGUIelements.SwitchingLogDGV.Columns[5].HeaderText = "Account(s)"
            $LegacyGUIelements.SwitchingLogDGV.Columns[6].FillWeight = 30; $LegacyGUIelements.SwitchingLogDGV.Columns[6].HeaderText = "Cycles"; $LegacyGUIelements.SwitchingLogDGV.Columns[6].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIelements.SwitchingLogDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"
            $LegacyGUIelements.SwitchingLogDGV.Columns[7].FillWeight = 35; $LegacyGUIelements.SwitchingLogDGV.Columns[7].DefaultCellStyle.Alignment = "MiddleRight"; $LegacyGUIelements.SwitchingLogDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"
            $LegacyGUIelements.SwitchingLogDGV.Columns[8].FillWeight = 30 + ($LegacyGUIelements.SwitchingLogDGV.MinersBest_Combo.ForEach({ $_.DeviceNames.Count }) | Measure-Object -Maximum).Maximum * 15; $LegacyGUIelements.SwitchingLogDGV.Columns[8].HeaderText = "Device(s)"
            $LegacyGUIelements.SwitchingLogDGV.Columns[9].FillWeight = 30
            $LegacyGUIelements.SwitchingLogDGV.Columns[10].Visible = $false

            $LegacyGUIelements.SwitchingLogClearButton.Enabled = $true

            $LegacyGUIelements.SwitchingLogDGV | Add-Member ColumnWidthChanged $true -Force
        }
        if ($Session.Config.UseColorForMinerStatus) { 
            foreach ($Row in $LegacyGUIelements.SwitchingLogDGV.Rows) { 
                $Row.DefaultCellStyle.Backcolor = $LegacyGUIelements.Colors[$Row.DataBoundItem.Action]
            }
        }
        $LegacyGUIelements.SwitchingLogDGV.EndInit()
    }
    else { 
        $LegacyGUIelements.SwitchingLogLabel.Text = "Waiting for switching log information..."
        $LegacyGUIelements.SwitchingLogClearButton.Enabled = $false
    }
    Remove-Variable SwitchingLogDisplayTypes
    $LegacyGUIelements.SwitchingLogDGV.ClearSelection()
    $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
}

function Set-DataGridViewDoubleBuffer { 

    param (
        [Parameter (Mandatory = $true)]
        [System.Windows.Forms.DataGridView]$Grid,
        [Parameter (Mandatory = $true)]
        [Boolean]$Enabled
    )

    $Type = $Grid.GetType();
    $PropInfo = $Type.GetProperty("DoubleBuffered", ("Instance", "NonPublic"))
    $PropInfo.SetValue($Grid, $Enabled, $null)
}
function Out-DataTable { 
    # based on http://thepowershellguy.com/blogs/posh/archive/2007/01/21/powershell-gui-scripblock-monitor-script.aspx

    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject[]]$InputObject
    )

    begin { 
        $DataTable = [Data.DataTable]::new()
        $First = $true
    }
    process { 
        foreach ($Object in $InputObject) { 
            $DataRow = $DataTable.NewRow()
            foreach ($Property in $Object.PSObject.Properties) { 
                if ($First) { 
                    $Col = [Data.DataColumn]::new()
                    $Col.ColumnName = $Property.Name.ToString()
                    $DataTable.Columns.Add($Col)
                }
                $DataRow.Item($Property.Name) = $Property.Value
            }
            $DataTable.Rows.Add($DataRow)
            $First = $false
        }
    }
    end { 
        return @(, $DataTable)
    }
}

function Set-TableColor { 

    param (
        [Parameter (Mandatory = $true)]
        $DataGridView
    )
    if ($Session.Config.UseColorForMinerStatus) { 
        foreach ($Row in $DataGridView.Rows) { 
            if ($LegacyGUIelements.Colors[$Row.DataBoundItem.SubStatus]) { 
                $Row.DefaultCellStyle.Backcolor = $LegacyGUIelements.Colors[$Row.DataBoundItem.SubStatus]
            }
        }
    }
}

# function Set-WorkerColor { 
#     if ($Session.Config.UseColorForMinerStatus) { 
#         foreach($Row in $LegacyGUIelements.WorkersDGV.Rows) { 
#             $Row.DefaultCellStyle.Backcolor = Switch ($Row.DataBoundItem.Status) { 
#                 "Offline" { $LegacyGUIelements.Colors["disabled"]; Break }
#                 "Paused"  { $LegacyGUIelements.Colors["idle"]; Break }
#                 "Running" { $LegacyGUIelements.Colors["running"]; Break }
#                 Default   { [System.Drawing.Color]::FromArgb(255, 255, 255, 255) }
#             }
#         }
#     }
# }

function Update-TabControl { 

    if (-not $LegacyGUIform.ShowInTaskbar) { return }

    Resize-Form

    switch ($LegacyGUIelements.TabControl.SelectedTab.Name) { 
        "SystemStatus" { 
            $LegacyGUIelements.ActiveMinersDGV.ClearSelection()

            $LegacyGUIelements.ContextMenuStripItem1.Enabled = $true
            $LegacyGUIelements.ContextMenuStripItem1.Text = "Re-benchmark miner"
            $LegacyGUIelements.ContextMenuStripItem1.Visible = $true
            $LegacyGUIelements.ContextMenuStripItem2.Enabled = $Session.Config.CalculatePowerCost
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
            $LegacyGUIelements.ContextMenuStripItem7.Visible = $false

            if ($Session.NewMiningStatus -eq "Idle") { 
                $LegacyGUIelements.ActiveMinersLabel.Text = "No miners running - mining is stopped"
                $LegacyGUIelements.ActiveMinersDGV.DataSource = $null
                $LegacyGUIelements.ActiveMinersDGV | Add-Member ColumnWidthChanged $false -Force
            }
            elseif ($Session.NewMiningStatus -eq "Paused") { 
                $LegacyGUIelements.ActiveMinersLabel.Text = "No miners running - mining is paused"
                $LegacyGUIelements.ActiveMinersDGV.DataSource = $null
                $LegacyGUIelements.ActiveMinersDGV | Add-Member ColumnWidthChanged $false -Force
            }
            elseif ($Session.NewMiningStatus -eq "Running" -and $Session.MiningStatus -eq "Running" -and $Global:CoreCycleRunspace.Job.IsCompleted -eq $true) { 
                $LegacyGUIelements.ActiveMinersLabel.Text = "No miners - mining is suspended"
                $LegacyGUIelements.ActiveMinersDGV.DataSource = $null
                $LegacyGUIelements.ActiveMinersDGV | Add-Member ColumnWidthChanged $false -Force
            }
            elseif ($Session.MinersBest) { 
                if (-not $LegacyGUIelements.ActiveMinersDGV.SelectedRows) { 
                    $LegacyGUIelements.ActiveMinersDGV.BeginInit()
                    $LegacyGUIelements.ActiveMinersDGV.DataSource = $Session.MinersBest.PsObject.Copy().ForEach({ if ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object @(
                        @{ Name = "Info"; Expression = { $_.Info } }
                        @{ Name = "SubStatus"; Expression = { $_.SubStatus } }
                        @{ Name = "Device(s)"; Expression = { $_.BaseName_Version_Device -replace ".+-" } }
                        @{ Name = "Status Info"; Expression = { $_.StatusInfo } }
                        @{ Name = "Earnings (biased) $($Session.Config.FIATcurrency)/day"; Expression = { if ([Double]::IsNaN($_.Earnings)) { "n/a" } else { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Earnings * $Session.Rates.BTC.($Session.Config.FIATcurrency)) } } }
                        @{ Name = "Power cost $($Session.Config.FIATcurrency)/day"; Expression = { if ([Double]::IsNaN($_.PowerCost) -or -not $Session.CalculatePowerCost) { "n/a" } else { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Powercost * $Session.Rates.BTC.($Session.Config.FIATcurrency)) } } }
                        @{ Name = "Profit (biased) $($Session.Config.FIATcurrency)/day"; Expression = { if ([Double]::IsNaN($_.PowerCost) -or -not $Session.CalculatePowerCost) { "n/a" } else { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Profit * $Session.Rates.BTC.($Session.Config.FIATcurrency)) } } }
                        @{ Name = "Power consumption (live)"; Expression = { if ($_.MeasurePowerConsumption) { if ($_.Status -eq "Running") { "Measuring..." } else { "Unmeasured" } } else { if ([Double]::IsNaN($_.PowerConsumption_Live)) { "n/a" } else { "$($_.PowerConsumption_Live.ToString("N2")) W" } } } }
                        @{ Name = "Algorithm(variant) [Currency]"; Expression = { $_.Workers.ForEach({ "$($_.Pool.AlgorithmVariant)$(if ($_.Pool.Currency) { " [$($_.Pool.Currency)]" })" }) -join " & " } },
                        @{ Name = "Pool"; Expression = { $_.Workers.Pool.Name -join " & " } }
                        @{ Name = "Hashrate (live)"; Expression = { if ($_.Benchmark) { if ($_.Status -eq "Running") { "Benchmarking..." } else { "Benchmark pending" } } else { $_.Workers.ForEach({ $_.Hashrates_Live | ConvertTo-Hash }) -join " & " } } }
                        @{ Name = "Running time (hhh:mm:ss)"; Expression = { "{0}:{1:mm}:{1:ss}" -f [Math]::floor(([DateTime]::Now.ToUniversalTime() - $_.BeginTime).TotalDays * 24), ([DateTime]::Now.ToUniversalTime() - $_.BeginTime) } }
                        # @{ Name = "Total active (hhh:mm:ss)"; Expression = { "{0}:{1:mm}:{1:ss}" -f [Math]::floor($_.TotalMiningDuration.TotalDays * 24), $_.TotalMiningDuration } }
                    ) | Out-DataTable
                    $LegacyGUIelements.ActiveMinersDGV.Sort($LegacyGUIelements.ActiveMinersDGV.Columns[2], [System.ComponentModel.ListSortDirection]::Ascending)
                    $LegacyGUIelements.ActiveMinersLabel.Text = "Active miners updated $($Session.MinersUpdatedTimestamp.ToLocalTime().ToString("G")) ($($LegacyGUIelements.ActiveMinersDGV.Rows.count) miner$(if ($LegacyGUIelements.ActiveMinersDGV.Rows.count -ne 1) { "s" }))"

                    $LegacyGUIelements.ActiveMinersDGV.Columns[0].Visible = $false
                    $LegacyGUIelements.ActiveMinersDGV.Columns[1].Visible = $false
                    if ($LegacyGUIelements.ActiveMinersDGV.Columns -and -not $LegacyGUIelements.ActiveMinersDGV.ColumnWidthChanged) { 
                        $LegacyGUIelements.ActiveMinersDGV.Columns[2].FillWeight = 45 + ($Session.MinersBest.ForEach({ $_.DeviceNames.Count }) | Measure-Object -Maximum).Maximum * 20
                        $LegacyGUIelements.ActiveMinersDGV.Columns[3].FillWeight = 190
                        $LegacyGUIelements.ActiveMinersDGV.Columns[4].FillWeight = 52; $LegacyGUIelements.ActiveMinersDGV.Columns[4].DefaultCellStyle.Alignment = $LegacyGUIelements.ActiveMinersDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.ActiveMinersDGV.Columns[5].FillWeight = 52; $LegacyGUIelements.ActiveMinersDGV.Columns[5].DefaultCellStyle.Alignment = $LegacyGUIelements.ActiveMinersDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.ActiveMinersDGV.Columns[5].Visible = $Session.CalculatePowerCost
                        $LegacyGUIelements.ActiveMinersDGV.Columns[6].FillWeight = 52; $LegacyGUIelements.ActiveMinersDGV.Columns[6].DefaultCellStyle.Alignment = $LegacyGUIelements.ActiveMinersDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.ActiveMinersDGV.Columns[6].Visible = $Session.CalculatePowerCost
                        $LegacyGUIelements.ActiveMinersDGV.Columns[7].FillWeight = 52; $LegacyGUIelements.ActiveMinersDGV.Columns[7].DefaultCellStyle.Alignment = $LegacyGUIelements.ActiveMinersDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.ActiveMinersDGV.Columns[7].Visible = $Session.CalculatePowerCost
                        $LegacyGUIelements.ActiveMinersDGV.Columns[8].FillWeight = 60 + ($Session.MinersBest.ForEach({ $_.Workers.Count }) | Measure-Object -Maximum).Maximum * 30
                        $LegacyGUIelements.ActiveMinersDGV.Columns[9].FillWeight = 45 + ($Session.MinersBest.ForEach({ $_.Workers.Count }) | Measure-Object -Maximum).Maximum * 25
                        $LegacyGUIelements.ActiveMinersDGV.Columns[10].FillWeight = 45 + ($Session.MinersBest.ForEach({ $_.Workers.Count }) | Measure-Object -Maximum).Maximum * 25; $LegacyGUIelements.ActiveMinersDGV.Columns[10].DefaultCellStyle.Alignment = $LegacyGUIelements.ActiveMinersDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.ActiveMinersDGV.Columns[11].FillWeight = 50; $LegacyGUIelements.ActiveMinersDGV.Columns[11].DefaultCellStyle.Alignment = $LegacyGUIelements.ActiveMinersDGV.Columns[11].HeaderCell.Style.Alignment = "MiddleRight"
                        # $LegacyGUIelements.ActiveMinersDGV.Columns[12].FillWeight = 50; $LegacyGUIelements.ActiveMinersDGV.Columns[12].DefaultCellStyle.Alignment = $LegacyGUIelements.ActiveMinersDGV.Columns[12].HeaderCell.Style.Alignment = "MiddleRight"

                        $LegacyGUIelements.ActiveMinersDGV | Add-Member ColumnWidthChanged $true -Force
                    }
                    $LegacyGUIelements.ActiveMinersDGV.EndInit()
                }
            }
            else { 
                $LegacyGUIelements.ActiveMinersLabel.Text = "Waiting for active miner information..."
                $LegacyGUIelements.ActiveMinersDGV.DataSource = $null
            }
            break
        }
        "EarningsAndBalances" { 

            function Get-NextColor { 
                param (
                    [Parameter (Mandatory = $true)]
                    [Byte[]]$Color,
                    [Parameter (Mandatory = $true)]
                    [Int[]]$Factors
                )

                # Apply change Factor
                (0..($Color.Count - 1)).ForEach({ $Color[$_] = [Math]::Abs(($Color[$_] + $Factors[$_]) % 192) })
                $Color
            }

            if ($Session.Config.BalancesTrackerPollInterval -gt 0) { 
                if ($Datasource = [System.IO.File]::ReadAllLines("$PWD\Cache\EarningsChartData.json") | ConvertFrom-Json -ErrorAction Ignore) { 
                    try { 
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
                        $ChartArea.AxisX.IsMarginVisible = $false
                        $ChartArea.AxisX.LabelStyle.Enabled = $true
                        $ChartArea.AxisX.MajorGrid.Enabled = $false
                        $ChartArea.AxisX.Maximum = $Datasource.Labels.Count + 1
                        $ChartArea.AxisX.Minimum = 0
                        $ChartArea.AxisY.Interval = [Math]::Ceiling(($Datasource.DaySum | Measure-Object -Maximum).Maximum / 4)
                        $ChartArea.AxisY.LabelAutoFitStyle = $ChartArea.AxisY.labelAutoFitStyle - 4
                        $ChartArea.AxisY.MajorGrid.Enabled = $true
                        $ChartArea.AxisY.MajorGrid.LineColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255) #"#FFFFFF"
                        $ChartArea.AxisY.Title = $Session.Config.FIATcurrency
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
                        foreach ($Pool in $DataSource.Earnings.PSObject.Properties.Name) { 

                            $Color = (Get-NextColor -Color $Color -Factors -0, -20, -20, -20)

                            $LegacyGUIelements.EarningsChart.Series.Add($Pool)
                            $LegacyGUIelements.EarningsChart.Series[$Pool].ChartType = "StackedColumn"
                            $LegacyGUIelements.EarningsChart.Series[$Pool].BorderWidth = 3
                            $LegacyGUIelements.EarningsChart.Series[$Pool].Color = [System.Drawing.Color]::FromArgb($Color[0], $Color[1], $Color[2], $Color[3])

                            $I = 0
                            $Datasource.Earnings.$Pool.ForEach(
                                { 
                                    $_ *= $Session.Rates.BTC.($Session.Config.FIATcurrency)
                                    $null = $LegacyGUIelements.EarningsChart.Series[$Pool].Points.addxy(0, $_)
                                    $Daysum[$I] += $_
                                    if ($_) { $LegacyGUIelements.TooltipText[$I] = "$($LegacyGUIelements.TooltipText[$I])`r$($Pool): {0:N$($Session.Config.DecimalsMax)} $($Session.Config.FIATcurrency)" -f $_ }
                                    $I ++
                                }
                            )
                        }

                        $I = 0
                        $DataSource.Labels.ForEach(
                            { 
                                $ChartArea.AxisX.CustomLabels.Add($I + 0.5, $I + 1.5, " $_ ")
                                $ChartArea.AxisX.CustomLabels[$I].ToolTip = "$($LegacyGUIelements.TooltipText[$I])`rTotal: {0:N$($Session.Config.DecimalsMax)} $($Session.Config.FIATcurrency)" -f $Daysum[$I]
                                foreach ($Pool in $DataSource.Earnings.PSObject.Properties.Name) { 
                                    if ($Datasource.Earnings.$Pool[$I]) { $LegacyGUIelements.EarningsChart.Series[$Pool].Points[$I].ToolTip = "$($LegacyGUIelements.TooltipText[$I])`rTotal: {0:N$($Session.Config.DecimalsMax)} $($Session.Config.FIATcurrency)" -f $Daysum[$I] }
                                }
                                $I ++
                            }
                        )
                        $ChartArea.AxisY.Maximum = ($DaySum | Measure-Object -Maximum).Maximum * 1.05

                        Remove-Variable ChartArea, ChartTitle, Color, DaySum, I, Pool
                    }
                    catch { }
                }

                $DataSource = $Session.Balances.Values
                if ($Session.Balances.Values.LastUpdated) { 
                    $LegacyGUIelements.BalancesLabel.Text = "Balances updated $(($Session.Balances.Values.LastUpdated | Sort-Object -Bottom 1).ToLocalTime().ToString())"

                    $LegacyGUIelements.BalancesDGV.BeginInit()
                    $LegacyGUIelements.BalancesDGV.DataSource = $DataSource | Select-Object @(
                        @{ Name = "Currency"; Expression = { $_.Currency } },
                        @{ Name = "Pool [Currency]"; Expression = { "$($_.Pool) [$($_.Currency)]" } },
                        @{ Name = "Balance ($($Session.Config.FIATcurrency))"; Expression = { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Balance * $Session.Rates.($_.Currency).($Session.Config.FIATcurrency)) } },
                        @{ Name = "$($Session.Config.FIATcurrency) in past 1 hr"; Expression = { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Growth1 * $Session.Rates.($_.Currency).($Session.Config.FIATcurrency)) } },
                        @{ Name = "$($Session.Config.FIATcurrency) in past 6 hrs"; Expression = { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Growth6 * $Session.Rates.($_.Currency).($Session.Config.FIATcurrency)) } },
                        @{ Name = "$($Session.Config.FIATcurrency) in past 24 hrs"; Expression = { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Growth24 * $Session.Rates.($_.Currency).($Session.Config.FIATcurrency)) } },
                        @{ Name = "$($Session.Config.FIATcurrency) in past 7 days"; Expression = { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Growth168 * $Session.Rates.($_.Currency).($Session.Config.FIATcurrency)) } },
                        @{ Name = "$($Session.Config.FIATcurrency) in past 30 days"; Expression = { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Growth720 * $Session.Rates.($_.Currency).($Session.Config.FIATcurrency)) } },
                        @{ Name = "Avg. $($Session.Config.FIATcurrency) / 1 hr"; Expression = { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.AvgHourlyGrowth * $Session.Rates.($_.Currency).($Session.Config.FIATcurrency)) } },
                        @{ Name = "Avg. $($Session.Config.FIATcurrency) / 24 hrs"; Expression = { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.AvgDailyGrowth * $Session.Rates.($_.Currency).($Session.Config.FIATcurrency)) } },
                        @{ Name = "Avg. $($Session.Config.FIATcurrency) / 7 days"; Expression = { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.AvgWeeklyGrowth * $Session.Rates.($_.Currency).($Session.Config.FIATcurrency)) } },
                        @{ Name = "Projected pay date"; Expression = { if ($_.ProjectedPayDate -is [DateTime]) { $_.ProjectedPayDate.ToShortDateString() } else { $_.ProjectedPayDate } } },
                        @{ Name = "Payout threshold"; Expression = { if ($_.PayoutThresholdCurrency -eq "BTC" -and $Session.Config.UsemBTC) { $PayoutThresholdCurrency = "mBTC"; $mBTCfactor = 1000 } else { $PayoutThresholdCurrency = $_.PayoutThresholdCurrency; $mBTCfactor = 1 }; "{0:P2} of {1} {2} " -f ($_.Balance / $_.PayoutThreshold * $Session.Rates.($_.Currency).($_.PayoutThresholdCurrency)), [String](("{0:N$(Get-DecimalsFromValue ($_.PayoutThreshold * $mBTCfactor) $Session.Config.DecimalsMax)}" -f [float]($_.PayoutThreshold * $mBTCfactor)) -replace "0*$" -replace "\.$") <# Cast to string to avoid extra decimal places #>, $PayoutThresholdCurrency } }
                    ) | Out-DataTable

                    $LegacyGUIelements.BalancesDGV.Sort($LegacyGUIelements.BalancesDGV.Columns[1], [System.ComponentModel.ListSortDirection]::Ascending)

                    if ($LegacyGUIelements.BalancesDGV.Columns -and -not $LegacyGUIelements.BalancesDGV.ColumnWidthChanged) { 
                        $LegacyGUIelements.BalancesDGV.Columns[0].Visible = $false
                        $LegacyGUIelements.BalancesDGV.Columns[1].FillWeight = 100
                        $LegacyGUIelements.BalancesDGV.Columns[2].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[2].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[2].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.BalancesDGV.Columns[3].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[3].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[3].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.BalancesDGV.Columns[3].Visible = $Session.Config.BalancesShowSums
                        $LegacyGUIelements.BalancesDGV.Columns[4].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[4].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.BalancesDGV.Columns[4].Visible = $Session.Config.BalancesShowSums
                        $LegacyGUIelements.BalancesDGV.Columns[5].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[5].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.BalancesDGV.Columns[5].Visible = $Session.Config.BalancesShowSums
                        $LegacyGUIelements.BalancesDGV.Columns[6].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[6].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.BalancesDGV.Columns[6].Visible = $Session.Config.BalancesShowSums
                        $LegacyGUIelements.BalancesDGV.Columns[7].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[7].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.BalancesDGV.Columns[7].Visible = $Session.Config.BalancesShowSums
                        $LegacyGUIelements.BalancesDGV.Columns[8].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[8].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[8].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.BalancesDGV.Columns[8].Visible = $Session.Config.BalancesShowAverages
                        $LegacyGUIelements.BalancesDGV.Columns[9].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[9].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[9].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.BalancesDGV.Columns[9].Visible = $Session.Config.BalancesShowAverages
                        $LegacyGUIelements.BalancesDGV.Columns[10].FillWeight = 70; $LegacyGUIelements.BalancesDGV.Columns[10].DefaultCellStyle.Alignment = $LegacyGUIelements.BalancesDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.BalancesDGV.Columns[10].Visible = $Session.Config.BalancesShowAverages
                        $LegacyGUIelements.BalancesDGV.Columns[11].FillWeight = 70
                        $LegacyGUIelements.BalancesDGV.Columns[12].FillWeight = 100

                        $LegacyGUIelements.BalancesDGV | Add-Member ColumnWidthChanged $true -Force
                    }
                    $LegacyGUIelements.BalancesDGV.Rows.ForEach(
                        { 
                            $_.Cells[2].ToolTipText = "Balance {0:n$($Session.Config.DecimalsMax)} $(if ($_.Cells[0].Value -eq "BTC" -and $Session.Config.UsemBTC) { $Factor = 1000; "mBTC" } else { $Factor = 1; $($_.Cells[0].Value) })" -f ([Double]$_.Cells[2].Value * $Session.Rates.($Session.Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                            $_.Cells[3].ToolTipText = "{0:n$($Session.Config.DecimalsMax)} $(if ($_.Cells[0].Value -eq "BTC" -and $Session.Config.UsemBTC) { $Factor = 1000; "mBTC" } else { $Factor = 1; $($_.Cells[0].Value) }) in past 1 hr" -f ([Double]$_.Cells[3].Value * $Session.Rates.($Session.Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                            $_.Cells[4].ToolTipText = "{0:n$($Session.Config.DecimalsMax)} $(if ($_.Cells[0].Value -eq "BTC" -and $Session.Config.UsemBTC) { $Factor = 1000; "mBTC" } else { $Factor = 1; $($_.Cells[0].Value) }) in past 6 hr" -f ([Double]$_.Cells[4].Value * $Session.Rates.($Session.Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                            $_.Cells[5].ToolTipText = "{0:n$($Session.Config.DecimalsMax)} $(if ($_.Cells[0].Value -eq "BTC" -and $Session.Config.UsemBTC) { $Factor = 1000; "mBTC" } else { $Factor = 1; $($_.Cells[0].Value) }) in past 24 hr" -f ([Double]$_.Cells[5].Value * $Session.Rates.($Session.Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                            $_.Cells[6].ToolTipText = "{0:n$($Session.Config.DecimalsMax)} $(if ($_.Cells[0].Value -eq "BTC" -and $Session.Config.UsemBTC) { $Factor = 1000; "mBTC" } else { $Factor = 1; $($_.Cells[0].Value) }) in past 7 days" -f ([Double]$_.Cells[6].Value * $Session.Rates.($Session.Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                            $_.Cells[7].ToolTipText = "{0:n$($Session.Config.DecimalsMax)} $(if ($_.Cells[0].Value -eq "BTC" -and $Session.Config.UsemBTC) { $Factor = 1000; "mBTC" } else { $Factor = 1; $($_.Cells[0].Value) }) in past 30 days" -f ([Double]$_.Cells[7].Value * $Session.Rates.($Session.Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                            $_.Cells[8].ToolTipText = "Avg. {0:n$($Session.Config.DecimalsMax)} $(if ($_.Cells[0].Value -eq "BTC" -and $Session.Config.UsemBTC) { $Factor = 1000; "mBTC" } else { $Factor = 1; $($_.Cells[0].Value) }) / 1 hr" -f ([Double]$_.Cells[8].Value * $Session.Rates.($Session.Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                            $_.Cells[9].ToolTipText = "Avg. {0:n$($Session.Config.DecimalsMax)} $(if ($_.Cells[0].Value -eq "BTC" -and $Session.Config.UsemBTC) { $Factor = 1000; "mBTC" } else { $Factor = 1; $($_.Cells[0].Value) }) / 24 hrs" -f ([Double]$_.Cells[9].Value * $Session.Rates.($Session.Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                            $_.Cells[10].ToolTipText = "Avg. {0:n$($Session.Config.DecimalsMax)} $(if ($_.Cells[0].Value -eq "BTC" -and $Session.Config.UsemBTC) { $Factor = 1000; "mBTC" } else { $Factor = 1; $($_.Cells[0].Value) }) / 7 days" -f ([Double]$_.Cells[10].Value * $Session.Rates.($Session.Config.FIATcurrency).($_.Cells[0].Value) * $Factor)
                        }
                    )
                    $LegacyGUIelements.BalancesDGV.EndInit()
                }
                else { 
                    $LegacyGUIelements.BalancesLabel.Text = "Balances tracker is running - waiting for balances information..."
                }
                Remove-Variable DataSource
            }
            else { 
                $LegacyGUIelements.BalancesLabel.Text = "Balances tracker is disabled (configuration item 'BalancesTrackerPollInterval' -eq 0)"
                $LegacyGUIelements.BalancesLabel.DataSource = $null
            }
            break
        }
        "Miners" { 
            $LegacyGUIelements.MinersDGV.ClearSelection()

            $LegacyGUIelements.ContextMenuStripItem1.Enabled = $true
            $LegacyGUIelements.ContextMenuStripItem1.Text = "Re-benchmark miner"
            $LegacyGUIelements.ContextMenuStripItem1.Visible = $true
            $LegacyGUIelements.ContextMenuStripItem2.Enabled = $Session.Config.CalculatePowerCost
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
            $LegacyGUIelements.ContextMenuStripItem7.Text = "Copy miner command line to clipboard"
            $LegacyGUIelements.ContextMenuStripItem7.Visible = $false

            if ($LegacyGUIelements.RadioButtonMinersOptimal.checked) { 
                if ($Session.MinersOptimal) { 
                    $Bias = if ($Session.CalculatePowerCost -and -not $Session.Config.IgnorePowerCost) { "Profit_Bias" } else { "Earnings_Bias" }
                    $DataSource = $Session.MinersOptimal.PsObject.Copy().ForEach({ if ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, { $_.BaseName_Version_Device -replace ".+-" }, @{ Expression = $Bias; Descending = $true }
                    Remove-Variable Bias
                }
            }
            elseif ($LegacyGUIelements.RadioButtonMinersUnavailable.checked) { 
                $DataSource = $Session.Miners.Where({ $_.Available -ne $true }).PsObject.Copy().ForEach({ if ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Sort-Object { $_.BaseName_Version_Device -replace ".+-" }, Info, Algorithm
            }
            else { 
                if ($Session.Miners) {
                    $Bias = if ($Session.CalculatePowerCost -and -not $Session.Config.IgnorePowerCost) { "Profit_Bias" } else { "Earnings_Bias" }
                    $DataSource = $Session.Miners.PsObject.Copy().ForEach({ if ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, { $_.BaseName_Version_Device -replace ".+-" }, @{ Expression = $Bias; Descending = $true }
                    Remove-Variable Bias
                }
            }

            if ($Session.MiningStatus -eq "Idle") { 
                $LegacyGUIelements.MinersLabel.Text = "No miners - mining is stopped"
                $LegacyGUIelements.MinersDGV.DataSource = $null
                $LegacyGUIelements.MinersDGV | Add-Member ColumnWidthChanged $false -Force
            }
            elseif ($Session.MiningStatus -eq "Paused") { 
                $LegacyGUIelements.MinersLabel.Text = "No miners - mining is paused"
                $LegacyGUIelements.MinersDGV.DataSource = $null
                $LegacyGUIelements.MinersDGV | Add-Member ColumnWidthChanged $false -Force
            }
            elseif ($Session.MiningStatus -eq "Running" -and -not $Global:CoreCycleRunspace) { 
                $LegacyGUIelements.MinersLabel.Text = "No miners - mining is suspended"
                $LegacyGUIelements.MinersDGV.DataSource = $null
                $LegacyGUIelements.MinersDGV | Add-Member ColumnWidthChanged $false -Force
            }
            elseif ($Session.Miners) { 
                if (-not $LegacyGUIelements.MinersDGV.SelectedRows) { 
                    $LegacyGUIelements.MinersDGV.BeginInit()
                    $LegacyGUIelements.MinersDGV.DataSource = $DataSource | Select-Object @(
                        @{ Name = "Info"; Expression = { $_.Info } }
                        @{ Name = "SubStatus"; Expression = { $_.SubStatus } },
                        @{ Name = "Miner"; Expression = { $_.Name } },
                        @{ Name = "Device(s)"; Expression = { $_.BaseName_Version_Device -replace ".+-" } },
                        @{ Name = "Status"; Expression = { $_.Status } },
                        @{ Name = "Earnings (biased) $($Session.Config.FIATcurrency)/day"; Expression = { if ([Double]::IsNaN($_.Earnings_Bias)) { "n/a" } else { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Earnings * $Session.Rates.BTC.($Session.Config.FIATcurrency)) } } },
                        @{ Name = "Power cost $($Session.Config.FIATcurrency)/day"; Expression = { if ([Double]::IsNaN($_.PowerCost)) { "n/a" } else { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Powercost * $Session.Rates.BTC.($Session.Config.FIATcurrency)) } } },
                        @{ Name = "Profit (biased) $($Session.Config.FIATcurrency)/day"; Expression = { if ([Double]::IsNaN($_.Profit_Bias) -or -not $Session.CalculatePowerCost) { "n/a" } else { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Profit * $Session.Rates.BTC.($Session.Config.FIATcurrency)) } } },
                        @{ Name = "Power consumption"; Expression = { if ($_.MeasurePowerConsumption) { if ($_.Status -eq "Running") { "Measuring..." } else { "Unmeasured" } } else { if ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } else { "$($_.PowerConsumption.ToString("N2")) W" } } } }
                        @{ Name = "Algorithm(variant) [Currency]"; Expression = { $_.Workers.ForEach({ "$($_.Pool.AlgorithmVariant)$(if ($_.Pool.Currency) { " [$($_.Pool.Currency)]" })" }) -join " & " } },
                        @{ Name = "Pool"; Expression = { $_.Workers.Pool.Name -join " & " } },
                        @{ Name = "Hashrate"; Expression = { if ($_.Benchmark) { if ($_.Status -eq "Running") { "Benchmarking..." } else { "Benchmark pending" } } else { $_.Workers.ForEach({ $_.Hashrate | ConvertTo-Hash }) -join " & " } } }
                        if ($LegacyGUIelements.RadioButtonMinersUnavailable.checked -or $LegacyGUIelements.RadioButtonMiners.checked) { @{ Name = "Reason(s)"; Expression = { $_.Reasons -join ", " } } }
                    ) | Out-DataTable
                    $LegacyGUIelements.MinersLabel.Text = "Miner information updated $($Session.MinersUpdatedTimestamp.ToLocalTime().ToString("G")) ($($LegacyGUIelements.MinersDGV.Rows.count) miner$(if ($LegacyGUIelements.MinersDGV.Rows.count -ne 1) { "s" }))"
                    if ($LegacyGUIelements.MinersDGV.Columns -and -not $LegacyGUIelements.MinersDGV.ColumnWidthChanged) { 
                        $LegacyGUIelements.MinersDGV.Columns[0].Visible = $false
                        $LegacyGUIelements.MinersDGV.Columns[1].Visible = $false
                        $LegacyGUIelements.MinersDGV.Columns[2].FillWeight = 160
                        $LegacyGUIelements.MinersDGV.Columns[3].FillWeight = 35 + ($DataSource.ForEach({ $_.DeviceNames.Count }) | Measure-Object -Maximum).Maximum * 15
                        $LegacyGUIelements.MinersDGV.Columns[4].FillWeight = 35; $LegacyGUIelements.MinersDGV.Columns[4].Visible = -not $LegacyGUIelements.RadioButtonMinersUnavailable.checked
                        $LegacyGUIelements.MinersDGV.Columns[5].FillWeight = 40; $LegacyGUIelements.MinersDGV.Columns[5].DefaultCellStyle.Alignment = $LegacyGUIelements.MinersDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.MinersDGV.Columns[6].FillWeight = 40; $LegacyGUIelements.MinersDGV.Columns[6].DefaultCellStyle.Alignment = $LegacyGUIelements.MinersDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.MinersDGV.Columns[6].Visible = $Session.CalculatePowerCost
                        $LegacyGUIelements.MinersDGV.Columns[7].FillWeight = 40; $LegacyGUIelements.MinersDGV.Columns[7].DefaultCellStyle.Alignment = $LegacyGUIelements.MinersDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.MinersDGV.Columns[7].Visible = $Session.CalculatePowerCost
                        $LegacyGUIelements.MinersDGV.Columns[8].FillWeight = 40; $LegacyGUIelements.MinersDGV.Columns[8].DefaultCellStyle.Alignment = $LegacyGUIelements.MinersDGV.Columns[8].HeaderCell.Style.Alignment = "MiddleRight"; $LegacyGUIelements.MinersDGV.Columns[8].Visible = $Session.CalculatePowerCost
                        $LegacyGUIelements.MinersDGV.Columns[9].FillWeight = if ($LegacyGUIelements.MinersDGV.DataSource.Pool -like "* & ") { 90 } else { 60 }
                        $LegacyGUIelements.MinersDGV.Columns[10].FillWeight = if ($LegacyGUIelements.MinersDGV.DataSource.Pool -like "* & ") { 85 } else { 60 }
                        $LegacyGUIelements.MinersDGV.Columns[11].FillWeight = if ($LegacyGUIelements.MinersDGV.DataSource.Pool -like "* & ") { 80 } else { 50 }; $LegacyGUIelements.MinersDGV.Columns[11].DefaultCellStyle.Alignment = $LegacyGUIelements.MinersDGV.Columns[11].HeaderCell.Style.Alignment = "MiddleRight"

                        $LegacyGUIelements.MinersDGV | Add-Member ColumnWidthChanged $true -Force
                    }
                    Set-TableColor -DataGridView $LegacyGUIelements.MinersDGV
                    $LegacyGUIelements.MinersDGV.ClearSelection()
                    $LegacyGUIelements.MinersDGV.EndInit()
                }
            }
            else { 
                $LegacyGUIelements.MinersLabel.Text = "Waiting for miner information..."
                $LegacyGUIelements.MinersDGV.DataSource = $null
            }

            Remove-Variable DataSource -ErrorAction Ignore
            break
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
            $LegacyGUIelements.ContextMenuStripItem7.Visible = $false

            if ($LegacyGUIelements.RadioButtonPoolsBest.checked) { $DataSource = $Session.PoolsBest }
            elseif ($LegacyGUIelements.RadioButtonPoolsUnavailable.checked) { $DataSource = $Session.Pools.Where({ -not $_.Available }) }
            else { $DataSource = $Session.Pools }

            if ($Session.NewMiningStatus -eq "Idle") { 
                $LegacyGUIelements.PoolsLabel.Text = "No pools - mining is stopped"
                $LegacyGUIelements.PoolsDGV.DataSource = $null
                $LegacyGUIelements.PoolsDGV | Add-Member ColumnWidthChanged $false -Force
            }
            elseif ($Session.NewMiningStatus -eq "Paused") { 
                $LegacyGUIelements.PoolsLabel.Text = "No pools - mining is paused"
                $LegacyGUIelements.PoolsDGV.DataSource = $null
                $LegacyGUIelements.PoolsDGV | Add-Member ColumnWidthChanged $false -Force
            }
            elseif ($Session.NewMiningStatus -eq "Running" -and $Session.MiningStatus -eq "Running" -and -not $Session.Pools -and $Global:CoreCycleRunspace.Job.IsCompleted -eq $true) { 
                $LegacyGUIelements.PoolsLabel.Text = "No pools - mining is suspended"
                $LegacyGUIelements.PoolsDGV.DataSource = $null
                $LegacyGUIelements.PoolsDGV | Add-Member ColumnWidthChanged $false -Force
            }
            elseif ($Session.Pools) { 
                if (-not $LegacyGUIelements.PoolsDGV.SelectedRows) { 
                    $LegacyGUIelements.PoolsDGV.BeginInit()
                    if ($Session.Config.UsemBTC) { 
                        $Factor = 1000
                        $Unit = "mBTC"
                    }
                    else { 
                        $Factor = 1
                        $Unit = "BTC"
                    }
                    $LegacyGUIelements.PoolsDGV.DataSource = $DataSource | Sort-Object -Property AlgorithmVariant, Currency, Name | Select-Object @(
                        @{ Name = "Algorithm (variant)"; Expression = { $_.AlgorithmVariant } }
                        @{ Name = "Currency"; Expression = { $_.Currency } }
                        @{ Name = "Coin name"; Expression = { $_.CoinName } }
                        @{ Name = "$Unit/GH/Day (biased)"; Expression = { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Price_Bias * [Math]::Pow(1024, 3) * $Factor) } }
                        @{ Name = "Accuracy"; Expression = { "{0:p2}" -f $_.Accuracy } }
                        @{ Name = "Pool name"; Expression = { $_.Name } }
                        @{ Name = "Host"; Expression = { $_.Host } }
                        @{ Name = "Port"; Expression = { "$(if ($_.Port) { $_.Port } else { "-" })" } }
                        @{ Name = "SSL port"; Expression = { "$(if ($_.PortSSL) { $_.PortSSL } else { "-" })" } }
                        @{ Name = "Earnings adjustment factor"; Expression = { $_.EarningsAdjustmentFactor } }
                        @{ Name = "Fee"; Expression = { "{0:p2}" -f $_.Fee } }
                        if ($LegacyGUIelements.RadioButtonPoolsUnavailable.checked -or $LegacyGUIelements.RadioButtonPools.checked) { @{ Name = "Reason(s)"; Expression = { $_.Reasons -join ", " } } }
                    ) | Out-DataTable
                    Remove-Variable Factor, Unit

                    $LegacyGUIelements.PoolsDGV.Sort($LegacyGUIelements.PoolsDGV.Columns[0], [System.ComponentModel.ListSortDirection]::Ascending)
                    $LegacyGUIelements.PoolsDGV.ClearSelection()
                    $LegacyGUIelements.PoolsLabel.Text = "Pool information updated $($Session.PoolsUpdatedTimestamp.ToLocalTime().ToString("G")) ($($LegacyGUIelements.PoolsDGV.Rows.Count) pool$(if ($LegacyGUIelements.PoolsDGV.Rows.count -ne 1) { "s" }))"

                    if ($LegacyGUIelements.PoolsDGV.Columns -and -not $LegacyGUIelements.PoolsDGV.ColumnWidthChanged) { 
                        $LegacyGUIelements.PoolsDGV.Columns[0].FillWeight = 80
                        $LegacyGUIelements.PoolsDGV.Columns[1].FillWeight = 40
                        $LegacyGUIelements.PoolsDGV.Columns[2].FillWeight = 70
                        $LegacyGUIelements.PoolsDGV.Columns[3].FillWeight = 55; $LegacyGUIelements.PoolsDGV.Columns[3].DefaultCellStyle.Alignment = $LegacyGUIelements.PoolsDGV.Columns[3].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.PoolsDGV.Columns[4].FillWeight = 45; $LegacyGUIelements.PoolsDGV.Columns[4].DefaultCellStyle.Alignment = $LegacyGUIelements.PoolsDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.PoolsDGV.Columns[5].FillWeight = 55
                        $LegacyGUIelements.PoolsDGV.Columns[6].FillWeight = 120
                        $LegacyGUIelements.PoolsDGV.Columns[7].FillWeight = 35; $LegacyGUIelements.PoolsDGV.Columns[7].DefaultCellStyle.Alignment = $LegacyGUIelements.PoolsDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.PoolsDGV.Columns[8].FillWeight = 35; $LegacyGUIelements.PoolsDGV.Columns[8].DefaultCellStyle.Alignment = $LegacyGUIelements.PoolsDGV.Columns[8].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.PoolsDGV.Columns[9].FillWeight = 35; $LegacyGUIelements.PoolsDGV.Columns[9].DefaultCellStyle.Alignment = $LegacyGUIelements.PoolsDGV.Columns[9].HeaderCell.Style.Alignment = "MiddleRight"
                        $LegacyGUIelements.PoolsDGV.Columns[10].FillWeight = 35; $LegacyGUIelements.PoolsDGV.Columns[10].DefaultCellStyle.Alignment = $LegacyGUIelements.PoolsDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"
                        if ($LegacyGUIelements.PoolsDGV.Columns[11]) { $LegacyGUIelements.PoolsDGV.Columns[11].FillWeight = 140 }
                        $LegacyGUIelements.PoolsDGV | Add-Member ColumnWidthChanged $true -Force
                    }
                    $LegacyGUIelements.PoolsDGV.EndInit()
                }
            }
            else { 
                $LegacyGUIelements.PoolsLabel.Text = "Waiting for pool information..."
                $LegacyGUIelements.PoolsDGV.DataSource = $null
            }
            Remove-Variable DataSource
            break
        }
        # "RigMonitor" { 
        #     $LegacyGUIelements.WorkersDGV.ClearSelection()
        # 
        #     $LegacyGUIelements.WorkersDGV.Visible = $Session.Config.ShowWorkerStatus
        #     $LegacyGUIelements.EditMonitoringLink.Visible = $Session.APIport
        #
        #     If ($Session.Config.ShowWorkerStatus) { 
        #         If (-not $LegacyGUIelements.WorkersDGV.SelectedRows) { 
        #
        #             Read-MonitoringData
        #
        #             if ($Session.Workers) { $LegacyGUIelements.WorkersLabel.Text = "Worker status updated $($Session.WorkersLastUpdated.ToString())" }
        #             elseif ($Session.MiningStatus -eq "Idle") { 
        #                 $LegacyGUIelements.WorkersLabel.Text = "No workers - mining is stopped"
        #                 $LegacyGUIelements.WorkersDGV.DataSource = $null
        #                 $LegacyGUIelements.WorkersDGV | Add-Member ColumnWidthChanged
        #             }
        #             elseif ($Session.MiningStatus -eq "Paused" -and -not $DataSource) { 
        #                 $LegacyGUIelements.WorkersLabel.Text = "No workers - mining is paused"
        #                 $LegacyGUIelements.WorkersDGV.DataSource = $null
        #                 $LegacyGUIelements.WorkersDGV | Add-Member ColumnWidthChanged
        #             }
        #             elseif ($Session.NewMiningStatus -eq "Running" -and $Session.MiningStatus -eq "Running" -and $Global:CoreCycleRunspace.Job.IsCompleted -eq $true) { 
        #                 $LegacyGUIelements.MinersLabel.Text = "No workers - mining is suspended"
        #                 $LegacyGUIelements.WorkersDGV.DataSource = $null
        #                 $LegacyGUIelements.WorkersDGV | Add-Member ColumnWidthChanged
        #             }
        #             else  { $LegacyGUIelements.WorkersLabel.Text = "Waiting for monitoring information..." }
        #
        #             $LegacyGUIelements.WorkersDGV.BeginInit()
        #             $LegacyGUIelements.WorkersDGV.DataSource = $Session.Workers | Select-Object @(
        #                 @{ Name = "Worker"; Expression = { $_.worker } },
        #                 @{ Name = "Status"; Expression = { $_.status } },
        #                 @{ Name = "Last seen"; Expression = { (Get-TimeSince $_.date) } },
        #                 @{ Name = "Version"; Expression = { $_.version } },
        #                 @{ Name = "Currency"; Expression = { $_.data.Currency | Select-Object -Unique } },
        #                 @{ Name = "Estimated earnings/day"; Expression = { If ($null -ne $_.Data) { "{0:n$($Session.Config.DecimalsMax)}" -f (($_.Data.EarningsWhere({ -not [Double]::IsNaN($_) }) | Measure-Object -Sum).Sum * $Session.Rates.BTC.($_.data.Currency | Select-Object -Unique)) } } },
        #                 @{ Name = "Estimated profit/day"; Expression = { If ($null -ne $_.Data) { " {0:n$($Session.Config.DecimalsMax)}" -f (($_.Data.Profit.Where({ -not [Double]::IsNaN($_) }) | Measure-Object -Sum).Sum * $Session.Rates.BTC.($_.data.Currency | Select-Object -Unique)) } } },
        #                 @{ Name = "Miner"; Expression = { $_.data.Name -join $nl } },
        #                 @{ Name = "Pool"; Expression = { $_.data.ForEach({ $_.Pool -split "," -join " & " }) -join $nl } },
        #                 @{ Name = "Algorithm"; Expression = { $_.data.ForEach({ $_.Algorithm -split "," -join " & " }) -join $nl } },
        #                 @{ Name = "Live hashrate"; Expression = { $_.data.ForEach({ $_.CurrentSpeed.ForEach({ If ([Double]::IsNaN($_)) { "n/a" } else { $_ | ConvertTo-Hash } }) -join " & " }) -join $nl } },
        #                 @{ Name = "Benchmark hashrate(s)"; Expression = { $_.data.ForEach({ $_.Hashrate.ForEach({ If ([Double]::IsNaN($_)) { "n/a" } else { $_ | ConvertTo-Hash } }) -join " & " }) -join $nl } }
        #             ) | Out-DataTable
        #             $LegacyGUIelements.WorkersDGV.Sort($LegacyGUIelements.WorkersDGV.Columns[0], [System.ComponentModel.ListSortDirection]::Ascending)
        #             $LegacyGUIelements.WorkersDGV.ClearSelection()
        #
        #             If ($LegacyGUIelements.WorkersDGV.Columns -and -not $LegacyGUIelements.WorkersDGV.ColumnWidthChanged) { 
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
        #                 $LegacyGUIelements.WorkersDGV | Add-Member ColumnWidthChanged $true -Force
        #             }
        #             Set-WorkerColor
        #             $LegacyGUIelements.WorkersDGV.EndInit()
        #         }
        #     }
        #     else { 
        #         $LegacyGUIelements.WorkersLabel.Text = "Worker status reporting is disabled (Configuration item 'ShowWorkerStatus' -eq `$false)."
        #         $LegacyGUIelements.WorkersDGV.DataSource = $null
        #     }
        #     Break
        # }
        "SwitchingLog" { 
            CheckBoxSwitchingLog_Click
            break
        }
        "WatchdogTimers" { 
            $LegacyGUIelements.WatchdogTimersRemoveButton.Visible = $Session.Config.Watchdog
            $LegacyGUIelements.WatchdogTimersDGV.Visible = $Session.Config.Watchdog

            if ($Session.Config.Watchdog) { 
                if ($Session.NewMiningStatus -eq "Idle") { 
                    $LegacyGUIelements.WatchdogTimersLabel.Text = "No watchdog timers - mining is stopped"
                    $LegacyGUIelements.WatchdogTimersDGV.DataSource = $null
                    $LegacyGUIelements.WatchdogTimersDGV | Add-Member ColumnWidthChanged
                }
                elseif ($Session.NewMiningStatus -eq "Paused") { 
                    $LegacyGUIelements.WatchdogTimersLabel.Text = "No watchdog timers - mining is paused"
                    $LegacyGUIelements.WatchdogTimersDGV.DataSource = $null
                    $LegacyGUIelements.WatchdogTimersDGV | Add-Member ColumnWidthChanged
                }
                elseif ($Session.NewMiningStatus -eq "Running" -and $Session.MiningStatus -eq "Running" -and -not $Session.Pools -and $Global:CoreCycleRunspace.Job.IsCompleted -eq $true) { 
                    $LegacyGUIelements.WatchdogTimersLabel.Text = "No watchdog timers - mining is suspended"
                    $LegacyGUIelements.WatchdogTimersDGV.DataSource = $null
                    $LegacyGUIelements.WatchdogTimersDGV | Add-Member ColumnWidthChanged
                }
                elseif ($Session.WatchdogTimers) { 
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

                    if ($LegacyGUIelements.WatchdogTimersDGV.Columns -and -not $LegacyGUIelements.WatchdogTimersDGV.ColumnWidthChanged) { 
                        $LegacyGUIelements.WatchdogTimersDGV.Columns[0].FillWeight = 200
                        $LegacyGUIelements.WatchdogTimersDGV.Columns[1].FillWeight = 60
                        $LegacyGUIelements.WatchdogTimersDGV.Columns[2].FillWeight = 60
                        $LegacyGUIelements.WatchdogTimersDGV.Columns[3].FillWeight = 60
                        $LegacyGUIelements.WatchdogTimersDGV.Columns[4].FillWeight = 44
                        $LegacyGUIelements.WatchdogTimersDGV.Columns[5].FillWeight = 35 + ($Session.WatchdogTimers.ForEach({ $_.DeviceNames.Count }) | Measure-Object -Maximum).Maximum * 20
                        $LegacyGUIelements.WatchdogTimersDGV.Columns[6].FillWeight = 55

                        $LegacyGUIelements.WatchdogTimersDGV | Add-Member ColumnWidthChanged $true -Force
                    }
                    $LegacyGUIelements.WatchdogTimersDGV.EndInit()
                }
                else { 
                    $LegacyGUIelements.WatchdogTimersLabel.Text = "Waiting for watchdog timer information..."
                    $LegacyGUIelements.WatchdogTimersDGV.DataSource = $null
                }
            }
            else { $LegacyGUIelements.WatchdogTimersLabel.Text = "Watchdog is disabled (Configuration item 'Watchdog' -eq `$false)" }

            $LegacyGUIelements.WatchdogTimersRemoveButton.Enabled = [Boolean]$LegacyGUIelements.WatchdogTimersDGV.Rows
        }
    }
}

function Update-GUIstatus { 

    $LegacyGUIform.Text = $host.UI.RawUI.WindowTitle

    switch ($Session.NewMiningStatus) { 
        "Idle" { 
            $LegacyGUIelements.MiningStatusLabel.ForeColor = [System.Drawing.Color]::Red
            $LegacyGUIelements.MiningStatusLabel.Text = "$($Session.Branding.ProductLabel) is stopped"
            $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Black
            break
        }
        "Paused" { 
            $LegacyGUIelements.MiningStatusLabel.ForeColor = [System.Drawing.Color]::Blue
            $LegacyGUIelements.MiningStatusLabel.Text = "$($Session.Branding.ProductLabel) is paused"
            $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Black
            break
        }
        "Running" { 
            if ($Session.MiningStatus -eq "Running" -and -not $Global:CoreCycleRunspace) { 
                $LegacyGUIelements.MiningStatusLabel.ForeColor = [System.Drawing.Color]::Blue
                $LegacyGUIelements.MiningStatusLabel.Text = "$($Session.Branding.ProductLabel) is suspended"
                $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Black
            }
            else { 
                $LegacyGUIelements.MiningStatusLabel.ForeColor = [System.Drawing.Color]::Green
                $LegacyGUIelements.MiningStatusLabel.Text = "$($Session.Branding.ProductLabel) is running"

                if ($Session.MinersRunning -and $Session.MiningProfit -gt 0) { $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Green }
                elseif ($Session.MinersRunning -and $Session.MiningProfit -lt 0) { $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Red }
                else { $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Black }
            }
        }
    }
    $LegacyGUIelements.MiningSummaryLabel.Text = (($Session.Summary.Replace("$($LegacyGUIelements.MiningStatusLabel.Text). ", "") -replace "&ensp;", " " -replace "   ", "  " -replace "&", "&&") -split "<br>") -join "`r`n"
    Update-TabControl
}

$LegacyGUIelements = [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase) # as case insensitve sorted hashtable
[System.Windows.Forms.Application]::EnableVisualStyles()
$LegacyGUIform = [System.Windows.Forms.Form]::new()

# For high DPI, first call SuspendLayout(), after that, Set AutoScaleDimensions, AutoScaleMode
# SuspendLayout() is very important to correctly size and position all controls!
$LegacyGUIform.SuspendLayout()
$LegacyGUIform.AutoScaleDimensions = [System.Drawing.SizeF]::new(96, 96)
$LegacyGUIform.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::DPI
$LegacyGUIform.MaximizeBox = $true
$LegacyGUIform.MinimumSize = [System.Drawing.Size]::new(800, 600)
$LegacyGUIform.Text = $Session.Branding.ProductLabel
$LegacyGUIform.TopMost = $false

# Define GUI elements
$LegacyGUIelements.Colors = @{ }
$LegacyGUIelements.Colors["benchmarking"] = [System.Drawing.Color]::FromArgb(241, 255, 229)
$LegacyGUIelements.Colors["disabled"] = [System.Drawing.Color]::FromArgb(255, 243, 231)
$LegacyGUIelements.Colors["failed"] = [System.Drawing.Color]::FromArgb(255, 230, 230)
$LegacyGUIelements.Colors["idle"] = $LegacyGUIelements.Colors["stopped"] = [System.Drawing.Color]::FromArgb(230, 248, 252)
$LegacyGUIelements.Colors["launched"] = [System.Drawing.Color]::FromArgb(229, 255, 229)
$LegacyGUIelements.Colors["dryrun"] = $LegacyGUIelements.Colors["running"] = [System.Drawing.Color]::FromArgb(212, 244, 212)
$LegacyGUIelements.Colors["starting"] = $LegacyGUIelements.Colors["stopping"] = [System.Drawing.Color]::FromArgb(245, 255, 245)
$LegacyGUIelements.Colors["unavailable"] = [System.Drawing.Color]::FromArgb(254, 245, 220)
$LegacyGUIelements.Colors["warmingup"] = [System.Drawing.Color]::FromArgb(231, 255, 230)

$LegacyGUIelements.Tooltip = [System.Windows.Forms.ToolTip]::new()

$LegacyGUIelements.StatusPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIelements.StatusPage.Name = "SystemStatus"
$LegacyGUIelements.StatusPage.Text = "System status"
$LegacyGUIelements.StatusPage.ToolTipText = "Show active miners and system log"
$LegacyGUIelements.EarningsPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIelements.EarningsPage.Name = "EarningsAndBalances"
$LegacyGUIelements.EarningsPage.Text = "Earnings and balances"
$LegacyGUIelements.EarningsPage.ToolTipText = "Information about the calculated earnings / profit"
$LegacyGUIelements.MinersPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIelements.MinersPage.Name = "Miners"
$LegacyGUIelements.MinersPage.Text = "Miners"
$LegacyGUIelements.MinersPage.ToolTipText = "Miner information updated in the last cycle"
$LegacyGUIelements.PoolsPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIelements.PoolsPage.Name = "Pools"
$LegacyGUIelements.PoolsPage.Text = "Pools"
$LegacyGUIelements.PoolsPage.ToolTipText = "Pool information updated in the last cycle"
# $LegacyGUIelements.RigMonitorPage = [System.Windows.Forms.TabPage]::new()
# $LegacyGUIelements.RigMonitorPage.Text = "Rig monitor"
# $LegacyGUIelements.RigMonitorPage.ToolTipText = "Consolidated overview of all known mining rigs"
$LegacyGUIelements.SwitchingLogPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIelements.SwitchingLogPage.Name = "SwitchingLog"
$LegacyGUIelements.SwitchingLogPage.Text = "Switching log"
$LegacyGUIelements.SwitchingLogPage.ToolTipText = "List of the previously launched miners"
$LegacyGUIelements.WatchdogTimersPage = [System.Windows.Forms.TabPage]::new()
$LegacyGUIelements.WatchdogTimersPage.Name = "WatchdogTimers"
$LegacyGUIelements.WatchdogTimersPage.Text = "Watchdog timers"
$LegacyGUIelements.WatchdogTimersPage.ToolTipText = "List of all watchdog timers"

$LegacyGUIelements.MiningStatusLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIelements.MiningStatusLabel.AutoSize = $false
$LegacyGUIelements.MiningStatusLabel.BackColor = [System.Drawing.Color]::Transparent
$LegacyGUIelements.MiningStatusLabel.Font = [System.Drawing.Font]::new($Font2, 12)
$LegacyGUIelements.MiningStatusLabel.ForeColor = [System.Drawing.Color]::Black
$LegacyGUIelements.MiningStatusLabel.Height = 20
$LegacyGUIelements.MiningStatusLabel.Location = [System.Drawing.Point]::new(11, 10)
$LegacyGUIelements.MiningStatusLabel.Text = "$($Session.Branding.ProductLabel)"
$LegacyGUIelements.MiningStatusLabel.TextAlign = "MiddleLeft"
$LegacyGUIelements.MiningStatusLabel.Visible = $true
$LegacyGUIelements.MiningStatusLabel.Width = 360
$LegacyGUIform.Controls.Add($LegacyGUIelements.MiningStatusLabel)

$LegacyGUIelements.MiningSummaryLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIelements.MiningSummaryLabel.AutoSize = $false
$LegacyGUIelements.MiningSummaryLabel.BackColor = [System.Drawing.Color]::Transparent
$LegacyGUIelements.MiningSummaryLabel.BorderStyle = 'None'
$LegacyGUIelements.MiningSummaryLabel.Font = [System.Drawing.Font]::new($Font2, 10)
$LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Black
$LegacyGUIelements.MiningSummaryLabel.Height = 60
$LegacyGUIelements.MiningSummaryLabel.Location = [System.Drawing.Point]::new(12, 36)
$LegacyGUIelements.MiningSummaryLabel.Tag = ""
$LegacyGUIelements.MiningSummaryLabel.TextAlign = "MiddleLeft"
$LegacyGUIelements.MiningSummaryLabel.Visible = $true
$LegacyGUIform.Controls.Add($LegacyGUIelements.MiningSummaryLabel)
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.MiningSummaryLabel, "Color legend:`rBlack: Mining profitability is unknown`rGreen: Mining is profitable`rRed: Mining is NOT profitable")

$LegacyGUIelements.ButtonPause = [System.Windows.Forms.Button]::new()
$LegacyGUIelements.ButtonPause.Font = [System.Drawing.Font]::new($Font2, 10)
$LegacyGUIelements.ButtonPause.Height = 24
$LegacyGUIelements.ButtonPause.Text = "Pause mining"
$LegacyGUIelements.ButtonPause.Visible = $true
$LegacyGUIelements.ButtonPause.Width = 100
$LegacyGUIelements.ButtonPause.Add_Click(
    { 
        if ($Session.NewMiningStatus -ne "Paused" -and -not $Session.SuspendCycle) { 
            $Session.NewMiningStatus = "Paused"
            $Session.SuspendCycle = $false
            $Session.RestartCycle = $true
        }
    }
)
$LegacyGUIform.Controls.Add($LegacyGUIelements.ButtonPause)
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.ButtonPause, "Pause mining processes.`rBrain jobs and balances tracker remain running.")

$LegacyGUIelements.ButtonStart = [System.Windows.Forms.Button]::new()
$LegacyGUIelements.ButtonStart.Font = [System.Drawing.Font]::new($Font2, 10)
$LegacyGUIelements.ButtonStart.Height = 24
$LegacyGUIelements.ButtonStart.Text = "Start mining"
$LegacyGUIelements.ButtonStart.Visible = $true
$LegacyGUIelements.ButtonStart.Width = 100
$LegacyGUIelements.ButtonStart.Add_Click(
    { 
        if ($Session.NewMiningStatus -ne "Running") { 
            $Session.NewMiningStatus = "Running"
            $Session.SuspendCycle = $false
            $Session.RestartCycle = $true
        }
    }
)
$LegacyGUIform.Controls.Add($LegacyGUIelements.ButtonStart)
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.ButtonStart, "Start the mining process.`rBrain jobs and balances tracker will also start.")

$LegacyGUIelements.ButtonStop = [System.Windows.Forms.Button]::new()
$LegacyGUIelements.ButtonStop.Font = [System.Drawing.Font]::new($Font2, 10)
$LegacyGUIelements.ButtonStop.Height = 24
$LegacyGUIelements.ButtonStop.Text = "Stop mining"
$LegacyGUIelements.ButtonStop.Visible = $true
$LegacyGUIelements.ButtonStop.Width = 100
$LegacyGUIelements.ButtonStop.Add_Click(
    { 
        if ($Session.NewMiningStatus -ne "Idle") { 
            $Session.NewMiningStatus = "Idle"
            $Session.SuspendCycle = $false
            $Session.RestartCycle = $true
        }
    }
)
$LegacyGUIform.Controls.Add($LegacyGUIelements.ButtonStop)
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.ButtonStop, "Stop mining processes.`rBrain jobs and balances tracker will also stop.")

$LegacyGUIelements.EditConfigLink = [System.Windows.Forms.LinkLabel]::new()
$LegacyGUIelements.EditConfigLink.ActiveLinkColor = [System.Drawing.Color]::Blue
$LegacyGUIelements.EditConfigLink.Font = [System.Drawing.Font]::new($Font2, 10)
$LegacyGUIelements.EditConfigLink.LinkColor = [System.Drawing.Color]::Blue
$LegacyGUIelements.EditConfigLink.Location = [System.Drawing.Point]::new(18, ($LegacyGUIform.Bottom - 28))
$LegacyGUIelements.EditConfigLink.TextAlign = "MiddleLeft"
$LegacyGUIelements.EditConfigLink.Size = [System.Drawing.Size]::new(380, 22)
$LegacyGUIelements.EditConfigLink.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        if ($LegacyGUIelements.EditConfigLink.Tag -eq "WebGUI") { Start-Process "http://localhost:$($Session.APIport)/configedit.html" } else { Edit-File $Session.ConfigFile }
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)
$LegacyGUIform.Controls.Add($LegacyGUIelements.EditConfigLink)

$LegacyGUIelements.CopyrightLabel = [System.Windows.Forms.LinkLabel]::new()
$LegacyGUIelements.CopyrightLabel.ActiveLinkColor = [System.Drawing.Color]::Blue
$LegacyGUIelements.CopyrightLabel.Font = [System.Drawing.Font]::new($Font2, 10)
$LegacyGUIelements.CopyrightLabel.Location = [System.Drawing.Point]::new(8, ($LegacyGUIform.Bottom - 28))
$LegacyGUIelements.CopyrightLabel.LinkColor = [System.Drawing.Color]::Blue
$LegacyGUIelements.CopyrightLabel.Size = [System.Drawing.Size]::new(380, 22)
$LegacyGUIelements.CopyrightLabel.Text = "Copyright (c) 2018-$([DateTime]::Now.Year) UselessGuru"
$LegacyGUIelements.CopyrightLabel.TextAlign = "MiddleRight"
$LegacyGUIelements.CopyrightLabel.Add_Click({ Start-Process "$($Session.Branding.BrandWebSite)" })
$LegacyGUIform.Controls.Add($LegacyGUIelements.CopyrightLabel)
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

$LegacyGUIelements.ContextMenuStripItem7 = [System.Windows.Forms.ToolStripMenuItem]::new()
[Void]$LegacyGUIelements.ContextMenuStrip.Items.Add($LegacyGUIelements.ContextMenuStripItem7)

$LegacyGUIelements.ContextMenuStrip.Add_ItemClicked(
    { 
        $Data = @()

        $SourceControl = $this.SourceControl
        if ($SourceControl.Name -match "LaunchedMinersDGV|MinersDGV|SwitchingLog") { 

            $MinerInfoColumn = if ($SourceControl.Name -match "LaunchedMinersDGV|MinersDGV") { 0 } else { 2 }

            switch ($_.ClickedItem.Text) { 
                "Re-benchmark miner" { 
                    $LegacyGUIelements.ContextMenuStrip.Visible = $false
                    $Session.Miners.Where({ $_.Info -in $SourceControl.SelectedRows.ForEach({ $_.Cells[$MinerInfoColumn].Value }) }).ForEach(
                        { 
                            $Data += $_.Name
                            Set-MinerReBenchmark $_
                        }
                    )
                    if ($Data.Count) { 
                        $Message = "Re-benchmark triggered for $($Data.Count) miner$(if ($Data.Count -ne 1) { "s" })."
                        Write-Message -Level Verbose "GUI: $Message" -Console $false
                        $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                        if ($Session.Config.DryRun -and $Session.NewMiningStatus -eq "Running") { $Session.EndCycleTime = [DateTime]::Now.ToUniversalTime() }
                    }
                    else { 
                        $Data = "No matching miners found."
                    }
                    Update-TabControl
                    break
                }
                "Re-measure power consumption" { 
                    $LegacyGUIelements.ContextMenuStrip.Visible = $false
                    $Session.Miners.Where({ $_.Info -in $SourceControl.SelectedRows.ForEach({ $_.Cells[$MinerInfoColumn].Value }) }).ForEach(
                        { 
                            $Data += $_.Name
                            Set-MinerMeasurePowerConsumption $_ 
                        }
                    )
                    if ($Data.Count) { 
                        $Message = "Re-measure power consumption triggered for $($Data.Count) miner$(if ($Data.Count -ne 1) { "s" })."
                        Write-Message -Level Verbose "GUI: $Message" -Console $false
                        $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                        Remove-Variable Message
                        if ($Session.Config.DryRun -and $Session.NewMiningStatus -eq "Running") { $Session.EndCycleTime = [DateTime]::Now.ToUniversalTime() }
                        Update-TabControl
                    }
                    else { 
                        $Data = "No matching miners found."
                    }
                    break
                }
                "Mark miner as failed" { 
                    $LegacyGUIelements.ContextMenuStrip.Visible = $false
                    $Session.Miners.Where({ $_.Info -in $SourceControl.SelectedRows.ForEach({ $_.Cells[$MinerInfoColumn].Value }) }).ForEach(
                        { 
                            Set-MinerFailed $_
                            $Data += $_.Name
                        }
                    )
                    if ($Data.Count) { 
                        $Message = "Marked $($Data.Count) miner$(if ($Data.Count -ne 1) { "s" }) as failed." 
                        Write-Message -Level Verbose "GUI: $Message" -Console $false
                        $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                        Remove-Variable Message
                        Update-TabControl
                    }
                    else { 
                        $Data = "No matching miners found."
                    }
                    break
                }
                "Disable miner" { 
                    $LegacyGUIelements.ContextMenuStrip.Visible = $false
                    $Session.Miners.Where({ $_.Info -in $SourceControl.SelectedRows.ForEach({ $_.Cells[$MinerInfoColumn].Value }) }).Where({ -not $_.Disabled }).ForEach(
                        { 
                            $Data += $_.Name
                            Set-MinerDisabled $_
                        }
                    )
                    if ($Data.Count) { 
                        $Message = "Disabled $($Data.Count) miner$(if ($Data.Count -ne 1) { "s" })."
                        Write-Message -Level Verbose "GUI: $Message" -Console $false
                        $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                        Remove-Variable Message
                        Update-TabControl
                    }
                    else { 
                        $Data = "No miners to disable."
                    }
                    break
                }
                "Enable miner" { 
                    $LegacyGUIelements.ContextMenuStrip.Visible = $false
                    $Session.Miners.Where({ $_.Info -in $SourceControl.SelectedRows.ForEach({ $_.Cells[$MinerInfoColumn].Value }) }).Where({ $_.Disabled }).ForEach(
                        { 
                            $Data += $_.Name
                            Set-MinerEnabled $_
                        }
                    )
                    if ($Data.Count) { 
                        $Message = "Enabled $($Data.Count) miner$(if ($Data.Count -ne 1) { "s" })."
                        Write-Message -Level Verbose "GUI: $Message" -Console $false
                        $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                        Remove-Variable Message
                        Update-TabControl
                    }
                    else { 
                        $Data = "No miners to enable."
                    }
                    break
                }
                "Remove watchdog timer" { 
                    $this.SourceControl.SelectedRows.ForEach(
                        { 
                            $MinerName = $_.Cells[2].Value
                            # Update miner
                            foreach ($Miner in $Session.Miners.Where({ $_.Name -eq $MinerName -and $Session.WatchdogTimers.Where({ $_.MinerName -eq $MinerName }) })) { 
                                $Data += $Miner.Name
                                $Miner.Reasons.Where({ $_ -like "Miner suspended by watchdog *" }).ForEach({ $null = $Miner.Reasons.Remove($_) })
                                if (-not $Miner.Reasons.Count) { $Miner.Available = $true }
                            }

                            # Remove Watchdog timers
                            $Session.WatchdogTimers = $Session.WatchdogTimers.Where({ $_.MinerName -ne $MinerName })
                        }
                    )
                    $LegacyGUIelements.ContextMenuStrip.Visible = $false
                    if ($Data) { 
                        $Message = "$($Data.Count) miner watchdog timer$(if ($Data.Count -ne 1) { "s" }) removed."
                        Write-Message -Level Verbose "GUI: $Message" -Console $false
                        $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                    }
                    else { 
                        $Data = "No matching watchdog timer found."
                    }
                    Remove-Variable Message, Miner, MinerName -ErrorAction Ignore
                    break
                }
                "Copy miner command line to clipboard" { 
                    $this.SourceControl.SelectedRows.ForEach(
                        { 
                            Set-Clipboard $_.Cells[10].Value
                            $null = (New-Object -ComObject Wscript.Shell).Popup("Miner command line copied to clipboard.", 0, "$($Session.Branding.ProductLabel) v$($Session.Branding.Version)", (4096 + 64))
                        }
                    )
                }
            }
            Remove-Variable MinerInfoColumn
            if ($Data.Count -ge 1) { [Void][System.Windows.Forms.MessageBox]::Show([String]($Data -join "`r`n"), "$($Session.Branding.ProductLabel): $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK, 64) }

        }
        elseif ($this.SourceControl.Name -match "PoolsDGV") { 
            switch ($_.ClickedItem.Text) { 
                "Reset pool stat data" { 
                    $this.SourceControl.SelectedRows.ForEach(
                        { 
                            $SelectedPoolName = $_.Cells[5].Value
                            $SelectedPoolAlgorithm = $_.Cells[0].Value
                            $Session.Pools.Where({ $_.Name -eq $SelectedPoolName -and $_.Algorithm -eq $SelectedPoolAlgorithm }).ForEach(
                                { 
                                    $Data += "$($_.Algorithm)$(if ($_.Currency) { "-$($_.Currency)" })@$($_.Name)$(if ($($_.Variant -replace $_.Name)) { "[$($_.Variant -replace $_.Name)]" })"

                                    Remove-Stat -Name "$($_.Variant)_$($_.Algorithm)$(if ($_.Currency) { "-$($_.Currency)" })_Profit"

                                    $_.Reasons = [System.Collections.Generic.SortedSet[String]]::new()
                                    $_.Price = $_.Price_Bias = $_.StablePrice = $_.Accuracy = [Double]::NaN
                                    $_.Available = $true
                                    $_.Disabled = $false
                                }
                            )
                        }
                    )
                    $LegacyGUIelements.ContextMenuStrip.Visible = $false
                    $Message = "Reset pool stats for $($Data.Count) pool$(if ($Data.Count -ne 1) { "s" })."
                    Write-Message -Level Verbose "GUI: $Message" -Console $false
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                    Remove-Variable Message, SelectedPoolAlgorithm, SelectedPoolName, StatName -ErrorAction Ignore
                    Update-TabControl
                    break
                }
                "Remove watchdog timer" { 
                    $this.SourceControl.SelectedRows.ForEach(
                        { 
                            $PoolName = $_.Cells[5].Value
                            $PoolAlgorithm = $_.Cells[0].Value
                            # Update pool
                            foreach ($Pool in ($Session.Pools.Where({ $_.Name -eq $PoolName -and $_.Algorithm -eq $PoolAlgorithm -and $Session.WatchdogTimers.Where({ $_.PoolName -eq $PoolName -and $_.Algorithm -eq $PoolAlgorithm }) }))) { 
                                $Data += "$($Pool.Key) ($($Pool.Region))"
                                $Pool.Reasons.Where({ $_ -like "Pool suspended by watchdog *" }).ForEach({ $null = $Pool.Reasons.Remove($_) })
                                if (-not $Pool.Reasons.Count) { $Pool.Available = $true }
                            }

                            # Remove Watchdog timers
                            $Session.WatchdogTimers = $Session.WatchdogTimers.Where({ $_.PoolName -ne $PoolName -or $_.Algorithm -ne $PoolAlgorithm })

                            Remove-Variable Pool, PoolAlgorithm, PoolAlgorithm, PoolName
                        }
                    )
                    $LegacyGUIelements.ContextMenuStrip.Visible = $false
                    if ($Data) { 
                        $Message = "$($Data.Count) pool watchdog timer$(if ($Data.Count -ne 1) { "s" }) removed."
                        Write-Message -Level Verbose "GUI: $Message" -Console $false
                        $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                        Remove-Variable Message
                    }
                    else { 
                        $Data = "No matching watchdog timer found."
                    }
                    break
                }
            }
            if ($Data.Count -ge 1) { [Void][System.Windows.Forms.MessageBox]::Show([String]($Data -join "`r`n"), "$($Session.Branding.ProductLabel): $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK, 64) }

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
$LegacyGUIelements.ActiveMinersLabel.Font = [System.Drawing.Font]::new($Font2, 10)
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
$LegacyGUIelements.ActiveMinersDGV.Font = [System.Drawing.Font]::new($Font, 9)
$LegacyGUIelements.ActiveMinersDGV.Height = 3
$LegacyGUIelements.ActiveMinersDGV.Location = [System.Drawing.Point]::new(0, ($LegacyGUIelements.ActiveMinersLabel.Height + 6))
$LegacyGUIelements.ActiveMinersDGV.MultiSelect = $true
$LegacyGUIelements.ActiveMinersDGV.Name = "LaunchedMinersDGV"
$LegacyGUIelements.ActiveMinersDGV.ReadOnly = $true
$LegacyGUIelements.ActiveMinersDGV.RowHeadersVisible = $false
$LegacyGUIelements.ActiveMinersDGV.ScrollBars = "None"
$LegacyGUIelements.ActiveMinersDGV.SelectionMode = "FullRowSelect"
$LegacyGUIelements.ActiveMinersDGV.Add_CellClick({ if ($this.Rows[$_.RowIndex].Tag -eq "ToggleSelect") { $this.Rows[$_.RowIndex].Selected = $false; $this.Rows[$_.RowIndex].Tag = $null } })
$LegacyGUIelements.ActiveMinersDGV.Add_CellMouseDown({ if ($this.SelectedRows.Count -eq 1 -and $this.Rows[$_.RowIndex].Selected) { $this.Rows[$_.RowIndex].Tag = "ToggleSelect" } })
$LegacyGUIelements.ActiveMinersDGV.Add_DataSourceChanged({ if ($LegacyGUIelements.TabControl.SelectedTab.Text -eq "System status") { Resize-Form } }) # To fully show grid
$LegacyGUIelements.ActiveMinersDGV.Add_MouseUp({ if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right) { $LegacyGUIelements.ContextMenuStrip.Enabled = [Boolean]$this.SelectedRows } })
$LegacyGUIelements.ActiveMinersDGV.Add_SelectionChanged({ $LegacyGUIelements.ContextMenuStripItem7.Enabled = [Boolean]($LegacyGUIelements.ActiveMinersDGV.SelectedRows.Count -eq 1) })
$LegacyGUIelements.ActiveMinersDGV.Add_Sorted({ Set-TableColor -DataGridView $this; $this.ClearSelection() }) 
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIelements.ActiveMinersDGV -Enabled $true
$LegacyGUIelements.StatusPageControls += $LegacyGUIelements.ActiveMinersDGV

$LegacyGUIelements.SystemLogLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIelements.SystemLogLabel.AutoSize = $false
$LegacyGUIelements.SystemLogLabel.Font = [System.Drawing.Font]::new($Font2, 10)
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
$LegacyGUIelements.BalancesLabel.Font = [System.Drawing.Font]::new($Font2, 10)
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
$LegacyGUIelements.BalancesDGV.Font = [System.Drawing.Font]::new($Font, 9)
$LegacyGUIelements.BalancesDGV.Height = 3
$LegacyGUIelements.BalancesDGV.Location = [System.Drawing.Point]::new(0, 0)
$LegacyGUIelements.BalancesDGV.MultiSelect = $true
$LegacyGUIelements.BalancesDGV.Name = "EarningsDGV"
$LegacyGUIelements.BalancesDGV.ReadOnly = $true
$LegacyGUIelements.BalancesDGV.RowHeadersVisible = $false
$LegacyGUIelements.BalancesDGV.SelectionMode = "FullRowSelect"
$LegacyGUIelements.BalancesDGV.Add_DataSourceChanged({ if ($LegacyGUIelements.TabControl.SelectedTab.Text -eq "Earnings and balances") { Resize-Form } }) # To fully show grid
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIelements.BalancesDGV -Enabled $true
$LegacyGUIelements.EarningsPageControls += $LegacyGUIelements.BalancesDGV

# Miner page Controls
$LegacyGUIelements.MinersPageControls = @()

$LegacyGUIelements.RadioButtonMinersOptimal = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIelements.RadioButtonMinersOptimal.AutoSize = $false
$LegacyGUIelements.RadioButtonMinersOptimal.Checked = $true
$LegacyGUIelements.RadioButtonMinersOptimal.Font = [System.Drawing.Font]::new($Font2, 10)
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
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.RadioButtonMinersOptimal, "Shows the list of all optimal miners per algorithm and device.")

$LegacyGUIelements.RadioButtonMinersUnavailable = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIelements.RadioButtonMinersUnavailable.AutoSize = $LegacyGUIelements.RadioButtonMinersOptimal.AutoSize
$LegacyGUIelements.RadioButtonMinersUnavailable.Font = $LegacyGUIelements.RadioButtonMinersOptimal.Font
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
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.RadioButtonMinersUnavailable, "Shows the list of all unavailable miners.`rThe column 'Reason(s)' shows the filter criteria(s) that made the miner unavailable.")

$LegacyGUIelements.RadioButtonMiners = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIelements.RadioButtonMiners.AutoSize = $LegacyGUIelements.RadioButtonMinersUnavailable.AutoSize
$LegacyGUIelements.RadioButtonMiners.Font = $LegacyGUIelements.RadioButtonMinersUnavailable.Font
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
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.RadioButtonMiners, "Shows the list of all miners.`rNote: UG-Miner will only create miners for algorithms that have at least one available pool.")

$LegacyGUIelements.MinersLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIelements.MinersLabel.AutoSize = $false
$LegacyGUIelements.MinersLabel.Font = [System.Drawing.Font]::new($Font2, 10)
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
$LegacyGUIelements.MinersDGV.Font = [System.Drawing.Font]::new($Font, 9)
$LegacyGUIelements.MinersDGV.Height = 3
$LegacyGUIelements.MinersDGV.Location = [System.Drawing.Point]::new(0, ($LegacyGUIelements.MinersLabel.Height + $LegacyGUIelements.MinersPanel.Height + 10))
$LegacyGUIelements.MinersDGV.MultiSelect = $true
$LegacyGUIelements.MinersDGV.Name = "MinersDGV"
$LegacyGUIelements.MinersDGV.ReadOnly = $true
$LegacyGUIelements.MinersDGV.RowHeadersVisible = $false
$LegacyGUIelements.MinersDGV.SelectionMode = "FullRowSelect"
$LegacyGUIelements.MinersDGV.Add_CellClick({ if ($this.Rows[$_.RowIndex].Tag -eq "ToggleSelect") { $this.Rows[$_.RowIndex].Selected = $false; $this.Rows[$_.RowIndex].Tag = $null } })
$LegacyGUIelements.MinersDGV.Add_CellMouseDown({ if ($this.SelectedRows.Count -eq 1 -and $this.Rows[$_.RowIndex].Selected) { $this.Rows[$_.RowIndex].Tag = "ToggleSelect" } })
$LegacyGUIelements.MinersDGV.Add_MouseUp({ if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right) { $LegacyGUIelements.ContextMenuStrip.Enabled = [Boolean]$this.SelectedRows } })
$LegacyGUIelements.MinersDGV.Add_SelectionChanged({ $LegacyGUIelements.ContextMenuStripItem7.Enabled = [Boolean]($LegacyGUIelements.ActiveMinersDGV.SelectedRows.Count -eq 1) })
$LegacyGUIelements.MinersDGV.Add_Sorted({ Set-TableColor -DataGridView $this; $this.ClearSelection() })
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIelements.MinersDGV -Enabled $true
$LegacyGUIelements.MinersPageControls += $LegacyGUIelements.MinersDGV

# Pools page Controls
$LegacyGUIelements.PoolsPageControls = @()

$LegacyGUIelements.RadioButtonPoolsBest = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIelements.RadioButtonPoolsBest.AutoSize = $false
$LegacyGUIelements.RadioButtonPoolsBest.Font = [System.Drawing.Font]::new($Font2, 10)
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
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.RadioButtonPoolsBest, "Shows the list of the best paying pools for each algorithm.")

$LegacyGUIelements.RadioButtonPoolsUnavailable = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIelements.RadioButtonPoolsUnavailable.AutoSize = $LegacyGUIelements.RadioButtonPoolsBest.AutoSize
$LegacyGUIelements.RadioButtonPoolsUnavailable.Font = $LegacyGUIelements.RadioButtonPoolsBest.Font
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
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.RadioButtonPoolsUnavailable, "Shows the list of all unavailable pools.`rThe column 'Reason(s)' shows the filter criteria(s) that made the pool unavailable.")

$LegacyGUIelements.RadioButtonPools = [System.Windows.Forms.RadioButton]::new()
$LegacyGUIelements.RadioButtonPools.AutoSize = $LegacyGUIelements.RadioButtonPoolsUnavailable.AutoSize
$LegacyGUIelements.RadioButtonPools.Font = $LegacyGUIelements.RadioButtonPoolsUnavailable.Font
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
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.RadioButtonPools, "Shows the list of all configured pools.")

$LegacyGUIelements.PoolsLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIelements.PoolsLabel.AutoSize = $false
$LegacyGUIelements.PoolsLabel.Font = [System.Drawing.Font]::new($Font2, 10)
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
$LegacyGUIelements.PoolsDGV.Font = [System.Drawing.Font]::new($Font, 9)
$LegacyGUIelements.PoolsDGV.Height = 3
$LegacyGUIelements.PoolsDGV.Location = [System.Drawing.Point]::new(0, ($LegacyGUIelements.PoolsLabel.Height + $LegacyGUIelements.PoolsPanel.Height + 10))
$LegacyGUIelements.PoolsDGV.MultiSelect = $true
$LegacyGUIelements.PoolsDGV.Name = "PoolsDGV"
$LegacyGUIelements.PoolsDGV.ReadOnly = $true
$LegacyGUIelements.PoolsDGV.RowHeadersVisible = $false
$LegacyGUIelements.PoolsDGV.SelectionMode = "FullRowSelect"
$LegacyGUIelements.PoolsDGV.Add_CellClick({ if ($this.Rows[$_.RowIndex].Tag -eq "ToggleSelect") { $this.Rows[$_.RowIndex].Selected = $false; $this.Rows[$_.RowIndex].Tag = $null } })
$LegacyGUIelements.PoolsDGV.Add_CellMouseDown({ if ($this.SelectedRows.Count -eq 1 -and $this.Rows[$_.RowIndex].Selected) { $this.Rows[$_.RowIndex].Tag = "ToggleSelect" } })
$LegacyGUIelements.PoolsDGV.Add_MouseUp({ if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right) { $LegacyGUIelements.ContextMenuStrip.Enabled = [Boolean]$this.SelectedRows } })
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIelements.PoolsDGV -Enabled $true
$LegacyGUIelements.PoolsPageControls += $LegacyGUIelements.PoolsDGV

# Monitoring Page Controls
# $LegacyGUIelements.RigMonitorPageControls = @()

# $LegacyGUIelements.WorkersLabel = [System.Windows.Forms.Label]::new()
# $LegacyGUIelements.WorkersLabel.AutoSize = $false
# $LegacyGUIelements.WorkersLabel.Font = [System.Drawing.Font]::new($Font2, 10)
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
# $LegacyGUIelements.WorkersDGV.Font = [System.Drawing.Font]::new($Font, 9)
# $LegacyGUIelements.WorkersDGV.Height = 3
# $LegacyGUIelements.WorkersDGV.Location = [System.Drawing.Point]::new(6, ($LegacyGUIelements.WorkersLabel.Height + 8))
# $LegacyGUIelements.WorkersDGV.ReadOnly = $true
# $LegacyGUIelements.WorkersDGV.RowHeadersVisible = $false
# $LegacyGUIelements.WorkersDGV.SelectionMode = "FullRowSelect"
# $LegacyGUIelements.WorkersDGV.Add_CellClick({ if ($this.Rows[$_.RowIndex].Tag -eq "ToggleSelect") { $this.Rows[$_.RowIndex].Selected = $false; $this.Rows[$_.RowIndex].Tag = $null } })
# $LegacyGUIelements.WorkersDGV.Add_CellMouseDown({ if ($this.SelectedRows.Count -eq 1 -and $this.Rows[$_.RowIndex].Selected) { $this.Rows[$_.RowIndex].Tag = "ToggleSelect" } })
# $LegacyGUIelements.WorkersDGV.Add_Sorted({ Set-WorkerColor -DataGridView $this })
# Set-DataGridViewDoubleBuffer -Grid $LegacyGUIelements.WorkersDGV -Enabled $true
# $LegacyGUIelements.RigMonitorPageControls.Add($LegacyGUIelements.WorkersDGV)

$LegacyGUIelements.EditMonitoringLink = [System.Windows.Forms.LinkLabel]::new()
$LegacyGUIelements.EditMonitoringLink.ActiveLinkColor = [System.Drawing.Color]::Blue
$LegacyGUIelements.EditMonitoringLink.Font = [System.Drawing.Font]::new($Font2, 10)
$LegacyGUIelements.EditMonitoringLink.Height = 20
$LegacyGUIelements.EditMonitoringLink.Location = [System.Drawing.Point]::new(0, 6)
$LegacyGUIelements.EditMonitoringLink.LinkColor = [System.Drawing.Color]::Blue
$LegacyGUIelements.EditMonitoringLink.Text = "Edit the monitoring configuration"
$LegacyGUIelements.EditMonitoringLink.TextAlign = "MiddleRight"
$LegacyGUIelements.EditMonitoringLink.Size = [System.Drawing.Size]::new(330, 26)
$LegacyGUIelements.EditMonitoringLink.Visible = $false
$LegacyGUIelements.EditMonitoringLink.Width = 330
$LegacyGUIelements.EditMonitoringLink.Add_Click({ Start-Process "http://localhost:$($Session.APIport)/rigmonitor.html" })
# $LegacyGUIelements.RigMonitorPageControls += $LegacyGUIelements.EditMonitoringLink
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.EditMonitoringLink, "Click to the edit the monitoring configuration in the web GUI")

# SwitchingLog Page Controls
$LegacyGUIelements.SwitchingLogPageControls = @()

$LegacyGUIelements.SwitchingLogLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIelements.SwitchingLogLabel.AutoSize = $false
$LegacyGUIelements.SwitchingLogLabel.Font = [System.Drawing.Font]::new($Font2, 10)
$LegacyGUIelements.SwitchingLogLabel.Height = 20
$LegacyGUIelements.SwitchingLogLabel.Location = [System.Drawing.Point]::new(0, 6)
$LegacyGUIelements.SwitchingLogLabel.Width = 600
$LegacyGUIelements.SwitchingLogPageControls += $LegacyGUIelements.SwitchingLogLabel

$LegacyGUIelements.SwitchingLogClearButton = [System.Windows.Forms.Button]::new()
$LegacyGUIelements.SwitchingLogClearButton.Font = [System.Drawing.Font]::new($Font2, 10)
$LegacyGUIelements.SwitchingLogClearButton.Height = 24
$LegacyGUIelements.SwitchingLogClearButton.Location = [System.Drawing.Point]::new(0, ($LegacyGUIelements.SwitchingLogLabel.Height + 8))
$LegacyGUIelements.SwitchingLogClearButton.Text = "Clear switching log"
$LegacyGUIelements.SwitchingLogClearButton.Visible = $true
$LegacyGUIelements.SwitchingLogClearButton.Width = 160
$LegacyGUIelements.SwitchingLogClearButton.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

        Get-ChildItem -Path ".\Logs\SwitchingLog.csv" -File | Remove-Item -Force
        $LegacyGUIelements.SwitchingLogDGV.DataSource = $null
        $Data = "Switching log '.\Logs\SwitchingLog.csv' cleared."
        Write-Message -Level Verbose "GUI: $Data" -Console $false
        $LegacyGUIelements.SwitchingLogClearButton.Enabled = $false

        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal

        [Void][System.Windows.Forms.MessageBox]::Show($Data, "$($Session.Branding.ProductLabel) $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK, 64)
    }
)
$LegacyGUIelements.SwitchingLogPageControls += $LegacyGUIelements.SwitchingLogClearButton
$LegacyGUIelements.Tooltip.SetToolTip($LegacyGUIelements.SwitchingLogClearButton, "This will clear the switching log '.\Logs\SwitchingLog.csv'")

$LegacyGUIelements.CheckShowSwitchingLogCPU = [System.Windows.Forms.CheckBox]::new()
$LegacyGUIelements.CheckShowSwitchingLogCPU.AutoSize = $true
$LegacyGUIelements.CheckShowSwitchingLogCPU.Enabled = [Boolean]($Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Session.Config.ExcludeDeviceName -and $_.Type -eq "CPU" }))
$LegacyGUIelements.CheckShowSwitchingLogCPU.Font = [System.Drawing.Font]::new($Font2, 10)
$LegacyGUIelements.CheckShowSwitchingLogCPU.Height = 20
$LegacyGUIelements.CheckShowSwitchingLogCPU.Location = [System.Drawing.Point]::new(($LegacyGUIelements.SwitchingLogClearButton.Width + 30), ($LegacyGUIelements.SwitchingLogLabel.Height + 10))
$LegacyGUIelements.CheckShowSwitchingLogCPU.Tag = "CPU"
$LegacyGUIelements.CheckShowSwitchingLogCPU.Text = "CPU"
$LegacyGUIelements.CheckShowSwitchingLogCPU.Width = 40
$LegacyGUIelements.SwitchingLogPageControls += $LegacyGUIelements.CheckShowSwitchingLogCPU
$LegacyGUIelements.CheckShowSwitchingLogCPU.ForEach({ $_.Add_Click({ CheckBoxSwitchingLog_Click($this) }) })

$LegacyGUIelements.CheckShowSwitchingLogAMD = [System.Windows.Forms.CheckBox]::new()
$LegacyGUIelements.CheckShowSwitchingLogAMD.AutoSize = $LegacyGUIelements.CheckShowSwitchingLogCPU.AutoSize
$LegacyGUIelements.CheckShowSwitchingLogAMD.Enabled = [Boolean]($Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Session.Config.ExcludeDeviceName -and $_.Type -eq "GPU" -and $_.Vendor -eq "AMD" }))
$LegacyGUIelements.CheckShowSwitchingLogAMD.Height = $LegacyGUIelements.CheckShowSwitchingLogCPU.Height
$LegacyGUIelements.CheckShowSwitchingLogAMD.Font = $LegacyGUIelements.CheckShowSwitchingLogCPU.Font
$LegacyGUIelements.CheckShowSwitchingLogAMD.Location = [System.Drawing.Point]::new(($LegacyGUIelements.SwitchingLogClearButton.Width + 30 + $LegacyGUIelements.CheckShowSwitchingLogCPU.Width + 30), $LegacyGUIelements.CheckShowSwitchingLogCPU.Top)
$LegacyGUIelements.CheckShowSwitchingLogAMD.Tag = "AMD"
$LegacyGUIelements.CheckShowSwitchingLogAMD.Text = "AMD"
$LegacyGUIelements.CheckShowSwitchingLogAMD.Width = 40
$LegacyGUIelements.SwitchingLogPageControls += $LegacyGUIelements.CheckShowSwitchingLogAMD
$LegacyGUIelements.CheckShowSwitchingLogAMD.ForEach({ $_.Add_Click({ CheckBoxSwitchingLog_Click($this) }) })

$LegacyGUIelements.CheckShowSwitchingLogINTEL = [System.Windows.Forms.CheckBox]::new()
$LegacyGUIelements.CheckShowSwitchingLogINTEL.AutoSize = $LegacyGUIelements.CheckShowSwitchingLogAMD.AutoSize
$LegacyGUIelements.CheckShowSwitchingLogINTEL.Enabled = [Boolean]($Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Session.Config.ExcludeDeviceName -and $_.Type -eq "GPU" -and $_.Vendor -eq "INTEL" }))
$LegacyGUIelements.CheckShowSwitchingLogINTEL.Font = $LegacyGUIelements.CheckShowSwitchingLogAMD.Font
$LegacyGUIelements.CheckShowSwitchingLogINTEL.Height = $LegacyGUIelements.CheckShowSwitchingLogAMD.Height
$LegacyGUIelements.CheckShowSwitchingLogINTEL.Location = [System.Drawing.Point]::new(($LegacyGUIelements.SwitchingLogClearButton.Width + 30 + $LegacyGUIelements.CheckShowSwitchingLogCPU.Width + 30 + $LegacyGUIelements.CheckShowSwitchingLogAMD.Width + 30), $LegacyGUIelements.CheckShowSwitchingLogAMD.Top)
$LegacyGUIelements.CheckShowSwitchingLogINTEL.Tag = "INTEL"
$LegacyGUIelements.CheckShowSwitchingLogINTEL.Text = "INTEL"
$LegacyGUIelements.CheckShowSwitchingLogINTEL.Width = 50
$LegacyGUIelements.SwitchingLogPageControls += $LegacyGUIelements.CheckShowSwitchingLogINTEL
$LegacyGUIelements.CheckShowSwitchingLogINTEL.ForEach({ $_.Add_Click({ CheckBoxSwitchingLog_Click($this) }) })

$LegacyGUIelements.CheckShowSwitchingLogNVIDIA = [System.Windows.Forms.CheckBox]::new()
$LegacyGUIelements.CheckShowSwitchingLogNVIDIA.AutoSize = $LegacyGUIelements.CheckShowSwitchingLogINTEL.AutoSize
$LegacyGUIelements.CheckShowSwitchingLogNVIDIA.Enabled = [Boolean]($Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Session.Config.ExcludeDeviceName -and $_.Type -eq "GPU" -and $_.Vendor -eq "NVIDIA" }))
$LegacyGUIelements.CheckShowSwitchingLogNVIDIA.Font = $LegacyGUIelements.CheckShowSwitchingLogINTEL.Font
$LegacyGUIelements.CheckShowSwitchingLogNVIDIA.Height = $LegacyGUIelements.CheckShowSwitchingLogINTEL.Height
$LegacyGUIelements.CheckShowSwitchingLogNVIDIA.Location = [System.Drawing.Point]::new(($LegacyGUIelements.SwitchingLogClearButton.Width + 30 + $LegacyGUIelements.CheckShowSwitchingLogCPU.Width + 30 + $LegacyGUIelements.CheckShowSwitchingLogAMD.Width + 30 + $LegacyGUIelements.CheckShowSwitchingLogINTEL.Width + 30), ($LegacyGUIelements.SwitchingLogLabel.Height + 10))
$LegacyGUIelements.CheckShowSwitchingLogNVIDIA.Tag = "NVIDIA"
$LegacyGUIelements.CheckShowSwitchingLogNVIDIA.Text = "NVIDIA"
$LegacyGUIelements.CheckShowSwitchingLogNVIDIA.Width = 55
$LegacyGUIelements.SwitchingLogPageControls += $LegacyGUIelements.CheckShowSwitchingLogNVIDIA
$LegacyGUIelements.CheckShowSwitchingLogNVIDIA.ForEach({ $_.Add_Click({ CheckBoxSwitchingLog_Click($this) }) })

$LegacyGUIelements.SwitchingLogDGV = [System.Windows.Forms.DataGridView]::new()
$LegacyGUIelements.SwitchingLogDGV.AllowUserToAddRows = $false
$LegacyGUIelements.SwitchingLogDGV.AllowUserToDeleteRows = $false
$LegacyGUIelements.SwitchingLogDGV.AllowUserToOrderColumns = $true
$LegacyGUIelements.SwitchingLogDGV.AllowUserToResizeColumns = $true
$LegacyGUIelements.SwitchingLogDGV.AllowUserToResizeRows = $false
$LegacyGUIelements.SwitchingLogDGV.AutoSizeColumnsMode = "Fill"
$LegacyGUIelements.SwitchingLogDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIelements.SwitchingLogDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LegacyGUIelements.SwitchingLogDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LegacyGUIelements.SwitchingLogDGV.ColumnHeadersVisible = $true
$LegacyGUIelements.SwitchingLogDGV.ContextMenuStrip = $LegacyGUIelements.ContextMenuStrip
$LegacyGUIelements.SwitchingLogDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LegacyGUIelements.SwitchingLogDGV.EnableHeadersVisualStyles = $false
$LegacyGUIelements.SwitchingLogDGV.Font = [System.Drawing.Font]::new($Font, 9)
$LegacyGUIelements.SwitchingLogDGV.Height = 3
$LegacyGUIelements.SwitchingLogDGV.Location = [System.Drawing.Point]::new(0, ($LegacyGUIelements.SwitchingLogLabel.Height + $LegacyGUIelements.SwitchingLogClearButton.Height + 12))
$LegacyGUIelements.SwitchingLogDGV.MultiSelect = $false
$LegacyGUIelements.SwitchingLogDGV.Name = "SwitchingLogDGV"
$LegacyGUIelements.SwitchingLogDGV.ReadOnly = $true
$LegacyGUIelements.SwitchingLogDGV.RowHeadersVisible = $false
$LegacyGUIelements.SwitchingLogDGV.SelectionMode = "FullRowSelect"
$LegacyGUIelements.SwitchingLogDGV.Add_CellClick({ if ($this.Rows[$_.RowIndex].Tag -eq "ToggleSelect") { $this.Rows[$_.RowIndex].Selected = $false; $this.Rows[$_.RowIndex].Tag = $null } })
$LegacyGUIelements.SwitchingLogDGV.Add_CellMouseDown({ if ($this.SelectedRows.Count -eq 1 -and $this.Rows[$_.RowIndex].Selected) { $this.Rows[$_.RowIndex].Tag = "ToggleSelect" } })
$LegacyGUIelements.SwitchingLogDGV.Add_MouseUp({ if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right) { $LegacyGUIelements.ContextMenuStrip.Enabled = [Boolean]$this.SelectedRows } })
$LegacyGUIelements.SwitchingLogDGV.Add_Sorted({ if ($Session.Config.UseColorForMinerStatus) { foreach ($Row in $this.Rows) { $Row.DefaultCellStyle.Backcolor = $LegacyGUIelements.Colors[$Row.DataBoundItem.Action] } } })
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIelements.SwitchingLogDGV -Enabled $true
$LegacyGUIelements.SwitchingLogPageControls += $LegacyGUIelements.SwitchingLogDGV

$LegacyGUIelements.CheckShowSwitchingLogCPU.Checked = $LegacyGUIelements.CheckShowSwitchingLogCPU.Enabled
$LegacyGUIelements.CheckShowSwitchingLogAMD.Checked = $LegacyGUIelements.CheckShowSwitchingLogAMD.Enabled
$LegacyGUIelements.CheckShowSwitchingLogINTEL.Checked = $LegacyGUIelements.CheckShowSwitchingLogINTEL.Enabled
$LegacyGUIelements.CheckShowSwitchingLogNVIDIA.Checked = $LegacyGUIelements.CheckShowSwitchingLogNVIDIA.Enabled

# Watchdog Page Controls
$LegacyGUIelements.WatchdogTimersPageControls = @()

$LegacyGUIelements.WatchdogTimersLabel = [System.Windows.Forms.Label]::new()
$LegacyGUIelements.WatchdogTimersLabel.AutoSize = $false
$LegacyGUIelements.WatchdogTimersLabel.Font = [System.Drawing.Font]::new($Font2, 10)
$LegacyGUIelements.WatchdogTimersLabel.Height = 20
$LegacyGUIelements.WatchdogTimersLabel.Location = [System.Drawing.Point]::new(0, 6)
$LegacyGUIelements.WatchdogTimersLabel.Width = 600
$LegacyGUIelements.WatchdogTimersPageControls += $LegacyGUIelements.WatchdogTimersLabel

$LegacyGUIelements.WatchdogTimersRemoveButton = [System.Windows.Forms.Button]::new()
$LegacyGUIelements.WatchdogTimersRemoveButton.Font = [System.Drawing.Font]::new($Font2, 10)
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
        foreach ($Miner in $Session.Miners) { 
            $Miner.Reasons.Where({ $_ -like "Miner suspended by watchdog *" }).ForEach({ $null = $Miner.Reasons.Remove($_) })
            if (-not $Miner.Reasons.Count) { $Miner.Available = $true }
        }
        Remove-Variable Miner

        foreach ($Pool in $Session.Pools) { 
            $Pool.Reasons.Where({ $_ -like "Pool suspended by watchdog *" }).ForEach({ $null = $Pool.Reasons.Remove($_) })
            if (-not $Pool.Reasons.Count) { $Pool.Available = $true }
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
$LegacyGUIelements.WatchdogTimersDGV.Font = [System.Drawing.Font]::new($Font, 9)
$LegacyGUIelements.WatchdogTimersDGV.Height = 3
$LegacyGUIelements.WatchdogTimersDGV.Location = [System.Drawing.Point]::new(0, ($LegacyGUIelements.WatchdogTimersLabel.Height + $LegacyGUIelements.WatchdogTimersRemoveButton.Height + 12))
$LegacyGUIelements.WatchdogTimersDGV.Name = "WatchdogTimersDGV"
$LegacyGUIelements.WatchdogTimersDGV.ReadOnly = $true
$LegacyGUIelements.WatchdogTimersDGV.RowHeadersVisible = $false
$LegacyGUIelements.WatchdogTimersDGV.SelectionMode = "FullRowSelect"
Set-DataGridViewDoubleBuffer -Grid $LegacyGUIelements.WatchdogTimersDGV -Enabled $true
$LegacyGUIelements.WatchdogTimersPageControls += $LegacyGUIelements.WatchdogTimersDGV

$LegacyGUIelements.StatusPage.Controls.AddRange(@($LegacyGUIelements.StatusPageControls))
$LegacyGUIelements.EarningsPage.Controls.AddRange(@($LegacyGUIelements.EarningsPageControls))
$LegacyGUIelements.MinersPage.Controls.AddRange(@($LegacyGUIelements.MinersPageControls))
$LegacyGUIelements.PoolsPage.Controls.AddRange(@($LegacyGUIelements.PoolsPageControls))
# $LegacyGUIelements.RigMonitorPage.Controls.AddRange(@($LegacyGUIelements.RigMonitorPageControls))
$LegacyGUIelements.SwitchingLogPage.Controls.AddRange(@($LegacyGUIelements.SwitchingLogPageControls))
$LegacyGUIelements.WatchdogTimersPage.Controls.AddRange(@($LegacyGUIelements.WatchdogTimersPageControls))

$LegacyGUIelements.TabControl = [System.Windows.Forms.TabControl]::new()
$LegacyGUIelements.TabControl.Appearance = "Buttons"
$LegacyGUIelements.TabControl.Font = [System.Drawing.Font]::new($Font2, 10)
$LegacyGUIelements.TabControl.Height = 0
$LegacyGUIelements.TabControl.Location = [System.Drawing.Point]::new(12, $LegacyGUIelements.MiningSummaryLabel.Bottom + 10)
$LegacyGUIelements.TabControl.Name = "TabControl"
$LegacyGUIelements.TabControl.ShowToolTips = $true
$LegacyGUIelements.TabControl.Padding = [System.Drawing.Point]::new(18, 6)
$LegacyGUIelements.TabControl.Width = 0
$LegacyGUIelements.TabControl.Add_Click(
    { 
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        Update-TabControl
        $LegacyGUIform.Cursor = [System.Windows.Forms.Cursors]::Normal
    }
)
# $LegacyGUIelements.TabControl.Controls.AddRange(@($LegacyGUIelements.StatusPage, $LegacyGUIelements.EarningsPage, $LegacyGUIelements.MinersPage, $LegacyGUIelements.PoolsPage, $LegacyGUIelements.RigMonitorPage, $LegacyGUIelements.SwitchingLogPage, $LegacyGUIelements.WatchdogTimersPage))
$LegacyGUIelements.TabControl.Controls.AddRange(@($LegacyGUIelements.StatusPage, $LegacyGUIelements.EarningsPage, $LegacyGUIelements.MinersPage, $LegacyGUIelements.PoolsPage, $LegacyGUIelements.SwitchingLogPage, $LegacyGUIelements.WatchdogTimersPage))

$LegacyGUIelements.Timer = [System.Windows.Forms.Timer]::new()
$LegacyGUIelements.Timer.Interval = 500
$LegacyGUIelements.Timer.Add_Tick(
    { 
        if ($Session.MinersRunning) { 
            # Set process priority to BelowNormal to avoid hashrate drops on systems with weak CPUs
            (Get-Process -Id $PID -ErrorAction Ignore).PriorityClass = "BelowNormal"
        }
        else { 
            (Get-Process -Id $PID -ErrorAction Ignore).PriorityClass = "Normal"
        }

        if ($Session.APIserver.IsListening) { 
            if ($LegacyGUIelements.EditConfigLink.Tag -ne "WebGUI") { 
                $LegacyGUIelements.EditConfigLink.Tag = "WebGUI"
                $LegacyGUIelements.EditConfigLink.Text = "Edit configuration in the web GUI"
            }
        }
        elseif ($LegacyGUIelements.EditConfigLink.Tag -ne "Edit-File") { 
            $LegacyGUIelements.EditConfigLink.Tag = "Edit-File"
            $LegacyGUIelements.EditConfigLink.Text = "Edit configuration file '$($Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))' in notepad"
        }

        # If something (pause button, idle timer, web GUI/config) has set the RestartCycle flag, stop and start mining to switch modes immediately
        if ($Session.RestartCycle) { 
            $Session.RestartCycle = $false

            if ($Session.NewMiningStatus -ne $Session.MiningStatus) { 

                if ($Session.NewMiningStatus -eq "Running" -and $Session.Config.IdleDetection) { Write-Message -Level Verbose "Idle detection is enabled. Mining will get suspended on any keyboard or mouse activity." }

                # Keep only the last 10 files
                Get-ChildItem -Path ".\Logs\$($Session.Branding.ProductLabel)_*.log" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse
                Get-ChildItem -Path ".\Logs\SwitchingLog_*.csv" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse
                Get-ChildItem -Path "$($Session.ConfigFile)_*.backup" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse

                if ($Session.Config.Proxy -eq "") { 
                    $PSDefaultParameterValues.Remove("*:Proxy")
                }
                else { 
                    $PSDefaultParameterValues["*:Proxy"] = $Session.Config.Proxy
                }

                Stop-Brain @($Session.Brains.Keys.Where({ $_ -notin (Get-PoolBaseName $Session.Config.PoolName) }))

                switch ($Session.NewMiningStatus) { 
                    "Idle" { 
                        $LegacyGUIelements.ButtonPause.Enabled = $false
                        $LegacyGUIelements.ButtonStart.Enabled = $false
                        $LegacyGUIelements.ButtonStop.Enabled = $false

                        if ($Session.MiningStatus) { 
                            $LegacyGUIelements.TabControl.SelectTab($LegacyGUIelements.StatusPage)
                            Write-Host ""
                            $Message = "'Stop mining' button clicked."
                            Write-Message -Level Info $Message
                            $Session.Summary = $Message
                            Remove-Variable Message

                            Update-GUIstatus

                            Stop-CoreCycle
                            Stop-Brain
                            Stop-BalancesTracker

                            # if ($Session.Config.ReportToServer) { Write-MonitoringData }
                        }

                        $LegacyGUIelements.ButtonPause.Enabled = $true
                        $LegacyGUIelements.ButtonStart.Enabled = $true

                        if (-not $Session.ConfigurationHasChangedDuringUpdate) { 
                            Write-Host ""
                            $Message = "$($Session.Branding.ProductLabel) is stopped."
                            Write-Message -Level Info $Message
                            $Message = "$Message Click the 'Start mining' button to make money."
                            $Session.Summary = $Message
                            Remove-Variable Message
                            $Session.RefreshTimestamp = (Get-Date -Format "G")
                        }
                        break
                    }
                    "Paused" { 
                        $LegacyGUIelements.ButtonPause.Enabled = $false
                        $LegacyGUIelements.ButtonStart.Enabled = $false
                        $LegacyGUIelements.ButtonStop.Enabled = $false

                        if ($Session.MiningStatus) { 
                            $LegacyGUIelements.TabControl.SelectTab($LegacyGUIelements.StatusPage)
                            Write-Host ""
                            $Message = "'Pause mining' button clicked."
                            Write-Message -Level Info $Message
                            $Session.Summary = $Message
                            Remove-Variable Message

                            Update-GUIstatus

                            Stop-CoreCycle
                            Start-Brain @(Get-PoolBaseName $Session.Config.PoolName)
                            if ($Session.Config.BalancesTrackerPollInterval -gt 0) { Start-BalancesTracker } else { Stop-BalancesTracker }

                            # if ($Session.Config.ReportToServer) { Write-MonitoringData }
                            $Session.RefreshTimestamp = (Get-Date -Format "G")
                        }

                        $LegacyGUIelements.ButtonStart.Enabled = $true
                        $LegacyGUIelements.ButtonStop.Enabled = $true

                        Write-Host ""
                        $Message = "$($Session.Branding.ProductLabel) is paused."
                        Write-Message -Level Info $Message
                        $Message = "$Message Click the 'Start mining' button to make money.<br>"
                        ((@(if ($Session.Config.UsemBTC) { "mBTC" } else { ($Session.Config.PayoutCurrency) }) + @($Session.Config.ExtraCurrencies)) | Select-Object -Unique).Where({ $Session.Rates.$_.($Session.Config.FIATcurrency) }).ForEach(
                            { 
                                $Message = "$($Message)1 $_ = {0:N$(Get-DecimalsFromValue -Value $Session.Rates.$_.($Session.Config.FIATcurrency) -DecimalsMax $Session.Config.DecimalsMax)} $($Session.Config.FIATcurrency)&ensp;&ensp;&ensp;" -f $Session.Rates.$_.($Session.Config.FIATcurrency)
                            }
                        )
                        $Session.Summary = $Message
                        Remove-Variable Message
                        break
                    }
                    "Running" { 
                        $LegacyGUIelements.ButtonPause.Enabled = $false
                        $LegacyGUIelements.ButtonStart.Enabled = $false
                        $LegacyGUIelements.ButtonStop.Enabled = $false


                        if ($Session.MiningStatus) { 
                            $LegacyGUIelements.TabControl.SelectTab($LegacyGUIelements.StatusPage)
                            Write-Host ""
                            $Message = "'Start mining' button clicked."
                            Write-Message -Level Info $Message
                            $Message = "$Message Mining processes are starting..."
                            $Session.Summary = $Message
                            $Session.RefreshTimestamp = (Get-Date -Format "G")
                            Remove-Variable Message
                            Update-GUIstatus
                        }

                        Start-Brain @(Get-PoolBaseName $Session.Config.PoolName)
                        Start-CoreCycle
                        if ($Session.Config.BalancesTrackerPollInterval -gt 0) { Start-BalancesTracker } else { Stop-BalancesTracker }

                        $LegacyGUIelements.ButtonPause.Enabled = $true
                        $LegacyGUIelements.ButtonStop.Enabled = $true
                        if (-not $Session.MiningStatus) { $host.UI.RawUI.FlushInputBuffer() }
                        break
                    }
                }
                $Session.MiningStatus = $Session.NewMiningStatus
            }
            Update-GUIstatus

            # Remove all closed runspaces
            (Get-Runspace).Where({ $_.RunspaceStateInfo.State -eq "Closed" }).ForEach({ $_.Dispose() })

            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
        }

        if ($Session.NewMiningStatus -ne "Idle") { 

            # Check internet connection every 10 minutes
            if ($Session.NetworkChecked -lt [DateTime]::Now.ToUniversalTime().AddMinutes(-10)) { 
                $NetworkInterface = (Get-NetConnectionProfile).Where({ $_.IPv4Connectivity -eq "Internet" }).InterfaceIndex
                $Session.MyIPaddress = if ($NetworkInterface) { (Get-NetIPAddress -InterfaceIndex $NetworkInterface -AddressFamily IPV4).IPAddress } else { $null }
                Remove-Variable NetworkInterface
                if ($Session.MyIPaddress) { $Session.NetworkChecked = [DateTime]::Now.ToUniversalTime() }
            }

            if ($Session.MyIPaddress) { 
                # Read exchange rates at least once every hour
                if (($Session.MiningStatus -eq "Paused" -and $Session.Config.FIATcurrency -notin $Session.AllCurrencies) -or (-not $Session.BalancesTrackerRunning -and $Session.RatesUpdated -lt [DateTime]::Now.ToUniversalTime().AddMinutes(-((60, $Session.Config.RatesUpdateInterval) | Measure-Object -Minimum).Minimum))) { Get-Rate }
            }
            else { 
                Write-Message -Level Error "No internet connection - will retry in $($Session.Config.Interval) seconds..."
                Start-Sleep -Seconds $Session.Config.Interval
            }

            # Start balances tracker
            if ($Session.MyIPaddress -and $Session.Config.BalancesTrackerPollInterval -gt 0) { Start-BalancesTracker } else { Stop-BalancesTracker }
        }

        if ($Session.Config.ShowConsole) { 
            Show-Console
            if ([System.Console]::KeyAvailable) { 
                $KeyPressed = ([System.Console]::ReadKey($true))

                if ($Session.NewMiningStatus -eq "Running" -and $KeyPressed.Key -eq "p" -and $KeyPressed.Modifiers -eq 5 <# <Ctrl><Alt> #>) { 
                    if (-not $Global:CoreCycleRunspace.Job.IsCompleted -eq $false) { 
                        # Core is complete / gone. Cycle cannot be suspended anymore
                        $Session.SuspendCycle = $false
                    }
                    else { 
                        $Session.SuspendCycle = -not $Session.SuspendCycle
                        if ($Session.SuspendCycle) { 
                            $Message = "'<Ctrl><Alt>P' pressed. Core cycle is suspended until you press '<Ctrl><Alt>P' again."
                            $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Blue
                            $LegacyGUIelements.MiningSummaryLabel.Text = $Message
                            $LegacyGUIelements.ButtonPause.Enabled = $false
                            Write-Host $Message -ForegroundColor Cyan
                        }
                        else { 
                            $Message = "'<Ctrl><Alt>P' pressed. Core cycle is running again."
                            $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Blue
                            $LegacyGUIelements.MiningSummaryLabel.Text = $Message
                            $LegacyGUIelements.ButtonPause.Enabled = $true
                            Write-Host $Message -ForegroundColor Cyan
                        }
                        Remove-Variable Message
                    }
                }
                else { 
                    switch ($KeyPressed.KeyChar) { 
                        " " { 
                            $Session.RefreshNeeded = $true
                            break
                        }
                        "1" { 
                            $Config.ShowPoolBalances = -not $Config.ShowPoolBalances
                            Write-Host "`nKey '$_' pressed: Listing pool balances is now " -NoNewline; if ($Config.ShowPoolBalances) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                            break
                        }
                        "2" { 
                            $Config.ShowAllOptimalMiners = -not $Config.ShowAllOptimalMiners
                            Write-Host "`nKey '$_' pressed: Listing all optimal miners is now " -NoNewline; if ($Config.ShowAllOptimalMiners) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                            break
                        }
                        "3" { 
                            $Config.UIstyle = if ($Config.UIstyle -eq "light") { "full" } else { "light" }
                            $Config.UIstyle = $Config.UIstyle
                            Write-Host "`nKey '$_' pressed: UI style is now " -NoNewline; Write-Host "$($Config.UIstyle)" -ForegroundColor Blue -NoNewline; Write-Host " (Information about miners run in the past 24hrs, failed miners in the past 24hrs & watchdog timers will " -NoNewline; if ($Config.UIstyle -eq "light") { Write-Host "not " -ForegroundColor Red -NoNewline }; Write-Host "be shown)"
                            break
                        }
                        "4" { 
                            $Config.LegacyGUI = -not $Config.LegacyGUI
                            Write-Host "`nKey '$_' pressed: Legacy GUI is now " -NoNewline; if ($Config.LegacyGUI) { Write-Host "enabled" -ForegroundColor Green } else { Write-Host "disabled" -ForegroundColor DarkYellow }
                            if ($LegacyGUIform.ShowInTaskbar -ne $Config.LegacyGUI) { 
                                if ($Config.LegacyGUI) { 
                                    $LegacyGUIform.WindowState = $Session.WindowStateOriginal
                                    $LegacyGUIform.ShowInTaskbar = $true
                                    Update-TabControl
                                }
                                elseif ($LegacyGUIform.WindowState -ne [System.Windows.Forms.FormWindowState]::Minimized) { 
                                    $Session.WindowStateOriginal = $LegacyGUIform.WindowState
                                    $LegacyGUIform.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
                                    $LegacyGUIform.ShowInTaskbar = $false
                                }
                            }
                        }
                        "5" { 
                            Write-Host "`nKey '$_' pressed: " -NoNewline
                            if ($Session.Config.WebGUI) { Stop-APIserver } else { Start-APIserver }
                            $Session.Config.WebGUI = [Boolean]($Session.APIport)
                            break
                        }
                        "a" { 
                            $Config.ShowColumnAccuracy = -not $Config.ShowColumnAccuracy
                            Write-Host "`nKey '$_' pressed: '" -NoNewline; Write-Host "A" -ForegroundColor Cyan -NoNewline; Write-Host "ccuracy' column visibility is now " -NoNewline; if ($Config.ShowColumnAccuracy) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                            break
                        }
                        "b" { 
                            $Config.ShowColumnEarningsBias = -not $Config.ShowColumnEarningsBias
                            Write-Host "`nKey '$_' pressed: 'Earnings " -NoNewline; Write-Host "b" -ForegroundColor Cyan -NoNewline; Write-Host "ias' column visibility is now " -NoNewline; if ($Config.ShowColumnEarningsBias) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                            break
                        }
                        "c" { 
                            $Config.ShowColumnCurrency = -not $Config.ShowColumnCurrency
                            Write-Host "`nKey '$_' pressed: '" -NoNewline; Write-Host "C" -ForegroundColor Cyan -NoNewline; Write-Host "urrency' column visibility is now " -NoNewline; if ($Config.ShowColumnCurrency) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                            break
                        }
                        "e" { 
                            $Config.ShowColumnEarnings = -not $Config.ShowColumnEarnings
                            $Config.ShowColumnEarnings = $Config.ShowColumnEarnings
                            Write-Host "`nKey '$_' pressed: '" -NoNewline; Write-Host "E" -ForegroundColor Cyan -NoNewline; Write-Host "arnings' column visibility is now " -NoNewline; if ($Config.ShowColumnEarnings) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                            break
                        }
                        "h" { 
                            Write-Host "`nHot key legend:                              Status:"
                            Write-Host "1: Toggle listing pool balances              [" -NoNewline; if ($Config.ShowPoolBalances) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                            Write-Host "2: Toggle listing all optimal miners         [" -NoNewline; if ($Config.ShowAllOptimalMiners) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                            Write-Host "3: Toggle UI style [full or light]           [" -NoNewline; Write-Host "$($Config.UIstyle)" -ForegroundColor Blue -NoNewline; Write-Host "]"
                            Write-Host "4: Toggle legacy GUI                         [" -NoNewline; if ($Config.LegacyGUI) { Write-Host "enabled" -ForegroundColor Green -NoNewline } else { Write-Host "disabled" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                            Write-Host "5: Toggle API server and web GUI             [" -NoNewline; if ($Session.APIport) { Write-Host "running on TCP port $($Session.APIport)" -ForegroundColor Green -NoNewline } elseif ($Session.Config.APIport -and $Session.Config.WebGUI -and -not $Session.APIport) { Write-Host "error" -ForegroundColor Red -NoNewline } else { Write-Host "disabled" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                            Write-Host
                            Write-Host "a: Toggle '" -NoNewline; Write-Host "A" -ForegroundColor Cyan -NoNewline; Write-Host "ccuracy' column visibility       [" -NoNewline; if ($Config.ShowColumnAccuracy) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                            Write-Host "b: Toggle 'Earnings " -NoNewline; Write-Host "b" -ForegroundColor Cyan -NoNewline; Write-Host "ias' column visibility  [" -NoNewline; if ($Config.ShowColumnEarningsBias) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                            Write-Host "c: Toggle '" -NoNewline; Write-Host "C" -ForegroundColor Cyan -NoNewline; Write-Host "urrency' column visibility       [" -NoNewline; if ($Config.ShowColumnCurrency) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                            Write-Host "e: Toggle '" -NoNewline; Write-Host "E" -ForegroundColor Cyan -NoNewline; Write-Host "arnings' column visibility       [" -NoNewline; if ($Config.ShowColumnEarnings) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                            Write-Host "m: Toggle '" -NoNewline; Write-Host "M" -ForegroundColor Cyan -NoNewline; Write-Host "iner fee' column visibility      [" -NoNewline; if ($Config.ShowColumnMinerFee) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                            Write-Host "n: Toggle 'Coin" -NoNewline; Write-Host "N" -ForegroundColor Cyan -NoNewline; Write-Host "ame' column visibility       [" -NoNewline; if ($Config.ShowColumnCoinName) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                            if ($Session.CalculatePowerCost) { 
                                Write-Host "o: Toggle 'Power c" -NoNewline; Write-Host "o" -ForegroundColor Cyan -NoNewline; Write-Host "st' column visibility     [" -NoNewline; if ($Config.ShowColumnPowerCost) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                            }
                            Write-Host "p: Toggle '" -NoNewline; Write-Host "P" -ForegroundColor Cyan -NoNewline; Write-Host "ool fee' column visibility       [" -NoNewline; if ($Config.ShowColumnPoolFee) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                            if ($Session.CalculatePowerCost) { 
                                Write-Host "r: Toggle 'P" -NoNewline; Write-Host "r" -ForegroundColor Cyan -NoNewline; Write-Host "ofit bias' column visibility    [" -NoNewline; if ($Config.ShowColumnProfitBias) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                            }
                            Write-Host "s: Toggle 'Ha" -NoNewline; Write-Host "s" -ForegroundColor Cyan -NoNewline; Write-Host "hrate(s)' column visibility    [" -NoNewline; if ($Config.ShowColumnHashrate) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                            if ($Session.CalculatePowerCost) { 
                                Write-Host "t: Toggle 'Profi" -NoNewline; Write-Host "t" -ForegroundColor Cyan -NoNewline; Write-Host "' column visibility         [" -NoNewline; if ($Config.ShowColumnProfit) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                            }
                            Write-Host "u: Toggle '" -NoNewline; Write-Host "U" -ForegroundColor Cyan -NoNewline; Write-Host "ser' column visibility           [" -NoNewline; if ($Config.ShowColumnUser) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                            if ($Session.CalculatePowerCost) { 
                                Write-Host "w: Toggle 'Po" -NoNewline; Write-Host "w" -ForegroundColor Cyan -NoNewline; Write-Host "er (W)' column visibility      [" -NoNewline; if ($Session.Config.CalculatePowerCost -and $Config.ShowColumnPowerConsumption) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                            }
                            Write-Host "`nq: " -NoNewline; Write-Host "Q" -ForegroundColor Blue -NoNewline; Write-Host "uit $($Session.Branding.ProductLabel)"
                            break
                        }
                        "m" { 
                            $Config.ShowColumnMinerFee = -not $Config.ShowColumnMinerFee
                            Write-Host "`nKey '$_' pressed: '" -NoNewline; Write-Host "M" -ForegroundColor Cyan -NoNewline; Write-Host "iner Fees' column visibility is now " -NoNewline; if ($Config.ShowColumnMinerFee) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                            break
                        }
                        "n" { 
                            $Config.ShowColumnCoinName = -not $Config.ShowColumnCoinName
                            Write-Host "`nKey '$_' pressed: 'Coin" -NoNewline; Write-Host "N" -ForegroundColor Cyan -NoNewline; Write-Host "ame' column visibility is now " -NoNewline; if ($Config.ShowColumnCoinName) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                            break
                        }
                        "o" { 
                            if ($Session.CalculatePowerCost) { 
                                $Config.ShowColumnPowerCost = -not $Config.ShowColumnPowerCost
                                Write-Host "`nKey '$_' pressed: 'Power c" -NoNewline; Write-Host "o" -ForegroundColor Cyan -NoNewline; Write-Host "st' column visibility is now " -NoNewline; if ($Config.ShowColumnPowerCost) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                            }
                            break
                        }
                        "p" { 
                            $Config.ShowColumnPoolFee = -not $Config.ShowColumnPoolFee
                            Write-Host "`nKey '$_' pressed: '"-NoNewline; Write-Host "P" -ForegroundColor Cyan -NoNewline; Write-Host "ool fees' column visibility is now " -NoNewline; if ($Config.ShowColumnPoolFee) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                            break
                        }
                        "q" { 
                            if (-not $Session.PopupActive) { 
                                $Session.PopupActive = $true
                                $Session.PopupInput = (New-Object -ComObject Wscript.Shell).Popup("Do you want to shut down $($Session.Branding.ProductLabel)?", 0, "$($Session.Branding.ProductLabel)", (4 + 32 + 4096))
                                if ($Session.PopupInput -eq 6) { 
                                    Write-Host
                                    Exit-UGminer
                                }
                                $Session.Remove("PopupActive")
                            }
                        }
                        "r" { 
                            if ($Session.CalculatePowerCost) { 
                                $Config.ShowColumnProfitBias = -not $Config.ShowColumnProfitBias
                                Write-Host "`nKey '$_' pressed: 'P" -NoNewline; Write-Host "r" -ForegroundColor Cyan -NoNewline; Write-Host "ofit bias' column visibility is now " -NoNewline; if ($Config.ShowColumnProfitBias) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                            }
                            break
                        }
                        "s" { 
                            $Config.ShowColumnHashrate = -not $Config.ShowColumnHashrate
                            Write-Host "`nKey '$_' pressed: 'Ha" -NoNewline; Write-Host "s" -ForegroundColor Cyan -NoNewline; Write-Host "hrates(s)' column visibility is now " -NoNewline; if ($Config.ShowColumnHashrate) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                            break
                        }
                        "t" { 
                            if ($Session.CalculatePowerCost) { 
                                $Config.ShowColumnProfit = -not $Config.ShowColumnProfit
                                Write-Host "`nKey '$_' pressed: 'Profi" -NoNewline; Write-Host "t" -ForegroundColor Cyan -NoNewline; Write-Host "' column visibility is now " -NoNewline; if ($Config.ShowColumnProfit) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                            }
                            break
                        }
                        "u" { 
                            $Config.ShowColumnUser = -not $Config.ShowColumnUser
                            Write-Host "`nKey '$_' pressed: '" -NoNewline; Write-Host "U" -ForegroundColor Cyan -NoNewline; Write-Host "ser' column visibility is now " -NoNewline; if ($Config.ShowColumnUser) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                            break
                        }
                        "w" { 
                            if ($Session.CalculatePowerCost) { 
                                $Config.ShowColumnPowerConsumption = -not $Config.ShowColumnPowerConsumption
                                Write-Host "`nKey '$_' pressed: 'Po" -NoNewline; Write-Host "w" -ForegroundColor Cyan -NoNewline; Write-Host "er (W)' column visibility is now " -NoNewline; if ($Config.ShowColumnPowerConsumption) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                            }
                            break
                        }
                    }
                }
                Remove-Variable KeyPressed
                $host.UI.RawUI.FlushInputBuffer()
            }
        }
        else { Hide-Console }

        if ($Session.MiningStatus -eq "Running") { 
            if ($Session.Config.IdleDetection) { 
                if ([Math]::Round([PInvoke.Win32.UserInput]::IdleTime.TotalSeconds) -gt $Session.Config.IdleSec) { 
                    # System was idle long enough, start mining
                    if (-not $Global:CoreCycleRunspace) { 
                        $Message = "System was idle for $($Session.Config.IdleSec) second$(if ($Session.Config.IdleSec -ne 1) { "s" }).<br>Resuming mining..."
                        Write-Message -Level Verbose ($Message -replace "<br>", " ")
                        $Session.Summary = $Message
                        $Session.RefreshTimestamp = (Get-Date -Format "G")

                        Start-CoreCycle

                        Update-GUIstatus
                        $LegacyGUIelements.MiningSummaryLabel.Text = ($Message -replace "&", "&&" -split "<br>") -join "`r`n"
                        $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Black

                        Remove-Variable Message
                    }
                }
                elseif ($Global:CoreCycleRunspace.Job.IsCompleted -eq $false) { 
                    $Message = "System activity detected."
                    Write-Message -Level Verbose $Message
                    $Session.Summary = $Message

                    Update-GUIstatus
                    $LegacyGUIelements.MiningSummaryLabel.Text = ($Message -replace "&", "&&" -split "<br>") -join "`r`n"
                    $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Black

                    Stop-CoreCycle

                    $Message = "Mining is suspended until system is idle for $($Session.Config.IdleSec) second$(if ($Session.Config.IdleSec -ne 1) { "s" })."
                    Write-Message -Level Verbose $Message
                    $Session.Summary = $Message

                    if ($LegacyGUIform.ShowInTaskbar) { 
                        Update-GUIstatus
                        $LegacyGUIelements.MiningSummaryLabel.Text = ($Message -replace "&", "&&" -split "<br>") -join "`r`n"
                        $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Black
                    }
                    else { 
                        $Session.RefreshTimestamp = (Get-Date -Format "G")
                    }
                    Remove-Variable Message

                    $Session.RefreshNeeded = $true
                }
                else { 
                    # Read-Config will read and apply configuration if configuration files have changed
                    Read-Config -ConfigFile $Session.ConfigFile -PoolsConfigFile $Session.PoolsConfigFile
                }
            }
            elseif ($Global:CoreCycleRunspace.Job.IsCompleted -ne $false) { 
                if ($Global:CoreCycleRunspace.Job.IsCompleted -eq $true) { 
                    Write-Message -Level Warn "Core cycle stopped - restarting..."
                    Stop-CoreCycle
                }
                Start-CoreCycle
                Update-GUIstatus
            }
            elseif (-not $Session.SuspendCycle -and -not $Session.MinersBenchmarkingOrMeasuring -and $Session.BeginCycleTimeCycleTime -and [DateTime]::Now.ToUniversalTime() -gt $Session.BeginCycleTimeCycleTime.AddSeconds(1.5 * $Session.Config.Interval)) { 
                # Core watchdog. Sometimes core loop gets stuck
                Write-Message -Level Warn "Core cycle is stuck - restarting..."
                Stop-CoreCycle
                Start-CoreCycle
                Update-GUIstatus
            }
        }
        else { 
            # Read-Config will read and apply configuration if configuration files have changed
            Read-Config -ConfigFile $Session.ConfigFile -PoolsConfigFile $Session.PoolsConfigFile
        }

        if ($Session.RefreshBalancesNeeded) { 
            $Session.RefreshBalancesNeeded = $false
            if ($LegacyGUIform.Visible -and $LegacyGUIelements.TabControl.SelectedTab.Text -eq "Earnings and balances") { Update-GUIstatus }
        }

        if ($Session.RefreshNeeded) { 
            $Session.RefreshNeeded = $false
            $Session.RefreshTimestamp = (Get-Date -Format "G")

            $host.UI.RawUI.WindowTitle = "$($Session.Branding.ProductLabel) $($Session.Branding.Version) - Runtime: {0:dd} days {0:hh} hrs {0:mm} mins - Path: $($Session.MainPath)" -f [TimeSpan]([DateTime]::Now.ToUniversalTime() - $Session.ScriptStartTime)

            # If API port has changed, Start-APIserver will restart server
            if ($Session.Config.WebGUI) { Start-APIserver } else { Stop-APIserver }

            Update-GUIstatus

            if ($Session.Config.ShowConsole) { 
                if ($Session.Miners) { Clear-Host }

                # Get and display earnings stats
                if ($Config.ShowPoolBalances) { 
                    $Session.Balances.Values.ForEach(
                        { 
                            if ($_.Currency -eq "BTC" -and $Session.Config.UsemBTC) { $Currency = "mBTC"; $mBTCfactorCurrency = 1000 } else { $Currency = $_.Currency; $mBTCfactorCurrency = 1 }
                            $PayoutCurrency = if ($_.PayoutThresholdCurrency) { $_.PayoutThresholdCurrency } else { $_.Currency }
                            if ($PayoutCurrency -eq "BTC" -and $Session.Config.UsemBTC) { $PayoutCurrency = "mBTC"; $mBTCfactorPayoutCurrency = 1000 } else { $mBTCfactorPayoutCurrency = 1 }
                            if ($Currency -ne $PayoutCurrency) { 
                                # Payout currency is different from asset currency
                                if ($Session.Rates.$Currency -and $Session.Rates.$Currency.$PayoutCurrency) { 
                                    $Percentage = ($_.Balance / $_.PayoutThreshold / $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency).toString("P2")
                                }
                                else { 
                                    $Percentage = "Unknown %"
                                }
                            }
                            else { 
                                $Percentage = ($_.Balance / $_.PayoutThreshold).ToString("P2")
                            }

                            Write-Host "$($_.Pool) [$($_.Wallet)]" -ForegroundColor Green
                            if ($Session.Config.BalancesShowSums) { 
                                Write-Host ("Earnings last 1 hour:   {0:n$($Session.Config.DecimalsMax)} {1}$(if ($Session.Rates.$Currency.($Session.Config.FIATcurrency)) { " (≈{2:n$($Session.Config.DecimalsMax)} {3}$(if ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.Config.DecimalsMax)} {5}" }))" })" -f ($_.Growth1 * $mBTCfactorCurrency), $Currency, ($_.Growth1 * $Session.Rates.$Currency.($Session.Config.FIATcurrency)), $Session.Config.FIATcurrency, ($_.Growth1 * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency)
                                Write-Host ("Earnings last 6 hours:  {0:n$($Session.Config.DecimalsMax)} {1}$(if ($Session.Rates.$Currency.($Session.Config.FIATcurrency)) { " (≈{2:n$($Session.Config.DecimalsMax)} {3}$(if ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.Config.DecimalsMax)} {5}" }))" })" -f ($_.Growth6 * $mBTCfactorCurrency), $Currency, ($_.Growth6 * $Session.Rates.$Currency.($Session.Config.FIATcurrency)), $Session.Config.FIATcurrency, ($_.Growth6 * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency)
                                Write-Host ("Earnings last 24 hours: {0:n$($Session.Config.DecimalsMax)} {1}$(if ($Session.Rates.$Currency.($Session.Config.FIATcurrency)) { " (≈{2:n$($Session.Config.DecimalsMax)} {3}$(if ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.Config.DecimalsMax)} {5}" }))" })" -f ($_.Growth24 * $mBTCfactorCurrency), $Currency, ($_.Growth24 * $Session.Rates.$Currency.($Session.Config.FIATcurrency)), $Session.Config.FIATcurrency, ($_.Growth24 * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency)
                                Write-Host ("Earnings last 7 days:   {0:n$($Session.Config.DecimalsMax)} {1}$(if ($Session.Rates.$Currency.($Session.Config.FIATcurrency)) { " (≈{2:n$($Session.Config.DecimalsMax)} {3}$(if ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.Config.DecimalsMax)} {5}" }))" })" -f ($_.Growth168 * $mBTCfactorCurrency), $Currency, ($_.Growth168 * $Session.Rates.$Currency.($Session.Config.FIATcurrency)), $Session.Config.FIATcurrency, ($_.Growth168 * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency)
                                Write-Host ("Earnings last 30 days:  {0:n$($Session.Config.DecimalsMax)} {1}$(if ($Session.Rates.$Currency.($Session.Config.FIATcurrency)) { " (≈{2:n$($Session.Config.DecimalsMax)} {3}$(if ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.Config.DecimalsMax)} {5}" }))" })" -f ($_.Growth720 * $mBTCfactorCurrency), $Currency, ($_.Growth720 * $Session.Rates.$Currency.($Session.Config.FIATcurrency)), $Session.Config.FIATcurrency, ($_.Growth720 * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency)
                            }
                            if ($Session.Config.BalancesShowAverages) { 
                                Write-Host ("Average/hour:           {0:n$($Session.Config.DecimalsMax)} {1}$(if ($Session.Rates.$Currency.($Session.Config.FIATcurrency)) { " (≈{2:n$($Session.Config.DecimalsMax)} {3}$(if ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.Config.DecimalsMax)} {5}" }))" })" -f ($_.AvgHourlyGrowth * $mBTCfactorCurrency), $Currency, ($_.AvgHourlyGrowth * $Session.Rates.$Currency.($Session.Config.FIATcurrency)), $Session.Config.FIATcurrency, ($_.AvgHourlyGrowth * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency)
                                Write-Host ("Average/day:            {0:n$($Session.Config.DecimalsMax)} {1}$(if ($Session.Rates.$Currency.($Session.Config.FIATcurrency)) { " (≈{2:n$($Session.Config.DecimalsMax)} {3}$(if ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.Config.DecimalsMax)} {5}" }))" })" -f ($_.AvgDailyGrowth * $mBTCfactorCurrency), $Currency, ($_.AvgDailyGrowth * $Session.Rates.$Currency.($Session.Config.FIATcurrency)), $Session.Config.FIATcurrency, ($_.AvgDailyGrowth * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency)
                                Write-Host ("Average/week:           {0:n$($Session.Config.DecimalsMax)} {1}$(if ($Session.Rates.$Currency.($Session.Config.FIATcurrency)) { " (≈{2:n$($Session.Config.DecimalsMax)} {3}$(if ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.Config.DecimalsMax)} {5}" }))" })" -f ($_.AvgWeeklyGrowth * $mBTCfactorCurrency), $Currency, ($_.AvgWeeklyGrowth * $Session.Rates.$Currency.($Session.Config.FIATcurrency)), $Session.Config.FIATcurrency, ($_.AvgWeeklyGrowth * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency)
                            }
                            Write-Host "Balance:                " -NoNewline; Write-Host ("{0:n$($Session.Config.DecimalsMax)} {1}$(if ($Session.Rates.$Currency.($Session.Config.FIATcurrency)) { " (≈{2:n$($Session.Config.DecimalsMax)} {3}$(if ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.Config.DecimalsMax)} {5}" }))" })" -f ($_.Balance * $mBTCfactorCurrency), $Currency, ($_.Balance * $Session.Rates.$Currency.($Session.Config.FIATcurrency)), $Session.Config.FIATcurrency, ($_.Balance * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency) -ForegroundColor Yellow
                            Write-Host ("{0} of {1:n$($Session.Config.DecimalsMax)} {2} payment threshold; projected payment date: $(if ($_.ProjectedPayDate -is [DateTime]) { $_.ProjectedPayDate.ToString("G") } else { $_.ProjectedPayDate.ToLower() }); data updated: $($_.LastUpdated.ToString().ToLower())`n" -f $Percentage, ($_.PayoutThreshold * $mBTCfactorPayoutCurrency), $PayoutCurrency)
                        }
                    )
                    Remove-Variable Currency, mBTCfactorCurrency, mBTCfactorPayoutCurrency, Percentage, PayoutCurrency -ErrorAction Ignore
                }

                if ($Session.MyIPaddress) { 
                    if ($Session.MiningStatus -eq "Running" -and $Session.Miners.Where({ $_.Available })) { 
                        # Miner list format
                        [System.Collections.ArrayList]$MinerTable = @(
                            @{ Label = "Miner"; Expression = { $_.Name } }
                            if ($Config.ShowColumnMinerFee -and $Session.Miners.Workers.Fee) { @{ Label = "Miner fee"; Expression = { $_.Workers.ForEach({ "{0:P2}" -f [Double]$_.Fee }) }; Align = "right" } }
                            if ($Config.ShowColumnEarningsBias) { @{ Label = "Earnings bias"; Expression = { if ([Double]::IsNaN($_.Earnings_Bias)) { "n/a" } else { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Earnings_Bias * $Session.Rates.BTC.($Session.Config.FIATcurrency)) } }; Align = "right" } }
                            if ($Config.ShowColumnEarnings) { @{ Label = "Earnings"; Expression = { if ([Double]::IsNaN($_.Earnings)) { "n/a" } else { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Earnings * $Session.Rates.BTC.($Session.Config.FIATcurrency)) } }; Align = "right" } }
                            if ($Config.ShowColumnPowerCost -and $Session.Config.CalculatePowerCost -and $Session.MiningPowerCost) { @{ Label = "Power cost"; Expression = { if ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } else { "-{0:n$($Session.Config.DecimalsMax)}" -f ($_.PowerCost * $Session.Rates.BTC.($Session.Config.FIATcurrency)) } }; Align = "right" } }
                            if ($Config.ShowColumnProfitBias -and $Session.MiningPowerCost) { @{ Label = "Profit bias"; Expression = { if ([Double]::IsNaN($_.Profit_Bias)) { "n/a" } else { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Profit_Bias * $Session.Rates.BTC.($Session.Config.FIATcurrency)) } }; Align = "right" } }
                            if ($Config.ShowColumnProfit -and $Session.MiningPowerCost) { @{ Label = "Profit"; Expression = { if ([Double]::IsNaN($_.Profit)) { "n/a" } else { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Profit * $Session.Rates.BTC.($Session.Config.FIATcurrency)) } }; Align = "right" } }
                            if ($Config.ShowColumnPowerConsumption -and $Session.Config.CalculatePowerCost) { @{ Label = "Power (W)"; Expression = { if ($_.MeasurePowerConsumption) { if ($_.Status -eq "Running") { "Measuring..." } else { "Unmeasured" } } else { if ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } else { "$($_.PowerConsumption.ToString("N2"))" } } }; Align = "right" } }
                            if ($Config.ShowColumnAccuracy) { @{ Label = "Accuracy"; Expression = { $_.Workers.ForEach({ "{0:P0}" -f [Double]$_.Pool.Accuracy }) }; Align = "right" } }
                            if ($Config.ShowColumnPoolFee -and $Session.Miners.Workers.Pool.Fee) { @{ Label = "Pool fee"; Expression = { $_.Workers.ForEach({ "{0:P2}" -f [Double]$_.Pool.Fee }) }; Align = "right" } }
                            if ($Config.ShowColumnHashrate) { @{ Label = "Hashrate"; Expression = { if ($_.Benchmark) { if ($_.Status -eq "Running") { "Benchmarking..." } else { "Benchmark pending" } } else { $_.Workers.ForEach({ $_.Hashrate | ConvertTo-Hash }) } }; Align = "right" } }
                            if ($Config.ShowColumnUser) { @{ Label = "User"; Expression = { $_.Workers.Pool.User } } }
                            if ($Config.ShowColumnCurrency) { @{ Label = "Currency"; Expression = { if ($_.Workers.Pool.Currency -match "\w") { $_.Workers.Pool.Currency } } } }
                            if ($Config.ShowColumnCoinName) { @{ Label = "CoinName"; Expression = { if ($_.Workers.Pool.CoinName -match "\w") { $_.Workers.Pool.CoinName } } } }
                        )
                        # Display top 5 optimal miners and all benchmarking of power consumption measuring miners
                        $Bias = if ($Session.CalculatePowerCost -and -not $Session.Config.IgnorePowerCost) { "Profit_Bias" } else { "Earnings_Bias" }
                        ($Session.Miners.Where({ $_.Optimal -or $_.Benchmark -or $_.MeasurePowerConsumption }) | Group-Object { $_.BaseName_Version_Device -replace ".+-" } | Sort-Object -Property Name).ForEach(
                            { 
                                $MinersDeviceGroup = $_.Group | Sort-Object { $_.Name, [String]$_.Algorithms } -Unique
                                $MinersDeviceGroupNeedingBenchmark = $MinersDeviceGroup.Where({ $_.Available -and $_.Benchmark })
                                $MinersDeviceGroupNeedingPowerConsumptionMeasurement = $MinersDeviceGroup.Where({ $_.Available -and $_.MeasurePowerConsumption })
                                $MinersDeviceGroup.Where(
                                    { 
                                        $Config.ShowAllOptimalMiners -or <# List all miners #>
                                        $MinersDeviceGroupNeedingBenchmark.Count -gt 0 -or
                                        $MinersDeviceGroupNeedingPowerConsumptionMeasurement.Count -gt 0 -or
                                        $_.$Bias -ge ($MinersDeviceGroup.$Bias | Sort-Object -Bottom 5 | Select-Object -Index 0) <# Always list at least the top 5 miners per device group #>
                                    }
                                ) | Sort-Object -Property @{ Expression = { $_.Benchmark }; Descending = $true }, @{ Expression = { $_.MeasurePowerConsumption }; Descending = $true }, @{ Expression = { $_.Best }; Descending = $true }, @{ Expression = { $_.KeepRunning }; Descending = $true }, @{ Expression = { $_.Prioritize }; Descending = $true }, @{ Expression = { $_.$Bias }; Descending = $true }, @{ Expression = { $_.Name }; Descending = $false }, @{ Expression = { $_.Algorithms[0] }; Descending = $false }, @{ Expression = { $_.Algorithms[1] }; Descending = $false } | 
                                    Format-Table $MinerTable -GroupBy @{ Name = "Device(s)"; Expression = { "$($MinersDeviceGroup[0].BaseName_Version_Device -replace ".+-")" } } -AutoSize | Out-Host
                            }
                        )
                        Remove-Variable Bias, MinerTable, MinersDeviceGroup, MinersDeviceGroupNeedingBenchmark, MinersDeviceGroupNeedingPowerConsumptionMeasurement -ErrorAction Ignore
                    }

                    if ($Session.MinersRunning) { 
                        Write-Host "`nRunning miner$(if ($Session.MinersBest.Count -ne 1) { "s" }):"
                        [System.Collections.ArrayList]$MinerTable = @(
                            @{ Label = "Name"; Expression = { $_.Name } }
                            if ($Config.ShowColumnPowerConsumption -and $Session.Config.CalculatePowerCost) { @{ Label = "Power (W)"; Expression = { if ([Double]::IsNaN($_.PowerConsumption_Live)) { "n/a" } else { "$($_.PowerConsumption_Live.ToString("N2"))" } }; Align = "right" } }
                            @{ Label = "Hashrate(s)"; Expression = { $_.Hashrates_Live.ForEach({ if ([Double]::IsNaN($_)) { "n/a" } else { $_ | ConvertTo-Hash } }) -join " & " }; Align = "right" }
                            @{ Label = "Active (this run)"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f ([DateTime]::Now.ToUniversalTime() - $_.BeginTime) } }
                            @{ Label = "Active (total)"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f ($_.TotalMiningDuration) } }
                            @{ Label = "Cnt"; Expression = { switch ($_.Activated) { 0 { "Never"; break } 1 { "Once"; break } default { $_ } } } }
                            @{ Label = "Device(s)"; Expression = { $_.BaseName_Version_Device -replace ".+-" } }
                            @{ Label = "Command"; Expression = { $_.CommandLine } }
                        )
                        $Session.MinersRunning | Sort-Object -Property { $_.BaseName_Version_Device -replace ".+-" } | Format-Table $MinerTable -Wrap | Out-Host
                        Remove-Variable MinerTable
                    }

                    if ($Config.UIstyle -eq "full" -or $Session.MinersNeedingBenchmark -or $Session.MinersNeedingPowerConsumptionMeasurement) { 

                        [System.Collections.ArrayList]$MinersActivatedLast24Hrs = $Session.Miners.Where({ $_.Activated -and $_.EndTime.ToLocalTime().AddHours(24) -gt [DateTime]::Now })

                        if ($ProcessesIdle = $MinersActivatedLast24Hrs.Where({ $_.Status -eq "Idle" })) { 
                            Write-Host "$($ProcessesIdle.Count) previously executed miner$(if ($ProcessesIdle.Count -ne 1) { "s" }) (past 24 hrs):"
                            [System.Collections.ArrayList]$MinerTable = @(
                                @{ Label = "Name"; Expression = { $_.Name } }
                                if ($Config.ShowColumnPowerConsumption -and $Session.Config.CalculatePowerCost) { @{ Label = "Power (W)"; Expression = { if ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } else { "$($_.PowerConsumption.ToString("N2"))" } }; Align = "right" } }
                                @{ Label = "Hashrate(s)"; Expression = { $_.Workers.Hashrate.ForEach({ $_ | ConvertTo-Hash }) -join " & " }; Align = "right" }
                                @{ Label = "Time since last run"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f $([DateTime]::Now - $_.EndTime.ToLocalTime()) } }
                                @{ Label = "Active (total)"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f $_.TotalMiningDuration } }
                                @{ Label = "Cnt"; Expression = { switch ($_.Activated) { 0 { "Never"; break } 1 { "Once"; break } default { $_ } } } }
                                @{ Label = "Device(s)"; Expression = { $_.BaseName_Version_Device -replace ".+-" } }
                                @{ Label = "Command"; Expression = { $_.CommandLine } }
                            )
                            $ProcessesIdle | Sort-Object -Property EndTime -Descending | Format-Table $MinerTable -Wrap | Out-Host
                            Remove-Variable MinerTable
                        }
                        Remove-Variable ProcessesIdle

                        if ($ProcessesFailed = $MinersActivatedLast24Hrs.Where({ $_.Status -eq "Failed" })) { 
                            Write-Host -ForegroundColor Red "$($ProcessesFailed.Count) failed miner$(if ($ProcessesFailed.Count -ne 1) { "s" }) (past 24 hrs):"
                            [System.Collections.ArrayList]$MinerTable = @(
                                @{ Label = "Name"; Expression = { $_.Name } }
                                if ($Config.ShowColumnPowerConsumption -and $Session.Config.CalculatePowerCost) { @{ Label = "Power (W)"; Expression = { if ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } else { "$($_.PowerConsumption.ToString("N2"))" } }; Align = "right" } }
                                @{ Label = "Hashrate(s)"; Expression = { $_.Workers.Hashrate.ForEach({ $_ | ConvertTo-Hash }) -join " & " }; Align = "right" }
                                @{ Label = "Time since last fail"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f $([DateTime]::Now - $_.EndTime.ToLocalTime()) } }
                                @{ Label = "Active (total)"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f $_.TotalMiningDuration } }
                                @{ Label = "Cnt"; Expression = { switch ($_.Activated) { 0 { "Never"; break } 1 { "Once"; break } default { $_ } } } }
                                @{ Label = "Device(s)"; Expression = { $_.BaseName_Version_Device -replace ".+-" } }
                                @{ Label = "Command"; Expression = { $_.CommandLine } }
                            )
                            $ProcessesFailed | Sort-Object { if ($_.EndTime) { $_.EndTime } else { [DateTime]0 } } | Format-Table $MinerTable -Wrap | Out-Host
                            Remove-Variable MinerTable
                        }
                        Remove-Variable MinersActivatedLast24Hrs, ProcessesFailed

                        if ($Session.Config.Watchdog) { 
                            # Display watchdog timers
                            $Session.WatchdogTimers.Where({ $_.Kicked -gt $Session.Timer.AddSeconds(-$Session.WatchdogReset) }) | Sort-Object -Property Kicked, @{ Expression = { $_.MinerBaseName_Version_Device -replace ".+-" } } | Format-Table -Wrap (
                                @{ Label = "Miner watchdog timer"; Expression = { $_.MinerName } },
                                @{ Label = "Pool"; Expression = { $_.PoolName } },
                                @{ Label = "Algorithm"; Expression = { $_.Algorithm } },
                                @{ Label = "Device(s)"; Expression = { $_.MinerBaseName_Version_Device -replace ".+-" } },
                                @{ Label = "Last updated"; Expression = { "{0:mm} min {0:ss} sec ago" -f ([DateTime]::Now.ToUniversalTime() - $_.Kicked) }; Align = "right" }
                            ) | Out-Host
                        }
                    }

                    if ($Session.MiningStatus -eq "Running" -and $Global:CoreCycleRunspace.Job.IsCompleted -eq $false) { 

                        if ($Config.UIstyle -ne "full" -and $Session.MinersBenchmarkingOrMeasuring) { Write-Host -ForegroundColor DarkYellow "$(if ($Session.MinersNeedingBenchmark) { "Benchmarking" })$(if ($Session.MinersNeedingBenchmark -and $Session.MinersNeedingPowerConsumptionMeasurement) { " / " })$(if ($Session.MinersNeedingPowerConsumptionMeasurement) { "Measuring power consumption" }): Temporarily switched UI style to 'full'. (Information about miners run in the past, failed miners & watchdog timers will be shown)`n" }

                        $Colour = if ($Session.MinersRunning -and ($Session.MinersNeedingBenchmark -or $Session.MinersNeedingPowerConsumptionMeasurement)) { "DarkYello" } else { "White" }
                        Write-Host -ForegroundColor $Colour ($Session.Summary -replace "\.\.\.<br>", "... " -replace "<br>", " " -replace "\s*/\s*", "/" -replace "\s*=\s*", "=")
                        Remove-Variable Colour

                        if ($Session.Miners.Where({ $_.Available -and -not ($_.Benchmark -or $_.MeasurePowerConsumption) })) { 
                            if ($Session.MiningProfit -lt 0) { 
                                # Mining causes a loss
                                Write-Host -ForegroundColor Red ("Mining is currently NOT profitable and $(if ($Session.Config.DryRun) { "would cause" } else { "causes" }) a loss of {0} {1:n$($Session.Config.DecimalsMax)}/day (including base power cost)." -f $Session.Config.FIATcurrency, - ($Session.MiningProfit * $Session.Rates.BTC.($Session.Config.FIATcurrency)))
                            }
                            if ($Session.MiningProfit -lt $Session.Config.ProfitabilityThreshold) { 
                                # Mining profit is below the configured threshold
                                Write-Host -ForegroundColor Blue ("Mining profit ({0} {1:n$($Session.Config.DecimalsMax)}) is below the configured threshold of {0} {2:n$($Session.Config.DecimalsMax)}/day. Mining is suspended until threshold is reached." -f $Session.Config.FIATcurrency, ($Session.MiningProfit * $Session.Rates.BTC.($Session.Config.FIATcurrency)), $Session.Config.ProfitabilityThreshold)
                            }
                            $StatusInfo = "Last refresh: $($Session.BeginCycleTime.ToLocalTime().ToString("G"))   |   Next refresh: $(if ($Session.EndCycleTime) { $($Session.EndCycleTime.ToLocalTime().ToString("G")) } else { 'n/a (Mining is suspended)' })   |   Hot keys: $(if ($Session.CalculatePowerCost) { "[12345abcemnopqrstuw]" } else { "[12345abcemnpqsu]" })   |   Press 'h' for help"
                            Write-Host ("-" * $StatusInfo.Length)
                            Write-Host -ForegroundColor Yellow $StatusInfo
                            Remove-Variable StatusInfo
                        }
                    }
                }
                else { 
                    Write-Host -ForegroundColor Red "No internet connection - will retry in $($Session.Config.Interval) seconds..."
                }
            }
        }
    }
)

$LegacyGUIform.Controls.Add($LegacyGUIelements.TabControl)
$LegacyGUIform.ResumeLayout()

$LegacyGUIform.KeyPreview = $true
$LegacyGUIform.Add_Load(
    { 
        # Restore window size
        if ((Test-Path -LiteralPath ".\Config\WindowSettings.json" -PathType Leaf) -and ($WindowSettings = [System.IO.File]::ReadAllLines("$PWD\Config\WindowSettings.json") | ConvertFrom-Json -AsHashtable)) { 
            # Ensure form is displayed inside the available screen space
            if ($WindowSettings.Top -gt 0 -and $WindowSettings.Top -lt [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize.Height * 0.95) { $LegacyGUIform.Top = $WindowSettings.Top }
            if ($WindowSettings.Left -gt 0 -and $WindowSettings.Left -lt [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize.Width * 0.95) { $LegacyGUIform.Left = $WindowSettings.Left }
            if ($WindowSettings.Width -gt $LegacyGUIform.MinimumSize.Width) { $LegacyGUIform.Width = $WindowSettings.Width }
            if ($WindowSettings.Height -gt $LegacyGUIform.MinimumSize.Height) { $LegacyGUIform.Height = $WindowSettings.Height }
        }

        if ($Config.LegacyGUIStartMinimized) { $LegacyGUIform.WindowState = [System.Windows.Forms.FormWindowState]::Minimized }
        $Session.WindowStateOriginal = $LegacyGUIform.WindowState

        switch ($Session.MiningStatus) { 
            "Idle" { 
                $LegacyGUIelements.ButtonPause.Enabled = $true
                $LegacyGUIelements.ButtonStart.Enabled = $true
                $LegacyGUIelements.ButtonStop.Enabled = $false
                break
            }
            "Paused" { 
                $LegacyGUIelements.ButtonPause.Enabled = $false
                $LegacyGUIelements.ButtonStart.Enabled = $true
                $LegacyGUIelements.ButtonStop.Enabled = $true
                break
            }
            "Running" { 
                $LegacyGUIelements.ButtonPause.Enabled = $true
                $LegacyGUIelements.ButtonStart.Enabled = $false
                $LegacyGUIelements.ButtonStop.Enabled = $true
            }
        }

        Disable-X

        $LegacyGUIelements.Timer.Start()
    }
)

$LegacyGUIform.Add_FormClosing(
    { 
        if ($FormClosing) {
            return # Exit if already closing
        }
        $Script:FormClosing = $true

        if ($Config.LegacyGUI -and $KeyPressed.Key -ne "q") { 
            if (-not $Session.Config.ShowConsole) {
                # If console is not visible there is no user friendly way to end script
                $Session.PopupInput = (New-Object -ComObject Wscript.Shell).Popup("Do you want to shut down $($Session.Branding.ProductLabel)?", 0, "$($Session.Branding.ProductLabel)", (4 + 32 + 4096))
                if ($Session.PopupInput -eq 7 <#No#>) { 
                    $Session.Remove("PopupInput")
                    $Script:FormClosing = $false
                    $_.Cancel = $true
                    return
                }
            }
            else { 
                $Session.PopupInput = (New-Object -ComObject Wscript.Shell).Popup("Do you also want to shut down $($Session.Branding.ProductLabel)?", 0, "$($Session.Branding.ProductLabel)", (3 + 32 + 4096))
                if ($Session.PopupInput -eq 2 <#Cancel#>) { 
                    $Session.Remove("PopupInput")
                    $Script:FormClosing = $false
                    $_.Cancel = $true
                    return
                }
            }
            $Config.LegacyGUI = $false
        }

        if ($Session.PopupInput -eq 6 <#Yes#>) { 
            # Save window settings
            if ($LegacyGUIform.DesktopBounds.Width -ge 0) { [PSCustomObject]@{ Top = $LegacyGUIform.Top; Left = $LegacyGUIform.Left; Height = $LegacyGUIform.Height; Width = $LegacyGUIform.Width } | ConvertTo-Json | Out-File -LiteralPath ".\Config\WindowSettings.json" -Force -ErrorAction Ignore }

            Exit-UGminer
        }
        $Session.Remove("PopupInput")
        $Config.LegacyGUI = $false
        $Session.WindowStateOriginal = $LegacyGUIform.WindowState
        $LegacyGUIform.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
        $LegacyGUIform.ShowInTaskbar = $false
        $Script:FormClosing = $false

        # Do not close form
        $_.Cancel = $true

        return
    }
)

$LegacyGUIform.Add_KeyDown(
    { 
        if ($Session.NewMiningStatus -eq "Running" -and $_.Control -and $_.Alt -and $_.KeyCode -eq "P") { 
            # '<Ctrl><Alt>P' pressed
            if (-not $Global:CoreCycleRunspace.Job.IsCompleted -eq $false) { 
                # Core is complete / gone. Cycle cannot be suspended anymore
                $Session.SuspendCycle = $false
            }
            else { 
                $Session.SuspendCycle = -not $Session.SuspendCycle
                if ($Session.SuspendCycle) { 
                    $Message = "'<Ctrl><Alt>P' pressed. Core cycle is suspended until you press '<Ctrl><Alt>P' again."
                    $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Blue
                    $LegacyGUIelements.MiningSummaryLabel.Text = $Message
                    $LegacyGUIelements.ButtonPause.Enabled = $false
                    Write-Host $Message -ForegroundColor Cyan
                }
                else { 
                    $Message = "'<Ctrl><Alt>P' pressed. Core cycle is running again."
                    $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Blue
                    $LegacyGUIelements.MiningSummaryLabel.Text = $Message
                    $LegacyGUIelements.ButtonPause.Enabled = $true
                    Write-Host $Message -ForegroundColor Cyan
                }
                Remove-Variable Message
            }
        }
        elseif ($_.KeyCode -eq "F5") { 
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