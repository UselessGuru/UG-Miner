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
File:           \Includes\include.ps1
Version:        6.2.24
Version date:   2024/08/10
#>

$Global:DebugPreference = "SilentlyContinue"
$Global:ErrorActionPreference = "SilentlyContinue"
$Global:InformationPreference = "SilentlyContinue"
$Global:ProgressPreference = "SilentlyContinue"
$Global:WarningPreference = "SilentlyContinue"
$Global:VerbosePreference = "SilentlyContinue"

# Fix TLS Version erroring
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

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
        $Time = New-Object System.Runtime.InteropServices.ComTypes.FILETIME
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

Class Device { 
    [String]$Architecture
    [Int]$Bus
    [Int]$Bus_Index
    [Int]$Bus_Type_Index
    [Int]$Bus_Platform_Index
    [Int]$Bus_Vendor_Index
    [PSCustomObject]$CIM
    [Version]$CUDAVersion
    [Double]$ConfiguredPowerConsumption = 0 # Workaround if device does not expose power consumption
    [PSCustomObject]$CPUfeatures
    [Int]$Id
    [Int]$Index = 0
    [Int64]$Memory
    [String]$Model
    [Double]$MemoryGiB
    [String]$Name
    [PSCustomObject]$OpenCL = [PSCustomObject]@{ }
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

Class Pool { 
    [Double]$Accuracy
    [String]$Algorithm
    [String]$AlgorithmVariant
    [Boolean]$Available = $true
    [Boolean]$Best = $false
    [Nullable[Int64]]$BlockHeight = $null
    [String]$CoinName
    [String]$Currency
    [Nullable[Double]]$DAGSizeGiB = $null
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
    [System.Collections.Generic.List[String]]$Reasons
    [String]$Region
    [Boolean]$SendHashrate # If true miner will send hashrate to pool
    [Boolean]$SSLselfSignedCertificate
    [Double]$StablePrice
    [DateTime]$Updated = [DateTime]::Now.ToUniversalTime()
    [String]$User
    [String]$Variant
    [String]$WorkerName = ""
    [Nullable[UInt]]$Workers
}

Class Worker { 
    [Boolean]$Disabled
    [Double]$Earning
    [Double]$Earning_Bias
    [Double]$Earning_Accuracy
    [Double]$Fee
    [Double]$Hashrate
    [Pool]$Pool
    [TimeSpan]$TotalMiningDuration
    [DateTime]$Updated = [DateTime]::Now.ToUniversalTime()
}

Enum MinerStatus { 
    Disabled
    DryRun
    Failed
    Idle
    Running
    Unavailable
}

Class Miner { 
    [Int]$Activated
    [TimeSpan]$Active = [TimeSpan]::Zero
    [String[]]$Algorithms = @() # derived from workers, required for GetDataReader & Web GUI
    [String]$API
    [String]$Arguments
    [Boolean]$Available = $true
    [String]$BaseName
    [DateTime]$BeginTime # UniversalTime
    [Boolean]$Benchmark = $false # derived from stats
    [Boolean]$Best = $false
    [String]$CommandLine
    [UInt]$ContinousCycle = 0 # Counter, miner has been running continously for n loops
    [UInt16]$DataCollectInterval = 5 # Seconds
    [DateTime]$DataSampleTimestamp = 0 # Newest sample
    [String[]]$DeviceNames = @() # derived from devices
    [PSCustomObject[]]$Devices
    [Boolean]$Disabled = $false
    [Double]$Earning = [Double]::NaN # derived from pool and stats
    [Double]$Earning_Bias = [Double]::NaN # derived from pool and stats
    [Double]$Earning_Accuracy = 0 # derived from pool and stats
    [DateTime]$EndTime # UniversalTime
    [String[]]$EnvVars = @()
    [Double[]]$Hashrates_Live = @()
    [String]$Info
    [Boolean]$KeepRunning = $false # do not stop miner even if not best (MinInterval)
    [String]$LogFile
    [Boolean]$MeasurePowerConsumption = $false
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
    [System.Collections.Generic.List[String]]$Reasons = @() # Why is a miner not available?
    [Boolean]$Restart = $false 
    hidden [DateTime]$StatStart
    hidden [DateTime]$StatEnd
    [MinerStatus]$Status = [MinerStatus]::Idle
    [String]$StatusInfo = ""
    [String]$SubStatus = [MinerStatus]::Idle
    [TimeSpan]$TotalMiningDuration # derived from pool and stats
    [String]$Type
    [DateTime]$Updated # derived from stats
    [String]$URI
    [DateTime]$ValidDataSampleTimestamp = 0
    [String]$Version
    [UInt16[]]$WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
    [String]$WindowStyle
    [Worker[]]$Workers = @()
    [Worker[]]$WorkersRunning = @()

    hidden [System.Collections.Generic.List[PSCustomObject]]$Data = @() # To store data samples (speed & power consumtion)
    hidden [System.Management.Automation.Job]$DataReaderJob = $null
    hidden [System.Management.Automation.Job]$ProcessJob = $null
    hidden [System.Diagnostics.Process]$Process = $null
 
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

        $this.DataCollectInterval = If ($this.Benchmark -or $this.MeasurePowerConsumption) { 1 } Else { 5 }

        # Start Miner data reader, devices property required for GetPowerConsumption/ConfiguredPowerConsumption
        $this.DataReaderJob = Start-ThreadJob -Name "$($this.Name)_DataReader" -StreamingHost $null -InitializationScript ([ScriptBlock]::Create("Set-Location('$(Get-Location)')")) -ScriptBlock $ScriptBlock -ArgumentList ($this.API), ($this | Select-Object -Property Algorithms, DataCollectInterval, Devices, Name, Path, Port, ReadPowerConsumption | ConvertTo-Json -Depth 5 -WarningAction Ignore)

        Remove-Variable ScriptBlock -ErrorAction Ignore
    }

    hidden [Void]StopDataReader() { 
        If ($this.DataReaderJob) { 
            $this.DataReaderJob | Stop-Job
            # Get data before removing read data
            If ($this.Status -eq [MinerStatus]::Running -and $this.DataReaderJob.HasMoreData) { ($this.DataReaderJob | Receive-Job).Where({ $_.Date }).ForEach({ $this.Data.Add($_) }) }
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

        $this.ContinousCycle = 0
        $this.DataSampleTimestamp = [DateTime]0
        $this.ValidDataSampleTimestamp = [DateTime]0

        $this.Hashrates_Live = @($this.Workers.ForEach({ [Double]::NaN }))
        $this.PowerConsumption_Live = [Double]::NaN

        If ($this.Status -eq [MinerStatus]::DryRun) { 
            $this.StatusInfo = "Dry run '$($this.Info)'"
            $this.SubStatus = "idle"
            Write-Message -Level Info "Dry run for miner '$($this.Info)'..."
            $this.StatStart = $this.BeginTime = [DateTime]::Now.ToUniversalTime()
        }
        Else { 
            $this.StatusInfo = "Starting '$($this.Info)'"
            Write-Message -Level Info "Starting miner '$($this.Info)'..."
        }

        Write-Message -Level Verbose $this.CommandLine

        # Log switching information to .\Logs\SwitchingLog.csv
        [PSCustomObject]@{ 
            DateTime                = (Get-Date -Format o)
            Action                  = If ($this.Status -eq [MinerStatus]::DryRun) { "DryRun" } Else { "Launched" }
            Name                    = $this.Name
            Accounts                = $this.Workers.Pool.User -join " "
            Activated               = $this.Activated
            Algorithms              = $this.Workers.Pool.AlgorithmVariant -join " "
            Benchmark               = $this.Benchmark
            CommandLine             = $this.CommandLine
            Cycle                   = ""
            DeviceNames             = $this.DeviceNames -join " "
            Duration                = ""
            Earning                 = $this.Earning
            Earning_Bias            = $this.Earning_Bias
            LastDataSample          = $null
            MeasurePowerConsumption = $this.MeasurePowerConsumption
            Pools                   = ($this.Workers.Pool.Name | Select-Object -Unique) -join " "
            Profit                  = $this.Profit
            Profit_Bias             = $this.Profit_Bias
            Reason                  = ""
            Type                    = $this.Type
        } | Export-Csv -Path ".\Logs\SwitchingLog.csv" -Append -NoTypeInformation

        If ($this.Status -ne [MinerStatus]::DryRun) { 

            $this.ProcessJob = Invoke-CreateProcess -BinaryPath "$PWD\$($this.Path)" -ArgumentList $this.GetCommandLineParameters() -WorkingDirectory (Split-Path "$PWD\$($this.Path)") -WindowStyle $this.WindowStyle -EnvBlock $this.EnvVars -JobName $this.Name -LogFile $this.LogFile

            # Sometimes the process cannot be found instantly
            $Loops = 100
            Do { 
                If ($this.ProcessId = ($this.ProcessJob | Receive-Job | Select-Object -ExpandProperty ProcessId)) { 
                    $this.Activated ++
                    $this.DataSampleTimestamp = [DateTime]0
                    $this.Status = [MinerStatus]::Running
                    $this.SubStatus = "starting"
                    $this.StatStart = $this.BeginTime = [DateTime]::Now.ToUniversalTime()
                    $this.Process = Get-Process -Id $this.ProcessId -ErrorAction SilentlyContinue
                    $this.StartDataReader()
                    Break
                }
                $Loops --
                Start-Sleep -Milliseconds 50
            } While ($Loops -gt 0)
            Remove-Variable Loops
        }
        $this.WorkersRunning = $this.Workers
    }

    hidden [Void]StopMining() { 
        If ([MinerStatus]::Running, [MinerStatus]::Disabled, [MinerStatus]::DryRun -contains $this.Status) { 
            $this.StatusInfo = "Stopping miner '$($this.Info)'..."
            Write-Message -Level Info $this.StatusInfo
        }
        Else { 
            $this.SubStatus = [MinerStatus]::Failed
            Write-Message -Level Error $this.StatusInfo
        }

        $this.StopDataReader()

        $this.EndTime = [DateTime]::Now.ToUniversalTime()

        If ($this.ProcessId) { 
            If (Get-Process -Id $this.ProcessId -ErrorAction Ignore) { Stop-Process -Id $this.ProcessId -Force -ErrorAction Ignore | Out-Null }
            $this.ProcessId = $null
        }

        If ($this.Process) { 
            [Void]$this.Process.CloseMainWindow()
            $this.Process = $null
        }

        If ($this.ProcessJob) { 
            Try { $this.Active += $this.ProcessJob.PSEndTime - $this.ProcessJob.PSBeginTime } Catch { }
            # Jobs are getting removed in core loop (stopping immediately after stopping process here may take several seconds)
            $this.ProcessJob = $null
        }

        $this.Status = If ([MinerStatus]::Running, [MinerStatus]::DryRun -contains $this.Status) { [MinerStatus]::Idle } Else { [MinerStatus]::Failed }

        # Log switching information to .\Logs\SwitchingLog
        [PSCustomObject]@{ 
            DateTime                = (Get-Date -Format o)
            Action                  = If ($this.Status -eq [MinerStatus]::Idle) { "Stopped" } Else { "Failed" }
            Name                    = $this.Name
            Activated               = $this.Activated
            Accounts                = $this.WorkersRunning.Pool.User -join " "
            Algorithms              = $this.WorkersRunning.Pool.AlgorithmVariant -join " "
            Benchmark               = $this.Benchmark
            CommandLine             = $this.CommandLine
            Cycle                   = $this.ContinousCycle
            DeviceNames             = $this.DeviceNames -join " "
            Duration                = "{0:hh\:mm\:ss}" -f ($this.EndTime - $this.BeginTime)
            Earning                 = $this.Earning
            Earning_Bias            = $this.Earning_Bias
            LastDataSample          = If ($this.Data.Count -ge 1) { $this.Data.Item($this.Data.Count - 1 ) | ConvertTo-Json -Compress } Else { "" }
            MeasurePowerConsumption = $this.MeasurePowerConsumption
            Pools                   = ($this.WorkersRunning.Pool.Name | Select-Object -Unique) -join " "
            Profit                  = $this.Profit
            Profit_Bias             = $this.Profit_Bias
            Reason                  = If ($this.StatusInfo -and $this.Status -eq [MinerStatus]::Failed) { $this.StatusInfo -replace "'$($this.StatusInfo)' " } Else { "" }
            Type                    = $this.Type
        } | Export-Csv -Path ".\Logs\SwitchingLog.csv" -Append -NoTypeInformation

        If ($this.Status -eq [MinerStatus]::Idle) { 
            $this.StatusInfo = "Idle"
            $this.SubStatus = $this.Status
        }
        $this.WorkersRunning = [Worker[]]@()
    }

    [MinerStatus]GetStatus() { 
        If ($this.ProcessJob.State -eq "Running" -and $this.ProcessId -and (Get-Process -Id $this.ProcessId -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessName)) { 
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
            Return $this.Active + ($this.Process.EndTime - $this.Process.BeginTime)
        }
        ElseIf ($this.Process.BeginTime) { 
            Return $this.Active + ([DateTime]::Now - $this.Process.BeginTime)
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
            If ($RegistryEntry = $RegistryData.PSObject.Properties.Where({ $_.Value -split " " -contains $Device.Name })) { 
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
        $PowerConsumptionVariance = $PowerConsumptionSamples.PowerUsage | Measure-Object -Average -Minimum -Maximum | ForEach-Object { If ($_.Average) { ($_.Maximum - $_.Minimum) / $_.Average } }

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

    [Void]Refresh([Double]$PowerCostBTCperW, [Hashtable]$Config) { 
        $this.Best = $false
        $this.MinDataSample = $Config.MinDataSample
        $this.Prioritize = [Boolean]($this.Workers.Where({ $_.Pool.Prioritize }))
        $this.ProcessPriority = If ($this.Type -eq "CPU") { $Config.CPUMinerProcessPriority } Else { $Config.GPUMinerProcessPriority }
        $this.Reasons = [System.Collections.Generic.List[String]]@()
        If ($this.ReadPowerConsumption -ne $this.Devices.ReadPowerConsumption -notcontains $false) { $this.Restart = $true }
        $this.ReadPowerConsumption = $this.Devices.ReadPowerConsumption -notcontains $false
        $this.Updated = ($this.Workers.Updated | Measure-Object -Minimum).Minimum
        $this.TotalMiningDuration = ($this.Workers.TotalMiningDuration | Measure-Object -Minimum).Minimum
        $this.WindowStyle = If ($Config.MinerWindowStyleNormalWhenBenchmarking -and $this.Benchmark) { "normal" } Else { $Config.MinerWindowStyle }

        $this.Workers.ForEach(
            { 
                If ($Stat = Get-Stat -Name "$($this.Name)_$($_.Pool.Algorithm)_Hashrate") { 
                    $_.Hashrate = $Stat.Hour
                    $Factor = $_.Hashrate * (1 - $_.Fee - $_.Pool.Fee)
                    $_.Disabled = $Stat.Disabled
                    $_.Earning = $_.Pool.Price * $Factor
                    $_.Earning_Accuracy = $_.Pool.Accuracy
                    $_.Earning_Bias = $_.Pool.Price_Bias * $Factor
                    $_.TotalMiningDuration = $Stat.Duration
                    $_.Updated = $Stat.Updated
                }
                Else { 
                    $_.Disabled = $false
                    $_.Hashrate = [Double]::NaN
                }
            }
        )
        $this.Benchmark = [Boolean]($this.Workers.Hashrate -match [Double]::NaN)
        $this.Disabled = $this.Workers.Disabled -contains $true

        If ($this.Benchmark -eq $true) { 
            $this.Earning = [Double]::NaN
            $this.Earning_Bias = [Double]::NaN
            $this.Earning_Accuracy = [Double]::NaN
        }
        Else { 
            $this.Earning = ($this.Workers.Earning | Measure-Object -Sum).Sum
            $this.Earning_Bias = ($this.Workers.Earning_Bias | Measure-Object -Sum).Sum
            $this.Earning_Accuracy = 0
            If ($this.Earning) { $this.Workers.ForEach({ $this.Earning_Accuracy += $_.Earning_Accuracy * $_.Earning / $this.Earning }) }
        }

        If ($Stat = Get-Stat -Name "$($this.Name)_PowerConsumption") { 
            $this.PowerConsumption = $Stat.Week
            $this.PowerCost = $this.PowerConsumption * $PowerCostBTCperW
            $this.Profit = $this.Earning - $this.PowerCost
            $this.Profit_Bias = $this.Earning_Bias - $this.PowerCost
            $this.MeasurePowerConsumption = $false
        }
        Else { 
            $this.PowerCost = [Double]::NaN
            $this.PowerConsumption = [Double]::NaN
            $this.Profit = [Double]::NaN
            $this.Profit_Bias = [Double]::NaN
            $this.MeasurePowerConsumption = $Config.CalculatePowerCost
        }
    }
}

Function Start-Core { 

    If (-not $Variables.CoreRunspace) { 

        $Variables.CoreRunspace = @{ }

        $Variables.LastDonated = [DateTime]::Now.AddDays(-1).AddHours(1)

        $Variables.Remove("EndCycleTime")

        $Variables.CycleStarts = @()

        $Runspace = [RunspaceFactory]::CreateRunspace()
        $Runspace.ApartmentState = "STA"
        $Runspace.Name = "Core"
        $Runspace.ThreadOptions = "ReuseThread"
        $Runspace.Open()

        $Runspace.SessionStateProxy.SetVariable("Config", $Config)
        $Runspace.SessionStateProxy.SetVariable("Stats", $Stats)
        $Runspace.SessionStateProxy.SetVariable("Variables", $Variables)
        [Void]$Runspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)

        $PowerShell = [PowerShell]::Create()
        $PowerShell.Runspace = $Runspace
        $Variables.CoreRunspace.Job = $Powershell.AddScript("$($Variables.MainPath)\Includes\Core.ps1").BeginInvoke()
        $Variables.CoreRunspace.PowerShell = $PowerShell
        $Variables.CoreRunspace.StartTime = [DateTime]::Now.ToUniversalTime()
    }
}

Function Stop-Core { 

    If ($Variables.CoreRunspace) { 

        $Variables.CoreRunspace.PowerShell.Stop() | Out-Null

        $Variables.EndCycleTime = [DateTime]::Now.ToUniversalTime()

        ForEach ($Miner in $Variables.Miners.Where({ [MinerStatus]::DryRun, [MinerStatus]::Running -contains $_.Status })) { 
            ForEach ($Worker in $Miner.WorkersRunning) { 
                If ($WatchdogTimers = @($Variables.WatchdogTimers.Where({ $_.MinerName -eq $Miner.Name -and $_.PoolName -eq $Worker.Pool.Name -and $_.PoolRegion -eq $Worker.Pool.Region -and $_.AlgorithmVariant -eq $Worker.Pool.AlgorithmVariant -and $_.DeviceNames -eq $Miner.DeviceNames }))) { 
                    # Remove Watchdog timers
                    $Variables.WatchdogTimers = @($Variables.WatchdogTimers.Where({ $_ -notin $WatchdogTimers }))
                }
            }
            Remove-Variable WatchdogTimers, Worker -ErrorAction Ignore
            $Miner.SetStatus([MinerStatus]::Idle)
        }
        Remove-Variable $Miner

        $Variables.Miners = [Miner[]]@()
        $Variables.MinersBenchmarkingOrMeasuring = [Miner[]]@()
        $Variables.MinersBest = [Miner[]]@()
        $Variables.MinersBestPerDevice = [Miner[]]@()
        $Variables.MinerDeviceNamesCombinations = [Miner[]]@()
        $Variables.MinersFailed = [Miner[]]@()
        $Variables.MinersMissingBinary = [Miner[]]@()
        $Variables.MissingMinerFirewallRule = [Miner[]]@()
        $Variables.MinersMissingPrerequisite = [Miner[]]@()
        $Variables.MinersOptimal = [Miner[]]@()
        $Variables.MinersRunning = [Miner[]]@()

        # Must close runspace after miners were stopped, otherwise methods don't work any longer
        $Variables.CoreRunspace.PowerShell.EndInvoke($Variables.CoreRunspace.Job) | Out-Null
        $Variables.CoreRunspace.PowerShell.Runspace.Dispose() | Out-Null
        $Variables.CoreRunspace.PowerShell.Dispose() | Out-Null
        $Variables.CoreRunspace.Close() | Out-Null
        $Variables.CoreRunspace.Dispose() | Out-Null

        $Variables.CoreRunspace.Remove("PowerShell")
        $Variables.Remove("CoreRunspace")

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
        $Name.ForEach(
            { 
                If ($Config.PoolsConfig.$_.BrainConfig -and -not $Variables.Brains.$_) { 
                    $BrainScript = ".\Brains\$($_).ps1"
                    If (Test-Path -LiteralPath $BrainScript -PathType Leaf) { 
                        $Variables.Brains.$_ = @{ }

                        $Runspace = [RunspaceFactory]::CreateRunspace()
                        $Runspace.ApartmentState = "STA"
                        $Runspace.Name = "Brain_$($_)"
                        $Runspace.ThreadOptions = "ReuseThread"
                        $Runspace.Open()

                        $Runspace.SessionStateProxy.SetVariable("Config", $Config)
                        $Runspace.SessionStateProxy.SetVariable("Stats", $Stats)
                        $Runspace.SessionStateProxy.SetVariable("Variables", $Variables)
                        [Void]$Runspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)

                        $PowerShell = [PowerShell]::Create()
                        $PowerShell.Runspace = $Runspace
                        $Variables.Brains.$_.Job = $Powershell.AddScript($BrainScript).BeginInvoke()
                        $Variables.Brains.$_.PowerShell = $PowerShell
                        $Variables.Brains.$_.StartTime = [DateTime]::Now.ToUniversalTime()

                        $BrainsStarted += $_
                    }
                }
            }
        )
        If ($BrainsStarted.Count -gt 0) { Write-Message -Level Info "Pool brain backgound job$(If ($BrainsStarted.Count -gt 1) { "s" }) for $($BrainsStarted -join ", " -replace ",([^,]*)$", ' &$1') started." }
    }
    Else { 
        Write-Message -Level Error "Failed to start Pool brain backgound jobs. Directory '.\Brains' is missing."
    }
}

Function Stop-Brain { 

    Param (
        [Parameter(Mandatory = $false)]
        [String[]]$Name = $Variables.Brains.psBase.Keys
    )

    If ($Name) { 

        $BrainsStopped = @()

        $Name.Where({ $Variables.Brains.$_ }).ForEach(
            { 
                # Stop Brains
                $Variables.Brains[$_].PowerShell.Stop() | Out-Null
                If (-not $Variables.Brains[$_].Job.IsCompleted) { $Variables.Brains[$_].PowerShell.EndInvoke($Variables.Brains[$_].Job) | Out-Null }
                $Variables.Brains[$_].PowerShell.Runspace.Close() | Out-Null
                $Variables.Brains[$_].PowerShell.Dispose() | Out-Null
                $Variables.Brains.Remove($_)
                $Variables.BrainData.Remove($_)
                $BrainsStopped += $_
            }
        )
        If ($BrainsStopped.Count -gt 0) { Write-Message -Level Info "Pool brain backgound job$(If ($BrainsStopped.Count -gt 1) { "s" }) for $(($BrainsStopped | Sort-Object) -join ", " -replace ",([^,]*)$", ' &$1') stopped." }

        [System.GC]::Collect()
    }
}

Function Start-BalancesTracker { 

    If (-not $Global:BalancesTrackerRunspace) { 

        If (Test-Path -LiteralPath ".\Balances" -PathType Container) { 
            Try { 
                $Global:BalancesTrackerRunspace = @{ }

                $Variables.Summary = "Starting Balances tracker background process..."
                Write-Message -Level Verbose ($Variables.Summary -replace "<br>", " ")

                $Runspace = [RunspaceFactory]::CreateRunspace()
                $Runspace.ApartmentState = "STA"
                $Runspace.Name = "BalancesTracker"
                $Runspace.ThreadOptions = "ReuseThread"
                $Runspace.Open()

                $Runspace.SessionStateProxy.SetVariable("Config", $Config)
                $Runspace.SessionStateProxy.SetVariable("Stats", $Stats)
                $Runspace.SessionStateProxy.SetVariable("Variables", $Variables)
                [Void]$Runspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)

                $PowerShell = [PowerShell]::Create()
                $PowerShell.Runspace = $Runspace
                $Global:BalancesTrackerRunspace.Job = $Powershell.AddScript("$($Variables.MainPath)\Includes\BalancesTracker.ps1").BeginInvoke()
                $Global:BalancesTrackerRunspace.PowerShell = $PowerShell
                $Global:BalancesTrackerRunspace.StartTime = [DateTime]::Now.ToUniversalTime()
            }
            Catch { 
                Write-Message -Level Error "Failed to start Balances tracker [$Error[0]]."
            }
        }
        Else { 
            Write-Message -Level Error "Failed to start Balances tracker. Directory '.\Balances' is missing."
        }
    }
}

Function Stop-BalancesTracker { 

    If ($Global:BalancesTrackerRunspace) { 

        $Variables.BalancesTrackerRunning = $false
        $Global:BalancesTrackerRunspace.PowerShell.Stop() | Out-Null
        $Global:BalancesTrackerRunspace.PowerShell.EndInvoke() | Out-Null
        $Global:BalancesTrackerRunspace.PowerShell.Runspace.Close() | Out-Null
        $Global:BalancesTrackerRunspace.PowerShell.Dispose() | Out-Null
        $Global:BalancesTrackerRunspace.Close() | Out-Null
        $Global:BalancesTrackerRunspace.Dispose() | Out-Null

        $Variables.Remove("BalancesTrackerRunspace")

        $Variables.Summary += "<br>Balances tracker background process stopped."
        Write-Message -Level Info "Balances tracker background process stopped."
    }

    [System.GC]::Collect()
}

Function Get-Rate { 

    $RatesCacheFileName = "$($Variables.MainPath)\Cache\Rates.json"

    # Use stored currencies from last run
    If (-not $Variables.BalancesCurrencies -and $Config.BalancesTrackerPollInterval) { $Variables.BalancesCurrencies = $Variables.Rates.PSObject.Properties.Name -creplace "^m" }

    $Variables.AllCurrencies = @(@(@($Config.MainCurrency) + @($Config.Wallets.psBase.Keys) + @($Variables.PoolData.Keys.ForEach({ $Variables.PoolData.$_.GuaranteedPayoutCurrencies })) + @($Config.ExtraCurrencies) + @($Variables.BalancesCurrencies) | Select-Object) -replace "mBTC", "BTC" | Sort-Object -Unique)

    Try { 
        $TSymBatches = @()
        $TSyms = "BTC"
        $Variables.AllCurrencies.Where({ $_ -notin @("BTC", "INVALID") }).ForEach(
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
                $Response = Invoke-RestMethod -Uri "https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC&tsyms=$($_)$(If ($Config.CryptoCompareAPIKeyParam) { "&api_key=$($Config.CryptoCompareAPIKeyParam)" })&extraParams=$($Variables.Branding.BrandWebSite) Version $($Variables.Branding.Version)" -TimeoutSec 5 -ErrorAction Ignore
                If ($Response.BTC) { 
                    $Response.BTC.ForEach(
                        { 
                            $_.PSObject.Properties.ForEach({ $Rates.BTC | Add-Member @{ "$($_.Name)" = $_.Value } -Force })
                        }
                    )
                }
                Else { 
                    If ($Response.Message -eq "You are over your rate limit please upgrade your account!") { 
                        Write-Message -Level Error "min-api.cryptocompare.com API rate exceeded. You need to register an account with cryptocompare.com and add the API key as 'CryptoCompareAPIKeyParam' to the configuration file '$($Variables.ConfigFile)'."
                    }
                }
            }
        )

        If ($Currencies = $Rates.BTC.PSObject.Properties.Name) { 
            $Currencies.Where({ $_ -ne "BTC" }).ForEach(
                { 
                    $Currency = $_
                    $Rates | Add-Member $Currency ($Rates.BTC | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json) -Force
                    $Rates.$Currency.PSObject.Properties.Name.ForEach(
                        { 
                            $Rates.$Currency | Add-Member $_ (($Rates.BTC.$_ / $Rates.BTC.$Currency) -as [Double]) -Force
                        }
                    )
                }
            )

            # Add mBTC
            If ($Config.UsemBTC) { 
                $Currencies.ForEach(
                    { 
                        $Currency = $_
                        $mCurrency = "m$Currency"
                        $Rates | Add-Member $mCurrency ($Rates.$Currency | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json) -Force
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
            Write-Message -Level Info "Loaded currency exchange rates from 'min-api.cryptocompare.com'.$(If ($Variables.RatesMissingCurrencies = Compare-Object @($Currencies | Select-Object) @($Variables.AllCurrencies | Select-Object) -PassThru) { " API does not provide rates for $($Variables.RatesMissingCurrencies -join ", " -replace ",([^,]*)$", ' &$1')." })"
            $Variables.Rates = $Rates
            $Variables.RatesUpdated = [DateTime]::Now.ToUniversalTime()

            $Variables.Rates | ConvertTo-Json -Depth 5 | Out-File -LiteralPath $RatesCacheFileName -Force -ErrorAction Ignore
        }
    }
    Catch { 
        # Read exchange rates from min-api.cryptocompare.com, use stored data as fallback
        $RatesCache = ([System.IO.File]::ReadAllLines($RatesCacheFileName) | ConvertFrom-Json -ErrorAction Ignore)
        If ($RatesCache.PSObject.Properties.Name) { 
            $Variables.Rates = $RatesCache
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
        [String]$Level = "Info"
    )

    $Message = $Message -replace "<br>", " " -replace "&ensp;", " "

    # Make sure we are in main script
    If ($Host.Name -eq "ConsoleHost" -and (-not $Config.Keys -or $Config.LogToScreen -contains $Level)) { 
        # Write to console
        Switch ($Level) { 
            "Debug"    { Write-Host $Message -ForegroundColor "Blue" }
            "Error"    { Write-Host $Message -ForegroundColor "Red" }
            "Info"     { Write-Host $Message -ForegroundColor "White" }
            "MemDebug" { Write-Host $Message -ForegroundColor "Cyan" }
            "Verbose"  { Write-Host $Message -ForegroundColor "Yello" }
            "Warn"     { Write-Host $Message -ForegroundColor "Magenta" }
        }
    }

    $Message = "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") $($Level.ToUpper()): $Message"

    If (-not $Config.Keys.Count -or $Config.LogToScreen -contains $Level ) { 
        # Ignore error when legacy GUI gets closed
        Try { 
            $SelectionLength = $Variables.TextBoxSystemLog.SelectionLength
            $SelectionStart = $Variables.TextBoxSystemLog.SelectionStart
            $TextLength = $Variables.TextBoxSystemLog.TextLength

            If ($Variables.TextBoxSystemLog.Lines.Count -gt 100) { 
                # Keep only 100 lines, more lines impact performance
                $Variables.TextBoxSystemLog.Lines = $Variables.TextBoxSystemLog.Lines | Select-Object -Last 100
            }

            $SelectionStart = $SelectionStart + ($Variables.TextBoxSystemLog.TextLength - $TextLength)
            If ($SelectionLength -and $SelectionStart -gt 0) { 
                $Variables.TextBoxSystemLog.Lines += $Message
                $Variables.TextBoxSystemLog.Select($SelectionStart, $SelectionLength)
                $Variables.TextBoxSystemLog.ScrollToCaret()
            }
            Else { 
                $Variables.TextBoxSystemLog.AppendText("`r`n$Message")
            }
        }
        Catch { }
    }

    If (-not $Config.Keys.Count -or $Config.LogToFile -contains $Level) { 

        $Variables.LogFile = "$($Variables.MainPath)\Logs\$($Variables.Branding.ProductLabel)_$(Get-Date -Format "yyyy-MM-dd").log"

        $Mutex = New-Object System.Threading.Mutex($false, "$($Variables.Branding.ProductLabel)_Write-Message")
        # Get mutex. Mutexes are shared across all threads and processes.
        # This lets us ensure only one thread is trying to write to the file at a time.

        # Attempt to aquire mutex, waiting up to 1 second if necessary
        If ($Mutex.WaitOne(1000)) { 
            $Message | Out-File -LiteralPath $Variables.LogFile -Append -ErrorAction Ignore
            $Mutex.ReleaseMutex()
        }
    }
}

Function Write-MonitoringData { 

    # Updates a remote monitoring server, sending this worker's data and pulling data about other workers

    # Skip If server and user aren't filled out
    If (-not $Config.MonitoringServer) { Return }
    If (-not $Config.MonitoringUser) { Return }

    # Build object with just the data we need to send, and make sure to use relative paths so we don't accidentally
    # reveal someone's windows username or other system information they might not want sent
    # For the ones that can be an array, comma separate them
    $Data = @(
        ($Variables.Miners.Where({ $_.Status -eq [MinerStatus]::DryRun -or $_.Status -eq [MinerStatus]::Running }) | Sort-Object { [String]$_.DeviceNames }).ForEach(
            { 
                [PSCustomObject]@{ 
                    Algorithm      = $_.WorkersRunning.Pool.Algorithm -join ","
                    Currency       = $Config.MainCurrency
                    CurrentSpeed   = $_.Hashrates_Live
                    Earning        = ($_.WorkersRunning.Earning | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
                    EstimatedSpeed = $_.WorkersRunning.Hashrate
                    Name           = $_.Name
                    Path           = Resolve-Path -Relative $_.Path
                    Pool           = $_.WorkersRunning.Pool.Name -join ","
                    Profit         = If ($_.Profit) { $_.Profit } ElseIf ($Variables.CalculatePowerCost) { ($_.WorkersRunning.Profit | Measure-Object -Sum | Select-Object -ExpandProperty Sum) - $_.PowerConsumption_Live * $Variables.PowerCostBTCperW } Else { [Double]::Nan }
                    Type           = $_.Type
                }
            }
        )
    )

    $Body = @{ 
        user    = $Config.MonitoringUser
        worker  = $Config.WorkerName
        version = "$($Variables.Branding.ProductLabel) $($Variables.Branding.Version.ToString())"
        status  = $Variables.NewMiningStatus
        profit  = If ([Double]::IsNaN($Variables.MiningProfit)) { "n/a" } Else { [String]$Variables.MiningProfit } # Earnings is NOT profit! Needs to be changed in mining monitor server
        data    = ConvertTo-Json $Data
    }

    # Send the request
    Try { 
        $Response = Invoke-RestMethod -Uri "$($Config.MonitoringServer)/api/report.php" -Method Post -Body $Body -TimeoutSec 10 -ErrorAction Stop
        If ($Response -eq "Success") { 
            Write-Message -Level Verbose "Reported worker status to monitoring server '$($Config.MonitoringServer)' [ID $($Config.MonitoringUser)]."
        }
        Else { 
            Write-Message -Level Verbose "Reporting worker status to monitoring server '$($Config.MonitoringServer)' failed: [$($Response)]."
        }
    }
    Catch { 
        Write-Message -Level Warn "Monitoring: Unable to send status to '$($Config.MonitoringServer)' [ID $($Config.MonitoringUser)]."
    }
}

Function Read-MonitoringData { 

    If ($Config.ShowWorkerStatus -and $Config.MonitoringUser -and $Config.MonitoringServer -and $Variables.WorkersLastUpdated -lt [DateTime]::Now.AddSeconds(-30)) { 
        Try { 
            $Workers = Invoke-RestMethod -Uri "$($Config.MonitoringServer)/api/workers.php" -Method Post -Body @{ user = $Config.MonitoringUser } -TimeoutSec 10 -ErrorAction Stop
            # Calculate some additional properties and format others
            $Workers.ForEach(
                { 
                    # Convert the unix timestamp to a datetime object, taking into account the local time zone
                    $_ | Add-Member @{ date = [TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($_.lastseen)) } -Force

                    # If a machine hasn't reported in for more than 10 minutes, mark it as offline
                    If ((New-TimeSpan -Start $_.date -End ([DateTime]::Now)).TotalMinutes -gt 10) { $_.status = "Offline" }
                }
            )
            $Variables.Workers = $Workers
            $Variables.WorkersLastUpdated = ([DateTime]::Now)

            Write-Message -Level Verbose "Retrieved worker status from '$($Config.MonitoringServer)' [ID $($Config.MonitoringUser)]."
        }
        Catch { 
            Write-Message -Level Warn "Monitoring: Unable to retrieve worker data from '$($Config.MonitoringServer)' [ID $($Config.MonitoringUser)]."
        }
    }
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
        [Hashtable]$HT1,
        [Parameter(Mandatory = $true)]
        [Hashtable]$HT2,
        [Parameter(Mandatory = $false)]
        [Boolean]$Unique = $false
    )

    $HT2.psBase.Keys.ForEach(
        { 
            If ($HT1.$_ -is [Hashtable]) { 
                $HT1[$_] = Merge-Hashtable -HT1 $HT1[$_] -Ht2 $HT2.$_ -Unique $Unique
            }
            ElseIf ($HT1.$_ -is [Array]) { 
                If ($HT2.$_) { 
                    $HT1.$_ += $HT2.$_
                    If ($Unique) { $HT1.$_ = ($HT1.$_ | Sort-Object -Unique) -as [Array] }
                }
            }
            Else { 
                $HT1.$_ = $HT2.$_ -as $HT2.$_.GetType()
            }
        }
    )
    Return $HT1
}

Function Get-RandomDonationPoolsConfig { 
    # Randomize donation data
    # Build pool config with available donation data, not all devs have the same set of wallets available

    $Variables.DonationRandom = $Variables.DonationData | Get-Random
    $DonationRandomPoolsConfig = [Ordered]@{ }
    ((Get-ChildItem .\Pools\*.ps1 -File).BaseName | Sort-Object -Unique).Where({ $Variables.DonationRandom.PoolName -contains $_ }).ForEach(
        { 
            $PoolConfig = $Config.PoolsConfig[$_] | ConvertTo-Json -Depth 99 -Compress | ConvertFrom-Json -AsHashtable
            $PoolConfig.EarningsAdjustmentFactor = 1
            $PoolConfig.Region = $Config.PoolsConfig[$_].Region
            $PoolConfig.WorkerName = "$($Variables.Branding.ProductLabel)-$($Variables.Branding.Version.ToString())-donate$($Config.Donation)"
            Switch -regex ($_) { 
                "^MiningDutch$|^MiningPoolHub$|^ProHashing$" { 
                    If ($Variables.DonationRandom."$($_)UserName") { 
                        # not all devs have a known HashCryptos, MiningDutch or ProHashing account
                        $PoolConfig.UserName = $Variables.DonationRandom."$($_)UserName"
                        $PoolConfig.Variant = $Config.PoolsConfig[$_].Variant
                        $DonationRandomPoolsConfig.$_ = $PoolConfig
                    }
                    Break
                }
                Default { 
                    # not all devs have a known ETC or ETH address
                    If (Compare-Object @($Variables.PoolData.$_.GuaranteedPayoutCurrencies | Select-Object) @($Variables.DonationRandom.Wallets.PSObject.Properties.Name | Select-Object) -IncludeEqual -ExcludeDifferent) { 
                        $PoolConfig.Variant = If ($Config.PoolsConfig[$_].Variant) { $Config.PoolsConfig[$_].Variant } Else { $Config.PoolName -match $_ }
                        $PoolConfig.Wallets = $Variables.DonationRandom.Wallets | ConvertTo-Json | ConvertFrom-Json -AsHashtable
                        $DonationRandomPoolsConfig.$_ = $PoolConfig
                    }
                }
            }
        }
    )

    Return $DonationRandomPoolsConfig
}

Function Read-Config { 

    Param (
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )

    Function Get-DefaultConfig { 

        $DefaultConfig = @{ }

        $DefaultConfig.ConfigFileVersion = $Variables.Branding.Version.ToString()
        $Variables.FreshConfig = $true

        # Add default config items
        $Variables.AllCommandLineParameters.psBase.Keys.Where({ $_ -notin $DefaultConfig.psBase.Keys }).ForEach(
            { 
                $Value = $Variables.AllCommandLineParameters.$_
                If ($Value -is [Switch]) { $Value = [Boolean]$Value }
                $DefaultConfig.$_ = $Value
            }
        )

        $RandomDonationData = $Variables.DonationData | Get-Random
        $DefaultConfig.MiningDutchUserName = $RandomDonationData.MiningDutchUserName
        $DefaultConfig.MiningPoolHubUserName = $RandomDonationData.MiningPoolHubUserName
        $DefaultConfig.NiceHashWallet = $RandomDonationData.Wallets.BTC
        $DefaultConfig.ProHashingUserName = $RandomDonationData.ProHashingUserName
        $DefaultConfig.Wallets.BTC = $RandomDonationData.Wallets.BTC

        Return $DefaultConfig
    }

    Function Get-PoolsConfig { 

        # Load pool data
        If (-not $Variables.PoolData) { 
            $Variables.PoolData = [System.IO.File]::ReadAllLines("$PWD\Data\PoolData.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject
            $Variables.PoolVariants = @(($Variables.PoolData.psBase.Keys.ForEach({ $Variables.PoolData.$_.Variant.psBase.Keys -replace " External$| Internal$" })) | Sort-Object -Unique)
            If (-not $Variables.PoolVariants) { 
                Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\PoolData.json' is not a valid $($Variables.Branding.ProductLabel) JSON data file. Please restore it from your original download."
                $WscriptShell.Popup("File '.\Data\PoolData.json' is not a valid $($Variables.Branding.ProductLabel) JSON data file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
                Exit
            }
        }

        # Build in memory pool config
        $PoolsConfig = @{ }
        ((Get-ChildItem .\Pools\*.ps1 -File).BaseName | Sort-Object -Unique).ForEach(
            { 
                $PoolName = $_
                If ($PoolConfig = $Variables.PoolData.$PoolName) { 
                    If ($CustomPoolConfig = $Variables.PoolsConfigData.$PoolName) { 
                        # Merge default config data with custom pool config
                        $PoolConfig = Merge-Hashtable -HT1 $PoolConfig -HT2 $CustomPoolConfig -Unique $true
                    }

                    If (-not $PoolConfig.EarningsAdjustmentFactor) { 
                        $PoolConfig.EarningsAdjustmentFactor = $ConfigFromFile.EarningsAdjustmentFactor
                    }
                    If ($PoolConfig.EarningsAdjustmentFactor -le 0 -or $PoolConfig.EarningsAdjustmentFactor -gt 10) { 
                        $PoolConfig.EarningsAdjustmentFactor = $ConfigFromFile.EarningsAdjustmentFactor
                        Write-Message -Level Warn "Earnings adjustment factor (value: $($PoolConfig.EarningsAdjustmentFactor)) for pool '$PoolName' is not within supported range (0 - 10); using default value $($PoolConfig.EarningsAdjustmentFactor)."
                    }

                    If (-not $PoolConfig.WorkerName) { $PoolConfig.WorkerName = $ConfigFromFile.WorkerName }
                    If (-not $PoolConfig.BalancesKeepAlive) { $PoolConfig.BalancesKeepAlive = $PoolData.$PoolName.BalancesKeepAlive }

                    $PoolConfig.Region = $PoolConfig.Region.Where({ (Get-Region $_) -notin @($PoolConfig.ExcludeRegion) })

                    Switch ($PoolName) { 
                        "Hiveon" { 
                            If (-not $PoolConfig.Wallets) { 
                                $PoolConfig.Wallets = [Ordered]@{ }
                                $ConfigFromFile.Wallets.GetEnumerator().Name.Where({ $PoolConfig.PayoutCurrencies -contains $_ }).ForEach({ $PoolConfig.Wallets.$_ = $ConfigFromFile.Wallets.$_ })
                            }
                            Break
                        }
                        "MiningDutch" { 
                            If ((-not $PoolConfig.PayoutCurrency) -or $PoolConfig.PayoutCurrency -eq "[Default]") { $PoolConfig.PayoutCurrency = $ConfigFromFile.PayoutCurrency }
                            If (-not $PoolConfig.UserName) { $PoolConfig.UserName = $ConfigFromFile.MiningDutchUserName }
                            If (-not $PoolConfig.Wallets) { $PoolConfig.Wallets = @{ "$($PoolConfig.PayoutCurrency)" = $($ConfigFromFile.Wallets.($PoolConfig.PayoutCurrency)) } }
                            Break
                        }
                        "MiningPoolHub" { 
                            If (-not $PoolConfig.UserName) { $PoolConfig.UserName = $ConfigFromFile.MiningPoolHubUserName }
                            Break
                        }
                        "NiceHash" { 
                            If (-not $PoolConfig.Variant."Nicehash Internal".Wallets.BTC) { 
                                If ($ConfigFromFile.NiceHashWallet -and $ConfigFromFile.NiceHashWalletIsInternal) { $PoolConfig.Variant."NiceHash Internal".Wallets = [Ordered]@{ "BTC" = $ConfigFromFile.NiceHashWallet } }
                            }
                            If (-not $PoolConfig.Variant."Nicehash External".Wallets.BTC) { 
                                If ($ConfigFromFile.NiceHashWallet -and -not $ConfigFromFile.NiceHashWalletIsInternal) { $PoolConfig.Variant."NiceHash External".Wallets = [Ordered]@{ "BTC" = $ConfigFromFile.NiceHashWallet } }
                                ElseIf ($ConfigFromFile.Wallets.BTC) { $PoolConfig.Variant."NiceHash External".Wallets = [Ordered]@{ "BTC" = $ConfigFromFile.Wallets.BTC } }
                            }
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
                    If ($PoolConfig.Algorithm) { $PoolConfig.Algorithm = @($PoolConfig.Algorithm -replace " " -split ",") }
                }
                $PoolsConfig.$PoolName = $PoolConfig
            }
        )

        Return $PoolsConfig
    }

    # Load the configuration
    $ConfigFromFile = @{ }
    If (Test-Path -LiteralPath $ConfigFile -PathType Leaf) { 
        $ConfigFromFile = [System.IO.File]::ReadAllLines($ConfigFile) | ConvertFrom-Json -AsHashtable | Get-SortedObject
        If ($ConfigFromFile.psBase.Keys.Count -eq 0) { 
            $CorruptConfigFile = "$($ConfigFile)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").corrupt"
            Move-Item -Path $ConfigFile $CorruptConfigFile -Force
            $Message = "Configuration file '$ConfigFile' is corrupt and was renamed to '$CorruptConfigFile'."
            Write-Message -Level Warn $Message
            $ConfigFromFile = Get-DefaultConfig
        }
        Else { 
            $Variables.ConfigFileTimestamp = (Get-Item -Path $Variables.ConfigFile).LastWriteTime
            ($Variables.AllCommandLineParameters.psBase.Keys | Sort-Object).ForEach(
                { 
                    If ($ConfigFromFile.psBase.Keys -contains $_) { 
                        # Upper / lower case conversion of variable keys (Web GUI is case sensitive)
                        $Value = $ConfigFromFile.$_
                        $ConfigFromFile.Remove($_)
                        If ($Variables.AllCommandLineParameters.$_ -is [Switch]) { 
                            $ConfigFromFile.$_ = [Boolean]$Value
                        }
                        ElseIf ($Variables.AllCommandLineParameters.$_ -is [Array]) { 
                            $ConfigFromFile.$_ = [Array]$Value
                        }
                        Else { 
                            $ConfigFromFile.$_ = $Value -as $Variables.AllCommandLineParameters.$_.GetType().Name
                        }
                    }
                    Else { 
                        # Config parameter not in config file - use hardcoded value
                        $Value = $Variables.AllCommandLineParameters.$_
                        If ($Value -is [Switch]) { $Value = [Boolean]$Value }
                        $ConfigFromFile.$_ = $Value
                    }
                }
            )
        }
        If ($ConfigFromFile.EarningsAdjustmentFactor -le 0 -or $ConfigFromFile.EarningsAdjustmentFactor -gt 10) { 
            $ConfigFromFile.EarningsAdjustmentFactor = 1
            Write-Message -Level Warn "Default Earnings adjustment factor (value: $($ConfigFromFile.EarningsAdjustmentFactor)) is not within supported range (0 - 10); using default value $($ConfigFromFile.EarningsAdjustmentFactor)."
        }
    }
    Else { 
        $ConfigFromFile = Get-DefaultConfig
    }

    # Build custom pools configuration, create case insensitive hashtable (https://stackoverflow.com/questions/24054147/powershell-hash-tables-double-key-error-a-and-a)
    If ($Variables.PoolsConfigFile -and (Test-Path -LiteralPath $Variables.PoolsConfigFile -PathType Leaf)) { 
        Try { 
            $Variables.PoolsConfigData = [System.IO.File]::ReadAllLines($Variables.PoolsConfigFile) | ConvertFrom-Json -AsHashtable | Get-SortedObject
            $Variables.PoolsConfigFileTimestamp = (Get-Item -Path $Variables.PoolsConfigFile).LastWriteTime
        }
        Catch { 
            $Variables.PoolsConfigData = [Ordered]@{ }
            Write-Message -Level Warn "Pools configuration file '$($Variables.PoolsConfigFile.Replace("$(Convert-Path ".\")\", ".\"))' is corrupt and will be ignored."
        }
    }

    $ConfigFromFile.PoolsConfig = Get-PoolsConfig

    # Must update existing thread safe variable. Reassignment breaks updates to instances in other threads
    $ConfigFromFile.psBase.Keys.ForEach({ $Global:Config.$_ = $ConfigFromFile.$_ })

    $Variables.ShowAccuracy = $Config.ShowAccuracy
    $Variables.ShowAllMiners = $Config.ShowAllMiners
    $Variables.ShowEarning = $Config.ShowEarning
    $Variables.ShowEarningBias = $Config.ShowEarningBias
    $Variables.ShowMinerFee = $Config.ShowMinerFee
    $Variables.ShowPool = $Config.ShowPool
    $Variables.ShowPoolBalances = $Config.ShowPoolBalances
    $Variables.ShowPoolFee = $Config.ShowPoolFee
    $Variables.ShowPowerCost = $Config.ShowPowerCost
    $Variables.ShowPowerConsumption = $Config.ShowPowerConsumption
    $Variables.ShowProfit = $Config.ShowProfit
    $Variables.ShowProfitBias = $Config.ShowProfitBias
    $Variables.ShowCoinName = $Config.ShowCoinName
    $Variables.ShowCurrency = $Config.ShowCurrency
    $Variables.ShowUser = $Config.ShowUser
    $Variables.UIStyle = $Config.UIStyle
}

Function Update-ConfigFile { 

    Param (
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )

    # Changed config items
    ($Config.GetEnumerator().Name | Sort-Object).ForEach(
        { 
            Switch ($_) { 
                # "OldParameterName" { $Config.NewParameterName = $Config.$_; $Config.Remove($_) }
                Default { If ($_ -notin @(@($Variables.AllCommandLineParameters.psBase.Keys) + @("CryptoCompareAPIKeyParam") + @("DryRun") + @("PoolsConfig") + @("PoolsConfig"))) { $Config.Remove($_) } } # Remove unsupported config items
            }
        }
    )

    # Available regions have changed
    If ((Get-Region $Config.Region -List) -notcontains $Config.Region) { 
        $OldRegion = $Config.Region
        # Write message about new mining regions
        $Config.Region = Switch ($OldRegion) { 
            "Brazil"       { "USA West" }
            "Europe East"  { "Europe" }
            "Europe North" { "Europe" }
            "India"        { "Asia" }
            "US"           { "USA West" }
            Default        { "Europe" }
        }
        Write-Message -Level Warn "Available mining locations have changed ($OldRegion -> $($Config.Region)). Please verify your configuration."
    }

    $Config.ConfigFileVersion = $Variables.Branding.Version.ToString()
    Write-Config -ConfigFile $ConfigFile -Config $Config
    Write-Message -Level Verbose "Updated configuration file '$($ConfigFile)' to version $($Variables.Branding.Version.ToString())."
}

Function Write-Config { 

    Param (
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile,
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )

    $Header = 
"// This file was generated by $($Variables.Branding.ProductLabel)
// $($Variables.Branding.ProductLabel) will automatically add / convert / rename / update new settings when updating to a new version
"
    If (Test-Path -LiteralPath $ConfigFile -PathType Leaf) { 
        Copy-Item -Path $ConfigFile -Destination "$($ConfigFile)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").backup"
        Get-ChildItem -Path "$($ConfigFile)_*.backup" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse # Keep 10 backup copies
    }

    $NewConfig = $Config.Clone()

    $NewConfig.Remove("ConfigFile")
    $NewConfig.Remove("PoolsConfig")

    "$Header$($NewConfig | Get-SortedObject | ConvertTo-Json -Depth 10)" | Out-File -LiteralPath $ConfigFile -Force

    $Variables.ShowAccuracy = $Config.ShowAccuracy
    $Variables.ShowAllMiners = $Config.ShowAllMiners
    $Variables.ShowCoinName = $Config.ShowCoinName
    $Variables.ShowCurrency = $Config.ShowCurrency
    $Variables.ShowEarning = $Config.ShowEarning
    $Variables.ShowEarningBias = $Config.ShowEarningBias
    $Variables.ShowMinerFee = $Config.ShowMinerFee
    $Variables.ShowPool = $Config.ShowPool
    $Variables.ShowPoolBalances = $Config.ShowPoolBalances
    $Variables.ShowPoolFee = $Config.ShowPoolFee
    $Variables.ShowPowerConsumption = $Config.ShowPowerConsumption
    $Variables.ShowPowerCost = $Config.ShowPowerCost
    $Variables.ShowProfit = $Config.ShowProfit
    $Variables.ShowProfitBias = $Config.ShowProfitBias
    $Variables.ShowShares = $Config.ShowShares
    $Variables.ShowUser = $Config.ShowUser
    $Variables.UIStyle = $Config.UIStyle
}

Function Edit-File { 
    # Opens file in notepad. Notepad will remain in foreground until closed.

    Param (
        [Parameter(Mandatory = $false)]
        [String]$FileName
    )

    $FileWriteTime = (Get-Item -Path $FileName).LastWriteTime
    If (-not $FileWriteTime) { 
        If ($FileName -eq $Variables.PoolsConfigFile -and (Test-Path -LiteralPath ".\Data\PoolsConfig-Template.json" -PathType Leaf)) { 
            Copy-Item ".\Data\PoolsConfig-Template.json" $FileName
        }
    }

    If (-not ($NotepadProcess = (Get-CimInstance CIM_Process).Where({ $_.CommandLine -Like "*\Notepad.exe* $($FileName)" }))) { 
        $NotepadProcess = Start-Process -FilePath Notepad.exe -ArgumentList $FileName -PassThru
    }
    # Check if the window is not already in foreground
    While ($NotepadProcess = (Get-CimInstance CIM_Process).Where({ $_.CommandLine -Like "*\Notepad.exe* $($FileName)" })) { 
        Try { 
            $FGWindowPid = [IntPtr]::Zero
            [Win32]::GetWindowThreadProcessId([Win32]::GetForegroundWindow(), [ref]$FGWindowPid) | Out-Null
            $MainWindowHandle = (Get-Process -Id $NotepadProcess.ProcessId).MainWindowHandle
            If ($NotepadProcess.ProcessId -ne $FGWindowPid) { 
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
        Write-Message -Level Verbose "Saved '$FileName'. Changes will become active in next cycle."
        Return "Saved '$FileName'.`nChanges will become active in next cycle."
    }
    Else { 
        Return "No changes to '$FileName' made."
    }
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
                    If ($Object.$_ -is [Hashtable] -or $Object.$_ -is [PSCustomObject]) { $SortedObject | Add-Member $_ (Get-SortedObject $Object.$_) }
                    ElseIf ($Object.$_ -is [Array]) { $SortedObject | Add-Member $_ @($Object.$_ | Sort-Object) }
                    Else { $SortedObject | Add-Member $_ $Object.$_ }
                }
            )
        }
        "Hashtable|OrderedDictionary|SyncHashtable" { 
            $SortedObject = [Ordered]@{ }
            ($Object.GetEnumerator().Name | Sort-Object).ForEach(
                { 
                    If ($Object[$_] -is [Hashtable] -or $Object[$_] -is [PSCustomObject]) { $SortedObject[$_] = Get-SortedObject $Object[$_] }
                    ElseIf ($Object.$_ -is [Array]) { $SortedObject[$_] = @($Object[$_] | Sort-Object) }
                    Else { $SortedObject[$_] = $Object[$_] }
                }
            )
        }
        Default { 
            $SortedObject = $Object
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
            Return
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
        [Parameter(Mandatory = $true)]
        [String[]]$Names
    )

    $Names.ForEach(
        { 
            $Name = $_

            If ($Global:Stats[$Name] -isnot [Hashtable]) { 
                # Reduce number of errors
                If (-not (Test-Path -LiteralPath "Stats\$Name.txt" -PathType Leaf)) { 
                    Return
                }

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

            Return $Global:Stats[$Name]
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
        Features = $Features.psBase.Keys.ForEach{ If ($Features.$_) { $_ } }
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

    ForEach ($GPUArchitecture in $Variables.GPUArchitectureDbAMD.PSObject.Properties) { 
        If ($Architecture -match $GPUArchitecture.Value) { 
            Return $GPUArchitecture.Name
        }
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

    ForEach ($GPUArchitecture in $Variables.GPUArchitectureDbNvidia.PSObject.Properties) { 
        If ($GPUArchitecture.Value.Compute -contains $ComputeCapability) { 
            Return $GPUArchitecture.Name
        }
    }

    ForEach ($GPUArchitecture in $GPUArchitectureDbNvidia.PSObject.Properties) { 
        If ($Model -match $GPUArchitecture.Value.Model) { 
            Return $GPUArchitecture.Name
        }
    }
    Return "Other"
}

Function Get-Device { 

    Param (
        [Parameter(Mandatory = $false)]
        [String[]]$Name = @(),
        [Parameter(Mandatory = $false)]
        [String[]]$ExcludeName = @(),
        [Parameter(Mandatory = $false)]
        [Switch]$Refresh = $false
    )

    If ($Name) { 
        $DeviceList = [System.IO.File]::ReadAllLines("$PWD\Data\Devices.json") | ConvertFrom-Json
        $Name_Devices = $Name.ForEach(
            { 
                $Name_Split = $_ -split "#"
                $Name_Split = @($Name_Split | Select-Object -First 1) + @(($Name_Split | Select-Object -Skip 1).ForEach({ [Int]$_ }))
                $Name_Split += @("*") * (100 - $Name_Split.Count)

                $Name_Device = $DeviceList.("{0}" -f $Name_Split) | Select-Object *
                ($Name_Device | Get-Member -MemberType NoteProperty).Name.ForEach({ $Name_Device.$_ = $Name_Device.$_ -f $Name_Split })

                $Name_Device
            }
        )
    }

    If ($ExcludeName) { 
        If (-not $DeviceList) { $DeviceList = [System.IO.File]::ReadAllLines("$PWD\Data\Devices.json") | ConvertFrom-Json }
        $ExcludeName_Devices = $ExcludeName.ForEach(
            { 
                $ExcludeName_Split = $_ -split "#"
                $ExcludeName_Split = @($ExcludeName_Split | Select-Object -First 1) + @(($ExcludeName_Split | Select-Object -Skip 1).ForEach({ [Int]$_ }))
                $ExcludeName_Split += @("*") * (100 - $ExcludeName_Split.Count)

                $ExcludeName_Device = $DeviceList.("{0}" -f $ExcludeName_Split) | Select-Object *
                ($ExcludeName_Device | Get-Member -MemberType NoteProperty).Name.ForEach({ $ExcludeName_Device.$_ = $ExcludeName_Device.$_ -f $ExcludeName_Split })

                $ExcludeName_Device
            }
        )
    }

    If (-not $Variables.Devices -or $Refresh) { 
        $Variables.Devices = @()

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
                    $Device_CIM = $_ | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json

                    # Add normalised values
                    $Variables.Devices += $Device = [PSCustomObject]@{ 
                        Name      = $null
                        Model     = $Device_CIM.Name
                        Type      = "CPU"
                        Bus       = $null
                        Vendor    = $(
                            Switch -Regex ($Device_CIM.Manufacturer) { 
                                "Advanced Micro Devices" { "AMD" }
                                "AMD"                    { "AMD" }
                                "Intel"                  { "INTEL" }
                                "NVIDIA"                 { "NVIDIA" }
                                "Microsoft"              { "MICROSOFT" }
                                Default                  { $Device_CIM.Manufacturer -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "[^A-Z0-9]" }
                            }
                        )
                        Memory    = $null
                        MemoryGiB = $null
                    }

                    $Device | Add-Member @{ 
                        Id             = [Int]$Id
                        Type_Id        = [Int]$Type_Id.($Device.Type)
                        Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                        Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)
                    }

                    $Device.Name  = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)"
                    $Device.Model = ((($Device.Model -split " " -replace "Processor", "CPU" -replace "Graphics", "GPU") -notmatch $Device.Type -notmatch $Device.Vendor) -join " " -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "[^ A-Z0-9\.]" -replace " \s+").trim()

                    If (-not $Type_Vendor_Id.($Device.Type)) { 
                        $Type_Vendor_Id.($Device.Type) = @{ }
                    }

                    $Id ++
                    $Vendor_Id.($Device.Vendor) ++
                    $Type_Vendor_Id.($Device.Type).($Device.Vendor) ++
                    If ($Variables."Supported$($Device.Type)DeviceVendors" -contains $Device.Vendor) { $Type_Id.($Device.Type) ++ }

                    # Read CPU features
                    # $Device | Add-Member CPUfeatures ((Get-CpuId).Features | Sort-Object)
                    $Device | Add-Member CPUfeatures $Variables.CPUfeatures 

                    # Add raw data
                    $Device | Add-Member @{ 
                        CIM = $Device_CIM
                    }
                }
            )

            (Get-CimInstance CIM_VideoController).ForEach(
                { 
                    $Device_CIM = $_ | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json

                    $Device_PNP = [PSCustomObject]@{ }
                    (Get-PnpDevice $Device_CIM.PNPDeviceID | Get-PnpDeviceProperty).ForEach({ $Device_PNP | Add-Member $_.KeyName $_.Data })
                    $Device_PNP = $Device_PNP | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json

                    $Device_Reg = Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\$($Device_PNP.DEVPKEY_Device_Driver)" | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json

                    # Add normalised values
                    $Variables.Devices += $Device = [PSCustomObject]@{ 
                        Name      = $null
                        Model     = $Device_CIM.Name
                        Type      = "GPU"
                        Bus       = $(
                            If ($Device_PNP.DEVPKEY_Device_BusNumber -is [Int64] -or $Device_PNP.DEVPKEY_Device_BusNumber -is [Int32]) { 
                                [Int64]$Device_PNP.DEVPKEY_Device_BusNumber
                            }
                        )
                        Vendor    = $(
                            Switch -Regex ([String]$Device_CIM.AdapterCompatibility) { 
                                "Advanced Micro Devices" { "AMD" }
                                "AMD"                    { "AMD" }
                                "Intel"                  { "INTEL" }
                                "NVIDIA"                 { "NVIDIA" }
                                "Microsoft"              { "MICROSOFT" }
                                Default                  { $Device_CIM.AdapterCompatibility -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "[^A-Z0-9]" }
                            }
                        )
                        Memory    = [Math]::Max([UInt64]$Device_CIM.AdapterRAM, [uInt64]$Device_Reg.'HardwareInformation.qwMemorySize')
                        MemoryGiB = [Double]([Math]::Round([Math]::Max([UInt64]$Device_CIM.AdapterRAM, [uInt64]$Device_Reg.'HardwareInformation.qwMemorySize') / 0.05GB) / 20) # Round to nearest 50MB
                    }

                    $Device | Add-Member @{ 
                        Id             = [Int]$Id
                        Type_Id        = [Int]$Type_Id.($Device.Type)
                        Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                        Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)
                    }
                    #Unsupported devices start with DeviceID 100 (to not disrupt device order when running in a Citrix or RDP session)
                    If ($Variables."Supported$($Device.Type)DeviceVendors" -contains $Device.Vendor) { 
                        $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)"
                    }
                    ElseIf ($Device.Type -eq "CPU") { 
                        $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedCPUVendorID ++)"
                    }
                    Else { 
                        $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedGPUVendorID ++)"
                    }
                    $Device.Model = ((($Device.Model -split " " -replace "Processor", "CPU" -replace "Graphics", "GPU") -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") + "$([UInt64]($Device.Memory/1GB))GB" -join " " -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "[^ A-Z0-9\.]" -replace " \s+").trim()

                    If (-not $Type_Vendor_Id.($Device.Type)) { 
                        $Type_Vendor_Id.($Device.Type) = @{ }
                    }

                    $Id ++
                    $Vendor_Id.($Device.Vendor) ++
                    $Type_Vendor_Id.($Device.Type).($Device.Vendor) ++
                    If ($Variables."Supported$($Device.Type)DeviceVendors" -contains $Device.Vendor) { $Type_Id.($Device.Type) ++ }

                    # Add raw data
                    $Device | Add-Member @{ 
                        CIM = $Device_CIM
                        # PNP = $Device_PNP
                        # Reg = $Device_Reg
                    }
                }
            )
        }
        Catch { 
            Write-Message -Level Warn "WDDM device detection has failed."
        }
        Remove-Variable Device, Device_CIM, Device_PNP, Device_Reg -ErrorAction Ignore

        # Get OpenCL data
        Try { 
            [OpenCl.Platform]::GetPlatformIDs().ForEach(
                { 
                    # Skip devices with negative PCIbus 
                    ([OpenCl.Device]::GetDeviceIDs($_, [OpenCl.DeviceType]::All).Where({ $_.PCIbus -ge 0 }).ForEach({ $_ | ConvertTo-Json -WarningAction SilentlyContinue }) | Select-Object -Unique).ForEach(
                        { 
                            $Device_OpenCL = $_ | ConvertFrom-Json

                            # Add normalised values
                            $Device = [PSCustomObject]@{ 
                                Name      = $null
                                Model     = $Device_OpenCL.Name
                                Type      = $(
                                    Switch -Regex ([String]$Device_OpenCL.Type) { 
                                        "CPU"   { "CPU" }
                                        "GPU"   { "GPU" }
                                        Default { [String]$Device_OpenCL.Type -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "[^A-Z0-9]" }
                                    }
                                )
                                Bus       = $(
                                    If ($Device_OpenCL.PCIBus -is [Int64] -or $Device_OpenCL.PCIBus -is [Int32]) { 
                                        [Int64]$Device_OpenCL.PCIBus
                                    }
                                )
                                Vendor    = $(
                                    Switch -Regex ([String]$Device_OpenCL.Vendor) { 
                                        "Advanced Micro Devices" { "AMD" }
                                        "AMD"                    { "AMD" }
                                        "Intel"                  { "INTEL" }
                                        "NVIDIA"                 { "NVIDIA" }
                                        "Microsoft"              { "MICROSOFT" }
                                        Default                  { [String]$Device_OpenCL.Vendor -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "[^A-Z0-9]" }
                                    }
                                )
                                Memory    = [UInt64]$Device_OpenCL.GlobalMemSize
                                MemoryGiB = [Double]([Math]::Round($Device_OpenCL.GlobalMemSize / 0.05GB) / 20) # Round to nearest 50MB
                            }

                            $Device | Add-Member @{ 
                                Id             = [Int]$Id
                                Type_Id        = [Int]$Type_Id.($Device.Type)
                                Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                                Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)
                            }
                            #Unsupported devices get DeviceID 100 (to not disrupt device order when running in a Citrix or RDP session)
                            If ($Variables."Supported$($Device.Type)DeviceVendors" -contains $Device.Vendor) { 
                                $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)"
                            }
                            ElseIf ($Device.Type -eq "CPU") { 
                                $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedCPUVendorID ++)"
                            }
                            Else { 
                                $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedGPUVendorID ++)"
                            }
                            $Device.Model = ((($Device.Model -split " " -replace "Processor", "CPU" -replace "Graphics", "GPU") -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") + "$([UInt64]($Device.Memory/1GB))GB") -join " " -replace "\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel" -replace "[^A-Z0-9 ]"

                            If (-not $Type_Vendor_Id.($Device.Type)) { 
                                $Type_Vendor_Id.($Device.Type) = @{ }
                            }

                            If ($Variables.Devices.Where({ $_.Type -eq $Device.Type -and $_.Bus -eq $Device.Bus })) { 
                                $Device = $Variables.Devices.Where({ $_.Type -eq $Device.Type -and $_.Bus -eq $Device.Bus })
                            }
                            ElseIf ($Device.Type -eq "GPU" -and "AMD", "INTEL", "NVIDIA" -contains $Device.Vendor) { 
                                $Variables.Devices += $Device

                                If (-not $Type_Vendor_Index.($Device.Type)) { 
                                    $Type_Vendor_Index.($Device.Type) = @{ }
                                }

                                $Id ++
                                $Vendor_Id.($Device.Vendor) ++
                                $Type_Vendor_Id.($Device.Type).($Device.Vendor) ++
                                $Type_Id.($Device.Type) ++
                            }

                            # Add OpenCL specific data
                            $Device | Add-Member @{ 
                                Index                 = [Int]$Index
                                Type_Index            = [Int]$Type_Index.($Device.Type)
                                Vendor_Index          = [Int]$Vendor_Index.($Device.Vendor)
                                Type_Vendor_Index     = [Int]$Type_Vendor_Index.($Device.Type).($Device.Vendor)
                                PlatformId            = [Int]$PlatformId
                                PlatformId_Index      = [Int]$PlatformId_Index.($PlatformId)
                                Type_PlatformId_Index = [Int]$Type_PlatformId_Index.($Device.Type).($PlatformId)
                            } -Force

                            # Add raw data
                            $Device | Add-Member @{ 
                                OpenCL = $Device_OpenCL
                            } -Force

                            If (-not $Type_Vendor_Index.($Device.Type)) { 
                                $Type_Vendor_Index.($Device.Type) = @{ }
                            }
                            If (-not $Type_PlatformId_Index.($Device.Type)) { 
                                $Type_PlatformId_Index.($Device.Type) = @{ }
                            }

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
            )

            ($Variables.Devices.Where({ $_.Model -ne "Remote Display Adapter 0GB" -and $_.Vendor -ne "CitrixSystemsInc" -and $_.Bus -Is [Int64] }) | Sort-Object -Property Bus).ForEach(
                { 
                    If ($_.Type -eq "GPU") { 
                        If ($_.Vendor -eq "NVIDIA") { 
                            $_ | Add-Member "Architecture" (Get-GPUArchitectureNvidia -Model $_.Model -ComputeCapability $_.OpenCL.DeviceCapability)
                        }
                        ElseIf ($_.Vendor -eq "AMD") { 
                            $_ | Add-Member "Architecture" (Get-GPUArchitectureAMD -Model $_.Model -Architecture $_.OpenCL.Architecture)
                        }
                        Else { 
                            $_ | Add-Member "Architecture" "Other"
                        }
                    }

                    $_ | Add-Member @{ 
                        Slot             = [Int]$Slot
                        Type_Slot        = [Int]$Type_Slot.($_.Type)
                        Vendor_Slot      = [Int]$Vendor_Slot.($_.Vendor)
                        Type_Vendor_Slot = [Int]$Type_Vendor_Slot.($_.Type).($_.Vendor)
                    }

                    If (-not $Type_Vendor_Slot.($_.Type)) { 
                        $Type_Vendor_Slot.($_.Type) = @{ }
                    }

                    $Slot ++
                    $Type_Slot.($_.Type) ++
                    $Vendor_Slot.($_.Vendor) ++
                    $Type_Vendor_Slot.($_.Type).($_.Vendor) ++
                }
            )
        }
        Catch { 
            Write-Message -Level Warn "OpenCL device detection has failed."
        }
    }

    $Variables.Devices.ForEach(
        { 
            [Device]$Device = $_

            $Device.Bus_Index = @($Variables.Devices.Bus | Sort-Object).IndexOf([Int]$Device.Bus)
            $Device.Bus_Type_Index = @($Variables.Devices.Where({ $_.Type -eq $Device.Type }).Bus | Sort-Object).IndexOf([Int]$Device.Bus)
            $Device.Bus_Vendor_Index = @($Variables.Devices.Where({ $_.Vendor -eq $Device.Vendor }).Bus | Sort-Object).IndexOf([Int]$Device.Bus)
            $Device.Bus_Platform_Index = @($Variables.Devices.Where({ $_.Platform -eq $Device.Platform }).Bus | Sort-Object).IndexOf([Int]$Device.Bus)

            If (-not $Name -or ($Name_Devices.Where({ ($Device | Select-Object (($_ | Get-Member -MemberType NoteProperty).Name)) -like ($_ | Select-Object (($_ | Get-Member -MemberType NoteProperty).Name)) }))) { 
                If (-not $ExcludeName -or -not ($ExcludeName_Devices.Where({ ($Device | Select-Object (($_ | Get-Member -MemberType NoteProperty).Name)) -like ($_ | Select-Object (($_ | Get-Member -MemberType NoteProperty).Name)) }))) { 
                    $Device
                }
            }
        }
    )
}

Filter ConvertTo-Hash { 

    $Units = " kMGTPEZY" # k(ilo) in small letters, see https://en.wikipedia.org/wiki/Metric_prefix

    If ( $_ -eq $null -or [Double]::IsNaN($_)) { Return "n/a" }
    $Base1000 = [Math]::Truncate([Math]::Log([Math]::Abs([Double]$_), [Math]::Pow(1000, 1)))
    $Base1000 = [Math]::Max([Double]0, [Math]::Min($Base1000, $Units.Length - 1))
    $UnitValue = $_ / [Math]::Pow(1000, $Base1000)
    $Digits = If ($UnitValue -lt 10 ) { 3 } Else { 2 }
    "{0:n$($Digits)} $($Units[$Base1000])H/s" -f $UnitValue
}

Function Get-DecimalsFromValue { 
    # Used to limit absolute length of number
    # The larger the value, the less decimal digits are returned
    # Maximal $DecimalsMax decimals are returned

    Param (
        [Parameter(Mandatory = $true)]
        [Double]$Value,
        [Parameter(Mandatory = $true)]
        [Int]$DecimalsMax
    )

    $Decimals = 1 + $DecimalsMax - [Math]::Floor([Math]::Abs($Value)).ToString().Length
    If ($Decimals -gt $DecimalsMax) { $Decimals = 0 }

    Return $Decimals
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

    $CombinationKeys = ($Combination | Get-Member -MemberType NoteProperty).Name

    For ($I = $SizeMin; $I -le $SizeMax; $I ++) { 
        $X = [Math]::Pow(2, $I) - 1

        While ($X -le [Math]::Pow(2, $Value.Count) - 1) { 
            [PSCustomObject]@{ 
                Combination = ($CombinationKeys.Where({ $_ -band $X })).ForEach({ $Combination.$_ })
            }
            $Smallest = ($X -band - $X)
            $Ripple = $X + $Smallest
            $NewSmallest = ($Ripple -band - $Ripple)
            $Ones = (($NewSmallest / $Smallest) -shr 1) - 1
            $X = $Ripple -bor $Ones
        }
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
        [String]$StartF = 0x00000081, # STARTF_USESHOWWINDOW, STARTF_FORCEOFFFEEDBACK
        [Parameter(Mandatory = $false)]
        [String]$JobName,
        [Parameter(Mandatory = $false)]
        [String]$LogFile
    )

    # Cannot use Start-ThreadJob, $ControllerProcess.WaitForExit(500) would not work and miners remain running
    Start-Job -Name $JobName -ArgumentList $BinaryPath, $ArgumentList, $WorkingDirectory, $EnvBlock, $CreationFlags, $WindowStyle, $StartF, $PID { 
        Param ($BinaryPath, $ArgumentList, $WorkingDirectory, $EnvBlock, $CreationFlags, $WindowStyle, $StartF, $ControllerProcessID)

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
    public uint cb; public string lpReserved; public string lpDesktop; [MarshalAs(UnmanagedType.LPWStr)] public string lpTitle;
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
            "hidden" { "0x0000" } # SW_HIDE
            "normal" { "0x0001" } # SW_SHOWNORMAL
            Default  { "0x0007" } # SW_SHOWMINNOACTIVE
        }

        # Set local environment
        ($EnvBlock | Select-Object).ForEach({ Set-Item -Path "Env:$(($_ -split "=")[0])" "$(($_ -split "=")[1])" -Force })

        # StartupInfo Struct
        $StartupInfo = New-Object STARTUPINFO
        $StartupInfo.dwFlags = $StartF # StartupInfo.dwFlag
        $StartupInfo.wShowWindow = $ShowWindow # StartupInfo.ShowWindow
        $StartupInfo.cb = [System.Runtime.InteropServices.Marshal]::SizeOf($StartupInfo) # Struct Size

        # SECURITY_ATTRIBUTES Struct (Process & Thread)
        $SecAttr = New-Object SECURITY_ATTRIBUTES
        $SecAttr.Length = [System.Runtime.InteropServices.Marshal]::SizeOf($SecAttr)

        # CreateProcess --> lpCurrentDirectory
        If (-not $WorkingDirectory) { $WorkingDirectory = [IntPtr]::Zero }

        # ProcessInfo Struct
        $ProcessInfo = New-Object PROCESS_INFORMATION

        # Call CreateProcess
        [Void][Kernel32]::CreateProcess($BinaryPath, "$BinaryPath$ArgumentList", [ref]$SecAttr, [ref]$SecAttr, $false, $CreationFlags, [IntPtr]::Zero, $WorkingDirectory, [ref]$StartupInfo, [ref]$ProcessInfo)
        $Proc = Get-Process -Id $ProcessInfo.dwProcessId
        If ($null -eq $Proc) { 
            [PSCustomObject]@{ ProcessId = $null }
            Return 
        }

        [PSCustomObject]@{ProcessId = $Proc.Id }

        $ControllerProcess.Handle | Out-Null
        $Proc.Handle | Out-Null

        Do { 
            If ($ControllerProcess.WaitForExit(1000)) { 
                [Void]$Proc.CloseMainWindow()
                [Void]$Proc.WaitForExit()
                [Void]$Proc.Close()
            }
        } While ($Proc.HasExited -eq $false)

        Remove-Variable ArgumentList, BinaryPath, ControllerProcess, ControllerProcessID, CreationFlags, EnvBlock, Proc, ProcessInfo, SecAttr, ShowWindow, StartF, StartupInfo, WindowStyle, WorkingDirectory
        [System.GC]::Collect()
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

        # use first (topmost) directory, some miners, e.g. ClaymoreDual_v11.9, contain multiple miner binaries for different driver versions in various sub dirs
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

    If ($Variables.Algorithms[$Algorithm]) { Return $Variables.Algorithms[$Algorithm] }
    (Get-Culture).TextInfo.ToTitleCase($Algorithm.ToLower())
}

Function Get-Region { 

    Param (
        [Parameter(Mandatory = $true)]
        [String]$Region,
        [Parameter(Mandatory = $false)]
        [Switch]$List = $false
    )

    If ($List) { Return $Variables.Regions[$Region] }
    ElseIf ($Variables.Regions[$Region]) { Return $($Variables.Regions[$Region] | Select-Object -First 1) }
    Else { Return $Region }
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

    If (-not ($Variables.CoinNames[$Currency] -and $Variables.CurrencyAlgorithm[$Currency])) { 

        # Get mutex. Mutexes are shared across all threads and processes.
        # This lets us ensure only one thread is trying to write to the file at a time.
        $Mutex = New-Object System.Threading.Mutex($false, "$($Variables.Branding.ProductLabel)_DataFiles")

        If (-not $Variables.CurrencyAlgorithm[$Currency]) { 
            $Variables.CurrencyAlgorithm[$Currency] = Get-Algorithm $Algorithm
            # Attempt to aquire mutex, waiting up to 1 second if necessary. If aquired, update the file and release mutex
            If ($Mutex.WaitOne(1000)) { 
                $Variables.CurrencyAlgorithm | Get-SortedObject | ConvertTo-Json | Out-File -Path ".\Data\CurrencyAlgorithm.json" -ErrorAction Ignore -Force
                $Mutex.ReleaseMutex()
            }
        }
        If (-not $Variables.CoinNames[$Currency]) { 
            If ($CoinName = ((Get-Culture).TextInfo.ToTitleCase($CoinName.Trim().ToLower()) -replace "[^A-Z0-9\$\.]" -replace "coin$", "Coin" -replace "bitcoin$", "Bitcoin")) { 
                $Variables.CoinNames[$Currency] = $CoinName
                # Attempt to aquire mutex, waiting up to 1 second if necessary. If aquired, update the  file and release mutex
                If ($Mutex.WaitOne(1000)) { 
                    $Variables.CoinNames | Get-SortedObject | ConvertTo-Json | Out-File -Path ".\Data\CoinNames.json" -ErrorAction Ignore -Force
                    $Mutex.ReleaseMutex()
                }
            }
        }
    }
}

Function Get-AlgorithmFromCurrency { 

    Param (
        [Parameter(Mandatory = $false)]
        [String]$Currency
    )

    If ($Currency -and $Currency -ne "*") { 
        If ($Variables.CurrencyAlgorithm[$Currency]) { 
            Return $Variables.CurrencyAlgorithm[$Currency]
        }

        # Get mutex. Mutexes are shared across all threads and processes.
        # This lets us ensure only one thread is trying to write to the file at a time.
        $Mutex = New-Object System.Threading.Mutex($false, "$($Variables.Branding.ProductLabel)_DataFiles")

        # Attempt to aquire mutex, waiting up to 1 second if necessary. If aquired, update the coin names file and release mutex
        If ($Mutex.WaitOne(1000)) { 
            $Variables.CurrencyAlgorithm = [Ordered]@{ } # as case insensitive hash table
            (([System.IO.File]::ReadAllLines("$PWD\Data\CurrencyAlgorithm.json") | ConvertFrom-Json).PSObject.Properties).ForEach({ $Variables.CurrencyAlgorithm[$_.Name] = $_.Value })
            $Mutex.ReleaseMutex()
        }

        If ($Variables.CurrencyAlgorithm[$Currency]) { 
            Return $Variables.CurrencyAlgorithm[$Currency]
        }
    }
    Return $null
}

Function Get-CurrencyFromAlgorithm { 

    Param (
        [Parameter(Mandatory = $false)]
        [String]$Algorithm
    )

    If ($Algorithm) { 
        If ($Currencies = @($Variables.CurrencyAlgorithm.psBase.Keys.Where({ $Variables.CurrencyAlgorithm[$_] -eq $Algorithm }))) { 
            Return $Currencies
        }
    }
    Return $null
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
        If ($Variables.EquihashCoinPers[$Currency]) { 
            Return "$($Command)$($Variables.EquihashCoinPers[$Currency])"
        }

        $Variables.EquihashCoinPers = [Ordered]@{ } # as case insensitive hash table
        (([System.IO.File]::ReadAllLines("$PWD\Data\EquihashCoinPers.json") | ConvertFrom-Json).PSObject.Properties).ForEach({ $Variables.EquihashCoinPers[$_.Name] = $_.Value })

        If ($Variables.EquihashCoinPers[$Currency]) { 
            Return "$($Command)$($Variables.EquihashCoinPers[$Currency])"
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

        $Variables.CheckedForUpdate = [DateTime]::Now

        If ($Variables.Branding.ProductLabel -and [Version]$UpdateVersion.Version -gt $Variables.Branding.Version) { 
            If ($UpdateVersion.AutoUpdate) { 
                If ($Config.AutoUpdate) { 
                    Write-Message -Level Verbose "Version checker: New version $($UpdateVersion.Version) found. Starting update..."
                    Initialize-Autoupdate -UpdateVersion $UpdateVersion
                }
                Else { 
                    Write-Message -Level Verbose "Version checker: New version $($UpdateVersion.Version) found. Auto Update is disabled in config - You must update manually."
                }
            }
            Else { 
                Write-Message -Level Verbose "Version checker: New version is available. $($UpdateVersion.Version) does not support auto-update. You must update manually."
            }
            If ($Config.ShowChangeLog) { 
                Start-Process "https://github.com/UselessGuru/UG-Miner/releases/tag/v$($UpdateVersion.Version)"
            }
        }
        Else { 
            Write-Message -Level Verbose "Version checker: $($Variables.Branding.ProductLabel) $($Variables.Branding.Version) is current - no update available."
        }
    }
    Catch { 
        Write-Message -Level Warn "Version checker could not contact update server."
    }
}

Function Initialize-Autoupdate { 

    Param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UpdateVersion
    )

    Set-Location $Variables.MainPath
    If (-not (Test-Path -LiteralPath ".\AutoUpdate" -PathType Container)) { New-Item -Path . -Name "AutoUpdate" -ItemType Directory | Out-Null }
    If (-not (Test-Path -LiteralPath ".\Logs" -PathType Container)) { New-Item -Path . -Name "Logs" -ItemType Directory | Out-Null }

    $UpdateScriptURL = "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/AutoUpdate/Autoupdate.ps1"
    $UpdateScript = ".\AutoUpdate\AutoUpdate.ps1"
    $UpdateLog = ".\Logs\AutoUpdateLog_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").txt"

    # Download update script
    "Downloading update script..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose 
    Try { 
        Invoke-WebRequest -Uri $UpdateScriptURL -OutFile $UpdateScript -TimeoutSec 15
        "Executing update script..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose 
        . $UpdateScript
    }
    Catch { 
        "Downloading update script failed. Cannot complete auto-update :-(" | Tee-Object $UpdateLog -Append | Write-Message -Level Error
    }
}

Function Start-LogReader { 

    If ((Test-Path -LiteralPath $Config.LogViewerExe -PathType Leaf) -and (Test-Path -LiteralPath $Config.LogViewerConfig -PathType Leaf)) { 
        $Variables.LogViewerConfig = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Config.LogViewerConfig)
        $Variables.LogViewerExe = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Config.LogViewerExe)
        If ($SnaketailProcess = (Get-CimInstance CIM_Process).Where({ $_.CommandLine -eq """$($Variables.LogViewerExe)"" $($Variables.LogViewerConfig)" })) { 
            # Activate existing Snaketail window
            $LogViewerMainWindowHandle = (Get-Process -Id $SnaketailProcess.ProcessId).MainWindowHandle
            If (@($LogViewerMainWindowHandle).Count -eq 1) { 
                Try { 
                    [Win32]::ShowWindowAsync($LogViewerMainWindowHandle, 6) | Out-Null # SW_MINIMIZE 
                    [Win32]::ShowWindowAsync($LogViewerMainWindowHandle, 9) | Out-Null # SW_RESTORE
                }
                Catch {}
            }
        }
        Else { 
            [Void](& $($Variables.LogViewerExe) $($Variables.LogViewerConfig))
        }
    }
}

Function Get-ObsoleteMinerStats { 

    $StatFiles = @(Get-ChildItem ".\Stats\*" -Include "*_Hashrate.txt", "*_PowerConsumption.txt").BaseName
    $MinerNames = @(Get-ChildItem ".\Miners\*.ps1").BaseName

    Return @($StatFiles.Where({ (($_ -split "-")[0, 1] -join "-") -notin $MinerNames }))
}

Function Test-Prime { 

    Param (
        [Parameter(Mandatory = $true)]
        [Double]$Number
    )

    If ($Number -lt 2) { Return $false }
    If ($Number -eq 2) { Return $true }

    $PowNumber = [Int64][Math]::Pow($Number, 0.5)
    For ([Int64]$I = 3; $I -lt $PowNumber; $I += 2) { If ($Number % $I -eq 0) { Return $false } }

    Return $true
}

Function Update-DAGdata { 

    If (-not $Variables.DAGdata) { $Variables.DAGdata = [PSCustomObject]@{ } }
    If (-not $Variables.DAGdata."Algorithm") { $Variables.DAGdata | Add-Member "Algorithm" ([PSCustomObject]@{ }) }
    If (-not $Variables.DAGdata."Currency") { $Variables.DAGdata | Add-Member "Currency" ([PSCustomObject]@{ }) }
    If (-not $Variables.DAGdata."Updated") { $Variables.DAGdata | Add-Member "Updated" ([PSCustomObject]@{ }) }

    # Update on script start, once every 24hrs or if unable to get data from source
    $Url = "https://whattomine.com/coins.json"
    If ($Variables.DAGdata.Updated.$Url -lt $Variables.ScriptStartTime -or $Variables.DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
        # Get block data for from whattomine.com
        Try { 
            Write-Message -Level Info "Loading DAG data from '$Url'..."
            $DAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 5

            If ($DAGdataResponse.coins.PSObject.Properties.Name) { 
                $DAGdataResponse.coins.PSObject.Properties.Name.Where({ $DAGdataResponse.coins.$_.tag -ne "NICEHASH" }).ForEach(
                    { 
                        $AlgorithmNorm = Get-Algorithm $DAGdataResponse.coins.$_.algorithm
                        $Currency = $DAGdataResponse.coins.$_.tag
                        If (-not $Variables.CoinNames[$Currency]) { [Void](Add-CoinName -Algorithm $AlgorithmNorm -Currency $Currency -CoinName $_) }
                        If ($AlgorithmNorm -match $Variables.RegexAlgoHasDAG) { 
                            If ($DAGdataResponse.coins.$_.last_block -ge $Variables.DAGdata.Currency.$Currency.BlockHeight) { 
                                $DAGdata = Get-DAGdata -BlockHeight $DAGdataResponse.coins.$_.last_block -Currency $Currency -EpochReserve 2
                                If ($DAGdata.Epoch -and $DAGdata.Algorithm -match $Variables.RegexAlgoHasDAG) { 
                                    $DAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                                    $DAGdata | Add-Member Url $Url -Force
                                    $Variables.DAGdata.Currency | Add-Member $Currency $DAGdata -Force
                                }
                                Else { 
                                    Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                                }
                            }
                        }
                    }
                )
                $Variables.DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
            }
            Else { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url'."
            }
        }
        Catch { 
            Write-Message -Level Warn "Failed to load DAG data from '$Url'."
        }
    }

    # Update on script start, once every 24hrs or if unable to get data from source
    $Url = "https://minerstat.com/dag-size-calculator"
    If ($Variables.DAGdata.Updated.$Url -lt $Variables.ScriptStartTime -or $Variables.DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
        # Get block data from Minerstat
        Try { 
            Write-Message -Level Info "Loading DAG data from '$Url'..."
            $DAGdataResponse = Invoke-WebRequest -Uri $Url -TimeoutSec 5 # PWSH 6+ no longer supports basic parsing -> parse text
            If ($DAGdataResponse.statuscode -eq 200) { 
                (($DAGdataResponse.Content -split "\n" -replace '"', "'").Where({ $_ -like "<div class='block' title='Current block height of *" })).ForEach(
                    { 
                        $Currency = $_ -replace "^<div class='block' title='Current block height of " -replace "'>.*$"
                        If ($Currency -notin @("ETF")) {
                            # ETF has invalid DAG data of 444GiB
                            $BlockHeight = [Math]::Floor(($_ -replace "^<div class='block' title='Current block height of $Currency'>" -replace "</div>"))
                            If ((Get-AlgorithmFromCurrency -Currency $Currency) -and $BlockHeight -ge $Variables.DAGdata.Currency.$Currency.BlockHeight) { 
                                $DAGdata = Get-DAGdata -BlockHeight $BlockHeight -Currency $Currency -EpochReserve 2
                                If ($DAGdata.Epoch -and $DAGdata.Algorithm -match $Variables.RegexAlgoHasDAG) { 
                                    $DAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                                    $DAGdata | Add-Member Url $Url -Force
                                    $Variables.DAGdata.Currency | Add-Member $Currency $DAGdata -Force
                                }
                                Else { 
                                    Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                                }
                            }
                        }
                    }
                )
                $Variables.DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
            }
            Else { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url'."
            }
        }
        Catch { 
            Write-Message -Level Warn "Failed to load DAG data from '$Url'."
        }
    }

    # Update on script start, once every 24hrs or if unable to get data from source
    $Url = "https://prohashing.com/api/v1/currencies"
    If ($Variables.DAGdata.Updated.$Url -lt $Variables.ScriptStartTime -or $Variables.DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
        # Get block data from ProHashing
        Try { 
            Write-Message -Level Info "Loading DAG data from '$Url'..."
            $DAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 5

            If ($DAGdataResponse.code -eq 200) { 
                $DAGdataResponse.data.PSObject.Properties.Name.Where({ $DAGdataResponse.data.$_.enabled -and $DAGdataResponse.data.$_.height -and ($Variables.RegexAlgoHasDAG -match (Get-Algorithm $DAGdataResponse.data.$_.algo) -or $Variables.DAGdata.Currency.psBase.Keys -contains $_) }).ForEach(
                    { 
                        If (Get-AlgorithmFromCurrency -Currency $_) { 
                            If ($DAGdataResponse.data.$_.height -gt $Variables.DAGdata.Currency.$_.BlockHeight) { 
                                $DAGdata = Get-DAGdata -BlockHeight $DAGdataResponse.data.$_.height -Currency $_ -EpochReserve 2
                                If ($DAGdata.Epoch -and $DAGdata.Algorithm -match $Variables.RegexAlgoHasDAG) { 
                                    $DAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                                    $DAGdata | Add-Member Url $Url -Force
                                    $Variables.DAGdata.Currency | Add-Member $_ $DAGdata -Force
                                }
                                Else { 
                                    Write-Message -Level Warn "Failed to load DAG data for '$_' from '$Url'."
                                }
                            }
                        }
                    }
                )
                $Variables.DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
            }
            Else { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url'."
            }
        }
        Catch { 
            Write-Message -Level Warn "Failed to load DAG data from '$Url'."
        }
    }

    # Update on script start, once every 24hrs or if unable to get data from source
    $Currency = "SCC"
    $Url = "https://www.coinexplorer.net/api/v1/SCC/getblockcount"
    If (-not $Variables.DAGdata.Currency.$Currency.BlockHeight -or $Variables.DAGdata.Updated.$Url -lt $Variables.ScriptStartTime -or $Variables.DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
        # Get block data from StakeCube block explorer
        Try { 
            Write-Message -Level Info "Loading DAG data from '$Url'..."
            $DAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 15
            If ((Get-AlgorithmFromCurrency -Currency $Currency) -and $DAGdataResponse -gt $Variables.DAGdata.Currency.$Currency.BlockHeight) { 
                $DAGdata = Get-DAGdata -BlockHeight $DAGdataResponse -Currency $Currency -EpochReserve 2
                If ($DAGdata.Epoch) { 
                    $DAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                    $DAGdata | Add-Member Url $Url -Force
                    $Variables.DAGdata.Currency | Add-Member $Currency $DAGdata -Force
                    $Variables.DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
                }
                Else { 
                    Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                }
            }
        }
        Catch { 
            Write-Message -Level Warn "Failed to load DAG data from '$Url'."
        }
    }

    # Update on script start, once every 24hrs or if unable to get data from source
    $Currency = "EVR"
    $Url = "https://evr.cryptoscope.io/api/getblockcount"
    If (-not $Variables.DAGdata.Currency.$Currency.BlockHeight -or $Variables.DAGdata.Updated.$Url -lt $Variables.ScriptStartTime -or $Variables.DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
        # ZergPool (Coins) also supplies EVR DAG data
        If (-not ($Variables.PoolName -notmatch "ZergPoolCoins.*")) { 
            # Get block data from EVR block explorer
            Try { 
                Write-Message -Level Info "Loading DAG data from '$Url'..."
                $DAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 15
                If ((Get-AlgorithmFromCurrency -Currency $Currency) -and $DAGdataResponse.blockcount -gt $Variables.DAGdata.Currency.$Currency.BlockHeight) { 
                    $DAGdata = Get-DAGdata -BlockHeight $DAGdataResponse.blockcount -Currency $Currency -EpochReserve 2
                    If ($DAGdata.Epoch) { 
                        $DAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                        $DAGdata | Add-Member Url $Url -Force
                        $Variables.DAGdata.Currency | Add-Member $Currency $DAGdata -Force
                        $Variables.DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
                    }
                    Else { 
                        Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                    }
                }
            }
            Catch { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url'."
            }
        }
    }

    $Currency = "MEWC"
    $Url = "https://mewc.cryptoscope.io/api/getblockcount"
    If (-not $Variables.DAGdata.Currency.$Currency.BlockHeight -or $Variables.DAGdata.Updated.$Url -lt $Variables.ScriptStartTime -or $Variables.DAGdata.Updated.$Url -lt [DateTime]::Now.ToUniversalTime().AddDays(-1)) { 
        # ZergPool (Coins) also supplies MEWC DAG data
        If (-not ($Variables.PoolName -notmatch "ZergPoolCoins.*")) { 
            # Get block data from MeowCoin block explorer
            Try { 
                Write-Message -Level Info "Loading DAG data from '$Url'..."
                $DAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 15
                If ((Get-AlgorithmFromCurrency -Currency $Currency) -and $DAGdataResponse.blockcount -gt $Variables.DAGdata.Currency.$Currency.BlockHeight) { 
                    $DAGdata = Get-DAGdata -BlockHeight $DAGdataResponse.blockcount -Currency $Currency -EpochReserve 2
                    If ($DAGdata.Epoch) { 
                        $DAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                        $DAGdata | Add-Member Url $Url -Force
                        $Variables.DAGdata.Currency | Add-Member $Currency $DAGdata -Force
                        $Variables.DAGdata.Updated | Add-Member $Url ([DateTime]::Now.ToUniversalTime()) -Force
                    }
                    Else { 
                        Write-Message -Level Warn "Failed to load DAG data for '$Currency' from '$Url'."
                    }
                }
            }
            Catch { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url'."
            }
        }
    }

    If ($Variables.DAGdata.Updated.PSObject.Properties.Name.Where({ $Variables.DAGdata.Updated.$_ -gt $Variables.Timer })) { 
        #At least one DAG was updated, get maximum DAG size per algorithm
        $DAGdataKeys = @($Variables.DAGdata.Currency.PSObject.Properties.Name) # Store as array to avoid error 'An error occurred while enumerating through a collection: Collection was modified; enumeration operation may not execute.'

        ForEach ($Algorithm in @($DAGdataKeys.ForEach({ $Variables.DAGdata.Currency.$_.Algorithm }) | Select-Object -Unique)) { 
            Try { 
                $Variables.DAGdata.Algorithm | Add-Member $Algorithm (
                    [PSCustomObject]@{ 
                        BlockHeight = [Int]($DAGdataKeys.Where({ $Variables.DAGdata.Currency.$_.Algorithm -eq $Algorithm }).ForEach({ $Variables.DAGdata.Currency.$_.BlockHeight }) | Measure-Object -Maximum).Maximum
                        DAGsize     = [Int64]($DAGdataKeys.Where({ $Variables.DAGdata.Currency.$_.Algorithm -eq $Algorithm }).ForEach({ $Variables.DAGdata.Currency.$_.DAGsize }) | Measure-Object -Maximum).Maximum
                        Epoch       = [Int]($DAGdataKeys.Where({ $Variables.DAGdata.Currency.$_.Algorithm -eq $Algorithm }).ForEach({ $Variables.DAGdata.Currency.$_.Epoch }) | Measure-Object -Maximum).Maximum
                    }
                ) -Force
                $Variables.DAGdata.Algorithm.$Algorithm | Add-Member CoinName ($DAGdataKeys.Where({ $Variables.DAGdata.Currency.$_.DAGsize -eq $Variables.DAGdata.Algorithm.$Algorithm.DAGsize -and $Variables.DAGdata.Currency.$_.Algorithm -eq $Algorithm })) -Force
            }
            Catch { 
                Start-Sleep 0
            }
        }

        # Add default '*' (equal to highest)
        $Variables.DAGdata.Currency | Add-Member "*" (
            [PSCustomObject]@{ 
                BlockHeight = [Int]($DAGdataKeys.ForEach({ $Variables.DAGdata.Currency.$_.BlockHeight }) | Measure-Object -Maximum).Maximum
                CoinName    = "*"
                DAGsize     = [Int64]($DAGdataKeys.ForEach({ $Variables.DAGdata.Currency.$_.DAGsize }) | Measure-Object -Maximum).Maximum
                Epoch       = [Int]($DAGdataKeys.ForEach({ $Variables.DAGdata.Currency.$_.Epoch }) | Measure-Object -Maximum).Maximum
            }
        ) -Force
        $Variables.DAGdata = $Variables.DAGdata | Get-SortedObject
        $Variables.DAGdata | ConvertTo-Json -Depth 5 | Out-File -LiteralPath ".\Data\DAGdata.json" -Force
    }
    Remove-Variable Algorithm, BlockHeight, Currency, DAGdata, DAGdataKeys, DAGdataResponse, DAGsize, Epoch, Url -ErrorAction Ignore
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
            $DatasetBytesInit = 4294967296
            $DatasetBytesGrowth = 16777216
            $MixBytes = 256
            $Size = ($DatasetBytesInit + $DatasetBytesGrowth * $Epoch) - $MixBytes
            While (-not (Test-Prime ($Size / $MixBytes))) { 
                $Size -= 2 * $MixBytes
            }
            Break
        }
        "ERG" { 
            # https://github.com/RainbowMiner/RainbowMiner/issues/2102
            $Size = [Math]::Pow(2, 26)
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
            $Size = ($DatasetBytesInit + $DatasetBytesGrowth * $Epoch) - $MixBytes
            While (-not (Test-Prime ($Size / $MixBytes))) { 
                $Size -= 2 * $MixBytes
            }
            Break
        }
        "IRON" { 
            # IRON (FishHash) has static DAG size of 4608MB (Ethash epoch 448, https://github.com/iron-fish/fish-hash/blob/main/FishHash.pdf Chapter 4)
            $Size = 4608MB
            Break
        }
        "MEWC" { 
            If ($Epoch -ge 110) { $Epoch *= 4 } # https://github.com/Meowcoin-Foundation/meowpowminer/blob/6e1f38c1550ab23567960699ba1c05aad3513bcd/libcrypto/ethash.hpp#L48 & https://github.com/Meowcoin-Foundation/meowpowminer/blob/6e1f38c1550ab23567960699ba1c05aad3513bcd/libcrypto/ethash.cpp#L249C1-L254C6
            $DatasetBytesInit = 1GB
            $DatasetBytesGrowth = 8MB
            $MixBytes = 128
            $Size = ($DatasetBytesInit + $DatasetBytesGrowth * $Epoch) - $MixBytes
            While (-not (Test-Prime ($Size / $MixBytes))) { 
                $Size -= 2 * $MixBytes
            }
        }
        Default { 
            $DatasetBytesInit = 1GB
            $DatasetBytesGrowth = 8MB
            $MixBytes = 128
            $Size = ($DatasetBytesInit + $DatasetBytesGrowth * $Epoch) - $MixBytes
            While (-not (Test-Prime ($Size / $MixBytes))) { 
                $Size -= 2 * $MixBytes
            }
        }
    }

    Return [Int64]$Size
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

    If ($Algorithm = Get-AlgorithmFromCurrency $Currency) { 
        $Epoch = Get-DAGepoch -BlockHeight $BlockHeight -Algorithm $Algorithm -EpochReserve $EpochReserve

        Return [PSCustomObject]@{ 
            Algorithm   = $Algorithm
            BlockHeight = [Int]$BlockHeight
            CoinName    = [String]$Variables.CoinNames[$Currency]
            DAGsize     = [Int64](Get-DAGSize -Epoch $Epoch -Currency $Currency)
            Epoch       = [UInt16]$Epoch
        }
    }
    Return $null
}

Function Get-DAGepoch { 

    Param (
        [Parameter(Mandatory = $true)]
        [Double]$BlockHeight,
        [Parameter(Mandatory = $true)]
        [String]$Algorithm,
        [Parameter(Mandatory = $true)]
        [UInt16]$EpochReserve = 0
    )

    Switch ($Algorithm) { 
        "Autolykos2" { $BlockHeight -= 416768 } # Epoch 0 starts @ 417792
        "FishHash"   { Return 448 } # IRON (FishHash) has static DAG size of 4608MB (Ethash epoch 448, https://github.com/iron-fish/fish-hash/blob/main/FishHash.pdf Chapter 4)
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
        "Autolykos2"   { Return 1024 }
        "EtcHash"      { If ($BlockHeight -ge 11700000 ) { Return 60000 } Else { Return 30000 } }
        "EthashSHA256" { Return 4000 }
        "EvrProgPow"   { Return 12000 }
        "FiroPow"      { Return 1300 }
        "KawPow"       { Return 7500 }
        "MeowPow"      { Return 7500 } # https://github.com/Meowcoin-Foundation/meowpowminer/blob/6e1f38c1550ab23567960699ba1c05aad3513bcd/libcrypto/ethash.hpp#L32
        "Octopus"      { Return 524288 }
        "SCCpow"       { Return 3240 } # https://github.com/stakecube/sccminer/commit/16bdfcaccf9cba555f87c05f6b351e1318bd53aa#diff-200991710fe4ce846f543388b9b276e959e53b9bf5c7b7a8154b439ae8c066aeR32
        Default        { Return 30000 }
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
        $DataTable = New-Object Data.DataTable
        $First = $true
    }
    Process { 
        ForEach ($Object in $InputObject) { 
            $DataRow = $DataTable.NewRow()
            ForEach ($Property in $Object.PSObject.Properties) { 
                If ($First) { 
                    $Col = New-Object Data.DataColumn
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
    $Length = $Numbers.Length

    If ($Length % 2 -eq 0) { 
        # Even number of elements, so the median is the average of the two middle elements.
        ($Numbers[$Length / 2] + $Numbers[$Length / 2 - 1]) / 2
    }
    Else { 
        # Odd number of elements, so the median is the middle element.
        $Numbers[$Length / 2]
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

    If ( $Script:LastMemoryUsageByte -ne 0 ) { 
        If ($DiffBytes -ge 0) { 
            $Sign = "+"
        }
        $DiffText = ", $Sign$DiffBytes"
    }

    # Save last value in script global variable
    $Script:LastMemoryUsageByte = $MemUsageByte

    Return ("Memory usage {0:n1} MB ({1:n0} Bytes{2})" -f $MemUsageMB, $MemUsageByte, $Difftext)
}

Function Initialize-Environment { 

    # Verify donation data
    $Variables.DonationData = [System.IO.File]::ReadAllLines("$PWD\Data\DonationData.json") | ConvertFrom-Json -NoEnumerate
    If (-not $Variables.DonationData) { 
        Write-Error "Terminating Error - Cannot continue! File '.\Data\DonationData.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\DonationData.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    Write-Host "Loaded donation data."

    # Load donation log
    $Variables.DonationLog = [System.IO.File]::ReadAllLines("$PWD\Logs\DonateLog.json") | ConvertFrom-Json -NoEnumerate
    If (-not $Variables.DonationLog) { $Variables.DonationLog = @() }
    Else { Write-Host "Loaded donation log." }

    # Load algorithm list
    $Variables.Algorithms = [Ordered]@{ } # as case insensitive hash table
    (([System.IO.File]::ReadAllLines("$PWD\Data\Algorithms.json") | ConvertFrom-Json).PSObject.Properties).ForEach({ $Variables.Algorithms[$_.Name] = $_.Value })
    If (-not $Variables.Algorithms.Keys) { 
        Write-Error "Terminating Error - Cannot continue! File '.\Data\Algorithms.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\Algorithms.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }

    # Load coin names
    $Variables.CoinNames = [Ordered]@{ } # as case insensitive hash table
    (([System.IO.File]::ReadAllLines("$PWD\Data\CoinNames.json") | ConvertFrom-Json).PSObject.Properties).ForEach({ $Variables.CoinNames[$_.Name] = $_.Value })
    If (-not $Variables.CoinNames.Keys) { 
        Write-Error "Terminating Error - Cannot continue! File '.\Data\CoinNames.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\CoinNames.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }

    # Load currency algorithm data
    $Variables.CurrencyAlgorithm = [Ordered]@{ } # as case insensitive hash table
    (([System.IO.File]::ReadAllLines("$PWD\Data\CurrencyAlgorithm.json") | ConvertFrom-Json).PSObject.Properties).ForEach({ $Variables.CurrencyAlgorithm[$_.Name] = $_.Value })
    If (-not $Variables.CurrencyAlgorithm.Keys) { 
        Write-Error "Terminating Error - Cannot continue! File '.\Data\CurrencyAlgorithm.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\CurrencyAlgorithm.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Start-Sleep -Seconds 10
        Exit
    }

    # Load EquihashCoinPers data
    $Variables.EquihashCoinPers = [Ordered]@{ } # as case insensitive hash table
    (([System.IO.File]::ReadAllLines("$PWD\Data\EquihashCoinPers.json") | ConvertFrom-Json).PSObject.Properties).ForEach({ $Variables.EquihashCoinPers[$_.Name] = $_.Value })
    If (-not $Variables.EquihashCoinPers) { 
        Write-Error "Terminating Error - Cannot continue! File '.\Data\EquihashCoinPers.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\EquihashCoinPers.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    Write-Host "Loaded algorithm & coin database."

    # Load regions list
    $Variables.Regions = [Ordered]@{ } # as case insensitive hash table
    (([System.IO.File]::ReadAllLines("$PWD\Data\Regions.json") | ConvertFrom-Json).PSObject.Properties).ForEach({ $Variables.Regions[$_.Name] = @($_.Value) })
    If (-not $Variables.Regions.Keys) { 
        Write-Error "Terminating Error - Cannot continue! File '.\Data\Regions.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\Regions.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    Write-Host "Loaded regions database."

    # Load FIAT currencies list
    $Variables.FIATcurrencies = [System.IO.File]::ReadAllLines("$PWD\Data\FIATcurrencies.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject
    If (-not $Variables.FIATcurrencies) { 
        Write-Error "Terminating Error - Cannot continue! File '.\Data\FIATcurrencies.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\FIATcurrencies.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    Write-Host "Loaded fiat currencies database."

    # Load unprofitable algorithms
    $Variables.UnprofitableAlgorithms = [System.IO.File]::ReadAllLines("$PWD\Data\UnprofitableAlgorithms.json") | ConvertFrom-Json -ErrorAction Stop -AsHashtable | Get-SortedObject
    If (-not $Variables.UnprofitableAlgorithms.Count) { 
        Write-Error "Error loading list of unprofitable algorithms. File '.\Data\UnprofitableAlgorithms.json' is not a valid $($Variables.Branding.ProductLabel) JSON data file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\UnprofitableAlgorithms.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    Write-Host "Loaded list of unprofitable algorithms."

    # Load DAG data, if not available it will get recreated
    $Variables.DAGdata = [System.IO.File]::ReadAllLines("$PWD\Data\DAGdata.json") | ConvertFrom-Json | Get-SortedObject
    If ($Variables.DAGdata) { Write-Host "Loaded DAG database." }

    # Load PoolsLastUsed data
    $Variables.PoolsLastUsed = [System.IO.File]::ReadAllLines("$PWD\Data\PoolsLastUsed.json") | ConvertFrom-Json -AsHashtable
    If (-not $Variables.PoolsLastUsed.psBase.Keys) { $Variables.PoolsLastUsed = @{ } }
    Else { Write-Host "Loaded pools last used data." }

    # Load AlgorithmsLastUsed data
    $Variables.AlgorithmsLastUsed = [System.IO.File]::ReadAllLines("$PWD\Data\AlgorithmsLastUsed.json") | ConvertFrom-Json -AsHashtable
    If (-not $Variables.AlgorithmsLastUsed.psBase.Keys) { $Variables.AlgorithmsLastUsed = @{ } }
    Else { Write-Host "Loaded algorithm last used data." }

    # Load EarningsChart data to make it available early in GUI
    If (Test-Path -LiteralPath ".\Data\EarningsChartData.json" -PathType Leaf) { $Variables.EarningsChartData = [System.IO.File]::ReadAllLines("$PWD\Data\EarningsChartData.json") | ConvertFrom-Json }
    Else { Write-Host "Loaded earnings chart data." }

    # Load Balances data to make it available early in GUI
    If (Test-Path -LiteralPath ".\Data\Balances.json" -PathType Leaf) { $Variables.Balances = [System.IO.File]::ReadAllLines("$PWD\Data\Balances.json") | ConvertFrom-Json }
    Else { Write-Host "Loaded balances data." }

    # Load CUDA version table
    $Variables.CUDAVersionTable = [System.IO.File]::ReadAllLines("$PWD\Data\CUDAVersion.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject
    If (-not $Variables.CUDAVersionTable) { 
        Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\CUDAVersion.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\CUDAVersion.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    Else { Write-Host "Loaded CUDA version table." }

    # Load NVidia GPU architecture table
    $Variables.GPUArchitectureDbNvidia = [System.IO.File]::ReadAllLines("$PWD\Data\GPUArchitectureNvidia.json") | ConvertFrom-Json -ErrorAction Ignore
    If (-not $Variables.GPUArchitectureDbNvidia) { 
        Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\GPUArchitectureNvidia.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\GPUArchitectureNvidia.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    Else { Write-Host "Loaded NVidia GPU architecture table." }

    # Load AMD GPU architecture table
    $Variables.GPUArchitectureDbAMD = [System.IO.File]::ReadAllLines("$PWD\Data\GPUArchitectureAMD.json") | ConvertFrom-Json -ErrorAction Ignore
    If (-not $Variables.GPUArchitectureDbAMD) { 
        Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\GPUArchitectureAMD.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\GPUArchitectureAMD.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    Else { Write-Host "Loaded AMD GPU architecture table." }

    $Variables.BalancesCurrencies = @($Variables.Balances.PSObject.Properties.Name.ForEach({ $Variables.Balances.$_.Currency }) | Sort-Object -Unique)

    Write-Host ""
}