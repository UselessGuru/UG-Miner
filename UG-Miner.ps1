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
File:           UG-Miner.ps1
Version:        6.5.13
Version date:   2025/09/30
#>

using module .\Includes\Include.psm1

Param(
    [Parameter(Mandatory = $false)]
    [String[]]$Algorithm = @(), # i.e. @("Equihash1445", "Ethash", "KawPow") etc. If '+' is used, then only the explicitly enabled algorithms are used. If '-' is used, then all algorithms except the disabled ones are used. Do not combine '+' and '-' concurrently.
    [Parameter(Mandatory = $false)]
    [String]$APIlogfile = "", # API will log all requests to this file, leave empty to disable
    [Parameter(Mandatory = $false)]
    [Int]$APIport = 3999, # TCP Port for API and web GUI
    [Parameter(Mandatory = $false)]
    [Switch]$AutoReboot = $true, # If true will reboot computer when a miner is completely dead, e.g. unresponsive
    [Parameter(Mandatory = $false)]
    [Switch]$AutoUpdate = $true, # If true will automatically update to the new version
    [Parameter(Mandatory = $false)]
    [Int]$AutoUpdateCheckInterval = 1, # If true will periodically check for a new program version every n days (0 to disable)
    [Parameter(Mandatory = $false)]
    [Switch]$BackupOnAutoUpdate = $true, # If true a backup copy will be saved as '[UG-Miner directory]\AutoUpdate\Backup_v[version]_[date_time].zip' when updateing
    [Parameter(Mandatory = $false)]
    [Double]$BadShareRatioThreshold = 0.05, # Allowed ratio of bad shares (total / bad) as reported by the miner. If the ratio exceeds the configured threshold then the miner will get marked as failed. Allowed values: 0.00 - 1.00. 0 disables this check
    [Parameter(Mandatory = $false)]
    [Boolean]$BalancesKeepAlive = $true, # If true will force mining at a pool to protect your earnings (some pools auto-purge the wallet after longer periods of inactivity, see '\Data\PoolData.Json' BalancesKeepAlive properties)
    [Parameter(Mandatory = $false)]
    [Boolean]$BalancesShowSums = $true, # Show 1hr / 6hrs / 24hr / 7day & 30day pool earnings sums in web dashboard
    [Parameter(Mandatory = $false)]
    [Boolean]$BalancesShowAverages = $true, # Show 1hr / 24hr & 7day pool earnings averages in web dashboard
    [Parameter(Mandatory = $false)]
    [Boolean]$BalancesShowInAllCurrencies = $true, # If true pool balances will be shown in all currencies in web dashboard
    [Parameter(Mandatory = $false)]
    [Boolean]$BalancesShowInFIATcurrency = $true, # If true pool balances will be shown in main currency in web dashboard
    [Parameter(Mandatory = $false)]
    [String[]]$BalancesTrackerExcludePools = @(), # Balances tracker will not track these pools
    [Parameter(Mandatory = $false)]
    [Switch]$BalancesTrackerLog = $false, # If true will store all balance tracker data in .\Logs\EarningTrackerLog.csv
    [Parameter(Mandatory = $false)]
    [UInt16]$BalancesTrackerPollInterval = 10, # minutes, interval duration to trigger background task to collect pool balances & earnings data; set to 0 to disable, minumum value 10
    [Parameter(Mandatory = $false)]
    [Switch]$BenchmarkAllPoolAlgorithmCombinations = [Boolean]($Host.Name -eq "Visual Studio Code Host"),
    [Parameter(Mandatory = $false)]
    [Switch]$CalculatePowerCost = [Boolean](Get-ItemProperty -Path "HKCU:\Software\HWiNFO64\VSB" -ErrorAction Ignore), # If true power consumption will be read from miners and calculate power cost, required for true profit calculation
    [Parameter(Mandatory = $false)]
    [String]$ConfigFile = ".\Config\Config.json", # Config file name
    [Parameter(Mandatory = $false)]
    [Int]$CPUMiningReserveCPUcore = 1, # Number of CPU cores reserved for main script processing. Helps to get more stable hashrates and faster core loop processing.
    [Parameter(Mandatory = $false)]
    [Int]$CPUMinerProcessPriority = "-2", # Process priority for CPU miners
    [Parameter(Mandatory = $false)]
    [String[]]$Currency = @(), # i.e. @("+ETC", +EVR", "+KIIRO") etc. If '+' is used, then only the explicitly enabled currencies are used. If '-' is used, then all currencies except the disabled ones are used. Do not combine '+' and '-' concurrently.
    [Parameter(Mandatory = $false)]
    [Int]$DecimalsMax = 6, # Display numbers with maximal n decimal digits (larger numbers are shown with less decimal digits)
    [Parameter(Mandatory = $false)]
    [Int]$Delay = 0, # seconds between stop and start of miners, use only when getting blue screens on miner switches
    [Parameter(Mandatory = $false)]
    [Switch]$DisableCpuMiningOnBattery = $false, # If true will not use CPU miners while running on battery
    [Parameter(Mandatory = $false)]
    [Switch]$DisableDualAlgoMining = $false, # If true will not use any dual algorithm miners
    [Parameter(Mandatory = $false)]
    [Switch]$DisableMinerFee = $false, # Set to true to disable miner fees (Note: not all miners support turning off their built in fees, others will reduce the hashrate)
    [Parameter(Mandatory = $false)]
    [Switch]$DisableMinersWithFee = $false, # Set to true to disable all miners which contain fees
    [Parameter(Mandatory = $false)]
    [Switch]$DisableSingleAlgoMining = $false, # If true will not use any single algorithm miners
    [Parameter(Mandatory = $false)]
    [Int]$Donation = 15, # Minutes per Day
    [Parameter(Mandatory = $false)]
    [Switch]$DryRun = $false, # If true will do all the benchmarks, but will not mine
    [Parameter(Mandatory = $false)]
    [Double]$EarningsAdjustmentFactor = 1, # Default adjustment factor for prices reported by ALL pools (unless there is a per pool value configuration definined). Prices will be multiplied with this. Allowed values: 0.0 - 10.0
    [Parameter(Mandatory = $false)]
    [String[]]$ExcludeDeviceName = @(), # Array of disabled devices, e.g. @("CPU#00", "GPU#02"); by default all devices are enabled
    [Parameter(Mandatory = $false)]
    [String[]]$ExcludeMinerName = @(), # List of miners to be excluded; Either specify miner short name, e.g. "PhoenixMiner" (without '-v...') to exclude any version of the miner, or use the full miner name incl. version information
    [Parameter(Mandatory = $false)]
    [String[]]$ExtraCurrencies = @("ETC", "ETH", "mBTC"), # Extra currencies used in balances summary, enter 'real-world' or crypto currencies, mBTC (milli BTC) is also allowed
    [Parameter(Mandatory = $false)]
    [String]$FIATcurrency = (Get-Culture).NumberFormat.CurrencySymbol, # Default main 'real-money' currency, i.e. GBP, USD, AUD, NZD etc. Do not use crypto currencies
    [Parameter(Mandatory = $false)]
    [Int]$GPUMinerProcessPriority = "-1", # Process priority for GPU miners
    [Parameter(Mandatory = $false)]
    [Switch]$IdleDetection = $false, # If true will start mining only if system is idle for $IdleSec seconds
    [Parameter(Mandatory = $false)]
    [Int]$IdleSec = 120, # seconds the system must be idle before mining starts
    [Parameter(Mandatory = $false)]
    [Switch]$IgnoreMinerFee = $false, # If true will ignore miner fee for earnings & profit calculation
    [Parameter(Mandatory = $false)]
    [Switch]$IgnorePoolFee = $false, # If true will ignore pool fee for earnings & profit calculation
    [Parameter(Mandatory = $false)]
    [Switch]$IgnorePowerCost = $false, # If true will ignore power cost in best miner selection, instead miners with best earnings will be selected
    [Parameter(Mandatory = $false)]
    [Switch]$Ignore0HashrateSample = $false, # If true will ignore 0 hashrate samples when setting miner status to 'warming up'
    [Parameter(Mandatory = $false)]
    [Int]$Interval = 90, # Average cycle loop duration (seconds), min 60, max 3600
    [Parameter(Mandatory = $false)]
    [Switch]$LegacyGUI = $false, # If true will start legacy GUI
    [Parameter(Mandatory = $false)]
    [Switch]$LegacyGUIStartMinimized = $true, # If true will start legacy GUI as minimized window
    [Parameter(Mandatory = $false)]
    [Switch]$LogBalanceAPIResponse = $false, # If true will log the pool balance API data
    [Parameter(Mandatory = $false)]
    [String[]]$LogLevel = @("Error", "Warn", "Info", "Verbose"), # Log level detail to be written to log file and screen, see Write-Message function; any of "Debug", "Error", "Info", "MemDbg", "Verbose", "Warn"
    [Parameter(Mandatory = $false)]
    [String]$LogViewerConfig = ".\Utils\UG-Miner_LogReader.xml", # Path to external log viewer config file
    [Parameter(Mandatory = $false)]
    [String]$LogViewerExe = ".\Utils\SnakeTail.exe", # Path to optional external log reader (SnakeTail) [https://github.com/snakefoot/snaketail-net], leave empty to disable
    [Parameter(Mandatory = $false)]
    [Double]$MinAccuracy = 0.5, # Use only pools with price accuracy greater than the configured value. Allowed values: 0.0 - 1.0 (0% - 100%)
    [Parameter(Mandatory = $false)]
    [Int]$MinCycle = 1, # Minimum number of cycles a miner must mine the same available algorithm@pool continously before switching is allowed (e.g. 3 would force a miner to stick mining algorithm@pool for min. 3 cycles before switching to another algorithm or pool)
    [Parameter(Mandatory = $false)]
    [Int]$MinDataSample = 20, # Minimum number of hashrate samples required to store hashrate
    [Parameter(Mandatory = $false)]
    [Int]$MinerSet = 3, # Defines the set of available miners. 0: Benchmark best miner per algorithm and device only; 1: Benchmark optimal miners (more than one per algorithm and device); 2: Benchmark all miners per algorithm and device (except those in the unprofitable algorithms list); 3: Benchmark most miners per algorithm and device (even those in the unprofitable algorithms list, not recommended)
    [Parameter(Mandatory = $false)]
    [Double]$MinerSwitchingThreshold = 10, # Will not switch miners unless another miner has n% higher earnings / profit
    [Parameter(Mandatory = $false)]
    [Switch]$MinerUseBestPoolsOnly = $false, # If true it will use only the best pools for mining. Some miners / algorithms are incompatible with some pools. In this case the miner will not be available. This can impact profitability, but is less CPU heavy. This was the default algorithm for versions older than 5.x
    [Parameter(Mandatory = $false)]
    [String]$MinerWindowStyle = "minimized", # "minimized": miner window is minimized (default), but accessible; "normal": miner windows are shown normally; "hidden": miners will run as a hidden background task and are not accessible (not recommended)
    [Parameter(Mandatory = $false)]
    [Switch]$MinerWindowStyleNormalWhenBenchmarking = $true, # If true miner window is shown normal when benchmarking (recommended to better see miner messages)
    [Parameter(Mandatory = $false)]
    [String]$MiningDutchAPIKey = "", # MiningDutch API Key (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [String]$MiningDutchUserName = "UselessGuru", # MiningDutch username
    [Parameter(Mandatory = $false)]
    [String]$MiningPoolHubAPIKey = "", # MiningPoolHub API Key (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [String]$MiningPoolHubUserName = "UselessGuru", # MiningPoolHub username
    [Parameter(Mandatory = $false)]
    [Int]$MinWorker = 25, # Minimum workers mining the algorithm at the pool. If less miners are mining the algorithm then the pool will be disabled. This is also a per pool setting configurable in 'PoolsConfig.json'
    # [Parameter(Mandatory = $false)]
    # [String]$MonitoringServer = "https://UG-Miner.com", # Monitoring server hostname, default "https://UG-Miner.com"
    # [Parameter(Mandatory = $false)]
    # [String]$MonitoringUser = "", # Monitoring user ID as registered with monitoring server
    [Parameter(Mandatory = $false)]
    [String]$NiceHashAPIKey = "", # NiceHash API Key (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [String]$NiceHashAPISecret = "", # NiceHash API Secret (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [String]$NiceHashWallet = "", # NiceHash wallet, if left empty $Wallets[BTC] is used
    [Parameter(Mandatory = $false)]
    [String]$NiceHashOrganizationId = "", # NiceHash Organization Id (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [Switch]$OpenFirewallPorts = $true, # If true will open firewall ports for all miners (requires admin rights!)
    [Parameter(Mandatory = $false)]
    [String]$PayoutCurrency = "BTC", # i.e. BTC, LTC, ZEC, ETH etc., default PayoutCurrency for all pools that have no other currency configured, PayoutCurrency is also a per pool setting (to be configured in 'PoolsConfig.json')
    [Parameter(Mandatory = $false)]
    [Switch]$PoolAllow0Hashrate = $false, # Allow mining to the pool even when there is 0 (or no) hashrate reported in the API (not recommended)
    [Parameter(Mandatory = $false)]
    [Switch]$PoolAllow0Price = $false, # Allow mining to the pool even when the price reported in the API is 0 (not recommended)
    [Parameter(Mandatory = $false)]
    [Int]$PoolAPIallowedFailureCount = 3, # Max number of pool API request attempts
    [Parameter(Mandatory = $false)]
    [Double]$PoolAllowedPriceIncreaseFactor = 5, # Max. allowed price increase compared with last price. If price increase is higher then the pool will be marked as unavaliable.
    [Parameter(Mandatory = $false)]
    [Int]$PoolAPIretryInterval = 3, # Time (in seconds) until pool API request retry. Note: Do not set this value too small to avoid temporary blocking by pool
    [Parameter(Mandatory = $false)]
    [Int]$PoolAPItimeout = 20, # Time (in seconds) until it aborts the pool request (useful if a pool's API is stuck). Note: do not set this value too small or UG-Miner will not be able to get any pool data
    [Parameter(Mandatory = $false)]
    [String]$PoolsConfigFile = ".\Config\PoolsConfig.json", # PoolsConfig file name
    [Parameter(Mandatory = $false)]
    [String[]]$PoolName = @("HashCryptosPlus", "HiveON", "MiningDutchPlus", "NiceHash", "ProHashingPlus", "ZPoolPlus"), # Valid values are "HashCryptos", "HashCryptos24hr", "HashCryptosPlus", "HiveON", "MiningDutch", "MiningDutch24hr", "MiningDutchPlus", "NiceHash", "ProHashing", "ProHashing24hr", "ProHashingPlus", "ZPool", "ZPool24hr", "ZPoolPlus"
    [Parameter(Mandatory = $false)]
    [Int]$PoolTimeout = 20, # Time (in seconds) until it aborts the pool request (useful if a pool's API is stuck). Note: do not set this value too small or UG-Miner will not be able to get any pool data
    [Parameter(Mandatory = $false)]
    [Hashtable]$PowerPricekWh = @{ "00:00" = 0.26; "12:00" = 0.3 }, # Price of power per kW⋅h (in $Currency, e.g. CHF), valid from HH:mm (24hr format)
    [Parameter(Mandatory = $false)]
    [Hashtable]$PowerConsumption = @{ }, # Static power consumption per device in watt, e.g. @{ "GPU#03" = 25, "GPU#04 = 55" } (in case HWiNFO cannot read power consumption)
    [Parameter(Mandatory = $false)]
    [Double]$PowerConsumptionIdleSystemW = 60, # Watt, power consumption of idle system. Part of profit calculation.
    [Parameter(Mandatory = $false)]
    [Double]$ProfitabilityThreshold = -99, # Minimum profit threshold, if profit is less than the configured value (in $Currency, e.g. CHF) mining will stop (except for benchmarking & power consumption measuring)
    [Parameter(Mandatory = $false)]
    [String]$ProHashingAPIkey = "", # ProHashing API Key (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [String]$ProHashingMiningMode = "PPS", # Either PPS (Pay Per Share) or PPLNS (Pay per Last N Shares)
    [Parameter(Mandatory = $false)]
    [String]$ProHashingUserName = "UselessGuru", # ProHashing UserName, if left empty then $UserName is used
    [Parameter(Mandatory = $false)]
    [String]$Proxy = "", # i.e http://192.0.0.1:8080
    [Parameter(Mandatory = $false)]
    [String]$Region = "Europe", # Used to determine pool nearest to you. One of "Australia", "Asia", "Brazil", "Canada", "Europe", "HongKong", "India", "Kazakhstan", "Russia", "USA East", "USA West"
    # [Parameter(Mandatory = $false)]
    # [Switch]$ReportToServer = $false, # If true will report worker status to central monitoring server
    [Parameter(Mandatory = $false)]
    [Switch]$ShowColumnAccuracy = $true, # Show pool data accuracy column in main text window miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowAllMiners = $false, # Always show all miners in main text window miner overview (if false, only the best miners will be shown except when in benchmark / PowerConsumption measurement)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowChangeLog = $true, # If true will show the changlog when an update is available
    [Parameter(Mandatory = $false)]
    [Switch]$ShowColumnCoinName = $true, # Show CoinName column in main text window miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowConsole = $true, # If true will console window will be shown
    [Parameter(Mandatory = $false)]
    [Switch]$ShowColumnCurrency = $true, # Show Currency column in main text window miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowColumnEarnings = $true, # Show miner earnings column in main text window miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowColumnEarningsBias = $true, # Show miner earnings bias column in main text window miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowColumnHashrate = $true, # Show hashrate(s) column in main text window miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowColumnMinerFee = $true, # Show miner fee column in main text window miner overview (if fees are available, t.b.d. in miner files, property '[Double]Fee')
    [Parameter(Mandatory = $false)]
    [Switch]$ShowPoolBalances = $false, # Display pool balances & earnings information in main text window, requires BalancesTrackerPollInterval -gt 0
    [Parameter(Mandatory = $false)]
    [Switch]$ShowColumnPool = $true, # Show pool column in main text window miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowColumnPoolFee = $true, # Show pool fee column in main text window miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowColumnProfit = $true, # Show miner profit column in main text window miner overview (if power price is available, see PowerPricekWh)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowColumnProfitBias = $true, # Show miner profit bias column in main text window miner overview (if power price is available, see PowerPricekWh)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowColumnPowerConsumption = $true, # Show power consumption column in main text window miner overview (if power price is available, see PowerPricekWh)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowColumnPowerCost = $true, # Show power cost column in main text window miner overview (if power price is available, see PowerPricekWh)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowShares = $true, # Show share data in log
    [Parameter(Mandatory = $false)]
    [Switch]$ShowColumnUser = $false, # Show pool user name column in main text window miner overview
    # [Parameter(Mandatory = $false)]
    # [Switch]$ShowWorkerStatus = $true, # Show worker status from other rigs (data retrieved from monitoring server)
    [Parameter(Mandatory = $false)]
    [String]$SSL = "Prefer", # SSL pool connections: One of three values: 'Prefer' (use where available), 'Never' (pools that only allow SSL connections are marked as unavailable) or 'Always' (pools that do not allow SSL are marked as unavailable). This is also a per pool setting configurable in 'PoolsConfig.json'
    [Parameter(Mandatory = $false)]
    [Switch]$SSLallowSelfSignedCertificate = $false, # If true will allow SSL/TLS connections with self signed certificates (this is a security issue)
    [Parameter(Mandatory = $false)]
    [String]$StartupMode = "Running", # One of 'Idle', 'Paused' or 'Running'. This is the same as the buttons in the legacy & web GUI
    [Parameter(Mandatory = $false)]
    [Boolean]$SubtractBadShares = $true, # If true will deduct bad shares when calculating effective hashrates
    [Parameter(Mandatory = $false)]
    [Int]$SyncWindow = 3, # Cycles. Pool prices must all be all have been collected within the last 'SyncWindow' cycles, otherwise the biased value of older poll price data will get reduced more the older the data is
    [Parameter(Mandatory = $false)]
    [Switch]$UseColorForMinerStatus = $true, # If true miners in web and legacy GUI will be shown with colored background depending on status
    [Parameter(Mandatory = $false)]
    [Switch]$UsemBTC = $true, # If true will display BTC values in milli BTC
    [Parameter(Mandatory = $false)]
    [Switch]$UseMinerTweaks = $false, # If true will apply miner specific tweaks, e.g mild overclock. This may improve profitability at the expense of system stability (Admin rights are required)
    [Parameter(Mandatory = $false)]
    [String]$UIstyle = "light", # light or full. Defines level of info displayed in main text window
    [Parameter(Mandatory = $false)]
    [Double]$UnrealisticAlgorithmDeviceEarningsFactor = 10, # Ignore miner if resulting earnings are more than $.UnrealisticAlgorithmDeviceEarningsFactor higher than any other miner for the device & algorithm
    [Parameter(Mandatory = $false)]
    [Double]$UnrealisticMinerEarningsFactor = 5, # Ignore miner if resulting earnings are more than $UnrealisticAlgorithmDeviceEarningsFactor higher than average earnings of all other miners with same algorithm
    [Parameter(Mandatory = $false)]
    [Double]$UnrealisticPoolPriceFactor = 10, # Mark pool unavailable if current price data in pool API is more than $UnrealisticPoolPriceFactor higher than previous price
    [Parameter(Mandatory = $false)]
    [Switch]$UseAnycast = $true, # If true pools will use anycast for best network performance and ping times (currently no available pool supports this feature) 
    [Parameter(Mandatory = $false)]
    [Hashtable]$Wallets = @{ "BTC" = "1GPSq8txFnyrYdXL8t6S94mYdF8cGqVQJF" },
    [Parameter(Mandatory = $false)]
    [Switch]$Watchdog = $true, # If true will automatically put pools and/or miners temporarily on hold it they fail $WatchdogCount times in a row
    [Parameter(Mandatory = $false)]
    [Int]$WatchdogCount = 3, # Number of watchdog timers
    [Parameter(Mandatory = $false)]
    [Switch]$WebGUI = $true, # If true launch web GUI (recommended)
    [Parameter(Mandatory = $false)]
    [String]$WorkerName = [System.Net.Dns]::GetHostName() # Do not allow '.'
)

Set-Location (Split-Path $MyInvocation.MyCommand.Path)

[ConsoleModeSettings]::DisableQuickEditMode()

$ErrorLogFile = ".\Logs\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
$RecommendedPWSHversion = [Version]"7.5.3"

# Close useless empty cmd window that comes up when starting from bat file
If ((Get-Process -Id $PID).Parent.ProcessName -eq "conhost") { 
    $ConhostProcessId = (Get-Process -Id $PID).Parent.Id
    If ((Get-Process -Id $ConHostProcessId).Parent.ProcessName -eq "cmd") { Stop-Process -Id (Get-Process -Id $ConhostProcessId).Parent.Id -Force -ErrorAction Ignore }
    Remove-Variable ConhostProcessId
}

@"
 _   _  ____       __  __ _
| | | |/ ___|     |  \/  (_)_ __   ___ _ __
| | | | |  _ _____| |\/| | | '_ \ / _ \ '__|
| |_| | |_| |_____| |  | | | | | |  __/ |
 \___/ \____|     |_|  |_|_|_| |_|\___|_|

Copyright (c) 2018-$([DateTime]::Now.Year) UselessGuru
This is free software, and you are welcome to redistribute it under certain conditions.
https://github.com/UselessGuru/UG-Miner/blob/master/LICENSE
"@
Write-Host "`nCopyright and license notices must be preserved.`n" -ForegroundColor Green

# Initialize global thread safe case insensitive lists
$Global:Config = [System.Collections.SortedList]::Synchronized([System.Collections.SortedList]::new([StringComparer]::OrdinalIgnoreCase))
$Global:Session = [System.Collections.SortedList]::Synchronized([System.Collections.SortedList]::new([StringComparer]::OrdinalIgnoreCase))
$Global:Stats = [System.Collections.SortedList]::Synchronized([System.Collections.SortedList]::new([StringComparer]::OrdinalIgnoreCase))

# Expand paths
$Session.MainPath = (Split-Path $MyInvocation.MyCommand.Path)
$Session.ConfigFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ConfigFile)
$Session.PoolsConfigFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PoolsConfigFile)

# Branding data
$Session.Branding = [PSCustomObject]@{ 
    BrandName    = "UG-Miner"
    BrandWebSite = "https://github.com/UselessGuru/UG-Miner"
    ProductLabel = "UG-Miner"
    Version      = [System.Version]"6.5.13"
}

$host.UI.RawUI.WindowTitle = "$($Session.Branding.ProductLabel) $($Session.Branding.Version)"

Write-Message -Level Info "Starting $($Session.Branding.ProductLabel)® v$($Session.Branding.Version) © 2017-$([DateTime]::Now.Year) UselessGuru..."

Write-Host ""
Write-Host "Checking PWSH version..." -ForegroundColor Yellow -NoNewline
If ($PSVersiontable.PSVersion -lt [System.Version]"7.0.0") { 
    Write-Host " ✖" -ForegroundColor Red
    Write-Message -Level Error "Unsupported PWSH version $($PSVersiontable.PSVersion.ToString()) detected. $($Session.Branding.BrandName) requires at least PWSH version 7.0.0."
    Write-Host "The recommended version is $($RecommendedPWSHversion) which can be downloaded from https://github.com/PowerShell/powershell/releases." -ForegroundColor Red
    (New-Object -ComObject Wscript.Shell).Popup("Unsupported PWSH version $($PSVersiontable.PSVersion.ToString()) detected.`n`n$($Session.Branding.BrandName) requires at least PWSH version 7.0.0.`nThe recommended version is $($RecommendedPWSHversion) which can be downloaded from https://github.com/PowerShell/powershell/releases.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
    Exit
}
Write-Host " ✔  (running PWSH version $($PSVersionTable.PSVersion)" -ForegroundColor Green -NoNewLine
If ($PSVersionTable.PSVersion -lt $RecommendedPWSHversion) { Write-Host " [recommended version is $($RecommendedPWSHversion)]" -ForegroundColor DarkYellow -NoNewline }
Write-Host ")" -ForegroundColor Green

# Another instance might already be running. Wait no more than 20 seconds (previous instance might be from autoupdate)
$CursorPosition = $Host.UI.RawUI.CursorPosition

$Loops = 20
While (((Get-CimInstance CIM_Process).Where({ $_.CommandLine -like "PWSH* -Command $($Session.MainPath)*.ps1 *" }).CommandLine).Count -gt 1) { 
    $Loops --
    [Console]::SetCursorPosition(0, $CursorPosition.y)
    Write-Host ""
    Write-Host "Waiting for another instance of $($Session.Branding.ProductLabel) to close... [-$Loops] " -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    If ($Loops -eq 0) { 
        [Console]::SetCursorPosition(55, $CursorPosition.y)
        Write-Host " ✖    " -ForegroundColor Red
        Write-Message -Level Error "Another instance of $($Session.Branding.ProductLabel) is still running. Cannot continue!"
        (New-Object -ComObject Wscript.Shell).Popup("Another instance of $($Session.Branding.ProductLabel) is still running.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Exit
    }
}
If ($Loops -ne 20) { 
    [Console]::SetCursorPosition(55, $CursorPosition.y)
    Write-Host " ✔    " -ForegroundColor Green
}
Remove-Variable Loops

# Convert command line parameters syntax
$Session.AllCommandLineParameters = [Ordered]@{ } # as case insensitive hash table
($MyInvocation.MyCommand.Parameters.psBase.Keys.Where({ $_ -ne "ConfigFile" -and (Get-Variable $_ -ErrorAction Ignore) }) | Sort-Object).ForEach(
    { 
        If ($MyInvocation.MyCommandLineParameters.$_ -is [Switch]) { 
            $Session.AllCommandLineParameters.$_ = [Boolean]$Session.AllCommandLineParameters.$_
        }
        Else { 
            $Session.AllCommandLineParameters.$_ = Get-Variable $_ -ValueOnly
        }
        Remove-Variable $_
    }
)

# Must done before reading config (Get-Region)
Write-Host ""
Write-Message -Level Verbose "Preparing environment and loading data files..."
Initialize-Environment
$CursorPosition = $Host.UI.RawUI.CursorPosition
[Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
Write-Host " ✔" -ForegroundColor Green
[Console]::SetCursorPosition($CursorPosition.X, $CursorPosition.y)

# Read configuration, if no config file exists Read-Config will create an initial running configuration in memory
Write-Host ""
If (Test-Path -LiteralPath $Session.ConfigFile) { 
     Write-Message -Level Info "Using configuration file '$($Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'."
}
Else { 
    $Session.FreshConfig = $true
    $Session.NewMiningStatus = $Session.MiningStatus = "Idle"
}

Read-Config -ConfigFile $Session.ConfigFile
$Session.ConfigRunning = $Config.Clone()

# Start log reader (SnakeTail) [https://github.com/snakefoot/snaketail-net]
Start-LogReader

# Update config file to include all new config items
If (-not $Config.ConfigFileVersion -or [System.Version]::Parse($Config.ConfigFileVersion) -lt $Session.Branding.Version) { Update-ConfigFile  -ConfigFile $Session.ConfigFile }

# Internet connection must be available
Write-Host ""
write-Host "Checking internet connection..." -ForegroundColor Yellow -NoNewline
$NetworkInterface = (Get-NetConnectionProfile).Where({ $_.IPv4Connectivity -eq "Internet" }).InterfaceIndex
$Session.MyIPaddress = If ($NetworkInterface) { (Get-NetIPAddress -InterfaceIndex $NetworkInterface -AddressFamily IPV4).IPAddress } Else { $null }
Remove-Variable NetworkInterface
If (-not $Session.MyIPaddress) { 
    Write-Host " ✖" -ForegroundColor Red
    Write-Message -Level Error "Terminating Error - no internet connection. $($Session.Branding.ProductLabel) will shut down."
    (New-Object -ComObject Wscript.Shell).Popup("No internet connection`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
    Exit
}
Write-Host " ✔  (IP address: $($Session.MyIPaddress))" -ForegroundColor Green

# Check if a new version is available and run update if so configured
Write-Host ""
Get-Version
[Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
Write-Host " ✔" -ForegroundColor Green

# Prerequisites check
Write-Message -Level Verbose "Verifying pre-requisites..."
If ([System.Environment]::OSVersion.Version -lt [System.Version]"10.0.0.0") { 
    [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
    Write-Host " ✖" -ForegroundColor Red
    Write-Message -Level Error "$($Session.Branding.ProductLabel) requires at least Windows 10. $($Session.Branding.ProductLabel) will shut down."
    (New-Object -ComObject Wscript.Shell).Popup("$($Session.Branding.ProductLabel) requires at least Windows 10.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
    Exit
}
$Prerequisites = @(
    "$env:SystemRoot\System32\MSVCR120.dll",
    "$env:SystemRoot\System32\VCRUNTIME140.dll",
    "$env:SystemRoot\System32\VCRUNTIME140_1.dll"
)
If ($PrerequisitesMissing = $Prerequisites.Where({ -not (Test-Path -LiteralPath $_ -PathType Leaf) })) { 
    [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
    Write-Host " ✖" -ForegroundColor Red
    $PrerequisitesMissing.ForEach({ Write-Message -Level Warn "'$_' is missing." })
    Write-Message -Level Error "Please install the required runtime modules. Download and extract"
    Write-Message -Level Error "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/Visual-C-Runtimes-All-in-One-Sep-2019/Visual-C-Runtimes-All-in-One-Sep-2019.zip"
    Write-Message -Level Error "and run 'install_all.bat' (Administrative privileges are required)."
    Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
    (New-Object -ComObject Wscript.Shell).Popup("Prerequisites missing.`nPlease install the required runtime modules.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
    Exit
}
Remove-Variable Prerequisites, PrerequisitesMissing

If (-not (Get-Command Get-PnpDevice)) { 
    [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
    Write-Host " ✖" -ForegroundColor Red
    Write-Message -Level Error "Windows Management Framework 5.1 is missing.`nPlease install the required runtime modules from https://www.microsoft.com/en-us/download/details.aspx?id=54616. $($Session.Branding.ProductLabel) will shut down."
    (New-Object -ComObject Wscript.Shell).Popup("Windows Management Framework 5.1 is missing.`nPlease install the required runtime modules.`n`n$($Session.Branding.ProductLabel) will shut down.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
    Exit
}
[Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
Write-Host " ✔" -ForegroundColor Green
Remove-Variable RecommendedPWSHversion

# Exclude from AV scanner
If ($Session.FreshConfig -and (Get-Command "Get-MpPreference") -and (Get-MpComputerStatus)) { 
    Try { 
        Write-Message -Level Verbose "Excluding the $($Session.Branding.ProductLabel) directory from Microsoft Defender Antivirus scans to avoid false virus alerts..."
        If (-not $Session.IsLocalAdmin) { 
            Write-Host "You must accept the UAC control dialog to continue." -ForegroundColor Blue -NoNewLine
            Start-Sleep -Seconds 5
        }
        Start-Process "pwsh" "-Command Write-Host 'Excluding UG-Miner directory ''$(Convert-Path .)'' from Microsoft Defender Antivirus scans...'; Import-Module Defender -SkipEditionCheck; Add-MpPreference -ExclusionPath '$(Convert-Path .)'" -Verb runAs
        [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
        Write-Host " ✔" -ForegroundColor Green
        Write-Host "                                                    "
        [Console]::SetCursorPosition(0, $Host.UI.RawUI.CursorPosition.Y - 1)
    }
    Catch { 
        [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
        Write-Host " ✖" -ForegroundColor Red
        Write-Message -Level Error "Could not exclude the directory '$PWD' from Microsoft Defender Antivirus scans. $($Session.Branding.ProductLabel) will shut down."
        (New-Object -ComObject Wscript.Shell).Popup("Could not exclude the directory`n'$PWD'`n from Microsoft Defender Antivirus scans.`nThis would lead to unpredictable results.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        Exit
    }
    # Unblock files
    If (Get-Command "Unblock-File" -ErrorAction Ignore) { 
        If (Get-Item .\* -Stream Zone.*) { 
            Write-Message -Level Verbose "Unblocking files that were downloaded from the internet..."
            Get-ChildItem -Path . -Recurse | Unblock-File
            [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
            Write-Host " ✔" -ForegroundColor Green
        }
    }
}

$Session.VertHashDatPath = ".\Cache\VertHash.dat"
If (Test-Path -LiteralPath $Session.VertHashDatPath -PathType Leaf) { 
    Write-Message -Level Verbose "Verifying integrity of VertHash data file '$($Session.VertHashDatPath)'..."
    $VertHashDatCursorPosition = $Session.CursorPosition
}
# Start-ThreadJob needs to be run in any case to set number of threads
$VertHashDatCheckJob = Start-ThreadJob -InitializationScript ([ScriptBlock]::Create("Set-Location '$($Session.MainPath)'")) -ScriptBlock { If (Test-Path -LiteralPath ".\Cache\VertHash.dat" -PathType Leaf) { (Get-FileHash -Path ".\Cache\VertHash.dat").Hash -eq "A55531E843CD56B010114AAF6325B0D529ECF88F8AD47639B6EDEDAFD721AA48" } } -StreamingHost $null -ThrottleLimit ((Get-CimInstance CIM_VideoController).Count + 1)

Write-Message -Level Verbose "Importing modules..."
Try { 
    Add-Type -Path ".\Cache\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll" -ErrorAction Stop
}
Catch { 
    If (Test-Path -LiteralPath ".\Cache\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll" -ErrorAction Ignore) { Remove-Item ".\Cache\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll" -Force }
    Add-Type -Path ".\Includes\OpenCL\*.cs" -OutputAssembly ".\Cache\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll"
    Add-Type -Path ".\Cache\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll"
}

Try { 
    Add-Type -Path ".\Cache\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll" -ErrorAction Stop
}
Catch { 
    If (Test-Path -LiteralPath ".\Cache\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll" -ErrorAction Ignore) { Remove-Item ".\Cache\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll" -Force }
    Add-Type -Path ".\Includes\CPUID.cs" -OutputAssembly ".\Cache\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll"
    Add-Type -Path ".\Cache\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll"
}

Import-Module NetSecurity -ErrorAction Ignore
Import-Module Defender -ErrorAction Ignore -SkipEditionCheck
[Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
Write-Host " ✔" -ForegroundColor Green

Write-Message -Level Verbose "Setting variables..."
$nl = "`n" # Must use variable, cannot join with "`n" with Write-Host

# Align CUDA id with nvidia-smi order
$env:CUDA_DEVICE_ORDER = "PCI_BUS_ID"
# For AMD
$env:GPU_FORCE_64BIT_PTR = 1
$env:GPU_MAX_HEAP_SIZE = 100
$env:GPU_USE_SYNC_OBJECTS = 1
$env:GPU_MAX_ALLOC_PERCENT = 100
$env:GPU_SINGLE_ALLOC_PERCENT = 100
$env:GPU_MAX_WORKGROUP_SIZE = 256

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

$Session.BrainData = @{ }
$Session.Brains = @{ }
$Session.CoreLoopCounter = [Int64]0
$Session.CoreError = @()
$Session.CPUfeatures = (Get-CpuId).Features | Sort-Object
$Session.CycleStarts = @()
$Session.IsLocalAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
$Session.LegacyGUI = $Config.LegacyGUI
$Session.MiningEarnings = $Session.MiningProfit = $Session.MiningPowerCost = [Double]::NaN
$Session.NewMiningStatus = If ($Config.StartupMode -match "Paused|Running") { $Config.StartupMode } Else { "Idle" }
$Session.RestartCycle = $true
$Session.ScriptStartTime = (Get-Process -Id $PID).StartTime.ToUniversalTime()
$Session.SuspendCycle = $false
$Session.WatchdogTimers = [System.Collections.Generic.List[PSCustomObject]]::new()

$Session.RegexAlgoIsEthash = "^Autolykos2$|^EtcHash$|^Ethash$|^EthashB3$|^UbqHash$"
$Session.RegexAlgoIsProgPow = "^EvrProgPow$|^FiroPow$|^KawPow$|^MeowPow$|^PhiHash$|^ProgPow|^SCCpow$"
$Session.RegexAlgoHasDynamicDAG = "^Autolykos2$|^EtcHash$|^Ethash$|^EthashB3$|^EvrProgPow$|^FiroPow$|^KawPow$|^MeowPow$|^Octopus$|^PhiHash$|^ProgPow|^SCCpow$|^UbqHash$"
$Session.RegexAlgoHasStaticDAG = "^FishHash$|^HeavyHashKarlsenV2$"
$Session.RegexAlgoHasDAG = (($Session.RegexAlgoHasDynamicDAG -split "\|") + ($Session.RegexAlgoHasStaticDAG -split "\|") | Sort-Object) -join "|"
[Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
Write-Host " ✔" -ForegroundColor Green

$Session.Summary = "Loading miner device information.<br>This may take a while..."
Write-Message -Level Verbose "$($Session.Summary)"

$Session.SupportedCPUDeviceVendors = @("AMD", "INTEL")
$Session.SupportedGPUDeviceVendors = @("AMD", "INTEL", "NVIDIA")
$Session.GPUArchitectureDbNvidia.PSObject.Properties.ForEach({ $_.Value.Model = $_.Value.Model -join "|" })
$Session.GPUArchitectureDbAMD.PSObject.Properties.ForEach({ $_.Value = $_.Value -join "|" })

$Session.Devices = Get-Device

If ($Session.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -eq "AMD" }).OpenCL.DriverVersion -and (Get-Item -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Khronos\OpenCL\Vendors).Property -notlike "*\amdocl64.dll") { 
    Write-Message -Level Error "OpenCL driver installation for AMD GPU devices is incomplete"
    Write-Message -Level Error "Please create the missing registry key as described in https://github.com/ethereum-mining/ethminer/issues/2001#issuecomment-662288143. $($Session.Branding.ProductLabel) will shut down."
    (New-Object -ComObject Wscript.Shell).Popup("The OpenCL driver installation for AMD GPU devices is incomplete.`nPlease create the missing registry key as described here:`n`nhttps://github.com/ethereum-mining/ethminer/issues/2001#issuecomment-662288143`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
    Exit
}

$Session.Devices.Where({ $_.Type -eq "CPU" -and $_.Vendor -notin $Session.SupportedCPUDeviceVendors }).ForEach({ $_.State = [DeviceState]::Unsupported; $_.Status = "Unavailable"; $_.StatusInfo = "Unsupported CPU vendor: '$($_.Vendor)'" })
$Session.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -notin $Session.SupportedGPUDeviceVendors }).ForEach({ $_.State = [DeviceState]::Unsupported; $_.Status = "Unavailable"; $_.StatusInfo = "Unsupported GPU vendor: '$($_.Vendor)'" })
$Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Type -eq "GPU" -and -not ($_.CUDAversion -or $_.OpenCL.DriverVersion) }).ForEach({ $_.State = [DeviceState]::Unsupported; $_.Status = "Unavailable"; $_.StatusInfo = "Unsupported GPU model: '$($_.Model)'" })

$Session.Devices.Where({ $Config.ExcludeDeviceName -contains $_.Name -and $_.State -ne [DeviceState]::Unsupported }).ForEach({ $_.State = [DeviceState]::Disabled; $_.Status = "Idle"; $_.StatusInfo = "Disabled (ExcludeDeviceName: '$($_.Name)')" })

# Build driver version table
$Session.DriverVersion = [PSCustomObject]@{ }
If ($Session.Devices.CUDAversion) { $Session.DriverVersion | Add-Member "CUDA" ($Session.Devices.CUDAversion | Sort-Object -Top 1) }
$Session.DriverVersion | Add-Member "CIM" ([PSCustomObject]@{ })
$Session.DriverVersion.CIM | Add-Member "CPU" ([System.Version](($Session.Devices.Where({ $_.Type -eq "CPU" }).CIM.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))
$Session.DriverVersion.CIM | Add-Member "AMD" ([System.Version](($Session.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -eq "AMD" }).CIM.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))
$Session.DriverVersion.CIM | Add-Member "NVIDIA" ([System.Version](($Session.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -eq "NVIDIA" }).CIM.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))
$Session.DriverVersion | Add-Member "OpenCL" ([PSCustomObject]@{ })
$Session.DriverVersion.OpenCL | Add-Member "CPU" ([System.Version](($Session.Devices.Where({ $_.Type -eq "CPU" }).OpenCL.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))
$Session.DriverVersion.OpenCL | Add-Member "AMD" ([System.Version](($Session.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -eq "AMD" }).OpenCL.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))
$Session.DriverVersion.OpenCL | Add-Member "NVIDIA" ([System.Version](($Session.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -eq "NVIDIA" }).OpenCL.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))

[Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
Write-Host " ✔  ($($Session.Devices.count) device$(If ($Session.Devices.count -ne 1) { "s" }) found" -ForegroundColor Green -NoNewline
If ($Session.Devices.Where({ $_.State -eq [DeviceState]::Unsupported })) { Write-Host " [$($Session.Devices.Where({ $_.State -eq [DeviceState]::Unsupported }).Count) unsupported device$(If ($Session.Devices.Where({ $_.State -eq [DeviceState]::Unsupported }).Count -ne 1){ "s" })]" -ForegroundColor DarkYellow -NoNewline } 
Write-Host ")" -ForegroundColor Green

# Driver version changed
If ((Test-Path -LiteralPath ".\Cache\DriverVersion.json" -PathType Leaf) -and ([System.IO.File]::ReadAllLines("$PWD\Cache\DriverVersion.json") | ConvertFrom-Json | ConvertTo-Json -Compress) -ne ($Session.DriverVersion | ConvertTo-Json -Compress)) { Write-Message -Level Warn "Graphics card driver version data has changed. It is recommended to re-benchmark all miners." }
$Session.DriverVersion | ConvertTo-Json | Out-File -LiteralPath ".\Cache\DriverVersion.json" -Force

# Rename existing switching log
If (Test-Path -LiteralPath ".\Logs\SwitchingLog.csv" -PathType Leaf) { Get-ChildItem -Path ".\Logs\SwitchingLog.csv" -File | Rename-Item -NewName { "SwitchingLog_$($_.LastWriteTime.toString("yyyy-MM-dd_HH-mm-ss")).csv" } }

$CursorPosition = $Host.UI.RawUI.CursorPosition
If ($VertHashDatCheckJob | Wait-Job -Timeout 60 | Receive-Job -Wait -AutoRemoveJob) { 
    [Console]::SetCursorPosition($VertHashDatCursorPosition.X, $VertHashDatCursorPosition.Y)
    Write-Host " ✔  (checksum ok)" -ForegroundColor Green
}
Else { 
    If (Test-Path -LiteralPath $Session.VertHashDatPath -PathType Leaf -ErrorAction Ignore) { 
        Remove-Item -Path $Session.VertHashDatPath -Force
        [Console]::SetCursorPosition($VertHashDatCursorPosition.X, $VertHashDatCursorPosition.Y)
        Write-Host " ✖  (VertHash data file '$($Session.VertHashDatPath)' is corrupt -> file deleted. It will be re-downloaded if needed)" -ForegroundColor Red
    }
}
Remove-Variable VertHashDatCheckJob, VertHashDatCursorPosition -ErrorAction Ignore
[Console]::SetCursorPosition($CursorPosition.X, $CursorPosition.y)

# Getting exchange rates
Write-Host ""
Get-Rate

# Start API server
If ($Config.WebGUI) { 
    Write-Host ""
    Start-APIserver
}

Function MainLoop { 

    If ($Session.MinersRunning) { 
        # Set process priority to BelowNormal to avoid hashrate drops on systems with weak CPUs
        (Get-Process -Id $PID).PriorityClass = "BelowNormal"
    }
    Else { 
        (Get-Process -Id $PID).PriorityClass = "Normal"
    }

    If ($Session.ConfigurationHasChangedDuringUpdate) { $Session.NewMiningStatus = $Session.MiningStatus = "Idle" }

    If ($Session.ConfigRunning.BalancesTrackerPollInterval -gt 0 -and $Session.MiningStatus -ne "Idle") { Start-BalancesTracker } Else { Stop-BalancesTracker }

    # Check internet connection and update rates every 15 minutes
    If ($Session.NewMiningStatus -ne "Idle" -and $Session.RatesUpdated -lt [DateTime]::Now.ToUniversalTime().AddMinutes(-15)) { 
        # Check internet connection
        $NetworkInterface = (Get-NetConnectionProfile).Where({ $_.IPv4Connectivity -eq "Internet" }).InterfaceIndex
        $Session.MyIPaddress = If ($NetworkInterface) { (Get-NetIPAddress -InterfaceIndex $NetworkInterface -AddressFamily IPV4).IPAddress } Else { $null }
        Remove-Variable NetworkInterface
        If ($Session.MyIPaddress) { 
            Get-Rate
            If ($Session.NewMiningStatus -eq "Paused") { $Session.RefreshNeeded = $true }
        }
        Else { 
            Write-Message -Level Error "No internet connection - will retry in $($Session.ConfigRunning.Interval) seconds..."
            Start-Sleep -Seconds $Session.ConfigRunning.Interval
        }
    }

    # If something (pause button, idle timer, WebGUI/config) has set the RestartCycle flag, stop and start mining to switch modes immediately
    If ($Session.RestartCycle -or ($LegacyGUIform -and -not $LegacyGUIelements.MiningSummaryLabel.Text)) { 
        $Session.RestartCycle = $false

        If ($Session.NewMiningStatus -ne $Session.MiningStatus) { 

            If ($Session.NewMiningStatus -eq "Running" -and $Session.ConfigRunning.IdleDetection) { Write-Message -Level Verbose "Idle detection is enabled. Mining will get suspended on any keyboard or mouse activity." }

            # Keep only the last 10 files
            Get-ChildItem -Path ".\Logs\$($Session.Branding.ProductLabel)_*.log" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse
            Get-ChildItem -Path ".\Logs\SwitchingLog_*.csv" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse
            Get-ChildItem -Path "$($Session.ConfigFile)_*.backup" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse

            If ($Session.ConfigRunning.Proxy -eq "") { 
                $PSDefaultParameterValues.Remove("*:Proxy")
            }
            Else { 
                $PSDefaultParameterValues["*:Proxy"] = $Session.ConfigRunning.Proxy
            }

            Stop-Brain @($Session.Brains.Keys.Where({ $_ -notin (Get-PoolBaseName $Session.ConfigRunning.PoolName) }))

            Switch ($Session.NewMiningStatus) { 
                "Idle" { 
                    If ($LegacyGUIelements) { 
                        $LegacyGUIelements.ButtonPause.Enabled = $false
                        $LegacyGUIelements.ButtonStart.Enabled = $false
                        $LegacyGUIelements.ButtonStop.Enabled = $false
                    }

                    If ($Session.MiningStatus) { 
                        Write-Host ""
                        $Message = "'Stop mining' button clicked."
                        Write-Message -Level Info $Message
                        $Session.Summary = $Message
                        Remove-Variable Message

                        If ($LegacyGUIelements) { Update-GUIstatus }

                        Stop-Core
                        Stop-Brain
                        Stop-BalancesTracker

                        # If ($Session.ConfigRunning.ReportToServer) { Write-MonitoringData }

                        If ($LegacyGUIelements) { 
                            $LegacyGUIelements.ButtonPause.Enabled = $true
                            $LegacyGUIelements.ButtonStart.Enabled = $true
                        }
                    }

                    If (-not $Session.ConfigurationHasChangedDuringUpdate) { 
                        Write-Host ""
                        $Message = "$($Session.Branding.ProductLabel) is stopped."
                        Write-Message -Level Info $Message
                        $Message += " Click the 'Start mining' button to make money."
                        $Session.Summary = $Message
                        Remove-Variable Message
                    }
                    Break
                }
                "Paused" { 
                    If ($LegacyGUIelements) { 
                        $LegacyGUIelements.ButtonPause.Enabled = $false
                        $LegacyGUIelements.ButtonStart.Enabled = $false
                        $LegacyGUIelements.ButtonStop.Enabled = $false
                    }

                    Write-Host ""
                    $Message = "'Pause mining' button clicked."
                    Write-Message -Level Info $Message
                    $Session.Summary = $Message
                    Remove-Variable Message

                    If ($LegacyGUIelements) { Update-GUIstatus }

                    Stop-Core
                    Start-Brain @(Get-PoolBaseName $Session.ConfigRunning.PoolName)
                    If ($Session.ConfigRunning.BalancesTrackerPollInterval -gt 0) { Start-BalancesTracker } Else { Stop-BalancesTracker }

                    # If ($Session.ConfigRunning.ReportToServer) { Write-MonitoringData }

                    If ($LegacyGUIelements) { 
                        $LegacyGUIelements.ButtonStart.Enabled = $true
                        $LegacyGUIelements.ButtonStop.Enabled = $true
                    }

                    Write-Host ""
                    $Message = "$($Session.Branding.ProductLabel) is paused."
                    Write-Message -Level Info $Message
                    $Message += " Click the 'Start mining' button to make money.<br>"
                    ((@(If ($Session.ConfigRunning.UsemBTC) { "mBTC" } Else { ($Session.ConfigRunning.PayoutCurrency) }) + @($Session.ConfigRunning.ExtraCurrencies)) | Select-Object -Unique).Where({ $Session.Rates.$_.($Session.ConfigRunning.FIATcurrency) }).ForEach(
                        { 
                            $Message += "1 $_ = {0:N$(Get-DecimalsFromValue -Value $Session.Rates.$_.($Session.ConfigRunning.FIATcurrency) -DecimalsMax $Session.ConfigRunning.DecimalsMax)} $($Session.ConfigRunning.FIATcurrency)&ensp;&ensp;&ensp;" -f $Session.Rates.$_.($Session.ConfigRunning.FIATcurrency)
                        }
                    )
                    $Session.Summary = $Message
                    Remove-Variable Message
                    Break
                }
                "Running" { 
                    If ($LegacyGUIelements) { 
                        $LegacyGUIelements.ButtonPause.Enabled = $false
                        $LegacyGUIelements.ButtonStart.Enabled = $false
                        $LegacyGUIelements.ButtonStop.Enabled = $false
                    }

                    If ($Session.MiningStatus) { 
                        Write-Host ""
                        $Message = "'Start mining' button clicked."
                        Write-Message -Level Info $Message
                        $Message += " Mining processes are starting..."
                        $Session.Summary = $Message
                        Remove-Variable Message
                        If ($LegacyGUIelements) { Update-GUIstatus }
                    }

                    Start-Brain @(Get-PoolBaseName $Session.ConfigRunning.PoolName)
                    Start-Core

                    If ($Session.ConfigRunning.BalancesTrackerPollInterval -gt 0) { Start-BalancesTracker } Else { Stop-BalancesTracker }

                    If ($LegacyGUIelements) { 
                        $LegacyGUIelements.ButtonPause.Enabled = $true
                        $LegacyGUIelements.ButtonStop.Enabled = $true
                    }
                    If (-not $Session.MiningStatus) { $host.UI.RawUI.FlushInputBuffers() }
                    Break
                }
            }
            If ($LegacyGUIelements) { Update-GUIstatus }
            $Session.MiningStatus = $Session.NewMiningStatus
        }
        $Session.RefreshNeeded = $true
    }

    If ($Session.ConfigRunning.ShowConsole) { 
        Show-Console
        If ([System.Console]::KeyAvailable) { 
            $KeyPressed = [System.Console]::ReadKey($true)

            If ($Session.NewMiningStatus -eq "Running" -and $KeyPressed.Key -eq "p" -and $KeyPressed.Modifiers -eq 5 <# <Ctrl><Alt> #>) { 
                If (-not $Global:CoreRunspace.Job.IsCompleted -eq $false) { 
                    # Core is complete / gone. Cycle cannot be suspended anymore
                    $Session.SuspendCycle = $false
                }
                Else { 
                    $Session.SuspendCycle = -not $Session.SuspendCycle
                    If ($Session.SuspendCycle) { 
                        $Message = "'<Ctrl><Alt>P' pressed. Core cycle is suspended until you press '<Ctrl><Alt>P' again."
                        If ($LegacyGUIelements) { 
                            $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Blue
                            $LegacyGUIelements.MiningSummaryLabel.Text = $Message
                            $LegacyGUIelements.ButtonPause.Enabled = $false
                        }
                        Write-Host $Message -ForegroundColor Cyan
                    }
                    Else { 
                        $Message = "'<Ctrl><Alt>P' pressed. Core cycle is running again."
                        If ($LegacyGUIelements) { 
                            $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Blue
                            $LegacyGUIelements.MiningSummaryLabel.Text = $Message
                            $LegacyGUIelements.ButtonPause.Enabled = $true
                        }
                        Write-Host $Message -ForegroundColor Cyan
                        If ([DateTime]::Now.ToUniversalTime() -gt $Session.EndCycleTime) { $Session.EndCycleTime = [DateTime]::Now.ToUniversalTime() }
                    }
                    Remove-Variable Message
                }
            }
            Else { 
                Switch ($KeyPressed.KeyChar) { 
                    "1" { 
                        $Session.ShowPoolBalances = -not $Session.ShowPoolBalances
                        Write-Host "`nListing pool balances set to [" -NoNewline; If ($Session.ShowPoolBalances) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        $Session.RefreshNeeded = $true
                        Break
                    }
                    "2" { 
                        $Session.ShowAllMiners = -not $Session.ShowAllMiners
                        Write-Host "`nListing all optimal miners set to [" -NoNewline; If ($Session.ShowAllMiners) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        $Session.RefreshNeeded = $true
                        Break
                    }
                    "3" { 
                        $Session.UIstyle = If ($Session.UIstyle -eq "light") { "full" } Else { "light" }
                        Write-Host "`nUI style set to [" -NoNewline; Write-Host "$($Session.UIstyle)" -ForegroundColor Blue -NoNewline; Write-Host "] (Information about miners run in the past 24hrs, failed miners in the past 24hrs & watchdog timers will " -NoNewline; If ($Session.UIstyle -eq "light") { Write-Host "not " -ForegroundColor Red -NoNewline }; Write-Host "be shown)"
                        $Session.RefreshNeeded = $true
                        Break
                    }
                    "4" { 
                        $Session.LegacyGUI = -not $Session.LegacyGUI
                        Write-Host "`nLegacy GUI [" -NoNewline; If ($Session.LegacyGUI) { Write-Host "enabled" -ForegroundColor Green -NoNewline } Else { Write-Host "disabled" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        If (-not $Session.LegacyGUI) { $LegacyGUIform.Close() }
                        $Session.RefreshNeeded = $true
                        Break
                    }
                    "a" { 
                        $Session.ShowColumnAccuracy = -not $Session.ShowColumnAccuracy
                        Write-Host "`n'" -NoNewline; Write-Host "A" -ForegroundColor Cyan -NoNewline; Write-Host "ccuracy' column visibility set to [" -NoNewline; If ($Session.ShowColumnAccuracy) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        $Session.RefreshNeeded = $true
                        Break
                    }
                    "c" { 
                        If ($Session.CalculatePowerCost) { 
                            $Session.ShowColumnPowerCost = -not $Session.ShowColumnPowerCost
                            Write-Host "`n'Power " -NoNewline; Write-Host "c" -ForegroundColor Cyan -NoNewline; Write-Host "ost' column visibility set to [" -NoNewline; If ($Session.ShowColumnPowerCost) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                            $Session.RefreshNeeded = $true
                        }
                        Break
                    }
                    "e" { 
                        $Session.ShowColumnEarnings = -not $Session.ShowColumnEarnings
                        Write-Host "`n'" -NoNewline; Write-Host "E" -ForegroundColor Cyan -NoNewline; Write-Host "arnings' column visibility set to [" -NoNewline; If ($Session.ShowColumnEarnings) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        $Session.RefreshNeeded = $true
                        Break
                    }
                    "f" { 
                        $Session.ShowColumnPoolFee = -not $Session.ShowColumnPoolFee
                        Write-Host "`nPool '"-NoNewline; Write-Host "F" -ForegroundColor Cyan -NoNewline; Write-Host "ees' column visibility set to [" -NoNewline; If ($Session.ShowColumnPoolFee) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        $Session.RefreshNeeded = $true
                        Break
                    }
                    "h" { 
                        Write-Host "`nHot key legend:"
                        Write-Host "1: Toggle listing pool balances              [" -NoNewline; If ($Session.ShowPoolBalances) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        Write-Host "2: Toggle listing all optimal miners         [" -NoNewline; If ($Session.ShowAllMiners) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        Write-Host "3: Toggle UI style [full or light]           [" -NoNewline; Write-Host "$($Session.UIstyle)" -ForegroundColor Blue -NoNewline; Write-Host "]"
                        Write-Host "4: Toggle use of legacy GUI                  [" -NoNewline; If ($Session.LegacyGUI) { Write-Host "enabled" -ForegroundColor Green -NoNewline } Else { Write-Host "disabled" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        Write-Host
                        Write-Host "a: Toggle '" -NoNewline; Write-Host "A" -ForegroundColor Cyan -NoNewline; Write-Host "ccuracy' column visibility       [" -NoNewline; If ($Session.ShowColumnAccuracy) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        If ($Session.CalculatePowerCost) { 
                            Write-Host "c: Toggle 'Power " -NoNewline; Write-Host "c" -ForegroundColor Cyan -NoNewline; Write-Host "ost' column visibility     [" -NoNewline; If ($Session.ShowColumnPowerCost) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        }
                        Write-Host "e: Toggle '" -NoNewline; Write-Host "E" -ForegroundColor Cyan -NoNewline; Write-Host "arnings' column visibility       [" -NoNewline; If ($Session.ShowColumnEarnings) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        Write-Host "f: Toggle pool '" -NoNewline; Write-Host "F" -ForegroundColor Cyan -NoNewline; Write-Host "ees' column visibility      [" -NoNewline; If ($Session.ShowColumnPoolFee) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        Write-Host "i: Toggle 'Earnings b" -NoNewline; Write-Host "i" -ForegroundColor Cyan -NoNewline; Write-Host "as' column visibility  [" -NoNewline; If ($Session.ShowColumnEarningsBias) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        Write-Host "m: Toggle " -NoNewline; Write-Host "m" -ForegroundColor Cyan -NoNewline; Write-Host "iner 'Fees' column visibility     [" -NoNewline; If ($Session.ShowColumnMinerFee) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        Write-Host "n: Toggle 'Coin" -NoNewline; Write-Host "N" -ForegroundColor Cyan -NoNewline; Write-Host "ame' column visibility       [" -NoNewline; If ($Session.ShowColumnCoinName) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        Write-Host "p: Toggle '" -NoNewline; Write-Host "P" -ForegroundColor Cyan -NoNewline; Write-Host "ool' column visibility           [" -NoNewline; If ($Session.ShowColumnPool) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        If ($Session.CalculatePowerCost) { 
                            Write-Host "r: Toggle 'P" -NoNewline; Write-Host "r" -ForegroundColor Cyan -NoNewline; Write-Host "ofit bias' column visibility    [" -NoNewline; If ($Session.ShowColumnProfitBias) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        }
                        Write-Host "s: Toggle 'Ha" -NoNewline; Write-Host "s" -ForegroundColor Cyan -NoNewline; Write-Host "hrate(s)' column visibility    [" -NoNewline; If ($Session.ShowColumnHashrate) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        If ($Session.CalculatePowerCost) { 
                            Write-Host "t: Toggle 'Profi" -NoNewline; Write-Host "t" -ForegroundColor Cyan -NoNewline; Write-Host "' column visibility         [" -NoNewline; If ($Session.ShowColumnProfit) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        }
                        Write-Host "u: Toggle '" -NoNewline; Write-Host "U" -ForegroundColor Cyan -NoNewline; Write-Host "ser' column visibility           [" -NoNewline; If ($Session.ShowColumnUser) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        If ($Session.CalculatePowerCost) { 
                            Write-Host "w: Toggle 'Po" -NoNewline; Write-Host "w" -ForegroundColor Cyan -NoNewline; Write-Host "er (W)' column visibility      [" -NoNewline; If ($Session.ConfigRunning.CalculatePowerCost -and $Session.ShowColumnPowerConsumption) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        }
                        Write-Host "y: Toggle 'Currenc" -NoNewline; Write-Host "y" -ForegroundColor Cyan -NoNewline; Write-Host "' column visibility       [" -NoNewline; If ($Session.ShowColumnCurrency) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        Write-Host "`nq: " -NoNewline; Write-Host "Q" -ForegroundColor Blue -NoNewline; Write-Host "uit $($Session.Branding.ProductLabel)"
                        Break
                    }
                    "i" { 
                        $Session.ShowColumnEarningsBias = -not $Session.ShowColumnEarningsBias
                        Write-Host "`n'Earnings b" -NoNewline; Write-Host "i" -ForegroundColor Cyan -NoNewline; Write-Host "as' column visibility set to [" -NoNewline; If ($Session.ShowColumnEarningsBias) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        $Session.RefreshNeeded = $true
                        Break
                    }
                    "m" { 
                        $Session.ShowColumnMinerFee = -not $Session.ShowColumnMinerFee
                        Write-Host "`nM" -ForegroundColor Cyan -NoNewline; Write-Host "iner 'Fees' column visibility set to [" -NoNewline; If ($Session.ShowColumnMinerFee) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        $Session.RefreshNeeded = $true
                        Break
                    }
                    "n" { 
                        $Session.ShowColumnCoinName = -not $Session.ShowColumnCoinName
                        Write-Host "`n'Coin" -NoNewline; Write-Host "N" -ForegroundColor Cyan -NoNewline; Write-Host "ame' column visibility set to [" -NoNewline; If ($Session.ShowColumnCoinName) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        $Session.RefreshNeeded = $true
                        Break
                    }
                    "p" { 
                        $Session.ShowColumnPool = -not $Session.ShowColumnPool
                        Write-Host "`n'" -NoNewline; Write-Host "P" -ForegroundColor Cyan -NoNewline; Write-Host "ool' column visibility set to [" -NoNewline; If ($Session.ShowColumnPool) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        $Session.RefreshNeeded = $true
                        Break
                    }
                    "q" { 
                        $MsgBoxInput = [System.Windows.Forms.MessageBox]::Show("Do you want to shut down $($Session.Branding.ProductLabel)?", "$($Session.Branding.ProductLabel)", [System.Windows.Forms.MessageBoxButtons]::YesNo, 32, "Button2")
                        If ($MsgBoxInput -eq "Yes") { 
                            Write-Host
                            Exit-UGminer
                        }
                        $Session.RefreshNeeded = $true
                    }
                    "r" { 
                        If ($Session.CalculatePowerCost) { 
                            $Session.ShowColumnProfitBias = -not $Session.ShowColumnProfitBias
                            Write-Host "`n'P" -NoNewline; Write-Host "r" -ForegroundColor Cyan -NoNewline; Write-Host "ofit bias' column visibility set to [" -NoNewline; If ($Session.ShowColumnProfitBias) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                            $Session.RefreshNeeded = $true
                        }
                        Break
                    }
                    "s" { 
                        $Session.ShowColumnHashrate = -not $Session.ShowColumnHashrate
                        Write-Host "`n'Ha" -NoNewline; Write-Host "s" -ForegroundColor Cyan -NoNewline; Write-Host "hrates(s)' column visibility set to [" -NoNewline; If ($Session.ShowColumnHashrate) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        $Session.RefreshNeeded = $true
                        Break
                    }
                    "t" { 
                        If ($Session.CalculatePowerCost) { 
                            $Session.ShowColumnProfit = -not $Session.ShowColumnProfit
                            Write-Host "`n'" -NoNewline; Write-Host "P" -ForegroundColor Cyan -NoNewline; Write-Host "rofit' column visibility set to [" -NoNewline; If ($Session.ShowColumnProfit) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                            $Session.RefreshNeeded = $true
                        }
                        Break
                    }
                    "u" { 
                        $Session.ShowColumnUser = -not $Session.ShowColumnUser
                        Write-Host "`n'" -NoNewline; Write-Host "U" -ForegroundColor Cyan -NoNewline; Write-Host "ser' column visibility set to [" -NoNewline; If ($Session.ShowColumnUser) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        $Session.RefreshNeeded = $true
                        Break
                    }
                    "w" { 
                        If ($Session.CalculatePowerCost) { 
                            $Session.ShowColumnPowerConsumption = -not $Session.ShowColumnPowerConsumption
                            Write-Host "`n'Po" -NoNewline; Write-Host "w" -ForegroundColor Cyan -NoNewline; Write-Host "er (W)' column visibility set to [" -NoNewline; If ($Session.ShowColumnPowerConsumption) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                            $Session.RefreshNeeded = $true
                        }
                        Break
                    }
                    "y" { 
                        $Session.ShowColumnCurrency = -not $Session.ShowColumnCurrency
                        Write-Host "`n'Currenc" -NoNewline; Write-Host "y" -ForegroundColor Cyan -NoNewline; Write-Host "' column visibility set to [" -NoNewline; If ($Session.ShowColumnCurrency) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "]"
                        $Session.RefreshNeeded = $true
                        Break
                    }
                }
            }

            If ($Session.RefreshNeeded) { Start-Sleep -Seconds 2 }
            Remove-Variable KeyPressed
            $host.UI.RawUI.FlushInputBuffer()
        }
    }
    Else { Hide-Console }

    If ($Session.MiningStatus -eq "Running") { 
        If ($Session.ConfigRunning.IdleDetection) { 
            If ([Math]::Round([PInvoke.Win32.UserInput]::IdleTime.TotalSeconds) -gt $Session.ConfigRunning.IdleSec) { 
                # System was idle long enough, start mining
                If (-not $Global:CoreRunspace) { 
                    $Message = "System was idle for $($Session.ConfigRunning.IdleSec) second$(If ($Session.ConfigRunning.IdleSec -ne 1) { "s" }).<br>Resuming mining..."
                    Write-Message -Level Verbose ($Message -replace "<br>", " ")
                    $Session.Summary = $Message

                    Start-Core

                    If ($LegacyGUIelements) { 
                        Update-GUIstatus
                        $LegacyGUIelements.MiningSummaryLabel.Text = ($Message -replace "&", "&&" -split "<br>") -join "`r`n"
                        $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Black
                    }
                }
                Remove-Variable Message
            }
            ElseIf ($Global:CoreRunspace.Job.IsCompleted -eq $false -and $Global:CoreRunspace.StartTime -lt [DateTime]::Now.ToUniversalTime().AddSeconds( 1 )) { 
                $Message = "System activity detected."
                Write-Message -Level Verbose $Message
                $Session.Summary = $Message

                If ($LegacyGUIelements) { 
                    Update-GUIstatus
                    $LegacyGUIelements.MiningSummaryLabel.Text = ($Message -replace "&", "&&" -split "<br>") -join "`r`n"
                    $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Black
                }

                Stop-Core

                $Message = "Mining is suspended until system is idle for $($Session.ConfigRunning.IdleSec) second$(If ($Session.ConfigRunning.IdleSec -ne 1) { "s" })."
                Write-Message -Level Verbose $Message
                $Session.Summary = $Message

                If ($LegacyGUIelements) { 
                    Update-GUIstatus
                    $LegacyGUIelements.MiningSummaryLabel.Text = ($Message -replace "&", "&&" -split "<br>") -join "`r`n"
                    $LegacyGUIelements.MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Black
                }
                Remove-Variable Message
            }
        }
        ElseIf ($Global:CoreRunspace.Job.IsCompleted -ne $false) { 
            If ($Global:CoreRunspace.Job.IsCompleted -eq $true) { 
                Write-Message -Level Warn "Core cycle stopped abnormally - restarting..."
                Stop-Core
            }
            Start-Core
            If ($LegacyGUIelements) { Update-GUIstatus }
        }
        ElseIf (-not $Session.SuspendCycle -and -not $Session.MinersBenchmarkingOrMeasuring -and $Session.BeginCycleTimeCycleTime -and [DateTime]::Now.ToUniversalTime() -gt $Session.BeginCycleTimeCycleTime.AddSeconds(1.5 *$Session.ConfigRunning.Interval)) { 
            # Core watchdog. Sometimes core loop gets stuck
            Write-Message -Level Warn "Core cycle is stuck - restarting..."
            Stop-Core
            Start-Core
            If ($LegacyGUIelements) { Update-GUIstatus }
        }
    }
    ElseIf ((Test-Path -Path $Session.ConfigFile) -and (Test-Path -Path $Session.PoolsConfigFile)) { 
        If (-not ($Session.FreshConfig -or $Session.ConfigurationHasChangedDuringUpdate) -and $Session.ConfigFileReadTimestamp -ne (Get-Item -Path $Session.ConfigFile -ErrorAction Ignore).LastWriteTime -or $Session.PoolsConfigFileReadTimestamp -ne (Get-Item -Path $Session.PoolsConfigFile -ErrorAction Ignore).LastWriteTime) { 
            Read-Config -ConfigFile $Session.ConfigFile
            $Session.ConfigRunning = $Session.ConfigRunning.Clone()
            Write-Message -Level Verbose "Activated changed configuration."
            $Session.RefreshNeeded = $true
        }
    }

    If ($Session.RefreshBalancesNeeded) { 
        $Session.RefreshBalancesNeeded = $false
        If ($LegacyGUIelements -and $LegacyGUIelements.TabControl.SelectedTab.Text -eq "Earnings and balances") { Update-GUIstatus }
    }
    ElseIf ($Session.RefreshNeeded) { 
        $Session.RefreshNeeded = $false
        $Session.RefreshTimestamp = (Get-Date -Format "G")

        $host.UI.RawUI.WindowTitle = "$($Session.Branding.ProductLabel) $($Session.Branding.Version) - Runtime: {0:dd} days {0:hh} hrs {0:mm} mins - Path: $($Session.MainPath)" -f [TimeSpan]([DateTime]::Now.ToUniversalTime() - $Session.ScriptStartTime)
        If ($LegacyGUIelements) { Update-GUIstatus }

        # API port has changed, Start-APIserver will restart server and stop all running miners when port has changed
        If ($Session.ConfigRunning.APIport) { Start-APIserver } Else { Stop-APIserver }

        If ($Session.ConfigRunning.ShowConsole) { 
            If ($Session.Miners) { Clear-Host }

            # Get and display earnings stats
            If ($Session.ShowPoolBalances) { 
                $Session.Balances.Values.ForEach(
                    { 
                        If ($_.Currency -eq "BTC" -and $Session.ConfigRunning.UsemBTC) { $Currency = "mBTC"; $mBTCfactorCurrency = 1000 } Else { $Currency = $_.Currency; $mBTCfactorCurrency = 1 }
                        $PayoutCurrency = If ($_.PayoutThresholdCurrency) { $_.PayoutThresholdCurrency } Else { $_.Currency }
                        If ($PayoutCurrency -eq "BTC" -and $Session.ConfigRunning.UsemBTC)  { $PayoutCurrency = "mBTC"; $mBTCfactorPayoutCurrency = 1000 } Else { $mBTCfactorPayoutCurrency = 1}
                        If ($Currency -ne $PayoutCurrency) { 
                            # Payout currency is different from asset currency
                            If ($Session.Rates.$Currency -and $Session.Rates.$Currency.$PayoutCurrency) { 
                                $Percentage = ($_.Balance / $_.PayoutThreshold / $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency).toString("P2")
                            }
                            Else { 
                                $Percentage = "Unknown %"
                            }
                        }
                        Else { 
                            $Percentage = ($_.Balance / $_.PayoutThreshold).ToString("P2")
                        }

                        Write-Host "$($_.Pool) [$($_.Wallet)]" -ForegroundColor Green
                        If ($Session.ConfigRunning.BalancesShowSums) { 
                            Write-Host ("Earnings last 1 hour:   {0:n$($Session.ConfigRunning.DecimalsMax)} {1}$(If ($Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)) { " (≈{2:n$($Session.ConfigRunning.DecimalsMax)} {3}$(If ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.ConfigRunning.DecimalsMax)} {5}" }))" })" -f ($_.Growth1 * $mBTCfactorCurrency), $Currency, ($_.Growth1 * $Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)), $Session.ConfigRunning.FIATcurrency, ($_.Growth1 * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency)
                            Write-Host ("Earnings last 6 hours:  {0:n$($Session.ConfigRunning.DecimalsMax)} {1}$(If ($Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)) { " (≈{2:n$($Session.ConfigRunning.DecimalsMax)} {3}$(If ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.ConfigRunning.DecimalsMax)} {5}" }))" })" -f ($_.Growth6 * $mBTCfactorCurrency), $Currency, ($_.Growth6 * $Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)), $Session.ConfigRunning.FIATcurrency, ($_.Growth6 * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency)
                            Write-Host ("Earnings last 24 hours: {0:n$($Session.ConfigRunning.DecimalsMax)} {1}$(If ($Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)) { " (≈{2:n$($Session.ConfigRunning.DecimalsMax)} {3}$(If ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.ConfigRunning.DecimalsMax)} {5}" }))" })" -f ($_.Growth24 * $mBTCfactorCurrency), $Currency, ($_.Growth24 * $Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)), $Session.ConfigRunning.FIATcurrency, ($_.Growth24 * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency)
                            Write-Host ("Earnings last 7 days:   {0:n$($Session.ConfigRunning.DecimalsMax)} {1}$(If ($Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)) { " (≈{2:n$($Session.ConfigRunning.DecimalsMax)} {3}$(If ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.ConfigRunning.DecimalsMax)} {5}" }))" })" -f ($_.Growth168 * $mBTCfactorCurrency), $Currency, ($_.Growth168 * $Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)), $Session.ConfigRunning.FIATcurrency, ($_.Growth168 * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency)
                            Write-Host ("Earnings last 30 days:  {0:n$($Session.ConfigRunning.DecimalsMax)} {1}$(If ($Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)) { " (≈{2:n$($Session.ConfigRunning.DecimalsMax)} {3}$(If ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.ConfigRunning.DecimalsMax)} {5}" }))" })" -f ($_.Growth720 * $mBTCfactorCurrency), $Currency, ($_.Growth720 * $Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)), $Session.ConfigRunning.FIATcurrency, ($_.Growth720 * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency)
                        }
                        If ($Session.ConfigRunning.BalancesShowAverages) { 
                            Write-Host ("Average/hour:           {0:n$($Session.ConfigRunning.DecimalsMax)} {1}$(If ($Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)) { " (≈{2:n$($Session.ConfigRunning.DecimalsMax)} {3}$(If ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.ConfigRunning.DecimalsMax)} {5}" }))" })" -f ($_.AvgHourlyGrowth * $mBTCfactorCurrency), $Currency, ($_.AvgHourlyGrowth * $Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)), $Session.ConfigRunning.FIATcurrency, ($_.AvgHourlyGrowth * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency)
                            Write-Host ("Average/day:            {0:n$($Session.ConfigRunning.DecimalsMax)} {1}$(If ($Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)) { " (≈{2:n$($Session.ConfigRunning.DecimalsMax)} {3}$(If ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.ConfigRunning.DecimalsMax)} {5}" }))" })" -f ($_.AvgDailyGrowth * $mBTCfactorCurrency), $Currency, ($_.AvgDailyGrowth * $Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)), $Session.ConfigRunning.FIATcurrency, ($_.AvgDailyGrowth * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency)
                            Write-Host ("Average/week:           {0:n$($Session.ConfigRunning.DecimalsMax)} {1}$(If ($Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)) { " (≈{2:n$($Session.ConfigRunning.DecimalsMax)} {3}$(If ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.ConfigRunning.DecimalsMax)} {5}" }))" })" -f ($_.AvgWeeklyGrowth * $mBTCfactorCurrency), $Currency, ($_.AvgWeeklyGrowth * $Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)), $Session.ConfigRunning.FIATcurrency, ($_.AvgWeeklyGrowth * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency)
                        }
                        Write-Host "Balance:                " -NoNewline; Write-Host ("{0:n$($Session.ConfigRunning.DecimalsMax)} {1}$(If ($Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)) { " (≈{2:n$($Session.ConfigRunning.DecimalsMax)} {3}$(If ($Currency -ne $PayoutCurrency) { "≈{4:n$($Session.ConfigRunning.DecimalsMax)} {5}" }))" })" -f ($_.Balance * $mBTCfactorCurrency), $Currency, ($_.Balance * $Session.Rates.$Currency.($Session.ConfigRunning.FIATcurrency)), $Session.ConfigRunning.FIATcurrency, ($_.Balance * $mBTCfactorPayoutCurrency * $Session.Rates.$Currency.$PayoutCurrency), $PayoutCurrency) -ForegroundColor Yellow
                        Write-Host ("{0} of {1:n$($Session.ConfigRunning.DecimalsMax)} {2} payment threshold; projected payment date: $(If ($_.ProjectedPayDate -is [DateTime]) { $_.ProjectedPayDate.ToString("G") } Else { $_.ProjectedPayDate })`n" -f $Percentage, ($_.PayoutThreshold * $mBTCfactorPayoutCurrency), $PayoutCurrency)
                    }
                )
                Remove-Variable Currency, mBTCfactorCurrency, mBTCfactorPayoutCurrency, Percentage, PayoutCurrency -ErrorAction Ignore
            }

            If ($Session.MyIPaddress) { 
                If ($Session.MiningStatus -eq "Running" -and $Session.Miners.Where({ $_.Available })) { 
                    # Miner list format
                    [System.Collections.ArrayList]$MinerTable = @(
                        @{ Label = "Miner"; Expression = { $_.Name } }
                        If ($Session.ShowColumnMinerFee -and $Session.Miners.Workers.Fee) { @{ Label = "Fee"; Expression = { $_.Workers.ForEach({ "{0:P2}" -f [Double]$_.Fee }) }; Align = "right" } }
                        If ($Session.ShowColumnEarningsBias) { @{ Label = "Earnings bias"; Expression = { If ([Double]::IsNaN($_.Earnings_Bias)) { "n/a" } Else { "{0:n$($Session.ConfigRunning.DecimalsMax)}" -f ($_.Earnings_Bias * $Session.Rates.BTC.($Session.ConfigRunning.FIATcurrency)) } }; Align = "right" } }
                        If ($Session.ShowColumnEarnings) { @{ Label = "Earnings"; Expression = { If ([Double]::IsNaN($_.Earnings)) { "n/a" } Else { "{0:n$($Session.ConfigRunning.DecimalsMax)}" -f ($_.Earnings * $Session.Rates.BTC.($Session.ConfigRunning.FIATcurrency)) } }; Align = "right" } }
                        If ($Session.ShowColumnPowerCost -and $Session.ConfigRunning.CalculatePowerCost -and $Session.MiningPowerCost) { @{ Label = "Power cost"; Expression = { If ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } Else { "-{0:n$($Session.ConfigRunning.DecimalsMax)}" -f ($_.PowerCost * $Session.Rates.BTC.($Session.ConfigRunning.FIATcurrency)) } }; Align = "right" } }
                        If ($Session.ShowColumnProfitBias -and $Session.MiningPowerCost) { @{ Label = "Profit bias"; Expression = { If ([Double]::IsNaN($_.Profit_Bias)) { "n/a" } Else { "{0:n$($Session.ConfigRunning.DecimalsMax)}" -f ($_.Profit_Bias * $Session.Rates.BTC.($Session.ConfigRunning.FIATcurrency)) } }; Align = "right" } }
                        If ($Session.ShowColumnProfit -and $Session.MiningPowerCost) { @{ Label = "Profit"; Expression = { If ([Double]::IsNaN($_.Profit)) { "n/a" } Else { "{0:n$($Session.ConfigRunning.DecimalsMax)}" -f ($_.Profit * $Session.Rates.BTC.($Session.ConfigRunning.FIATcurrency)) } }; Align = "right" } }
                        If ($Session.ShowColumnPowerConsumption -and $Session.ConfigRunning.CalculatePowerCost) { @{ Label = "Power (W)"; Expression = { If ($_.MeasurePowerConsumption) { If ($_.Status -eq "Running") { "Measuring..." } Else { "Unmeasured" } } Else { If ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } Else { "$($_.PowerConsumption.ToString("N2"))" } } }; Align = "right" } }
                        If ($Session.ShowColumnAccuracy) { @{ Label = "Accuracy"; Expression = { $_.Workers.ForEach({ "{0:P0}" -f [Double]$_.Pool.Accuracy }) }; Align = "right" } }
                        @{ Label = "Algorithm"; Expression = { $_.Workers.Pool.Algorithm } }
                        If ($Session.ShowColumnPool) { @{ Label = "Pool"; Expression = { $_.Workers.Pool.Name } } }
                        If ($Session.ShowColumnPoolFee -and $Session.Miners.Workers.Pool.Fee) { @{ Label = "Fee"; Expression = { $_.Workers.ForEach({ "{0:P2}" -f [Double]$_.Pool.Fee }) }; Align = "right" } }
                        If ($Session.ShowColumnHashrate) { @{ Label = "Hashrate"; Expression = { If ($_.Benchmark) { If ($_.Status -eq "Running") { "Benchmarking..." } Else { "Benchmark pending" } } Else { $_.Workers.ForEach({ $_.Hashrate | ConvertTo-Hash }) } }; Align = "right" } }
                        If ($Session.ShowColumnUser) { @{ Label = "User"; Expression = { $_.Workers.Pool.User } } }
                        If ($Session.ShowColumnCurrency) { @{ Label = "Currency"; Expression = { If ($_.Workers.Pool.Currency -match "\w") { $_.Workers.Pool.Currency } } } }
                        If ($Session.ShowColumnCoinName) { @{ Label = "CoinName"; Expression = { If ($_.Workers.Pool.CoinName -match "\w" ) { $_.Workers.Pool.CoinName } } } }
                    )
                    # Display top 5 optimal miners and all benchmarking of power consumption measuring miners
                    $Bias = If ($Session.CalculatePowerCost -and -not $Session.ConfigRunning.IgnorePowerCost) { "Profit_Bias" } Else { "Earnings_Bias" }
                    ($Session.Miners.Where({ $_.Optimal -or $_.Benchmark -or $_.MeasurePowerConsumption }) | Group-Object { $_.BaseName_Version_Device -replace ".+-" } | Sort-Object -Property Name).ForEach(
                        { 
                            $MinersDeviceGroup = $_.Group | Sort-Object { $_.Name, [String]$_.Algorithms } -Unique
                            $MinersDeviceGroupNeedingBenchmark = $MinersDeviceGroup.Where({ $_.Benchmark })
                            $MinersDeviceGroupNeedingPowerConsumptionMeasurement = $MinersDeviceGroup.Where({ $_.MeasurePowerConsumption })
                            $MinersDeviceGroup.Where(
                                { 
                                    $Session.ShowAllMiners -or <# List all miners #>
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

                If ($Session.MinersRunning) { 
                    Write-Host "`nRunning miner$(If ($Session.MinersBest.Count -ne 1) { "s" }):"
                    [System.Collections.ArrayList]$MinerTable = @(
                        @{ Label = "Name"; Expression = { $_.Name } }
                        If ($Session.ShowColumnPowerConsumption -and $Session.ConfigRunning.CalculatePowerCost) { @{ Label = "Power (W)"; Expression = { If ([Double]::IsNaN($_.PowerConsumption_Live)) { "n/a" } Else { "$($_.PowerConsumption_Live.ToString("N2"))" } }; Align = "right" } }
                        @{ Label = "Hashrate(s)"; Expression = { $_.Hashrates_Live.ForEach({ If ([Double]::IsNaN($_)) { "n/a" } Else { $_ | ConvertTo-Hash } }) -join " & " }; Align = "right" }
                        @{ Label = "Active (this run)"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f ([DateTime]::Now.ToUniversalTime() - $_.BeginTime) } }
                        @{ Label = "Active (total)"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f ($_.TotalMiningDuration) } }
                        @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never"; Break } 1 { "Once"; Break } Default { $_ } } } }
                        @{ Label = "Device(s)"; Expression = { $_.BaseName_Version_Device -replace ".+-" } }
                        @{ Label = "Command"; Expression = { $_.CommandLine } }
                    )
                    $Session.MinersRunning | Sort-Object -Property { $_.BaseName_Version_Device -replace ".+-" } | Format-Table $MinerTable -Wrap | Out-Host
                    Remove-Variable MinerTable
                }

                If ($Session.UIstyle -eq "full" -or $Session.MinersNeedingBenchmark -or $Session.MinersNeedingPowerConsumptionMeasurement) { 

                    If ($Session.UIstyle -ne "full") { Write-Host -ForegroundColor DarkYellow "$(If ($Session.MinersNeedingBenchmark) { "Benchmarking" })$(If ($Session.MinersNeedingBenchmark -and $Session.MinersNeedingPowerConsumptionMeasurement) { " / " })$(If ($Session.MinersNeedingPowerConsumptionMeasurement) { "Measuring power consumption" }): Temporarily switched UI style to 'full'. (Information about miners run in the past, failed miners & watchdog timers will be shown)`n" }

                    [System.Collections.ArrayList]$MinersActivatedLast24Hrs = $Session.Miners.Where({ $_.Activated -and $_.EndTime.ToLocalTime().AddHours(24) -gt [DateTime]::Now })

                    If ($ProcessesIdle = $MinersActivatedLast24Hrs.Where({ $_.Status -eq "Idle" })) { 
                        Write-Host "$($ProcessesIdle.Count) previously executed miner$(If ($ProcessesIdle.Count -ne 1) { "s" }) (past 24 hrs):"
                        [System.Collections.ArrayList]$MinerTable = @(
                            @{ Label = "Name"; Expression = { $_.Name } }
                            If ($Session.ShowColumnPowerConsumption -and $Session.ConfigRunning.CalculatePowerCost) { @{ Label = "Power (W)"; Expression = { If ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } Else { "$($_.PowerConsumption.ToString("N2"))" } }; Align = "right" } }
                            @{ Label = "Hashrate(s)"; Expression = { $_.Workers.Hashrate.ForEach({ $_ | ConvertTo-Hash }) -join " & " }; Align = "right" }
                            @{ Label = "Time since last run"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f $([DateTime]::Now - $_.EndTime.ToLocalTime()) } }
                            @{ Label = "Active (total)"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f $_.TotalMiningDuration } }
                            @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never"; Break } 1 { "Once"; Break } Default { $_ } } } }
                            @{ Label = "Device(s)"; Expression = { $_.BaseName_Version_Device -replace ".+-" } }
                            @{ Label = "Command"; Expression = { $_.CommandLine } }
                        )
                        $ProcessesIdle | Sort-Object -Property EndTime -Descending | Format-Table $MinerTable -Wrap | Out-Host
                        Remove-Variable MinerTable
                    }
                    Remove-Variable ProcessesIdle

                    If ($ProcessesFailed = $MinersActivatedLast24Hrs.Where({ $_.Status -eq "Failed" })) { 
                        Write-Host -ForegroundColor Red "$($ProcessesFailed.Count) failed miner$(If ($ProcessesFailed.Count -ne 1) { "s" }) (past 24 hrs):"
                        [System.Collections.ArrayList]$MinerTable = @(
                            @{ Label = "Name"; Expression = { $_.Name } }
                            If ($Session.ShowColumnPowerConsumption -and $Session.ConfigRunning.CalculatePowerCost) { @{ Label = "Power (W)"; Expression = { If ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } Else { "$($_.PowerConsumption.ToString("N2"))" } }; Align = "right" } }
                            @{ Label = "Hashrate(s)"; Expression = { $_.Workers.Hashrate.ForEach({ $_ | ConvertTo-Hash }) -join " & " }; Align = "right" }
                            @{ Label = "Time since last fail"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f $([DateTime]::Now - $_.EndTime.ToLocalTime()) } }
                            @{ Label = "Active (total)"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f $_.TotalMiningDuration } }
                            @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never"; Break } 1 { "Once"; Break } Default { $_ } } } }
                            @{ Label = "Device(s)"; Expression = { $_.BaseName_Version_Device -replace ".+-" } }
                            @{ Label = "Command"; Expression = { $_.CommandLine } }
                        )
                        $ProcessesFailed | Sort-Object { If ($_.EndTime) { $_.EndTime } Else { [DateTime]0 } } | Format-Table $MinerTable -Wrap | Out-Host
                        Remove-Variable MinerTable
                    }
                    Remove-Variable MinersActivatedLast24Hrs, ProcessesFailed

                    If ($Session.ConfigRunning.Watchdog) { 
                        # Display watchdog timers
                        $Session.WatchdogTimers.Where({ $_.Kicked -gt $Session.Timer.AddSeconds(-$Session.WatchdogReset) }) | Sort-Object -Property Kicked, @{ Expression = { $_.MinerBaseName_Version_Device -replace ".+-"} } | Format-Table -Wrap (
                            @{ Label = "Miner watchdog timer"; Expression = { $_.MinerName } },
                            @{ Label = "Pool"; Expression = { $_.PoolName } },
                            @{ Label = "Algorithm"; Expression = { $_.Algorithm } },
                            @{ Label = "Device(s)"; Expression = { $_.MinerBaseName_Version_Device -replace ".+-" } },
                            @{ Label = "Last updated"; Expression = { "{0:mm} min {0:ss} sec ago" -f ([DateTime]::Now.ToUniversalTime() - $_.Kicked) }; Align = "right" }
                        ) | Out-Host
                    }
                }

                If ($Session.MiningStatus -eq "Running") { 

                    $Colour = If ($Session.MinersNeedingBenchmark -or $Session.MinersNeedingPowerConsumptionMeasurement) { "DarkYello" } Else { "White"}
                    Write-Host -ForegroundColor $Colour ($Session.Summary -replace "\.\.\.<br>", "... " -replace "<br>", " " -replace "\s*/\s*", "/" -replace "\s*=\s*", "=")
                    Remove-Variable Colour

                    If ($Session.Miners.Where({ $_.Available -and -not ($_.Benchmark -or $_.MeasurePowerConsumption) })) { 
                        If ($Session.MiningProfit -lt 0) { 
                            # Mining causes a loss
                            Write-Host -ForegroundColor Red ("Mining is currently NOT profitable and $(If ($Session.ConfigRunning.DryRun) { "would cause" } Else { "causes" }) a loss of {0} {1:n$($Session.ConfigRunning.DecimalsMax)}/day (including base power cost)." -f $Session.ConfigRunning.FIATcurrency, - ($Session.MiningProfit * $Session.Rates.BTC.($Session.ConfigRunning.FIATcurrency)))
                        }
                        If ($Session.MiningProfit -lt $Session.ConfigRunning.ProfitabilityThreshold) { 
                            # Mining profit is below the configured threshold
                            Write-Host -ForegroundColor Blue ("Mining profit ({0} {1:n$($Session.ConfigRunning.DecimalsMax)}) is below the configured threshold of {0} {2:n$($Session.ConfigRunning.DecimalsMax)}/day. Mining is suspended until threshold is reached." -f $Session.ConfigRunning.FIATcurrency, ($Session.MiningProfit * $Session.Rates.BTC.($Session.ConfigRunning.FIATcurrency)), $Session.ConfigRunning.ProfitabilityThreshold)
                        }
                        $StatusInfo = "Last refresh: $($Session.BeginCycleTime.ToLocalTime().ToString("G"))   |   Next refresh: $(If ($Session.EndCycleTime) { $($Session.EndCycleTime.ToLocalTime().ToString("G")) } Else { 'n/a (Mining is suspended)' })   |   Hot keys: $(If ($Session.CalculatePowerCost) { "[1234acefimnpqrstuwy]" } Else { "[1234aefimnqrsuwy]" })   |   Press 'h' for help"
                        Write-Host ("-" * $StatusInfo.Length)
                        Write-Host -ForegroundColor Yellow $StatusInfo
                        Remove-Variable StatusInfo
                    }
                }
            }
            Else { 
                Write-Host -ForegroundColor Red "No internet connection - will retry in $($Session.ConfigRunning.Interval) seconds..."
            }
        }

        $Error.Clear()
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()
    }
}

If ($Session.FreshConfig -or $Session.ConfigurationHasChangedDuringUpdate) { 
    $Session.NewMiningStatus = "Idle" # Must click 'Start mining' in GUI
    If ($Session.FreshConfig) { 
        Write-Host ""
        Write-Message -Level Warn "No configuration file found. Edit and save your configuration using the configuration editor (http://localhost:$($Session.ConfigRunning.APIport)/configedit.html)"
        $Session.Summary = "Edit your settings and save the configuration.<br>Then click the 'Start mining' button."
        (New-Object -ComObject Wscript.Shell).Popup("No configuration file found.`n`nEdit and save your configuration using the configuration editor (http://localhost:$($Session.ConfigRunning.APIport)/configedit.html).`n`n`Start making money by clicking 'Start mining'.`n`nHappy Mining!", 0, "Welcome to $($Session.Branding.ProductLabel) v$($Session.Branding.Version)", (4096 + 48)) | Out-Null
    }
    Else { 
        Write-Message -Level Warn "Configuration has changed during update. Verify and save your configuration using the configuration editor (http://localhost:$($Session.ConfigRunning.APIport)/configedit.html)"
        $Session.Summary = "Verify your settings and save the configuration.<br>Then click the 'Start mining' button."
        (New-Object -ComObject Wscript.Shell).Popup("The configuration has changed during update:`n`n$($Session.ConfigurationHasChangedDuringUpdate -join $nl)`n`nVerify and save the configuration using the configuration editor (http://localhost:$($Session.ConfigRunning.APIport)/configedit.html).`n`n`Start making money by clicking 'Start mining'.`n`nHappy Mining!", 0, "$($Session.Branding.ProductLabel) v$($Session.Branding.Version) - configuration has changed", (4096 + 64)) | Out-Null
    }
}

Write-Host ""
While ($true) { 
    If (-not $Session.ConfigRunning.ShowConsole) { $Session.LegacyGUI = $true }
    If ($Session.LegacyGUI) { 
        If (-not $LegacyGUIform.CanSelect) { . .\Includes\LegacyGUI.ps1 }
        # Show legacy GUI
        $LegacyGUIform.ShowDialog() | Out-Null
    }
    Else { 
        MainLoop
        Start-Sleep -Milliseconds 500
    }
}