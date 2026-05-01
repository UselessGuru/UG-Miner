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
File:           \Includes\include.ps1
Version:        6.8.5
Version date:   2026/05/01
#>

# $Global:DebugPreference = "SilentlyContinue"
# $Global:ErrorActionPreference = "SilentlyContinue"
# $Global:InformationPreference = "SilentlyContinue"
# $Global:ProgressPreference = "SilentlyContinue"
# $Global:WarningPreference = "SilentlyContinue"
# $Global:VerbosePreference = "SilentlyContinue"

# Fix TLS Version erroring
if ([Net.ServicePointManager]::SecurityProtocol -notmatch [Net.SecurityProtocolType]::Tls10) { [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls10 }
if ([Net.ServicePointManager]::SecurityProtocol -notmatch [Net.SecurityProtocolType]::Tls11) { [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls11 }
if ([Net.ServicePointManager]::SecurityProtocol -notmatch [Net.SecurityProtocolType]::Tls12) { [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12 }

# Disable QuickEditMode, based on https://stackoverflow.com/a/77091157
Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class ConsoleModeSettings
{
    const uint ENABLE_QUICK_EDIT = 0x0040;
    const uint ENABLE_INSERT_MODE = 0x0020;

    const int STD_INPUT_HANDLE = -10;

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr GetStdHandle(int nStdHandle);

    [DllImport("kernel32.dll")]
    static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);

    [DllImport("kernel32.dll")]
    static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);

    public static void EnableQuickEditMode()
    {
        SetConsoleFlag(ENABLE_QUICK_EDIT, true);
    }

    public static void DisableQuickEditMode()
    {
        SetConsoleFlag(ENABLE_QUICK_EDIT, false);
    }

    private static void SetConsoleFlag(uint modeFlag, bool enable)
    {
        IntPtr consoleHandle = GetStdHandle(STD_INPUT_HANDLE);
        uint consoleMode;
        if (GetConsoleMode(consoleHandle, out consoleMode))
        {
            if (enable)
                consoleMode |= modeFlag;
            else
                consoleMode &= ~modeFlag;

            SetConsoleMode(consoleHandle, consoleMode);
        }
    }
}

'@ 

# No native way to check how long the system has been idle in PowerShell. Have to use .NET code.
Add-Type -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace PInvoke.Win32 { 

    public static class UserInput { 

        [DllImport("user32.dll", SetLastError = false)]
        private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [StructLayout(LayoutKind.Sequential)]
        private struct LASTINPUTINFO { 
            public uint cbSize;
            public int dwTime;
        }

        public static DateTime LastInput { 
            get { 
                DateTime bootTime = DateTime.UtcNow.AddMilliseconds(-Environment.TickCount);
                DateTime lastInput = bootTime.AddMilliseconds(LastInputTicks);
                return lastInput;
            }
        }

        public static TimeSpan IdleTime { 
            get { 
                return DateTime.UtcNow.Subtract(LastInput);
            }
        }

        public static int LastInputTicks { 
            get { 
                LASTINPUTINFO lii = new LASTINPUTINFO();
                lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
                GetLastInputInfo(ref lii);
                return lii.dwTime;
            }
        }
    }
}
'@

# Registry key info
# Based on https://community.nexthink.com/s/question/0D52p00008n4ORKCA2/get-the-timestamp-of-any-path-or-key-in-the-registry
$RegData = Add-Type -Name GetRegData -Namespace RegQueryInfoKey -Using System.Text -PassThru -MemberDefinition '
[DllImport("advapi32.dll", CharSet = CharSet.Auto)]

public static extern Int32 RegQueryInfoKey(
    Microsoft.Win32.SafeHandles.SafeRegistryHandle hKey,
    StringBuilder lpClass,
    Int32 lpCls, Int32 spare, Int32 subkeys,
    Int32 skLen, Int32 mcLen, Int32 values,
    Int32 vNLen, Int32 mvLen, Int32 secDesc,
    out System.Runtime.InteropServices.ComTypes.FILETIME lpftLastWriteTime
);'

function Get-RegTime { 
    param (
        [Parameter (Mandatory = $true)]
        [String]$RegistryPath
    )

    $Reg = Get-Item $RegistryPath -Force
    if ($Reg.handle) { 
        $Time = [System.Runtime.InteropServices.ComTypes.FILETIME]::new()
        $Result = $RegData::RegQueryInfoKey($Reg.Handle, $null, 0, 0, 0, 0, 0, 0, 0, 0, 0, [ref]$Time)
        if ($Result -eq 0) { 
            $Low = [UInt32]0 -bor $Time.dwLowDateTime
            $High = [UInt32]0 -bor $Time.dwHighDateTime
            $TimeValue = ([Int64]$High -shl 32) -bor $Low
            return [DateTime]::FromFileTime($TimeValue)
        }
    }
}

# Window handling
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class Win32 { 
    [DllImport("user32.dll")]
    public static extern int SetWindowText(IntPtr hWnd, string strTitle);

    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern int SetForegroundWindow(IntPtr hwnd);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern int GetWindowThreadProcessId(IntPtr hWnd, out int lpdwProcessId);

    [DllImport("user32.dll")] 
    public static extern long GetSystemMenu(IntPtr hWnd, bool bRevert);

    [DllImport("user32.dll")] 
    public static extern bool EnableMenuItem(long hMenuItem, long wIDEnableItem, long wEnable);

    [DllImport("user32.dll")]
    public static extern long SetWindowLongPtr(long hWnd, long nIndex, long dwNewLong);
}
"@

# .Net methods for hiding/showing the console in the background
# https://stackoverflow.com/questions/40617800/opening-powershell-script-and-hide-command-prompt-but-not-the-gui
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

$Global:PriorityNames = [PSCustomObject]@{ -2 = "Idle"; -1 = "BelowNormal"; 0 = "Normal"; 1 = "AboveNormal"; 2 = "High"; 3 = "RealTime" }

[NoRunspaceAffinity()] # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_classes?view=powershell-7.4#example-4---class-definition-with-and-without-runspace-affinity
class Device { 
    [String]$Architecture
    [Int64]$Bus
    [UInt16]$Bus_Index
    [UInt16]$Bus_Type_Index
    [UInt16]$Bus_Platform_Index
    [UInt16]$Bus_Vendor_Index
    [PSCustomObject]$CIM
    [System.Version]$CUDAversion
    [Double]$ConfiguredPowerConsumption = 0 # Workaround if device does not expose power consumption
    [PSCustomObject]$CPUfeatures
    [UInt16]$Id
    [UInt16]$Index = 0
    [Int64]$Memory
    [String]$Model
    [Double]$MemoryGiB
    [String]$Name
    [PSCustomObject]$OpenCL
    [UInt16]$PlatformId = 0
    [UInt16]$PlatformId_Index
    # [PSCustomObject]$PNP
    [Boolean]$ReadPowerConsumption = $false
    # [PSCustomObject]$Reg
    [UInt16]$Slot = 0
    [DeviceState]$State = [DeviceState]::Enabled
    [String]$Status = "Idle"
    [String]$StatusInfo = ""
    [String]$SubStatus
    [String]$Type
    [UInt16]$Type_Id
    [UInt16]$Type_Index
    [UInt16]$Type_PlatformId_Index
    [UInt16]$Type_Slot
    [UInt16]$Type_Vendor_Id
    [UInt16]$Type_Vendor_Index
    [UInt16]$Type_Vendor_Slot
    [String]$Vendor
    [UInt16]$Vendor_Id
    [UInt16]$Vendor_Index
    [UInt16]$Vendor_Slot
}

enum DeviceState { 
    Enabled
    Disabled
    Unsupported
}

[NoRunspaceAffinity()]
class Pool : IDisposable { 
    [Double]$Accuracy
    [String]$Algorithm
    [String]$AlgorithmVariant
    [Boolean]$Available = $true
    [Boolean]$Best = $false
    [Nullable[Int64]]$BlockHeight = $null # DAG block height
    [String]$CoinName
    [String]$Currency
    [Nullable[Double]]$DAGsizeGiB = $null
    [Boolean]$Disabled = $false
    [Double]$EarningsAdjustmentFactor = 1
    [Nullable[UInt16]]$Epoch = $null # DAG epoch
    [Double]$Fee
    [String]$Host
    # [String[]]$Hosts # To be implemented for pool failover
    [String]$Key # Primary key for faster pool updates
    [String]$Name
    [String]$Pass
    [System.Collections.Generic.List[Nullable[UInt16]]]$PoolPorts
    [UInt16]$Port
    [UInt16]$PortSSL
    [String]$PoolUri # Link to pool algorithm web page
    [Double]$Price
    [Double]$Price_Bias
    [Boolean]$Prioritize = $false # derived from BalancesKeepAlive
    [String]$Protocol # ethproxy, ethstratum1, ethstratum2, ethstratumnh, stratum
    [System.Collections.Generic.SortedSet[String]]$Reasons # Why is the pool not available?
    [String]$Region
    [Boolean]$SendHashrate # If true miner will send hashrate to pool
    [Boolean]$SSLselfSignedCertificate
    [Double]$StablePrice
    [DateTime]$Updated
    [String]$User
    [String]$Variant # none, 24h or plus
    [String]$WorkerName = ""
    [Nullable[UInt]]$Workers

    Dispose() { 
        $this = $null
    }
}

[NoRunspaceAffinity()]
class Worker : IDisposable { 
    [Boolean]$Disabled = $false
    [Double]$Earnings = [Double]::NaN
    [Double]$Earnings_Bias = [Double]::NaN
    [Double]$Earnings_Accuracy = [Double]::NaN
    [Double]$Fee = 0
    [Double]$Hashrate = [Double]::NaN
    [Pool]$Pool
    [TimeSpan]$TotalMiningDuration = [TimeSpan]0
    [DateTime]$Updated = [DateTime]::Now.ToUniversalTime()

    Dispose() { 
        $this = $null
    }
}

enum MinerStatus { 
    Disabled
    DryRun
    Failed
    Idle
    Running
    Unavailable
}

[NoRunspaceAffinity()]
class Miner : IDisposable { 
    [UInt16]$Activated
    [TimeSpan]$Active = [TimeSpan]::Zero
    [String[]]$Algorithms = @() # derived from workers, required for GetDataReader & Web GUI
    [String]$API
    [String]$Arguments
    [Boolean]$Available = $true
    [String]$BaseName
    [String]$BaseName_Version
    [String]$BaseName_Version_Device
    [DateTime]$BeginTime # UniversalTime
    [Boolean]$Benchmark = $false # derived from stats
    [Boolean]$Best = $false
    [String]$CommandLine
    [UInt]$ContinousCycle = 0 # Counter, miner has been running continously for n loops
    [Double]$DataCollectInterval = 5 # Seconds, allow fractions of seconds
    [DateTime]$DataSampleTimestamp = 0 # Newest sample
    [System.Collections.Generic.List[String]]$DeviceNames = @() # derived from devices
    [PSCustomObject[]]$Devices
    [Boolean]$Disabled = $false
    [Double]$Earnings = [Double]::NaN # derived from pool and stats
    [Double]$Earnings_Bias = [Double]::NaN # derived from pool and stats
    [Double]$Earnings_Accuracy = 0 # derived from pool and stats
    [DateTime]$EndTime # UniversalTime
    [String[]]$EnvVars = @()
    [Double[]]$Fee = @() # miner fee
    [Double[]]$Hashrates_Live = @()
    [String]$Info
    [Boolean]$KeepRunning = $false # do not stop miner even if not best (MinInterval)
    [DateTime]$LastUsed # derived from stats
    [String]$LogFile # path to miner log file
    [Boolean]$MeasurePowerConsumption = $false # derived from stats
    [UInt16]$MinDataSample # for safe hashrate values
    [String]$MinerUri # access to miner API / web interface
    [String]$Name
    [Boolean]$Optimal = $false
    [String]$Path
    [String]$PrerequisitePath
    [String]$PrerequisiteURI
    [UInt16]$Port # miner API port
    [Double]$PowerCost = [Double]::NaN
    [Double]$PowerConsumption = [Double]::NaN
    [Double]$PowerConsumption_Live = [Double]::NaN
    [Boolean]$Prioritize = $false # derived from BalancesKeepAlive
    [UInt32]$ProcessId = 0
    [Int16]$ProcessPriority = -1
    [Double]$Profit = [Double]::NaN
    [Double]$Profit_Bias = [Double]::NaN
    [Boolean]$ReadPowerConsumption
    [System.Collections.Generic.SortedSet[String]]$Reasons = @() # Why is the miner not available?
    [Boolean]$Restart = $false # if true miner will restart at end of cycle
    hidden [DateTime]$StatStart # UniversalTime
    hidden [DateTime]$StatEnd # UniversalTime
    [MinerStatus]$Status = [MinerStatus]::Idle
    [String]$StatusInfo = ""
    [String]$SubStatus = [MinerStatus]::Idle
    [TimeSpan]$TotalMiningDuration # derived from pool and stats
    [String]$Type
    [DateTime]$Updated # derived from pool update value
    [String]$URI # miner binary download address
    [DateTime]$ValidDataSampleTimestamp = 0
    [String]$Version # Miner version
    [UInt16[]]$WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
    [String]$WindowStyle # "minimized": miner window is minimized (default), but accessible; "normal": miner windows are shown normally; "hidden": miners will run as a hidden background task and are not accessible
    [Worker[]]$Workers = @() # derived from pools
    [Worker[]]$WorkersRunning = @() # derived from pools

    hidden [System.Collections.Generic.List[PSCustomObject]]$Data = @() # To store data samples (speed & power consumtion)
    hidden [System.Management.Automation.Job]$DataReaderJob = $null
    hidden [System.Management.Automation.Job]$ProcessJob = $null
    hidden [System.Diagnostics.Process]$Process = $null

    Dispose() { 
        $this = $null
    }

    [String]GetCommandLine() { 
        return "$($this.Path)$($this.GetCommandLineParameters())"
    }

    [String]GetCommandLineParameters() { 
        if ($this.Arguments -and (Test-Json -Json $this.Arguments -ErrorAction Ignore)) { 
            return ($this.Arguments | ConvertFrom-Json).Arguments
        }
        else { 
            return $this.Arguments
        }
    }

    [String[]]GetProcessNames() { 
        return @(([IO.FileInfo]($this.Path | Split-Path -Leaf)).BaseName)
    }

    hidden [Void]StartDataReader() { 
        $ScriptBlock = { 
            $ScriptBody = "using module .\Includes\Include.psm1"; $Script = [ScriptBlock]::Create($ScriptBody); . $Script

            try { 
                # Load miner API file
                . ".\Includes\MinerAPIs\$($args[0]).ps1"
                $ProgressPreference = "SilentlyContinue"
                $Miner = ($args[1] | ConvertFrom-Json) -as $args[0]
                Start-Sleep -Seconds 2

                while ($true) { 
                    $LoopEnd = [DateTime]::Now.AddSeconds($Miner.DataCollectInterval)
                    $Miner.GetMinerData()
                    while ([DateTime]::Now -lt $LoopEnd) { Start-Sleep -Milliseconds 50 }
                }
            }
            catch { 
                return $_
            }
            Remove-Variable Miner, LoopEnd -ErrorAction Ignore
        }

        # Start miner data reader, devices property required for GetPowerConsumption/ConfiguredPowerConsumption
        $this.DataReaderJob = Start-ThreadJob -ErrorVariable $null -InformationVariable $null -OutVariable $null -WarningVariable $null -Name "$($this.NameAndDevice)_DataReader" -StreamingHost $null -InitializationScript ([ScriptBlock]::Create("Set-Location('$(Get-Location)')")) -ScriptBlock $ScriptBlock -ArgumentList ($this.API), ($this | Select-Object -Property Algorithms, DataCollectInterval, Devices, Name, Path, Port, ReadPowerConsumption | ConvertTo-Json -Depth 5 -WarningAction Ignore)

        Remove-Variable ScriptBlock -ErrorAction Ignore
    }

    hidden [Void]StopDataReader() { 
        if ($this.DataReaderJob) { 
            $null = ($this.DataReaderJob | Stop-Job)
            # Get data before removing read data
            if ($this.Status -eq [MinerStatus]::Running -and $this.DataReaderJob.HasMoreData) { ($this.DataReaderJob | Receive-Job).Where({ $_.Date }).ForEach({ $null = $this.Data.Add($_) }) }
            $null = ($this.DataReaderJob | Remove-Job -Force -ErrorAction Ignore)
            $this.DataReaderJob.Dispose()
            $this.DataReaderJob = $null
        }
    }

    hidden [Void]RestartDataReader() { 
        $this.StopDataReader()
        $this.StartDataReader()
    }

    hidden [Void]StartMining() { 
        if ($this.Arguments -and (Test-Json $this.Arguments -ErrorAction Ignore)) { $this.CreateConfigFiles() }

        # Stat just got removed (Miner.Activated < 1, set by API)
        if ($this.Activated -le 0) { $this.Activated = 0 }
        if ($this.Benchmark -or $this.MeasurePowerConsumption) { $this.Data = @() }

        $this.ContinousCycle = 0
        $this.DataSampleTimestamp = [DateTime]0
        $this.ValidDataSampleTimestamp = [DateTime]0

        $this.Hashrates_Live = @($this.Workers.ForEach({ [Double]::NaN }))
        $this.PowerConsumption_Live = [Double]::NaN

        if ($this.Status -eq [MinerStatus]::DryRun) { 
            Write-Message -Level Info "Dry run for miner '$($this.Info)'..."
            $this.StatusInfo = "$($this.Info) (Dry run)"
            $this.SubStatus = "dryrun"
            $this.StatStart = $this.BeginTime = [DateTime]::Now.ToUniversalTime()
        }
        else { 
            Write-Message -Level Info "Starting miner '$($this.Info)'..."
            $this.StatusInfo = "$($this.Info) is getting ready"
            $this.SubStatus = "starting"
        }

        Write-Message -Level Verbose $this.CommandLine

        # Log switching information to .\Logs\SwitchingLog.csv
        [PSCustomObject]@{ 
            DateTime                = (Get-Date -Format o)
            Action                  = if ($this.Status -eq [MinerStatus]::DryRun) { "DryRun" } else { "Launched" }
            Name                    = $this.Name
            Accounts                = $this.Workers.Pool.User -join ";"
            Activated               = $this.Activated
            Algorithms              = $this.Workers.Pool.AlgorithmVariant -join ";"
            Benchmark               = $this.Benchmark
            CommandLine             = $this.CommandLine
            Cycle                   = ""
            DeviceNames             = $this.BaseName_Version_Device -replace ".+-"
            Duration                = ""
            Earnings                = $this.Earnings
            Earnings_Bias           = $this.Earnings_Bias
            Hashrates               = ""
            LastDataSample          = $null
            MeasurePowerConsumption = $this.MeasurePowerConsumption
            Pools                   = $this.Workers.Pool.Name -join ";"
            Profit                  = $this.Profit
            Profit_Bias             = $this.Profit_Bias
            PowerConsumption        = ""
            Reason                  = ""
            Type                    = $this.Type
        } | Export-Csv -Path ".\Logs\SwitchingLog.csv" -Append -NoTypeInformation

        if ($this.Status -eq [MinerStatus]::DryRun) { 
            $this.WorkersRunning = $this.Workers
        }
        else { 
            $this.ProcessJob = Invoke-CreateProcess -ErrorVariable $null -InformationVariable $null -OutVariable $null -WarningVariable $null -BinaryPath "$PWD\$($this.Path)" -ArgumentList $this.GetCommandLineParameters() -WorkingDirectory (Split-Path "$PWD\$($this.Path)") -WindowStyle $this.WindowStyle -EnvBlock $this.EnvVars -JobName $this.Name -LogFile $this.LogFile -Status $this.StatusInfo

            # Sometimes the process cannot be found instantly
            $Loops = 100
            do { 
                if ($this.ProcessId = ($this.ProcessJob | Receive-Job -ErrorAction Ignore).MinerProcessId) { 
                    $this.Activated ++
                    $this.DataSampleTimestamp = [DateTime]0
                    $this.Status = [MinerStatus]::Running
                    $this.StatStart = $this.BeginTime = [DateTime]::Now.ToUniversalTime()
                    $this.Process = Get-Process -Id $this.ProcessId -ErrorAction SilentlyContinue
                    $this.StartDataReader()
                    $this.WorkersRunning = $this.Workers
                    break
                }
                else { 
                    Start-Sleep -Milliseconds 50
                }
                $Loops --
            } while ($Loops -gt 0)
            Remove-Variable Loops
        }
    }

    hidden [Void]StopMining() { 
        if ([MinerStatus]::Running, [MinerStatus]::Disabled, [MinerStatus]::DryRun -contains $this.Status) { 
            Write-Message -Level Info "Stopping miner '$($this.Info)'..."
            $this.StatusInfo = "$($this.Info) is stopping..."
        }

        $this.StopDataReader()

        if ($this.ProcessJob) { 
            if ($this.ProcessJob.State -eq "Running") { $this.ProcessJob | Stop-Job -ErrorAction Ignore }
            try { $this.Active += $this.ProcessJob.PSEndTime - $this.ProcessJob.PSBeginTime } catch { }
            # Jobs are getting removed in core loop (removing here immediately after stopping process may take several seconds)
            $this.ProcessJob.Dispose()
            $this.ProcessJob = $null
        }

        $this.EndTime = [DateTime]::Now.ToUniversalTime()

        if ($this.Process.Id) { 
            if ($this.Process.Parent.Id) { $null = (Stop-Process -Id $this.Process.Parent.Id -Force -ErrorAction Ignore) }
            $null = (Stop-Process -Id $this.Process.Id -Force -ErrorAction Ignore)
            # Some miners, e.g. HellMiner spawn child process(es) that may need separate killing
            (Get-CimInstance win32_process -Filter "ParentProcessId = $($this.Process.Id)").ForEach({ $null = (Stop-Process -Id $_.ProcessId -Force -ErrorAction Ignore) })
        }
        $this.Process = $null

        $this.StatusInfo = if ($this.Status -eq [MinerStatus]::Failed) { $this.StatusInfo.Replace("'$($this.Name)' ", "") -replace ".+stopped. " -replace ".+sample.*\) " } else { "" }

        # Log switching information to .\Logs\SwitchingLog
        [PSCustomObject]@{ 
            DateTime                = (Get-Date -Format o)
            Action                  = if ($this.Status -eq [MinerStatus]::Failed) { "Failed" } else { "Stopped" }
            Name                    = $this.Name
            Activated               = $this.Activated
            Accounts                = $this.WorkersRunning.Pool.User -join " "
            Algorithms              = $this.WorkersRunning.Pool.AlgorithmVariant -join " "
            Benchmark               = $this.Benchmark
            CommandLine             = $this.CommandLine
            Cycle                   = $this.ContinousCycle
            DeviceNames             = $this.BaseName_Version_Device -replace ".+-"
            Duration                = "{0:hh\:mm\:ss}" -f ($this.EndTime - $this.BeginTime)
            Earnings                = $this.Earnings
            Earnings_Bias           = $this.Earnings_Bias
            Hashrates               = $this.WorkersRunning.Hashrate.ForEach({ $_ | ConvertTo-Hash }) -join " & "
            LastDataSample          = if ($this.Data.Count -ge 1) { $this.Data.Item | Select-Object -Last 1 | ConvertTo-Json -Compress } else { "" }
            MeasurePowerConsumption = $this.MeasurePowerConsumption
            Pools                   = ($this.WorkersRunning.Pool.Name | Select-Object -Unique) -join " "
            PowerConsumption        = "$($this.PowerConsumption.ToString("N2"))W"
            Profit                  = $this.Profit
            Profit_Bias             = $this.Profit_Bias
            Reason                  = $this.StatusInfo
            Type                    = $this.Type
        } | Export-Csv -Path ".\Logs\SwitchingLog.csv" -Append -NoTypeInformation

        if ($this.Status -eq [MinerStatus]::Failed) { 
            $this.StatusInfo = "Failed: Miner $($this.StatusInfo)"
            $this.SubStatus = "Failed"
            $this.WorkersRunning.ForEach(
                { 
                    $_.Disabled = $false
                    $_.Earnings = [Double]::NaN
                    $_.Earnings_Accuracy = [Double]::NaN
                    $_.Earnings_Bias = [Double]::NaN
                    $_.Fee = 0
                    $_.Hashrate = [Double]::NaN
                    $_.TotalMiningDuration = [TimeSpan]0
                }
            )
            $this.Earnings = $this.Earnings_Accuracy = $this.Earnings_Bias = $this.PowerCost = $this.PowerConsumption = $this.PowerConsumption_Live = $this.Profit = $this.Profit_Bias = [Double]::NaN
            $this.Hashrates_Live = @($this.WorkersRunning.ForEach({ [Double]::NaN }))
        }
        else { 
            $this.Status = [MinerStatus]::Idle
            $this.StatusInfo = "Idle"
            $this.SubStatus = $this.Status
        }
        $this.WorkersRunning = [Worker[]]@()
    }

    [MinerStatus]GetStatus() { 
        if ($this.ProcessJob.State -eq "Running" -and $this.ProcessId -and (Get-Process -Id $this.ProcessId -ErrorAction SilentlyContinue)) { 
            # Use ProcessName, some crashed miners are dead, but may still be found by their processId
            return [MinerStatus]::Running
        }
        elseif ($this.Status -eq [MinerStatus]::Running) { 
            return [MinerStatus]::Failed
        }
        else { 
            return $this.Status
        }
    }

    [Void]SetStatus([MinerStatus]$Status) { 
        switch ($Status) { 
            "DryRun" { 
                $this.Status = [MinerStatus]::DryRun
                $this.StartMining()
                break
            }
            "Idle" { 
                $this.StopMining()
                break
            }
            "Running" { 
                $this.StartMining()
                break
            }
            default { 
                $this.Status = [MinerStatus]::Failed
                $this.StopMining()
            }
        }
    }

    [Double]GetPowerConsumption() { 
        $TotalPowerConsumption = [Double]0

        # Read power consumption from HwINFO64 reg key, otherwise use hardconfigured value
        $RegistryData = Get-ItemProperty "HKCU:\Software\HWiNFO64\VSB"
        foreach ($Device in $this.Devices) { 
            if ($RegistryEntry = $RegistryData.PSObject.Properties.Where({ $_.Name -like "Label*" -and $_.Value -split " " -contains $Device.Name })) { 
                $TotalPowerConsumption += [Double](($RegistryData.($RegistryEntry.Name -replace "Label", "Value") -split " ")[0])
            }
            else { 
                $TotalPowerConsumption += [Double]$Device.ConfiguredPowerConsumption
            }
        }
        return $TotalPowerConsumption
    }

    [Double[]]CollectHashrate([String]$Algorithm = [String]$this.Algorithm, [Boolean]$Safe = $this.Benchmark) { 
        # Returns an array of two values (safe, unsafe)
        $HashrateAverage = [Double]0
        $HashrateVariance = [Double]0

        $HashrateSamples = @($this.Data.Where({ $_.Hashrate.$Algorithm })) # Do not use 0 valued samples

        $HashrateAverage = ($HashrateSamples.Hashrate.$Algorithm | Measure-Object -Average).Average
        $HashrateVariance = $HashrateSamples.Hashrate.$Algorithm | Measure-Object -Average -Minimum -Maximum | ForEach-Object { if ($_.Average) { ($_.Maximum - $_.Minimum) / $_.Average } }

        if ($Safe) { 
            if ($HashrateSamples.Count -lt 10 -or $HashrateVariance -gt 0.1) { 
                return 0, $HashrateAverage
            }
            else { 
                return ($HashrateAverage * (1 + $HashrateVariance / 2)), $HashrateAverage
            }
        }
        else { 
            return $HashrateAverage, $HashrateAverage
        }
    }

    [Double[]]CollectPowerConsumption([Boolean]$Safe = $this.MeasurePowerConsumption) { 
        # Returns an array of two values (safe, unsafe)
        $PowerConsumptionAverage = [Double]0
        $PowerConsumptionVariance = [Double]0

        $PowerConsumptionSamples = @($this.Data.Where({ $_.PowerConsumption })) # Do not use 0 valued samples

        $PowerConsumptionAverage = ($PowerConsumptionSamples.PowerConsumption | Measure-Object -Average).Average
        $PowerConsumptionVariance = $PowerConsumptionSamples.Powerusage | Measure-Object -Average -Minimum -Maximum | ForEach-Object { if ($_.Average) { ($_.Maximum - $_.Minimum) / $_.Average } }

        if ($Safe) { 
            if ($PowerConsumptionSamples.Count -lt 10 -or $PowerConsumptionVariance -gt 0.1) { 
                return 0, $PowerConsumptionAverage
            }
            else { 
                return ($PowerConsumptionAverage * (1 + $PowerConsumptionVariance / 2)), $PowerConsumptionAverage
            }
        }
        else { 
            return $PowerConsumptionAverage, $PowerConsumptionAverage
        }
    }

    [Void]Refresh([Double]$PowerCostBTCperW, [Hashtable]$Config) { 
        $this.Available = $true
        $this.Best = $false
        $this.MinDataSample = $Config.MinDataSample
        $this.Prioritize = $this.Workers.Pool.Prioritize -contains $true
        $this.ProcessPriority = $Config."$($this.Type)MinerProcessPriority"
        if ($this.ReadPowerConsumption -ne $this.Devices.ReadPowerConsumption -notcontains $false) { $this.Restart = $true }
        $this.ReadPowerConsumption = $this.Devices.ReadPowerConsumption -notcontains $false
        $this.Reasons = [System.Collections.Generic.SortedSet[String]]::new()
        $this.Workers.ForEach(
            { 
                if ($Stat = Get-Stat -Name "$($this.Name)_$($_.Pool.Algorithm)_Hashrate") { 
                    $_.Disabled = $Stat.Disabled
                    $_.Hashrate = $Stat.Hour
                    $Factor = $_.Hashrate * (1 - $_.Fee - $_.Pool.Fee)
                    $_.Earnings = $_.Pool.Price * $Factor
                    $_.Earnings_Accuracy = $_.Pool.Accuracy
                    $_.Earnings_Bias = $_.Pool.Price_Bias * $Factor
                    $_.TotalMiningDuration = $Stat.Duration
                    $_.Updated = $Stat.Updated
                }
                else { 
                    $_.Disabled = $false
                    $_.Earnings = [Double]::NaN
                    $_.Earnings_Accuracy = [Double]::NaN
                    $_.Earnings_Bias = [Double]::NaN
                    $_.Fee = 0
                    $_.Hashrate = [Double]::NaN
                    $_.TotalMiningDuration = [TimeSpan]0
                }
            }
        )

        if ($this.Benchmark = [Boolean]($this.Workers.Hashrate -like [Double]::NaN)) { 
            $this.Earnings = [Double]::NaN
            $this.Earnings_Accuracy = [Double]::NaN
            $this.Earnings_Bias = [Double]::NaN
        }
        else { 
            $this.Earnings = 0
            $this.Earnings_Accuracy = 0
            $this.Earnings_Bias = 0
            $this.Workers.ForEach(
                { 
                    $this.Earnings += $_.Earnings
                    $this.Earnings_Bias += $_.Earnings_Bias
                }
            )
            if ($this.Earnings) { $this.Workers.ForEach({ $this.Earnings_Accuracy += $_.Earnings_Accuracy * $_.Earnings / $this.Earnings }) }
        }

        if ($Stat = Get-Stat -Name "$($this.Name)_PowerConsumption") { 
            $this.MeasurePowerConsumption = $false
            $this.PowerConsumption = $Stat.Week
            $this.PowerCost = $this.PowerConsumption * $PowerCostBTCperW
            $this.Profit = $this.Earnings - $this.PowerCost
            $this.Profit_Bias = $this.Earnings_Bias - $this.PowerCost
        }
        else { 
            $this.PowerConsumption = [Double]::NaN
            $this.PowerCost = [Double]::NaN
            $this.Profit = [Double]::NaN
            $this.Profit_Bias = [Double]::NaN
        }

        $this.Disabled = $this.Workers.Disabled -contains $true
        $this.TotalMiningDuration = ($this.Workers.TotalMiningDuration | Measure-Object -Minimum).Minimum
        $this.LastUsed = ($this.Workers.Updated | Measure-Object -Minimum).Minimum
        $this.Updated = ($this.Workers.Pool.Updated | Measure-Object -Minimum).Minimum
        $this.WindowStyle = if ($Config.MinerWindowStyleNormalWhenBenchmarking -and $this.Benchmark) { "normal" } else { $Config.MinerWindowStyle }
    }
}

function Invoke-CreateProcess { 
    # Based on https://github.com/FuzzySecurity/PowerShell-Suite/blob/master/Invoke-CreateProcess.ps1

    param (
        [Parameter (Mandatory = $true)]
        [String]$BinaryPath,
        [Parameter (Mandatory = $false)]
        [String]$ArgumentList = "",
        [Parameter (Mandatory = $false)]
        [String]$WorkingDirectory = "",
        [Parameter (Mandatory = $false)]
        [String[]]$EnvBlock,
        [Parameter (Mandatory = $false)]
        [String]$CreationFlags = 0x00000010, # CREATE_NEW_CONSOLE
        [Parameter (Mandatory = $false)]
        [String]$WindowStyle = "minimized",
        [Parameter (Mandatory = $false)]
        [String]$StartF = 0x00003001, # STARTF_USESHOWWINDOW, STARTF_TITLEISAPPID, STARTF_PREVENTPINNING
        [Parameter (Mandatory = $false)]
        [String]$JobName,
        [Parameter (Mandatory = $false)]
        [String]$LogFile,
        [Parameter (Mandatory = $false)]
        [String]$StatusInfo
    )

    # Cannot use Start-ThreadJob, $ControllerProcess.WaitForExit(250) would not work and miners remain running
    Start-Job -ErrorVariable $null -InformationVariable $null -OutVariable $null -WarningVariable $null -Name $JobName -ArgumentList $BinaryPath, $ArgumentList, $WorkingDirectory, $EnvBlock, $CreationFlags, $WindowStyle, $StartF, $PID, $JobName, $StatusInfo { 
        param ($BinaryPath, $ArgumentList, $WorkingDirectory, $EnvBlock, $CreationFlags, $WindowStyle, $StartF, $ControllerProcessID, $JobName, $StatusInfo)

        $ControllerProcess = Get-Process -Id $ControllerProcessID -ErrorAction Ignore
        if ($null -eq $ControllerProcess) { return }

        # Define all the structures for CreateProcess
        Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct PROCESS_INFORMATION
{ 
    public IntPtr hProcess; public IntPtr hThread; public uint dwProcessId; public uint dwThreadId;
}

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct STARTUPINFO
{ 
    public uint cb; public string lpReserved; public string lpDesktop; [MarshalAs(UnmanagedType.LPUTF8Str)] public string lpTitle;
    public uint dwX; public uint dwY; public uint dwXSize; public uint dwYSize; public uint dwXCountChars;
    public uint dwYCountChars; public uint dwFillAttribute; public uint dwFlags; public short wShowWindow;
    public short cbReserved2; public IntPtr lpReserved2; public IntPtr hStdInput; public IntPtr hStdOutput;
    public IntPtr hStdError;
}

[StructLayout(LayoutKind.Sequential)]
public struct SECURITY_ATTRIBUTES
{ 
    public int length; public IntPtr lpSecurityDescriptor; public bool bInheritHandle;
}

public static class Kernel32
{ 
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool CreateProcess(
        string lpApplicationName, string lpCommandLine, ref SECURITY_ATTRIBUTES lpProcessAttributes,
        ref SECURITY_ATTRIBUTES lpThreadAttributes, bool bInheritHandles, uint dwCreationFlags,
        IntPtr lpEnvironment, string lpCurrentDirectory, ref STARTUPINFO lpStartupInfo,
        out PROCESS_INFORMATION lpProcessInformation);
}
"@

        $ShowWindow = switch ($WindowStyle) { 
            "hidden" { "0x0000"; break } # SW_HIDE
            "normal" { "0x0001"; break } # SW_SHOWNORMAL
            default  { "0x0007" } # SW_SHOWMINNOACTIVE
        }

        # Set local environment
        ($EnvBlock | Select-Object).ForEach({ $null = (New-Item -Path "Env:$(($_ -split "=")[0])" -Value "$(($_ -split "=")[1])" -Force) })

        # StartupInfo struct
        $StartupInfo = [STARTUPINFO]::new()
        $StartupInfo.dwFlags = $StartF # StartupInfo.dwFlag
        $StartupInfo.wShowWindow = $ShowWindow # StartupInfo.ShowWindow
        $StartupInfo.lpTitle = $StatusInfo
        $StartupInfo.cb = [System.Runtime.InteropServices.Marshal]::SizeOf($StartupInfo) # Struct size

        # SECURITY_ATTRIBUTES Struct (Process & Thread)
        $SecAttr = [SECURITY_ATTRIBUTES]::new()
        $SecAttr.Length = [System.Runtime.InteropServices.Marshal]::SizeOf($SecAttr)

        # CreateProcess --> lpCurrentDirectory
        if (-not $WorkingDirectory) { $WorkingDirectory = [IntPtr]::Zero }

        # ProcessInfo struct
        $ProcessInfo = [PROCESS_INFORMATION]::new()

        # Force to use conhost, sometimes miners would get started using windows terminal
        $ConHost = "$($ENV:SystemRoot)\System32\conhost.exe"

        # Call CreateProcess
        [Void][Kernel32]::CreateProcess($ConHost, "$ConHost $BinaryPath$ArgumentList", [ref]$SecAttr, [ref]$SecAttr, $false, $CreationFlags, [IntPtr]::Zero, $WorkingDirectory, [ref]$StartupInfo, [ref]$ProcessInfo)

        # Timing issue, some processes are not immediately available on fast computers
        $Loops = 100
        do { 
            if ($ConhostProcess = Get-Process -Id $ProcessInfo.dwProcessId -ErrorAction Ignore) { break }
            Start-Sleep -Milliseconds 50
            $Loops --
        } while ($Loops -gt 0)
        do { 
            if ($MinerProcess = (Get-CimInstance win32_process -Filter "ParentProcessId = $($ProcessInfo.dwProcessId)")[0]) { break }
            Start-Sleep -Milliseconds 50
            $Loops --
        } while ($Loops -gt 0)

        if ($null -eq $MinerProcess.Count) { 
            [PSCustomObject]@{ 
                ConhostProcessId = $ProcessInfo.dwProcessId
                MinerProcessId   = $null
            }
            return
        }

        $MinerProcessId = $MinerProcess.ProcessId
        [PSCustomObject]@{ 
            ConhostProcessId = $ProcessInfo.dwProcessId
            MinerProcessId   = $MinerProcessId
        }

        $null = $ConhostProcess.Handle
        $null = $ControllerProcess.Handle
        $null = $MinerProcess.Handle

        do { 
            if ($ControllerProcess.WaitForExit(250)) { 
                # Kill process in bottom up order
                # Some miners, e.g. HellMiner spawn child process(es) that may need separate killing
                $null = (Get-CimInstance win32_process -Filter "ParentProcessId = $MinerProcessId").ForEach({ Stop-Process -Id $_.ProcessId -Force -ErrorAction Ignore })
                $null = (Stop-Process -Id $MinerProcessId -Force -ErrorAction Ignore)
                $null = (Stop-Process -Id $ProcessInfo.dwProcessId -Force -ErrorAction Ignore)
                $MinerProcess = $null
                $ControllerProcess = $null
            }
        } while ($ControllerProcess.HasExited -eq $false)
    }
}

function Start-CoreCycle { 

    if (-not $Global:CoreCycleRunspace) { 
        $Global:CoreCycleRunspace = [RunspaceFactory]::CreateRunspace()
        $Global:CoreCycleRunspace.ApartmentState = "STA"
        $Global:CoreCycleRunspace.Name = "CoreCycle"
        $Global:CoreCycleRunspace.ThreadOptions = "ReuseThread"
        $Global:CoreCycleRunspace.Open()

        $Global:CoreCycleRunspace.SessionStateProxy.SetVariable("Config", $Config)
        $Global:CoreCycleRunspace.SessionStateProxy.SetVariable("Session", $Session)
        $Global:CoreCycleRunspace.SessionStateProxy.SetVariable("Stats", $Stats)
        [Void]$Global:CoreCycleRunspace.SessionStateProxy.Path.SetLocation($Session.MainPath)

        $PowerShell = [PowerShell]::Create()
        $PowerShell.Runspace = $Global:CoreCycleRunspace
        [Void]$Powershell.AddScript("$($Session.MainPath)\Includes\CoreCycle.ps1")
        $Global:CoreCycleRunspace | Add-Member PowerShell $PowerShell
    }

    if ($Global:CoreCycleRunspace.Job.IsCompleted -ne $false) { 
        # Remove stats that have been deleted from disk
        try { 
            if ($StatFiles = (Get-ChildItem -Path "Stats" -File).BaseName) { 
                if ($Stats.Keys) { 
                    (Compare-Object -PassThru $StatFiles $Stats.Keys).Where({ $_.SideIndicator -eq "=>" }).ForEach({ $Stats.Remove($_) })
                }
            }
        }
        catch {}
        Remove-Variable StatFiles -ErrorAction Ignore

        Clear-Miners
        Clear-Pools
        $Session.Remove("PoolDataCollectedTimeStamp")

        $Global:CoreCycleRunspace | Add-Member Job ($Global:CoreCycleRunspace.PowerShell.BeginInvoke()) -Force
        $Global:CoreCycleRunspace | Add-Member StartTime ([DateTime]::Now.ToUniversalTime()) -Force
    }
}

function Clear-Miners { 

    param (
        [Parameter (Mandatory = $false)]
        [Boolean]$KeepMiners = $false
    )

    # Stop all miners
    foreach ($Miner in $Session.Miners.Where({ $_.ProcessJob -or $_.Status -eq [MinerStatus]::DryRun })) { 
        $Miner.SetStatus([MinerStatus]::Idle)
        $Session.Devices.Where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
    }
    Remove-Variable Miner -ErrorAction Ignore

    $Session.WatchdogTimers = [System.Collections.Generic.List[PSCustomObject]]::new()

    $Session.Miners.ForEach({ 
        $_.Workers.ForEach({ $_.Dispose() })
        $_.Dispose()
    })
    $Session.MinersBenchmarkingOrMeasuring.ForEach({ $_.Dispose() })
    $Session.MinersBest.ForEach({ $_.Dispose() })
    $Session.MinersBestPerDevice.ForEach({ $_.Dispose() })
    $Session.MinersFailed.ForEach({ $_.Dispose() })
    $Session.MinersMissingBinary.ForEach({ $_.Dispose() })
    $Session.MinersMissingFirewallRule.ForEach({ $_.Dispose() })
    $Session.MinersMissingPrerequisite.ForEach({ $_.Dispose() })
    $Session.MinersNeedingBenchmark.ForEach({ $_.Dispose() })
    $Session.MinersNeedingPowerConsumptionMeasurement.ForEach({ $_.Dispose() })
    $Session.MinersOptimal.ForEach({ $_.Dispose() })
    $Session.MinersRunning.ForEach({ $_.Dispose() })

    if (-not $KeepMiners) { $Session.Miners = [Miner[]]@() }
    $Session.MinersBenchmarkingOrMeasuring = [Miner[]]@()
    $Session.MinersBest = [Miner[]]@()
    $Session.MinersBestPerDevice = [Miner[]]@()
    $Session.MinersFailed = [Miner[]]@()
    $Session.MinersMissingBinary = [Miner[]]@()
    $Session.MinersMissingFirewallRule = [Miner[]]@()
    $Session.MinersMissingPrerequisite = [Miner[]]@()
    $Session.MinersNeedingBenchmark = [Miner[]]@()
    $Session.MinersNeedingPowerConsumptionMeasurement = [Miner[]]@()
    $Session.MinersOptimal = [Miner[]]@()
    $Session.MinersRunning = [Miner[]]@()
    $Session.Remove("MinersUpdatedTimestamp")

    $Session.MiningEarnings = [Double]0
    $Session.MiningPowerConsumption = [Double]0
    $Session.MiningPowerCost = [Double]0
    $Session.MiningProfit = [Double]0
}

function Clear-Pools { 

    $Session.Pools.ForEach({ $_.Dispose() })
    $Session.Pools.ForEach({ $_.Dispose() })
    $Session.PoolsAdded.ForEach({ $_.Dispose() })
    $Session.PoolsExpired.ForEach({ $_.Dispose() })
    $Session.PoolsNew.ForEach({ $_.Dispose() })
    $Session.PoolsUpdated.ForEach({ $_.Dispose() })

    $Session.Pools = [Pool[]]@()
    $Session.PoolsAdded = [Pool[]]@()
    $Session.PoolsExpired = [Pool[]]@()
    $Session.PoolsNew = [Pool[]]@()
    $Session.PoolsUpdated = [Pool[]]@()
    $Session.Remove("PoolsUpdatedTimestamp")
}

function Stop-CoreCycle { 

    if ($Global:CoreCycleRunspace) { 
        if ($Global:CoreCycleRunspace.Job.IsCompleted -eq $false) { 
            $Global:CoreCycleRunspace.PowerShell.Stop()

            if ($Session.Timer) { Write-Message -Level Info "Ending cycle." }
        }

        Clear-Miners

        if ($Session.NewMiningStatus -eq "Idle") { 
            Clear-Pools
        }

        $Session.Remove("EndCycleTime")
        $Session.Remove("Timer")

        # Must close runspace after miners were stopped, otherwise methods don't work any longer
        $Global:CoreCycleRunspace.PowerShell.Dispose()
        $Global:CoreCycleRunspace.Close()
        $Global:CoreCycleRunspace.Dispose()

        $Global:CoreCycleRunspace.PSObject.Properties.Remove("Job")
        $Global:CoreCycleRunspace.PSObject.Properties.Remove("PowerShell")
        $Global:CoreCycleRunspace.PSObject.Properties.Remove("StartTime")

        Remove-Variable CoreCycleRunspace -Scope Global
    }
}

function Start-Brain { 

    param (
        [Parameter (Mandatory = $false)]
        [String[]]$Name
    )

    if (Test-Path -LiteralPath ".\Brains" -PathType Container) { 

        # Starts Brains if necessary
        $BrainsStarted = @()
        $Name.Where({ $Session.Config.PoolsConfig.$_.BrainConfig -and -not $Session.Brains.$_ }).ForEach(
            { 
                $BrainScript = ".\Brains\$($_).ps1"
                if (Test-Path -LiteralPath $BrainScript -PathType Leaf) { 
                    $Session.Brains.$_ = [RunspaceFactory]::CreateRunspace()
                    $Session.Brains.$_.ApartmentState = "STA"
                    $Session.Brains.$_.Name = "Brain_$($_)"
                    $Session.Brains.$_.ThreadOptions = "ReuseThread"
                    $Session.Brains.$_.Open()

                    $Session.Brains.$_.SessionStateProxy.SetVariable("Config", $Config)
                    $Session.Brains.$_.SessionStateProxy.SetVariable("Session", $Session)
                    $Session.Brains.$_.SessionStateProxy.SetVariable("Stats", $Stats)
                    [Void]$Session.Brains.$_.SessionStateProxy.Path.SetLocation($Session.MainPath)

                    $PowerShell = [PowerShell]::Create()
                    $PowerShell.Runspace = $Session.Brains[$_]
                    $Session.Brains.$_ | Add-Member Job ($Powershell.AddScript($BrainScript).BeginInvoke())
                    $Session.Brains.$_ | Add-Member PowerShell $PowerShell
                    $Session.Brains.$_ | Add-Member StartTime ([DateTime]::Now.ToUniversalTime())

                    $BrainsStarted += $_
                }
            }
        )
        if ($BrainsStarted.Count -gt 0) { Write-Message -Level Info "Pool brain backgound process$(if ($BrainsStarted.Count -gt 1) { "es" }) for $($BrainsStarted -join ", " -replace ",([^,]*)$", " &`$1") started." }
    }
    else { 
        Write-Message -Level Error "Failed to start Pool brain backgound process$(if ($BrainsStarted.Count -gt 1) { "es" }). Directory '.\Brains' is missing."
    }
}

function Stop-Brain { 

    param (
        [Parameter (Mandatory = $false)]
        [String[]]$Name = $Session.Brains.Keys
    )

    if ($Name) { 

        $BrainsStopped = @()

        $Name.Where({ $Session.Brains.$_ }).ForEach(
            { 
                # Stop Brains
                $Session.Brains.$_.PowerShell.Stop()
                $Session.Brains.$_.PowerShell.Runspace.Dispose()
                $Session.Brains.$_.PowerShell.Dispose()
                $Session.Brains.$_.Close()
                $Session.Brains.$_.Dispose()

                $Session.Brains.$_.PSObject.Properties.Remove("Job")
                $Session.Brains.$_.PSObject.Properties.Remove("PowerShell")
                $Session.Brains.$_.PSObject.Properties.Remove("StartTime")

                $Session.Brains.Remove($_)
                $Session.BrainData.Remove($_)

                $BrainsStopped += $_
            }
        )
        if ($BrainsStopped.Count -gt 0) { 
            Write-Message -Level Info "Pool brain backgound process$(if ($BrainsStopped.Count -gt 1) { "es" }) for $(($BrainsStopped | Sort-Object) -join ", " -replace ",([^,]*)$", " &`$1") stopped."
        }
    }
}

function Start-BalancesTracker { 

    if (Test-Path -LiteralPath ".\Balances" -PathType Container) { 
        if (-not $Global:BalancesTrackerRunspace) { 
            $Global:BalancesTrackerRunspace = [RunspaceFactory]::CreateRunspace()
            $Global:BalancesTrackerRunspace.ApartmentState = "STA"
            $Global:BalancesTrackerRunspace.Name = "BalancesTracker"
            $Global:BalancesTrackerRunspace.ThreadOptions = "ReuseThread"
            $Global:BalancesTrackerRunspace.Open()

            $Global:BalancesTrackerRunspace.SessionStateProxy.SetVariable("Config", $Config)
            $Global:BalancesTrackerRunspace.SessionStateProxy.SetVariable("Session", $Session)
            [Void]$Global:BalancesTrackerRunspace.SessionStateProxy.Path.SetLocation($Session.MainPath)

            $PowerShell = [PowerShell]::Create()
            $PowerShell.Runspace = $Global:BalancesTrackerRunspace
            [Void]$Powershell.AddScript("$($Session.MainPath)\Includes\BalancesTracker.ps1")
            $Global:BalancesTrackerRunspace | Add-Member PowerShell $PowerShell
        }
        if ($Global:BalancesTrackerRunspace.Job.IsCompleted -ne $false) { 
            $Global:BalancesTrackerRunspace | Add-Member Job ($Global:BalancesTrackerRunspace.PowerShell.BeginInvoke()) -Force
            $Global:BalancesTrackerRunspace | Add-Member StartTime ([DateTime]::Now.ToUniversalTime()) -Force
            $Session.BalancesTrackerRunning = $true

            Write-Message -Level Info "Balances tracker background process started."
        }
    }
    else { 
        Write-Message -Level Error "Failed to start Balances tracker. Directory '.\Balances' is missing."
    }
}

function Stop-BalancesTracker { 

    if ($Global:BalancesTrackerRunspace) { 
        if ($Global:BalancesTrackerRunspace.Job.IsCompleted -eq $false) { 
            $Global:BalancesTrackerRunspace.PowerShell.Stop()

            $Session.BalancesTrackerRunning = $false

            Write-Message -Level Info "Balances tracker background process stopped."
        }

        $Global:BalancesTrackerRunspace.PowerShell.Dispose()
        $Global:BalancesTrackerRunspace.Close()
        $Global:BalancesTrackerRunspace.Dispose()

        $Global:BalancesTrackerRunspace.PSObject.Properties.Remove("Job")
        $Global:BalancesTrackerRunspace.PSObject.Properties.Remove("PowerShell")
        $Global:BalancesTrackerRunspace.PSObject.Properties.Remove("StartTime")

        Remove-Variable BalancesTrackerRunspace -Scope Global
    }
}

function Get-Rate { 

    $RatesCacheFileName = "$($Session.MainPath)\Cache\Rates.json"

    # Use stored currencies from last run
    if (-not $Session.BalancesCurrencies -and $Session.Config.BalancesTrackerPollInterval) { $Session.BalancesCurrencies = @($Session.Rates.PSObject.Properties.Name -creplace "^m") }

    $Session.AllCurrencies = @(@("USD") + @($Session.Config.FIATcurrency) + @($Session.Config.Wallets.psBase.Keys) + @($Session.Config.ExtraCurrencies) + @($Session.BalancesCurrencies) -replace "mBTC", "BTC") | Where-Object { $_ } | Sort-Object -Unique

    # Read exchange rates from min-api.cryptocompare.com, use cached data as fallback
    try { 
        $TSymBatches = @()
        $TSyms = "BTC"
        # A maximum of 99 currencies per request is supported
        $Session.AllCurrencies.Where({ "BTC", "INVALID" -notcontains $_ }).ForEach(
            { 
                if (($TSyms.Length + $_.Length) -lt 99) { 
                    $TSyms = "$TSyms,$($_)"
                }
                else { 
                    $TSymBatches += $TSyms
                    $TSyms = $_
                }
            }
        )
        $TSymBatches += $TSyms

        $Rates = [PSCustomObject]@{ BTC = [PSCustomObject]@{ } }
        $TSymBatches.ForEach(
            { 
                $Response = Invoke-RestMethod -Uri "https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC&tsyms=$($_)$(if ($Session.Config.CryptoCompareAPIKeyParam) { "&api_key=$($Session.Config.CryptoCompareAPIKeyParam)" })&extraParams=$($Session.Branding.BrandWebSite) version $($Session.Branding.Version)" -TimeoutSec 5 -ErrorAction Ignore
                if ($Response.BTC) { 
                    $Response.BTC.ForEach(
                        { 
                            $_.PSObject.Properties.ForEach({ $Rates.BTC | Add-Member @{ "$($_.Name)" = $_.Value } -Force })
                        }
                    )
                }
                elseif ($Response.Message -eq "You are over your rate limit please upgrade your account!") { 
                    Write-Message -Level Error "min-api.cryptocompare.com API rate exceeded. You need to register an account with cryptocompare.com and add the API key as 'CryptoCompareAPIKeyParam' to the configuration file '$($Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'."
                }
            }
        )
        Remove-Variable TSyms, TSymBatches

        if ($Currencies = $Rates.BTC.PSObject.Properties.Name) { 
            # Add mBTC
            if ($Session.Config.UsemBTC) { 
                $Currencies += "mBTC"
                $Rates.BTC | Add-Member @{ "mBTC" =  1000 }
            }

            $Currencies.Where({ $_ -ne "BTC" }).ForEach(
                { 
                    $Currency = $_
                    $Rates | Add-Member @{ $Currency = [PSCustomObject]@{ } }
                    $Rates.BTC.PSObject.Properties.Name.ForEach(
                        { 
                            $Rates.$Currency | Add-Member $_ ([Double]($Rates.BTC.$_ / $Rates.BTC.$Currency))
                        }
                    )
                }
            )
            Remove-Variable Currency -ErrorAction Ignore

            Write-Message -Level Verbose "Loaded currency exchange rates from 'min-api.cryptocompare.com'.$(if ($Session.RatesMissingCurrencies = Compare-Object @($Currencies.Where({ $_ -ne "mBTC" }) | Select-Object) @($Session.AllCurrencies | Select-Object) -PassThru) { " API does not provide rates for $($Session.RatesMissingCurrencies -join ", " -replace ",([^,]*)$", " &`$1"). $($Session.Branding.ProductLabel) cannot calculate the FIAT or BTC value for $(if ($Session.RatesMissingCurrencies.Count -ne 1) { "these currencies" } else { "this currency" })." })"
            if ($Session.Config.FIATcurrency -in $Session.RatesMissingCurrencies) { 
                $FallbackCurrency = @(@($Session.Config.ExtraCurrencies) + @("USD")).where( { $_ -in $Session.FIATcurrencies.Keys -and $Rates.$_ } )[0]
                Write-Message -Level Warn "API does not provide exchange rate for configured main FIAT currency $($Session.Config.FIATcurrency) ($($Session.FIATcurrencies.($Session.Config.FIATcurrency))). Using $FallbackCurrency ($($Session.FIATcurrencies.$FallbackCurrency)) as fallback."
                $Session.Config.FIATcurrency = $FallbackCurrency
                Remove-Variable FallbackCurrency
            }
            $Session.Rates = $Rates
            $Session.RatesUpdated = [DateTime]::Now.ToUniversalTime()
            $Session.RefreshTimestamp = (Get-Date -Format "G")
            $Session.Rates | ConvertTo-Json -Depth 5 | Out-File -LiteralPath $RatesCacheFileName -Force -ErrorAction Ignore
        }
    }
    catch { 
        $RatesCache = ([System.IO.File]::ReadAllLines($RatesCacheFileName) | ConvertFrom-Json -ErrorAction Ignore)
        if ($RatesCache.PSObject.Properties.Name) { 
            $Session.Rates = $RatesCache
            Write-Message -Level Warn "Could not load exchange rates from 'min-api.cryptocompare.com'. Using cached data from $((Get-Item -Path $RatesCacheFileName).LastWriteTime)."
        }
        else { 
            Write-Message -Level Warn "Could not load exchange rates from 'min-api.cryptocompare.com'."
        }
        # Trigger next attempt 1 minute before 'normal' refresh
        $Session.RatesUpdated = [DateTime]::Now.ToUniversalTime().AddMinutes(-14)
    }
}

function Write-Message { 

    param (
        [Parameter (Mandatory = $true, ValueFromPipeline = $true)]
        [String]$Message,
        [Parameter (Mandatory = $false)]
        [String]$Level = "Info",
        [Parameter (Mandatory = $false)]
        [Boolean]$Console = $true
    )

    if (-not $Session.Config.Keys.Count -or $Session.Config.LogLevel -contains $Level) { 

        $Message = $Message -replace "`n|(?:<br>)+|(?:&ensp;)+", " "

        # Make sure we are in main script
        if ($Console -and $Host.Name -match "Visual Studio Code Host|ConsoleHost") { 
            # Write to console
            switch ($Level) { 
                "Debug"   { Write-Host $Message -ForegroundColor "Blue" -NoNewline; break }
                "Error"   { Write-Host $Message -ForegroundColor "Red" -NoNewline; break }
                "Info"    { Write-Host $Message -ForegroundColor "White" -NoNewline; break }
                "MemDbg"  { Write-Host $Message -ForegroundColor "Cyan" -NoNewline; break }
                "Verbose" { Write-Host $Message -ForegroundColor "Yello" -NoNewline; break }
                "Warn"    { Write-Host $Message -ForegroundColor "Magenta" -NoNewline }
            }
            $Session.CursorPosition = $Host.UI.RawUI.CursorPosition
            Write-Host ""
        }

        switch ($Level) { 
            "Debug"   { $Message = "[DEBUG  ] $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") $Message"; break }
            "Error"   { $Message = "[ERROR  ] $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") $Message"; break }
            "Info"    { $Message = "[INFO   ] $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") $Message"; break }
            "MemDbg"  { $Message = "[MEMDBG ] $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") $Message"; break }
            "Verbose" { $Message = "[VERBOSE] $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") $Message"; break }
            "Warn"    { $Message = "[WARN   ] $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") $Message"; break }
            default   { $Message = "[-------] $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") $Message" }
        }

        if ($Session.TextBoxSystemLog) { 
            $SelectionLength = $Session.TextBoxSystemLog.SelectionLength
            $SelectionStart = $Session.TextBoxSystemLog.SelectionStart

            # Keep only 200 lines, more lines impact performance
            if ($Session.TextBoxSystemLog.Lines.Count -gt 200) { 
                $TextLength = $Session.TextBoxSystemLog.TextLength
                $Session.TextBoxSystemLog.Lines = $Session.TextBoxSystemLog.Lines | Select-Object -Last 200
                $SelectionStart += ($Session.TextBoxSystemLog.TextLength - $TextLength)
            }

            $Session.TextBoxSystemLog.AppendText("`r`n$Message")

            if ($SelectionLength -and $SelectionStart -ge 0) { 
                $Session.TextBoxSystemLog.Select($SelectionStart, $SelectionLength)
            }
        }

        # Get mutex. Mutexes are shared across all threads and processes.
        # This lets us ensure only one thread is trying to write to the file at a time.
        $Mutex = [System.Threading.Mutex]::new($false, "$($Session.Branding.ProductLabel)_LogFile")

        # Attempt to aquire mutex, waiting up to 1 second if necessary
        if ($Mutex.WaitOne(1000)) { 
            $Session.LogFile = "$($Session.MainPath)\Logs\$($Session.Branding.ProductLabel)_$(Get-Date -Format "yyyy-MM-dd").log"
            $Message | Out-File -LiteralPath $Session.LogFile -Append -ErrorAction Ignore
            $Mutex.ReleaseMutex()
        }
        $Mutex.Dispose()
        Remove-Variable Mutex
    }
}

# function Write-MonitoringData { 

#     # Updates a remote monitoring server, sending this worker's data and pulling data about other workers

#     # Skip If server and user aren't filled out
#     if (-not $Session.Config.MonitoringServer) { return }
#     if (-not $Session.Config.MonitoringUser) { return }

#     # Build object with just the data we need to send, and make sure to use relative paths so we don't accidentally
#     # reveal someone's windows username or other system information they might not want sent
#     # For the ones that can be an array, comma separate them
#     $Data = @(
#         ($Session.Miners.Where({ $_.Status -eq [MinerStatus]::DryRun -or $_.Status -eq [MinerStatus]::Running }) | Sort-Object { [String]$_.DeviceNames }).ForEach(
#             { 
#                 [PSCustomObject]@{ 
#                     Algorithm      = $_.WorkersRunning.Pool.Algorithm -join ","
#                     Currency       = $Session.Config.FIATcurrency
#                     CurrentSpeed   = $_.Hashrates_Live
#                     Earnings       = ($_.WorkersRunning.Earnings | Measure-Object -Sum).Sum
#                     EstimatedSpeed = $_.WorkersRunning.Hashrate
#                     Name           = $_.Name
#                     Path           = Resolve-Path -Relative $_.Path
#                     Pool           = $_.WorkersRunning.Pool.Name -join ","
#                     Profit         = if ($_.Profit) { $_.Profit } elseif ($Session.CalculatePowerCost) { ($_.WorkersRunning.Profit | Measure-Object -Sum).Sum - $_.PowerConsumption_Live * $Session.PowerCostBTCperW } else { [Double]::NaN }
#                     Type           = $_.Type
#                 }
#             }
#         )
#     )

#     $Body = @{ 
#         user    = $Session.Config.MonitoringUser
#         worker  = $Session.Config.WorkerName
#         version = "$($Session.Branding.ProductLabel) $($Session.Branding.Version.ToString())"
#         status  = $Session.NewMiningStatus
#         profit  = if ([Double]::IsNaN($Session.MiningProfit)) { "n/a" } else { [String]$Session.MiningProfit } # Earnings is NOT profit! Needs to be changed in mining monitor server
#         data    = ConvertTo-Json $Data
#     }

#     # Send the request
#     try { 
#         $Response = Invoke-RestMethod -Uri "$($Session.Config.MonitoringServer)/api/report.php" -Method Post -Body $Body -TimeoutSec 10 -ErrorAction Stop
#         if ($Response -eq "Success") { 
#             Write-Message -Level Verbose "Reported worker status to monitoring server '$($Session.Config.MonitoringServer)' [ID $($Session.Config.MonitoringUser)]."
#         }
#         else { 
#             Write-Message -Level Verbose "Reporting worker status to monitoring server '$($Session.Config.MonitoringServer)' failed: [$($Response)]."
#         }
#     }
#     catch { 
#         Write-Message -Level Warn "Monitoring: Unable to send status to monitoring server '$($Session.Config.MonitoringServer)' [ID $($Session.Config.MonitoringUser)]."
#     }
# }

# function Read-MonitoringData { 

#     if ($Session.Config.ShowWorkerStatus -and $Session.Config.MonitoringUser -and $Session.Config.MonitoringServer -and $Session.WorkersLastUpdated -lt [DateTime]::Now.AddSeconds(-30)) { 
#         try { 
#             $Workers = Invoke-RestMethod -Uri "$($Session.Config.MonitoringServer)/api/workers.php" -Method Post -Body @{ user = $Session.Config.MonitoringUser } -TimeoutSec 10 -ErrorAction Stop
#             # Calculate some additional properties and format others
#             $Workers.ForEach(
#                 { 
#                     # Convert the unix timestamp to a datetime object, taking into account the local time zone
#                     $_ | Add-Member @{ date = [TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($_.lastseen)) } -Force

#                     # If a machine hasn't reported in for more than 10 minutes, mark it as offline
#                     if ((New-TimeSpan -Start $_.date -End ([DateTime]::Now)).TotalMinutes -gt 10) { $_.status = "Offline" }
#                 }
#             )
#             $Session.Workers = $Workers
#             $Session.WorkersLastUpdated = ([DateTime]::Now)

#             Write-Message -Level Verbose "Retrieved worker status from '$($Session.Config.MonitoringServer)' [ID $($Session.Config.MonitoringUser)]."
#         }
#         catch { 
#             Write-Message -Level Warn "Monitoring: Unable to retrieve worker data from '$($Session.Config.MonitoringServer)' [ID $($Session.Config.MonitoringUser)]."
#         }
#     }

#     return $null
# }

function Get-TimeSince { 
    # Show friendly time since in days, hours, minutes and seconds

    param (
        [Parameter (Mandatory = $true)]
        [DateTime]$TimeStamp
    )

    $TimeSpan = New-TimeSpan -Start $TimeStamp -End ([DateTime]::Now)
    $TimeSince = ""

    if ($TimeSpan.Days -ge 1)    { $TimeSince = "{0:n0} day$(if ($TimeSpan.Days -ne 1) { "s" })" -f $TimeSpan.Days }
    if ($TimeSpan.Hours -ge 1)   { $TimeSince = "$TimeSince {0:n0} hour$(if ($TimeSpan.Hours -ne 1) { "s" })" -f $TimeSpan.Hours }
    if ($TimeSpan.Minutes -ge 1) { $TimeSince = "$TimeSince {0:n0} minute$(if ($TimeSpan.Minutes -ne 1) { "s" })" -f $TimeSpan.Minutes }
    if ($TimeSpan.Seconds -ge 1) { $TimeSince = "$TimeSince {0:n0} second$(if ($TimeSpan.Seconds -ne 1) { "s" })" -f $TimeSpan.Seconds }
    if ($TimeSince) { $TimeSince += " ago" } else { $TimeSince = "just now" }

    return $TimeSince
}

function Merge-Hashtable { 

    param (
        [Parameter (Mandatory = $true)]
        [Object]$HT1,
        [Parameter (Mandatory = $true)]
        [Object]$HT2,
        [Parameter (Mandatory = $false)]
        [Boolean]$Unique = $false
    )

    $HT1 = [System.Collections.SortedList]::New($HT1, [StringComparer]::OrdinalIgnoreCase)
    $HT2 = [System.Collections.SortedList]::New($HT2, [StringComparer]::OrdinalIgnoreCase)

    $HT2.Keys.ForEach(
        { 
            if ($HT1.$_) { 
                if ($HT1.$_.GetType().Name -eq "Array" -or $HT1.$_.GetType().BaseType -match "array|System\.Array") { 
                    if ($HT2.$_) { 
                        $HT1.$_ += $HT2.$_
                        if ($Unique) { $HT1.$_ = ($HT1.$_ | Sort-Object -Unique) -as [Array] }
                    }
                }
                if ($HT1.$_.GetType().Name -eq "OrderedHashtable" -or $HT1.$_.GetType().BaseType -match "hashtable|System\.Collections\.Hashtable") { 
                    $HT1[$_] = Merge-Hashtable -HT1 $HT1[$_] -HT2 $HT2.$_ -Unique $Unique
                }
            }
            else { 
                $HT1.$_ = $HT2.$_ -as $HT2.$_.GetType()
            }
        }
    )

    return $HT1
}

function Update-ConfigFile { 

    param (
        [Parameter (Mandatory = $true)]
        [String]$ConfigFile
    )

    $Session.ConfigurationHasChangedDuringUpdate = @()

    # NiceHash Internal is no longer available as of November 12, 2024
    if ($Config.PoolName -contains "NiceHash") { 
        if ($null -ne $Config.NiceHashWalletIsInternal -and -not $Config.NiceHashWalletIsInternal) { 
            Write-Message -Level Warn "Pool configuration changed during update (NiceHash [External] removed - to mine with NiceHash you must register)."
            $Session.ConfigurationHasChangedDuringUpdate += "- Pool 'NiceHash' [External] removed"
            $Config.PoolName = $Config.PoolName -notmatch "NiceHash"
            $Config.Remove("NiceHashWallet")
        }
    }
    $Config.Remove("NiceHashWalletIsInternal")

    # WorkerName must not contain '.'
    if ($Config.WorkerName -match "\.") { 
        $Config.WorkerName = $Config.WorkerName -replace "\."
        $Session.ConfigurationHasChangedDuringUpdate += "- WorkerName adjusted (no '.' allowed)"
    }

    # Removed pools
    ("AHashPool", "BlockMasters", "NLPool", "MiningPoolHub", "ProHashing", "ZergPool").ForEach(
        { 
            if ($Config.PoolName -like "$_*") { 
                Write-Message -Level Warn "Pool configuration changed during update ($($Config.PoolName -like "$_*" -join "; ") removed)."
                $Session.ConfigurationHasChangedDuringUpdate += "- Pool '$($Config.PoolName -like "$_*" -join "; ")' removed"
                $Config.PoolName = $Config.PoolName -notlike "$_*"
            }
            if ($Config.BalancesTrackerExcludePools -like "$_*") { 
                Write-Message -Level Warn "BalancesTrackerExcludePools changed during update ($($Config.BalancesTrackerExcludePools -like "$_*" -join "; ") removed)."
                $Session.ConfigurationHasChangedDuringUpdate += "- BalancesTrackerExcludePools '$($Config.BalancesTrackerExcludePools -like "$_*" -join "; ")' removed"
                $Config.BalancesTrackerExcludePools = $Config.BalancesTrackerExcludePools -notlike "$_*"
            }
        }
    )

    # Available regions have changed
    if ((Get-Region $Config.Region -List) -notcontains $Config.Region) { 
        $OldRegion = $Config.Region
        # Write message about new mining regions
        $Config.Region = switch ($OldRegion) { 
            "Brazil"       { "USA West"; break }
            "Europe East"  { "Europe"; break }
            "Europe North" { "Europe"; break }
            "India"        { "Asia"; break }
            "US"           { "USA West"; break }
            default        { "Europe" }
        }
        Write-Message -Level Warn "Available mining locations have changed during update ($OldRegion -> $($Config.Region))".
        $Session.ConfigurationHasChangedDuringUpdate += "- Available mining locations have changed ($OldRegion -> $($Config.Region))"
        Remove-Variable OldRegion
    }

    # Changed config items
    ($Config.GetEnumerator().Name | Sort-Object).ForEach(
        { 
            switch ($_) { 
                # To replace a configuration item: 
                # "OldConfigItemName" { $Config.NewConfigItemName = $Config.$_; $Config.Remove($_) }
                "BalancesShowInMainCurrency"  { $Config.BalancesShowInFIATcurrency = $Config.$_; $Config.Remove($_); break }
                "ExcludeMinerName"            { $Config.$_ = $Config.$_ -replace '^-'; break }
                "LogBalanceAPIResponse"       { $Config.BalancesTrackerLogAPIResponse = $Config.$_; $Config.Remove($_); break }
                "LogToScreen"                 { $Config.LogLevel = $Config.$_; $Config.Remove($_); break }
                "MainCurrency"                { $Config.FIATcurrency = $Config.$_; $Config.Remove($_); break }
                "Pools"                       { $Config.PowerConsumptionIdleSystem = $Config.$_; $Config.Remove($_); break }
                "PowerConsumptionIdleSystemW" { $Config.PowerConsumptionIdleSystem = $Config.$_; $Config.Remove($_); break }
                "ShowAccuracy"                { $Config.ShowColumnAccuracy = $Config.$_; $Config.Remove($_); break }
                "ShowAccuracyColumn"          { $Config.ShowColumnAccuracy = $Config.$_; $Config.Remove($_); break }
                "ShowAllOptimalMiners"        { $Config.ShowAllOptimalMiners = $Config.$_; $Config.Remove($_); break }
                "ShowCoinName"                { $Config.ShowColumnCoinName = $Config.$_; $Config.Remove($_); break }
                "ShowCoinNameColumn"          { $Config.ShowColumnCoinName = $Config.$_; $Config.Remove($_); break }
                "ShowCurrency"                { $Config.ShowColumnCurrency = $Config.$_; $Config.Remove($_); break }
                "ShowCurrencyColumn"          { $Config.ShowColumnCurrency = $Config.$_; $Config.Remove($_); break }
                "ShowEarning"                 { $Config.ShowColumnEarnings = $Config.$_; $Config.Remove($_); break }
                "ShowEarningColumn"           { $Config.ShowColumnEarnings = $Config.$_; $Config.Remove($_); break }
                "ShowEarningBias"             { $Config.ShowColumnEarningsBias = $Config.$_; $Config.Remove($_); break }
                "ShowEarningBiasColumn"       { $Config.ShowColumnEarningsBias = $Config.$_; $Config.Remove($_); break }
                "ShowHashrate"                { $Config.ShowColumnHashrate = $Config.$_; $Config.Remove($_); break }
                "ShowHashrateColumn"          { $Config.ShowColumnHashrate = $Config.$_; $Config.Remove($_); break }
                "ShowMinerFee"                { $Config.ShowColumnMinerFee = $Config.$_; $Config.Remove($_); break }
                "ShowMinerFeeColumn"          { $Config.ShowColumnMinerFee = $Config.$_; $Config.Remove($_); break }
                "ShowPoolFee"                 { $Config.ShowColumnPoolFee = $Config.$_; $Config.Remove($_); break }
                "ShowPoolFeeColumn"           { $Config.ShowColumnPoolFee = $Config.$_; $Config.Remove($_); break }
                "ShowProfit"                  { $Config.ShowColumnProfit = $Config.$_; $Config.Remove($_); break }
                "ShowProfitColumn"            { $Config.ShowColumnProfit = $Config.$_; $Config.Remove($_); break }
                "ShowProfitBias"              { $Config.ShowColumnProfitBias = $Config.$_; $Config.Remove($_); break }
                "ShowProfitBiasColumn"        { $Config.ShowColumnProfitBias = $Config.$_; $Config.Remove($_); break }
                "ShowPowerConsumption"        { $Config.ShowColumnPowerConsumption = $Config.$_; $Config.Remove($_); break }
                "ShowPowerConsumptionColumn"  { $Config.ShowColumnPowerConsumption = $Config.$_; $Config.Remove($_); break }
                "ShowPowerCost"               { $Config.ShowColumnPowerCost = $Config.$_; $Config.Remove($_); break }
                "ShowPowerCostColumn"         { $Config.ShowColumnPowerCost = $Config.$_; $Config.Remove($_); break }
                "ShowPoolBalances"            { $Config.ShowColumnPoolBalances = $Config.$_; $Config.Remove($_); break }
                "ShowPoolBalancesColumn"      { $Config.ShowColumnPoolBalances = $Config.$_; $Config.Remove($_); break }
                "ShowUser"                    { $Config.ShowColumnUser = $Config.$_; $Config.Remove($_); break }
                "ShowUserColumn"              { $Config.ShowColumnUser = $Config.$_; $Config.Remove($_); break }
                "UnrealMinerEarningFactor"    { $Config.UnrealisticMinerEarningsFactor = $Config.$_; $Config.Remove($_); break }
                "UnrealPoolPriceFactor"       { $Config.UnrealisticPoolPriceFactor = $Config.$_; $Config.Remove($_); break }

                # Remove unsupported config items
                default { if ($_ -notin @(@($Session.AllCommandLineParameters.psBase.Keys) + @("CryptoCompareAPIKeyParam") + @("DryRun") + @("PoolsConfig"))) { $Config.Remove($_) } }
            }
        }
    )

    if (-not $Session.FreshConfig) { 
        $Config.ConfigFileVersion = $Session.Branding.Version.ToString()
        Write-Configuration -Config $Config
        $Message = "Updated configuration file '$($Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))' to version $($Session.Branding.Version.ToString())."
        if ($Host.Name -match "ConsoleHost|Visual Studio Code Host") { $CursorPosition = $Host.UI.RawUI.CursorPosition }
        Write-Message -Level Verbose $Message
        if ($Host.Name -match "ConsoleHost|Visual Studio Code Host") { 
            try { 
                [Console]::SetCursorPosition($CursorPosition.X + $Message.length, $CursorPosition.y)
                Write-Host " ✔" -ForegroundColor Green
            } catch { }
        }
        Remove-Variable Message
    }
}

function Write-Configuration { 

    param (
        [Parameter (Mandatory = $true)]
        [PSCustomObject]$Config
    )

    if (-not (Test-Path -LiteralPath ".\Config" -PathType Container)) { $null = (New-Item -Path . -Name "Config" -ItemType Directory) }

    if (Test-Path -LiteralPath $Session.ConfigFile -PathType Leaf) { 
        Copy-Item -Path $Session.ConfigFile -Destination "$($Session.ConfigFile)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").backup"
        Get-ChildItem -Path "$($Session.ConfigFile)_*.backup" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse # Keep 10 backup copies
    }

    $NewConfig = $Config.Clone()

    $NewConfig.Remove("ConfigFile")
    $NewConfig.Remove("PoolsConfig")

    $Session.FreshConfig = $false

    $Header = 
    "// This file was generated by $($Session.Branding.ProductLabel) v$($Session.Branding.Version) on $((Get-Date).ToString())
// $($Session.Branding.ProductLabel) will automatically add / convert / rename / update new settings when updating to a new version
"
    # Get mutex. Mutexes are shared across all threads and processes.
    # This lets us ensure only one thread is trying to write to the file at a time.
    $Mutex = [System.Threading.Mutex]::new($false, "$($Session.Branding.ProductLabel)_ConfigFile")

    # Attempt to aquire mutex, waiting up to 1 second if necessary
    if ($Mutex.WaitOne(1000)) { 
        "$Header$($NewConfig | ConvertTo-Json -Depth 10)" | Out-File -LiteralPath $Session.ConfigFile -Force
        $Mutex.ReleaseMutex()
    }
    $Mutex.Dispose()
    Remove-Variable Mutex
}

function Edit-File { 
    # Opens file in notepad. Notepad will remain in foreground until closed.
    param (
        [Parameter (Mandatory = $false)]
        [String]$FileName
    )

    $FileWriteTime = (Get-Item -LiteralPath $FileName).LastWriteTime

    if ($FileName -eq $Session.PoolsConfigFile.Replace($PWD, ".")) { 
        if (Test-Path -LiteralPath $Session.PoolsConfigFile -PathType Leaf) { 
            Copy-Item -Path $Session.PoolsConfigFile -Destination "$($Session.PoolsConfigFile)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").backup"
            Get-ChildItem -Path "$($Session.PoolsConfigFile)_*.backup" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse # Keep 10 backup copies
        }
        else { 
            Copy-Item -LiteralPath "$PWD\Data\PoolsConfig-Template.json" -Destination $FileName -ErrorAction Ignore
        }
    }

    if ($FileName -eq $Session.ConfigFile.Replace($PWD, ".")) { 
        if (Test-Path -LiteralPath $Session.ConfigFile -PathType Leaf) { 
            Copy-Item -Path $Session.ConfigFile -Destination "$($Session.ConfigFile)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").backup"
            Get-ChildItem -Path "$($Session.ConfigFile)_*.backup" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse # Keep 10 backup copies
        }
    }

    if (-not ($NotepadProcessId = (Get-CimInstance CIM_Process).Where({ $_.CommandLine -like "*\Notepad.exe* $($FileName)" })[0].ProcessId)) { 
        $NotepadProcessId = (Start-Process -FilePath Notepad.exe -ArgumentList $FileName -PassThru).Id
    }

    # Check if the window is not already in foreground
    $FGWindowPid = [IntPtr]::Zero
    while (Get-Process -Id $NotepadProcessId) { 
        try { 
            if ($MainWindowHandle -le 0) { $MainWindowHandle = (Get-Process -Id $NotepadProcessId -ErrorAction Ignore).MainWindowHandle }
            if ($MainWindowHandle -le 0) { $MainWindowHandle = (Get-Process).Where({ $_.Parent.Id -eq $NotepadProcessId }).MainWindowHandle }

            $null = [Win32]::GetWindowThreadProcessId([Win32]::GetForegroundWindow(), [ref]$FGWindowPid)
            if ($NotepadProcessId -ne $FGWindowPid) { 
                if ([Win32]::GetForegroundWindow() -ne $MainWindowHandle) { 
                    $null = [Win32]::ShowWindowAsync($MainWindowHandle, 6) # SW_MINIMIZE
                    $null = [Win32]::ShowWindowAsync($MainWindowHandle, 9) # SW_RESTORE
                }
            }
            Start-Sleep -Milliseconds 100
        }
        catch { }
    }
    if ((Get-Item -Path $FileName).LastWriteTime -gt $FileWriteTime) { 
        if (($FileName -eq $Session.PoolsConfigFile.Replace($PWD, ".")) -or ($FileName -eq $Session.ConfigFile.Replace($PWD, "."))) { 
            Write-Message -Level Verbose "Configuration saved to '$FileName'. It will become fully active in the next cycle."
            "Configuration saved to '$FileName'.`nIt will become active in the next cycle."
        }
    }
    else { 
        "No changes to '$FileName' were made."
    }
    Remove-Variable FGWindowPid, FileName, FileWriteTime, MainWindowHandle, NotepadProcessId -ErrorAction Ignore
}

function Get-SortedObject { 

    param (
        [Parameter (Mandatory = $false, ValueFromPipeline = $true)]
        [Object]$Object
    )

    switch -Regex ($Object.GetType().Name) { 
        "PSCustomObject" { 
            $SortedObject = [PSCustomObject]@{ }
            ($Object.PSObject.Properties.Name | Sort-Object).ForEach(
                { 
                    if ($Object.$_.GetType().Name -eq "Array" -or $Object.$_.GetType().BaseType -match "array|System\.Array") { 
                        if ($Object[$_].Count -lt 2) { 
                            $SortedObject | Add-Member $_ ([System.Collections.Generic.SortedSet[Object]]([Array]$Object[$_]))
                        }
                        else { 
                            $SortedObject | Add-Member $_ ([System.Collections.Generic.SortedSet[Object]]($Object[$_]))
                        }
                    }
                    elseif ($Object.$_.GetType().Name -match "OrderedHashtable|PSCustomObject" -or $Object.$_.GetType().BaseType -match "hashtable|System\.Collections\.Hashtable") { 
                        $SortedObject | Add-Member $_ (Get-SortedObject $Object.$_)
                    }
                    else { 
                        $SortedObject | Add-Member $_ $Object.$_
                    }
                }
            )
            break
        }
        "Hashtable|OrderedDictionary|OrderedHashTable|SyncHashtable" { 
            $SortedObject = [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase) # as case insensitve sorted hashtable
            ($Object.GetEnumerator().Name | Sort-Object).ForEach(
                { 
                    if ($Object[$_].GetType().Name -eq "Array" -or $Object[$_].GetType().BaseType -match "array|System\.Array") { 
                        if ($Object[$_].Count -lt 2) { 
                            $SortedObject[$_] = [System.Collections.Generic.SortedSet[Object]]([Array]$Object[$_])
                        }
                        else { 
                            $SortedObject[$_] = [System.Collections.Generic.SortedSet[Object]]($Object[$_])
                        }
                    }
                    elseif ($Object[$_].GetType().Name -match "OrderedHashtable|PSCustomObject" -or $Object[$_].GetType().BaseType -match "hashtable|System\.Collections\.Hashtable") { 
                        $SortedObject[$_] = Get-SortedObject $Object[$_]
                    }
                    else { 
                        $SortedObject[$_] = $Object[$_]
                    }
                }
            )
            break
        }
        default { 
            $SortedObject = $Object | Sort-Object
        }
    }
    return $SortedObject
}

function Enable-Stat { 

    param (
        [Parameter (Mandatory = $true)]
        [String]$Name
    )

    if ($Stat = Get-Stat -Name $Name) { 

        $Path = "Stats\$Name.txt"
        $Stat.Disabled = $false

        @{ 
            Live                  = [Double]$Stat.Live
            Minute                = [Double]$Stat.Minute
            Minute_Fluctuation    = [Double]$Stat.Minute_Fluctuation
            Minute_5              = [Double]$Stat.Minute_5
            Minute_5_Fluctuation  = [Double]$Stat.Minute_5_Fluctuation
            Minute_10             = [Double]$Stat.Minute_10
            Minute_10_Fluctuation = [Double]$Stat.Minute_10_Fluctuation
            Hour                  = [Double]$Stat.Hour
            Hour_Fluctuation      = [Double]$Stat.Hour_Fluctuation
            Day                   = [Double]$Stat.Day
            Day_Fluctuation       = [Double]$Stat.Day_Fluctuation
            Week                  = [Double]$Stat.Week
            Week_Fluctuation      = [Double]$Stat.Week_Fluctuation
            Duration              = [String]$Stat.Duration
            Updated               = [DateTime]$Stat.Updated
            Disabled              = [Boolean]$Stat.Disabled
        } | ConvertTo-Json | Out-File -LiteralPath $Path -Force
    }
}

function Disable-Stat { 

    param (
        [Parameter (Mandatory = $true)]
        [String]$Name
    )

    $Path = "Stats\$Name.txt"
    $Stat = Get-Stat -Name $Name
    if (-not $Stat) { $Stat = Set-Stat -Name $Name -Value 0 }
    $Stat.Disabled = $true

    @{ 
        Live                  = [Double]$Stat.Live
        Minute                = [Double]$Stat.Minute
        Minute_Fluctuation    = [Double]$Stat.Minute_Fluctuation
        Minute_5              = [Double]$Stat.Minute_5
        Minute_5_Fluctuation  = [Double]$Stat.Minute_5_Fluctuation
        Minute_10             = [Double]$Stat.Minute_10
        Minute_10_Fluctuation = [Double]$Stat.Minute_10_Fluctuation
        Hour                  = [Double]$Stat.Hour
        Hour_Fluctuation      = [Double]$Stat.Hour_Fluctuation
        Day                   = [Double]$Stat.Day
        Day_Fluctuation       = [Double]$Stat.Day_Fluctuation
        Week                  = [Double]$Stat.Week
        Week_Fluctuation      = [Double]$Stat.Week_Fluctuation
        Duration              = [String]$Stat.Duration
        Updated               = [DateTime]$Stat.Updated
        Disabled              = [Boolean]$Stat.Disabled
    } | ConvertTo-Json | Out-File -LiteralPath $Path -Force
}

function Set-Stat { 

    param (
        [Parameter (Mandatory = $true)]
        [String]$Name,
        [Parameter (Mandatory = $true)]
        [Double]$Value,
        [Parameter (Mandatory = $false)]
        [DateTime]$Updated = ([DateTime]::Now),
        [Parameter (Mandatory = $false)]
        [TimeSpan]$Duration,
        [Parameter (Mandatory = $false)]
        [Boolean]$FaultDetection = $true,
        [Parameter (Mandatory = $false)]
        [Boolean]$ChangeDetection = $false,
        [Parameter (Mandatory = $false)]
        [UInt16]$ToleranceExceeded = 3
    )

    $Timer = $Updated = $Updated.ToUniversalTime()

    $Path = "Stats\$Name.txt"
    $SmallestValue = 1E-20
    $Stat = Get-Stat -Name $Name

    if ($Stat -is [Hashtable] -and -not [Double]::IsNaN($Stat.Minute_Fluctuation)) { 
        if (-not $Stat.Timer) { $Stat.Timer = $Stat.Updated.AddMinutes(-1) }
        if (-not $Duration) { $Duration = $Updated - $Stat.Timer }
        if ($Duration -le 0) { return $Stat }

        if ($ChangeDetection -and [Decimal]$Value -eq [Decimal]$Stat.Live) { $Updated = $Stat.Updated }

        if ($FaultDetection) { 
            $FaultFactor = if ($Name -match ".+_Hashrate$") { 0.1 } else { 0.2 }
            $ToleranceMin = $Stat.Week * (1 - $FaultFactor)
            $ToleranceMax = $Stat.Week * (1 + $FaultFactor)
        }
        else { 
            $ToleranceMin = $ToleranceMax = $Value
        }

        if ($Value -lt $ToleranceMin -or $Value -gt $ToleranceMax) { $Stat.ToleranceExceeded ++ }
        else { $Stat.ToleranceExceeded = [UInt16]0 }

        if ($Value -gt 0 -and $Stat.ToleranceExceeded -gt 0 -and $Stat.ToleranceExceeded -lt $ToleranceExceeded -and $Stat.Week -gt 0) { 
            if ($Name -match ".+_Hashrate$") { 
                Write-Message -Level Warn "Error saving hashrate for '$($Name -replace "_Hashrate$")'. $(($Value | ConvertTo-Hash) -replace " ") is outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace " ") to $(($ToleranceMax | ConvertTo-Hash) -replace " ")) [Cycle $($Stats.($Stat.Name).ToleranceExceeded) of $ToleranceExceeded until enforced update]."
            }
            elseif ($Name -match ".+_PowerConsumption") { 
                Write-Message -Level Warn "Error saving power consumption for '$($Name -replace "_PowerConsumption$")'. $($Value.ToString("N2"))W is outside fault tolerance ($($ToleranceMin.ToString("N2"))W to $($ToleranceMax.ToString("N2"))W) [Cycle $($Stats.($Stat.Name).ToleranceExceeded) of $ToleranceExceeded until enforced update]."
            }
            return $Stat
        }
        else { 
            if (-not $Stat.Disabled -and ($Value -eq 0 -or $Stat.ToleranceExceeded -ge $ToleranceExceeded -or $Stat.Week_Fluctuation -ge 1)) { 
                if ($Value -gt 0 -and $Stat.ToleranceExceeded -ge $ToleranceExceeded) { 
                    if ($Name -match ".+_Hashrate$") { 
                        Write-Message -Level Warn "Hashrate '$($Name -replace "_Hashrate$")' was forcefully updated. $(($Value | ConvertTo-Hash) -replace " ") was outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace " ") to $(($ToleranceMax | ConvertTo-Hash) -replace " "))$(if ($Stat.Week_Fluctuation -lt 1) { " for $($Stats.($Stat.Name).ToleranceExceeded) times in a row." })"
                    }
                    elseif ($Name -match ".+_PowerConsumption$") { 
                        Write-Message -Level Warn "Power consumption for '$($Name -replace "_PowerConsumption$")' was forcefully updated. $($Value.ToString("N2"))W was outside fault tolerance ($($ToleranceMin.ToString("N2"))W to $($ToleranceMax.ToString("N2"))W)$(if ($Stat.Week_Fluctuation -lt 1) { " for $($Stats.($Stat.Name).ToleranceExceeded) times in a row." })"
                    }
                }

                Remove-Stat -Name $Name
                $Stat = Set-Stat -Name $Name -Value $Value
            }
            else { 
                $Span_Minute = [Math]::Min($Duration.TotalMinutes / [Math]::Min($Stat.Duration.TotalMinutes, 1), 1)
                $Span_Minute_5 = [Math]::Min(($Duration.TotalMinutes / 5) / [Math]::Min(($Stat.Duration.TotalMinutes / 5), 1), 1)
                $Span_Minute_10 = [Math]::Min(($Duration.TotalMinutes / 10) / [Math]::Min(($Stat.Duration.TotalMinutes / 10), 1), 1)
                $Span_Hour = [Math]::Min($Duration.TotalHours / [Math]::Min($Stat.Duration.TotalHours, 1), 1)
                $Span_Day = [Math]::Min($Duration.TotalDays / [Math]::Min($Stat.Duration.TotalDays, 1), 1)
                $Span_Week = [Math]::Min(($Duration.TotalDays / 7) / [Math]::Min(($Stat.Duration.TotalDays / 7), 1), 1)

                $Stat.Live = $Value
                $Stat.Minute_Fluctuation = ((1 - $Span_Minute) * $Stat.Minute_Fluctuation) + ($Span_Minute * ([Math]::Abs($Value - $Stat.Minute) / [Math]::Max([Math]::Abs($Stat.Minute), $SmallestValue)))
                $Stat.Minute = (1 - $Span_Minute) * $Stat.Minute + $Span_Minute * $Value
                $Stat.Minute_5_Fluctuation = (1 - $Span_Minute_5) * $Stat.Minute_5_Fluctuation + $Span_Minute_5 * ([Math]::Abs($Value - $Stat.Minute_5) / [Math]::Max([Math]::Abs($Stat.Minute_5), $SmallestValue))
                $Stat.Minute_5 = (1 - $Span_Minute_5) * $Stat.Minute_5 + $Span_Minute_5 * $Value
                $Stat.Minute_10_Fluctuation = (1 - $Span_Minute_10) * $Stat.Minute_10_Fluctuation + $Span_Minute_10 * ([Math]::Abs($Value - $Stat.Minute_10) / [Math]::Max([Math]::Abs($Stat.Minute_10), $SmallestValue))
                $Stat.Minute_10 = (1 - $Span_Minute_10) * $Stat.Minute_10 + $Span_Minute_10 * $Value
                $Stat.Hour_Fluctuation = (1 - $Span_Hour) * $Stat.Hour_Fluctuation + $Span_Hour * ([Math]::Abs($Value - $Stat.Hour) / [Math]::Max([Math]::Abs($Stat.Hour), $SmallestValue))
                $Stat.Hour = (1 - $Span_Hour) * $Stat.Hour + $Span_Hour * $Value
                $Stat.Day_Fluctuation = (1 - $Span_Day) * $Stat.Day_Fluctuation + $Span_Day * ([Math]::Abs($Value - $Stat.Day) / [Math]::Max([Math]::Abs($Stat.Day), $SmallestValue))
                $Stat.Day = (1 - $Span_Day) * $Stat.Day + $Span_Day * $Value
                $Stat.Week_Fluctuation = (1 - $Span_Week) * $Stat.Week_Fluctuation + $Span_Week * ([Math]::Abs($Value - $Stat.Week) / [Math]::Max([Math]::Abs($Stat.Week), $SmallestValue))
                $Stat.Week = (1 - $Span_Week) * $Stat.Week + $Span_Week * $Value
                $Stat.Duration = $Stat.Duration + $Duration
                $Stat.Updated = $Updated
                $Stat.Timer = $Timer
                $Stat.ToleranceExceeded = [UInt16]0
            }
        }
    }
    else { 
        if (-not $Duration) { $Duration = [TimeSpan]::FromMinutes(1) }

        $Global:Stats[$Name] = $Stat = @{ 
            Name                  = $Name
            Live                  = [Double]$Value
            Minute                = [Double]$Value
            Minute_Fluctuation    = [Double]0
            Minute_5              = [Double]$Value
            Minute_5_Fluctuation  = [Double]0
            Minute_10             = [Double]$Value
            Minute_10_Fluctuation = [Double]0
            Hour                  = [Double]$Value
            Hour_Fluctuation      = [Double]0
            Day                   = [Double]$Value
            Day_Fluctuation       = [Double]0
            Week                  = [Double]$Value
            Week_Fluctuation      = [Double]0
            Duration              = [TimeSpan]$Duration
            Updated               = [DateTime]$Updated
            Disabled              = [Boolean]$false
            Timer                 = [DateTime]$Timer
            ToleranceExceeded     = [UInt16]0
        }
    }

    # Get mutex. Mutexes are shared across all threads and processes.
    # This lets us ensure only one thread is trying to write to the file at a time.
    $Mutex = [System.Threading.Mutex]::new($false, "$($Session.Branding.ProductLabel)_Set-Stat")

    # Attempt to aquire mutex, waiting up to 1 second if necessary
    if ($Mutex.WaitOne(1000)) { 
        @{ 
            Name                  = $Name
            Live                  = [Double]$Stat.Live
            Minute                = [Double]$Stat.Minute
            Minute_Fluctuation    = [Double]$Stat.Minute_Fluctuation
            Minute_5              = [Double]$Stat.Minute_5
            Minute_5_Fluctuation  = [Double]$Stat.Minute_5_Fluctuation
            Minute_10             = [Double]$Stat.Minute_10
            Minute_10_Fluctuation = [Double]$Stat.Minute_10_Fluctuation
            Hour                  = [Double]$Stat.Hour
            Hour_Fluctuation      = [Double]$Stat.Hour_Fluctuation
            Day                   = [Double]$Stat.Day
            Day_Fluctuation       = [Double]$Stat.Day_Fluctuation
            Week                  = [Double]$Stat.Week
            Week_Fluctuation      = [Double]$Stat.Week_Fluctuation
            Duration              = [String]$Stat.Duration
            Updated               = [DateTime]$Stat.Updated
            Disabled              = [Boolean]$Stat.Disabled
        } | ConvertTo-Json | Out-File -LiteralPath $Path -Force
        $Mutex.ReleaseMutex()
    }
    $Mutex.Dispose()
    Remove-Variable Mutex

    return $Stat
}

function Get-Stat { 

    param (
        [Parameter (Mandatory = $false)]
        [String[]]$Names = (Get-ChildItem $PWD\Stats).BaseName
    )

    $Names.ForEach(
        { 
            $Name = $_

            if ($Global:Stats[$Name] -isnot [Hashtable]) { 
                # Reduce number of errors
                if (-not (Test-Path -LiteralPath "Stats\$Name.txt" -PathType Leaf)) { return }

                try { 
                    $Stat = [System.IO.File]::ReadAllLines("$PWD\Stats\$Name.txt") | ConvertFrom-Json -ErrorAction Stop
                    $Global:Stats[$Name] = @{ 
                        Name                  = $Name
                        Live                  = [Double]$Stat.Live
                        Minute                = [Double]$Stat.Minute
                        Minute_Fluctuation    = [Double]$Stat.Minute_Fluctuation
                        Minute_5              = [Double]$Stat.Minute_5
                        Minute_5_Fluctuation  = [Double]$Stat.Minute_5_Fluctuation
                        Minute_10             = [Double]$Stat.Minute_10
                        Minute_10_Fluctuation = [Double]$Stat.Minute_10_Fluctuation
                        Hour                  = [Double]$Stat.Hour
                        Hour_Fluctuation      = [Double]$Stat.Hour_Fluctuation
                        Day                   = [Double]$Stat.Day
                        Day_Fluctuation       = [Double]$Stat.Day_Fluctuation
                        Week                  = [Double]$Stat.Week
                        Week_Fluctuation      = [Double]$Stat.Week_Fluctuation
                        Duration              = [TimeSpan]$Stat.Duration
                        Updated               = [DateTime]$Stat.Updated
                        Disabled              = [Boolean]$Stat.Disabled
                        ToleranceExceeded     = [UInt16]0
                    }
                }
                catch { 
                    Write-Message -Level Warn "Stat file '$Name' is corrupt and will be reset."
                    Remove-Stat $Name
                }
            }

            $Global:Stats[$Name]
        }
    )
}

function Remove-Stat { 

    param (
        [Parameter (Mandatory = $true)]
        [String[]]$Names
    )

    $Names.ForEach(
        { 
            Remove-Item -LiteralPath "Stats\$_.txt" -Force -Confirm:$false -ErrorAction Ignore
            $Global:Stats.Remove($_)
        }
    )
}

function Invoke-TcpRequest { 

    param (
        [Parameter (Mandatory = $true)]
        [String]$Server,
        [Parameter (Mandatory = $true)]
        [String]$Port,
        [Parameter (Mandatory = $true)]
        [String]$Request,
        [Parameter (Mandatory = $true)]
        [UInt16]$Timeout, # seconds
        [Parameter (Mandatory = $false)]
        [Boolean]$ReadToEnd = $false
    )

    try { 
        $Client = [Net.Sockets.TcpClient]::new()
        $Client.SendTimeout = $Client.ReceiveTimeout = $Timeout * 1000
        $Client.Connect($Server, $Port)
        $Stream = $Client.GetStream()
        $Writer = [IO.StreamWriter]::new($Stream)
        $Reader = [IO.StreamReader]::new($Stream)
        $Writer.AutoFlush = $true
        $Writer.WriteLine($Request)
        $Response = if ($ReadToEnd) { $Reader.ReadToEnd() } else { $Reader.ReadLine() }
    }
    catch { $Error.Remove($Error[$Error.Count - 1]) }
    finally { 
        if ($Reader) { $Reader.Close() }
        if ($Writer) { $Writer.Close() }
        if ($Stream) { $Stream.Close() }
        if ($Client) { $Client.Close() }
    }

    return $Response
}

function Get-CpuId { 
    # Brief : gets CPUID (CPU name and registers)

    # Name
    $Name = "" # not implemented
    # Vendor
    $Vendor = "" # not implemented

    $Info = [CpuID]::Invoke(0)
    # Convert 16 bytes to 4 ints for compatibility with existing code
    $Info = [Int[]]@(
        [BitConverter]::ToInt32($Info, 0 * 4)
        [BitConverter]::ToInt32($Info, 1 * 4)
        [BitConverter]::ToInt32($Info, 2 * 4)
        [BitConverter]::ToInt32($Info, 3 * 4)
    )

    $nIds = $Info[0]

    $Info = [CpuID]::Invoke(0x80000000)
    $nExIds = [BitConverter]::ToUInt32($Info, 0 * 4) # Not sure as to why 'nExIds' is unsigned; may not be necessary
    # Convert 16 bytes to 4 ints for compatibility with existing code
    $Info = [Int[]]@(
        [BitConverter]::ToInt32($Info, 0 * 4)
        [BitConverter]::ToInt32($Info, 1 * 4)
        [BitConverter]::ToInt32($Info, 2 * 4)
        [BitConverter]::ToInt32($Info, 3 * 4)
    )

    # Detect Features
    $Features = @{ }
    if ($nIds -ge 0x00000001) { 

        $Info = [CpuID]::Invoke(0x00000001)
        # convert 16 bytes to 4 ints for compatibility with existing code
        $Info = [Int[]]@(
            [BitConverter]::ToInt32($Info, 0 * 4)
            [BitConverter]::ToInt32($Info, 1 * 4)
            [BitConverter]::ToInt32($Info, 2 * 4)
            [BitConverter]::ToInt32($Info, 3 * 4)
        )

        $Features.MMX = ($Info[3] -band ([Int]1 -shl 23)) -ne 0
        $Features.SSE = ($Info[3] -band ([Int]1 -shl 25)) -ne 0
        $Features.SSE2 = ($Info[3] -band ([Int]1 -shl 26)) -ne 0
        $Features.SSE3 = ($Info[2] -band ([Int]1 -shl 00)) -ne 0

        $Features.SSSE3 = ($Info[2] -band ([Int]1 -shl 09)) -ne 0
        $Features.SSE41 = ($Info[2] -band ([Int]1 -shl 19)) -ne 0
        $Features.SSE42 = ($Info[2] -band ([Int]1 -shl 20)) -ne 0
        $Features.AES = ($Info[2] -band ([Int]1 -shl 25)) -ne 0

        $Features.AVX = ($Info[2] -band ([Int]1 -shl 28)) -ne 0
        $Features.FMA3 = ($Info[2] -band ([Int]1 -shl 12)) -ne 0

        $Features.RDRAND = ($Info[2] -band ([Int]1 -shl 30)) -ne 0
    }

    if ($nIds -ge 0x00000007) { 

        $Info = [CpuID]::Invoke(0x00000007)
        # Convert 16 bytes to 4 ints for compatibility with existing code
        $Info = [Int[]]@(
            [BitConverter]::ToInt32($Info, 0 * 4)
            [BitConverter]::ToInt32($Info, 1 * 4)
            [BitConverter]::ToInt32($Info, 2 * 4)
            [BitConverter]::ToInt32($Info, 3 * 4)
        )

        $Features.AVX2 = ($Info[1] -band ([Int]1 -shl 05)) -ne 0

        $Features.BMI1 = ($Info[1] -band ([Int]1 -shl 03)) -ne 0
        $Features.BMI2 = ($Info[1] -band ([Int]1 -shl 08)) -ne 0
        $Features.ADX = ($Info[1] -band ([Int]1 -shl 19)) -ne 0
        $Features.MPX = ($Info[1] -band ([Int]1 -shl 14)) -ne 0
        $Features.SHA = ($Info[1] -band ([Int]1 -shl 29)) -ne 0
        $Features.RDSEED = ($Info[1] -band ([Int]1 -shl 18)) -ne 0
        $Features.PREFETCHWT1 = ($Info[2] -band ([Int]1 -shl 00)) -ne 0
        $Features.RDPID = ($Info[2] -band ([Int]1 -shl 22)) -ne 0

        $Features.AVX512_F = ($Info[1] -band ([Int]1 -shl 16)) -ne 0
        $Features.AVX512_CD = ($Info[1] -band ([Int]1 -shl 28)) -ne 0
        $Features.AVX512_PF = ($Info[1] -band ([Int]1 -shl 26)) -ne 0
        $Features.AVX512_ER = ($Info[1] -band ([Int]1 -shl 27)) -ne 0

        $Features.AVX512_VL = ($Info[1] -band ([Int]1 -shl 31)) -ne 0
        $Features.AVX512_BW = ($Info[1] -band ([Int]1 -shl 30)) -ne 0
        $Features.AVX512_DQ = ($Info[1] -band ([Int]1 -shl 17)) -ne 0

        $Features.AVX512_IFMA = ($Info[1] -band ([Int]1 -shl 21)) -ne 0
        $Features.AVX512_VBMI = ($Info[2] -band ([Int]1 -shl 01)) -ne 0

        $Features.AVX512_VPOPCNTDQ = ($Info[2] -band ([Int]1 -shl 14)) -ne 0
        $Features.AVX512_4FMAPS = ($Info[3] -band ([Int]1 -shl 02)) -ne 0
        $Features.AVX512_4VNNIW = ($Info[3] -band ([Int]1 -shl 03)) -ne 0

        $Features.AVX512_VNNI = ($Info[2] -band ([Int]1 -shl 11)) -ne 0

        $Features.AVX512_VBMI2 = ($Info[2] -band ([Int]1 -shl 06)) -ne 0
        $Features.GFNI = ($Info[2] -band ([Int]1 -shl 08)) -ne 0
        $Features.VAES = ($Info[2] -band ([Int]1 -shl 09)) -ne 0
        $Features.AVX512_VPCLMUL = ($Info[2] -band ([Int]1 -shl 10)) -ne 0
        $Features.AVX512_BITALG = ($Info[2] -band ([Int]1 -shl 12)) -ne 0
    }

    if ($nExIds -ge 0x80000001) { 

        $Info = [CpuID]::Invoke(0x80000001)
        # Convert 16 bytes to 4 ints for compatibility with existing code
        $Info = [Int[]]@(
            [BitConverter]::ToInt32($Info, 0 * 4)
            [BitConverter]::ToInt32($Info, 1 * 4)
            [BitConverter]::ToInt32($Info, 2 * 4)
            [BitConverter]::ToInt32($Info, 3 * 4)
        )

        $Features.x64 = ($Info[3] -band ([Int]1 -shl 29)) -ne 0
        $Features.ABM = ($Info[2] -band ([Int]1 -shl 05)) -ne 0
        $Features.SSE4a = ($Info[2] -band ([Int]1 -shl 06)) -ne 0
        $Features.FMA4 = ($Info[2] -band ([Int]1 -shl 16)) -ne 0
        $Features.XOP = ($Info[2] -band ([Int]1 -shl 11)) -ne 0
        $Features.PREFETCHW = ($Info[2] -band ([Int]1 -shl 08)) -ne 0
    }

    # Wrap data into PSObject
    return [PSCustomObject]@{ 
        Vendor   = $Vendor
        Name     = $Name
        Features = ($Features.psBase.Keys | Sort-Object).ForEach({ if ($Features.$_) { $_ } })
    }
}

function Get-GPUArchitectureAMD { 

    param (
        [Parameter (Mandatory = $true)]
        [String]$Model,
        [Parameter (Mandatory = $false)]
        [String]$Architecture = ""
    )

    $Model = $Model -replace "[^A-Z0-9]"
    $Architecture = $Architecture -replace ":.+$" -replace "[^A-Za-z0-9]+"

    foreach ($GPUArchitecture in $Session.GPUArchitectureDbAMD.PSObject.Properties) { 
        if ($Architecture -match $GPUArchitecture.Value) { return $GPUArchitecture.Name }
    }

    return $Architecture
}

function Get-GPUArchitectureNvidia { 

    param (
        [Parameter (Mandatory = $true)]
        [String]$Model,
        [Parameter (Mandatory = $false)]
        [String]$ComputeCapability = ""
    )

    $Model = $Model -replace "[^A-Z0-9]"
    $ComputeCapability = $ComputeCapability -replace "[^\d\.]"

    foreach ($GPUArchitecture in $Session.GPUArchitectureDbNvidia.PSObject.Properties) { 
        if ($GPUArchitecture.Value.Compute -contains $ComputeCapability) { return $GPUArchitecture.Name }
    }

    foreach ($GPUArchitecture in $GPUArchitectureDbNvidia.PSObject.Properties) { 
        if ($Model -match $GPUArchitecture.Value.Model) { return $GPUArchitecture.Name }
    }

    return "Other"
}

function Get-Device { 

    $Devices = @()

    $Id = 0
    $Type_Id = @{ }
    $Vendor_Id = @{ }
    $Type_Vendor_Id = @{ }

    $Slot = 0
    $Type_Slot = @{ }
    $Vendor_Slot = @{ }
    $Type_Vendor_Slot = @{ }

    $Index = 0
    $Type_Index = @{ }
    $Vendor_Index = @{ }
    $Type_Vendor_Index = @{ }

    $PlatformId = 0
    $PlatformId_Index = @{ }
    $Type_PlatformId_Index = @{ }

    $UnsupportedCPUVendorID = 100
    $UnsupportedGPUVendorID = 100

    # Get WDDM data
    try { 
        (Get-CimInstance CIM_Processor).ForEach(
            { 
                $Device_CIM = [CimInstance]::new($_)

                # Add normalised values
                $Devices += $Device = [Device]@{ 
                    Bus       = $null
                    Name      = $null
                    Memory    = $null
                    MemoryGiB = $null
                    Model     = $Device_CIM.Name
                    Type      = "CPU"
                    Vendor    = $(
                        switch -Regex ($Device_CIM.Manufacturer) { 
                            "Advanced Micro Devices" { "AMD"; break }
                            "AMD"                    { "AMD"; break }
                            "Intel"                  { "INTEL"; break }
                            "NVIDIA"                 { "NVIDIA"; break }
                            "Microsoft"              { "MICROSOFT"; break }
                            default                  { $Device_CIM.Manufacturer -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "[^A-Z0-9]" }
                        }
                    )
                }

                $Device.Id = [UInt16]$Id
                $Device.Type_Id = [UInt16]$Type_Id.($Device.Type)
                $Device.Vendor_Id = [UInt16]$Vendor_Id.($Device.Vendor)
                $Device.Type_Vendor_Id = [UInt16]$Type_Vendor_Id.($Device.Type).($Device.Vendor)

                $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)"
                $Device.Model = (($Device.Model -split " " -replace "Processor", "CPU" -replace "Graphics", "GPU") -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "@" -notmatch ".*[MG]Hz") -join " " -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "^\s*" -replace "[^ A-Z0-9\.]" -replace " \s+" -replace "\s*$"

                if (-not $Type_Vendor_Id.($Device.Type)) { $Type_Vendor_Id.($Device.Type) = @{ } }

                $Id ++
                $Vendor_Id.($Device.Vendor) ++
                $Type_Vendor_Id.($Device.Type).($Device.Vendor) ++
                if ($Session."Supported$($Device.Type)DeviceVendors" -contains $Device.Vendor) { $Type_Id.($Device.Type) ++ }

                # Read CPU features
                $Device.CPUfeatures = $Session.CPUfeatures

                # Add raw data
                $Device.CIM = $Device_CIM
            }
        )

        # Reading all PnpDevices is faster (https://www.erwinmcm.com/speed-tip-for-pnp-powershell/)
        $PnpDevices = Get-PnpDevice -Class Display

        (Get-CimInstance CIM_VideoController).ForEach(
            { 
                $Device_CIM = [CimInstance]::new($_)
                $Device_PNP = [PSCustomObject]@{ }

                ($PnpDevices.Where({ $_.DeviceID -eq $Device_CIM.PNPDeviceID }) | Get-PnpDeviceProperty).ForEach({ $Device_PNP | Add-Member $_.KeyName $_.Data })
                $Device_PNP = $Device_PNP.PSObject.Copy()
                $Device_Reg = (Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\$($Device_PNP.DEVPKEY_Device_Driver)").PSObject.Copy()
                $Devices += $Device = [Device]@{ 
                    Bus       = $(
                        if ($Device_PNP.DEVPKEY_Device_BusNumber -is [UInt64] -or $Device_PNP.DEVPKEY_Device_BusNumber -is [UInt32]) { 
                            [Int64]$Device_PNP.DEVPKEY_Device_BusNumber
                        }
                    )
                    Name      = $null
                    Memory    = [Math]::Max([UInt64]$Device_CIM.AdapterRAM, [uInt64]$Device_Reg.'HardwareInformation.qwMemorySize')
                    MemoryGiB = [Double]([Math]::Round([Math]::Max([UInt64]$Device_CIM.AdapterRAM, [uInt64]$Device_Reg.'HardwareInformation.qwMemorySize') / 0.05GB) / 20) # Round to nearest 50MB
                    Model     = $Device_CIM.Name
                    Type      = "GPU"
                    Vendor    = $(
                        switch -Regex ([String]$Device_CIM.AdapterCompatibility) { 
                            "Advanced Micro Devices" { "AMD"; break }
                            "AMD"                    { "AMD"; break }
                            "Intel"                  { "INTEL"; break }
                            "NVIDIA"                 { "NVIDIA"; break }
                            "Microsoft"              { "MICROSOFT"; break }
                            default                  { $Device_CIM.AdapterCompatibility -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "[^A-Z0-9]" }
                        }
                    )
                }

                $Device.Id = [UInt16]$Id
                $Device.Type_Id = [UInt16]$Type_Id.($Device.Type)
                $Device.Vendor_Id = [UInt16]$Vendor_Id.($Device.Vendor)
                $Device.Type_Vendor_Id = [UInt16]$Type_Vendor_Id.($Device.Type).($Device.Vendor)

                # Unsupported devices start from DeviceID 100 (to not disrupt device order when running in a Citrix or RDP session)
                if ($Session."Supported$($Device.Type)DeviceVendors" -contains $Device.Vendor) { $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)" }
                elseif ($Device.Type -eq "CPU") { $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedCPUVendorID ++)" }
                else { $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedGPUVendorID ++)" }

                $Device.Model = (((($Device.Model -split " " -replace "Processor", "CPU" -replace "Graphics", "GPU") -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") -join " " -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "^\s*" -replace "[^ A-Z0-9\.]" -replace " \s+") + " ($([UInt64]($Device.Memory/1GB))GB)") -replace "\s*$"

                if (-not $Type_Vendor_Id.($Device.Type)) { $Type_Vendor_Id.($Device.Type) = @{ } }

                $Id ++
                $Vendor_Id.($Device.Vendor) ++
                $Type_Vendor_Id.($Device.Type).($Device.Vendor) ++
                if ($Session."Supported$($Device.Type)DeviceVendors" -contains $Device.Vendor) { $Type_Id.($Device.Type) ++ }

                # Add raw data
                $Device.CIM = $Device_CIM
                # $Device.PNP = $Device_PNP
                # $Device.Reg = $Device_Reg
            }
        )
    }
    catch { 
        Write-Message -Level Warn "WDDM device detection has failed."
    }
    Remove-Variable Device_CIM, Device_PNP, Device_Reg, PnpDevices -ErrorAction Ignore

    # Get OpenCL data
    [OpenCl.Platform]::GetPlatformIDs().ForEach(
        { 
            try { 
                $OpenCLplatform = $_
                # Skip devices with negative PCIbus
                ([OpenCl.Device]::GetDeviceIDs($_, [OpenCl.DeviceType]::All).Where({ $_.PCIbus -ge 0 }).ForEach({ $_ | ConvertTo-Json -EnumsAsStrings -WarningAction SilentlyContinue }) | Select-Object -Unique).ForEach(
                    { 
                        $Device_OpenCL = $_ | ConvertFrom-Json

                        # Add normalised values
                        $Device = [Device]@{ 
                            Bus       = $(
                                if ($Device_OpenCL.PCIBus -is [Int64] -or $Device_OpenCL.PCIBus -is [Int32]) { 
                                    [Int64]$Device_OpenCL.PCIBus
                                }
                            )
                            Name      = $null
                            Memory    = [UInt64]$Device_OpenCL.GlobalMemSize
                            MemoryGiB = [Double]([Math]::Round($Device_OpenCL.GlobalMemSize / 0.05GB) / 20) # Round to nearest 50MB
                            Model     = $Device_OpenCL.Name
                            Type      = $(
                                switch -Regex ([String]$Device_OpenCL.Type) { 
                                    "CPU"   { "CPU"; break }
                                    "GPU"   { "GPU"; break }
                                    default { [String]$Device_OpenCL.Type -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "[^A-Z0-9]" }
                                }
                            )
                            Vendor = $(
                                switch -Regex ([String]$Device_OpenCL.Vendor) { 
                                    "Advanced Micro Devices" { "AMD"; break }
                                    "AMD"                    { "AMD"; break }
                                    "Intel"                  { "INTEL"; break }
                                    "NVIDIA"                 { "NVIDIA"; break }
                                    "Microsoft"              { "MICROSOFT"; break }
                                    default                  { [String]$Device_OpenCL.Vendor -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "[^A-Z0-9]" }
                                }
                            )
                        }

                        $Device.Id = [UInt16]$Id
                        $Device.Type_Id = [UInt16]$Type_Id.($Device.Type)
                        $Device.Vendor_Id = [UInt16]$Vendor_Id.($Device.Vendor)
                        $Device.Type_Vendor_Id = [UInt16]$Type_Vendor_Id.($Device.Type).($Device.Vendor)

                        # Unsupported devices start from DeviceID 100 (to not disrupt device order when running in a Citrix or RDP session)
                        if ($Session."Supported$($Device.Type)DeviceVendors" -contains $Device.Vendor) { $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)" }
                        elseif ($Device.Type -eq "CPU") { $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedCPUVendorID ++)" }
                        else { $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedGPUVendorID ++)" }

                        $Device.Model = (((($Device.Model -split " " -replace "Processor", "CPU" -replace "Graphics", "GPU") -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") -join " " -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "^\s*" -replace "[^ A-Z0-9\.]" -replace " \s+") + " ($([UInt64]($Device.Memory/1GB))GB)") -replace "\s*$"

                        if (-not $Type_Vendor_Id.($Device.Type)) { $Type_Vendor_Id.($Device.Type) = @{ } }

                        if ($Devices.Where({ $_.Type -eq $Device.Type -and $_.Bus -eq $Device.Bus })) { $Device = [Device]($Devices.Where({ $_.Type -eq $Device.Type -and $_.Bus -eq $Device.Bus }) | Select-Object) }
                        elseif ($Device.Type -eq "GPU" -and $Session.SupportedGPUDeviceVendors -contains $Device.Vendor) { 
                            $Devices += $Device

                            if (-not $Type_Vendor_Index.($Device.Type)) { $Type_Vendor_Index.($Device.Type) = @{ } }

                            $Id ++
                            $Vendor_Id.($Device.Vendor) ++
                            $Type_Vendor_Id.($Device.Type).($Device.Vendor) ++
                            $Type_Id.($Device.Type) ++
                        }

                        # Add OpenCL specific data
                        $Device.Index = [UInt16]$Index
                        $Device.Type_Index = [UInt16]$Type_Index.($Device.Type)
                        $Device.Vendor_Index = [UInt16]$Vendor_Index.($Device.Vendor)
                        $Device.Type_Vendor_Index = [UInt16]$Type_Vendor_Index.($Device.Type).($Device.Vendor)
                        $Device.PlatformId = [UInt16]$PlatformId
                        $Device.PlatformId_Index = [UInt16]$PlatformId_Index.($PlatformId)
                        $Device.Type_PlatformId_Index = [UInt16]$Type_PlatformId_Index.($Device.Type).($PlatformId)

                        # Add raw data
                        $Device.OpenCL = $Device_OpenCL

                        if ($Device.OpenCL.PlatForm.Name -eq "NVIDIA CUDA") { $Device.CUDAversion = ([System.Version]($Device.OpenCL.PlatForm.Version -replace ".+CUDA ")) }

                        if (-not $Type_Vendor_Index.($Device.Type)) { $Type_Vendor_Index.($Device.Type) = @{ } }
                        if (-not $Type_PlatformId_Index.($Device.Type)) { $Type_PlatformId_Index.($Device.Type) = @{ } }

                        $Index ++
                        $Type_Index.($Device.Type) ++
                        $Vendor_Index.($Device.Vendor) ++
                        $Type_Vendor_Index.($Device.Type).($Device.Vendor) ++
                        $PlatformId_Index.($PlatformId) ++
                        $Type_PlatformId_Index.($Device.Type).($PlatformId) ++
                    }
                )
                $PlatformId ++
            }
            catch { 
                Write-Message -Level Warn "Device detection for OpenCL platform '$($OpenCLplatform.Version)' has failed."
                "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $Session.ErrorLogFile
                $_.Exception | Format-List -Force >> $Session.ErrorLogFile
                $_.InvocationInfo | Format-List -Force >> $Session.ErrorLogFile
            }
        }
    )
    Remove-Variable Device, OpenCLplatform -ErrorAction Ignore

    ($Devices.Where({ $_.Model -ne "Remote Display Adapter 0GB" -and $_.Vendor -ne "CitrixSystemsInc" -and $_.Bus -is [Int64] }) | Sort-Object -Property Bus).ForEach(
        { 
            if ($_.Type -eq "GPU") { 
                if ($_.Vendor -eq "NVIDIA") { $_.Architecture = (Get-GPUArchitectureNvidia -Model $_.Model -ComputeCapability $_.OpenCL.DeviceCapability) }
                elseif ($_.Vendor -eq "AMD") { $_.Architecture = (Get-GPUArchitectureAMD -Model $_.Model -Architecture $_.OpenCL.Architecture) }
                else { $_.Architecture = "Other" }
            }

            $_.Slot = [UInt16]$Slot
            $_.Type_Slot = [UInt16]$Type_Slot.($_.Type)
            $_.Vendor_Slot = [UInt16]$Vendor_Slot.($_.Vendor)
            $_.Type_Vendor_Slot = [UInt16]$Type_Vendor_Slot.($_.Type).($_.Vendor)

            if (-not $Type_Vendor_Slot.($_.Type)) { $Type_Vendor_Slot.($_.Type) = @{ } }

            $Slot ++
            $Type_Slot.($_.Type) ++
            $Vendor_Slot.($_.Vendor) ++
            $Type_Vendor_Slot.($_.Type).($_.Vendor) ++
        }
    )

    $Devices.ForEach(
        { 
            $Device = $_

            $Device.Bus_Index = @($Devices.Bus | Sort-Object).IndexOf([UInt16]$Device.Bus)
            $Device.Bus_Type_Index = @($Devices.Where({ $_.Type -eq $Device.Type }).Bus | Sort-Object).IndexOf([UInt16]$Device.Bus)
            $Device.Bus_Vendor_Index = @($Devices.Where({ $_.Vendor -eq $Device.Vendor }).Bus | Sort-Object).IndexOf([UInt16]$Device.Bus)
            $Device.Bus_Platform_Index = @($Devices.Where({ $_.Platform -eq $Device.Platform }).Bus | Sort-Object).IndexOf([UInt16]$Device.Bus)

            $Device
        }
    )
}

filter ConvertTo-Hash { 

    $Units = " kMGTPEZY" # k(ilo) in small letters, see https://en.wikipedia.org/wiki/Metric_prefix

    if ($null -eq $_ -or [Double]::IsNaN($_)) { return "n/a" }
    elseif ($_ -eq 0) { return "0h/s " }
    $Base1000 = [Math]::Max([Double]0, [Math]::Min([Math]::Truncate([Math]::Log([Math]::Abs([Double]$_), [Math]::Pow(1000, 1))), $Units.Length - 1))
    $UnitValue = $_ / [Math]::Pow(1000, $Base1000)
    $Digits = if ($UnitValue -lt 10) { 3 } else { 2 }
    "{0:n$($Digits)} $($Units[$Base1000])h/s" -f $UnitValue
}

function Get-DecimalsFromValue { 
    # Used to limit the absolute length of a number
    # The larger the value, the less decimal digits are returned
    # Maximal $DecimalsMax are returned

    param (
        [Parameter (Mandatory = $true)]
        [Double]$Value,
        [Parameter (Mandatory = $true)]
        [UInt16]$DecimalsMax
    )

    return [Math]::Max($DecimalsMax - [Math]::Floor([Math]::Abs($Value)).ToString().Length + 1, 0)
}

function Get-Combination { 

    param (
        [Parameter (Mandatory = $true)]
        [Array]$Value,
        [Parameter (Mandatory = $false)]
        [UInt16]$SizeMax = $Value.Count,
        [Parameter (Mandatory = $false)]
        [UInt16]$SizeMin = 1
    )

    $Combination = [PSCustomObject]@{ }

    for ($I = 0; $I -lt $Value.Count; $I ++) { 
        $Combination | Add-Member @{ [Math]::Pow(2, $I) = $Value[$I] }
    }

    $CombinationKeys = $Combination.PSObject.Properties.Name

    for ($I = $SizeMin; $I -le $SizeMax; $I ++) { 
        $X = [Math]::Pow(2, $I) - 1

        while ($X -le [Math]::Pow(2, $Value.Count) - 1) { 
            [PSCustomObject]@{ 
                Combination = $CombinationKeys.Where({ $_ -band $X }).ForEach({ $Combination.$_ })
            }
            $Smallest = $X -band -$X
            $Ripple = $X + $Smallest
            $NewSmallest = $Ripple -band -$Ripple
            $Ones = ($NewSmallest / $Smallest -shr 1) - 1
            $X = $Ripple -bor $Ones
        }
    }
}

function Get-Algorithm { 

    param (
        [Parameter (Mandatory = $false)]
        [String]$Algorithm
    )

    $Algorithm = $Algorithm -replace "[^a-z0-9]+"

    if ($Session.Algorithms[$Algorithm]) { return $Session.Algorithms[$Algorithm] }

    return (Get-Culture).TextInfo.ToTitleCase($Algorithm.ToLower())
}

function Get-Region { 

    param (
        [Parameter (Mandatory = $true)]
        [String]$Region,
        [Parameter (Mandatory = $false)]
        [Switch]$List = $false
    )

    if ($List) { return $Session.Regions[$Region] }

    if ($Session.Regions[$Region]) { return $($Session.Regions[$Region] | Select-Object -First 1) }

    return $Region
}

function Add-CoinName { 

    param (
        [Parameter (Mandatory = $true)]
        [String]$Currency,
        [Parameter (Mandatory = $true)]
        [String]$CoinName
    )

    if (-not $Session.CoinNames[$Currency]) { 

        # Get mutex. Mutexes are shared across all threads and processes.
        # This lets us ensure only one thread is trying to write to the file at a time.
        $Mutex = [System.Threading.Mutex]::new($false, "$($Session.Branding.ProductLabel)_Add-CoinName")

        # Attempt to aquire mutex, waiting up to 1 second if necessary. If aquired, update the file and release mutex
        if ($Mutex.WaitOne(1000)) { 
            if (-not $Session.CoinNames[$Currency]) { 
                if ($CoinName = ($CoinName.Trim() -replace "[^A-Z0-9 \$\.]" -replace "coin$", " Coin" -replace "bit coin$", "Bitcoin" -replace "ERC20$" , " ERC20" -replace "TRC20$" , " TRC20" -replace " \s+" )) { 
                    $Session.CoinNames[$Currency] = $CoinName
                    $Session.CoinNames | ConvertTo-Json | Out-File -Path ".\Data\CoinNames.json" -ErrorAction Ignore -Force
                }
            }
            $Mutex.ReleaseMutex()
        }
        $Mutex.Dispose()
        Remove-Variable Mutex
    }
}

function Add-CurrencyAlgorithm { 

    param (
        [Parameter (Mandatory = $true)]
        [String]$Algorithm,
        [Parameter (Mandatory = $true)]
        [String]$Currency
    )

    if (-not $Session.CurrencyAlgorithm[$Currency]) { 

        # Get mutex. Mutexes are shared across all threads and processes.
        # This lets us ensure only one thread is trying to write to the file at a time.
        $Mutex = [System.Threading.Mutex]::new($false, "$($Session.Branding.ProductLabel)_Add-CurrencyAlgorithm")

        # Attempt to aquire mutex, waiting up to 1 second if necessary. If aquired, update the file and release mutex
        if ($Mutex.WaitOne(1000)) { 
            if (-not $Session.CurrencyAlgorithm[$Currency]) { 
                $Session.CurrencyAlgorithm[$Currency] = Get-Algorithm $Algorithm
                $Session.CurrencyAlgorithm | ConvertTo-Json | Out-File -Path ".\Data\CurrencyAlgorithm.json" -ErrorAction Ignore -Force
            }
            $Mutex.ReleaseMutex()
        }
        $Mutex.Dispose()
        Remove-Variable Mutex
    }
}

function Get-CurrencyFromAlgorithm { 

    param (
        [Parameter (Mandatory = $false)]
        [String]$Algorithm
    )

    return $Session.CurrencyAlgorithm.Keys.Where({ $Session.CurrencyAlgorithm.$_ -eq $Algorithm })
}

function Get-EquihashCoinPers { 

    param (
        [Parameter (Mandatory = $false)]
        [String]$Command = "",
        [Parameter (Mandatory = $false)]
        [String]$Currency = "",
        [Parameter (Mandatory = $false)]
        [String]$DefaultCommand = ""
    )

    if ($Currency) { 
        if ($Session.EquihashCoinPers[$Currency]) { 
            return "$($Command)$($Session.EquihashCoinPers[$Currency])"
        }
    }

    return $DefaultCommand
}

function Get-PoolBaseName { 

    param (
        [Parameter (Mandatory = $false)]
        [String[]]$PoolNames
    )

    return ($PoolNames -replace "24hr$|coins$|coins24hr$|coinsplus$|plus$")
}

function Get-Version { 
    try { 
        $UpdateVersion = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/UselessGuru/UG-Miner/main/Version.txt" -TimeoutSec 15 -SkipCertificateCheck -Headers @{ "Cache-Control" = "no-cache" }).Content | ConvertFrom-Json

        $Session.CheckedForUpdate = [DateTime]::Now

        if ($Session.Branding.ProductLabel -and [System.Version]$UpdateVersion.Version -gt $Session.Branding.Version) { 
            if ($UpdateVersion.AutoUpdate) { 
                if ($Session.Config.AutoUpdate) { 
                    Write-Message -Level Verbose "Version checker: New version v$($UpdateVersion.Version) found. Starting update..."
                    try { 
                        [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
                        Write-Host " ✔" -ForegroundColor Green
                    } catch { }
                    Initialize-AutoUpdate -UpdateVersion $UpdateVersion
                }
                else { 
                    Write-Message -Level Verbose "Version checker: New version v$($UpdateVersion.Version) found. Auto Update is disabled in config - You must update manually."
                    try { 
                        [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
                        Write-Host " ✔" -ForegroundColor Green
                    } catch { }
                }
            }
            else { 
                Write-Message -Level Verbose "Version checker: New version is available. v$($UpdateVersion.Version) does not support auto-update. You must update manually."
                try { 
                    [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
                    Write-Host " ✔" -ForegroundColor Green
                } catch { }
            }
            if ($Session.Config.ShowChangeLog) { 
                Start-Process "https://github.com/UselessGuru/UG-Miner/releases/tag/v$($UpdateVersion.Version)"
            }
        }
        else { 
            Write-Message -Level Verbose "Version checker: $($Session.Branding.ProductLabel) v$($Session.Branding.Version) is current - no update available."
            try { 
                [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
                Write-Host " ✔" -ForegroundColor Green
            } catch { }
        }
    }
    catch { 
        Write-Message -Level Warn "Version checker could not contact update server."
        try { 
            [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
            Write-Host " ✖" -ForegroundColor Red
        } catch { }
    }
}

function Initialize-AutoUpdate { 

    param (
        [Parameter (Mandatory = $true)]
        [PSCustomObject]$UpdateVersion
    )

    Set-Location $Session.MainPath
    if (-not (Test-Path -LiteralPath ".\AutoUpdate" -PathType Container)) { $null = (New-Item -Path . -Name "AutoUpdate" -ItemType Directory) }
    if (-not (Test-Path -LiteralPath ".\Logs" -PathType Container)) { $null = (New-Item -Path . -Name "Logs" -ItemType Directory) }

    $UpdateLog = ".\Logs\AutoUpdateLog_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").txt"
    $UpdateScript = ".\AutoUpdate\$($UpdateVersion.UpdateScript -replace ".+/")"
    $UpdateScriptURL = $UpdateVersion.UpdateScript

    # Download update script
    try { 
        $CursorPosition = $Host.UI.RawUI.CursorPosition
        "Downloading update script '$($UpdateScript)'..." | Tee-Object -FilePath $UpdateLog -Append | Write-Message -Level Verbose
        try {
            Invoke-WebRequest -Uri $UpdateScriptURL -OutFile $UpdateScript -TimeoutSec 15
            [Console]::SetCursorPosition((32  + $UpdateScript.length), $CursorPosition.y)
            Write-Host " ✔" -ForegroundColor Green
        }
        catch { 
            [Console]::SetCursorPosition((32  + $UpdateScript.length), $CursorPosition.y)
            Write-Host " ✖" -ForegroundColor Red
        }
        $CursorPosition = $Host.UI.RawUI.CursorPosition
       "Executing update script '$($UpdateScript)'..." | Tee-Object -FilePath $UpdateLog -Append | Write-Message -Level Verbose
        try { 
            . $UpdateScript
            [Console]::SetCursorPosition((29 + $UpdateScript.length), $CursorPosition.y)
            Write-Host " ✔" -ForegroundColor Green
        }
        catch { 
            [Console]::SetCursorPosition((29 + $UpdateScript.length), $CursorPosition.y)
            Write-Host " ✖" -ForegroundColor Red
        }
    }
    catch { 
        try { 
            [Console]::SetCursorPosition(29, $CursorPosition.y) 
            Write-Host " ✖" -ForegroundColor Red
        }
        catch { }
        "Downloading update script failed. Cannot complete auto-update :-(" | Tee-Object -FilePath $UpdateLog -Append | Write-Message -Level Error
    }
    Remove-Variable CursorPosition, UpdateScript, UpdateScriptURL, UpdateLog
}

function Update-PoolWatchdog { 

    param (
        [Parameter (Mandatory = $true)]
        $Pools
    )

    # Apply watchdog to pools
    if ($Session.Config.Watchdog) { 
        # We assume that miner is up and running, so watchdog timer is not relevant
        if ($RelevantWatchdogTimers = $Session.WatchdogTimers.Where({ $_.MinerName -notin $Session.MinersRunning })) { 
            # Only pools with a corresponding watchdog timer object are of interest
            if ($RelevantPools = $Pools.Where({ $RelevantWatchdogTimers.PoolName -contains $_.Name })) { 

                # Add miner reason "Pool suspended by watchdog 'all algorithms'", only if more than one pool
                ($RelevantWatchdogTimers | Group-Object -Property PoolName).ForEach(
                    { 
                        if ($Session.Config.PoolName.Count -gt 1 -and $_.Count -ge (2 * $Session.WatchdogCount * ($_.Group.DeviceNames | Sort-Object -Unique).Count + 1)) { 
                            $Group = $_.Group
                            if ($PoolsToSuspend = $RelevantPools.Where({ $_.Name -eq $Group[0].PoolName })) { 
                                $PoolsToSuspend.ForEach({ $null = $null = $_.Reasons.Add("Pool suspended by watchdog [all algorithms]") })
                                Write-Message -Level Warn "Pool '$($Group[0].PoolName) [all algorithms]' is suspended by watchdog until $(($Group.Kicked | Sort-Object -Top 1).AddSeconds($Session.WatchdogReset).ToLocalTime().ToString("T"))."
                            }
                        }
                    }
                )
                Remove-Variable Group, PoolsToSuspend -ErrorAction Ignore

                if ($RelevantPools = $RelevantPools.Where({ -not ($_.Reasons -match "Pool suspended by watchdog .+") })) { 
                    # Add miner reason "Pool suspended by watchdog 'Algorithm [Algorithm]'"
                    ($RelevantWatchdogTimers | Group-Object -Property PoolName, Algorithm).ForEach(
                        { 
                            if ($_.Count -ge 2 * $Session.WatchdogCount * ($_.Group.DeviceNames | Sort-Object -Unique).Count - 1) { 
                                $Group = $_.Group
                                if ($PoolsToSuspend = $RelevantPools.Where({ $_.Name -eq $Group[0].PoolName -and $_.Algorithm -eq $Group[0].Algorithm })) { 
                                    $PoolsToSuspend.ForEach({ $null = $null = $_.Reasons.Add("Pool suspended by watchdog [Algorithm $($Group[0].Algorithm)]") })
                                    Write-Message -Level Warn "Pool '$($Group[0].PoolName) [Algorithm $($Group[0].Algorithm)]' is suspended by watchdog until $(($Group.Kicked | Sort-Object -Top 1).AddSeconds($Session.WatchdogReset).ToLocalTime().ToString("T"))."
                                }
                            }
                        }
                    )
                    Remove-Variable Group, PoolsToSuspend -ErrorAction Ignore
                }
            }
            Remove-Variable RelevantPools
        }
        Remove-Variable RelevantWatchdogTimers
    }

    return $Pools
}

function Test-IsPrime { 

    param (
        [Parameter (Mandatory = $true)]
        [UInt64]$Number
    )

    switch ($Number) { 
        ($_ -lt 2) { return $false }
        ($_ -eq 2) { return $true }
        default { 
            $PowNumber = [Int64][Math]::Pow($Number, 0.5)
            for ([UInt64]$I = 2; $I -le $PowNumber; $I++) { 
                if ($Number % $I -eq 0) { return $false }
            }
        }
    }
    return $true
}

function Get-AllDAGdata { 

    param (
        [Parameter (Mandatory = $true)]
        [PSCustomObject]$DAGdata
    )

    # Update on script start, once every 24hrs or if unable to get data from source on last attempt
    $Url = "https://whattomine.com/coins.json"
    if ($DAGdata.Updated.$Url -lt $Session.ScriptStartTime -or $DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
        # Get block data for from whattomine.com
        try { 
            Write-Message -Level Info "Loading DAG data from '$Url'..."
            $CurrencyDAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 5

            if ($CurrencyDAGdataResponse.coins.PSObject.Properties.Name) { 
                $CurrencyDAGdataResponse.coins.PSObject.Properties.Name.Where({ $CurrencyDAGdataResponse.coins.$_.tag -ne "NICEHASH" }).ForEach(
                    { 
                        if ($AlgorithmNorm = Get-Algorithm $CurrencyDAGdataResponse.coins.$_.algorithm) { 
                            $Currency = $CurrencyDAGdataResponse.coins.$_.tag
                            Add-CoinName -Currency $Currency -CoinName $($_ -replace '-.+$')
                            if ($AlgorithmNorm -match $Session.RegexAlgoHasDAG) { 
                                if ([UInt64]($CurrencyDAGdataResponse.coins.$_.last_block) -ge $DAGdata.Currency.$Currency.BlockHeight) { 
                                    $CurrencyDAGdata = Get-DAGdata -BlockHeight $CurrencyDAGdataResponse.coins.$_.last_block -Algorithm $AlgorithmNorm -Currency $Currency -EpochReserve 2
                                    if ($CurrencyDAGdata.BlockHeight -and $CurrencyDAGdata.Algorithm -match $Session.RegexAlgoHasDAG) { 
                                        $CurrencyDAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                                        $CurrencyDAGdata | Add-Member Url $Url -Force
                                        $DAGdata.Currency | Add-Member $Currency $CurrencyDAGdata -Force
                                    }
                                    else { 
                                        Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                                    }
                                }
                            }
                        }
                    }
                )
                $DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
            }
            else { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
            }
        }
        catch { 
            Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
        }
    }

    # Update on script start, once every 24hrs or if unable to get data from source on last attempt
    $Url = "https://minerstat.com/dag-size-calculator"
    if ($DAGdata.Updated.$Url -lt $Session.ScriptStartTime -or $DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
        # Get block data from Minerstat
        try { 
            Write-Message -Level Info "Loading DAG data from '$Url'..."
            $CurrencyDAGdataResponse = Invoke-WebRequest -Uri $Url -TimeoutSec 5 # PWSH 6+ no longer supports basic parsing -> parse text
            if ($CurrencyDAGdataResponse.statuscode -eq 200) { 
                (($CurrencyDAGdataResponse.Content -split "\n" -replace "`"", "'").Where({ $_ -like "<div class='block' title='Current block height of *" })).ForEach(
                    { 
                        $Currency = $_ -replace "^<div class='block' title='Current block height of " -replace "'>.*$"
                        if ($Currency -notin @("ETF")) { 
                            # ETF has invalid DAG data of 444GiB
                            $BlockHeight = [Math]::Floor(($_ -replace "^<div class='block' title='Current block height of $Currency'>" -replace "</div>"))
                            if ($Session.CurrencyAlgorithm[$Currency] -and $BlockHeight -ge $DAGdata.Currency.$Currency.BlockHeight) { 
                                $CurrencyDAGdata = Get-DAGdata -BlockHeight $BlockHeight -Currency $Currency -EpochReserve 2
                                if ($CurrencyDAGdata.Epoch -and $CurrencyDAGdata.Algorithm -match $Session.RegexAlgoHasDAG) { 
                                    $CurrencyDAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                                    $CurrencyDAGdata | Add-Member Url $Url -Force
                                    $DAGdata.Currency | Add-Member $Currency $CurrencyDAGdata -Force
                                }
                                else { 
                                    Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                                }
                            }
                        }
                    }
                )
                $DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
            }
            else { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
            }
        }
        catch { 
            Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
        }
    }

    # Update on script start, once every 24hrs or if unable to get data from source on last attempt
    # ZPool also supplies TLS DAG data.
    if (-not ($Session.Config.PoolName -match "^ZPool.*")) { 
        $Currency = "TLS"
        if ($Session.CurrencyAlgorithm[$Currency]) { 
            $Url = "https://telestai.cryptoscope.io/api/getblockcount"
            if (-not $DAGdata.Currency.$Currency.BlockHeight -or $DAGdata.Currency.$Currency.Date -lt $Session.ScriptStartTime -or $DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
                try { 
                    Write-Message -Level Info "Loading DAG data from '$Url'..."
                    $CurrencyDAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 15 -SkipCertificateCheck
                    if ([UInt64]($CurrencyDAGdataResponse.blockcount) -ge $DAGdata.Currency.$Currency.BlockHeight) { 
                        $CurrencyDAGdata = Get-DAGdata -BlockHeight $CurrencyDAGdataResponse.blockcount -Currency $Currency -EpochReserve 2
                        if ($CurrencyDAGdata.Epoch) { 
                            $CurrencyDAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                            $CurrencyDAGdata | Add-Member Url $Url -Force
                            $DAGdata.Currency | Add-Member $Currency $CurrencyDAGdata -Force
                            $DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
                        }
                        else { 
                            Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                        }
                    }
                }
                catch { 
                    Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
                }
            }
        }
    }

    # ZPool also supplies SCC DAG data
    if (-not ($Session.Config.PoolName -match "ZPool.*")) { 
        # Update on script start, once every 24hrs or if unable to get data from source on last attempt
        $Currency = "SCC"
        if ($Session.CurrencyAlgorithm[$Currency]) { 
            $Url = "https://www.coinexplorer.net/api/v1/SCC/block/latest"
            if (-not $DAGdata.Currency.$Currency.BlockHeight -or $DAGdata.Currency.$Currency.Date -lt $Session.ScriptStartTime -or $DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
                # Get block data from StakeCube block explorer
                try { 
                    Write-Message -Level Info "Loading DAG data from '$Url'..."
                    $CurrencyDAGdataResponse = [UInt64]((Invoke-RestMethod -Uri $Url -TimeoutSec 15 -SkipCertificateCheck).result.height)
                    if ($CurrencyDAGdataResponse -ge $DAGdata.Currency.$Currency.BlockHeight) { 
                        $CurrencyDAGdata = Get-DAGdata -BlockHeight $CurrencyDAGdataResponse -Currency $Currency -EpochReserve 2
                        if ($CurrencyDAGdata.Epoch) { 
                            $CurrencyDAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                            $CurrencyDAGdata | Add-Member Url $Url -Force
                            $DAGdata.Currency | Add-Member $Currency $CurrencyDAGdata -Force
                            $DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
                        }
                        else { 
                            Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                        }
                    }
                }
                catch { 
                    Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
                }
            }
        }
    }

    # Update on script start, once every 24hrs or if unable to get data from source on last attempt
    $Currency = "BLOCX"
    if ($Session.CurrencyAlgorithm[$Currency]) { 
        $Url = "https://blocxscan.com/api/v2/stats"
        if (-not $DAGdata.Currency.$Currency.BlockHeight -or $DAGdata.Updated.$Url -lt $Session.ScriptStartTime -or $DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
            # Get block data from BLOCX block explorer
            try { 
                Write-Message -Level Info "Loading DAG data from '$Url'..."
                $CurrencyDAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 15 -SkipCertificateCheck
                if ([UInt64]($CurrencyDAGdataResponse.total_blocks) -ge $DAGdata.Currency.$Currency.BlockHeight) { 
                    $CurrencyDAGdata = Get-DAGdata -BlockHeight $CurrencyDAGdataResponse.total_blocks -Currency $Currency -EpochReserve 2
                    if ($CurrencyDAGdata.DAGsize) { 
                        $CurrencyDAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                        $CurrencyDAGdata | Add-Member Url $Url -Force
                        $DAGdata.Currency | Add-Member $Currency $CurrencyDAGdata -Force
                        $DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
                    }
                    else { 
                        Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                    }
                }
            }
            catch { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
            }
        }
    }

    # ZPool also supplies PHI DAG data
    if (-not ($Session.Config.PoolName -match "^ZPool.*")) { 
        # Update on script start, once every 24hrs or if unable to get data from source on last attempt
        $Currency = "PHI"
        if ($Session.CurrencyAlgorithm[$Currency]) { 
            $Url = "https://explorer.phicoin.net/api/getblockcount"
            if (-not $DAGdata.Currency.$Currency.BlockHeight -or $DAGdata.Currency.$Currency.Date -lt $Session.ScriptStartTime -or $DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
                # Get block data from PHI block explorer
                try { 
                    Write-Message -Level Info "Loading DAG data from '$Url'..."
                    $CurrencyDAGdataResponse = [Int64](Invoke-RestMethod -Uri $Url -TimeoutSec 15 -SkipCertificateCheck)
                    if ($CurrencyDAGdataResponse -ge $DAGdata.Currency.$Currency.BlockHeight) { 
                        $CurrencyDAGdata = Get-DAGdata -BlockHeight $CurrencyDAGdataResponse -Currency $Currency -EpochReserve 0
                        if ($CurrencyDAGdata.Epoch -ge 0) { 
                            $CurrencyDAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                            $CurrencyDAGdata | Add-Member Url $Url -Force
                            $DAGdata.Currency | Add-Member $Currency $CurrencyDAGdata -Force
                            $DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
                        }
                        else { 
                            Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                        }
                    }
                }
                catch { 
                    Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
                }
            }
        }
    }

    # Zpool also supplies MEWC DAG data
    if (-not ($Session.Config.PoolName -match "^ZPool.+")) { 
        # Update on script start, once every 24hrs or if unable to get data from source on last attempt
        $Currency = "MEWC"
        if ($Session.CurrencyAlgorithm[$Currency]) { 
            $Url = "https://mewc.cryptoscope.io/api/getblockcount"
            if (-not $DAGdata.Currency.$Currency.BlockHeight -or $DAGdata.Currency.$Currency.Date -lt $Session.ScriptStartTime -or $DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
                # Get block data from MeowCoin block explorer
                try { 
                    Write-Message -Level Info "Loading DAG data from '$Url'..."
                    $CurrencyDAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 15 -SkipCertificateCheck
                    if ([UInt64]($CurrencyDAGdataResponse.blockcount) -ge $DAGdata.Currency.$Currency.BlockHeight) { 
                        $CurrencyDAGdata = Get-DAGdata -BlockHeight $CurrencyDAGdataResponse.blockcount -Currency $Currency -EpochReserve 2
                        if ($CurrencyDAGdata.Epoch -ge 0) { 
                            $CurrencyDAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                            $CurrencyDAGdata | Add-Member Url $Url -Force
                            $DAGdata.Currency | Add-Member $Currency $CurrencyDAGdata -Force
                            $DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
                        }
                        else { 
                            Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                        }
                    }
                }
                catch { 
                    Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
                }
            }
        }
    }

    # Update on script start, once every 24hrs or if unable to get data from source on last attempt
    $Currency = "LAX"
    if ($Session.CurrencyAlgorithm[$Currency]) { 
        $Url = "https://explorer.parallaxchain.org/api/v2/stats"
        if (-not $DAGdata.Currency.$Currency.BlockHeight -or $DAGdata.Updated.$Url -lt $Session.ScriptStartTime -or $DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
            # Get block data from Parallax block explorer
            try { 
                Write-Message -Level Info "Loading DAG data from '$Url'..."
                $CurrencyDAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 15 -SkipCertificateCheck
                if ([UInt64]($CurrencyDAGdataResponse.total_blocks) -ge $DAGdata.Currency.$Currency.BlockHeight) { 
                    $CurrencyDAGdata = Get-DAGdata -BlockHeight $CurrencyDAGdataResponse.total_blocks -Currency $Currency -EpochReserve 2
                    if ($CurrencyDAGdata.Epoch -ge 0) { 
                        $CurrencyDAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                        $CurrencyDAGdata | Add-Member Url $Url -Force
                        $DAGdata.Currency | Add-Member $Currency $CurrencyDAGdata -Force
                        $DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
                    }
                    else { 
                        Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                    }
                }
            }
            catch { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
            }
        }
    }
    # }

    if ($DAGdata.Updated.PSObject.Properties.Name.Where({ $DAGdata.Updated.$_ -gt $Session.Timer })) { 
        # At least one DAG was updated, get maximum DAG size per algorithm
        $CurrencyDAGdataKeys = @($DAGdata.Currency.PSObject.Properties.Name) # Store as array to avoid error 'An error occurred while enumerating through a collection: Collection was modified; enumeration operation may not execute.'

        foreach ($Algorithm in @($CurrencyDAGdataKeys.ForEach({ $DAGdata.Currency.$_.Algorithm }) | Select-Object -Unique)) { 
            $DAGdata.Algorithm | Add-Member $Algorithm (
                [PSCustomObject]@{ 
                    BlockHeight = [UInt32]($CurrencyDAGdataKeys.Where({ $DAGdata.Currency.$_.Algorithm -eq $Algorithm }).ForEach({ $DAGdata.Currency.$_.BlockHeight }) | Measure-Object -Maximum).Maximum
                    DAGsize     = [UInt64]($CurrencyDAGdataKeys.Where({ $DAGdata.Currency.$_.Algorithm -eq $Algorithm }).ForEach({ $DAGdata.Currency.$_.DAGsize }) | Measure-Object -Maximum).Maximum
                    Epoch       = [UInt16]($CurrencyDAGdataKeys.Where({ $DAGdata.Currency.$_.Algorithm -eq $Algorithm }).ForEach({ $DAGdata.Currency.$_.Epoch }) | Measure-Object -Maximum).Maximum
                }
            ) -Force
            $DAGdata.Algorithm.$Algorithm | Add-Member Currency ([String]($CurrencyDAGdataKeys.Where({ $DAGdata.Currency.$_.DAGsize -eq $DAGdata.Algorithm.$Algorithm.DAGsize -and $DAGdata.Currency.$_.Algorithm -eq $Algorithm }))) -Force
            $DAGdata.Algorithm.$Algorithm | Add-Member CoinName ([String]($Session.CoinNames[$DAGdata.Algorithm.$Algorithm.Currency])) -Force
        }

        # Add default '*' (equal to highest)
        $DAGdata.Currency | Add-Member "*" (
            [PSCustomObject]@{ 
                BlockHeight = [UInt32]($CurrencyDAGdataKeys.ForEach({ $DAGdata.Currency.$_.BlockHeight }) | Measure-Object -Maximum).Maximum
                Currency    = "*"
                DAGsize     = [UInt64]($CurrencyDAGdataKeys.ForEach({ $DAGdata.Currency.$_.DAGsize }) | Measure-Object -Maximum).Maximum
                Epoch       = [UInt16]($CurrencyDAGdataKeys.ForEach({ $DAGdata.Currency.$_.Epoch }) | Measure-Object -Maximum).Maximum
            }
        ) -Force
        $DAGdata = $DAGdata | Get-SortedObject
        $DAGdata | ConvertTo-Json -Depth 5 | Out-File -LiteralPath ".\Data\DAGdata.json" -Force
    }

    return $DAGdata
}

function Get-DAGdata { 

    param (
        [Parameter (Mandatory = $true)]
        [UInt32]$BlockHeight,
        [Parameter (Mandatory = $true)]
        [String]$Currency,
        [Parameter (Mandatory = $false)]
        [String]$Algorithm = $Session.CurrencyAlgorithm[$Currency],
        [Parameter (Mandatory = $false)]
        [Int16]$EpochReserve = 0
    )

    if ($Currency -eq "BLOCX") { 
        return [PSCustomObject]@{ 
            Algorithm   = $Algorithm
            BlockHeight = [UInt32]$BlockHeight
            CoinName    = [String]$Session.CoinNames[$Currency]
            DAGsize     = [UInt64]2GB
            Epoch       = [UInt32]0
        }
    }
    elseif ($Algorithm) { 
        $Epoch = Get-DAGepoch -BlockHeight $BlockHeight -Algorithm $Algorithm -EpochReserve $EpochReserve

        return [PSCustomObject]@{ 
            Algorithm   = $Algorithm
            BlockHeight = [UInt32]$BlockHeight
            CoinName    = [String]$Session.CoinNames[$Currency]
            DAGsize     = [UInt64](Get-DAGSize -Epoch $Epoch -Currency $Currency)
            Epoch       = [UInt32]$Epoch
        }
    }

    return [PSCustomObject]@{ }
}

function Get-DAGsize { 

    param (
        [Parameter (Mandatory = $true)]
        [UInt32]$Epoch,
        [Parameter (Mandatory = $true)]
        [String]$Currency
    )

    switch ($Currency) { 
        "CFX" { 
            $DatasetBytesInit = 4GB
            $DatasetBytesGrowth = 16MB
            $MixBytes = 256
            $Size = $DatasetBytesInit + ($DatasetBytesGrowth * $Epoch) - $MixBytes
            while (-not (Test-IsPrime ($Size / $MixBytes))) { 
                $Size -= 2 * $MixBytes
            }
            break
        }
        "ERG" { 
            # https://github.com/RainbowMiner/RainbowMiner/issues/2102
            $Size = 64MB
            $BlockHeight = [Math]::Min($BlockHeight, 4198400)
            if ($BlockHeight -ge 614400) { 
                $P = [Math]::Floor(($BlockHeight - 614400) / 51200) + 1
                while ($P-- -gt 0) { 
                    $Size = [Math]::Floor($Size / 100) * 105
                }
            }
            $Size *= 31
            break
        }
        "EVR" { 
            $DatasetBytesInit = 3GB
            $DatasetBytesGrowth = 8MB
            $MixBytes = 128
            $Size = $DatasetBytesInit + ($DatasetBytesGrowth * $Epoch) - $MixBytes
            while (-not (Test-IsPrime ($Size / $MixBytes))) { 
                $Size -= 2 * $MixBytes
            }
            break
        }
        "IRON" { 
            # IRON (FishHash) has a static DAG size of 4608MB (Ethash epoch 448, https://github.com/iron-fish/fish-hash/blob/main/FishHash.pdf Chapter 4)
            $Size = 4608MB
            break
        }
        "KLS" { 
            # KLS (KarlsenHash) is based on FishHash and has a static DAG size of 4608MB (Ethash epoch 448, https://github.com/iron-fish/fish-hash/blob/main/FishHash.pdf Chapter 4)
            $Size = 4608MB
            break
        }
        "MEWC" { 
            if ($Epoch -ge 110) { $Epoch *= 4 } # https://github.com/Meowcoin-Foundation/meowpowminer/blob/6e1f38c1550ab23567960699ba1c05aad3513bcd/libcrypto/ethash.hpp#L48 & https://github.com/Meowcoin-Foundation/meowpowminer/blob/6e1f38c1550ab23567960699ba1c05aad3513bcd/libcrypto/ethash.cpp#L249C1-L254C6
            $DatasetBytesInit = 1GB
            $DatasetBytesGrowth = 8MB
            $MixBytes = 128
            $Size = $DatasetBytesInit + ($DatasetBytesGrowth * $Epoch) - $MixBytes
            while (-not (Test-IsPrime ($Size / $MixBytes))) { 
                $Size -= 2 * $MixBytes
            }
            break
        }
        default { 
            $DatasetBytesInit = 1GB
            $DatasetBytesGrowth = 8MB
            $MixBytes = 128
            $Size = $DatasetBytesInit + ($DatasetBytesGrowth * $Epoch) - $MixBytes
            while (-not (Test-IsPrime ($Size / $MixBytes))) { 
                $Size -= 2 * $MixBytes
            }
        }
    }

    return [UInt64]$Size
}

function Get-DAGepoch { 

    param (
        [Parameter (Mandatory = $true)]
        [UInt32]$BlockHeight,
        [Parameter (Mandatory = $true)]
        [String]$Algorithm,
        [Parameter (Mandatory = $true)]
        [UInt16]$EpochReserve
    )

    switch ($Algorithm) { 
        "Autolykos2" { $BlockHeight -= 416768; break } # Epoch 0 starts @ 417792
        "FiroPow"    { if ($BlockHeight -gt 1205100) { return 700 } } # https://github.com/firoorg/firo/pull/1648/commits/436d5627bb9b9be6d32f4a24c2fc611e79325189 & https://github.com/firoorg/firo/commit/a3a4be2685ca99b1343de81367596655617a2974
        "FishHash"   { return 448 } # IRON (FishHash) has static DAG size of 4608MB (Ethash epoch 448, https://github.com/iron-fish/fish-hash/blob/main/FishHash.pdf Chapter 4)
        "PhiHash"    { return [Math]::Floor(((Get-Date) - [DateTime]::ParseExact("11/06/2023", "MM/dd/yyyy", $null)).TotalDays / 365.25) - 1 }
        default      { }
    }

    return [Math]::Floor($BlockHeight / (Get-DAGepochLength -BlockHeight $BlockHeight -Algorithm $Algorithm)) + $EpochReserve
}

function Get-DAGepochLength { 

    param (
        [Parameter (Mandatory = $true)]
        [UInt32]$BlockHeight,
        [Parameter (Mandatory = $true)]
        [String]$Algorithm
    )

    switch ($Algorithm) { 
        "Autolykos2"      { return 1024 }
        "EtcHash"         { if ($BlockHeight -ge 11700000) { return 60000 } else { return 30000 } }
        "EthashSHA256"    { return 4000 }
        "EvrProgPow"      { return 12000 }
        "FiroPow"         { return 1300 }
        "KawPow"          { return 7500 }
        "MeowPow"         { return 7500 } # https://github.com/Meowcoin-Foundation/meowpowminer/blob/6e1f38c1550ab23567960699ba1c05aad3513bcd/libcrypto/ethash.hpp#L32
        "Octopus"         { return 524288 }
        "PhiHash"         { return 7500 } # https://github.com/PhicoinProject/phihashminer_v2/blob/main/README.md
        "SCCpow"          { return 3240 } # https://github.com/stakecube/sccminer/commit/16bdfcaccf9cba555f87c05f6b351e1318bd53aa#diff-200991710fe4ce846f543388b9b276e959e53b9bf5c7b7a8154b439ae8c066aeR32
        "ProgPowTelestai" { return 12000 }
        default           { return 30000 }
    }
}

function Get-Median { 

    param (
        [Parameter (Mandatory = $true)]
        [Double[]]$Numbers
    )

    $Numbers = $Numbers | Sort-Object
    $Count = $Numbers.Count

    if ($Count % 2 -eq 0) { 
        # Even number of elements, median is the average of the two middle elements
        return ($Numbers[$Count / 2] + $Numbers[$Count / 2 - 1]) / 2
    }
    else { 
        # Odd number of elements, median is the middle element
        return $Numbers[$Count / 2]
    }
}

function Hide-Console { 
    # https://stackoverflow.com/questions/3571627/show-hide-the-console-window-of-a-c-sharp-console-application
    if ($host.Name -eq "ConsoleHost") { 
        if ($ConsoleWindowHandle = [Console.Window]::GetConsoleWindow()) { 
            # 0 = SW_HIDE
            $null = [Console.Window]::ShowWindow($ConsoleWindowHandle, 0)
        }
    }
}

function Show-Console { 
    # https://stackoverflow.com/questions/3571627/show-hide-the-console-window-of-a-c-sharp-console-application
    if ($host.Name -eq "ConsoleHost") { 
        if ($ConsoleWindowHandle = [Console.Window]::GetConsoleWindow()) { 
            # 5 = SW_SHOW
            $null = [Console.Window]::ShowWindow($ConsoleWindowHandle, 5)
        }
    }
}

function Get-MemoryUsage { 

    $MemUsageByte = [System.GC]::GetTotalMemory("forcefullcollection")
    $MemUsageMB = $MemUsageByte / 1MB
    $DiffBytes = $MemUsageByte - $Script:LastMemoryUsageByte
    $DiffText = ""
    $Sign = ""

    if ($Script:LastMemoryUsageByte -ne 0) { 
        if ($DiffBytes -ge 0) { $Sign = "+" }
        $DiffText = ", $Sign$DiffBytes"
    }

    # Save last value in script global variable
    $Script:LastMemoryUsageByte = $MemUsageByte

    return ("Memory usage {0:n1} MB ({1:n0} Bytes {2})" -f $MemUsageMB, $MemUsageByte, $Difftext)
}

function Start-APIserver { 

    if ($Session.APIport -and $Session.Config.APIport -ne $Session.APIport) { 
        Stop-APIserver
    }

    if (-not $Global:APIrunspace) { 

        $TCPclient = [System.Net.Sockets.TCPClient]::new()
        $AsyncResult = $TCPclient.BeginConnect("127.0.0.1", $Session.Config.APIport, $null, $null)
        if ($AsyncResult.AsyncWaitHandle.WaitOne(100)) { 
            Write-Message -Level Error "Error starting API on TCP port $($Session.Config.APIport). Port is in use."
            $Session.MinerBaseAPIport = 4000
            Write-Message -Level Warn "Using TCP port $(if ($Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported }).Count -eq 1) { $Session.MinerBaseAPIport } else { "range $($Session.MinerBaseAPIport) - $($Session.MinerBaseAPIport + $Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported }).Count - 1)" }) for miner communication."
            [Void]$TCPclient.Dispose()

            return
        }
        Remove-Variable AsyncResult, TCPClient

        # Setup runspace to launch the API server in a separate thread
        $Global:APIrunspace = [RunspaceFactory]::CreateRunspace()
        $Global:APIrunspace.ApartmentState = "STA"
        $Global:APIrunspace.Name = "APIServer"
        $Global:APIrunspace.ThreadOptions = "ReuseThread"
        $Global:APIrunspace.Open()

        $Global:APIrunspace.SessionStateProxy.SetVariable("Config", $Config)
        $Global:APIrunspace.SessionStateProxy.SetVariable("Session", $Session)
        $Global:APIrunspace.SessionStateProxy.SetVariable("Stats", $Stats)
        [Void]$Global:APIrunspace.SessionStateProxy.Path.SetLocation($Session.MainPath)

        $PowerShell = [PowerShell]::Create()
        $PowerShell.Runspace = $Global:APIrunspace
        [Void]$Powershell.AddScript("$($Session.MainPath)\Includes\APIserver.ps1")
        $Global:APIrunspace | Add-Member PowerShell $PowerShell

        # Initialize API and web GUI
        Write-Message -Level Verbose "Starting API and web GUI on 'http://localhost:$($Session.Config.APIport)'..."
        $Global:APIrunspace | Add-Member Job ($Global:APIrunspace.PowerShell.BeginInvoke())
        $Global:APIrunspace | Add-Member StartTime ([DateTime]::Now.ToUniversalTime())

        # Wait for API to get ready
        $RetryCount = 3
        while (-not ($Session.APIversion) -and $RetryCount -gt 0) { 
            Start-Sleep -Seconds 1
            try { 
                if ($Session.APIversion = [Version](Invoke-RestMethod "http://localhost:$($Session.Config.APIport)/apiversion" -TimeoutSec 1 -ErrorAction Stop)) { 
                    $Session.APIport = $Session.Config.APIport
                    if ($Session.Config.APIlogfile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): API (version $($Session.APIversion)) started." | Out-File $Session.Config.APIlogfile -Force -ErrorAction Ignore }
                    $Session.MinerBaseAPIport = $Session.APIport + 1
                    Write-Message -Level Info "API and web GUI is running on http://localhost:$($Session.APIport). Using TCP port $(if ($Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported }).Count -eq 1) { $Session.MinerBaseAPIport } else { "range $($Session.MinerBaseAPIport) - $($Session.MinerBaseAPIport + $Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported }).Count - 1)" }) for miner communication."
                    # Start Web GUI (show configuration edit if no existing config)
                    if ($Session.Config.WebGUI) { Start-Process "http://localhost:$($Session.APIport)$(if ($Session.FreshConfig -or $Session.ConfigurationHasChangedDuringUpdate) { "/configedit.html" })" }
                    break
                }
            }
            catch { }
            $RetryCount--
        }

        if ($Session.APIversion) { 
            $Session.MinerBaseAPIport = $Session.Config.MinerBaseAPIport
        }
        else { 
            Write-Message -Level Error "Error starting API on TCP port $($Session.Config.APIport)."
            $Session.MinerBaseAPIport = 4000
            Write-Message -Level Warn "Using TCP port $(if ($Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported }).Count -eq 1) { $Session.MinerBaseAPIport } else { "range $($Session.MinerBaseAPIport) - $($Session.MinerBaseAPIport + $Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported }).Count)" }) for miner communication."
        }
    }
}

function Stop-APIserver { 

    if ($Global:APIrunspace.Job.IsCompleted -eq $false) { 

        if ($Session.APIserver.IsListening) { 
            $Session.APIserver.Stop()
            if (-not $Session.MinerBaseAPIport) { $Session.MinerBaseAPIport = 4000 }
            Write-Message -Level Verbose "Stopped API and web GUI on TCP port $($Session.APIport). Using TCP port $(if ($Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported }).Count -eq 1) { $Session.MinerBaseAPIport } else { "range $($Session.MinerBaseAPIport) - $($Session.MinerBaseAPIport + $Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported }).Count - 1)" }) for miner communication."
        }

        $Session.APIserver.Close()
        $Session.APIserver.Dispose()

        $Global:APIrunspace.PowerShell.Stop()
        $Global:APIrunspace.PSObject.Properties.Remove("StartTime")

        $Session.Remove("APIport")
        $Session.Remove("APIversion")
    }

    $Session.MinerBaseAPIport = $Session.Config.MinerBaseAPIport

    if ($Global:APIrunspace) { 

        $Global:APIrunspace.PSObject.Properties.Remove("Job")

        $Global:APIrunspace.PowerShell.Dispose()
        $Global:APIrunspace.PowerShell = $null
        $Global:APIrunspace.Close()
        $Global:APIrunspace.Dispose()

        Remove-Variable APIrunspace -Scope Global
    }
}

function Set-MinerEnabled { 

    param (
        [Parameter (Mandatory = $true)]
        [Miner]$Miner
    )

    foreach ($Worker in $Miner.Workers) { 
        Enable-Stat -Name "$($Miner.Name)_$($Worker.Pool.Algorithm)_Hashrate"
    }

    $Miner.Disabled = $false
    $Miner.Reasons.Where({ $_ -notlike "Unrealistic *" }).ForEach({ $null = $Miner.Reasons.Remove({ $_ }) })
    if (-not $Miner.Reasons.Count) { $Miner.Available = $true }
}

function Set-MinerDisabled { 

    param (
        [Parameter (Mandatory = $true)]
        [Miner]$Miner
    )

    foreach ($Worker in $Miner.Workers) { 
        Disable-Stat -Name "$($Miner.Name)_$($Worker.Pool.Algorithm)_Hashrate"
        $Worker.Disabled = $false
    }

    $Miner.Available = $false
    $Miner.Disabled = $true
    if (-not $Miner.Reasons.Contains("Disabled by user")) { $null = $Miner.Reasons.Add("Disabled by user") }
}

function Set-MinerFailed { 

    param (
        [Parameter (Mandatory = $true)]
        [Miner]$Miner
    )

    foreach ($Worker in $Miner.Workers) { 
        Set-Stat -Name "$($Miner.Name)_$($Worker.Pool.Algorithm)_Hashrate" -Value 0 -FaultDetection $false
        $Worker.Hashrate = [Double]::NaN
        $Worker.Disabled = $false
        $Worker.Earnings = [Double]::NaN
        $Worker.Earnings_Accuracy = [Double]::NaN
        $Worker.Earnings_Bias = [Double]::NaN
        $Worker.Fee = 0
        $Worker.Hashrate = [Double]::NaN
        $Worker.TotalMiningDuration = [TimeSpan]0
    }
    Remove-Variable Worker

    # Clear power consumption
    Remove-Stat -Name "$($Miner.Name)_PowerConsumption"
    $Miner.PowerConsumption = $Miner.PowerCost = $Miner.Profit = $Miner.Profit_Bias = $Miner.Earnings = $Miner.Earnings_Bias = [Double]::NaN

    if (-not $Miner.Reasons.Contains("0 h/s stat file")) { $null = $Miner.Reasons.Add("0 h/s stat file") }
    $Miner.Available = $false
}

function Set-MinerReBenchmark { 

    param (
        [Parameter (Mandatory = $true)]
        [Object]$Miner
    )

    $Miner.Activated = 0 # To allow 3 attempts
    $Miner.Data = [System.Collections.Generic.HashSet[PSCustomObject]]::new()

    foreach ($Worker in $Miner.Workers) { 
        Remove-Stat -Name "$($Miner.Name)_$($Worker.Pool.Algorithm)_Hashrate"
        $Worker.Disabled = $false
        $Worker.Earnings = [Double]::NaN
        $Worker.Earnings_Accuracy = [Double]::NaN
        $Worker.Earnings_Bias = [Double]::NaN
        $Worker.Fee = 0
        $Worker.Hashrate = [Double]::NaN
        $Worker.TotalMiningDuration = [TimeSpan]0
    }
    Remove-Variable Worker

    Remove-Stat -Name "$($Miner.Name)_PowerConsumption"
    $Miner.Earnings = $Miner.Earnings_Accuracy = $Miner.Earnings_Bias = $Miner.PowerCost = $Miner.PowerConsumption = $Miner.PowerConsumption_Live = $Miner.Profit = $Miner.Profit_Bias = [Double]::NaN
    $Miner.Hashrates_Live = @($this.Workers.ForEach({ [Double]::NaN }))

    $Miner.Benchmark = $true
    $Miner.MeasurePowerConsumption = $true
    $Miner.Reasons = [System.Collections.Generic.SortedSet[String]]::new()
    $Miner.Available = $true

    # Remove watchdog
    $Session.WatchdogTimers = $Session.WatchdogTimers.Where({ $_.MinerName -ne $Miner.Name })
}

function Set-MinerMeasurePowerConsumption { 

    param (
        [Parameter (Mandatory = $true)]
        [Miner]$Miner
    )

    $Miner.Activated = 0 # To allow 3 attempts
    $Miner.Data = [System.Collections.Generic.HashSet[PSCustomObject]]::new()

    # Clear power consumption
    Remove-Stat -Name "$($Miner.Name)_PowerConsumption"
    $Miner.PowerConsumption = $Miner.PowerCost = $Miner.Profit = $Miner.Profit_Bias = [Double]::NaN

    $Miner.MeasurePowerConsumption = $true
    $Miner.Reasons = [System.Collections.Generic.SortedSet[String]]::new()
    $Miner.Available = $true

    # Remove watchdog
    $Session.WatchdogTimers = $Session.WatchdogTimers.Where({ $_.MinerName -ne $Miner.Name })
}

function Exit-UGminer { 

if ($LegacyGUIelements.TabControl) { $LegacyGUIelements.TabControl.SelectTab(0) }

    Write-Message -Level Info "Shutting down $($Session.Branding.ProductLabel)..."
    $Session.NewMiningStatus = "Idle"

    Stop-CoreCycle
    Stop-Brain
    Stop-BalancesTracker

    Write-Message -Level Info "$($Session.Branding.ProductLabel) has shut down."
    Start-Sleep -Seconds 2
    try {
        Stop-Process (Get-CimInstance CIM_Process).Where({ $_.CommandLine -eq """$($Session.LogViewerExe)"" $($Session.LogViewerConfig)" }).ProcessId -Force
    }
    catch {}
    Stop-Process $PID -Force
}

function Read-Config { 

    param (
        [Parameter (Mandatory = $true)]
        [String]$ConfigFile,
        [Parameter (Mandatory = $true)]
        [String]$PoolsConfigFile
    )

    function Read-ConfigFiles { 

        param (
            [Parameter (Mandatory = $true)]
            [String]$ConfigFile,
            [Parameter (Mandatory = $true)]
            [String]$PoolsConfigFile
        )

        function Get-DefaultConfig { 

            $DefaultConfig = @{ }
            $DefaultConfig.ConfigFileVersion = $Session.Branding.Version.ToString()

            # Add default config items
            $Session.AllCommandLineParameters.psBase.Keys.Where({ $_ -notin $DefaultConfig.psBase.Keys }).ForEach(
                { 
                    $Value = $Session.AllCommandLineParameters.$_
                    if ($Value -is [Switch]) { $Value = [Boolean]$Value }
                    $DefaultConfig.$_ = $Value
                }
            )

            return $DefaultConfig
        }

        function Get-PoolsConfig { 

            # Load default pool data
            $Session.PoolData = [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase)
            (Get-ChildItem -Path ".\Data\PoolData_*.json" | Sort-Object -Property BaseName).ForEach(
                { 
                    $Session.PoolData.$($_.BaseName -replace "PoolData_") = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines($_.ResolvedTarget) | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase)
                }
            )
            $Session.PoolBaseNames = @($Session.PoolData.Keys)
            $Session.PoolVariants = @(($Session.PoolBaseNames.ForEach({ $Session.PoolData.$_.Variant.Keys }).Where({ Test-Path -LiteralPath "$PWD\Pools\$(Get-PoolBaseName $_).ps1" })) | Sort-Object -Unique)
            if (-not $Session.PoolVariants) { 
                Write-Message -Level Error "Terminating error - cannot continue! File '.\Data\PoolData.json' is not a valid $($Session.Branding.ProductLabel) JSON data file. Please restore it from your original download."
                $null = (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\PoolData.json' is not a valid $($Session.Branding.ProductLabel) JSON data file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112)
                exit
            }

            # Build in memory pool config
            $PoolsConfig = [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase)
            ((Get-ChildItem .\Pools\*.ps1 -File).BaseName | Sort-Object -Unique).ForEach(
                { 
                    $PoolName = $_
                    if ($PoolConfig = $Session.PoolData.$PoolName.Clone()) { 

                        # Merge default config data with custom pool config
                        if ($Config.Pools.$PoolName) { $PoolConfig = Merge-Hashtable -HT1 $PoolConfig -HT2 $Config.Pools.$PoolName -Unique $true }

                        if (-not $PoolConfig.EarningsAdjustmentFactor) { $PoolConfig.EarningsAdjustmentFactor = $ConfigFromFile.EarningsAdjustmentFactor }
                        if ($PoolConfig.EarningsAdjustmentFactor -le 0 -or $PoolConfig.EarningsAdjustmentFactor -gt 10) { 
                            $PoolConfig.EarningsAdjustmentFactor = $ConfigFromFile.EarningsAdjustmentFactor
                            Write-Message -Level Warn "Earnings adjustment factor (value: $($PoolConfig.EarningsAdjustmentFactor)) for pool '$PoolName' is not within supported range (0 - 10); using default value $($PoolConfig.EarningsAdjustmentFactor)."
                        }

                        if (-not $PoolConfig.WorkerName) { $PoolConfig.WorkerName = $ConfigFromFile.WorkerName }
                        if (-not $PoolConfig.BalancesKeepAlive) { $PoolConfig.BalancesKeepAlive = $PoolData.$PoolName.BalancesKeepAlive }

                        $PoolConfig.Region = $PoolConfig.Region.Where({ (Get-Region $_) -notin @($PoolConfig.ExcludeRegion) })

                        switch ($PoolName) { 
                            "HiveON" { 
                                if (-not $PoolConfig.Wallets) { 
                                    $PoolConfig.Wallets = [System.Collections.SortedList]::new([StringComparer]::OrdinalIgnoreCase) # as ssorted case insensitive hash table
                                    $ConfigFromFile.Wallets.GetEnumerator().Name.Where({ $PoolConfig.PayoutCurrencies -contains $_ }).ForEach({ $PoolConfig.Wallets.$_ = $ConfigFromFile.Wallets.$_ })
                                }
                                break
                            }
                            "MiningDutch" { 
                                if ((-not $PoolConfig.PayoutCurrency) -or $PoolConfig.PayoutCurrency -eq "[Default]") { $PoolConfig.PayoutCurrency = $ConfigFromFile.PayoutCurrency }
                                if (-not $PoolConfig.UserName) { $PoolConfig.UserName = $ConfigFromFile.MiningDutchUserName }
                                break
                            }
                            "MiningPoolHub" { 
                                if (-not $PoolConfig.UserName) { $PoolConfig.UserName = $ConfigFromFile.MiningPoolHubUserName }
                                break
                            }
                            "NiceHash" { 
                                if ($ConfigFromFile.NiceHashWallet) { $PoolConfig.Wallets = @{ "BTC" = $ConfigFromFile.NiceHashWallet } }
                                break
                            }
                            default { 
                                if ((-not $PoolConfig.PayoutCurrency) -or $PoolConfig.PayoutCurrency -eq "[Default]") { $PoolConfig.PayoutCurrency = $ConfigFromFile.PayoutCurrency }
                                if (-not $PoolConfig.Wallets) { $PoolConfig.Wallets = $ConfigFromFile.Wallets }
                            }
                        }
                        $PoolsConfig.$PoolName = $PoolConfig
                    }
                }
            )

            Remove-Variable PoolConfig, PoolName -ErrorAction Ignore

            return $PoolsConfig
        }

        # Load the configuration
        $ConfigFromFile = [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase)
        if (Test-Path -LiteralPath $ConfigFile -PathType Leaf) { 
            try { 
                $ConfigFromFile = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines($ConfigFile) | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase)
            } 
            catch { }
            if ($ConfigFromFile.Keys.Count -eq 0) { 
                $CorruptConfigFile = "$($ConfigFile)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").corrupt"
                Move-Item -Path $ConfigFile $CorruptConfigFile -Force
                if ($Config.psBase.Keys.Count -gt 0) { 
                    Write-Message -Level Error "Configuration file '$($ConfigFile.Replace($PWD, "."))' is corrupt and was renamed to '$($CorruptConfigFile.Replace($PWD, "."))'. Using previous configuration values."
                    Write-Configuration -Config $Config
                    $Session.ConfigTimestamp = (Get-Item -Path $Session.ConfigFile).LastWriteTime
                    continue
                }
                else { 
                    Write-Host "Configuration file '$($ConfigFile.Replace($PWD, "."))' is corrupt and was renamed to '$($CorruptConfigFile.Replace($PWD, "."))'. Creating a new configuration using default values." -ForegroundColor "Red"
                    Write-Host
                    $ConfigFromFile = Get-DefaultConfig
                }
            }
            else { 
                $Session.ConfigTimestamp = (Get-Item -Path $Session.ConfigFile).LastWriteTime
                ($Session.AllCommandLineParameters.Keys | Sort-Object).ForEach(
                    { 
                        if ($ConfigFromFile.Keys -contains $_) { 
                            # Upper / lower case conversion of variable keys (Only visually important, config item names are actually not case sensitive)
                            $Value = $ConfigFromFile.$_
                            $ConfigFromFile.Remove($_)
                            if ($Session.AllCommandLineParameters.$_ -is [Switch]) { 
                                $ConfigFromFile.$_ = [Boolean]$Value
                            }
                            elseif ($Session.AllCommandLineParameters.$_ -is [Array]) { 
                                $ConfigFromFile.$_ = [System.Collections.Generic.SortedSet[Object]]($Value)
                            }
                            elseif ($Session.AllCommandLineParameters.$_ -is [Hashtable]) { 
                                $ConfigFromFile.$_ = [System.Collections.SortedList]::New($Value, [StringComparer]::OrdinalIgnoreCase)
                            }
                            else { 
                                $ConfigFromFile.$_ = $Value -as $Session.AllCommandLineParameters.$_.GetType().Name
                            }
                        }
                        else { 
                            # Config parameter not in config file - use hardcoded value
                            $Value = $Session.AllCommandLineParameters.$_
                            if ($Value -is [Switch]) { $Value = [Boolean]$Value }
                            $ConfigFromFile.$_ = $Value
                        }
                    }
                )
                if ($ConfigFromFile.EarningsAdjustmentFactor -le 0 -or $ConfigFromFile.EarningsAdjustmentFactor -gt 10) { 
                    $ConfigFromFile.EarningsAdjustmentFactor = $Session.AllCommandLineParameters.EarningsAdjustmentFactor
                    Write-Message -Level Warn "Configured EarningsAdjustmentFactor value $($ConfigFromFile.EarningsAdjustmentFactor) is not within supported range (0 - 10). Using default value $($Session.AllCommandLineParameters.EarningsAdjustmentFactor)."
                }
                if ($ConfigFromFile.PoolAllowedPriceIncreaseFactor -le 2 -or $ConfigFromFile.EarningsAdjustmentFactor -gt 99) { 
                    $ConfigFromFile.PoolAllowedPriceIncreaseFactor = $Session.AllCommandLineParameters.PoolAllowedPriceIncreaseFactor
                    Write-Message -Level Warn "Configured PoolAllowedPriceIncreaseFactor value $($ConfigFromFile.PoolAllowedPriceIncreaseFactor) is not within supported range (1 - 99). Using default value $($Session.AllCommandLineParameters.PoolAllowedPriceIncreaseFactor)."
                }
                if ($ConfigFromFile.CPUMiningReserveCPUcore -lt 0 -or $ConfigFromFile.CPUMiningReserveCPUcore -gt [Environment]::ProcessorCount) { 
                    $ConfigFromFile.CPUMiningReserveCPUcore = $Session.AllCommandLineParameters.CPUMiningReserveCPUcore
                    Write-Message -Level Warn "Configured CPUMiningReserveCPUcore value $($ConfigFromFile.CPUMiningReserveCPUcore) is not within supported range (0 - $([Environment]::ProcessorCount)). Using default value $($Session.AllCommandLineParameters.CPUMiningReserveCPUcore)."
                }
            }
        }
        else { 
            $ConfigFromFile = Get-DefaultConfig
        }

        # Must update existing thread safe variable. Recreation breaks updates to instances in other threads
        $ConfigFromFile.Keys.ForEach({ $Global:Config.$_ = $ConfigFromFile.$_ })

        # Build custom pools configuration, create case insensitive hashtable (https://stackoverflow.com/questions/24054147/powershell-hash-tables-double-key-error-a-and-a)
        if ($PoolsConfigFile -and (Test-Path -LiteralPath $PoolsConfigFile -PathType Leaf)) { 
            try { 
                [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase) # as case insensitve sorted hashtable
                $Config.PoolsConfig = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines($PoolsConfigFile) | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase)
            }
            catch { 
                $Config.PoolsConfig = [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase) # as case insensitive sorted hashtable
                Write-Message -Level Warn "Pools configuration file '$($PoolsConfigFile.Replace("$(Convert-Path ".\")\", ".\"))' is corrupt. Will use default values."
            }
        }

        $Global:Config.PoolsConfig = Get-PoolsConfig

        $Session.ConfigTimestamp = [DateTime]::Now.ToUniversalTime()

        # Write config file in case they do not exist already
        if (-not $Session.FreshConfig) { 
            if (-not (Test-Path -LiteralPath $Session.ConfigFile -PathType Leaf)) { 
                $Session.ConfigTimestamp = (Get-Item -Path $Session.ConfigFile).LastWriteTime.ToUniversalTime()
            }
        }
    }

    # Read-Config will read and apply configuration if configuration files have changed
    if (Test-Path -Path $Session.ConfigFile -PathType Leaf) { 
        if ((Get-Item -Path $ConfigFile -ErrorAction Ignore).LastWriteTime.ToUniversalTime() -gt $Session.ConfigTimestamp -or (Get-Item -Path $PoolsConfigFile -ErrorAction Ignore).LastWriteTime.ToUniversalTime() -gt $Session.ConfigTimestamp) { 
            Read-ConfigFiles -ConfigFile $ConfigFile -PoolsConfigFile $PoolsConfigFile

            if ($Config.APIport -lt 1024) { 
                $Config.APIPort = 3990
                Write-Message -Level Warn "API port in stored configuration is invalid. Will use default TCP port $($Config.APIPort)."
            }

            if ($Session.Config) { Write-Message -Level Verbose "Activated changed configuration." }

            if ($Config.IdleDetection -ne $Session.Config.IdleDetection) { 
                if ($Config.IdleDetection) { 
                    Write-Message -Level Verbose "Idle detection is enabled. Mining will get suspended on any keyboard or mouse activity."
                }
                elseif ($Session.MiningStatus) { 
                    Write-Message -Level Verbose "Idle detection is disabled."
                }
            }
            $Session.Config = $Config.Clone()
            $Session.Config.MinerBaseAPIport = $Session.Config.APIport + 1
        }
    }
}

function Get-ObsoleteMinerStats { 
    $StatFiles = @(Get-ChildItem ".\Stats\*" -Include "*_Hashrate.txt", "*_PowerConsumption.txt").BaseName
    $MinerNames = @(Get-ChildItem ".\Miners\*.ps1").BaseName

    return @($StatFiles.Where({ (($_ -split "-")[0, 1] -join "-") -notin $MinerNames }))
}