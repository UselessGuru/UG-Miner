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
File:           UG-Miner.ps1
Version:        6.8.1
Version date:   2026/04/15
#>

using module .\Includes\Include.psm1

param(
    [Parameter (Mandatory = $false)]
    [String[]]$Algorithm = @(), # i.e. @("Equihash1445", "Ethash", "KawPow") etc. If '+' is used, then only the explicitly enabled algorithms are used. If '-' is used, then all algorithms except the disabled ones are used. Do not combine '+' and '-' concurrently.
    [Parameter (Mandatory = $false)]
    [String]$APIlogfile = "", # API will log all requests to this file, leave empty to disable
    [Parameter (Mandatory = $false)]
    [UInt16]$APIport = 3999, # TCP Port for API and web GUI
    [Parameter (Mandatory = $false)]
    [Switch]$AutoReboot = $true, # If true UG-Miner will reboot computer if a miner is completely dead, e.g. unresponsive
    [Parameter (Mandatory = $false)]
    [Switch]$AutoUpdate = $true, # If true UG-Miner will automatically update to the new version
    [Parameter (Mandatory = $false)]
    [UInt16]$AutoUpdateCheckInterval = 1, # If true UG-Miner will periodically check for a new program version every n days (0 to disable)
    [Parameter (Mandatory = $false)]
    [Switch]$BackupOnAutoUpdate = $true, # If true a backup copy will be saved as '[UG-Miner directory]\AutoUpdate\Backup_v[version]_[date_time].zip' when updateing
    [Parameter (Mandatory = $false)]
    [Double]$BadShareRatioThreshold = 0.05, # Allowed ratio of bad shares (total / bad) as reported by the miner. If the ratio exceeds the configured threshold then the miner will get marked as failed. Allowed values: 0.00 - 1.00. 0 disables this check
    [Parameter (Mandatory = $false)]
    [Boolean]$BalancesKeepAlive = $true, # If true UG-Miner will force mining at a pool to protect your earnings (some pools auto-purge the wallet after longer periods of inactivity, see '\Data\PoolData.Json' BalancesKeepAlive properties)
    [Parameter (Mandatory = $false)]
    [Boolean]$BalancesShowSums = $true, # Show 1hr / 6hrs / 24hr / 7day & 30day pool earnings sums
    [Parameter (Mandatory = $false)]
    [Boolean]$BalancesShowAverages = $true, # Show 1hr / 24hr & 7day pool earnings averages
    [Parameter (Mandatory = $false)]
    [Boolean]$BalancesShowInAllCurrencies = $true, # If true pool balances will be shown in all currencies
    [Parameter (Mandatory = $false)]
    [Boolean]$BalancesShowInFIATcurrency = $true, # If true pool balances will be shown in main currency
    [Parameter (Mandatory = $false)]
    [String[]]$BalancesTrackerExcludePools = @("MiningDutch"), # Balances tracker will not track these pools
    [Parameter (Mandatory = $false)]
    [Switch]$BalancesTrackerLog = $false, # If true UG-Miner will store all balance tracker data in .\Logs\EarningTrackerLog.csv
    [Parameter (Mandatory = $false)]
    [UInt16]$BalancesTrackerPollInterval = 10, # Interval duration (in muinutes) to trigger background task to collect pool balances & earnings data; set to 0 to disable, minumum value 10
    [Parameter (Mandatory = $false)]
    [Switch]$BenchmarkAllPoolAlgorithmCombinations = [Boolean]($Host.Name -eq "Visual Studio Code Host"), # Some miners are not compatible with all algorithm@pool combinations. Mainly useful for development purposes, causes more benchmarking
    [Parameter (Mandatory = $false)]
    [Switch]$CalculatePowerCost = [Boolean](Get-ItemProperty -Path "HKCU:\Software\HWiNFO64\VSB" -ErrorAction Ignore), # If true UG-Miner will read power consumption from miners and calculate power cost, required for true profit calculation
    [Parameter (Mandatory = $false)]
    [String]$ConfigFile = ".\Config\Config.json", # Config file name
    [Parameter (Mandatory = $false)]
    [UInt16]$CPUMiningReserveCPUcore = 1, # Number of CPU cores reserved for main script processing. Helps to get more stable hashrates and faster core loop processing.
    [Parameter (Mandatory = $false)]
    [Int16]$CPUMinerProcessPriority = "-2", # Process priority for CPU miners
    [Parameter (Mandatory = $false)]
    [String[]]$Currency = @(), # i.e. @("+ETC", +EVR", "+KIIRO") etc. If '+' is used, then only the explicitly enabled currencies are used. If '-' is used, then all currencies except the disabled ones are used. Do not combine '+' and '-' concurrently.
    [Parameter (Mandatory = $false)]
    [UInt16]$DecimalsMax = 6, # Display numbers with maximal n decimal digits (larger numbers are shown with less decimal digits)
    [Parameter (Mandatory = $false)]
    [UInt16]$Delay = 0, # Time (in seconds) between stop and start of miners, use only when getting blue screens on miner switches
    [Parameter (Mandatory = $false)]
    [Switch]$DisableCpuMiningOnBattery = $false, # If true UG-Miner will not use CPU miners while running on battery
    [Parameter (Mandatory = $false)]
    [Switch]$DisableDualAlgoMining = $false, # If true UG-Miner will not use any dual algorithm miners
    [Parameter (Mandatory = $false)]
    [Switch]$DisableMinerFee = $false, # Set to true to disable miner fees (Note: not all miners support turning off their built in fees, others will reduce the hashrate)
    [Parameter (Mandatory = $false)]
    [Switch]$DisableMinersWithFee = $false, # Set to true to disable all miners which contain fees
    [Parameter (Mandatory = $false)]
    [Switch]$DisableSingleAlgoMining = $false, # If true UG-Miner will not use any single algorithm miners
    [Parameter (Mandatory = $false)]
    [UInt16]$Donation = 15, # Minutes per Day
    [Parameter (Mandatory = $false)]
    [Switch]$DryRun = $false, # If true UG-Miner will do all the benchmarks, but will not mine
    [Parameter (Mandatory = $false)]
    [Double]$EarningsAdjustmentFactor = 1, # Default adjustment factor for prices reported by ALL pools (unless there is a per pool value configuration definined). Prices will be multiplied with this. Allowed values: 0.0 - 10.0
    [Parameter (Mandatory = $false)]
    [String[]]$ExcludeDeviceName = @(), # List of disabled devices, e.g. @("CPU#00", "GPU#02"); by default all devices are enabled
    [Parameter (Mandatory = $false)]
    [String[]]$ExcludeMinerName = @(), # List of miners to be excluded; Either specify miner short name, e.g. "PhoenixMiner" (without '-v...') to exclude any version of the miner, or use the full miner name incl. version information
    [Parameter (Mandatory = $false)]
    [String[]]$ExtraCurrencies = @("ETC", "ETH", "mBTC"), # Extra currencies used in balances summary, enter 'real-world' or crypto currencies, mBTC (milli BTC) is also allowed
    [Parameter (Mandatory = $false)]
    [String]$FIATcurrency = (Get-Culture).NumberFormat.CurrencySymbol, # Default main 'real-money' currency, i.e. GBP, USD, AUD, NZD etc. Do not use crypto currencies
    [Parameter (Mandatory = $false)]
    [Int16]$GPUMinerProcessPriority = "-1", # Process priority for GPU miners
    [Parameter (Mandatory = $false)]
    [Switch]$IdleDetection = $false, # If true UG-Miner will start mining only if system is idle for $IdleSec seconds
    [Parameter (Mandatory = $false)]
    [UInt16]$IdleSec = 120, # Time (in seconds) the system must be idle before mining starts
    [Parameter (Mandatory = $false)]
    [Switch]$Ignore0HashrateSample = $false, # If true UG-Miner will ignore 0 hashrate samples when setting miner status to 'warming up'
    [Parameter (Mandatory = $false)]
    [Switch]$IgnoreMinerFee = $false, # If true UG-Miner will ignore miner fee for earnings & profit calculation
    [Parameter (Mandatory = $false)]
    [Switch]$IgnorePoolFee = $false, # If true UG-Miner will ignore pool fee for earnings & profit calculation
    [Parameter (Mandatory = $false)]
    [Switch]$IgnorePowerCost = $false, # If true UG-Miner will ignore power cost in best miner selection, instead miners with best earnings will be selected
    [Parameter (Mandatory = $false)]
    [UInt16]$Interval = 90, # Average cycle loop duration (seconds), min 60, max 3600
    [Parameter (Mandatory = $false)]
    [Switch]$LegacyGUI = $true, # If true UG-Miner will start legacy GUI
    [Parameter (Mandatory = $false)]
    [Switch]$LegacyGUIStartMinimized = $false, # If true UG-Miner will start legacy GUI as minimized window
    [Parameter (Mandatory = $false)]
    [Switch]$LogBalanceAPIResponse = $false, # If true UG-Miner will log the pool balance API data
    [Parameter (Mandatory = $false)]
    [String[]]$LogLevel = @("Error", "Info", "Verbose", "Warn"), # Log level detail to be written to log file and screen, see Write-Message function; any of "Debug", "Error", "Info", "MemDbg", "Verbose", "Warn"
    [Parameter (Mandatory = $false)]
    [String]$LogViewerConfig = ".\Utils\UG-Miner_LogReader.xml", # Path to external log viewer config file
    [Parameter (Mandatory = $false)]
    [String]$LogViewerExe = ".\Utils\SnakeTail.exe", # Path to optional external log reader (SnakeTail) [https://github.com/snakefoot/snaketail-net], leave empty to disable
    [Parameter (Mandatory = $false)]
    [Double]$MinAccuracy = 0.5, # Use only pools with price accuracy greater than the configured value. Allowed values: 0.0 - 1.0 (0% - 100%)
    [Parameter (Mandatory = $false)]
    [UInt16]$MinCycle = 1, # Minimum number of cycles a miner must mine the same available algorithm@pool continously before switching is allowed (e.g. 3 would force a miner to stick mining algorithm@pool for min. 3 cycles before switching to another algorithm or pool)
    [Parameter (Mandatory = $false)]
    [UInt16]$MinDataSample = 20, # Minimum number of hashrate samples required to store hashrate
    [Parameter (Mandatory = $false)]
    [Double]$MinerSwitchingThreshold = 10, # Will not switch miners unless another miner has n% higher earnings / profit
    [Parameter (Mandatory = $false)]
    [String]$MinerWindowStyle = "minimized", # "minimized": miner window is minimized (default), but accessible; "normal": miner windows are shown normally; "hidden": miners will run as a hidden background task and are not accessible (not recommended)
    [Parameter (Mandatory = $false)]
    [Switch]$MinerWindowStyleNormalWhenBenchmarking = $true, # If true miner windows are shown normal when benchmarking (recommended to better see miner messages)
    [Parameter (Mandatory = $false)]
    [String]$MiningDutchAPIKey = "", # MiningDutch API key (required to retrieve balance information)
    [Parameter (Mandatory = $false)]
    [String]$MiningDutchUserName = "UselessGuru", # MiningDutch username
    [Parameter (Mandatory = $false)]
    [String]$MiningPoolHubAPIKey = "", # MiningPoolHub API key (required to retrieve balance information)
    [Parameter (Mandatory = $false)]
    [String]$MiningPoolHubUserName = "UselessGuru", # MiningPoolHub username
    [Parameter (Mandatory = $false)]
    [UInt16]$MinWorker = 25, # Minimum workers mining the algorithm at the pool. If less miners are mining the algorithm then the pool will be disabled. This is also a per pool setting configurable in 'PoolsConfig.json'
    # [Parameter (Mandatory = $false)]
    # [String]$MonitoringServer = "https://UG-Miner.com", # Monitoring server hostname, default "https://UG-Miner.com"
    # [Parameter (Mandatory = $false)]
    # [String]$MonitoringUser = "", # Monitoring user ID as registered with monitoring server
    [Parameter (Mandatory = $false)]
    [String]$NiceHashAPIKey = "", # NiceHash API Key (required to retrieve balance information)
    [Parameter (Mandatory = $false)]
    [String]$NiceHashAPISecret = "", # NiceHash API secret (required to retrieve balance information)
    [Parameter (Mandatory = $false)]
    [String]$NiceHashWallet = "", # NiceHash wallet, if left empty $Wallets[BTC] is used
    [Parameter (Mandatory = $false)]
    [String]$NiceHashOrganizationId = "", # NiceHash organization ID (required to retrieve balance information)
    [Parameter (Mandatory = $false)]
    [Switch]$OpenFirewallPorts = $true, # If true UG-Miner will open firewall ports for all miners (administrator privileges are required)
    [Parameter (Mandatory = $false)]
    [String]$PayoutCurrency = "BTC", # i.e. BTC, LTC, ZEC, ETH etc., default PayoutCurrency for all pools that have no other currency configured, PayoutCurrency is also a per pool setting (to be configured in 'PoolsConfig.json')
    [Parameter (Mandatory = $false)]
    [Switch]$PoolAllow0Hashrate = $false, # Allow mining to the pool even when there is 0 (or no) hashrate reported in the API (not recommended)
    [Parameter (Mandatory = $false)]
    [Switch]$PoolAllow0Price = $false, # Allow mining to the pool even when the price reported in the API is 0 (not recommended)
    [Parameter (Mandatory = $false)]
    [UInt16]$PoolAPIallowedFailureCount = 3, # Max number of pool API request attempts
    [Parameter (Mandatory = $false)]
    [Double]$PoolAllowedPriceIncreaseFactor = 5, # Max. allowed price increase compared with last price. If price increase is higher then the pool will be marked as unavaliable.
    [Parameter (Mandatory = $false)]
    [UInt16]$PoolAPIretryInterval = 3, # Time (in seconds) until pool API request retry. Note: Do not set this value too small to avoid temporary blocking by pool
    [Parameter (Mandatory = $false)]
    [UInt16]$PoolAPItimeout = 20, # Time (in seconds) until it aborts the pool request (useful if a pool's API is stuck). Note: do not set this value too small or UG-Miner will not be able to get any pool data
    [Parameter (Mandatory = $false)]
    [String]$PoolsConfigFile = ".\Config\PoolsConfig.json", # Pools configuration file name
    [Parameter (Mandatory = $false)]
    [UInt16]$PoolsMaxAge = 24, # Time (in hours) until a pool is seen as too old (e.g. is has not been updated) and will be removed from the pool list
    [Parameter (Mandatory = $false)]
    [String[]]$PoolName = @("HashCryptosPlus", "HiveON", "MiningDutchPlus", "NiceHash", "ZPoolPlus"), # Valid values are "HashCryptos", "HashCryptos24hr", "HashCryptosPlus", "HiveON", "MiningDutch", "MiningDutch24hr", "MiningDutchPlus", "NiceHash", "ZPool", "ZPool24hr", "ZPoolPlus"
    [Parameter (Mandatory = $false)]
    [Hashtable]$PowerPricekWh = @{ "00:00" = 0.26; "12:00" = 0.3 }, # Price of power per kW⋅h (in $Currency, e.g. CHF), valid from HH:mm (24hr format)
    [Parameter (Mandatory = $false)]
    [Hashtable]$PowerConsumption = @{ }, # Static power consumption per device in watt, e.g. @{ "GPU#03" = 25, "GPU#04 = 55" } (in case HWiNFO cannot read power consumption)
    [Parameter (Mandatory = $false)]
    [Double]$PowerConsumptionIdleSystem = 60, # Power consumption (in Watt) of idle system. Part of profit calculation.
    [Parameter (Mandatory = $false)]
    [Double]$ProfitabilityThreshold = -99, # Minimum profit threshold, if profit is less than the configured value (in $Currency, e.g. CHF) mining will stop (except for benchmarking & power consumption measuring)
    [Parameter (Mandatory = $false)]
    [String]$Proxy = "", # i.e http://192.0.0.1:8080
    [Parameter (Mandatory = $false)]
    [UInt16]$RatesUpdateInterval = 15, # Interval (in minutes) between exchange rates updates from min-api.cryptocompare.com
    [Parameter (Mandatory = $false)]
    [String]$Region = "Europe", # Used to determine pool nearest to you. One of "Australia", "Asia", "Brazil", "Canada", "Europe", "HongKong", "India", "Kazakhstan", "Russia", "USA East", "USA West"
    # [Parameter (Mandatory = $false)]
    # [Switch]$ReportToServer = $false, # If true UG-Miner will report worker status to central monitoring server
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnAccuracy = $false, # Show pool data accuracy column in main text window miner overview
    [Parameter (Mandatory = $false)]
    [Switch]$ShowAllMiners = $false, # Always show all miners in main text window miner overview (if false, only the best miners will be shown except when in benchmark / PowerConsumption measurement)
    [Parameter (Mandatory = $false)]
    [Switch]$ShowChangeLog = $true, # If true UG-Miner will show the changlog when an update is available
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnCoinName = $true, # Show CoinName column in main text window miner overview
    [Parameter (Mandatory = $false)]
    [Switch]$ShowConsole = $true, # If true UG-Miner will console window will be shown
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnCurrency = $true, # Show Currency column in main text window miner overview
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnEarnings = $true, # Show miner earnings column in main text window miner overview
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnEarningsBias = $true, # Show miner earnings bias column in main text window miner overview
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnHashrate = $true, # Show hashrate(s) column in main text window miner overview
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnMinerFee = $true, # Show miner fee column in main text window miner overview
    [Parameter (Mandatory = $false)]
    [Switch]$ShowPoolBalances = $false, # Display pool balances & earnings information in main text window, requires BalancesTrackerPollInterval -gt 0
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnPoolFee = $true, # Show pool fee column in main text window miner overview
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnProfit = $true, # Show miner profit column in main text window miner overview (if power price is available, see PowerPricekWh)
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnProfitBias = $true, # Show miner profit bias column in main text window miner overview (if power price is available, see PowerPricekWh)
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnPowerConsumption = $true, # Show power consumption column in main text window miner overview (if power price is available, see PowerPricekWh)
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnPowerCost = $true, # Show power cost column in main text window miner overview (if power price is available, see PowerPricekWh)
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnUser = $false, # Show pool user name column in main text window miner overview
    [Parameter (Mandatory = $false)]
    [Switch]$ShowShares = $true, # Show share data in log
    # [Parameter (Mandatory = $false)]
    # [Switch]$ShowWorkerStatus = $true, # Show worker status from other rigs (data retrieved from monitoring server)
    [Parameter (Mandatory = $false)]
    [String]$SSL = "Prefer", # SSL pool connections: One of three values: 'Prefer' (use where available), 'Never' (pools that only allow SSL connections are marked as unavailable) or 'Always' (pools that do not allow SSL are marked as unavailable). This is also a per pool setting configurable in 'PoolsConfig.json'
    [Parameter (Mandatory = $false)]
    [Switch]$SSLallowSelfSignedCertificate = $true, # If true UG-Miner will allow SSL/TLS connections with self signed certificates (this is a security issue)
    [Parameter (Mandatory = $false)]
    [String]$StartupMode = "Running", # One of 'Idle', 'Paused' or 'Running'. This is the same as the buttons in the legacy & web GUI
    [Parameter (Mandatory = $false)]
    [Boolean]$SubtractBadShares = $true, # If true UG-Miner will deduct bad shares when calculating effective hashrates
    [Parameter (Mandatory = $false)]
    [UInt16]$SyncWindow = 3, # Cycles. Pool prices must all be all have been collected within the last 'SyncWindow' cycles, otherwise the biased value of older poll price data will get reduced more and more the older the data is
    [Parameter (Mandatory = $false)]
    [Switch]$UseColorForMinerStatus = $true, # If true miners in web and legacy GUI will be shown with colored background depending on status
    [Parameter (Mandatory = $false)]
    [Switch]$UsemBTC = $true, # If true UG-Miner will display BTC values in milli BTC
    [Parameter (Mandatory = $false)]
    [Switch]$UseMinerTweaks = $false, # If true UG-Miner will apply miner specific tweaks, e.g mild overclock. This may improve profitability at the expense of system stability (administrator privileges are required)
    [Parameter (Mandatory = $false)]
    [String]$UIstyle = "light", # light or full. Defines level of info displayed in main text window
    [Parameter (Mandatory = $false)]
    [Double]$UnrealisticAlgorithmDeviceEarningsFactor = 10, # Ignore miner if resulting earnings are more than $.UnrealisticAlgorithmDeviceEarningsFactor higher than any other miner for the device & algorithm
    [Parameter (Mandatory = $false)]
    [Double]$UnrealisticMinerEarningsFactor = 5, # Ignore miner if resulting earnings are more than $UnrealisticAlgorithmDeviceEarningsFactor higher than average earnings of all other miners with same algorithm
    [Parameter (Mandatory = $false)]
    [Double]$UnrealisticPoolPriceFactor = 10, # Mark pool unavailable if current price data in pool API is more than $UnrealisticPoolPriceFactor higher than previous price
    [Parameter (Mandatory = $false)]
    [Switch]$UseAnycast = $true, # If true pools will use anycast for best network performance and ping times (currently no available pool supports this feature) 
    [Parameter (Mandatory = $false)]
    [Switch]$UseUnprofitableAlgorithms = $false, # If true UG-Miner will also use unprofitable algorithms
    [Parameter (Mandatory = $false)]
    [Hashtable]$Wallets = @{ "BTC" = "1GPSq8txFnyrYdXL8t6S94mYdF8cGqVQJF" }, # list of currency = walletaddress pairs
    [Parameter (Mandatory = $false)]
    [Switch]$Watchdog = $true, # If true UG-Miner will automatically put pools and/or miners temporarily on hold it they fail $WatchdogCount times in a row
    [Parameter (Mandatory = $false)]
    [UInt16]$WatchdogCount = 3, # Number of watchdog timers
    [Parameter (Mandatory = $false)]
    [Switch]$WebGUI = $true, # If true launch web GUI (recommended)
    [Parameter (Mandatory = $false)]
    [String]$WorkerName = [System.Net.Dns]::GetHostName() # Do not allow '.'
)

[ConsoleModeSettings]::DisableQuickEditMode()

Set-Location (Split-Path $MyInvocation.MyCommand.Path)

$RecommendedPWSHversion = [Version]"7.6.0"

# Close useless empty cmd window that comes up when starting from bat file
if ((Get-Process -Id $PID).Parent.ProcessName -eq "conhost") { 
    $ConhostProcessId = (Get-Process -Id $PID).Parent.Id
    if ((Get-Process -Id $ConHostProcessId).Parent.ProcessName -eq "cmd") { Stop-Process -Id (Get-Process -Id $ConhostProcessId).Parent.Id -Force -ErrorAction Ignore }
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
$Session.ErrorLogFile = "$($Session.MainPath)\Logs\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"

# Branding data
$Session.Branding = [PSCustomObject]@{ 
    BrandName    = "UG-Miner"
    BrandWebSite = "https://github.com/UselessGuru/UG-Miner"
    ProductLabel = "UG-Miner"
    Version      = [System.Version]"6.8.1"
}
$Session.ScriptStartTime = (Get-Process -Id $PID).StartTime.ToUniversalTime()

$host.UI.RawUI.WindowTitle = "$($Session.Branding.ProductLabel) $($Session.Branding.Version) - Runtime: {0:dd} days {0:hh} hrs {0:mm} mins - Path: $($Session.MainPath)" -f [TimeSpan]([DateTime]::Now.ToUniversalTime() - $Session.ScriptStartTime)

Write-Message -Level Info "Starting $($Session.Branding.ProductLabel)® v$($Session.Branding.Version)..."

Write-Host "`nChecking PWSH version..." -ForegroundColor Yellow -NoNewline
if ($PSVersiontable.PSVersion -lt [System.Version]"7.4.0") { 
    Write-Host " ✖" -ForegroundColor Red
    Write-Message -Level Error "Unsupported PWSH version $($PSVersiontable.PSVersion.ToString()) detected. $($Session.Branding.BrandName) requires at least PWSH version 7.4.0."
    Write-Host "The recommended version is $($RecommendedPWSHversion) which can be downloaded from https://github.com/PowerShell/powershell/releases." -ForegroundColor Red
    (New-Object -ComObject Wscript.Shell).Popup("Unsupported PWSH version $($PSVersiontable.PSVersion.ToString()) detected.`n`n$($Session.Branding.BrandName) requires at least PWSH version 7.4.0.`nThe recommended version is $($RecommendedPWSHversion) which can be downloaded from https://github.com/PowerShell/powershell/releases.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
    exit
}
Write-Host " ✔  (running PWSH version $($PSVersionTable.PSVersion)" -ForegroundColor Green -NoNewline
if ($PSVersionTable.PSVersion -lt $RecommendedPWSHversion) { Write-Host " [recommended version is $($RecommendedPWSHversion)]" -ForegroundColor DarkYellow -NoNewline }
Write-Host ")" -ForegroundColor Green

# Another instance might already be running. Wait no more than 20 seconds (other instance might be from autoupdate)
$Loops = 20
$CursorPosition = $Host.UI.RawUI.CursorPosition
while (((Get-CimInstance CIM_Process).Where({ $_.CommandLine -like "PWSH* -Command $($Session.MainPath)*.ps1 *" }).CommandLine).Count -gt 1) { 
    $Loops --
    [Console]::SetCursorPosition(0, $CursorPosition.y)
    Write-Host "`nWaiting for another instance of $($Session.Branding.ProductLabel) to close... [-$Loops] " -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    if ($Loops -eq 0) { 
        [Console]::SetCursorPosition(58, ($CursorPosition.y + 1))
        Write-Host " ✖   " -ForegroundColor Red
        Write-Message -Level Error "Another instance of $($Session.Branding.ProductLabel) is still running. Cannot continue!"
        (New-Object -ComObject Wscript.Shell).Popup("Another instance of $($Session.Branding.ProductLabel) is still running.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        exit
    }
}
if ($Loops -ne 20) { 
    [Console]::SetCursorPosition((56 + $Loops.Tostring().Length), ($CursorPosition.y + 1))
    Write-Host " ✔    " -ForegroundColor Green
}
Remove-Variable Loops

# Convert command line parameters syntax
$Session.AllCommandLineParameters = [Ordered]@{ } # as case insensitive hash table
($MyInvocation.MyCommand.Parameters.psBase.Keys.Where({ $_ -ne "ConfigFile" -and (Get-Variable $_ -ErrorAction Ignore) }) | Sort-Object).ForEach(
    { 
        if ($MyInvocation.MyCommandLineParameters.$_ -is [Switch]) { 
            $Session.AllCommandLineParameters.$_ = [Boolean]$Session.AllCommandLineParameters.$_
        }
        else { 
            $Session.AllCommandLineParameters.$_ = Get-Variable $_ -ValueOnly
        }
        Remove-Variable $_
    }
)

# Must done before reading config (Get-Region)
Write-Host ""
Write-Message -Level Verbose "Preparing environment and loading data files..."
# Create directories
("Cache", "Config", "Logs", "Stats").ForEach(
    { 
        if (-not (Test-Path -LiteralPath ".\$_" -PathType Container)) { $null = (New-Item -Path . -Name "$_" -ItemType Directory) }
    }
)

# Check if all required files are present
("Balances", "Brains", "Data", "Miners", "Pools", "Web").ForEach(
    { 
        if (-not (Get-ChildItem -LiteralPath $PWD\$_)) { 
            Write-Error "Terminating error - cannot continue! No files in folder '\$_'. Please restore the folder from your original download."
            $null = (New-Object -ComObject Wscript.Shell).Popup("No files in folder '\$_'.`nPlease restore the folder from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112)
            Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
            Start-Sleep -Seconds 5
            exit
        }
    }
)

# Load donation as case insensitive sorted list
if (Test-Path -LiteralPath "$PWD\Data\DonationData.json") { $Session.DonationData = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\DonationData.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
if (-not $Session.DonationData) { 
    Write-Error "Terminating error - cannot continue! File '.\Data\DonationData.json' is not a valid JSON file. Please restore it from your original download."
    $null = (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\DonationData.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112)
    Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
    Start-Sleep -Seconds 5
    exit
}
Write-Host "Loaded donation database." -NoNewline; Write-Host " ✔  ($($Session.DonationData.Count) $(if ($Session.DonationData.Count -eq 1) { "entry" } else { "entries" } ))" -ForegroundColor Green

# Load donation log
if (Test-Path -LiteralPath "$PWD\Logs\DonationLog.csv") { $Session.DonationLog = @([System.IO.File]::ReadAllLines("$PWD\Logs\DonationLog.csv") | ConvertFrom-Csv -ErrorAction Ignore) }
if (-not $Session.DonationLog) { 
    $Session.DonationLog = @()
}
else { 
    Write-Host "Loaded donation log." -NoNewline; Write-Host " ✔  ($($Session.DonationLog.Count) $(if ($Session.DonationLog.Count -eq 1) { "entry" } else { "entries" } ))" -ForegroundColor Green
}

# Load algorithm list as case insensitive sorted list
if (Test-Path -LiteralPath "$PWD\Data\Algorithms.json") { $Session.Algorithms = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\Algorithms.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
if (-not $Session.Algorithms.Keys) { 
    Write-Error "Terminating error - cannot continue! File '.\Data\Algorithms.json' is not a valid JSON file. Please restore it from your original download."
    $null = (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\Algorithms.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112)
    Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
    Start-Sleep -Seconds 5
    exit
}
Write-Host "Loaded algorithm database." -NoNewline; Write-Host " ✔  ($($Session.Algorithms.Count) $(if ($Session.Algorithms.Count -eq 1) { "entry" } else { "entries" } ))" -ForegroundColor Green

# Load coin names as case insensitive sorted list
if (Test-Path -LiteralPath "$PWD\Data\CoinNames.json") { $Session.CoinNames = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\CoinNames.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
if (-not $Session.CoinNames.Keys) { 
    Write-Error "Terminating error - cannot continue! File '.\Data\CoinNames.json' is not a valid JSON file. Please restore it from your original download."
    $null = (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\CoinNames.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112)
    Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
    Start-Sleep -Seconds 5
    exit
}
Write-Host "Loaded coin names database." -NoNewline; Write-Host " ✔  ($($Session.CoinNames.Count) $(if ($Session.CoinNames.Count -eq 1) { "entry" } else { "entries" } ))" -ForegroundColor Green

# Load currency algorithm data as case insensitive sorted list
if (Test-Path -LiteralPath "$PWD\Data\CurrencyAlgorithm.json") { $Session.CurrencyAlgorithm = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\CurrencyAlgorithm.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
if (-not $Session.CurrencyAlgorithm.Keys) { 
    Write-Error "Terminating error - cannot continue! File '.\Data\CurrencyAlgorithm.json' is not a valid JSON file. Please restore it from your original download."
    $null = (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\CurrencyAlgorithm.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112)
    Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
    Start-Sleep -Seconds 5
    exit
}
Write-Host "Loaded currency database." -NoNewline; Write-Host " ✔  ($($Session.CurrencyAlgorithm.Count) $(if ($Session.CurrencyAlgorithm.Count -eq 1) { "entry" } else { "entries" } ))" -ForegroundColor Green

# Load EquihashCoinPers data as case insensitive sorted list
if (Test-Path -LiteralPath "$PWD\Data\EquihashCoinPers.json") { $Session.EquihashCoinPers = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\EquihashCoinPers.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
if (-not $Session.EquihashCoinPers) { 
    Write-Error "Terminating error - cannot continue! File '.\Data\EquihashCoinPers.json' is not a valid JSON file. Please restore it from your original download."
    $null = $WscriptShell.Popup("File '.\Data\EquihashCoinPers.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112)
    Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
    Start-Sleep -Seconds 5
    exit
}
Write-Host "Loaded equihash coins database." -NoNewline; Write-Host " ✔  ($($Session.EquihashCoinPers.Count) $(if ($Session.EquihashCoinPers.Count -eq 1) { "entry" } else { "entries" } ))" -ForegroundColor Green

# Load regions as case insensitive hash table
if (Test-Path -LiteralPath "$PWD\Data\Regions.json") { 
    $Session.Regions = [Ordered]@{ }
    ([System.IO.File]::ReadAllLines("$PWD\Data\Regions.json") | ConvertFrom-Json).PSObject.Properties.ForEach({ $Session.Regions[$_.Name] = @($_.Value) })
}
if (-not $Session.Regions.Keys) { 
    Write-Error "Terminating error - cannot continue! File '.\Data\Regions.json' is not a valid JSON file. Please restore it from your original download."
    $null = (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\Regions.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112)
    Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
    Start-Sleep -Seconds 5
    exit
}
Write-Host "Loaded regions database." -NoNewline; Write-Host " ✔  ($($Session.Regions.Count) $(if ($Session.Regions.Count -eq 1) { "entry" } else { "entries" } ))" -ForegroundColor Green

# Load FIAT currencies list as case insensitive sorted list
if (Test-Path -LiteralPath "$PWD\Data\FIATcurrencies.json") { $Session.FIATcurrencies = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\FIATcurrencies.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
if (-not $Session.FIATcurrencies) { 
    Write-Error "Terminating error - cannot continue! File '.\Data\FIATcurrencies.json' is not a valid JSON file. Please restore it from your original download."
    $null = (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\FIATcurrencies.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112)
    Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
    Start-Sleep -Seconds 5
    exit
}
Write-Host "Loaded fiat currencies database." -NoNewline; Write-Host " ✔  ($($Session.FIATcurrencies.Count) $(if ($Session.FIATcurrencies.Count -eq 1) { "entry" } else { "entries" } ))" -ForegroundColor Green

# Load unprofitable algorithms as case insensitive sorted list, cannot use one-liner (Error 'Cannot find an overload for "new" and the argument count: "2"')
$Session.UnprofitableAlgorithms = [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase)
if (Test-Path -LiteralPath "$PWD\Data\UnprofitableAlgorithms.json") { 
    $UnprofitableAlgorithms = [System.IO.File]::ReadAllLines("$PWD\Data\UnprofitableAlgorithms.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject
    $UnprofitableAlgorithms.Keys.ForEach({ $Session.UnprofitableAlgorithms.$_ = $UnprofitableAlgorithms.$_ })
    Remove-Variable UnprofitableAlgorithms
}
if (-not $Session.UnprofitableAlgorithms.Count) { 
    Write-Error "Error loading list of unprofitable algorithms. File '.\Data\UnprofitableAlgorithms.json' is not a valid $($Session.Branding.ProductLabel) JSON data file. Please restore it from your original download."
    $null = (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\UnprofitableAlgorithms.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112)
    Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
    Start-Sleep -Seconds 5
    exit
}
Write-Host "Loaded unprofitable algorithms database." -NoNewline; Write-Host " ✔  ($($Session.UnprofitableAlgorithms.Count) $(if ($Session.UnprofitableAlgorithms.Count -eq 1) { "entry" } else { "entries" } ))" -ForegroundColor Green

# Load DAG data, if not available it will get recreated
if (Test-Path -LiteralPath "$PWD\Data\DAGdata.json") { $Session.DAGdata = [System.IO.File]::ReadAllLines("$PWD\Data\DAGdata.json") | ConvertFrom-Json -ErrorAction Ignore | Get-SortedObject }
if (-not $Session.DAGdata) { 
    Write-Error "Error loading DAG database. File '.\Data\DAGdata.json' is not a valid $($Session.Branding.ProductLabel) JSON data file. Please restore it from your original download."
    $null = (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\DAGdata.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112)
    Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
    Start-Sleep -Seconds 5
    exit
}
Write-Host "Loaded DAG database." -NoNewline; Write-Host " ✔  ($($Session.DAGdata.Currency.PSObject.Properties.Name.Count) $(if ($Session.DAGdata.Currency.PSObject.Properties.Name.Count -eq 1) { "entry" } else { "entries" } ))" -ForegroundColor Green

# Load PoolsLastUsed data as case insensitive sorted list
if (Test-Path -LiteralPath "$PWD\Data\PoolsLastUsed.json") { $Session.PoolsLastUsed = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\PoolsLastUsed.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
if (-not $Session.PoolsLastUsed.psBase.Keys) { 
    $Session.PoolsLastUsed = @{ }
}
else { 
    Write-Host "Loaded pools last used database." -NoNewline; Write-Host " ✔  ($($Session.PoolsLastUsed.Count) $(if ($Session.PoolsLastUsed.Count -eq 1) { "entry" } else { "entries" } ))" -ForegroundColor Green
}

# Load AlgorithmsLastUsed data as case insensitive sorted list
if (Test-Path -LiteralPath "$PWD\Data\AlgorithmsLastUsed.json") { $Session.AlgorithmsLastUsed = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\AlgorithmsLastUsed.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
if (-not $Session.AlgorithmsLastUsed.psBase.Keys) { 
    $Session.AlgorithmsLastUsed = @{ }
}
else { 
    Write-Host "Loaded algorithms last used database." -NoNewline; Write-Host " ✔  ($($Session.AlgorithmsLastUsed.Count) $(if ($Session.AlgorithmsLastUsed.Count -eq 1) { "entry" } else { "entries" } ))" -ForegroundColor Green
}

# Load MinersLastUsed data as case insensitive sorted list
if (Test-Path -LiteralPath "$PWD\Data\MinersLastUsed.json") { $Session.MinersLastUsed = [System.Collections.SortedList]::New(([System.IO.File]::ReadAllLines("$PWD\Data\MinersLastUsed.json") | ConvertFrom-Json -AsHashtable | Get-SortedObject), [StringComparer]::OrdinalIgnoreCase) }
if (-not $Session.MinersLastUsed.psBase.Keys) { 
    $Session.MinersLastUsed = @{ }
}
else { 
    Write-Host "Loaded miners last used database." -NoNewline; Write-Host " ✔  ($($Session.MinersLastUsed.Count) $(if ($Session.MinersLastUsed.Count -eq 1) { "entry" } else { "entries" } ))" -ForegroundColor Green
}

# Load EarningsChart data to make it available early in GUI
if (Test-Path -LiteralPath "$PWD\Cache\EarningsChartData.json" -PathType Leaf) { 
    $Session.EarningsChartData = [System.IO.File]::ReadAllLines("$PWD\Cache\EarningsChartData.json") | ConvertFrom-Json
    $Session.BalancesUpdatedTimestamp = (Get-ItemProperty -LiteralPath "$PWD\Cache\EarningsChartData.json" -Name LastWriteTime).lastwritetime.ToString("G")
}
if (-not $Session.EarningsChartData.Earnings) { 
    $Session.EarningsChartData = @{ }
    $Session.BalancesUpdatedTimestamp = (Get-Date -Format "G")
}
else { 
    Write-Host "Loaded earnings chart database." -NoNewline; Write-Host " ✔  ($($Session.EarningsChartData.Earnings.PSObject.Properties.Name.Count) $(if ($Session.EarningsChartData.Earnings.PSObject.Properties.Name.Count -eq 1) { "entry" } else { "entries" } ))" -ForegroundColor Green
}

# Load Balances data to make it available early in GUI
if (Test-Path -LiteralPath "$PWD\Cache\Balances.json" -PathType Leaf) { $Session.Balances = [System.IO.File]::ReadAllLines("$PWD\Cache\Balances.json") | ConvertFrom-Json -AsHashtable }
if (-not $Session.Balances.Keys) { 
    $Session.Balances = [Ordered]@{ } # as case insensitive hash table
}
else { 
    Write-Host "Loaded balances database." -NoNewline; Write-Host " ✔  ($($Session.Balances.PSObject.Properties.Name.Count) $(if ($Session.Balances.PSObject.Properties.Name.Count-eq 1) { "entry" } else { "entries" } ))" -ForegroundColor Green
}

# Load NVidia GPU architecture table
if (Test-Path -LiteralPath "$PWD\Data\GPUArchitectureNvidia.json") { $Session.GPUArchitectureDbNvidia = [System.IO.File]::ReadAllLines("$PWD\Data\GPUArchitectureNvidia.json") | ConvertFrom-Json -ErrorAction Ignore }
if (-not $Session.GPUArchitectureDbNvidia) { 
    Write-Message -Level Error "Terminating error - cannot continue! File '.\Data\GPUArchitectureNvidia.json' is not a valid JSON file. Please restore it from your original download."
    $null = (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\GPUArchitectureNvidia.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112)
    Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
    Start-Sleep -Seconds 5
    exit
}
else { 
    $Session.GPUArchitectureDbNvidia.PSObject.Properties.ForEach({ $_.Value.Model = $_.Value.Model -join "|" })
    Write-Host "Loaded NVidia GPU architecture database." -NoNewline; Write-Host " ✔  ($($Session.GPUArchitectureDbNvidia.PSObject.Properties.Name.Count) $(if ($Session.GPUArchitectureDbNvidia.PSObject.Properties.Name.Count -eq 1) { "entry" } else { "entries" } ))" -ForegroundColor Green
}

# Load AMD GPU architecture table
if (Test-Path -LiteralPath "$PWD\Data\GPUArchitectureAMD.json") { $Session.GPUArchitectureDbAMD = [System.IO.File]::ReadAllLines("$PWD\Data\GPUArchitectureAMD.json") | ConvertFrom-Json -ErrorAction Ignore }
if (-not $Session.GPUArchitectureDbAMD) { 
    Write-Message -Level Error "Terminating error - cannot continue! File '.\Data\GPUArchitectureAMD.json' is not a valid JSON file. Please restore it from your original download."
    $null = (New-Object -ComObject Wscript.Shell).Popup("File '.\Data\GPUArchitectureAMD.json' is not a valid JSON file.`nPlease restore it from your original download.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112)
    Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
    Start-Sleep -Seconds 5
    exit
}
else { 
    $Session.GPUArchitectureDbAMD.PSObject.Properties.ForEach({ $_.Value = $_.Value -join "|" })
    Write-Host "Loaded AMD GPU architecture database." -NoNewline; Write-Host " ✔  ($($Session.GPUArchitectureDbAMD.PSObject.Properties.Name.Count) $(if ($Session.GPUArchitectureDbAMD.PSObject.Properties.Name.Count -eq 1) { "entry" } else { "entries" } ))" -ForegroundColor Green
}

$Session.BalancesCurrencies = @($Session.Balances.PSObject.Properties.Name.ForEach({ $Session.Balances.$_.Currency }) | Sort-Object -Unique)

$CursorPosition = $Host.UI.RawUI.CursorPosition
[Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
Write-Host " ✔" -ForegroundColor Green
[Console]::SetCursorPosition($CursorPosition.X, $CursorPosition.y)

Write-Host ""
if (Test-Path -LiteralPath $Session.ConfigFile) { 
    Write-Message -Level Info "Using configuration file '$($Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'."
}
else { 
    $Session.FreshConfig = $true
    $Session.NewMiningStatus = $Session.MiningStatus = "Idle"
}

# Read configuration, if no config file exists Read-Config will create an initial running configuration in memory
Read-Config -ConfigFile $Session.ConfigFile -PoolsConfigFile $Session.PoolsConfigFile

# Start log reader (SnakeTail) [https://github.com/snakefoot/snaketail-net]
if ($Session.Config.LogViewerConfig -and $Session.Config.LogViewerConfig) { 
    $Session.LogViewerConfig = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Session.Config.LogViewerConfig)
    $Session.LogViewerExe = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Session.Config.LogViewerExe)
    if (-not (Get-CimInstance CIM_Process).Where({ $_.CommandLine -eq """$($Session.LogViewerExe)"" $($Session.LogViewerConfig)" })) { & $($Session.LogViewerExe) $($Session.LogViewerConfig) }
}

# Update config file to include all new config items
if (-not $Session.Config.ConfigFileVersion -or [System.Version]::Parse($Session.Config.ConfigFileVersion) -lt $Session.Branding.Version) { Update-ConfigFile -ConfigFile $Session.ConfigFile }

# Internet connection must be available
Write-Host ""
Write-Host "Checking internet connection..." -ForegroundColor Yellow -NoNewline
$NetworkInterface = (Get-NetConnectionProfile).Where({ $_.IPv4Connectivity -eq "Internet" }).InterfaceIndex
$Session.MyIPaddress = if ($NetworkInterface) { (Get-NetIPAddress -InterfaceIndex $NetworkInterface -AddressFamily IPV4).IPAddress } else { $null }
Remove-Variable NetworkInterface
if (-not $Session.MyIPaddress) { 
    Write-Host " ✖" -ForegroundColor Red
    Write-Message -Level Error "Terminating Error - no internet connection. $($Session.Branding.ProductLabel) will shut down."
    (New-Object -ComObject Wscript.Shell).Popup("No internet connection`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
    exit
}
Write-Host " ✔  (IP address: $($Session.MyIPaddress))" -ForegroundColor Green

# Check if a new version is available and run update if so configured
Write-Host ""
Get-Version

# Prerequisites check
Write-Message -Level Verbose "Verifying pre-requisites..."
[Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
Write-Host " OS Version" -NoNewline
if ([System.Environment]::OSVersion.Version -lt [System.Version]"10.0.0.0") { 
    Write-Host " ✖" -ForegroundColor Red
    Write-Message -Level Error "$($Session.Branding.ProductLabel) requires at least Windows 10. $($Session.Branding.ProductLabel) will shut down."
    (New-Object -ComObject Wscript.Shell).Popup("$($Session.Branding.ProductLabel) requires at least Windows 10.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
    exit
}
Write-Host " ✔ " -ForegroundColor Green -NoNewline

Write-Host " Runtime modules" -NoNewline
$Prerequisites = @(
    "$env:SystemRoot\System32\MSVCR120.dll",
    "$env:SystemRoot\System32\VCRUNTIME140.dll",
    "$env:SystemRoot\System32\VCRUNTIME140_1.dll"
)
if ($PrerequisitesMissing = $Prerequisites.Where({ -not (Test-Path -LiteralPath $_ -PathType Leaf) })) { 
    Write-Host " ✖ " -ForegroundColor Red
    $PrerequisitesMissing.ForEach({ Write-Message -Level Warn "'$_' is missing." })
    Write-Message -Level Error "Please install the required runtime modules. Download and extract"
    Write-Message -Level Error "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/Visual-C-Runtimes-All-in-One-Sep-2019/Visual-C-Runtimes-All-in-One-Sep-2019.zip"
    Write-Message -Level Error "and run 'install_all.bat' (Administrative privileges are required)."
    Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
    (New-Object -ComObject Wscript.Shell).Popup("Prerequisites missing.`nPlease install the required runtime modules.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
    exit
}
Remove-Variable Prerequisites, PrerequisitesMissing
Write-Host " ✔ " -ForegroundColor Green -NoNewline

Write-Host " Windows Management Framework 5.1" -NoNewline
if (-not (Get-Command Get-PnpDevice)) { 
    Write-Host " ✖ " -ForegroundColor Red
    Write-Message -Level Error "Windows Management Framework 5.1 is missing.`nPlease install the required runtime modules from https://www.microsoft.com/en-us/download/details.aspx?id=54616. $($Session.Branding.ProductLabel) will shut down."
    (New-Object -ComObject Wscript.Shell).Popup("Windows Management Framework 5.1 is missing.`nPlease install the required runtime modules.`n`n$($Session.Branding.ProductLabel) will shut down.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
    exit
}
Remove-Variable RecommendedPWSHversion
Write-Host " ✔" -ForegroundColor Green

$Session.IsLocalAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Exclude from AV scanner
if ($Session.FreshConfig -and (Get-Command "Get-MpPreference") -and (Get-MpComputerStatus)) { 
    try { 
        Write-Message -Level Verbose "Excluding the $($Session.Branding.ProductLabel) directory from Microsoft Defender Antivirus scans to avoid false virus alerts..."
        if (-not $Session.IsLocalAdmin) { 
            Write-Host "You must accept the UAC control dialog to continue." -ForegroundColor Blue -NoNewline
            Start-Sleep -Seconds 5
        }
        Start-Process "pwsh" "-Command Write-Host 'Excluding UG-Miner directory ''$(Convert-Path .)'' from Microsoft Defender Antivirus scans...'; Import-Module Defender -SkipEditionCheck; Add-MpPreference -ExclusionPath '$(Convert-Path .)'" -Verb runAs
        [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
        Write-Host " ✔" -ForegroundColor Green
        Write-Host "                                                    "
        [Console]::SetCursorPosition(0, $Host.UI.RawUI.CursorPosition.Y - 1)
    }
    catch { 
        [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
        Write-Host " ✖" -ForegroundColor Red
        Write-Message -Level Error "Could not exclude the directory '$PWD' from Microsoft Defender Antivirus scans. $($Session.Branding.ProductLabel) will shut down."
        (New-Object -ComObject Wscript.Shell).Popup("Could not exclude the directory`n'$PWD'`n from Microsoft Defender Antivirus scans.`nThis would lead to unpredictable results.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
        exit
    }
    # Unblock files
    if (Get-Command "Unblock-File" -ErrorAction Ignore) { 
        if (Get-Item .\* -Stream Zone.*) { 
            Write-Message -Level Verbose "Unblocking files that were downloaded from the internet..."
            Get-ChildItem -Path . -Recurse | Unblock-File
            [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
            Write-Host " ✔" -ForegroundColor Green
        }
    }
}

$Session.VertHashDatPath = ".\Cache\VertHash.dat"
if (Test-Path -LiteralPath $Session.VertHashDatPath -PathType Leaf) { 
    Write-Message -Level Verbose "Verifying integrity of VertHash data file '$($Session.VertHashDatPath)'..."
    $VertHashDatCursorPosition = $Session.CursorPosition
}
# Start-ThreadJob needs to be run in any case to set number of threads (# of devices + downloader)
$VertHashDatCheckJob = Start-ThreadJob -InitializationScript ([ScriptBlock]::Create("Set-Location '$($Session.MainPath)'")) -ScriptBlock { if (Test-Path -LiteralPath ".\Cache\VertHash.dat" -PathType Leaf) { (Get-FileHash -Path ".\Cache\VertHash.dat").Hash -eq "A55531E843CD56B010114AAF6325B0D529ECF88F8AD47639B6EDEDAFD721AA48" } } -StreamingHost $null -ThrottleLimit ((Get-CimInstance CIM_VideoController).Count + 1)

Write-Message -Level Verbose "Importing modules... "
[Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
Write-Host "~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll" -NoNewline
try { 
    Add-Type -Path ".\Cache\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll"
    Write-Host " ✔ " -ForegroundColor Green -NoNewline
}
catch { 
    if (Test-Path -LiteralPath ".\Cache\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll" -ErrorAction Ignore) { Remove-Item ".\Cache\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll" -Force }
    try { 
        Add-Type -Path ".\Includes\OpenCL\*.cs" -OutputAssembly ".\Cache\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll"
        Add-Type -Path ".\Cache\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll"
        Write-Host " ✔ " -ForegroundColor Green -NoNewline
    }
    catch { 
        Write-Host " ✖ " -ForegroundColor Red -NoNewline
        $ErrorLoadingModules = $true
    }
}
Write-Host " ~CPUID_$($PSVersionTable.PSVersion.ToString()).dll" -NoNewline
try { 
    Add-Type -Path ".\Cache\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll"
    Write-Host " ✔ " -ForegroundColor Green -NoNewline
}
catch { 
    if (Test-Path -LiteralPath ".\Cache\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll" -ErrorAction Ignore) { Remove-Item ".\Cache\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll" -Force }
    try { 
        Add-Type -Path ".\Includes\CPUID.cs" -OutputAssembly ".\Cache\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll"
        Add-Type -Path ".\Cache\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll"
        Write-Host " ✔ " -ForegroundColor Green -NoNewline
    }
    catch { 
        Write-Host " ✖ " -ForegroundColor Red -NoNewline
        $ErrorLoadingModules = $true
    }
}
Write-Host " NetSecurity" -NoNewline
try { 
    Import-Module NetSecurity -ErrorAction Stop
    Write-Host " ✔ " -ForegroundColor Green -NoNewline
}
catch { 
    Write-Host " ✖ " -ForegroundColor Red -NoNewline
    $ErrorLoadingModules = $true
}
Write-Host " Defender" -NoNewline
try {
    Import-Module Defender -ErrorAction Stop -SkipEditionCheck
    Write-Host " ✔ " -ForegroundColor Green -NoNewline
}
catch { 
    Write-Host " ✖ " -ForegroundColor Red -NoNewline
    $ErrorLoadingModules = $true
}
if ($ErrorLoadingModules) { 
    Write-Error "Terminating error - cannot import required modules."
    (New-Object -ComObject Wscript.Shell).Popup("Cannot import required modules.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
    Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
    Start-Sleep -Seconds 5
    exit
}

Write-Host ""
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

$Session.BrainData = @{ }
$Session.Brains = @{ }
$Session.CoreLoopCounter = [Int64]0
$Session.CPUfeatures = (Get-CpuId).Features
$Session.CycleStarts = @()
$Session.Donation = [System.Collections.SortedList]::new([StringComparer]::OrdinalIgnoreCase)
$Session.MiningEarnings = $Session.MiningProfit = $Session.MiningPowerCost = [Double]::NaN
$Session.NewMiningStatus = if ($Session.Config.StartupMode -match "Paused|Running") { $Session.Config.StartupMode } else { "Idle" }
$Session.RestartCycle = $true
$Session.SuspendCycle = $false
$Session.WatchdogTimers = [System.Collections.Generic.List[PSCustomObject]]::new()

$Session.RegexAlgoIsEthash = "^Autolykos2$|^EtcHash$|^Ethash$|^EthashB3$|^EthashSHA256$|^UbqHash$|^XHash$"
$Session.RegexAlgoIsProgPow = "^EvrProgPow$|^FiroPow$|^KawPow$|^MeowPow$|^PhiHash$|^ProgPow|^SCCpow$"
$Session.RegexAlgoHasDynamicDAG = "^Autolykos2$|^EtcHash$|^Ethash$|^EthashB3$|^EthashSHA256$|^EvrProgPow$|^FiroPow$|^KawPow$|^MeowPow$|^Octopus$|^PhiHash$|^ProgPow|^SCCpow$|^UbqHash$|^XHash$"
$Session.RegexAlgoHasStaticDAG = "^FishHash$|^HeavyHashKarlsenV2$"
$Session.RegexAlgoHasDAG = (($Session.RegexAlgoHasDynamicDAG -split "\|") + ($Session.RegexAlgoHasStaticDAG -split "\|") | Sort-Object) -join "|"
[Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
Write-Host " ✔" -ForegroundColor Green

$Session.Summary = "Loading miner device information.<br>This may take a while..."
Write-Message -Level Verbose "$($Session.Summary)"

$Session.SupportedCPUDeviceVendors = @("AMD", "INTEL")
$Session.SupportedGPUDeviceVendors = @("AMD", "INTEL", "NVIDIA")

$Session.Devices = Get-Device

if ($Session.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -eq "AMD" }).OpenCL.DriverVersion -and (Get-Item -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Khronos\OpenCL\Vendors).Property -notlike "*\amdocl64.dll") { 
    Write-Message -Level Error "OpenCL driver installation for AMD GPU devices is incomplete"
    Write-Message -Level Error "Please create the missing registry key as described in https://github.com/ethereum-mining/ethminer/issues/2001#issuecomment-662288143. $($Session.Branding.ProductLabel) will shut down."
    (New-Object -ComObject Wscript.Shell).Popup("The OpenCL driver installation for AMD GPU devices is incomplete.`nPlease create the missing registry key as described here:`n`nhttps://github.com/ethereum-mining/ethminer/issues/2001#issuecomment-662288143`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
    exit
}

$Session.Devices.Where({ $_.Type -eq "CPU" -and $_.Vendor -notin $Session.SupportedCPUDeviceVendors }).ForEach({ $_.State = [DeviceState]::Unsupported; $_.Status = "Unavailable"; $_.StatusInfo = "Unsupported CPU vendor: '$($_.Vendor)'" })
$Session.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -notin $Session.SupportedGPUDeviceVendors }).ForEach({ $_.State = [DeviceState]::Unsupported; $_.Status = "Unavailable"; $_.StatusInfo = "Unsupported GPU vendor: '$($_.Vendor)'" })
$Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Type -eq "GPU" -and -not ($_.CUDAversion -or $_.OpenCL.DriverVersion) }).ForEach({ $_.State = [DeviceState]::Unsupported; $_.Status = "Unavailable"; $_.StatusInfo = "Unsupported GPU model: '$($_.Model)'" })

$Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported }).ForEach({ $_.Status = $_.SubStatus = "Idle"; if ($Session.Config.ExcludeDeviceName -contains $_.Name) { $_.State = [DeviceState]::Disabled; $_.Status = "Idle"; $_.StatusInfo = "Disabled (ExcludeDeviceName: '$($_.Name)')" } else { $Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported }).ForEach({ $_.Status = $_.SubStatus = "Idle"; if ($Session.Config.ExcludeDeviceName -contains $_.Name) { $_.State = [DeviceState]::Disabled; $_.Status = "Idle"; $_.StatusInfo = "Disabled (ExcludeDeviceName: '$($_.Name)')" } else { $_.SubStatus = "Idle" } }) = "Idle" } })

# Build driver version table
$Session.DriverVersion = [PSCustomObject]@{ }
if ($Session.Devices.CUDAversion) { $Session.DriverVersion | Add-Member "CUDA" ($Session.Devices.CUDAversion | Sort-Object -Top 1) }
$Session.DriverVersion | Add-Member "CIM" ([PSCustomObject]@{ })
$Session.DriverVersion.CIM | Add-Member "CPU" ([System.Version](($Session.Devices.Where({ $_.Type -eq "CPU" }).CIM.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))
$Session.DriverVersion.CIM | Add-Member "AMD" ([System.Version](($Session.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -eq "AMD" }).CIM.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))
$Session.DriverVersion.CIM | Add-Member "NVIDIA" ([System.Version](($Session.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -eq "NVIDIA" }).CIM.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))
$Session.DriverVersion | Add-Member "OpenCL" ([PSCustomObject]@{ })
$Session.DriverVersion.OpenCL | Add-Member "CPU" ([System.Version](($Session.Devices.Where({ $_.Type -eq "CPU" }).OpenCL.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))
$Session.DriverVersion.OpenCL | Add-Member "AMD" ([System.Version](($Session.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -eq "AMD" }).OpenCL.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))
$Session.DriverVersion.OpenCL | Add-Member "NVIDIA" ([System.Version](($Session.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -eq "NVIDIA" }).OpenCL.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))

[Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
Write-Host " ✔  ($($Session.Devices.count) device$(if ($Session.Devices.count -ne 1) { "s" }) found" -ForegroundColor Green -NoNewline
if ($Session.Devices.Where({ $_.State -eq [DeviceState]::Unsupported })) { Write-Host " [$($Session.Devices.Where({ $_.State -eq [DeviceState]::Unsupported }).Count) unsupported device$(if ($Session.Devices.Where({ $_.State -eq [DeviceState]::Unsupported }).Count -ne 1){ "s" })]" -ForegroundColor DarkYellow -NoNewline } 
Write-Host ")" -ForegroundColor Green

# Driver version changed
if ((Test-Path -LiteralPath ".\Cache\DriverVersion.json" -PathType Leaf) -and ([System.IO.File]::ReadAllLines("$PWD\Cache\DriverVersion.json") | ConvertFrom-Json | ConvertTo-Json -Compress) -ne ($Session.DriverVersion | ConvertTo-Json -Compress)) { Write-Message -Level Warn "Graphics card driver version data has changed. It is recommended to re-benchmark all miners." }
$Session.DriverVersion | ConvertTo-Json | Out-File -LiteralPath ".\Cache\DriverVersion.json" -Force

# Rename existing switching log
if (Test-Path -LiteralPath ".\Logs\SwitchingLog.csv" -PathType Leaf) { Get-ChildItem -Path ".\Logs\SwitchingLog.csv" -File | Rename-Item -NewName { "SwitchingLog_$($_.LastWriteTime.toString("yyyy-MM-dd_HH-mm-ss")).csv" } }

$CursorPosition = $Host.UI.RawUI.CursorPosition
if ($VertHashDatCheckJob | Wait-Job -Timeout 60 | Receive-Job -Wait -AutoRemoveJob) { 
    [Console]::SetCursorPosition($VertHashDatCursorPosition.X, $VertHashDatCursorPosition.Y)
    Write-Host " ✔  (checksum ok)" -ForegroundColor Green
}
else { 
    if (Test-Path -LiteralPath $Session.VertHashDatPath -PathType Leaf -ErrorAction Ignore) { 
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

if ($Session.Config.APIport) { 
    Start-APIserver
}
else { 
    # Use port 4000 for miner communication
    $Session.MinerBaseAPIport = 4000
    Write-Message -Level Warn "No valid TCP port for API; Using port $(if ($Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported }).Count -eq 1) { $Session.MinerBaseAPIport } else { "range $($Session.MinerBaseAPIport) - $(4000 + $Session.Devices.Where({ $_.State -ne [DeviceState]::Unsupported }).Count - 1)" }) for miner communication."
}

if ($Session.FreshConfig -or $Session.ConfigurationHasChangedDuringUpdate) { 
    if ($Session.FreshConfig) { 
        # Must click 'Start mining' in GUI
        $Session.NewMiningStatus = "Idle"
        Write-Host ""
        Write-Message -Level Warn "No configuration file found. Edit and save your configuration using the configuration editor (http://localhost:$($Session.Config.APIport)/configedit.html)"
        $Session.Summary = "Edit your settings and save the configuration.<br>Then click the 'Start mining' button."
        (New-Object -ComObject Wscript.Shell).Popup("No configuration file found.`n`nEdit and save your configuration using the configuration editor (http://localhost:$($Session.Config.APIport)/configedit.html).`n`n`Start making money by clicking 'Start mining'.`n`nHappy Mining!", 0, "Welcome to $($Session.Branding.ProductLabel) v$($Session.Branding.Version)", (4096 + 48)) | Out-Null
    }
    elseif ($Session.Config.StartupMode -ne "Running") {
        # Always accept changed config when StartupMode is 'running'
        Write-Message -Level Warn "Configuration has changed during update. Verify and save your configuration using the configuration editor (http://localhost:$($Session.Config.APIport)/configedit.html)"
        $Session.Summary = "Verify your settings and save the configuration.<br>Then click the 'Start mining' button."
        (New-Object -ComObject Wscript.Shell).Popup("The configuration has changed during update:`n`n$($Session.ConfigurationHasChangedDuringUpdate -join $nl)`n`nVerify and save the configuration using the configuration editor (http://localhost:$($Session.Config.APIport)/configedit.html).`n`n`Start making money by clicking 'Start mining'.`n`nHappy Mining!", 0, "$($Session.Branding.ProductLabel) v$($Session.Branding.Version) - configuration has changed", (4096 + 64)) | Out-Null
    }
}

Write-Host ""

. .\Includes\LegacyGUI.ps1
$LegacyGUIform.ShowInTaskbar = $Session.Config.LegacyGUI
$LegacyGUIform.ShowDialog() | Out-Null