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
File:           \Includes\include.ps1
Version:        6.5.13
Version date:   2025/09/30
#>

$Global:DebugPreference = "SilentlyContinue"
$Global:ErrorActionPreference = "SilentlyContinue"
$Global:InformationPreference = "SilentlyContinue"
$Global:ProgressPreference = "SilentlyContinue"
$Global:WarningPreference = "SilentlyContinue"
$Global:VerbosePreference = "SilentlyContinue"

# Fix TLS Version erroring
If ([Net.ServicePointManager]::SecurityProtocol -notmatch [Net.SecurityProtocolType]::Tls10) { [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls10 }
If ([Net.ServicePointManager]::SecurityProtocol -notmatch [Net.SecurityProtocolType]::Tls11) { [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls11 }
If ([Net.ServicePointManager]::SecurityProtocol -notmatch [Net.SecurityProtocolType]::Tls12) { [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12 }

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

        [DllImport("user32.dll", SetLastError=false)]
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

Function Get-RegTime { 
    Param (
        [Parameter(Mandatory = $true)]
        [String]$RegistryPath
    )

    $Reg = Get-Item $RegistryPath -Force
    If ($Reg.handle) { 
        $Time = [System.Runtime.InteropServices.ComTypes.FILETIME]::new()
        $Result = $RegData::RegQueryInfoKey($Reg.Handle, $null, 0, 0, 0, 0, 0, 0, 0, 0, 0, [ref]$Time)
        If ($Result -eq 0) { 
            $Low = [UInt32]0 -bor $Time.dwLowDateTime
            $High = [UInt32]0 -bor $Time.dwHighDateTime
            $TimeValue = ([Int64]$High -shl 32) -bor $Low
            Return [DateTime]::FromFileTime($TimeValue)
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
Class Device { 
    [String]$Architecture
    [Int64]$Bus
    [Int]$Bus_Index
    [Int]$Bus_Type_Index
    [Int]$Bus_Platform_Index
    [Int]$Bus_Vendor_Index
    [PSCustomObject]$CIM
    [System.Version]$CUDAversion
    [Double]$ConfiguredPowerConsumption = 0 # Workaround if device does not expose power consumption
    [PSCustomObject]$CPUfeatures
    [Int]$Id
    [Int]$Index = 0
    [Int64]$Memory
    [String]$Model
    [Double]$MemoryGiB
    [String]$Name
    [PSCustomObject]$OpenCL
    [Int]$PlatformId = 0
    [Int]$PlatformId_Index
    # [PSCustomObject]$PNP
    [Boolean]$ReadPowerConsumption = $false
    # [PSCustomObject]$Reg
    [Int]$Slot = 0
    [DeviceState]$State = [DeviceState]::Enabled
    [String]$Status = "Idle"
    [String]$StatusInfo = ""
    [String]$SubStatus
    [String]$Type
    [Int]$Type_Id
    [Int]$Type_Index
    [Int]$Type_PlatformId_Index
    [Int]$Type_Slot
    [Int]$Type_Vendor_Id
    [Int]$Type_Vendor_Index
    [Int]$Type_Vendor_Slot
    [String]$Vendor
    [Int]$Vendor_Id
    [Int]$Vendor_Index
    [Int]$Vendor_Slot
}

Enum DeviceState { 
    Enabled
    Disabled
    Unsupported
}

[NoRunspaceAffinity()]
Class Pool : IDisposable { 
    [Double]$Accuracy
    [String]$Algorithm
    [String]$AlgorithmVariant
    [Boolean]$Available = $true
    [Boolean]$Best = $false
    [Nullable[Int64]]$BlockHeight = $null
    [String]$CoinName
    [String]$Currency
    [Nullable[Double]]$DAGsizeGiB = $null
    [Boolean]$Disabled = $false
    [Double]$EarningsAdjustmentFactor = 1
    [Nullable[UInt16]]$Epoch = $null
    [Double]$Fee
    [String]$Host
    # [String[]]$Hosts # To be implemented for pool failover
    [String]$Key
    [String]$Name
    [String]$Pass
    $PoolPorts = @() # Cannot define nullable array
    [UInt16]$Port
    [UInt16]$PortSSL
    [String]$PoolUri # Link to pool algorithm web page
    [Double]$Price
    [Double]$Price_Bias
    [Boolean]$Prioritize = $false # derived from BalancesKeepAlive
    [String]$Protocol
    [System.Collections.Generic.SortedSet[String]]$Reasons = @() # Why is the pool not available?
    [String]$Region
    [Boolean]$SendHashrate # If true miner will send hashrate to pool
    [Boolean]$SSLselfSignedCertificate
    [Double]$StablePrice
    [DateTime]$Updated
    [String]$User
    [String]$Variant
    [String]$WorkerName = ""
    [Nullable[UInt]]$Workers
    [String]$ZAPcurrency

    Dispose() { 
        $this = $null
    }
}

[NoRunspaceAffinity()]
Class Worker : IDisposable { 
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

Enum MinerStatus { 
    Disabled
    DryRun
    Failed
    Idle
    Running
    Unavailable
}

[NoRunspaceAffinity()]
Class Miner : IDisposable { 
    [Int]$Activated
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
    [Double[]]$Hashrates_Live = @()
    [String]$Info
    [Boolean]$KeepRunning = $false # do not stop miner even if not best (MinInterval)
    [DateTime]$LastUsed # derived from stats
    [String]$LogFile
    [Boolean]$MeasurePowerConsumption = $false # derived from stats
    [UInt16]$MinDataSample # for safe hashrate values
    [UInt16]$MinerSet
    [String]$MinerUri
    [String]$Name
    [Bool]$Optimal = $false
    [String]$Path
    [String]$PrerequisitePath
    [String]$PrerequisiteURI
    [UInt16]$Port
    [Double]$PowerCost = [Double]::NaN
    [Double]$PowerConsumption = [Double]::NaN
    [Double]$PowerConsumption_Live = [Double]::NaN
    [Boolean]$Prioritize = $false # derived from BalancesKeepAlive
    [UInt32]$ProcessId = 0
    [Int]$ProcessPriority = -1
    [Double]$Profit = [Double]::NaN
    [Double]$Profit_Bias = [Double]::NaN
    [Boolean]$ReadPowerConsumption
    [System.Collections.Generic.SortedSet[String]]$Reasons = @() # Why is the miner not available?
    [Boolean]$Restart = $false 
    hidden [DateTime]$StatStart
    hidden [DateTime]$StatEnd
    [MinerStatus]$Status = [MinerStatus]::Idle
    [String]$StatusInfo = ""
    [String]$SubStatus = [MinerStatus]::Idle
    [TimeSpan]$TotalMiningDuration # derived from pool and stats
    [String]$Type
    [DateTime]$Updated
    [String]$URI
    [DateTime]$ValidDataSampleTimestamp = 0
    [String]$Version
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

    [String[]]GetProcessNames() { 
        Return @(([IO.FileInfo]($this.Path | Split-Path -Leaf)).BaseName)
    }

    [String]GetCommandLineParameters() { 
        If ($this.Arguments -and (Test-Json -Json $this.Arguments -ErrorAction Ignore)) { 
            Return ($this.Arguments | ConvertFrom-Json).Arguments
        }
        Else { 
            Return $this.Arguments
        }
    }

    [String]GetCommandLine() { 
        Return "$($this.Path)$($this.GetCommandLineParameters())"
    }

    hidden [Void]StartDataReader() { 
        $ScriptBlock = { 
            $ScriptBody = "using module .\Includes\Include.psm1"; $Script = [ScriptBlock]::Create($ScriptBody); . $Script

            Try { 
                # Load miner API file
                . ".\Includes\MinerAPIs\$($args[0]).ps1"
                $ProgressPreference = "SilentlyContinue"
                $Miner = ($args[1] | ConvertFrom-Json) -as $args[0]
                Start-Sleep -Seconds 2

                While ($true) { 
                    $LoopEnd = [DateTime]::Now.AddSeconds($Miner.DataCollectInterval)
                    $Miner.GetMinerData()
                    While ([DateTime]::Now -lt $LoopEnd) { Start-Sleep -Milliseconds 50 }
                }
            }
            Catch { 
                Return $_
            }
            Remove-Variable Miner, LoopEnd -ErrorAction Ignore
        }

        # Start miner data reader, devices property required for GetPowerConsumption/ConfiguredPowerConsumption
        $this.DataReaderJob = Start-ThreadJob -ErrorVariable $null -InformationVariable $null -OutVariable $null -WarningVariable $null -Name "$($this.NameAndDevice)_DataReader" -StreamingHost $null -InitializationScript ([ScriptBlock]::Create("Set-Location('$(Get-Location)')")) -ScriptBlock $ScriptBlock -ArgumentList ($this.API), ($this | Select-Object -Property Algorithms, DataCollectInterval, Devices, Name, Path, Port, ReadPowerConsumption | ConvertTo-Json -Depth 5 -WarningAction Ignore)

        Remove-Variable ScriptBlock -ErrorAction Ignore
    }

    hidden [Void]StopDataReader() { 
        If ($this.DataReaderJob) { 
            $this.DataReaderJob | Stop-Job
            # Get data before removing read data
            If ($this.Status -eq [MinerStatus]::Running -and $this.DataReaderJob.HasMoreData) { ($this.DataReaderJob | Receive-Job).Where({ $_.Date }).ForEach({ $this.Data.Add($_) | Out-Null }) }
            $this.DataReaderJob | Remove-Job -Force -ErrorAction Ignore | Out-Null
            $this.DataReaderJob = $null
        }
    }

    hidden [Void]RestartDataReader() { 
        $this.StopDataReader()
        $this.StartDataReader()
    }

    hidden [Void]StartMining() { 
        If ($this.Arguments -and (Test-Json $this.Arguments -ErrorAction Ignore)) { $this.CreateConfigFiles() }

        # Stat just got removed (Miner.Activated < 1, set by API)
        If ($this.Activated -le 0) { $this.Activated = 0 }
        If ($this.Benchmark -or $this.MeasurePowerConsumption) { $this.Data = @() }

        $this.ContinousCycle = 0
        $this.DataSampleTimestamp = [DateTime]0
        $this.ValidDataSampleTimestamp = [DateTime]0

        $this.Hashrates_Live = @($this.Workers.ForEach({ [Double]::NaN }))
        $this.PowerConsumption_Live = [Double]::NaN

        If ($this.Status -eq [MinerStatus]::DryRun) { 
            Write-Message -Level Info "Dry run for miner '$($this.Info)'..."
            $this.StatusInfo = "$($this.Info) (Dry run)"
            $this.SubStatus = "dryrun"
            $this.StatStart = $this.BeginTime = [DateTime]::Now.ToUniversalTime()
        }
        Else { 
            Write-Message -Level Info "Starting miner '$($this.Info)'..."
            $this.StatusInfo = "$($this.Info) is getting ready"
            $this.SubStatus = "starting"
        }

        Write-Message -Level Verbose $this.CommandLine

        # Log switching information to .\Logs\SwitchingLog.csv
        [PSCustomObject]@{ 
            DateTime                = (Get-Date -Format o)
            Action                  = If ($this.Status -eq [MinerStatus]::DryRun) { "DryRun" } Else { "Launched" }
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

        If ($this.Status -ne [MinerStatus]::DryRun) { 

            $this.ProcessJob = Invoke-CreateProcess -ErrorVariable $null -InformationVariable $null -OutVariable $null -WarningVariable $null -BinaryPath "$PWD\$($this.Path)" -ArgumentList $this.GetCommandLineParameters() -WorkingDirectory (Split-Path "$PWD\$($this.Path)") -WindowStyle $this.WindowStyle -EnvBlock $this.EnvVars -JobName $this.Name -LogFile $this.LogFile -Status $this.StatusInfo

            Try { 
                # Sometimes the process cannot be found instantly
                $Loops = 100
                Do { 
                    Start-Sleep -Milliseconds 50
                    If ($this.ProcessId = ($this.ProcessJob | Receive-Job -ErrorAction Ignore).MinerProcessId) { 
                        $this.Activated ++
                        $this.DataSampleTimestamp = [DateTime]0
                        $this.Status = [MinerStatus]::Running
                        $this.StatStart = $this.BeginTime = [DateTime]::Now.ToUniversalTime()
                        $this.Process = Get-Process -Id $this.ProcessId -ErrorAction SilentlyContinue
                        $this.StartDataReader()
                        Break
                    }
                    Else { 
                        Start-Sleep 0
                    }
                    $Loops --
                    # Start-Sleep -Milliseconds 50
                } While ($Loops -gt 0)
                Remove-Variable Loops
            }
            Catch { 
                Start-Sleep 0
            }
        }

        $this.WorkersRunning = $this.Workers
    }

    hidden [Void]StopMining() { 
        If ([MinerStatus]::Running, [MinerStatus]::Disabled, [MinerStatus]::DryRun -contains $this.Status) { 
            Write-Message -Level Info "Stopping miner '$($this.Info)'..."
            $this.StatusInfo = "$($this.Info) is stopping..."
        }

        If ($this.ProcessJob) { 
            If ($this.ProcessJob.State -eq "Running") { $this.ProcessJob | Stop-Job -ErrorAction Ignore }
            Try { $this.Active += $this.ProcessJob.PSEndTime - $this.ProcessJob.PSBeginTime } Catch { }
            # Jobs are getting removed in core loop (removing here immediately after stopping process may take several seconds)
            $this.ProcessJob = $null
        }

        $this.StopDataReader()

        $this.EndTime = [DateTime]::Now.ToUniversalTime()

        If ($this.Process.Id) { 
            If ($this.Process.Parent.Id) { Stop-Process -Id $this.Process.Parent.Id -Force -ErrorAction Ignore | Out-Null }
            Stop-Process -Id $this.Process.Id -Force -ErrorAction Ignore | Out-Null
            # Some miners, e.g. HellMiner spawn child process(es) that may need separate killing
            (Get-CimInstance win32_process -Filter "ParentProcessId = $($this.Process.Id)").ForEach({ Stop-Process -Id $_.ProcessId -Force -ErrorAction Ignore | Out-Null })
        }
        $this.Process = $null

        $this.StatusInfo = If ($this.Status -eq [MinerStatus]::Failed) { $this.StatusInfo.Replace("'$($this.Name)' ", "") -replace ".+stopped. " -replace ".+sample.*\) " } Else { "" }

        # Log switching information to .\Logs\SwitchingLog
        [PSCustomObject]@{ 
            DateTime                = (Get-Date -Format o)
            Action                  = If ($this.Status -eq [MinerStatus]::Failed) { "Failed" } Else { "Stopped" }
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
            LastDataSample          = If ($this.Data.Count -ge 1) { $this.Data.Item | Select-Object -Last 1 | ConvertTo-Json -Compress } Else { "" }
            MeasurePowerConsumption = $this.MeasurePowerConsumption
            Pools                   = ($this.WorkersRunning.Pool.Name | Select-Object -Unique) -join " "
            PowerConsumption        = "$($this.PowerConsumption.ToString("N2"))W"
            Profit                  = $this.Profit
            Profit_Bias             = $this.Profit_Bias
            Reason                  = $this.StatusInfo
            Type                    = $this.Type
        } | Export-Csv -Path ".\Logs\SwitchingLog.csv" -Append -NoTypeInformation

        If ($this.Status -eq [MinerStatus]::Failed) { 
            $this.StatusInfo = "Failed: Miner $($this.StatusInfo)"
            $this.SubStatus = "failed"
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
            $this.Earnings = $this.Earnings_Accuracy = $this.Earnings_Bias = $this.PowerCost = $this.PowerConsumption = $this.PowerConsumption_Live = $this.Profit = $this.Profit_Bias =[Double]::NaN
            $this.Hashrates_Live = @($this.WorkersRunning.ForEach({ [Double]::NaN }))
        }
        Else {  
            $this.Status = [MinerStatus]::Idle
            $this.StatusInfo = "Idle"
            $this.SubStatus = $this.Status
        }
        $this.WorkersRunning = [Worker[]]@()
    }

    [MinerStatus]GetStatus() { 
        If ($this.ProcessJob.State -eq "Running" -and $this.ProcessId -and (Get-Process -Id $this.ProcessId -ErrorAction SilentlyContinue)) { 
            # Use ProcessName, some crashed miners are dead, but may still be found by their processId
            Return [MinerStatus]::Running
        }
        ElseIf ($this.Status -eq [MinerStatus]::Running) { 
            Return [MinerStatus]::Failed
        }
        Else { 
            Return $this.Status
        }
    }

    [Void]SetStatus([MinerStatus]$Status) { 
        Switch ($Status) { 
            "DryRun" { 
                $this.Status = [MinerStatus]::DryRun
                $this.StartMining()
                Break
            }
            "Idle" { 
                $this.StopMining()
                Break
            }
            "Running" { 
                $this.StartMining()
                Break
            }
            Default { 
                $this.Status = [MinerStatus]::Failed
                $this.StopMining()
            }
        }
    }

    [DateTime]GetActiveLast() { 
        If ($this.Process.BeginTime -and $this.Process.EndTime) { 
            Return $this.Process.EndTime
        }
        ElseIf ($this.Process.BeginTime) { 
            Return [DateTime]::Now.ToUniversalTime()
        }
        ElseIf ($this.EndTime) { 
            Return $this.EndTime
        }
        Else { 
            Return [DateTime]::MinValue
        }
    }

    [TimeSpan]GetActiveTime() { 
        If ($this.Process.BeginTime -and $this.Process.EndTime) { 
            Return $this.Active + $this.Process.EndTime - $this.Process.BeginTime
        }
        ElseIf ($this.Process.BeginTime) { 
            Return $this.Active + [DateTime]::Now - $this.Process.BeginTime
        }
        Else { 
            Return $this.Active
        }
    }

    [Double]GetPowerConsumption() { 
        $TotalPowerConsumption = [Double]0

        # Read power consumption from HwINFO64 reg key, otherwise use hardconfigured value
        $RegistryData = Get-ItemProperty "HKCU:\Software\HWiNFO64\VSB"
        ForEach ($Device in $this.Devices) { 
            If ($RegistryEntry = $RegistryData.PSObject.Properties.Where({ $_.Name -like "Label*" -and $_.Value -split " " -contains $Device.Name })) { 
                $TotalPowerConsumption += [Double](($RegistryData.($RegistryEntry.Name -replace "Label", "Value") -split " ")[0])
            }
            Else { 
                $TotalPowerConsumption += [Double]$Device.ConfiguredPowerConsumption
            }
        }
        Return $TotalPowerConsumption
    }

    [Double[]]CollectHashrate([String]$Algorithm = [String]$this.Algorithm, [Boolean]$Safe = $this.Benchmark) { 
        # Returns an array of two values (safe, unsafe)
        $HashrateAverage = [Double]0
        $HashrateVariance = [Double]0

        $HashrateSamples = @($this.Data.Where({ $_.Hashrate.$Algorithm })) # Do not use 0 valued samples

        $HashrateAverage = ($HashrateSamples.Hashrate.$Algorithm | Measure-Object -Average).Average
        $HashrateVariance = $HashrateSamples.Hashrate.$Algorithm | Measure-Object -Average -Minimum -Maximum | ForEach-Object { If ($_.Average) { ($_.Maximum - $_.Minimum) / $_.Average } }

        If ($Safe) { 
            If ($HashrateSamples.Count -lt 10 -or $HashrateVariance -gt 0.1) { 
                Return 0, $HashrateAverage
            }
            Else { 
                Return ($HashrateAverage * (1 + $HashrateVariance / 2)), $HashrateAverage
            }
        }
        Else { 
            Return $HashrateAverage, $HashrateAverage
        }
    }

    [Double[]]CollectPowerConsumption([Boolean]$Safe = $this.MeasurePowerConsumption) { 
        # Returns an array of two values (safe, unsafe)
        $PowerConsumptionAverage = [Double]0
        $PowerConsumptionVariance = [Double]0

        $PowerConsumptionSamples = @($this.Data.Where({ $_.PowerConsumption })) # Do not use 0 valued samples

        $PowerConsumptionAverage = ($PowerConsumptionSamples.PowerConsumption | Measure-Object -Average).Average
        $PowerConsumptionVariance = $PowerConsumptionSamples.Powerusage | Measure-Object -Average -Minimum -Maximum | ForEach-Object { If ($_.Average) { ($_.Maximum - $_.Minimum) / $_.Average } }

        If ($Safe) { 
            If ($PowerConsumptionSamples.Count -lt 10 -or $PowerConsumptionVariance -gt 0.1) { 
                Return 0, $PowerConsumptionAverage
            }
            Else { 
                Return ($PowerConsumptionAverage * (1 + $PowerConsumptionVariance / 2)), $PowerConsumptionAverage
            }
        }
        Else { 
            Return $PowerConsumptionAverage, $PowerConsumptionAverage
        }
    }

    [Void]Refresh([Double]$PowerCostBTCperW, [Hashtable]$ConfigRunning) { 
        $this.Best = $false
        $this.MinDataSample = $ConfigRunning.MinDataSample
        $this.Prioritize = $this.Workers.Pool.Prioritize -contains $true
        $this.ProcessPriority = $ConfigRunning."$($this.Type)MinerProcessPriority"
        If ($this.ReadPowerConsumption -ne $this.Devices.ReadPowerConsumption -notcontains $false) { $this.Restart = $true }
        $this.ReadPowerConsumption = $this.Devices.ReadPowerConsumption -notcontains $false

        $this.Workers.ForEach(
            { 
                If ($Stat = Get-Stat -Name "$($this.Name)_$($_.Pool.Algorithm)_Hashrate") { 
                    $_.Disabled = $Stat.Disabled
                    $_.Hashrate = $Stat.Hour
                    $Factor = $_.Hashrate * (1 - $_.Fee - $_.Pool.Fee)
                    $_.Earnings = $_.Pool.Price * $Factor
                    $_.Earnings_Accuracy = $_.Pool.Accuracy
                    $_.Earnings_Bias = $_.Pool.Price_Bias * $Factor
                    $_.TotalMiningDuration = $Stat.Duration
                    $_.Updated = $Stat.Updated
                }
                Else { 
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

        If ($this.Benchmark = [Boolean]($this.Workers.Hashrate -like [Double]::NaN)) { 
            $this.Earnings = [Double]::NaN
            $this.Earnings_Accuracy = [Double]::NaN
            $this.Earnings_Bias = [Double]::NaN
        }
        Else { 
            $this.Earnings = 0
            $this.Earnings_Accuracy = 0
            $this.Earnings_Bias = 0
            $this.Workers.ForEach({ 
                $this.Earnings += $_.Earnings
                $this.Earnings_Bias += $_.Earnings_Bias
            })
            If ($this.Earnings) { $this.Workers.ForEach({ $this.Earnings_Accuracy += $_.Earnings_Accuracy * $_.Earnings / $this.Earnings }) }
        }

        If ($Stat = Get-Stat -Name "$($this.Name)_PowerConsumption") { 
            $this.PowerConsumption = $Stat.Week
            $this.PowerCost = $this.PowerConsumption * $PowerCostBTCperW
            $this.Profit = $this.Earnings - $this.PowerCost
            $this.Profit_Bias = $this.Earnings_Bias - $this.PowerCost
            $this.MeasurePowerConsumption = $false
        }
        Else { 
            $this.PowerConsumption = [Double]::NaN
            $this.PowerCost = [Double]::NaN
            $this.Profit = [Double]::NaN
            $this.Profit_Bias = [Double]::NaN
        }

        $this.Disabled = $this.Workers.Disabled -contains $true
        $this.TotalMiningDuration = ($this.Workers.TotalMiningDuration | Measure-Object -Minimum).Minimum
        $this.LastUsed = ($this.Workers.Updated | Measure-Object -Minimum).Minimum
        $this.Updated = ($this.Workers.Pool.Updated | Measure-Object -Minimum).Minimum
        $this.WindowStyle = If ($ConfigRunning.MinerWindowStyleNormalWhenBenchmarking -and $this.Benchmark) { "normal" } Else { $ConfigRunning.MinerWindowStyle }
    }
}

Function Invoke-CreateProcess { 
    # Based on https://github.com/FuzzySecurity/PowerShell-Suite/blob/master/Invoke-CreateProcess.ps1

    Param (
        [Parameter(Mandatory = $true)]
        [String]$BinaryPath,
        [Parameter(Mandatory = $false)]
        [String]$ArgumentList = "",
        [Parameter(Mandatory = $false)]
        [String]$WorkingDirectory = "",
        [Parameter(Mandatory = $false)]
        [String[]]$EnvBlock,
        [Parameter(Mandatory = $false)]
        [String]$CreationFlags = 0x00000010, # CREATE_NEW_CONSOLE
        [Parameter(Mandatory = $false)]
        [String]$WindowStyle = "minimized",
        [Parameter(Mandatory = $false)]
        [String]$StartF = 0x00003001, # STARTF_USESHOWWINDOW, STARTF_TITLEISAPPID, STARTF_PREVENTPINNING
        [Parameter(Mandatory = $false)]
        [String]$JobName,
        [Parameter(Mandatory = $false)]
        [String]$LogFile,
        [Parameter(Mandatory = $false)]
        [String]$StatusInfo
    )

    # Cannot use Start-ThreadJob, $ControllerProcess.WaitForExit(250) would not work and miners remain running
    Start-Job  -ErrorVariable $null -InformationVariable $null -OutVariable $null -WarningVariable $null -Name $JobName -ArgumentList $BinaryPath, $ArgumentList, $WorkingDirectory, $EnvBlock, $CreationFlags, $WindowStyle, $StartF, $PID, $JobName, $StatusInfo { 
        Param ($BinaryPath, $ArgumentList, $WorkingDirectory, $EnvBlock, $CreationFlags, $WindowStyle, $StartF, $ControllerProcessID, $JobName, $StatusInfo)

        $ControllerProcess = Get-Process -Id $ControllerProcessID
        If ($null -eq $ControllerProcess) { Return }

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

        $ShowWindow = Switch ($WindowStyle) { 
            "hidden" { "0x0000"; Break } # SW_HIDE
            "normal" { "0x0001"; Break } # SW_SHOWNORMAL
            Default  { "0x0007" } # SW_SHOWMINNOACTIVE
        }

        # Set local environment
        New-Item -Path "Env:UGMINER_JOBNAME" -Value $JobName -Force | Out-Null
        ($EnvBlock | Select-Object).ForEach({ New-Item -Path "Env:$(($_ -split "=")[0])" -Value "$(($_ -split "=")[1])" -Force | Out-Null })

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
        If (-not $WorkingDirectory) { $WorkingDirectory = [IntPtr]::Zero }

        # ProcessInfo struct
        $ProcessInfo = [PROCESS_INFORMATION]::new()

        # Force to use conhost, sometimes miners would get started using windows terminal
        $ConHost = "$($ENV:SystemRoot)\System32\conhost.exe"

        # Call CreateProcess
        [Void][Kernel32]::CreateProcess($ConHost, "$ConHost $BinaryPath$ArgumentList", [ref]$SecAttr, [ref]$SecAttr, $false, $CreationFlags, [IntPtr]::Zero, $WorkingDirectory, [ref]$StartupInfo, [ref]$ProcessInfo)

        # Timing issue, some processes are not immediately available on fast computers
        $Loops = 100
        Do { 
            If ($ConhostProcess = Get-Process -Id $ProcessInfo.dwProcessId -ErrorAction Ignore) { Break }
            Start-Sleep -Milliseconds 50
            $Loops --
        } While ($Loops -gt 0)
        Do { 
            If ($MinerProcess = (Get-CimInstance win32_process -Filter "ParentProcessId = $($ProcessInfo.dwProcessId)")) { Break }
            Start-Sleep -Milliseconds 50
            $Loops --
        } While ($Loops -gt 0)
        $MinerProcessId = $MinerProcess.ProcessId

        If ($null -eq $MinerProcess.Count) { 
            [PSCustomObject]@{ 
                ConhostProcessId = $ProcessInfo.dwProcessId
                MinerProcessId = $null
            }
            Return 
        }

        [PSCustomObject]@{ 
            ConhostProcessId = $ProcessInfo.dwProcessId
            MinerProcessId = $MinerProcessId
        }

        $ConhostProcess.Handle | Out-Null
        $ControllerProcess.Handle | Out-Null
        $MinerProcess.Handle | Out-Null
        $ChildProcesses.ForEach({ $_.Handle | Out-Null })

        Do { 
            If ($ControllerProcess.WaitForExit(250)) { 
                # Kill process in bottum up order
                # Some miners, e.g. HellMiner spawn child process(es) that may need separate killing
                (Get-CimInstance win32_process -Filter "ParentProcessId = $MinerProcessId").ForEach({ Stop-Process -Id $_.ProcessId -Force -ErrorAction Ignore | Out-Null })
                Stop-Process -Id $MinerProcessId -Force -ErrorAction Ignore | Out-Null
                Stop-Process -Id $ProcessInfo.dwProcessId -Force -ErrorAction Ignore | Out-Null
                $MinerProcess = $null
                $ControllerProcess = $null
            }
        } While ($ControllerProcess.HasExited -eq $false)
    }
}

Function Start-Core { 

    Try { 
        If (-not $Global:CoreRunspace) { 
            $Global:CoreRunspace = [RunspaceFactory]::CreateRunspace()
            $Global:CoreRunspace.ApartmentState = "STA"
            $Global:CoreRunspace.Name = "Core"
            $Global:CoreRunspace.ThreadOptions = "ReuseThread"
            $Global:CoreRunspace.Open()

            $Global:CoreRunspace.SessionStateProxy.SetVariable("Config", $Config)
            $Global:CoreRunspace.SessionStateProxy.SetVariable("Session", $Session)
            $Global:CoreRunspace.SessionStateProxy.SetVariable("Stats", $Stats)
            [Void]$Global:CoreRunspace.SessionStateProxy.Path.SetLocation($Session.MainPath)

            $PowerShell = [PowerShell]::Create()
            $PowerShell.Runspace = $Global:CoreRunspace
            [Void]$Powershell.AddScript("$($Session.MainPath)\Includes\Core.ps1")
            $Global:CoreRunspace | Add-Member PowerShell $PowerShell
            
            # Remove stats that have been deleted from disk
            Try { 
                If ($StatFiles = (Get-ChildItem -Path "Stats" -File).BaseName) { 
                    If ($Stats.psBase.Keys) { 
                        (Compare-Object -PassThru $StatFiles $Stats.psBase.Keys).Where({ $_.SideIndicator -eq "=>" }).ForEach(
                            { 
                                # Remove stat if deleted on disk
                                $Stats.Remove($_)
                            }
                        )
                    }
                }
            }
            Catch { }
            Remove-Variable StatFiles -ErrorAction Ignore
        }

        If ($Global:CoreRunspace.Job.IsCompleted -ne $false) { 
            $Global:CoreRunspace | Add-Member Job ($Global:CoreRunspace.PowerShell.BeginInvoke()) -Force
            $Global:CoreRunspace | Add-Member StartTime ([DateTime]::Now.ToUniversalTime()) -Force
        }
    }
    Catch { 
        Write-Message -Level Error "Failed to start core [$($Error[0])]."
    }
}

Function Clear-MinerData { 
        
    Param (
        [Parameter(Mandatory = $false)]
        [Boolean]$KeepMiners = $false
    )

    # Stop all miners
    ForEach ($Miner in $Session.Miners.Where({ $_.ProcessJob -or $_.Status -eq [MinerStatus]::DryRun })) { 
        $Miner.SetStatus([MinerStatus]::Idle)
        $Session.Devices.Where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
    }
    Remove-Variable Miner -ErrorAction Ignore

    $Session.WatchdogTimers = [System.Collections.Generic.List[PSCustomObject]]::new()

    $Session.Miners.ForEach({ $_.Dispose() })
    If (-not $KeepMiners) { $Session.Miners = [Miner[]]@() }
    $Session.MinersBenchmarkingOrMeasuring = [Miner[]]@()
    $Session.MinersBest = [Miner[]]@()
    $Session.MinersBestPerDevice = [Miner[]]@()
    $Session.MinersFailed = [Miner[]]@()
    $Session.MinersMissingBinary = [Miner[]]@()
    $Session.MinerMissingFirewallRule = [Miner[]]@()
    $Session.MinersMissingPrerequisite = [Miner[]]@()
    $Session.MinersOptimal = [Miner[]]@()
    $Session.MinersRunning = [Miner[]]@()
    $Session.Remove("MinersUpdatedTimestamp")

    $Session.MiningEarnings = [Double]0
    $Session.MiningPowerConsumption = [Double]0
    $Session.MiningPowerCost = [Double]0
    $Session.MiningProfit = [Double]0
}

Function Clear-PoolData { 

    $Session.Pools.ForEach({ $_.Dispose() })
    $Session.Pools = [Pool[]]@()
    $Session.PoolsAdded = [Pool[]]@()
    $Session.PoolsExpired = [Pool[]]@()
    $Session.PoolsNew = [Pool[]]@()
    $Session.PoolsUpdated = [Pool[]]@()
    $Session.Remove("PoolsUpdatedTimestamp")
}

Function Stop-Core { 

    If ($Global:CoreRunspace.Job.IsCompleted -eq $false) { 

        $Global:CoreRunspace.PowerShell.Stop()
        $Session.Remove("EndCycleTime")
        If ($Session.Timer) { Write-Message -Level Info "Ending cycle." }

        $Session.Remove("Timer")
        $Global:CoreRunspace.PSObject.Properties.Remove("StartTime")
    }

    Clear-MinerData

    If ($Session.NewMiningStatus -eq "Idle") { 
        Clear-PoolData
    }
    Else { 
        # Stop all miners
        ForEach ($Miner in $Session.Miners.Where({ $_.ProcessJob -or $_.Status -eq [MinerStatus]::DryRun })) { 
            $Miner.SetStatus([MinerStatus]::Idle)
            $Session.Devices.Where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
        }
        Remove-Variable Miner -ErrorAction Ignore
        $Session.MinersBest = [Miner[]]@()
        $Session.MinersBestPerDevice = [Miner[]]@()
        $Session.MiningEarnings = [Double]0
        $Session.MiningPowerConsumption = [Double]0
        $Session.MiningPowerCost = [Double]0
        $Session.MiningProfit = [Double]0
    }

    If ($Global:CoreRunspace) { 
        $Global:CoreRunspace.PSObject.Properties.Remove("Job")

        # Must close runspace after miners were stopped, otherwise methods don't work any longer
        $Global:CoreRunspace.PowerShell.Dispose()
        $Global:CoreRunspace.PowerShell = $null
        $Global:CoreRunspace.Close()
        $Global:CoreRunspace.Dispose()

        Remove-Variable CoreRunspace -Scope Global

        [System.GC]::Collect()
    }
}

Function Start-Brain { 

    Param (
        [Parameter(Mandatory = $false)]
        [String[]]$Name
    )

    If (Test-Path -LiteralPath ".\Brains" -PathType Container) { 

        # Starts Brains if necessary
        $BrainsStarted = @()
        $Name.Where({ $Session.ConfigRunning.PoolsConfig.$_.BrainConfig -and -not $Session.Brains.$_ }).ForEach(
            { 
                $BrainScript = ".\Brains\$($_).ps1"
                If (Test-Path -LiteralPath $BrainScript -PathType Leaf) { 
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
        If ($BrainsStarted.Count -gt 0) {  Write-Message -Level Info "Pool brain backgound job$(If ($BrainsStarted.Count -gt 1) { "s" }) for $($BrainsStarted -join ", " -replace ",([^,]*)$", " &`$1") started." }
    }
    Else { 
        Write-Message -Level Error "Failed to start Pool brain backgound jobs. Directory '.\Brains' is missing."
    }
}

Function Stop-Brain { 

    Param (
        [Parameter(Mandatory = $false)]
        [String[]]$Name = $Session.Brains.Keys
    )

    If ($Name) { 

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
        If ($BrainsStopped.Count -gt 0) { 
            Write-Message -Level Info "Pool brain backgound job$(If ($BrainsStopped.Count -gt 1) { "s" }) for $(($BrainsStopped | Sort-Object) -join ", " -replace ",([^,]*)$", " &`$1") stopped."
            [System.GC]::Collect()
        }
    }
}

Function Start-BalancesTracker { 

    Try { 
        If (Test-Path -LiteralPath ".\Balances" -PathType Container) { 
            If (-not $Global:BalancesTrackerRunspace) { 
                $Global:BalancesTrackerRunspace = [RunspaceFactory]::CreateRunspace()
                $Global:BalancesTrackerRunspace.ApartmentState = "STA"
                $Global:BalancesTrackerRunspace.Name = "BalancesTracker"
                $Global:BalancesTrackerRunspace.ThreadOptions = "ReuseThread"
                $Global:BalancesTrackerRunspace.Open()

                $Global:BalancesTrackerRunspace.SessionStateProxy.SetVariable("Config", $Config)
                $Global:BalancesTrackerRunspace.SessionStateProxy.SetVariable("Session", $Session)
                $Global:BalancesTrackerRunspace.SessionStateProxy.SetVariable("Stats", $Stats)
                [Void]$Global:BalancesTrackerRunspace.SessionStateProxy.Path.SetLocation($Session.MainPath)

                $PowerShell = [PowerShell]::Create()
                $PowerShell.Runspace = $Global:BalancesTrackerRunspace
                [Void]$Powershell.AddScript("$($Session.MainPath)\Includes\BalancesTracker.ps1")
                $Global:BalancesTrackerRunspace | Add-Member PowerShell $PowerShell
            }
                If ($Global:BalancesTrackerRunspace.Job.IsCompleted -ne $false) { 
                    $Global:BalancesTrackerRunspace | Add-Member Job ($Global:BalancesTrackerRunspace.PowerShell.BeginInvoke()) -Force
                    $Global:BalancesTrackerRunspace | Add-Member StartTime ([DateTime]::Now.ToUniversalTime()) -Force

                    Write-Message -Level Info "Balances tracker background process started."
                }
            }
        Else { 
            Write-Message -Level Error "Failed to start Balances tracker. Directory '.\Balances' is missing."
        }
    }
    Catch { 
        Write-Message -Level Error "Failed to start Balances tracker [$($Error[0])]."
    }
}

Function Stop-BalancesTracker { 

    If ($Global:BalancesTrackerRunspace.Job.IsCompleted -eq $false) { 
        $Global:BalancesTrackerRunspace.PowerShell.Stop()
        $Global:BalancesTrackerRunspace.PSObject.Properties.Remove("StartTime")

        $Session.BalancesTrackerRunning = $false

        Write-Message -Level Info "Balances tracker background process stopped."
    }

    If ($Global:BalancesTrackerRunspace) { 

        $Global:BalancesTrackerRunspace.PSObject.Properties.Remove("Job")

        $Global:BalancesTrackerRunspace.PowerShell.Dispose()
        $Global:BalancesTrackerRunspace.PowerShell = $null
        $Global:BalancesTrackerRunspace.Close()
        $Global:BalancesTrackerRunspace.Dispose()

        Remove-Variable BalancesTrackerRunspace -Scope Global

        [System.GC]::Collect()
    }
}

Function Get-CoinList { 
    $Data = (Invoke-RestMethod -Uri "https://min-api.cryptocompare.com/data/all/coinlist" -TimeoutSec 5 -ErrorAction Ignore).Data
    $CoinList = [Ordered]@{ }
    ($Data.PSObject.Properties.Name | Sort-Object).ForEach(
        { $CoinList.$_ = $Data.$_.CoinName }
    )
    $CoinList | ConvertTo-Json > t.txt
}

Function Get-Rate { 

    $RatesCacheFileName = "$($Session.MainPath)\Cache\Rates.json"

    # Use stored currencies from last run
    If (-not $Session.BalancesCurrencies -and $Session.ConfigRunning.BalancesTrackerPollInterval) { $Session.BalancesCurrencies = @($Session.Rates.PSObject.Properties.Name -creplace "^m") }

    $Session.AllCurrencies = @(@($Session.ConfigRunning.FIATcurrency) + @($Session.ConfigRunning.Wallets.psBase.Keys) + @($Session.PoolData.Keys.ForEach({ $Session.PoolData.$_.GuaranteedPayoutCurrencies })) + @($Session.ConfigRunning.ExtraCurrencies) + @($Session.BalancesCurrencies) -replace "mBTC", "BTC") | Where-Object { $_ } | Sort-Object -Unique

    Try { 
        $TSymBatches = @()
        $TSyms = "BTC"
        $Session.AllCurrencies.Where({ "BTC", "INVALID" -notcontains $_ }).ForEach(
            { 
                If (($TSyms.Length + $_.Length) -lt 99) { 
                    $TSyms = "$TSyms,$($_)"
                }
                Else { 
                    $TSymBatches += $TSyms
                    $TSyms = $_
                }
            }
        )
        $TSymBatches += $TSyms

        $Rates = [PSCustomObject]@{ BTC = [PSCustomObject]@{ } }
        $TSymBatches.ForEach(
            { 
                $Response = Invoke-RestMethod -Uri "https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC&tsyms=$($_)$(If ($Session.ConfigRunning.CryptoCompareAPIKeyParam) { "&api_key=$($Session.ConfigRunning.CryptoCompareAPIKeyParam)" })&extraParams=$($Session.Branding.BrandWebSite) Version $($Session.Branding.Version)" -TimeoutSec 5 -ErrorAction Ignore
                If ($Response.BTC) { 
                    $Response.BTC.ForEach(
                        { 
                            $_.PSObject.Properties.ForEach({ $Rates.BTC | Add-Member @{ "$($_.Name)" = $_.Value } -Force })
                        }
                    )
                }
                Else { 
                    If ($Response.Message -eq "You are over your rate limit please upgrade your account!") { 
                        Write-Message -Level Error "min-api.cryptocompare.com API rate exceeded. You need to register an account with cryptocompare.com and add the API key as 'CryptoCompareAPIKeyParam' to the configuration file '$($Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'."
                    }
                }
            }
        )

        If ($Currencies = $Rates.BTC.PSObject.Properties.Name) { 
            $Currencies.Where({ $_ -ne "BTC" }).ForEach(
                { 
                    $Currency = $_
                    $Rates | Add-Member $Currency $Rates.BTC.PSObject.Copy() -Force
                    $Rates.$Currency.PSObject.Properties.Name.ForEach(
                        { 
                            $Rates.$Currency | Add-Member $_ ([Double]($Rates.BTC.$_ / $Rates.BTC.$Currency)) -Force
                        }
                    )
                }
            )

            # Add mBTC
            If ($Session.ConfigRunning.UsemBTC) { 
                $Currencies.ForEach(
                    { 
                        $Currency = $_
                        $mCurrency = "m$Currency"
                        $Rates | Add-Member $mCurrency $Rates.$Currency.PSObject.Copy() -Force
                        $Rates.$mCurrency.PSOBject.Properties.Name.ForEach({ $Rates.$mCurrency | Add-Member $_ ([Double]$Rates.$Currency.$_ / 1000) -Force })
                    }
                )
                $Rates.PSOBject.Properties.Name.ForEach(
                    { 
                        $Currency = $_
                        $Rates.PSOBject.Properties.Name.Where({ $Currencies -contains $_ }).ForEach(
                            { 
                                $mCurrency = "m$($_)"
                                $Rates.$Currency | Add-Member $mCurrency ([Double]$Rates.$Currency.$_ * 1000) -Force
                            }
                        )
                    }
                )
            }
            Write-Message -Level Verbose "Loaded currency exchange rates from 'min-api.cryptocompare.com'.$(If ($Session.RatesMissingCurrencies = Compare-Object @($Currencies | Select-Object) @($Session.AllCurrencies | Select-Object) -PassThru) { " API does not provide rates for $($Session.RatesMissingCurrencies -join ", " -replace ",([^,]*)$", " &`$1"). $($Session.Branding.ProductLabel) cannot calculate the FIAT or BTC value for $(If ($Session.RatesMissingCurrencies.Count -ne 1) { "these currencies" } Else { "this currency" })." })"
            $Session.Rates = $Rates
            $Session.RatesUpdated = [DateTime]::Now.ToUniversalTime()

            $Session.Rates | ConvertTo-Json -Depth 5 | Out-File -LiteralPath $RatesCacheFileName -Force -ErrorAction Ignore
        }
    }
    Catch { 
        # Read exchange rates from min-api.cryptocompare.com, use stored data as fallback
        $RatesCache = ([System.IO.File]::ReadAllLines($RatesCacheFileName) | ConvertFrom-Json -ErrorAction Ignore)
        If ($RatesCache.PSObject.Properties.Name) { 
            $Session.Rates = $RatesCache
            $Session.RatesUpdated = [DateTime]::Now.ToUniversalTime().AddMinutes(-14) # Trigger next attempt in 1 minute
            Write-Message -Level Warn "Could not load exchange rates from 'min-api.cryptocompare.com'. Using cached data from $((Get-Item -Path $RatesCacheFileName).LastWriteTime)."
        }
        Else { 
            Write-Message -Level Warn "Could not load exchange rates from 'min-api.cryptocompare.com'."
        }
    }
}

Function Write-Message { 

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String]$Message,
        [Parameter(Mandatory = $false)]
        [String]$Level = "Info",
        [Parameter(Mandatory = $false)]
        [Boolean]$Console = $true
    )

    $Message = $Message -replace "(?:<br>)+|(?:&ensp;)+", " "

    # Make sure we are in main script
    If ($Console -and $Host.Name -match "Visual Studio Code Host|ConsoleHost" -and (-not $Session.ConfigRunning.Keys.Count -or $Session.ConfigRunning.LogLevel -contains $Level)) { 
        # Write to console
        Switch ($Level) { 
            "Debug"   { Write-Host $Message -ForegroundColor "Blue" -NoNewLine; Break }
            "Error"   { Write-Host $Message -ForegroundColor "Red" -NoNewLine; Break }
            "Info"    { Write-Host $Message -ForegroundColor "White" -NoNewLine; Break }
            "MemDbg"  { Write-Host $Message -ForegroundColor "Cyan" -NoNewLine; Break }
            "Verbose" { Write-Host $Message -ForegroundColor "Yello" -NoNewLine; Break }
            "Warn"    { Write-Host $Message -ForegroundColor "Magenta" -NoNewLine; Break }
        }
        $Session.CursorPosition = $Host.UI.RawUI.CursorPosition
        Write-Host ""
    }

    Switch ($Level) { 
        "Debug"   { $Message = "[DEBUG  ] $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") $Message"; Break }
        "Error"   { $Message = "[ERROR  ] $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") $Message"; Break }
        "Info"    { $Message = "[INFO   ] $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") $Message"; Break }
        "MemDbg"  { $Message = "[MEMDBG ] $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") $Message"; Break }
        "Verbose" { $Message = "[VERBOSE] $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") $Message"; Break }
        "Warn"    { $Message = "[WARN   ] $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") $Message"; Break }
    }

    If ($Session.TextBoxSystemLog) { 
        # Ignore error when legacy GUI gets closed
        Try { 
            If (-not $Session.ConfigRunning.Keys.Count -or $Session.ConfigRunning.LogLevel -contains $Level) { 
                $SelectionLength = $Session.TextBoxSystemLog.SelectionLength
                $SelectionStart = $Session.TextBoxSystemLog.SelectionStart
                $TextLength = $Session.TextBoxSystemLog.TextLength

                # Keep only 200 lines, more lines impact performance
                If ($Session.TextBoxSystemLog.Lines.Count -gt 250) { $Session.TextBoxSystemLog.Lines = $Session.TextBoxSystemLog.Lines | Select-Object -Last 200 }

                $SelectionStart += ($Session.TextBoxSystemLog.TextLength - $TextLength)
                If ($SelectionLength -and $SelectionStart -ge 0) { 
                    $Session.TextBoxSystemLog.Lines += $Message
                    $Session.TextBoxSystemLog.Select($SelectionStart, $SelectionLength)
                    $Session.TextBoxSystemLog.ScrollToCaret()
                }
                Else { 
                    $Session.TextBoxSystemLog.AppendText("`r`n$Message")
                }
            }
        }
        Catch { }
    }

    If (-not $Session.ConfigRunning.Keys.Count -or $Session.ConfigRunning.LogLevel -contains $Level) { 

        $Session.LogFile = "$($Session.MainPath)\Logs\$($Session.Branding.ProductLabel)_$(Get-Date -Format "yyyy-MM-dd").log"

        # Get mutex. Mutexes are shared across all threads and processes.
        # This lets us ensure only one thread is trying to write to the file at a time.
        $Mutex = [System.Threading.Mutex]::new($false, "$($Session.Branding.ProductLabel)_Write-Message")

        # Attempt to aquire mutex, waiting up to 1 second if necessary
        If ($Mutex.WaitOne(1000)) { 
            $Message | Out-File -LiteralPath $Session.LogFile -Append -ErrorAction Ignore
            $Mutex.ReleaseMutex()
        }
    }
}

Function Write-MonitoringData { 

    # Updates a remote monitoring server, sending this worker's data and pulling data about other workers

    # Skip If server and user aren't filled out
    If (-not $Session.ConfigRunning.MonitoringServer) { Return }
    If (-not $Session.ConfigRunning.MonitoringUser) { Return }

    # Build object with just the data we need to send, and make sure to use relative paths so we don't accidentally
    # reveal someone's windows username or other system information they might not want sent
    # For the ones that can be an array, comma separate them
    $Data = @(
        ($Session.Miners.Where({ $_.Status -eq [MinerStatus]::DryRun -or $_.Status -eq [MinerStatus]::Running }) | Sort-Object { [String]$_.DeviceNames }).ForEach(
            { 
                [PSCustomObject]@{ 
                    Algorithm      = $_.WorkersRunning.Pool.Algorithm -join ","
                    Currency       = $Session.ConfigRunning.FIATcurrency
                    CurrentSpeed   = $_.Hashrates_Live
                    Earnings       = ($_.WorkersRunning.Earnings | Measure-Object -Sum).Sum
                    EstimatedSpeed = $_.WorkersRunning.Hashrate
                    Name           = $_.Name
                    Path           = Resolve-Path -Relative $_.Path
                    Pool           = $_.WorkersRunning.Pool.Name -join ","
                    Profit         = If ($_.Profit) { $_.Profit } ElseIf ($Session.CalculatePowerCost) { ($_.WorkersRunning.Profit | Measure-Object -Sum).Sum - $_.PowerConsumption_Live * $Session.PowerCostBTCperW } Else { [Double]::NaN }
                    Type           = $_.Type
                }
            }
        )
    )

    $Body = @{ 
        user    = $Session.ConfigRunning.MonitoringUser
        worker  = $Session.ConfigRunning.WorkerName
        version = "$($Session.Branding.ProductLabel) $($Session.Branding.Version.ToString())"
        status  = $Session.NewMiningStatus
        profit  = If ([Double]::IsNaN($Session.MiningProfit)) { "n/a" } Else { [String]$Session.MiningProfit } # Earnings is NOT profit! Needs to be changed in mining monitor server
        data    = ConvertTo-Json $Data
    }

    # Send the request
    Try { 
        $Response = Invoke-RestMethod -Uri "$($Session.ConfigRunning.MonitoringServer)/api/report.php" -Method Post -Body $Body -TimeoutSec 10 -ErrorAction Stop
        If ($Response -eq "Success") { 
            Write-Message -Level Verbose "Reported worker status to monitoring server '$($Session.ConfigRunning.MonitoringServer)' [ID $($Session.ConfigRunning.MonitoringUser)]."
        }
        Else { 
            Write-Message -Level Verbose "Reporting worker status to monitoring server '$($Session.ConfigRunning.MonitoringServer)' failed: [$($Response)]."
        }
    }
    Catch { 
        Write-Message -Level Warn "Monitoring: Unable to send status to monitoring server '$($Session.ConfigRunning.MonitoringServer)' [ID $($Session.ConfigRunning.MonitoringUser)]."
    }
}

Function Read-MonitoringData { 

    If ($Session.ConfigRunning.ShowWorkerStatus -and $Session.ConfigRunning.MonitoringUser -and $Session.ConfigRunning.MonitoringServer -and $Session.WorkersLastUpdated -lt [DateTime]::Now.AddSeconds(-30)) { 
        Try { 
            $Workers = Invoke-RestMethod -Uri "$($Session.ConfigRunning.MonitoringServer)/api/workers.php" -Method Post -Body @{ user = $Session.ConfigRunning.MonitoringUser } -TimeoutSec 10 -ErrorAction Stop
            # Calculate some additional properties and format others
            $Workers.ForEach(
                { 
                    # Convert the unix timestamp to a datetime object, taking into account the local time zone
                    $_ | Add-Member @{ date = [TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($_.lastseen)) } -Force

                    # If a machine hasn't reported in for more than 10 minutes, mark it as offline
                    If ((New-TimeSpan -Start $_.date -End ([DateTime]::Now)).TotalMinutes -gt 10) { $_.status = "Offline" }
                }
            )
            $Session.Workers = $Workers
            $Session.WorkersLastUpdated = ([DateTime]::Now)

            Write-Message -Level Verbose "Retrieved worker status from '$($Session.ConfigRunning.MonitoringServer)' [ID $($Session.ConfigRunning.MonitoringUser)]."
        }
        Catch { 
            Write-Message -Level Warn "Monitoring: Unable to retrieve worker data from '$($Session.ConfigRunning.MonitoringServer)' [ID $($Session.ConfigRunning.MonitoringUser)]."
        }
    }

    Return $null
}

Function Get-TimeSince { 
    # Show friendly time since in days, hours, minutes and seconds

    Param (
        [Parameter(Mandatory = $true)]
        [DateTime]$TimeStamp
    )

    $TimeSpan = New-TimeSpan -Start $TimeStamp -End ([DateTime]::Now)
    $TimeSince = ""

    If ($TimeSpan.Days -ge 1) { $TimeSince += " {0:n0} day$(If ($TimeSpan.Days -ne 1) { "s" })" -f $TimeSpan.Days }
    If ($TimeSpan.Hours -ge 1) { $TimeSince += " {0:n0} hour$(If ($TimeSpan.Hours -ne 1) { "s" })" -f $TimeSpan.Hours }
    If ($TimeSpan.Minutes -ge 1) { $TimeSince += " {0:n0} minute$(If ($TimeSpan.Minutes -ne 1) { "s" })" -f $TimeSpan.Minutes }
    If ($TimeSpan.Seconds -ge 1) { $TimeSince += " {0:n0} second$(If ($TimeSpan.Seconds -ne 1) { "s" })" -f $TimeSpan.Seconds }
    If ($TimeSince) { $TimeSince += " ago" } Else { $TimeSince = "just now" }

    Return $TimeSince
}

Function Merge-Hashtable { 

    Param (
        [Parameter(Mandatory = $true)]
        [Object]$HT1,
        [Parameter(Mandatory = $true)]
        [Object]$HT2,
        [Parameter(Mandatory = $false)]
        [Boolean]$Unique = $false
    )

    $HT1 = [System.Collections.SortedList]::New($HT1, [StringComparer]::OrdinalIgnoreCase)
    $HT2 = [System.Collections.SortedList]::New($HT2, [StringComparer]::OrdinalIgnoreCase)

    $HT2.Keys.ForEach(
        { 
            If ($HT1.$_) { 
                If ($HT1.$_.GetType().Name -eq "Array" -or $HT1.$_.GetType().BaseType -match "array|System\.Array") { 
                    If ($HT2.$_) { 
                        $HT1.$_ += $HT2.$_
                        If ($Unique) { $HT1.$_ = ($HT1.$_ | Sort-Object -Unique) -as [Array] }
                    }
                    Break
                }
                ElseIf ($HT1.$_.GetType().Name -match "OrderedHashtable" -or $HT1.$_.GetType().BaseType -match "hashtable|System\.Collections\.Hashtable") { 
                    $HT1[$_] = Merge-Hashtable -HT1 $HT1[$_] -HT2 $HT2.$_ -Unique $Unique
                    Break
                }
            }
            Else { 
                $HT1.$_ = $HT2.$_ -as $HT2.$_.GetType()
            }
        }
    )

    Return $HT1
}

Function Get-DonationPoolsConfig { 
        # Build pool config with available donation data, not all devs have the same set of wallets available

    Param (
        [Parameter(Mandatory = $true)]
        [String]$DonateUsername
    )

    $DonationPoolsData = $Session.DonationData.$DonateUserName
    $DonationPoolsConfig = [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase) # as case insensitive hash table
    ((Get-ChildItem .\Pools\*.ps1 -File).BaseName | Sort-Object -Unique).Where({ $DonationPoolsData.PoolName -contains $_ }).ForEach(
        { 
            $DonationPoolConfig = $Session.ConfigRunning.PoolsConfig[$_].Clone()
            $DonationPoolConfig.EarningsAdjustmentFactor = 1
            $DonationPoolConfig.Region = $Session.ConfigRunning.PoolsConfig[$_].Region
            $DonationPoolConfig.WorkerName = "$($Session.Branding.ProductLabel)-$($Session.Branding.Version.ToString())-donate$($Session.ConfigRunning.Donation)"
            Switch -regex ($_) { 
                "^MiningDutch$|^ProHashing$" { 
                    If ($DonationPoolsData."$($_)UserName") { 
                        # not all devs have a known HashCryptos, MiningDutch or ProHashing account
                        $DonationPoolConfig.UserName = $DonationPoolsData."$($_)UserName"
                        $DonationPoolConfig.Variant = If ($Session.ConfigRunning.PoolsConfig[$_].Variant) { $Session.ConfigRunning.PoolsConfig[$_].Variant } Else { $Session.ConfigRunning.PoolName -match $_ }
                        $DonationPoolsConfig.$_ = $DonationPoolConfig
                    }
                    Break
                }
                Default { 
                    # not all devs have a known ETC or ETH address
                    
                    If ($Wallets = (Compare-Object -PassThru @((@($Session.PoolData.$_.GuaranteedPayoutCurrencies) + @($Session.PoolData.$_.PayoutCurrencies)) | Select-Object -Unique) @($DonationPoolsData.Wallets.Keys | Select-Object) -IncludeEqual -ExcludeDifferent)) { 
                        $DonationPoolConfig.Variant = If ($Session.ConfigRunning.PoolsConfig[$_].Variant) { $Session.ConfigRunning.PoolsConfig[$_].Variant } Else { $Session.ConfigRunning.PoolName -match $_ }
                        $DonationPoolConfig.Wallets = [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase)
                        $Wallets.Where({ $DonationPoolsData.Wallets.$_ }).ForEach({ $DonationPoolConfig.Wallets.$_ = $DonationPoolsData.Wallets.$_ })
                        $DonationPoolsConfig.$_ = $DonationPoolConfig
                    }
                }
            }
        }
    )

    Return $DonationPoolsConfig
}

Function Read-Config { 

    Param (
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )

    Function Get-DefaultConfig { 

        $DefaultConfig = @{ }
        $DefaultConfig.ConfigFileVersion = $Session.Branding.Version.ToString()

        # Add default config items
        $Session.AllCommandLineParameters.psBase.Keys.Where({ $_ -notin $DefaultConfig.psBase.Keys }).ForEach(
            { 
                $Value = $Session.AllCommandLineParameters.$_
                If ($Value -is [Switch]) { $Value = [Boolean]$Value }
                $DefaultConfig.$_ = $Value
            }
        )

        Return $DefaultConfig
    }

    Function Get-PoolsConfig { 

        # Load pool data
        If (-not $Session.PoolData) { 
            $Session.PoolData = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\PoolData.json") | ConvertFrom-Json -AsHashtable  | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase)
            $Session.PoolBaseNames = @($Session.PoolData.Keys)
            $Session.PoolVariants = @(($Session.PoolBaseNames.ForEach({ $Session.PoolData.$_.Variant.Keys }).Where({ Test-Path -LiteralPath "$PWD\Pools\$(Get-PoolBaseName $_).ps1" })) | Sort-Object -Unique)
            If (-not $Session.PoolVariants) { 
                Write-Message -Level Error "Terminating error - cannot continue! File '.\Data\PoolData.json' is not a valid $($Session.Branding.ProductLabel) JSON data file. Please restore it from your original download."
                (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\PoolData.json' is not a valid $($Session.Branding.ProductLabel) JSON data file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
                Exit
            }
        }

        # Build in memory pool config
        $PoolsConfig = [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase)
        ((Get-ChildItem .\Pools\*.ps1 -File).BaseName | Sort-Object -Unique).ForEach(
            { 
                $PoolName = $_
                If ($PoolConfig = $Session.PoolData.$PoolName.Clone()) { 
                    # Generic algorithm disabling is done in pool files
                    $PoolConfig.Remove("Algorithm")

                    # Merge default config data with custom pool config
                    If ($Session.PoolsConfigData.$PoolName -and ($CustomPoolConfig = [System.Collections.SortedList]::New($Session.PoolsConfigData.$PoolName, [StringComparer]::OrdinalIgnoreCase))) { 
                        $PoolConfig = Merge-Hashtable -HT1 $PoolConfig -HT2 $CustomPoolConfig -Unique $true
                    }

                    If (-not $PoolConfig.EarningsAdjustmentFactor) { $PoolConfig.EarningsAdjustmentFactor = $ConfigFromFile.EarningsAdjustmentFactor }
                    If ($PoolConfig.EarningsAdjustmentFactor -le 0 -or $PoolConfig.EarningsAdjustmentFactor -gt 10) { 
                        $PoolConfig.EarningsAdjustmentFactor = $ConfigFromFile.EarningsAdjustmentFactor
                        Write-Message -Level Warn "Earnings adjustment factor (value: $($PoolConfig.EarningsAdjustmentFactor)) for pool '$PoolName' is not within supported range (0 - 10); using default value $($PoolConfig.EarningsAdjustmentFactor)."
                    }

                    If (-not $PoolConfig.WorkerName) { $PoolConfig.WorkerName = $ConfigFromFile.WorkerName }
                    If (-not $PoolConfig.BalancesKeepAlive) { $PoolConfig.BalancesKeepAlive = $PoolData.$PoolName.BalancesKeepAlive }

                    $PoolConfig.Region = $PoolConfig.Region.Where({ (Get-Region $_) -notin @($PoolConfig.ExcludeRegion) })

                    Switch ($PoolName) { 
                        "HiveON" { 
                            If (-not $PoolConfig.Wallets) { 
                                $PoolConfig.Wallets = [System.Collections.SortedList]::new([StringComparer]::OrdinalIgnoreCase) # as ssorted case insensitive hash table
                                $ConfigFromFile.Wallets.GetEnumerator().Name.Where({ $PoolConfig.PayoutCurrencies -contains $_ }).ForEach({ 
                                    $PoolConfig.Wallets.$_ = $ConfigFromFile.Wallets.$_
                                })
                            }
                            Break
                        }
                        "MiningDutch" { 
                            If ((-not $PoolConfig.PayoutCurrency) -or $PoolConfig.PayoutCurrency -eq "[Default]") { $PoolConfig.PayoutCurrency = $ConfigFromFile.PayoutCurrency }
                            If (-not $PoolConfig.UserName) { $PoolConfig.UserName = $ConfigFromFile.MiningDutchUserName }
                            Break
                        }
                        "MiningPoolHub" { 
                            If (-not $PoolConfig.UserName) { $PoolConfig.UserName = $ConfigFromFile.MiningPoolHubUserName }
                            Break
                        }
                        "NiceHash" { 
                            If ($ConfigFromFile.NiceHashWallet) { $PoolConfig.Wallets = @{ "BTC" = $ConfigFromFile.NiceHashWallet } }
                            Break
                        }
                        "ProHashing" { 
                            If (-not $PoolConfig.UserName) { $PoolConfig.UserName = $ConfigFromFile.ProHashingUserName }
                            If (-not $PoolConfig.MiningMode) { $PoolConfig.MiningMode = $ConfigFromFile.ProHashingMiningMode }
                            Break
                        }
                        Default { 
                            If ((-not $PoolConfig.PayoutCurrency) -or $PoolConfig.PayoutCurrency -eq "[Default]") { $PoolConfig.PayoutCurrency = $ConfigFromFile.PayoutCurrency }
                            If (-not $PoolConfig.Wallets) { $PoolConfig.Wallets = $ConfigFromFile.Wallets }
                        }
                    }
                }
                $PoolsConfig.$PoolName = $PoolConfig
            }
        )
        Return $PoolsConfig
    }

    # Load the configuration
    $ConfigFromFile = [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase)
    If (Test-Path -LiteralPath $ConfigFile -PathType Leaf) { 
        Try { 
            $ConfigFromFile = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines($ConfigFile) | ConvertFrom-Json -AsHashtable  | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase)
        } 
        Catch { }
        If ($ConfigFromFile.Keys.Count -eq 0) { 
            $CorruptConfigFile = "$($ConfigFile)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").corrupt"
            Move-Item -Path $ConfigFile $CorruptConfigFile -Force
            If ($Config.psBase.Keys.Count -gt 0) { 
                Write-Message -Level Error "Configuration file '$($ConfigFile.Replace($PWD, "."))' is corrupt and was renamed to '$($CorruptConfigFile.Replace($PWD, "."))'. Using previous configuration values."
                Write-Config -Config $Config
                $Session.ConfigFileReadTimestamp = (Get-Item -Path $Session.ConfigFile).LastWriteTime
                Continue
            }
            Else { 
                Write-Host "Configuration file '$($ConfigFile.Replace($PWD, "."))' is corrupt and was renamed to '$($CorruptConfigFile.Replace($PWD, "."))'. Creating a new configuration using default values." -ForegroundColor "Red"
                Write-Host
                $ConfigFromFile = Get-DefaultConfig
            }
        }
        Else { 
            $Session.ConfigFileReadTimestamp = (Get-Item -Path $Session.ConfigFile).LastWriteTime
            ($Session.AllCommandLineParameters.Keys | Sort-Object).ForEach(
                { 
                    If ($ConfigFromFile.Keys -contains $_) { 
                        # Upper / lower case conversion of variable keys (config item names are case sensitive)
                        $Value = $ConfigFromFile.$_
                        $ConfigFromFile.Remove($_)
                        If ($Session.AllCommandLineParameters.$_ -is [Switch]) { 
                            $ConfigFromFile.$_ = [Boolean]$Value
                        }
                        ElseIf ($Session.AllCommandLineParameters.$_ -is [Array]) { 
                            $ConfigFromFile.$_ = [System.Collections.Generic.SortedSet[Object]]($Value)
                        }
                        ElseIf ($Session.AllCommandLineParameters.$_ -is [Hashtable]) { 
                            $ConfigFromFile.$_ = [System.Collections.SortedList]::New($Value, [StringComparer]::OrdinalIgnoreCase)
                        }
                        Else { 
                            $ConfigFromFile.$_ = $Value -as $Session.AllCommandLineParameters.$_.GetType().Name
                        }
                    }
                    Else { 
                        # Config parameter not in config file - use hardcoded value
                        $Value = $Session.AllCommandLineParameters.$_
                        If ($Value -is [Switch]) { $Value = [Boolean]$Value }
                        $ConfigFromFile.$_ = $Value
                    }
                }
            )
            If ($ConfigFromFile.EarningsAdjustmentFactor -le 0 -or $ConfigFromFile.EarningsAdjustmentFactor -gt 10) { 
                $ConfigFromFile.EarningsAdjustmentFactor = $Session.AllCommandLineParameters.EarningsAdjustmentFactor
                Write-Message -Level Warn "Default Earnings adjustment factor (value: $($ConfigFromFile.EarningsAdjustmentFactor)) is not within supported range (0 - 10); using default value $($Session.AllCommandLineParameters.EarningsAdjustmentFactor)."
            }
            If ($ConfigFromFile.PoolAllowedPriceIncreaseFactor -le 2 -or $ConfigFromFile.EarningsAdjustmentFactor -gt 99) { 
                $ConfigFromFile.PoolAllowedPriceIncreaseFactor = $Session.AllCommandLineParameters.PoolAllowedPriceIncreaseFactor
                Write-Message -Level Warn "Default Earnings adjustment factor (value: $($ConfigFromFile.PoolAllowedPriceIncreaseFactor)) is not within supported range (1 - 99); using default value $($Session.AllCommandLineParameters.PoolAllowedPriceIncreaseFactor)."
            }
        }
    }
    Else { 
        $ConfigFromFile = Get-DefaultConfig
    }

    # Build custom pools configuration, create case insensitive hashtable (https://stackoverflow.com/questions/24054147/powershell-hash-tables-double-key-error-a-and-a)
    If ($Session.PoolsConfigFile -and (Test-Path -LiteralPath $Session.PoolsConfigFile -PathType Leaf)) { 
        Try { 
            [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase) # as case insensitve sorted hashtable
            $Session.PoolsConfigData = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines($Session.PoolsConfigFile) | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase)
            $Session.PoolsConfigFileReadTimestamp = (Get-Item -Path $Session.PoolsConfigFile).LastWriteTime
        }
        Catch { 
            $Session.PoolsConfigData = [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase) # as case insensitive sorted hashtable
            Write-Message -Level Warn "Pools configuration file '$($Session.PoolsConfigFile.Replace("$(Convert-Path ".\")\", ".\"))' is corrupt. Will use default values."
            $Session.Remove("PoolsConfigFileReadTimestamp")
        }
    }
    Else { 
        $Session.Remove("PoolsConfigFileReadTimestamp")
    }

    $Global:Config.PoolsConfig = Get-PoolsConfig

    # Must update existing thread safe variable. Reassignment breaks updates to instances in other threads
    $ConfigFromFile.Keys.ForEach({ $Global:Config.$_ = $ConfigFromFile.$_ })

    $Session.ConfigReadTimestamp = [DateTime]::Now.ToUniversalTime()

    # Write config file in case they do not exist already
    If (-not $Session.FreshConfig) { 
        If (-not (Test-Path -LiteralPath $Session.ConfigFile -PathType Leaf)) { 
            Write-Config -Config $Config
            $Session.ConfigFileReadTimestamp = (Get-Item -Path $Session.ConfigFile).LastWriteTime
        }
    }
    $Session.ConfigRunning = $Config.Clone()

}

Function Update-ConfigFile { 

    Param (
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )

    $Session.ConfigurationHasChangedDuringUpdate = @()

    # NiceHash Internal is no longer available as of November 12, 2024
    If ($Config.PoolName -contains "NiceHash") { 
        If ($null -ne $Config.NiceHashWalletIsInternal -and -not $Config.NiceHashWalletIsInternal) { 
            Write-Message -Level Warn "Pool configuration changed during update (NiceHash [External] removed - to mine with NiceHash you must register)."
            $Session.ConfigurationHasChangedDuringUpdate += "- Pool 'NiceHash' [External] removed"
            $Config.PoolName = $Config.PoolName -notmatch "NiceHash"
            $Config.Remove("NiceHashWallet")
        }
    }
    $Config.Remove("NiceHashWalletIsInternal")

    # WorkerName must not contain '.'
    If ($Config.WorkerName -match  "\.") { 
        $Config.WorkerName = $Config.WorkerName -replace "\."
        $Session.ConfigurationHasChangedDuringUpdate += "- WorkerName adjusted (no '.' allowed)"
    }

    # Removed pools
    ("AHashPool", "BlockMasters", "NLPool", "MiningPoolHub", "ZergPool").ForEach(
        { 
            If ($Config.PoolName -like "$_*") { 
                Write-Message -Level Warn "Pool configuration changed during update ($($Config.PoolName -like "$_*" -join "; ") removed)."
                $Session.ConfigurationHasChangedDuringUpdate += "- Pool '$($Config.PoolName -like "$_*" -join "; ")' removed"
                $Config.PoolName = $Config.PoolName -notlike "$_*"
            }
            If ($Config.BalancesTrackerExcludePools -like "$_*") { 
                Write-Message -Level Warn "BalancesTrackerExcludePools changed during update ($($Config.BalancesTrackerExcludePools -like "$_*" -join "; ") removed)."
                $Session.ConfigurationHasChangedDuringUpdate += "- BalancesTrackerExcludePools '$($Config.BalancesTrackerExcludePools -like "$_*" -join "; ")' removed"
                $Config.BalancesTrackerExcludePools = $Config.BalancesTrackerExcludePools -notlike "$_*"
            }
        }
    )

    # Available regions have changed
    If ((Get-Region $Config.Region -List) -notcontains $Config.Region) { 
        $OldRegion = $Config.Region
        # Write message about new mining regions
        $Config.Region = Switch ($OldRegion) { 
            "Brazil"       { "USA West"; Break }
            "Europe East"  { "Europe"; Break }
            "Europe North" { "Europe"; Break }
            "India"        { "Asia"; Break }
            "US"           { "USA West"; Break }
            Default        { "Europe"; Break }
        }
        Write-Message -Level Warn "Available mining locations have changed during update ($OldRegion -> $($Config.Region))".
        $Session.ConfigurationHasChangedDuringUpdate += "- Available mining locations have changed ($OldRegion -> $($Config.Region))"
    }

    # Changed config items
    ($Config.GetEnumerator().Name | Sort-Object).ForEach(
        { 
            Switch ($_) { 
                # "OldParameterName" { $Config.NewParameterName = $Config.$_; $Config.Remove($_) }
                "BalancesShowInMainCurrency" { $Config.BalancesShowInFIATcurrency = $Config.$_; $Config.Remove($_); Break }
                "LogToScreen" { $Config.LogLevel = $Config.$_; $Config.Remove($_); Break }
                "MainCurrency" { $Config.FIATcurrency = $Config.$_; $Config.Remove($_); Break }
                "MinerInstancePerDeviceModel" { $Config.Remove($_); Break }
                "ShowAccuracy" { $Config.ShowColumnAccuracy = $Config.$_; $Config.Remove($_); Break }
                "ShowAccuracyColumn" { $Config.ShowColumnAccuracy = $Config.$_; $Config.Remove($_); Break }
                "ShowCoinName" { $Config.ShowColumnCoinName = $Config.$_; $Config.Remove($_); Break }
                "ShowCoinNameColumn" { $Config.ShowColumnCoinName = $Config.$_; $Config.Remove($_); Break }
                "ShowCurrency" { $Config.ShowColumnCurrency = $Config.$_; $Config.Remove($_); Break }
                "ShowCurrencyColumn" { $Config.ShowColumnCurrency = $Config.$_; $Config.Remove($_); Break }
                "ShowEarning" { $Config.ShowColumnEarnings = $Config.$_; $Config.Remove($_); Break }
                "ShowEarningColumn" { $Config.ShowColumnEarnings = $Config.$_; $Config.Remove($_); Break }
                "ShowEarningBias" { $Config.ShowColumnEarningsBias = $Config.$_; $Config.Remove($_); Break }
                "ShowEarningBiasColumn" { $Config.ShowColumnEarningsBias = $Config.$_; $Config.Remove($_); Break }
                "ShowHashrate" { $Config.ShowColumnHashrate = $Config.$_; $Config.Remove($_); Break }
                "ShowHashrateColumn" { $Config.ShowColumnHashrate = $Config.$_; $Config.Remove($_); Break }
                "ShowMinerFee" { $Config.ShowColumnMinerFee = $Config.$_; $Config.Remove($_); Break }
                "ShowMinerFeeColumn" { $Config.ShowColumnMinerFee = $Config.$_; $Config.Remove($_); Break }
                "ShowPool" { $Config.ShowColumnPool = $Config.$_; $Config.Remove($_); Break }
                "ShowPoolColumn" { $Config.ShowColumnPool = $Config.$_; $Config.Remove($_); Break }
                "ShowPoolFee" { $Config.ShowColumnPoolFee = $Config.$_; $Config.Remove($_); Break }
                "ShowPoolFeeColumn" { $Config.ShowColumnPoolFee = $Config.$_; $Config.Remove($_); Break }
                "ShowProfit" { $Config.ShowColumnProfit = $Config.$_; $Config.Remove($_); Break }
                "ShowProfitColumn" { $Config.ShowColumnProfit = $Config.$_; $Config.Remove($_); Break }
                "ShowProfitBias" { $Config.ShowColumnProfitBias = $Config.$_; $Config.Remove($_); Break }
                "ShowProfitBiasColumn" { $Config.ShowColumnProfitBias = $Config.$_; $Config.Remove($_); Break }
                "ShowPowerConsumption" { $Config.ShowColumnPowerConsumption = $Config.$_; $Config.Remove($_); Break }
                "ShowPowerConsumptionColumn" { $Config.ShowColumnPowerConsumption = $Config.$_; $Config.Remove($_); Break }
                "ShowPowerCost" { $Config.ShowColumnPowerCost = $Config.$_; $Config.Remove($_); Break }
                "ShowPowerCostColumn" { $Config.ShowColumnPowerCost = $Config.$_; $Config.Remove($_); Break }
                "ShowPoolBalances" { $Config.ShowColumnPoolBalances = $Config.$_; $Config.Remove($_); Break }
                "ShowPoolBalancesColumn" { $Config.ShowColumnPoolBalances = $Config.$_; $Config.Remove($_); Break }
                "ShowUser" { $Config.ShowColumnUser = $Config.$_; $Config.Remove($_); Break }
                "ShowUserColumn" { $Config.ShowColumnUser = $Config.$_; $Config.Remove($_); Break }
                "Transcript" { $Config.Remove($_); Break }
                "UnrealMinerEarningFactor" { $Config.UnrealisticMinerEarningsFactor = $Config.$_; $Config.Remove($_); Break }
                "UnrealPoolPriceFactor" { $Config.UnrealisticPoolPriceFactor = $Config.$_; $Config.Remove($_); Break }

                Default { If ($_ -notin @(@($Session.AllCommandLineParameters.psBase.Keys) + @("CryptoCompareAPIKeyParam") + @("DryRun") + @("PoolsConfig"))) { $Config.Remove($_) } } # Remove unsupported config items
            }
        }
    )

    If (-not $Session.FreshConfig) { 
        $Config.ConfigFileVersion = $Session.Branding.Version.ToString()
        Write-Config -Config $Config
        $Message = "Updated configuration file '$($Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))' to version $($Session.Branding.Version.ToString())."
        If ($Host.Name -match "ConsoleHost|Visual Studio Code Host") { $CursorPosition = $Host.UI.RawUI.CursorPosition }
        Write-Message -Level Verbose $Message
        If ($Host.Name -match "ConsoleHost|Visual Studio Code Host") { 
            [Console]::SetCursorPosition($CursorPosition.X + $Message.length, $CursorPosition.y)
            Write-Host " ✔" -ForegroundColor Green
        }
        Remove-Variable Message
    }
}

Function Write-Config { 

    Param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )

    If (-not (Test-Path -LiteralPath ".\Config" -PathType Container)) { New-Item -Path . -Name "Config" -ItemType Directory | Out-Null }

    If (Test-Path -LiteralPath $Session.ConfigFile -PathType Leaf) { 
        Copy-Item -Path $Session.ConfigFile -Destination "$($Session.ConfigFile)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").backup"
        Get-ChildItem -Path "$($Session.ConfigFile)_*.backup" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse # Keep 10 backup copies
    }

    $NewConfig = $Config.Clone()

    $NewConfig.Remove("ConfigFile")
    $NewConfig.Remove("PoolsConfig")

    $Header = 
"// This file was generated by $($Session.Branding.ProductLabel)
// $($Session.Branding.ProductLabel) will automatically add / convert / rename / update new settings when updating to a new version
"
    "$Header$($NewConfig | ConvertTo-Json -Depth 10)" | Out-File -LiteralPath $Session.ConfigFile -Force

    $Session.ShowAllMiners = $Config.ShowAllMiners
    $Session.ShowColumnAccuracy = $Config.ShowColumnAccuracy
    $Session.ShowColumnCoinName = $Config.ShowColumnCoinName
    $Session.ShowColumnCurrency = $Config.ShowColumnCurrency
    $Session.ShowColumnEarnings = $Config.ShowColumnEarnings
    $Session.ShowColumnEarningsBias = $Config.ShowColumnEarningsBias
    $Session.ShowColumnHashrate = $Config.ShowColumnHashrate
    $Session.ShowColumnMinerFee = $Config.ShowColumnMinerFee
    $Session.ShowColumnMinerFee = $Config.ShowColumnMinerFee
    $Session.ShowColumnPool = $Config.ShowColumnPool
    $Session.ShowColumnPoolFee = $Config.ShowColumnPoolFee
    $Session.ShowColumnPowerConsumption = $Config.ShowColumnPowerConsumption
    $Session.ShowColumnPowerCost = $Config.ShowColumnPowerCost
    $Session.ShowColumnProfit = $Config.ShowColumnProfit
    $Session.ShowColumnProfitBias = $Config.ShowColumnProfitBias
    $Session.ShowColumnUser = $Config.ShowColumnUser
    $Session.ShowPoolBalances = $Config.ShowPoolBalances
    $Session.ShowShares = $Config.ShowShares
    $Session.UIstyle = $Config.UIstyle
    $Session.FreshConfig = $false
}

Function Edit-File { 
    # Opens file in notepad. Notepad will remain in foreground until closed.
    Param (
        [Parameter(Mandatory = $false)]
        [String]$FileName
    )

    $FileWriteTime = (Get-Item -LiteralPath $FileName).LastWriteTime

    If ($FileName -eq $Session.PoolsConfigFile.Replace($PWD, ".")) { 
        If (Test-Path -LiteralPath $Session.PoolsConfigFile -PathType Leaf) { 
            Copy-Item -Path $Session.PoolsConfigFile -Destination "$($Session.PoolsConfigFile)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").backup"
            Get-ChildItem -Path "$($Session.PoolsConfigFile)_*.backup" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse # Keep 10 backup copies
        }
        Else { 
            Copy-Item -LiteralPath "$PWD\Data\PoolsConfig-Template.json" -Destination $FileName -ErrorAction Ignore
        }
    }

    If ($FileName -eq $Session.ConfigFile.Replace($PWD, ".")) { 
        If (Test-Path -LiteralPath $Session.ConfigFile -PathType Leaf) { 
            Copy-Item -Path $Session.ConfigFile -Destination "$($Session.ConfigFile)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").backup"
            Get-ChildItem -Path "$($Session.ConfigFile)_*.backup" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse # Keep 10 backup copies
        }
    }

    If (-not ($NotepadProcessId = (Get-CimInstance CIM_Process).Where({ $_.CommandLine -Like "*\Notepad.exe* $($FileName)" })[0].ProcessId)) { 
        $NotepadProcessId = (Start-Process -FilePath Notepad.exe -ArgumentList $FileName -PassThru).Id
    }

    # Check if the window is not already in foreground
    $FGWindowPid = [IntPtr]::Zero
    While (Get-Process -Id $NotepadProcessId) { 
        Try { 
            If ($MainWindowHandle -le 0) { $MainWindowHandle = (Get-Process -Id $NotepadProcessId).MainWindowHandle }
            If ($MainWindowHandle -le 0) { $MainWindowHandle = (Get-Process).Where({ $_.Parent.Id -eq $NotepadProcessId }).MainWindowHandle }

            [Win32]::GetWindowThreadProcessId([Win32]::GetForegroundWindow(), [ref]$FGWindowPid) | Out-Null
            If ($NotepadProcessId -ne $FGWindowPid) { 
                If ([Win32]::GetForegroundWindow() -ne $MainWindowHandle) { 
                    [Win32]::ShowWindowAsync($MainWindowHandle, 6) | Out-Null # SW_MINIMIZE
                    [Win32]::ShowWindowAsync($MainWindowHandle, 9) | Out-Null # SW_RESTORE
                }
            }
            Start-Sleep -Milliseconds 100
        }
        Catch { }
    }

    If ($FileWriteTime -ne (Get-Item -Path $FileName).LastWriteTime) { 
        Write-Message -Level Verbose "Saved '$FileName'. Changes will become fully active in the next cycle."
        Return "Saved '$FileName'.`nChanges will become fully active in the next cycle."
    }

    Return "No changes to '$FileName' were made."
}

Function Get-SortedObject { 

    Param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [Object]$Object
    )

    Switch -Regex ($Object.GetType().Name) { 
        "PSCustomObject" { 
            $SortedObject = [PSCustomObject]@{ }
            ($Object.PSObject.Properties.Name | Sort-Object).ForEach(
                { 
                    If ($Object.$_.GetType().Name -eq "Array" -or $Object.$_.GetType().BaseType -match "array|System\.Array") { 
                        If ($Object[$_].Count -lt 2) { 
                            $SortedObject | Add-Member $_ ([System.Collections.Generic.SortedSet[Object]]([Array]$Object[$_]))
                        }
                        Else { 
                            $SortedObject | Add-Member $_ ([System.Collections.Generic.SortedSet[Object]]($Object[$_]))
                        }
                    }
                    ElseIf ($Object.$_.GetType().Name -match "OrderedHashtable|PSCustomObject" -or $Object.$_.GetType().BaseType -match "hashtable|System\.Collections\.Hashtable") { 
                        $SortedObject | Add-Member $_ (Get-SortedObject $Object.$_)
                    }
                    Else { 
                        $SortedObject | Add-Member $_ $Object.$_
                    }
                }
            )
            Break
        }
        "Hashtable|OrderedDictionary|OrderedHashTable|SyncHashtable" { 
            $SortedObject = [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase) # as case insensitve sorted hashtable
            ($Object.GetEnumerator().Name | Sort-Object).ForEach(
                { 
                    If ($Object[$_].GetType().Name -eq "Array" -or $Object[$_].GetType().BaseType -match "array|System\.Array") { 
                        If ($Object[$_].Count -lt 2) { 
                            $SortedObject[$_] = [System.Collections.Generic.SortedSet[Object]]([Array]$Object[$_])
                        }
                        Else { 
                            $SortedObject[$_] = [System.Collections.Generic.SortedSet[Object]]($Object[$_])
                        }
                    }
                    ElseIf ($Object[$_].GetType().Name -match "OrderedHashtable|PSCustomObject" -or $Object[$_].GetType().BaseType -match "hashtable|System\.Collections\.Hashtable") { 
                        $SortedObject[$_] = Get-SortedObject $Object[$_]
                    }
                    Else { 
                        $SortedObject[$_] = $Object[$_]
                    }
                }
            )
            Break
        }
        Default { 
            $SortedObject = $Object | Sort-Object
        }
    }
    Return $SortedObject
}

Function Enable-Stat { 

    Param (
        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    If ($Stat = Get-Stat -Name $Name) { 

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

Function Disable-Stat { 

    Param (
        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    $Path = "Stats\$Name.txt"
    $Stat = Get-Stat -Name $Name
    If (-not $Stat) { $Stat = Set-Stat -Name $Name -Value 0 }
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

Function Set-Stat { 

    Param (
        [Parameter(Mandatory = $true)]
        [String]$Name,
        [Parameter(Mandatory = $true)]
        [Double]$Value,
        [Parameter(Mandatory = $false)]
        [DateTime]$Updated = ([DateTime]::Now),
        [Parameter(Mandatory = $false)]
        [TimeSpan]$Duration,
        [Parameter(Mandatory = $false)]
        [Boolean]$FaultDetection = $true,
        [Parameter(Mandatory = $false)]
        [Boolean]$ChangeDetection = $false,
        [Parameter(Mandatory = $false)]
        [Int]$ToleranceExceeded = 3
    )

    $Timer = $Updated = $Updated.ToUniversalTime()

    $Path = "Stats\$Name.txt"
    $SmallestValue = 1E-20
    $Stat = Get-Stat -Name $Name

    If ($Stat -is [Hashtable] -and -not [Double]::IsNaN($Stat.Minute_Fluctuation)) { 
        If (-not $Stat.Timer) { $Stat.Timer = $Stat.Updated.AddMinutes(-1) }
        If (-not $Duration) { $Duration = $Updated - $Stat.Timer }
        If ($Duration -le 0) { Return $Stat }

        If ($ChangeDetection -and [Decimal]$Value -eq [Decimal]$Stat.Live) { $Updated = $Stat.Updated }

        If ($FaultDetection) { 
            $FaultFactor = If ($Name -match ".+_Hashrate$") { 0.1 } Else { 0.2 }
            $ToleranceMin = $Stat.Week * (1 - $FaultFactor)
            $ToleranceMax = $Stat.Week * (1 + $FaultFactor)
        }
        Else { 
            $ToleranceMin = $ToleranceMax = $Value
        }

        If ($Value -lt $ToleranceMin -or $Value -gt $ToleranceMax) { $Stat.ToleranceExceeded ++ }
        Else { $Stat.ToleranceExceeded = [UInt16]0 }

        If ($Value -gt 0 -and $Stat.ToleranceExceeded -gt 0 -and $Stat.ToleranceExceeded -lt $ToleranceExceeded -and $Stat.Week -gt 0) { 
            If ($Name -match ".+_Hashrate$") { 
                Write-Message -Level Warn "Error saving hashrate for '$($Name -replace "_Hashrate$")'. $(($Value | ConvertTo-Hash) -replace " ") is outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace " ") to $(($ToleranceMax | ConvertTo-Hash) -replace " ")) [Iteration $($Stats.($Stat.Name).ToleranceExceeded) of $ToleranceExceeded until enforced update]."
            }
            ElseIf ($Name -match ".+_PowerConsumption") { 
                Write-Message -Level Warn "Error saving power consumption for '$($Name -replace "_PowerConsumption$")'. $($Value.ToString("N2"))W is outside fault tolerance ($($ToleranceMin.ToString("N2"))W to $($ToleranceMax.ToString("N2"))W) [Iteration $($Stats.($Stat.Name).ToleranceExceeded) of $ToleranceExceeded until enforced update]."
            }
            Return $Stat
        }
        Else { 
            If (-not $Stat.Disabled -and ($Value -eq 0 -or $Stat.ToleranceExceeded -ge $ToleranceExceeded -or $Stat.Week_Fluctuation -ge 1)) { 
                If ($Value -gt 0 -and $Stat.ToleranceExceeded -ge $ToleranceExceeded) { 
                    If ($Name -match ".+_Hashrate$") { 
                        Write-Message -Level Warn "Hashrate '$($Name -replace "_Hashrate$")' was forcefully updated. $(($Value | ConvertTo-Hash) -replace " ") was outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace " ") to $(($ToleranceMax | ConvertTo-Hash) -replace " "))$(If ($Stat.Week_Fluctuation -lt 1) { " for $($Stats.($Stat.Name).ToleranceExceeded) times in a row." })"
                    }
                    ElseIf ($Name -match ".+_PowerConsumption$") { 
                        Write-Message -Level Warn "Power consumption for '$($Name -replace "_PowerConsumption$")' was forcefully updated. $($Value.ToString("N2"))W was outside fault tolerance ($($ToleranceMin.ToString("N2"))W to $($ToleranceMax.ToString("N2"))W)$(If ($Stat.Week_Fluctuation -lt 1) { " for $($Stats.($Stat.Name).ToleranceExceeded) times in a row." })"
                    }
                }

                Remove-Stat -Name $Name
                $Stat = Set-Stat -Name $Name -Value $Value
            }
            Else { 
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
    Else { 
        If (-not $Duration) { $Duration = [TimeSpan]::FromMinutes(1) }

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

    Return $Stat
}

Function Get-Stat { 

    Param (
        [Parameter(Mandatory = $false)]
        [String[]]$Names = (Get-ChildItem $PWD\Stats).BaseName
    )

    $Names.ForEach(
        { 
            $Name = $_

            If ($Global:Stats[$Name] -isnot [Hashtable]) { 
                # Reduce number of errors
                If (-not (Test-Path -LiteralPath "Stats\$Name.txt" -PathType Leaf)) { Return }

                Try { 
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
                Catch { 
                    Write-Message -Level Warn "Stat file '$Name' is corrupt and will be reset."
                    Remove-Stat $Name
                }
            }

            $Global:Stats[$Name]
        }
    )
}

Function Remove-Stat { 

    Param (
        [Parameter(Mandatory = $true)]
        [String[]]$Names
    )

    $Names.ForEach(
        { 
            Remove-Item -LiteralPath "Stats\$_.txt" -Force -Confirm:$false -ErrorAction Ignore
            $Global:Stats.Remove($_)
        }
    )
}

Function Invoke-TcpRequest { 

    Param (
        [Parameter(Mandatory = $true)]
        [String]$Server,
        [Parameter(Mandatory = $true)]
        [String]$Port,
        [Parameter(Mandatory = $true)]
        [String]$Request,
        [Parameter(Mandatory = $true)]
        [Int]$Timeout, # seconds
        [Parameter(Mandatory = $false)]
        [Boolean]$ReadToEnd = $false
    )

    Try { 
        $Client = [Net.Sockets.TcpClient]::new()
        $Client.SendTimeout = $Client.ReceiveTimeout = $Timeout * 1000
        $Client.Connect($Server, $Port)
        $Stream = $Client.GetStream()
        $Writer = [IO.StreamWriter]::new($Stream)
        $Reader = [IO.StreamReader]::new($Stream)
        $Writer.AutoFlush = $true
        $Writer.WriteLine($Request)
        $Response = If ($ReadToEnd) { $Reader.ReadToEnd() } Else { $Reader.ReadLine() }
    }
    Catch { $Error.Remove($Error[$Error.Count - 1]) }
    Finally { 
        If ($Reader) { $Reader.Close() }
        If ($Writer) { $Writer.Close() }
        If ($Stream) { $Stream.Close() }
        If ($Client) { $Client.Close() }
    }

    Return $Response
}

Function Get-CpuId { 
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
    If ($nIds -ge 0x00000001) { 

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

    If ($nIds -ge 0x00000007) { 

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

    If ($nExIds -ge 0x80000001) { 

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
    Return [PSCustomObject]@{ 
        Vendor   = $Vendor
        Name     = $Name
        Features = ($Features.psBase.Keys | Sort-Object).ForEach{ If ($Features.$_) { $_ } }
    }
}

Function Get-GPUArchitectureAMD { 

    Param (
        [Parameter(Mandatory = $true)]
        [String]$Model,
        [Parameter(Mandatory = $false)]
        [String]$Architecture = ""
    )

    $Model = $Model -replace "[^A-Z0-9]"
    $Architecture = $Architecture -replace ":.+$" -replace "[^A-Za-z0-9]+"

    ForEach ($GPUArchitecture in $Session.GPUArchitectureDbAMD.PSObject.Properties) { 
        If ($Architecture -match $GPUArchitecture.Value) { Return $GPUArchitecture.Name }
    }

    Return $Architecture
}

Function Get-GPUArchitectureNvidia { 

    Param (
        [Parameter(Mandatory = $true)]
        [String]$Model,
        [Parameter(Mandatory = $false)]
        [String]$ComputeCapability = ""
    )

    $Model = $Model -replace "[^A-Z0-9]"
    $ComputeCapability = $ComputeCapability -replace "[^\d\.]"

    ForEach ($GPUArchitecture in $Session.GPUArchitectureDbNvidia.PSObject.Properties) { 
        If ($GPUArchitecture.Value.Compute -contains $ComputeCapability) { Return $GPUArchitecture.Name }
    }

    ForEach ($GPUArchitecture in $GPUArchitectureDbNvidia.PSObject.Properties) { 
        If ($Model -match $GPUArchitecture.Value.Model) { Return $GPUArchitecture.Name }
    }

    Return "Other"
}

Function Get-Device { 

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
    Try { 
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
                        Switch -Regex ($Device_CIM.Manufacturer) { 
                            "Advanced Micro Devices" { "AMD"; Break }
                            "AMD"                    { "AMD"; Break }
                            "Intel"                  { "INTEL"; Break }
                            "NVIDIA"                 { "NVIDIA"; Break }
                            "Microsoft"              { "MICROSOFT"; Break }
                            Default                  { $Device_CIM.Manufacturer -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "[^A-Z0-9]" }
                        }
                    )
                }

                $Device.Id             = [Int]$Id
                $Device.Type_Id        = [Int]$Type_Id.($Device.Type)
                $Device.Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                $Device.Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)

                $Device.Name  = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)"
                $Device.Model = (($Device.Model -split " " -replace "Processor", "CPU" -replace "Graphics", "GPU") -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "@" -notmatch ".*[MG]Hz") -join " " -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel"-replace "^\s*" -replace "[^ A-Z0-9\.]" -replace " \s+" -replace "\s*$"

                If (-not $Type_Vendor_Id.($Device.Type)) { $Type_Vendor_Id.($Device.Type) = @{ } }

                $Id ++
                $Vendor_Id.($Device.Vendor) ++
                $Type_Vendor_Id.($Device.Type).($Device.Vendor) ++
                If ($Session."Supported$($Device.Type)DeviceVendors" -contains $Device.Vendor) { $Type_Id.($Device.Type) ++ }

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
                        If ($Device_PNP.DEVPKEY_Device_BusNumber -is [UInt64] -or $Device_PNP.DEVPKEY_Device_BusNumber -is [UInt32]) { 
                            [Int64]$Device_PNP.DEVPKEY_Device_BusNumber
                        }
                    )
                    Name      = $null
                    Memory    = [Math]::Max([UInt64]$Device_CIM.AdapterRAM, [uInt64]$Device_Reg.'HardwareInformation.qwMemorySize')
                    MemoryGiB = [Double]([Math]::Round([Math]::Max([UInt64]$Device_CIM.AdapterRAM, [uInt64]$Device_Reg.'HardwareInformation.qwMemorySize') / 0.05GB) / 20) # Round to nearest 50MB
                    Model     = $Device_CIM.Name
                    Type      = "GPU"
                    Vendor    = $(
                        Switch -Regex ([String]$Device_CIM.AdapterCompatibility) { 
                            "Advanced Micro Devices" { "AMD"; Break }
                            "AMD"                    { "AMD"; Break }
                            "Intel"                  { "INTEL"; Break }
                            "NVIDIA"                 { "NVIDIA"; Break }
                            "Microsoft"              { "MICROSOFT"; Break }
                            Default                  { $Device_CIM.AdapterCompatibility -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "[^A-Z0-9]" }
                        }
                    )
                }

                $Device.Id             = [Int]$Id
                $Device.Type_Id        = [Int]$Type_Id.($Device.Type)
                $Device.Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                $Device.Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)

                # Unsupported devices start with DeviceID 100 (to not disrupt device order when running in a Citrix or RDP session)
                If ($Session."Supported$($Device.Type)DeviceVendors" -contains $Device.Vendor) { $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)" }
                ElseIf ($Device.Type -eq "CPU") { $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedCPUVendorID ++)" }
                Else { $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedGPUVendorID ++)" }

                $Device.Model = (($Device.Model -split " " -replace "Processor", "CPU" -replace "Graphics", "GPU") -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") + "$([UInt64]($Device.Memory/1GB))GB" -join " " -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel"-replace "^\s*" -replace "[^ A-Z0-9\.]" -replace " \s+" -replace "\s*$"

                If (-not $Type_Vendor_Id.($Device.Type)) { $Type_Vendor_Id.($Device.Type) = @{ } }

                $Id ++
                $Vendor_Id.($Device.Vendor) ++
                $Type_Vendor_Id.($Device.Type).($Device.Vendor) ++
                If ($Session."Supported$($Device.Type)DeviceVendors" -contains $Device.Vendor) { $Type_Id.($Device.Type) ++ }

                # Add raw data
                $Device.CIM = $Device_CIM
                # $Device.PNP = $Device_PNP
                # $Device.Reg = $Device_Reg
            }
        )
    }
    Catch { 
        Write-Message -Level Warn "WDDM device detection has failed."
    }
    Remove-Variable Device_CIM, Device_PNP, Device_Reg, PnpDevices -ErrorAction Ignore

    # Get OpenCL data
    [OpenCl.Platform]::GetPlatformIDs().ForEach(
        { 
            Try { 
                $OpenCLplatform = $_
                # Skip devices with negative PCIbus 
                ([OpenCl.Device]::GetDeviceIDs($_, [OpenCl.DeviceType]::All).Where({ $_.PCIbus -ge 0 }).ForEach({ $_ | ConvertTo-Json -EnumsAsStrings -WarningAction SilentlyContinue }) | Select-Object -Unique).ForEach(
                    { 
                        $Device_OpenCL = $_ | ConvertFrom-Json

                        # Add normalised values
                        $Device = [Device]@{ 
                            Bus = $(
                                If ($Device_OpenCL.PCIBus -is [Int64] -or $Device_OpenCL.PCIBus -is [Int32]) { 
                                    [Int64]$Device_OpenCL.PCIBus
                                }
                            )
                            Name      = $null
                            Memory    = [UInt64]$Device_OpenCL.GlobalMemSize
                            MemoryGiB = [Double]([Math]::Round($Device_OpenCL.GlobalMemSize / 0.05GB) / 20) # Round to nearest 50MB
                            Model     = $Device_OpenCL.Name
                            Type      = $(
                                Switch -Regex ([String]$Device_OpenCL.Type) { 
                                    "CPU"   { "CPU"; Break }
                                    "GPU"   { "GPU"; Break }
                                    Default { [String]$Device_OpenCL.Type -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "[^A-Z0-9]" }
                                }
                            )
                            Vendor = $(
                                Switch -Regex ([String]$Device_OpenCL.Vendor) { 
                                    "Advanced Micro Devices" { "AMD"; Break }
                                    "AMD"                    { "AMD"; Break }
                                    "Intel"                  { "INTEL"; Break }
                                    "NVIDIA"                 { "NVIDIA"; Break }
                                    "Microsoft"              { "MICROSOFT"; Break }
                                    Default                  { [String]$Device_OpenCL.Vendor -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "[^A-Z0-9]" }
                                }
                            )
                        }

                        $Device.Id             = [Int]$Id
                        $Device.Type_Id        = [Int]$Type_Id.($Device.Type)
                        $Device.Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                        $Device.Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)

                        # Unsupported devices get DeviceID 100 (to not disrupt device order when running in a Citrix or RDP session)
                        If ($Session."Supported$($Device.Type)DeviceVendors" -contains $Device.Vendor) { $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)" }
                        ElseIf ($Device.Type -eq "CPU") { $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedCPUVendorID ++)" }
                        Else {$Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedGPUVendorID ++)" }

                        $Device.Model = ((($Device.Model -split " " -replace "Processor", "CPU" -replace "Graphics", "GPU") -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") + "$([UInt64]($Device.Memory/1GB))GB") -join " " -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "^\s*" -replace "[^ A-Z0-9\.]" -replace " \s+" -replace "\s*$"

                        If (-not $Type_Vendor_Id.($Device.Type)) { $Type_Vendor_Id.($Device.Type) = @{ } }

                        If ($Devices.Where({ $_.Type -eq $Device.Type -and $_.Bus -eq $Device.Bus })) { $Device = [Device]($Devices.Where({ $_.Type -eq $Device.Type -and $_.Bus -eq $Device.Bus }) | Select-Object) }
                        ElseIf ($Device.Type -eq "GPU" -and $Session.SupportedGPUDeviceVendors -contains $Device.Vendor) { 
                            $Devices += $Device

                            If (-not $Type_Vendor_Index.($Device.Type)) { $Type_Vendor_Index.($Device.Type) = @{ } }

                            $Id ++
                            $Vendor_Id.($Device.Vendor) ++
                            $Type_Vendor_Id.($Device.Type).($Device.Vendor) ++
                            $Type_Id.($Device.Type) ++
                        }

                        # Add OpenCL specific data
                        $Device.Index                 = [Int]$Index
                        $Device.Type_Index            = [Int]$Type_Index.($Device.Type)
                        $Device.Vendor_Index          = [Int]$Vendor_Index.($Device.Vendor)
                        $Device.Type_Vendor_Index     = [Int]$Type_Vendor_Index.($Device.Type).($Device.Vendor)
                        $Device.PlatformId            = [Int]$PlatformId
                        $Device.PlatformId_Index      = [Int]$PlatformId_Index.($PlatformId)
                        $Device.Type_PlatformId_Index = [Int]$Type_PlatformId_Index.($Device.Type).($PlatformId)

                        # Add raw data
                        $Device.OpenCL = $Device_OpenCL

                        If ($Device.OpenCL.PlatForm.Name -eq "NVIDIA CUDA") { $Device.CUDAversion = ([System.Version]($Device.OpenCL.PlatForm.Version -replace ".+CUDA ")) }

                        If (-not $Type_Vendor_Index.($Device.Type)) { $Type_Vendor_Index.($Device.Type) = @{ } }
                        If (-not $Type_PlatformId_Index.($Device.Type)) { $Type_PlatformId_Index.($Device.Type) = @{ } }

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
            Catch { 
                Write-Message -Level Warn "Device detection for OpenCL platform '$($OpenCLplatform.Version)' has failed."
                "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $ErrorLogFile
                $_.Exception | Format-List -Force >> $ErrorLogFile
                $_.InvocationInfo | Format-List -Force >> $ErrorLogFile
            }
        }
    )
    Remove-Variable Device, OpenCLplatform -ErrorAction Ignore

    ($Devices.Where({ $_.Model -ne "Remote Display Adapter 0GB" -and $_.Vendor -ne "CitrixSystemsInc" -and $_.Bus -Is [Int64] }) | Sort-Object -Property Bus).ForEach(
        { 
            If ($_.Type -eq "GPU") { 
                If ($_.Vendor -eq "NVIDIA") { $_.Architecture = (Get-GPUArchitectureNvidia -Model $_.Model -ComputeCapability $_.OpenCL.DeviceCapability) }
                ElseIf ($_.Vendor -eq "AMD") { $_.Architecture = (Get-GPUArchitectureAMD -Model $_.Model -Architecture $_.OpenCL.Architecture) }
                Else { $_.Architecture = "Other" }
            }

            $_.Slot             = [Int]$Slot
            $_.Type_Slot        = [Int]$Type_Slot.($_.Type)
            $_.Vendor_Slot      = [Int]$Vendor_Slot.($_.Vendor)
            $_.Type_Vendor_Slot = [Int]$Type_Vendor_Slot.($_.Type).($_.Vendor)

            If (-not $Type_Vendor_Slot.($_.Type)) { $Type_Vendor_Slot.($_.Type) = @{ } }

            $Slot ++
            $Type_Slot.($_.Type) ++
            $Vendor_Slot.($_.Vendor) ++
            $Type_Vendor_Slot.($_.Type).($_.Vendor) ++
        }
    )

    $Devices.ForEach(
        { 
            $Device = $_

            $Device.Bus_Index = @($Devices.Bus | Sort-Object).IndexOf([Int]$Device.Bus)
            $Device.Bus_Type_Index = @($Devices.Where({ $_.Type -eq $Device.Type }).Bus | Sort-Object).IndexOf([Int]$Device.Bus)
            $Device.Bus_Vendor_Index = @($Devices.Where({ $_.Vendor -eq $Device.Vendor }).Bus | Sort-Object).IndexOf([Int]$Device.Bus)
            $Device.Bus_Platform_Index = @($Devices.Where({ $_.Platform -eq $Device.Platform }).Bus | Sort-Object).IndexOf([Int]$Device.Bus)

            $Device
        }
    )
}

Filter ConvertTo-Hash { 

    $Units = " kMGTPEZY" # k(ilo) in small letters, see https://en.wikipedia.org/wiki/Metric_prefix

    If ( $null -eq $_ -or [Double]::IsNaN($_)) { Return "n/a" }
    ElseIf ($_ -eq 0) { Return "0H/s " }
    $Base1000 = [Math]::Max([Double]0, [Math]::Min([Math]::Truncate([Math]::Log([Math]::Abs([Double]$_), [Math]::Pow(1000, 1))), $Units.Length - 1))
    $UnitValue = $_ / [Math]::Pow(1000, $Base1000)
    $Digits = If ($UnitValue -lt 10) { 3 } Else { 2 }
    "{0:n$($Digits)} $($Units[$Base1000])H/s" -f $UnitValue
}

Function Get-DecimalsFromValue { 
    # Used to limit absolute length of number
    # The larger the value, the less decimal digits are returned
    # Maximal $DecimalsMax are returned

    Param (
        [Parameter(Mandatory = $true)]
        [Double]$Value,
        [Parameter(Mandatory = $true)]
        [Int]$DecimalsMax
    )

    Return [Math]::Max($DecimalsMax - [Math]::Floor([Math]::Abs($Value)).ToString().Length + 1, 0)
}

Function Get-Combination { 

    Param (
        [Parameter(Mandatory = $true)]
        [Array]$Value,
        [Parameter(Mandatory = $false)]
        [Int]$SizeMax = $Value.Count,
        [Parameter(Mandatory = $false)]
        [Int]$SizeMin = 1
    )

    $Combination = [PSCustomObject]@{ }

    For ($I = 0; $I -lt $Value.Count; $I ++) { 
        $Combination | Add-Member @{ [Math]::Pow(2, $I) = $Value[$I] }
    }

    $CombinationKeys = $Combination.PSObject.Properties.Name

    For ($I = $SizeMin; $I -le $SizeMax; $I ++) { 
        $X = [Math]::Pow(2, $I) - 1

        While ($X -le [Math]::Pow(2, $Value.Count) - 1) { 
            [PSCustomObject]@{ 
                Combination = $CombinationKeys.Where({ $_ -band $X }).ForEach({ $Combination.$_ })
            }
            $Smallest = $X -band - $X
            $Ripple = $X + $Smallest
            $NewSmallest = $Ripple -band - $Ripple
            $Ones = (($NewSmallest / $Smallest) -shr 1) - 1
            $X = $Ripple -bor $Ones
        }
    }
}

Function Expand-WebRequest { 

    Param (
        [Parameter(Mandatory = $true)]
        [String]$Uri,
        [Parameter(Mandatory = $false)]
        [String]$Path = ""
    )

    # Set current path used by .net methods to the same as the script's path
    [Environment]::CurrentDirectory = $ExecutionContext.SessionState.Path.CurrentFileSystemLocation

    If (-not $Path) { $Path = Join-Path ".\Downloads" ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName }
    If (-not (Test-Path -LiteralPath ".\Downloads" -PathType Container)) { New-Item "Downloads" -ItemType "directory" | Out-Null }
    $FileName = Join-Path ".\Downloads" (Split-Path $Uri -Leaf)

    If (Test-Path -LiteralPath $FileName -PathType Leaf) { Remove-Item $FileName }
    Invoke-WebRequest -Uri $Uri -OutFile $FileName -TimeoutSec 5

    If (".msi", ".exe" -contains ([IO.FileInfo](Split-Path $Uri -Leaf)).Extension) { 
        Start-Process $FileName "-qb" -Wait | Out-Null
    }
    Else { 
        $Path_Old = (Join-Path (Split-Path (Split-Path $Path)) ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName)
        $Path_New = Split-Path $Path

        If (Test-Path -LiteralPath $Path_Old -PathType Container) { Remove-Item $Path_Old -Recurse -Force }
        Start-Process ".\Utils\7z" "x `"$([IO.Path]::GetFullPath($FileName))`" -o`"$([IO.Path]::GetFullPath($Path_Old))`" -y -spe" -Wait -WindowStyle Hidden | Out-Null

        If (Test-Path -LiteralPath $Path_New -PathType Container) { Remove-Item $Path_New -Recurse -Force }

        # Use first (topmost) directory, some miners, e.g. ClaymoreDual_v11.9, contain multiple miner binaries for different driver versions in various subdirs
        $Path_Old = ((Get-ChildItem -Path $Path_Old -File -Recurse).Where({ $_.Name -eq $(Split-Path $Path -Leaf) })).Directory | Select-Object -First 1

        If ($Path_Old) { 
            (Move-Item $Path_Old $Path_New -PassThru).ForEach({ $_.LastWriteTime = [DateTime]::Now })
            $Path_Old = (Join-Path (Split-Path (Split-Path $Path)) ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName)
            If (Test-Path -LiteralPath $Path_Old -PathType Container) { Remove-Item -Path $Path_Old -Recurse -Force }
        }
        Else { 
            Throw "Error: Cannot find '$Path'."
        }
    }
}

Function Get-Algorithm { 

    Param (
        [Parameter(Mandatory = $false)]
        [String]$Algorithm
    )

    $Algorithm = $Algorithm -replace "[^a-z0-9]+"

    If ($Session.Algorithms[$Algorithm]) { Return $Session.Algorithms[$Algorithm] }

    Return (Get-Culture).TextInfo.ToTitleCase($Algorithm.ToLower())
}

Function Get-Region { 

    Param (
        [Parameter(Mandatory = $true)]
        [String]$Region,
        [Parameter(Mandatory = $false)]
        [Switch]$List = $false
    )

    If ($List) { Return $Session.Regions[$Region] }

    If ($Session.Regions[$Region]) { Return $($Session.Regions[$Region] | Select-Object -First 1) }

    Return $Region
}

Function Add-CoinName { 

    Param (
        [Parameter(Mandatory = $true)]
        [String]$Algorithm,
        [Parameter(Mandatory = $true)]
        [String]$Currency,
        [Parameter(Mandatory = $true)]
        [String]$CoinName
    )

    If ($Algorithm -and -not (($Session.CoinNames[$Currency] -and $Session.CurrencyAlgorithm[$Currency]))) { 

        # Get mutex. Mutexes are shared across all threads and processes.
        # This lets us ensure only one thread is trying to write to the file at a time.
        $Mutex = [System.Threading.Mutex]::new($false, "$($Session.Branding.ProductLabel)_DataFiles")

        If (-not $Session.CurrencyAlgorithm[$Currency]) { 
            $Session.CurrencyAlgorithm[$Currency] = Get-Algorithm $Algorithm
            # Attempt to aquire mutex, waiting up to 1 second if necessary. If aquired, update the file and release mutex
            If ($Mutex.WaitOne(1000)) { 
                $Session.CurrencyAlgorithm | ConvertTo-Json | Out-File -Path ".\Data\CurrencyAlgorithm.json" -ErrorAction Ignore -Force
                $Mutex.ReleaseMutex()
            }
        }
        If (-not $Session.CoinNames[$Currency]) { 
            If ($CoinName = ($CoinName.Trim() -replace "[^A-Z0-9 \$\.]" -replace "coin$", " Coin" -replace "bit coin$", "Bitcoin" -replace "ERC20$" , " ERC20" -replace "TRC20$" , " TRC20" -replace " \s+" )) { 
                $Session.CoinNames[$Currency] = $CoinName
                # Attempt to aquire mutex, waiting up to 1 second if necessary. If aquired, update the file and release mutex
                If ($Mutex.WaitOne(1000)) { 
                    $Session.CoinNames | ConvertTo-Json | Out-File -Path ".\Data\CoinNames.json" -ErrorAction Ignore -Force
                    $Mutex.ReleaseMutex()
                }
            }
        }
    }
}

Function Get-CurrencyFromAlgorithm { 

    Param (
        [Parameter(Mandatory = $false)]
        [String]$Algorithm
    )

    Return $Session.CurrencyAlgorithm.$Algorithm
}

Function Get-EquihashCoinPers { 

    Param (
        [Parameter(Mandatory = $false)]
        [String]$Command = "",
        [Parameter(Mandatory = $false)]
        [String]$Currency = "",
        [Parameter(Mandatory = $false)]
        [String]$DefaultCommand = ""
    )

    If ($Currency) { 
        If ($Session.EquihashCoinPers[$Currency]) { 
            Return "$($Command)$($Session.EquihashCoinPers[$Currency])"
        }
    }

    Return $DefaultCommand
}

Function Get-PoolBaseName { 

    Param (
        [Parameter(Mandatory = $false)]
        [String[]]$PoolNames
    )

    Return ($PoolNames -replace "24hr$|coins$|coins24hr$|coinsplus$|plus$")
}

Function Get-Version { 
    Try { 
        $UpdateVersion = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/UselessGuru/UG-Miner/main/Version.txt" -TimeoutSec 15 -SkipCertificateCheck -Headers @{ "Cache-Control" = "no-cache" }).Content | ConvertFrom-Json

        $Session.CheckedForUpdate = [DateTime]::Now

        If ($Session.Branding.ProductLabel -and [System.Version]$UpdateVersion.Version -gt $Session.Branding.Version) { 
            If ($UpdateVersion.AutoUpdate) { 
                If ($Session.ConfigRunning.AutoUpdate) { 
                    Write-Message -Level Verbose "Version checker: New version $($UpdateVersion.Version) found. Starting update..."
                    [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
                    Write-Host " ✔" -ForegroundColor Green
                    Initialize-AutoUpdate -UpdateVersion $UpdateVersion
                }
                Else { 
                    Write-Message -Level Verbose "Version checker: New version $($UpdateVersion.Version) found. Auto Update is disabled in config - You must update manually."
                    [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
                    Write-Host " ✔" -ForegroundColor Green
                }
            }
            Else { 
                Write-Message -Level Verbose "Version checker: New version is available. $($UpdateVersion.Version) does not support auto-update. You must update manually."
                [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
                Write-Host " ✔" -ForegroundColor Green
            }
            If ($Session.ConfigRunning.ShowChangeLog) { 
                Start-Process "https://github.com/UselessGuru/UG-Miner/releases/tag/v$($UpdateVersion.Version)"
            }
        }
        Else { 
            Write-Message -Level Verbose "Version checker: $($Session.Branding.ProductLabel) $($Session.Branding.Version) is current - no update available."
            [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
            Write-Host " ✔" -ForegroundColor Green
        }
    }
    Catch { 
        Write-Message -Level Warn "Version checker could not contact update server."
        [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
        Write-Host " ✖" -ForegroundColor Red
    }
}

Function Initialize-AutoUpdate { 

    Param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UpdateVersion
    )

    Set-Location $Session.MainPath
    If (-not (Test-Path -LiteralPath ".\AutoUpdate" -PathType Container)) { New-Item -Path . -Name "AutoUpdate" -ItemType Directory | Out-Null }
    If (-not (Test-Path -LiteralPath ".\Logs" -PathType Container)) { New-Item -Path . -Name "Logs" -ItemType Directory | Out-Null }

    $UpdateScriptURL = "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/AutoUpdate/AutoUpdate.ps1"
    $UpdateScript = ".\AutoUpdate\AutoUpdate.ps1"
    $UpdateLog = ".\Logs\AutoUpdateLog_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").txt"

    # Download update script
    $CursorPosition = $Host.UI.RawUI.CursorPosition
    "Downloading update script..." | Tee-Object -FilePath $UpdateLog -Append | Write-Message -Level Verbose 
    Try { 
        Invoke-WebRequest -Uri $UpdateScriptURL -OutFile $UpdateScript -TimeoutSec 15
        [Console]::SetCursorPosition(28, $CursorPosition.y)
        Write-Host " ✔" -ForegroundColor Green
        $CursorPosition = $Host.UI.RawUI.CursorPosition
        "Starting update script..." | Tee-Object -FilePath $UpdateLog -Append | Write-Message -Level Verbose 
        [Console]::SetCursorPosition(25, $CursorPosition.y)
        Write-Host " ✔" -ForegroundColor Green
        . $UpdateScript
    }
    Catch { 
        [Console]::SetCursorPosition(29, $CursorPosition.y)
        Write-Host " ✖" -ForegroundColor Red
        "Downloading update script failed. Cannot complete auto-update :-(" | Tee-Object -FilePath $UpdateLog -Append | Write-Message -Level Error
    }
}

Function Start-LogReader { 

    If ((Test-Path -LiteralPath $Session.ConfigRunning.LogViewerExe -PathType Leaf) -and (Test-Path -LiteralPath $Session.ConfigRunning.LogViewerConfig -PathType Leaf)) { 
        $Session.LogViewerConfig = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Session.ConfigRunning.LogViewerConfig)
        $Session.LogViewerExe = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Session.ConfigRunning.LogViewerExe)
        If ($SnaketailProcess = (Get-CimInstance CIM_Process).Where({ $_.CommandLine -eq """$($Session.LogViewerExe)"" $($Session.LogViewerConfig)" })) { 
            # Activate existing Snaketail window
            $LogViewerMainWindowHandle = (Get-Process -Id $SnaketailProcess.ProcessId).MainWindowHandle
            If (@($LogViewerMainWindowHandle).Count -eq 1) { 
                Try { 
                    [Win32]::ShowWindowAsync($LogViewerMainWindowHandle, 6) | Out-Null # SW_MINIMIZE 
                    [Win32]::ShowWindowAsync($LogViewerMainWindowHandle, 9) | Out-Null # SW_RESTORE
                }
                Catch { }
            }
        }
        Else { 
            & $($Session.LogViewerExe) $($Session.LogViewerConfig)
        }
    }
}

Function Get-ObsoleteMinerStats { 
    # Used in AutoUpdate.ps1

    $StatFiles = @(Get-ChildItem ".\Stats\*" -Include "*_Hashrate.txt", "*_PowerConsumption.txt").BaseName
    $MinerNames = @(Get-ChildItem ".\Miners\*.ps1").BaseName

    Return @($StatFiles.Where({ (($_ -split "-")[0, 1] -join "-") -notin $MinerNames }))
}

Function Update-PoolWatchdog { 

    Param (
        [Parameter(Mandatory = $true)]
        $Pools
    )

    # Apply watchdog to pools
    If ($Session.ConfigRunning.Watchdog) { 
        # We assume that miner is up and running, so watchdog timer is not relevant
        If ($RelevantWatchdogTimers = $Session.WatchdogTimers.Where({ $_.MinerName -notin $Session.MinersRunning })) { 
            # Only pools with a corresponding watchdog timer object are of interest
            If ($RelevantPools = $Pools.Where({ $RelevantWatchdogTimers.PoolName -contains $_.Name })) { 

                # Add miner reason "Pool suspended by watchdog 'all algorithms'", only if more than one pool
                ($RelevantWatchdogTimers | Group-Object -Property PoolName).ForEach(
                    { 
                        If ($Session.ConfigRunning.PoolName.Count -gt 1 -and $_.Count -ge (2 * $Session.WatchdogCount * ($_.Group.DeviceNames | Sort-Object -Unique).Count + 1)) { 
                            $Group = $_.Group
                            If ($PoolsToSuspend = $RelevantPools.Where({ $_.Name -eq $Group[0].PoolName })) { 
                                $PoolsToSuspend.ForEach({ $_.Reasons.Add("Pool suspended by watchdog [all algorithms]") | Out-Null })
                                Write-Message -Level Warn "Pool '$($Group[0].PoolName) [all algorithms]' is suspended by watchdog until $(($Group.Kicked | Sort-Object -Top 1).AddSeconds($Session.WatchdogReset).ToLocalTime().ToString("T"))."
                            }
                        }
                    }
                )
                Remove-Variable Group, PoolsToSuspend -ErrorAction Ignore

                If ($RelevantPools = $RelevantPools.Where({ -not ($_.Reasons -match "Pool suspended by watchdog .+") })) { 
                    # Add miner reason "Pool suspended by watchdog 'Algorithm [Algorithm]'"
                    ($RelevantWatchdogTimers | Group-Object -Property PoolName, Algorithm).ForEach(
                        { 
                            If ($_.Count -ge 2 * $Session.WatchdogCount * ($_.Group.DeviceNames | Sort-Object -Unique).Count - 1) { 
                                $Group = $_.Group
                                If ($PoolsToSuspend = $RelevantPools.Where({ $_.Name -eq $Group[0].PoolName -and $_.Algorithm -eq $Group[0].Algorithm })) { 
                                    $PoolsToSuspend.ForEach({ $_.Reasons.Add("Pool suspended by watchdog [Algorithm $($Group[0].Algorithm)]") | Out-Null })
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

    Return $Pools
}

Function Test-Prime { 

    Param (
        [Parameter(Mandatory = $true)]
        [Double]$Number
    )

    Switch ($Number) { 
        ($Number -lt 2) { Return $false }
        ($Number -eq 2) { Return $true }
        Default { 
            $PowNumber = [Int64][Math]::Pow($Number, 0.5)
            For ([Int64]$I = 3; $I -lt $PowNumber; $I += 2) { 
                If ($Number % $I -eq 0) { Return $false }
            }
        }
    }
    Return $true
}

Function Get-AllDAGdata { 

    Param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$DAGdata
    )

    # Update on script start, once every 24hrs or if unable to get data from source
    $Url = "https://whattomine.com/coins.json"
    If ($DAGdata.Updated.$Url -lt $Session.ScriptStartTime -or $DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
        # Get block data for from whattomine.com
        Try { 
            Write-Message -Level Info "Loading DAG data from '$Url'..."
            $CurrencyDAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 5

            If ($CurrencyDAGdataResponse.coins.PSObject.Properties.Name) { 
                $CurrencyDAGdataResponse.coins.PSObject.Properties.Name.Where({ $CurrencyDAGdataResponse.coins.$_.tag -ne "NICEHASH" }).ForEach(
                    { 
                        If ($AlgorithmNorm = Get-Algorithm $CurrencyDAGdataResponse.coins.$_.algorithm) { 
                            $Currency = $CurrencyDAGdataResponse.coins.$_.tag
                            Add-CoinName -Algorithm $CurrencyDAGdataResponse.coins.$_.algorithm -Currency $Currency -CoinName $_
                            If ($AlgorithmNorm -match $Session.RegexAlgoHasDAG) { 
                                If ($CurrencyDAGdataResponse.coins.$_.last_block -ge $DAGdata.Currency.$Currency.BlockHeight) { 
                                    $CurrencyDAGdata = Get-DAGdata -BlockHeight $CurrencyDAGdataResponse.coins.$_.last_block -Currency $Currency -EpochReserve 2
                                    If ($CurrencyDAGdata.BlockHeight -and $CurrencyDAGdata.Algorithm -match $Session.RegexAlgoHasDAG) { 
                                        $CurrencyDAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                                        $CurrencyDAGdata | Add-Member Url $Url -Force
                                        $DAGdata.Currency | Add-Member $Currency $CurrencyDAGdata -Force
                                    }
                                    Else { 
                                        Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                                    }
                                }
                            }
                        }
                    }
                )
                $DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
            }
            Else { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
            }
        }
        Catch { 
            Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
        }
    }

    # Update on script start, once every 24hrs or if unable to get data from source
    $Url = "https://minerstat.com/dag-size-calculator"
    If ($DAGdata.Updated.$Url -lt $Session.ScriptStartTime -or $DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
        # Get block data from Minerstat
        Try { 
            Write-Message -Level Info "Loading DAG data from '$Url'..."
            $CurrencyDAGdataResponse = Invoke-WebRequest -Uri $Url -TimeoutSec 5 # PWSH 6+ no longer supports basic parsing -> parse text
            If ($CurrencyDAGdataResponse.statuscode -eq 200) { 
                (($CurrencyDAGdataResponse.Content -split "\n" -replace "`"", "'").Where({ $_ -like "<div class='block' title='Current block height of *" })).ForEach(
                    { 
                        $Currency = $_ -replace "^<div class='block' title='Current block height of " -replace "'>.*$"
                        If ($Currency -notin @("ETF")) { 
                            # ETF has invalid DAG data of 444GiB
                            $BlockHeight = [Math]::Floor(($_ -replace "^<div class='block' title='Current block height of $Currency'>" -replace "</div>"))
                            If ($Session.CurrencyAlgorithm[$Currency] -and $BlockHeight -ge $DAGdata.Currency.$Currency.BlockHeight) { 
                                $CurrencyDAGdata = Get-DAGdata -BlockHeight $BlockHeight -Currency $Currency -EpochReserve 2
                                If ($CurrencyDAGdata.Epoch -and $CurrencyDAGdata.Algorithm -match $Session.RegexAlgoHasDAG) { 
                                    $CurrencyDAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                                    $CurrencyDAGdata | Add-Member Url $Url -Force
                                    $DAGdata.Currency | Add-Member $Currency $CurrencyDAGdata -Force
                                }
                                Else { 
                                    Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                                }
                            }
                        }
                    }
                )
                $DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
            }
            Else { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
            }
        }
        Catch { 
            Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
        }
    }

    # Update on script start, once every 24hrs or if unable to get data from source
    $Url = "https://prohashing.com/api/v1/currencies"
    If ($DAGdata.Updated.$Url -lt $Session.ScriptStartTime -or $DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
        # Get block data from ProHashing
        Try { 
            Write-Message -Level Info "Loading DAG data from '$Url'..."
            $CurrencyDAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec $Config.PoolsConfig.ProHashing.PoolAPItimeout

            If ($CurrencyDAGdataResponse.code -eq 200) { 
                $CurrencyDAGdataResponse.data.PSObject.Properties.Name.Where({ $CurrencyDAGdataResponse.data.$_.enabled -and $CurrencyDAGdataResponse.data.$_.height -and ($Session.RegexAlgoHasDAG -match (Get-Algorithm $CurrencyDAGdataResponse.data.$_.algo) -or $DAGdata.Currency.psBase.Keys -contains $_) }).ForEach(
                    { 
                        If ($Session.CurrencyAlgorithm[$Currency]) { 
                            If ($CurrencyDAGdataResponse.data.$_.height -gt $DAGdata.Currency.$_.BlockHeight) { 
                                $CurrencyDAGdata = Get-DAGdata -BlockHeight $CurrencyDAGdataResponse.data.$_.height -Currency $_ -EpochReserve 2
                                If ($CurrencyDAGdata.Epoch -and $CurrencyDAGdata.Algorithm -match $Session.RegexAlgoHasDAG) { 
                                    $CurrencyDAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                                    $CurrencyDAGdata | Add-Member Url $Url -Force
                                    $DAGdata.Currency | Add-Member $_ $CurrencyDAGdata -Force
                                }
                                Else { 
                                    Write-Message -Level Warn "Failed to load DAG data for '$_' from '$Url'."
                                }
                            }
                        }
                    }
                )
                $DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
            }
            Else { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
            }
        }
        Catch { 
            Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
        }
    }

    # Update on script start, once every 24hrs or if unable to get data from source
    # ZPool also supplies TLS DAG data.
    If (-not ($Session.ConfigRunning.PoolName -match "^ZPool.*")) { 
        If ($Session.CurrencyAlgorithm[$Currency]) { 
            $Currency = "TLS"
            $Url = "https://telestai.cryptoscope.io/api/getblockcount"
            If (-not $DAGdata.Currency.$Currency.BlockHeight -or $DAGdata.Updated.$Url -lt $Session.ScriptStartTime -or $DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
                # Get block data from StakeCube block explorer
                Try { 
                    Write-Message -Level Info "Loading DAG data from '$Url'..."
                    $CurrencyDAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 15 -SkipCertificateCheck
                    If ($CurrencyDAGdataResponse.blockcount -ge $DAGdata.Currency.$Currency.BlockHeight) { 
                        $CurrencyDAGdata = Get-DAGdata -BlockHeight $CurrencyDAGdataResponse.blockcount -Currency $Currency -EpochReserve 2
                        If ($CurrencyDAGdata.Epoch) { 
                            $CurrencyDAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                            $CurrencyDAGdata | Add-Member Url $Url -Force
                            $DAGdata.Currency | Add-Member $Currency $CurrencyDAGdata -Force
                            $DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
                        }
                        Else { 
                            Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                        }
                    }
                }
                Catch { 
                    Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
                }
            }
        }
    }

    # ZPool also supplies SCC DAG data
    If (-not ($Session.ConfigRunning.PoolName -match "ZPool.*")) { 
        # Update on script start, once every 24hrs or if unable to get data from source
        $Currency = "SCC"
        If ($Session.CurrencyAlgorithm[$Currency]) { 
            $Url = "https://www.coinexplorer.net/api/v1/SCC/block/latest"
            If (-not $DAGdata.Currency.$Currency.BlockHeight -or $DAGdata.Updated.$Url -lt $Session.ScriptStartTime -or $DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
                # Get block data from StakeCube block explorer
                Try { 
                    Write-Message -Level Info "Loading DAG data from '$Url'..."
                    $CurrencyDAGdataResponse = (Invoke-RestMethod -Uri $Url -TimeoutSec 15 -SkipCertificateCheck).result.height
                    If ($CurrencyDAGdataResponse -ge $DAGdata.Currency.$Currency.BlockHeight) { 
                        $CurrencyDAGdata = Get-DAGdata -BlockHeight $CurrencyDAGdataResponse -Currency $Currency -EpochReserve 2
                        If ($CurrencyDAGdata.Epoch) { 
                            $CurrencyDAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                            $CurrencyDAGdata | Add-Member Url $Url -Force
                            $DAGdata.Currency | Add-Member $Currency $CurrencyDAGdata -Force
                            $DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
                        }
                        Else { 
                            Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                        }
                    }
                }
                Catch { 
                    Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
                }
            }
        }
    }

    # Update on script start, once every 24hrs or if unable to get data from source
    $Currency = "BLOCX"
    If ($Session.CurrencyAlgorithm[$Currency]) { 
        $Url = "https://blocxscan.com/api/v2/stats"
        If (-not $DAGdata.Currency.$Currency.BlockHeight -or $DAGdata.Updated.$Url -lt $Session.ScriptStartTime -or $DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
            # Get block data from BLOCX block explorer
            Try { 
                Write-Message -Level Info "Loading DAG data from '$Url'..."
                $CurrencyDAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 15 -SkipCertificateCheck
                If ([UInt64]$CurrencyDAGdataResponse.total_blocks -ge $DAGdata.Currency.$Currency.BlockHeight) { 
                    $CurrencyDAGdata = Get-DAGdata -BlockHeight $CurrencyDAGdataResponse.total_blocks -Currency $Currency -EpochReserve 2
                    If ($CurrencyDAGdata.DAGsize) { 
                        $CurrencyDAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                        $CurrencyDAGdata | Add-Member Url $Url -Force
                        $DAGdata.Currency | Add-Member $Currency $CurrencyDAGdata -Force
                        $DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
                    }
                    Else { 
                        Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                    }
                }
            }
            Catch { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
            }
        }
    }

    # ZPool also supplies PHI DAG data
    If (-not ($Session.ConfigRunning.PoolName -match "^ZPool.*")) { 
        # Update on script start, once every 24hrs or if unable to get data from source
        $Currency = "PHI"
        If ($Session.CurrencyAlgorithm[$Currency]) { 
            $Url = "https://explorer.phicoin.net/api/getblockcount"
            If (-not $DAGdata.Currency.$Currency.BlockHeight -or $DAGdata.Updated.$Url -lt $Session.ScriptStartTime -or $DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
                # Get block data from PHI block explorer
                Try { 
                    Write-Message -Level Info "Loading DAG data from '$Url'..."
                    $CurrencyDAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 15 -SkipCertificateCheck
                    If ($CurrencyDAGdataResponse -ge $DAGdata.Currency.$Currency.BlockHeight) { 
                        $CurrencyDAGdata = Get-DAGdata -BlockHeight $CurrencyDAGdataResponse -Currency $Currency -EpochReserve 0
                        If ($CurrencyDAGdata.Epoch -ge 0) { 
                            $CurrencyDAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                            $CurrencyDAGdata | Add-Member Url $Url -Force
                            $DAGdata.Currency | Add-Member $Currency $CurrencyDAGdata -Force
                            $DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
                        }
                        Else { 
                            Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                        }
                    }
                }
                Catch { 
                    Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
                }
            }
        }
    }

    # Zpool also supplies MEWC DAG data
    If (-not ($Session.ConfigRunning.PoolName -match "^ZPool.+")) { 
        # Update on script start, once every 24hrs or if unable to get data from source
        $Currency = "MEWC"
        If ($Session.CurrencyAlgorithm[$Currency]) { 
            $Url = "https://mewc.cryptoscope.io/api/getblockcount"
            If (-not $DAGdata.Currency.$Currency.BlockHeight -or $DAGdata.Updated.$Url -lt $Session.ScriptStartTime -or $DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
                # Get block data from MeowCoin block explorer
                Try { 
                    Write-Message -Level Info "Loading DAG data from '$Url'..."
                    $CurrencyDAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 15 -SkipCertificateCheck
                    If ($CurrencyDAGdataResponse.blockcount -ge $DAGdata.Currency.$Currency.BlockHeight) { 
                        $CurrencyDAGdata = Get-DAGdata -BlockHeight $CurrencyDAGdataResponse.blockcount -Currency $Currency -EpochReserve 2
                        If ($CurrencyDAGdata.Epoch -ge 0) { 
                            $CurrencyDAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                            $CurrencyDAGdata | Add-Member Url $Url -Force
                            $DAGdata.Currency | Add-Member $Currency $CurrencyDAGdata -Force
                            $DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
                        }
                        Else { 
                            Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                        }
                    }
                }
                Catch { 
                    Write-Message -Level Warn "Failed to load DAG data from '$Url' - Error: $($_.Exception.Message -replace "^.+: " -replace "\.$")."
                }
            }
        }
    }

    If ($DAGdata.Updated.PSObject.Properties.Name.Where({ $DAGdata.Updated.$_ -gt $Session.Timer })) { 
        # At least one DAG was updated, get maximum DAG size per algorithm
        $CurrencyDAGdataKeys = @($DAGdata.Currency.PSObject.Properties.Name) # Store as array to avoid error 'An error occurred while enumerating through a collection: Collection was modified; enumeration operation may not execute.'

        ForEach ($Algorithm in @($CurrencyDAGdataKeys.ForEach({ $DAGdata.Currency.$_.Algorithm }) | Select-Object -Unique)) { 
            $DAGdata.Algorithm | Add-Member $Algorithm (
                [PSCustomObject]@{ 
                    BlockHeight = [Int]($CurrencyDAGdataKeys.Where({ $DAGdata.Currency.$_.Algorithm -eq $Algorithm }).ForEach({ $DAGdata.Currency.$_.BlockHeight }) | Measure-Object -Maximum).Maximum
                    DAGsize     = [Int64]($CurrencyDAGdataKeys.Where({ $DAGdata.Currency.$_.Algorithm -eq $Algorithm }).ForEach({ $DAGdata.Currency.$_.DAGsize }) | Measure-Object -Maximum).Maximum
                    Epoch       = [Int]($CurrencyDAGdataKeys.Where({ $DAGdata.Currency.$_.Algorithm -eq $Algorithm }).ForEach({ $DAGdata.Currency.$_.Epoch }) | Measure-Object -Maximum).Maximum
                }
            ) -Force
            $DAGdata.Algorithm.$Algorithm | Add-Member Currency ([String]($CurrencyDAGdataKeys.Where({ $DAGdata.Currency.$_.DAGsize -eq $DAGdata.Algorithm.$Algorithm.DAGsize -and $DAGdata.Currency.$_.Algorithm -eq $Algorithm }))) -Force
            $DAGdata.Algorithm.$Algorithm | Add-Member CoinName ([String]($Session.CoinNames[$DAGdata.Algorithm.$Algorithm.Currency])) -Force
        }

        # Add default '*' (equal to highest)
        $DAGdata.Currency | Add-Member "*" (
            [PSCustomObject]@{ 
                BlockHeight = [Int]($CurrencyDAGdataKeys.ForEach({ $DAGdata.Currency.$_.BlockHeight }) | Measure-Object -Maximum).Maximum
                Currency    = "*"
                DAGsize     = [Int64]($CurrencyDAGdataKeys.ForEach({ $DAGdata.Currency.$_.DAGsize }) | Measure-Object -Maximum).Maximum
                Epoch       = [Int]($CurrencyDAGdataKeys.ForEach({ $DAGdata.Currency.$_.Epoch }) | Measure-Object -Maximum).Maximum
            }
        ) -Force
        $DAGdata = $DAGdata | Get-SortedObject
        $DAGdata | ConvertTo-Json -Depth 5 | Out-File -LiteralPath ".\Data\DAGdata.json" -Force
    }

    Return $DAGdata
}

Function Get-DAGdata { 

    Param (
        [Parameter(Mandatory = $true)]
        [Double]$BlockHeight,
        [Parameter(Mandatory = $true)]
        [String]$Currency,
        [Parameter(Mandatory = $false)]
        [Int16]$EpochReserve = 0
    )

    If ($Currency -eq "BLOCX") { 
        Return [PSCustomObject]@{ 
            Algorithm   = $Session.CurrencyAlgorithm[$Currency]
            BlockHeight = [Int]$BlockHeight
            CoinName    = [String]$Session.CoinNames[$Currency]
            DAGsize     = [Int64]2GB
            Epoch       = [UInt16]0
        }
    }
    ElseIf ($Algorithm = $Session.CurrencyAlgorithm[$Currency]) { 
        $Epoch = Get-DAGepoch -BlockHeight $BlockHeight -Algorithm $Algorithm -EpochReserve $EpochReserve

        Return [PSCustomObject]@{ 
            Algorithm   = $Algorithm
            BlockHeight = [Int]$BlockHeight
            CoinName    = [String]$Session.CoinNames[$Currency]
            DAGsize     = [Int64](Get-DAGSize -Epoch $Epoch -Currency $Currency)
            Epoch       = [UInt16]$Epoch
        }
    }

    Return [PSCustomObject]@{ }
}

Function Get-DAGsize { 

    Param (
        [Parameter(Mandatory = $true)]
        [Double]$Epoch,
        [Parameter(Mandatory = $true)]
        [String]$Currency
    )

    Switch ($Currency) { 
        "CFX" { 
            $DatasetBytesInit = 4GB
            $DatasetBytesGrowth = 16MB
            $MixBytes = 256
            $Size = $DatasetBytesInit + ($DatasetBytesGrowth * $Epoch) - $MixBytes
            While (-not (Test-Prime ($Size / $MixBytes))) { 
                $Size -= 2 * $MixBytes
            }
            Break
        }
        "ERG" { 
            # https://github.com/RainbowMiner/RainbowMiner/issues/2102
            $Size = 64MB
            $BlockHeight = [Math]::Min($BlockHeight, 4198400)
            If ($BlockHeight -ge 614400) { 
                $P = [Math]::Floor(($BlockHeight - 614400) / 51200) + 1
                While ($P-- -gt 0) { 
                    $Size = [Math]::Floor($Size / 100) * 105
                }
            }
            $Size *= 31
            Break
        }
        "EVR" { 
            $DatasetBytesInit = 3GB
            $DatasetBytesGrowth = 8MB
            $MixBytes = 128
            $Size = $DatasetBytesInit + ($DatasetBytesGrowth * $Epoch) - $MixBytes
            While (-not (Test-Prime ($Size / $MixBytes))) { 
                $Size -= 2 * $MixBytes
            }
            Break
        }
        "IRON" { 
            # IRON (FishHash) has a static DAG size of 4608MB (Ethash epoch 448, https://github.com/iron-fish/fish-hash/blob/main/FishHash.pdf Chapter 4)
            $Size = 4608MB
            Break
        }
        "KLS" { 
            # KLS (KarlsenHash) is based on FishHash and has a static DAG size of 4608MB (Ethash epoch 448, https://github.com/iron-fish/fish-hash/blob/main/FishHash.pdf Chapter 4)
            $Size = 4608MB
            Break
        }
        "MEWC" { 
            If ($Epoch -ge 110) { $Epoch *= 4 } # https://github.com/Meowcoin-Foundation/meowpowminer/blob/6e1f38c1550ab23567960699ba1c05aad3513bcd/libcrypto/ethash.hpp#L48 & https://github.com/Meowcoin-Foundation/meowpowminer/blob/6e1f38c1550ab23567960699ba1c05aad3513bcd/libcrypto/ethash.cpp#L249C1-L254C6
            $DatasetBytesInit = 1GB
            $DatasetBytesGrowth = 8MB
            $MixBytes = 128
            $Size = $DatasetBytesInit + ($DatasetBytesGrowth * $Epoch) - $MixBytes
            While (-not (Test-Prime ($Size / $MixBytes))) { 
                $Size -= 2 * $MixBytes
            }
            Break
        }
        # "PHI" { 
        #     # https://phicoin.net/docs/Phicoin/algorithm#improved-dag-growth-mechanism
        #     $DatasetBytesInit = 4GB
        #     $Size = $DatasetBytesInit * [Math]::Pow(1.25, $Epoch)
        #     Break
        # }
        Default { 
            $DatasetBytesInit = 1GB
            $DatasetBytesGrowth = 8MB
            $MixBytes = 128
            $Size = $DatasetBytesInit + ($DatasetBytesGrowth * $Epoch) - $MixBytes
            While (-not (Test-Prime ($Size / $MixBytes))) { 
                $Size -= 2 * $MixBytes
            }
        }
    }

    Return [Int64]$Size
}

Function Get-DAGepoch { 

    Param (
        [Parameter(Mandatory = $true)]
        [Double]$BlockHeight,
        [Parameter(Mandatory = $true)]
        [String]$Algorithm,
        [Parameter(Mandatory = $true)]
        [UInt16]$EpochReserve
    )

    Switch ($Algorithm) { 
        "Autolykos2" { $BlockHeight -= 416768; Break } # Epoch 0 starts @ 417792
        "FishHash"   { Return 448 } # IRON (FishHash) has static DAG size of 4608MB (Ethash epoch 448, https://github.com/iron-fish/fish-hash/blob/main/FishHash.pdf Chapter 4)
        "PhiHash"    { Return [Math]::Floor(((Get-Date) - [DateTime]::ParseExact("11/06/2023", "MM/dd/yyyy", $null)).TotalDays / 365.25) -1 }
        Default      { }
    }

    Return [Math]::Floor($BlockHeight / (Get-DAGepochLength -BlockHeight $BlockHeight -Algorithm $Algorithm)) + $EpochReserve
}

Function Get-DAGepochLength { 

    Param (
        [Parameter(Mandatory = $true)]
        [Double]$BlockHeight,
        [Parameter(Mandatory = $true)]
        [String]$Algorithm
    )

    Switch ($Algorithm) { 
        "Autolykos2"      { Return 1024 }
        "EtcHash"         { If ($BlockHeight -ge 11700000) { Return 60000 } Else { Return 30000 } }
        "EthashSHA256"    { Return 4000 }
        "EvrProgPow"      { Return 12000 }
        "FiroPow"         { Return 1300 }
        "KawPow"          { Return 7500 }
        "MeowPow"         { Return 7500 } # https://github.com/Meowcoin-Foundation/meowpowminer/blob/6e1f38c1550ab23567960699ba1c05aad3513bcd/libcrypto/ethash.hpp#L32
        "Octopus"         { Return 524288 }
        "PhiHash"         { Return 7500 } # https://github.com/PhicoinProject/phihashminer_v2/blob/main/README.md
        "SCCpow"          { Return 3240 } # https://github.com/stakecube/sccminer/commit/16bdfcaccf9cba555f87c05f6b351e1318bd53aa#diff-200991710fe4ce846f543388b9b276e959e53b9bf5c7b7a8154b439ae8c066aeR32
        "ProgPowTelestai" { Return 12000 }
        Default           { Return 30000 }
    }
}

Function Out-DataTable { 
    # based on http://thepowershellguy.com/blogs/posh/archive/2007/01/21/powershell-gui-scripblock-monitor-script.aspx

    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject[]]$InputObject
    )

    Begin { 
        $DataTable = [Data.DataTable]::new()
        $First = $true
    }
    Process { 
        ForEach ($Object in $InputObject) { 
            $DataRow = $DataTable.NewRow()
            ForEach ($Property in $Object.PSObject.Properties) { 
                If ($First) { 
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
    End { 
        Return @(, $DataTable)
    }
}

Function Get-Median { 

    Param (
        [Parameter(Mandatory = $true)]
        [Double[]]$Numbers
    )

    $Numbers = $Numbers | Sort-Object
    $Count = $Numbers.Count

    If ($Count % 2 -eq 0) { 
        # Even number of elements, median is the average of the two middle elements
        Return ($Numbers[$Count / 2] + $Numbers[$Count / 2 - 1]) / 2
    }
    Else { 
        # Odd number of elements, median is the middle element
        Return $Numbers[$Count / 2]
    }
}

Function Hide-Console { 
    # https://stackoverflow.com/questions/3571627/show-hide-the-console-window-of-a-c-sharp-console-application
    If ($host.Name -eq "ConsoleHost") { 
        If ($ConsoleWindowHandle = [Console.Window]::GetConsoleWindow()) { 
            # 0 = SW_HIDE
            [Console.Window]::ShowWindow($ConsoleWindowHandle, 0) | Out-Null
        }
    }
}

Function Show-Console { 
    # https://stackoverflow.com/questions/3571627/show-hide-the-console-window-of-a-c-sharp-console-application
    If ($host.Name -eq "ConsoleHost") { 
        If ($ConsoleWindowHandle = [Console.Window]::GetConsoleWindow()) { 
            # 5 = SW_SHOW
            [Console.Window]::ShowWindow($ConsoleWindowHandle, 5) | Out-Null
        }
    }
}

Function Get-MemoryUsage { 

    $MemUsageByte = [System.GC]::GetTotalMemory("forcefullcollection")
    $MemUsageMB = $MemUsageByte / 1MB
    $DiffBytes = $MemUsageByte - $Script:LastMemoryUsageByte
    $DiffText = ""
    $Sign = ""

    If ( $Script:LastMemoryUsageByte -ne 0) { 
        If ($DiffBytes -ge 0) { $Sign = "+" }
        $DiffText = ", $Sign$DiffBytes"
    }

    # Save last value in script global variable
    $Script:LastMemoryUsageByte = $MemUsageByte

    Return ("Memory usage {0:n1} MB ({1:n0} Bytes{2})" -f $MemUsageMB, $MemUsageByte, $Difftext)
}

Function Initialize-Environment { 

    # Create directories
    If (-not (Test-Path -LiteralPath ".\Cache" -PathType Container)) { New-Item -Path . -Name "Cache" -ItemType Directory | Out-Null }
    If (-not (Test-Path -LiteralPath ".\Config" -PathType Container)) { New-Item -Path . -Name "Config" -ItemType Directory | Out-Null }
    If (-not (Test-Path -LiteralPath ".\Logs" -PathType Container)) { New-Item -Path . -Name "Logs" -ItemType Directory | Out-Null }
    If (-not (Test-Path -LiteralPath ".\Stats" -PathType Container)) { New-Item -Path . -Name "Stats" -ItemType Directory -Force | Out-Null }

    # Check if all required files are present
    If (-not (Get-ChildItem -LiteralPath $PWD\Balances)) { 
        Write-Error "Terminating error - cannot continue! No files in folder '\Balances'. Please restore the folder from your original download."
        (New-Object -ComObject Wscript.Shell).Popup("No files in folder '\Balances'.`nPlease restore the folder from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
        Start-Sleep -Seconds 5
        Exit
    }
    If (-not (Get-ChildItem -LiteralPath $PWD\Brains)) { 
        Write-Error "Terminating error - cannot continue! No files in folder '\Brains'. Please restore the folder from your original download."
        (New-Object -ComObject Wscript.Shell).Popup("No files in folder '\Brains'.`nPlease restore the folder from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
        Start-Sleep -Seconds 5
        Exit
    }
    If (-not (Get-ChildItem -LiteralPath $PWD\Data)) { 
        Write-Error "Terminating error - cannot continue! No files in folder '\Data'. Please restore the folder from your original download."
        (New-Object -ComObject Wscript.Shell).Popup("No files in folder '\Data'.`nPlease restore the folder from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
        Start-Sleep -Seconds 5
        Exit
    }
    If (-not (Get-ChildItem -LiteralPath $PWD\Miners)) { 
        Write-Error "Terminating error - cannot continue! No files in folder '\Miners'. Please restore the folder from your original download."
        (New-Object -ComObject Wscript.Shell).Popup("No files in folder '\Miners'.`nPlease restore the folder from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
        Start-Sleep -Seconds 5
        Exit
    }
    If (-not (Get-ChildItem -LiteralPath $PWD\Pools)) { 
        Write-Error "Terminating error - cannot continue! No files in folder '\Pools'. Please restore the folder from your original download."
        (New-Object -ComObject Wscript.Shell).Popup("No files in folder '\Pools'.`nPlease restore the folder from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
        Start-Sleep -Seconds 5
        Exit
    }
    If (-not (Get-ChildItem -LiteralPath $PWD\Web)) { 
        Write-Error "Terminating error - cannot continue! No files in folder '\Web'. Please restore the folder from your original download."
        (New-Object -ComObject Wscript.Shell).Popup("No files in folder '\Web'.`nPlease restore the folder from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
        Start-Sleep -Seconds 5
        Exit
    }

    # Load donation as sorted case insensitive hash table
    If (Test-Path -LiteralPath "$PWD\Data\DonationData.json") { $Session.DonationData = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\DonationData.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
    If (-not $Session.DonationData) { 
        Write-Error "Terminating error - cannot continue! File '.\Data\DonationData.json' is not a valid JSON file. Please restore it from your original download."
        (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\DonationData.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
        Start-Sleep -Seconds 5
        Exit
    }
    Write-Host "Loaded donation data."

    # Load donation log
    If (Test-Path -LiteralPath "$PWD\Logs\DonationLog.csv") { $Session.DonationLog = @([System.IO.File]::ReadAllLines("$PWD\Logs\DonationLog.csv") | ConvertFrom-Csv -ErrorAction Ignore) }
    If (-not $Session.DonationLog) { 
        $Session.DonationLog = @()
    }
    Else { 
        Write-Host "Loaded donation log."
    }

    # Load algorithm list as sorted case insensitive hash table
    If (Test-Path -LiteralPath "$PWD\Data\Algorithms.json") { $Session.Algorithms = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\Algorithms.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
    If (-not $Session.Algorithms.Keys) { 
        Write-Error "Terminating error - cannot continue! File '.\Data\Algorithms.json' is not a valid JSON file. Please restore it from your original download."
        (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\Algorithms.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
        Start-Sleep -Seconds 5
        Exit
    }

    # Load coin names as sorted case insensitive hash table
    If (Test-Path -LiteralPath "$PWD\Data\CoinNames.json") { $Session.CoinNames = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\CoinNames.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
    If (-not $Session.CoinNames.Keys) { 
        Write-Error "Terminating error - cannot continue! File '.\Data\CoinNames.json' is not a valid JSON file. Please restore it from your original download."
        (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\CoinNames.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
        Start-Sleep -Seconds 5
        Exit
    }

    # Load currency algorithm data as sorted case insensitive hash table
    If (Test-Path -LiteralPath "$PWD\Data\CurrencyAlgorithm.json") { $Session.CurrencyAlgorithm = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\CurrencyAlgorithm.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
    If (-not $Session.CurrencyAlgorithm.Keys) { 
        Write-Error "Terminating error - cannot continue! File '.\Data\CurrencyAlgorithm.json' is not a valid JSON file. Please restore it from your original download."
        (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\CurrencyAlgorithm.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
        Start-Sleep -Seconds 5
        Exit
    }

    # Load EquihashCoinPers data as sorted case insensitive hash table
    If (Test-Path -LiteralPath "$PWD\Data\EquihashCoinPers.json") { $Session.EquihashCoinPers = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\EquihashCoinPers.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
    If (-not $Session.EquihashCoinPers) { 
        Write-Error "Terminating error - cannot continue! File '.\Data\EquihashCoinPers.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\EquihashCoinPers.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
        Start-Sleep -Seconds 5
        Exit
    }
    Write-Host "Loaded algorithm & coin database."

    # Load regions as sorted case insensitive hash table
    If (Test-Path -LiteralPath "$PWD\Data\Regions.json") { 
        $Session.Regions = [Ordered]@{ } # as case insensitive hash table
        ([System.IO.File]::ReadAllLines("$PWD\Data\Regions.json") | ConvertFrom-Json).PSObject.Properties.ForEach({ $Session.Regions[$_.Name] = @($_.Value) })
    }
    If (-not $Session.Regions.Keys) { 
        Write-Error "Terminating error - cannot continue! File '.\Data\Regions.json' is not a valid JSON file. Please restore it from your original download."
        (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\Regions.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
        Start-Sleep -Seconds 5
        Exit
    }
    Write-Host "Loaded regions database."

    # Load FIAT currencies list as sorted case insensitive hash table
    If (Test-Path -LiteralPath "$PWD\Data\FIATcurrencies.json") { $Session.FIATcurrencies = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\FIATcurrencies.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
    If (-not $Session.FIATcurrencies) { 
        Write-Error "Terminating error - cannot continue! File '.\Data\FIATcurrencies.json' is not a valid JSON file. Please restore it from your original download."
        (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\FIATcurrencies.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
        Start-Sleep -Seconds 5
        Exit
    }
    Write-Host "Loaded fiat currencies database."

    # Load unprofitable algorithms as sorted case insensitive hash table, cannot use one-liner (Error 'Cannot find an overload for "new" and the argument count: "2"')
    $Session.UnprofitableAlgorithms = [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase)
    If (Test-Path -LiteralPath "$PWD\Data\UnprofitableAlgorithms.json") { 
        $UnprofitableAlgorithms = [System.IO.File]::ReadAllLines("$PWD\Data\UnprofitableAlgorithms.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject
        $UnprofitableAlgorithms.Keys.ForEach({ $Session.UnprofitableAlgorithms.$_ = $UnprofitableAlgorithms.$_ })
        Remove-Variable UnprofitableAlgorithms
    }
    If (-not $Session.UnprofitableAlgorithms.Count) { 
        Write-Error "Error loading list of unprofitable algorithms. File '.\Data\UnprofitableAlgorithms.json' is not a valid $($Session.Branding.ProductLabel) JSON data file. Please restore it from your original download."
        (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\UnprofitableAlgorithms.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
        Start-Sleep -Seconds 5
        Exit
    }
    Write-Host "Loaded list of unprofitable algorithms."

    # Load DAG data, if not available it will get recreated
    If (Test-Path -LiteralPath "$PWD\Data\DAGdata.json" ) { $Session.DAGdata = [System.IO.File]::ReadAllLines("$PWD\Data\DAGdata.json") | ConvertFrom-Json -ErrorAction Ignore | Get-SortedObject }
    If (-not $Session.DAGdata) { 
        Write-Error "Error loading list of DAG data. File '.\Data\DAGdata.json' is not a valid $($Session.Branding.ProductLabel) JSON data file. Please restore it from your original download."
        (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\DAGdata.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
        Start-Sleep -Seconds 5
        Exit
    }
    Write-Host "Loaded DAG database."

    # Load PoolsLastUsed data as sorted case insensitive hash table
    If (Test-Path -LiteralPath "$PWD\Data\PoolsLastUsed.json") { $Session.PoolsLastUsed = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\PoolsLastUsed.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
    If (-not $Session.PoolsLastUsed.psBase.Keys) { 
        $Session.PoolsLastUsed = @{ }
    }
    Else { 
        Write-Host "Loaded pools last used data."
    }

    # Load AlgorithmsLastUsed data as sorted case insensitive hash table
    If (Test-Path -LiteralPath "$PWD\Data\AlgorithmsLastUsed.json") { $Session.AlgorithmsLastUsed = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\AlgorithmsLastUsed.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
    If (-not $Session.AlgorithmsLastUsed.psBase.Keys) { 
        $Session.AlgorithmsLastUsed = @{ }
    }
    Else { 
        Write-Host "Loaded algorithm last used data."
    }

    # Load MinersLastUsed data as sorted case insensitive hash table
    If (Test-Path -LiteralPath "$PWD\Data\MinersLastUsed.json") { $Session.MinersLastUsed = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\MinersLastUsed.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
    If (-not $Session.MinersLastUsed.psBase.Keys) { 
        $Session.MinersLastUsed = @{ }
    }
    Else { 
        Write-Host "Loaded algorithm last used data."
    }

    # Load EarningsChart data to make it available early in GUI
    If (Test-Path -LiteralPath "$PWD\Cache\EarningsChartData.json" -PathType Leaf) { $Session.EarningsChartData = [System.IO.File]::ReadAllLines("$PWD\Cache\EarningsChartData.json") | ConvertFrom-Json }
    If (-not $Session.EarningsChartData.Earnings) { 
        $Session.EarningsChartData = @{ }
    }
    Else { 
        Write-Host "Loaded earnings chart data."
    }

    # Load Balances data to make it available early in GUI
    If (Test-Path -LiteralPath "$PWD\Cache\Balances.json" -PathType Leaf) { $Session.Balances = [System.IO.File]::ReadAllLines("$PWD\Cache\Balances.json") | ConvertFrom-Json }
    If (-not $Session.Balances.PSObject.Properties.Name) { 
        $Session.Balances = @{ }
    }
    Else { Write-Host "Loaded balances data." }

    # Load NVidia GPU architecture table
    If (Test-Path -LiteralPath "$PWD\Data\GPUArchitectureNvidia.json") { $Session.GPUArchitectureDbNvidia = [System.IO.File]::ReadAllLines("$PWD\Data\GPUArchitectureNvidia.json") | ConvertFrom-Json -ErrorAction Ignore }
    If (-not $Session.GPUArchitectureDbNvidia) { 
        Write-Message -Level Error "Terminating error - cannot continue! File '.\Data\GPUArchitectureNvidia.json' is not a valid JSON file. Please restore it from your original download."
        (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\GPUArchitectureNvidia.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
        Start-Sleep -Seconds 5
        Exit
    }
    Else { Write-Host "Loaded NVidia GPU architecture table." }

    # Load AMD GPU architecture table
    If (Test-Path -LiteralPath "$PWD\Data\GPUArchitectureAMD.json") { $Session.GPUArchitectureDbAMD = [System.IO.File]::ReadAllLines("$PWD\Data\GPUArchitectureAMD.json") | ConvertFrom-Json -ErrorAction Ignore }
    If (-not $Session.GPUArchitectureDbAMD) { 
        Write-Message -Level Error "Terminating error - cannot continue! File '.\Data\GPUArchitectureAMD.json' is not a valid JSON file. Please restore it from your original download."
        (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\GPUArchitectureAMD.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
        Start-Sleep -Seconds 5
        Exit
    }
    Else { Write-Host "Loaded AMD GPU architecture table." }

    $Session.BalancesCurrencies = @($Session.Balances.PSObject.Properties.Name.ForEach({ $Session.Balances.$_.Currency }) | Sort-Object -Unique)
}

Function Restart-APIserver { 
    Stop-APIserver
    Start-APIserver
}

Function Start-APIserver { 

    If ($Session.ConfigRunning.APIport -ne $Session.APIport) { 
        Stop-APIserver
    }

    If (-not $Global:APIrunspace) { 

        $TCPclient = [System.Net.Sockets.TCPClient]::new()
        $AsyncResult = $TCPclient.BeginConnect("127.0.0.1", $Session.ConfigRunning.APIport, $null, $null)
        If ($AsyncResult.AsyncWaitHandle.WaitOne(100)) { 
            Write-Message -Level Error "Error initializing API and web GUI on port $($Session.ConfigRunning.APIport). Port is in use."
            [Void]$TCPclient.Dispose()

            Return
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
        Write-Message -Level Verbose "Initializing API and web GUI on 'http://localhost:$($Session.ConfigRunning.APIport)'..."
        $Global:APIrunspace | Add-Member Job ($Global:APIrunspace.PowerShell.BeginInvoke())
        $Global:APIrunspace | Add-Member StartTime ([DateTime]::Now.ToUniversalTime())

        # Wait for API to get ready
        $RetryCount = 3
        While (-not ($Session.APIversion) -and $RetryCount -gt 0) { 
            Start-Sleep -Seconds 1
            Try { 
                If ($Session.APIversion = [Version](Invoke-RestMethod "http://localhost:$($Session.ConfigRunning.APIport)/apiversion" -TimeoutSec 1 -ErrorAction Stop)) { 
                    $Session.APIport = $Session.ConfigRunning.APIport
                    If ($Session.ConfigRunning.APIlogfile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): API (version $($Session.APIversion)) started." | Out-File $Session.ConfigRunning.APIlogfile -Force -ErrorAction Ignore }
                    Write-Message -Level Info "API and web GUI is running on http://localhost:$($Session.APIport)."
                    # Start Web GUI (show configuration edit if no existing config)
                    If ($Session.ConfigRunning.WebGUI) { Start-Process "http://localhost:$($Session.APIport)$(If ($Session.FreshConfig -or $Session.ConfigurationHasChangedDuringUpdate) { "/configedit.html" })" }
                    Break
                }
            }
            Catch { }
            $RetryCount--
        }
        If (-not $Session.APIversion) { Write-Message -Level Error "Error initializing API and web GUI on port $($Session.ConfigRunning.APIport)." }
    }
}

Function Stop-APIserver { 

    If ($Global:APIrunspace.Job.IsCompleted -eq $false) { 

        If ($Session.APIserver.IsListening) { 
            If ($Session.ConfigRunning.APIport -ne $Session.APIport -or $Session.Miners.Port -contains $Session.ConfigRunning.APIport) { 
                # API port has changed; must stop all running miners
                If ($Session.MinersRunning) { 
                    Write-Message -Level Info "API and web GUI port has changed. Stopping all running miners..."

                    Clear-MinerData
                    Stop-Core
                }
            }
            $Session.APIserver.Stop()
        }

        $Session.APIserver.Close()
        $Session.APIserver.Dispose()

        $Global:APIrunspace.PowerShell.Stop()
        $Global:APIrunspace.PSObject.Properties.Remove("StartTime")

        Write-Message -Level Verbose "Stopped API and web GUI on port $($Session.APIport)."

        $Session.Remove("APIport")
        $Session.Remove("APIversion")
    }

    If ($Global:APIrunspace) { 

        $Global:APIrunspace.PSObject.Properties.Remove("Job")

        $Global:APIrunspace.PowerShell.Dispose()
        $Global:APIrunspace.PowerShell = $null
        $Global:APIrunspace.Close()
        $Global:APIrunspace.Dispose()

        Remove-Variable APIrunspace -Scope Global

        [System.GC]::Collect()
    }
}

Function Set-MinerEnabled { 

    Param (
        [Parameter(Mandatory = $true)]
        [Miner]$Miner
    )

    ForEach ($Worker in $Miner.Workers) { 
        Enable-Stat -Name "$($Miner.Name)_$($Worker.Pool.Algorithm)_Hashrate"
    }

    $Miner.Disabled = $false
    $Miner.Reasons.Remove("Disabled by user") | Out-Null
    $Miner.Reasons.Where({ $_ -notlike "Unrealistic *" }).ForEach({ $Miner.Reasons.Remove({ $_ }) | Out-Null })
    If (-not $Miner.Reasons.Count) { $Miner.Available = $true }
}

Function Set-MinerDisabled { 

    Param (
        [Parameter(Mandatory = $true)]
        [Miner]$Miner
    )

    ForEach ($Worker in $Miner.Workers) { 
        Disable-Stat -Name "$($Miner.Name)_$($Worker.Pool.Algorithm)_Hashrate"
        $Worker.Disabled = $false
    }

    $Miner.Available = $false
    $Miner.Disabled = $true
    If (-not $Miner.Reasons.Contains("Disabled by user")) { $Miner.Reasons.Add("Disabled by user") | Out-Null }
}

Function Set-MinerFailed { 

    Param (
        [Parameter(Mandatory = $true)]
        [Miner]$Miner
    )

    ForEach ($Worker in $Miner.Workers) { 
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

    If (-not $Miner.Reasons.Contains("0 H/s stat file")) { $Miner.Reasons.Add("0 H/s stat file") | Out-Null }
    $Miner.Available = $false
}

Function Set-MinerReBenchmark { 

    Param (
        [Parameter(Mandatory = $true)]
        [Miner]$Miner
    )

    $Miner.Activated = 0 # To allow 3 attempts
    $Miner.Data = [System.Collections.Generic.HashSet[PSCustomObject]]::new()

    ForEach ($Worker in $Miner.Workers) { 
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
    $Session.WatchdogTimers = $Session.WatchdogTimers | Where-Object MinerName -NE $Miner.Name
}

Function Set-MinerMeasurePowerConsumption { 

    Param (
        [Parameter(Mandatory = $true)]
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
    $Session.WatchdogTimers = $Session.WatchdogTimers | Where-Object MinerName -NE $Miner.Name
}

Function Exit-UGminer { 

    If ($Session.LegacyGUI) { 
        # Save window settings
        If ($LegacyGUIform.DesktopBounds.Width -ge 0) { [PSCustomObject]@{ Top = $LegacyGUIform.Top; Left = $LegacyGUIform.Left; Height = $LegacyGUIform.Height; Width = $LegacyGUIform.Width } | ConvertTo-Json | Out-File -LiteralPath ".\Config\WindowSettings.json" -Force -ErrorAction Ignore }

        $TimerUI.Stop()
        Remove-Variable $TimerUI
        $LegacyGUIelements.TabControl.SelectTab(0)
    }

    Write-Message -Level Info "Shutting down $($Session.Branding.ProductLabel)..."
    $Session.NewMiningStatus = "Idle"

    Stop-Core
    Stop-Brain
    Stop-BalancesTracker

    Write-Message -Level Info "$($Session.Branding.ProductLabel) has shut down."
    Start-Sleep -Seconds 2
    Stop-Process $PID -Force
}