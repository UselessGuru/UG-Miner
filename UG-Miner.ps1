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
Version:        6.7.12
Version date:   2025/12/20
#>

using module .\Includes\Include.psm1

param(
    [Parameter (Mandatory = $false)]
    [String[]]$Algorithm = @(), # i.e. @("Equihash1445", "Ethash", "KawPow") etc. If '+' is used, then only the explicitly enabled algorithms are used. If '-' is used, then all algorithms except the disabled ones are used. Do not combine '+' and '-' concurrently.
    [Parameter (Mandatory = $false)]
    [String]$APIlogfile = "", # API will log all requests to this file, leave empty to disable
    [Parameter (Mandatory = $false)]
    [UInt]$APIport = 3999, # TCP Port for API and web GUI
    [Parameter (Mandatory = $false)]
    [Switch]$AutoReboot = $true, # If true will reboot computer when a miner is completely dead, e.g. unresponsive
    [Parameter (Mandatory = $false)]
    [Switch]$AutoUpdate = $true, # If true will automatically update to the new version
    [Parameter (Mandatory = $false)]
    [Int]$AutoUpdateCheckInterval = 1, # If true will periodically check for a new program version every n days (0 to disable)
    [Parameter (Mandatory = $false)]
    [Switch]$BackupOnAutoUpdate = $true, # If true a backup copy will be saved as '[UG-Miner directory]\AutoUpdate\Backup_v[version]_[date_time].zip' when updateing
    [Parameter (Mandatory = $false)]
    [Double]$BadShareRatioThreshold = 0.05, # Allowed ratio of bad shares (total / bad) as reported by the miner. If the ratio exceeds the configured threshold then the miner will get marked as failed. Allowed values: 0.00 - 1.00. 0 disables this check
    [Parameter (Mandatory = $false)]
    [Boolean]$BalancesKeepAlive = $true, # If true will force mining at a pool to protect your earnings (some pools auto-purge the wallet after longer periods of inactivity, see '\Data\PoolData.Json' BalancesKeepAlive properties)
    [Parameter (Mandatory = $false)]
    [Boolean]$BalancesShowSums = $true, # Show 1hr / 6hrs / 24hr / 7day & 30day pool earnings sums in web dashboard
    [Parameter (Mandatory = $false)]
    [Boolean]$BalancesShowAverages = $true, # Show 1hr / 24hr & 7day pool earnings averages in web dashboard
    [Parameter (Mandatory = $false)]
    [Boolean]$BalancesShowInAllCurrencies = $true, # If true pool balances will be shown in all currencies in web dashboard
    [Parameter (Mandatory = $false)]
    [Boolean]$BalancesShowInFIATcurrency = $true, # If true pool balances will be shown in main currency in web dashboard
    [Parameter (Mandatory = $false)]
    [String[]]$BalancesTrackerExcludePools = @("MiningDutch"), # Balances tracker will not track these pools
    [Parameter (Mandatory = $false)]
    [Switch]$BalancesTrackerLog = $false, # If true will store all balance tracker data in .\Logs\EarningTrackerLog.csv
    [Parameter (Mandatory = $false)]
    [UInt16]$BalancesTrackerPollInterval = 10, # minutes, interval duration to trigger background task to collect pool balances & earnings data; set to 0 to disable, minumum value 10
    [Parameter (Mandatory = $false)]
    [Switch]$BenchmarkAllPoolAlgorithmCombinations = [Boolean]($Host.Name -eq "Visual Studio Code Host"),
    [Parameter (Mandatory = $false)]
    [Switch]$CalculatePowerCost = [Boolean](Get-ItemProperty -Path "HKCU:\Software\HWiNFO64\VSB" -ErrorAction Ignore), # If true power consumption will be read from miners and calculate power cost, required for true profit calculation
    [Parameter (Mandatory = $false)]
    [String]$ConfigFile = ".\Config\Config.json", # Config file name
    [Parameter (Mandatory = $false)]
    [Int]$CPUMiningReserveCPUcore = 1, # Number of CPU cores reserved for main script processing. Helps to get more stable hashrates and faster core loop processing.
    [Parameter (Mandatory = $false)]
    [Int]$CPUMinerProcessPriority = "-2", # Process priority for CPU miners
    [Parameter (Mandatory = $false)]
    [String[]]$Currency = @(), # i.e. @("+ETC", +EVR", "+KIIRO") etc. If '+' is used, then only the explicitly enabled currencies are used. If '-' is used, then all currencies except the disabled ones are used. Do not combine '+' and '-' concurrently.
    [Parameter (Mandatory = $false)]
    [Int]$DecimalsMax = 6, # Display numbers with maximal n decimal digits (larger numbers are shown with less decimal digits)
    [Parameter (Mandatory = $false)]
    [Int]$Delay = 0, # seconds between stop and start of miners, use only when getting blue screens on miner switches
    [Parameter (Mandatory = $false)]
    [Switch]$DisableCpuMiningOnBattery = $false, # If true will not use CPU miners while running on battery
    [Parameter (Mandatory = $false)]
    [Switch]$DisableDualAlgoMining = $false, # If true will not use any dual algorithm miners
    [Parameter (Mandatory = $false)]
    [Switch]$DisableMinerFee = $false, # Set to true to disable miner fees (Note: not all miners support turning off their built in fees, others will reduce the hashrate)
    [Parameter (Mandatory = $false)]
    [Switch]$DisableMinersWithFee = $false, # Set to true to disable all miners which contain fees
    [Parameter (Mandatory = $false)]
    [Switch]$DisableSingleAlgoMining = $false, # If true will not use any single algorithm miners
    [Parameter (Mandatory = $false)]
    [Int]$Donation = 15, # Minutes per Day
    [Parameter (Mandatory = $false)]
    [Switch]$DryRun = $false, # If true will do all the benchmarks, but will not mine
    [Parameter (Mandatory = $false)]
    [Double]$EarningsAdjustmentFactor = 1, # Default adjustment factor for prices reported by ALL pools (unless there is a per pool value configuration definined). Prices will be multiplied with this. Allowed values: 0.0 - 10.0
    [Parameter (Mandatory = $false)]
    [String[]]$ExcludeDeviceName = @(), # Array of disabled devices, e.g. @("CPU#00", "GPU#02"); by default all devices are enabled
    [Parameter (Mandatory = $false)]
    [String[]]$ExcludeMinerName = @(), # List of miners to be excluded; Either specify miner short name, e.g. "PhoenixMiner" (without '-v...') to exclude any version of the miner, or use the full miner name incl. version information
    [Parameter (Mandatory = $false)]
    [String[]]$ExtraCurrencies = @("ETC", "ETH", "mBTC"), # Extra currencies used in balances summary, enter 'real-world' or crypto currencies, mBTC (milli BTC) is also allowed
    [Parameter (Mandatory = $false)]
    [String]$FIATcurrency = (Get-Culture).NumberFormat.CurrencySymbol, # Default main 'real-money' currency, i.e. GBP, USD, AUD, NZD etc. Do not use crypto currencies
    [Parameter (Mandatory = $false)]
    [Int]$GPUMinerProcessPriority = "-1", # Process priority for GPU miners
    [Parameter (Mandatory = $false)]
    [Switch]$IdleDetection = $false, # If true will start mining only if system is idle for $IdleSec seconds
    [Parameter (Mandatory = $false)]
    [Int]$IdleSec = 120, # seconds the system must be idle before mining starts
    [Parameter (Mandatory = $false)]
    [Switch]$Ignore0HashrateSample = $false, # If true will ignore 0 hashrate samples when setting miner status to 'warming up'
    [Parameter (Mandatory = $false)]
    [Switch]$IgnoreMinerFee = $false, # If true will ignore miner fee for earnings & profit calculation
    [Parameter (Mandatory = $false)]
    [Switch]$IgnorePoolFee = $false, # If true will ignore pool fee for earnings & profit calculation
    [Parameter (Mandatory = $false)]
    [Switch]$IgnorePowerCost = $false, # If true will ignore power cost in best miner selection, instead miners with best earnings will be selected
    [Parameter (Mandatory = $false)]
    [Int]$Interval = 90, # Average cycle loop duration (seconds), min 60, max 3600
    [Parameter (Mandatory = $false)]
    [Switch]$LegacyGUI = $true, # If true will start legacy GUI
    [Parameter (Mandatory = $false)]
    [Switch]$LegacyGUIStartMinimized = $false, # If true will start legacy GUI as minimized window
    [Parameter (Mandatory = $false)]
    [Switch]$LogBalanceAPIResponse = $false, # If true will log the pool balance API data
    [Parameter (Mandatory = $false)]
    [String[]]$LogLevel = @("Error", "Info", "Verbose", "Warn"), # Log level detail to be written to log file and screen, see Write-Message function; any of "Debug", "Error", "Info", "MemDbg", "Verbose", "Warn"
    [Parameter (Mandatory = $false)]
    [String]$LogViewerConfig = ".\Utils\UG-Miner_LogReader.xml", # Path to external log viewer config file
    [Parameter (Mandatory = $false)]
    [String]$LogViewerExe = ".\Utils\SnakeTail.exe", # Path to optional external log reader (SnakeTail) [https://github.com/snakefoot/snaketail-net], leave empty to disable
    [Parameter (Mandatory = $false)]
    [Double]$MinAccuracy = 0.5, # Use only pools with price accuracy greater than the configured value. Allowed values: 0.0 - 1.0 (0% - 100%)
    [Parameter (Mandatory = $false)]
    [Int]$MinCycle = 1, # Minimum number of cycles a miner must mine the same available algorithm@pool continously before switching is allowed (e.g. 3 would force a miner to stick mining algorithm@pool for min. 3 cycles before switching to another algorithm or pool)
    [Parameter (Mandatory = $false)]
    [Int]$MinDataSample = 20, # Minimum number of hashrate samples required to store hashrate
    [Parameter (Mandatory = $false)]
    [Double]$MinerSwitchingThreshold = 10, # Will not switch miners unless another miner has n% higher earnings / profit
    [Parameter (Mandatory = $false)]
    [Switch]$MinerUseBestPoolsOnly = $false, # If true it will use only the best pools for mining. Some miners / algorithms are incompatible with some pools. In this case the miner will not be available. This can impact profitability, but is less CPU heavy. This was the default algorithm for versions older than 5.x
    [Parameter (Mandatory = $false)]
    [String]$MinerWindowStyle = "minimized", # "minimized": miner window is minimized (default), but accessible; "normal": miner windows are shown normally; "hidden": miners will run as a hidden background task and are not accessible (not recommended)
    [Parameter (Mandatory = $false)]
    [Switch]$MinerWindowStyleNormalWhenBenchmarking = $true, # If true miner window is shown normal when benchmarking (recommended to better see miner messages)
    [Parameter (Mandatory = $false)]
    [String]$MiningDutchAPIKey = "", # MiningDutch API key (required to retrieve balance information)
    [Parameter (Mandatory = $false)]
    [String]$MiningDutchUserName = "UselessGuru", # MiningDutch username
    [Parameter (Mandatory = $false)]
    [String]$MiningPoolHubAPIKey = "", # MiningPoolHub API key (required to retrieve balance information)
    [Parameter (Mandatory = $false)]
    [String]$MiningPoolHubUserName = "UselessGuru", # MiningPoolHub username
    [Parameter (Mandatory = $false)]
    [Int]$MinWorker = 25, # Minimum workers mining the algorithm at the pool. If less miners are mining the algorithm then the pool will be disabled. This is also a per pool setting configurable in 'PoolsConfig.json'
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
    [Switch]$OpenFirewallPorts = $true, # If true will open firewall ports for all miners (requires admin rights!)
    [Parameter (Mandatory = $false)]
    [String]$PayoutCurrency = "BTC", # i.e. BTC, LTC, ZEC, ETH etc., default PayoutCurrency for all pools that have no other currency configured, PayoutCurrency is also a per pool setting (to be configured in 'PoolsConfig.json')
    [Parameter (Mandatory = $false)]
    [Switch]$PoolAllow0Hashrate = $false, # Allow mining to the pool even when there is 0 (or no) hashrate reported in the API (not recommended)
    [Parameter (Mandatory = $false)]
    [Switch]$PoolAllow0Price = $false, # Allow mining to the pool even when the price reported in the API is 0 (not recommended)
    [Parameter (Mandatory = $false)]
    [Int]$PoolAPIallowedFailureCount = 3, # Max number of pool API request attempts
    [Parameter (Mandatory = $false)]
    [Double]$PoolAllowedPriceIncreaseFactor = 5, # Max. allowed price increase compared with last price. If price increase is higher then the pool will be marked as unavaliable.
    [Parameter (Mandatory = $false)]
    [Int]$PoolAPIretryInterval = 3, # Time (in seconds) until pool API request retry. Note: Do not set this value too small to avoid temporary blocking by pool
    [Parameter (Mandatory = $false)]
    [Int]$PoolAPItimeout = 20, # Time (in seconds) until it aborts the pool request (useful if a pool's API is stuck). Note: do not set this value too small or UG-Miner will not be able to get any pool data
    [Parameter (Mandatory = $false)]
    [String]$PoolsConfigFile = ".\Config\PoolsConfig.json", # Pools configuration file name
    [Parameter (Mandatory = $false)]
    [String[]]$PoolName = @("HashCryptosPlus", "HiveON", "MiningDutchPlus", "NiceHash", "ZPoolPlus"), # Valid values are "HashCryptos", "HashCryptos24hr", "HashCryptosPlus", "HiveON", "MiningDutch", "MiningDutch24hr", "MiningDutchPlus", "NiceHash", "ZPool", "ZPool24hr", "ZPoolPlus"
    [Parameter (Mandatory = $false)]
    [Int]$PoolTimeout = 20, # Time (in seconds) until it aborts the pool request (useful if a pool's API is stuck). Note: do not set this value too small or UG-Miner will not be able to get any pool data
    [Parameter (Mandatory = $false)]
    [Hashtable]$PowerPricekWh = @{ "00:00" = 0.26; "12:00" = 0.3 }, # Price of power per kW⋅h (in $Currency, e.g. CHF), valid from HH:mm (24hr format)
    [Parameter (Mandatory = $false)]
    [Hashtable]$PowerConsumption = @{ }, # Static power consumption per device in watt, e.g. @{ "GPU#03" = 25, "GPU#04 = 55" } (in case HWiNFO cannot read power consumption)
    [Parameter (Mandatory = $false)]
    [Double]$PowerConsumptionIdleSystemW = 60, # Watt, power consumption of idle system. Part of profit calculation.
    [Parameter (Mandatory = $false)]
    [Double]$ProfitabilityThreshold = -99, # Minimum profit threshold, if profit is less than the configured value (in $Currency, e.g. CHF) mining will stop (except for benchmarking & power consumption measuring)
    [Parameter (Mandatory = $false)]
    [String]$Proxy = "", # i.e http://192.0.0.1:8080
    [Parameter (Mandatory = $false)]
    [UInt16]$RatesUpdateInterval = 15, # minutes, interval between exchange rates updates from min-api.cryptocompare.com
    [Parameter (Mandatory = $false)]
    [String]$Region = "Europe", # Used to determine pool nearest to you. One of "Australia", "Asia", "Brazil", "Canada", "Europe", "HongKong", "India", "Kazakhstan", "Russia", "USA East", "USA West"
    # [Parameter (Mandatory = $false)]
    # [Switch]$ReportToServer = $false, # If true will report worker status to central monitoring server
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnAccuracy = $false, # Show pool data accuracy column in main text window miner overview
    [Parameter (Mandatory = $false)]
    [Switch]$ShowAllMiners = $false, # Always show all miners in main text window miner overview (if false, only the best miners will be shown except when in benchmark / PowerConsumption measurement)
    [Parameter (Mandatory = $false)]
    [Switch]$ShowChangeLog = $true, # If true will show the changlog when an update is available
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnCoinName = $true, # Show CoinName column in main text window miner overview
    [Parameter (Mandatory = $false)]
    [Switch]$ShowConsole = $true, # If true will console window will be shown
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnCurrency = $true, # Show Currency column in main text window miner overview
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnEarnings = $true, # Show miner earnings column in main text window miner overview
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnEarningsBias = $true, # Show miner earnings bias column in main text window miner overview
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnHashrate = $true, # Show hashrate(s) column in main text window miner overview
    [Parameter (Mandatory = $false)]
    [Switch]$ShowColumnMinerFee = $true, # Show miner fee column in main text window miner overview (if fees are available, t.b.d. in miner files, property '[Double]Fee')
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
    [Switch]$SSLallowSelfSignedCertificate = $true, # If true will allow SSL/TLS connections with self signed certificates (this is a security issue)
    [Parameter (Mandatory = $false)]
    [String]$StartupMode = "Running", # One of 'Idle', 'Paused' or 'Running'. This is the same as the buttons in the legacy & web GUI
    [Parameter (Mandatory = $false)]
    [Boolean]$SubtractBadShares = $true, # If true will deduct bad shares when calculating effective hashrates
    [Parameter (Mandatory = $false)]
    [Int]$SyncWindow = 3, # Cycles. Pool prices must all be all have been collected within the last 'SyncWindow' cycles, otherwise the biased value of older poll price data will get reduced more the older the data is
    [Parameter (Mandatory = $false)]
    [Switch]$UseColorForMinerStatus = $true, # If true miners in web and legacy GUI will be shown with colored background depending on status
    [Parameter (Mandatory = $false)]
    [Switch]$UsemBTC = $true, # If true will display BTC values in milli BTC
    [Parameter (Mandatory = $false)]
    [Switch]$UseMinerTweaks = $false, # If true will apply miner specific tweaks, e.g mild overclock. This may improve profitability at the expense of system stability (Admin rights are required)
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
    [Switch]$UseUnprofitableAlgorithms = $false, # If true will also use unprofitable algorithms
    [Parameter (Mandatory = $false)]
    [Hashtable]$Wallets = @{ "BTC" = "1GPSq8txFnyrYdXL8t6S94mYdF8cGqVQJF" },
    [Parameter (Mandatory = $false)]
    [Switch]$Watchdog = $true, # If true will automatically put pools and/or miners temporarily on hold it they fail $WatchdogCount times in a row
    [Parameter (Mandatory = $false)]
    [Int]$WatchdogCount = 3, # Number of watchdog timers
    [Parameter (Mandatory = $false)]
    [Switch]$WebGUI = $true, # If true launch web GUI (recommended)
    [Parameter (Mandatory = $false)]
    [String]$WorkerName = [System.Net.Dns]::GetHostName() # Do not allow '.'
)

[ConsoleModeSettings]::DisableQuickEditMode()

Set-Location (Split-Path $MyInvocation.MyCommand.Path)

$ErrorLogFile = ".\Logs\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
$RecommendedPWSHversion = [Version]"7.5.4"

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

# Branding data
$Session.Branding = [PSCustomObject]@{ 
    BrandName    = "UG-Miner"
    BrandWebSite = "https://github.com/UselessGuru/UG-Miner"
    ProductLabel = "UG-Miner"
    Version      = [System.Version]"6.7.12"
}
$Session.ScriptStartTime = (Get-Process -Id $PID).StartTime.ToUniversalTime()

$host.UI.RawUI.WindowTitle = "$($Session.Branding.ProductLabel) $($Session.Branding.Version) - Runtime: {0:dd} days {0:hh} hrs {0:mm} mins - Path: $($Session.MainPath)" -f [TimeSpan]([DateTime]::Now.ToUniversalTime() - $Session.ScriptStartTime)

Write-Message -Level Info "Starting $($Session.Branding.ProductLabel)® v$($Session.Branding.Version) © 2017-$([DateTime]::Now.Year) UselessGuru..."

Write-Host ""
Write-Host "Checking PWSH version..." -ForegroundColor Yellow -NoNewline
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
$CursorPosition = $Host.UI.RawUI.CursorPosition

$Loops = 20
while (((Get-CimInstance CIM_Process).where({ $_.CommandLine -like "PWSH* -Command $($Session.MainPath)*.ps1 *" }).CommandLine).Count -gt 1) { 
    $Loops --
    [Console]::SetCursorPosition(0, $CursorPosition.y)
    Write-Host ""
    Write-Host "Waiting for another instance of $($Session.Branding.ProductLabel) to close... [-$Loops] " -ForegroundColor Yellow
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
    [Console]::SetCursorPosition(58, ($CursorPosition.y + 1))
    Write-Host " ✔    " -ForegroundColor Green
}
Remove-Variable Loops

# Convert command line parameters syntax
$Session.AllCommandLineParameters = [Ordered]@{ } # as case insensitive hash table
($MyInvocation.MyCommand.Parameters.psBase.Keys.where({ $_ -ne "ConfigFile" -and (Get-Variable $_ -ErrorAction Ignore) }) | Sort-Object).ForEach(
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
Initialize-Environment
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
    if (-not (Get-CimInstance CIM_Process).where({ $_.CommandLine -eq """$($Session.LogViewerExe)"" $($Session.LogViewerConfig)" })) { & $($Session.LogViewerExe) $($Session.LogViewerConfig) }
}

# Update config file to include all new config items
if (-not $Session.Config.ConfigFileVersion -or [System.Version]::Parse($Session.Config.ConfigFileVersion) -lt $Session.Branding.Version) { Update-ConfigFile -ConfigFile $Session.ConfigFile }

# Internet connection must be available
Write-Host ""
Write-Host "Checking internet connection..." -ForegroundColor Yellow -NoNewline
$NetworkInterface = (Get-NetConnectionProfile).where({ $_.IPv4Connectivity -eq "Internet" }).InterfaceIndex
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
if ([System.Environment]::OSVersion.Version -lt [System.Version]"10.0.0.0") { 
    [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
    Write-Host " ✖" -ForegroundColor Red
    Write-Message -Level Error "$($Session.Branding.ProductLabel) requires at least Windows 10. $($Session.Branding.ProductLabel) will shut down."
    (New-Object -ComObject Wscript.Shell).Popup("$($Session.Branding.ProductLabel) requires at least Windows 10.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
    exit
}
$Prerequisites = @(
    "$env:SystemRoot\System32\MSVCR120.dll",
    "$env:SystemRoot\System32\VCRUNTIME140.dll",
    "$env:SystemRoot\System32\VCRUNTIME140_1.dll"
)
if ($PrerequisitesMissing = $Prerequisites.where({ -not (Test-Path -LiteralPath $_ -PathType Leaf) })) { 
    [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
    Write-Host " ✖" -ForegroundColor Red
    $PrerequisitesMissing.ForEach({ Write-Message -Level Warn "'$_' is missing." })
    Write-Message -Level Error "Please install the required runtime modules. Download and extract"
    Write-Message -Level Error "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/Visual-C-Runtimes-All-in-One-Sep-2019/Visual-C-Runtimes-All-in-One-Sep-2019.zip"
    Write-Message -Level Error "and run 'install_all.bat' (Administrative privileges are required)."
    Write-Message -Level Error "$($Session.Branding.ProductLabel) will shut down."
    (New-Object -ComObject Wscript.Shell).Popup("Prerequisites missing.`nPlease install the required runtime modules.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
    exit
}
Remove-Variable Prerequisites, PrerequisitesMissing

if (-not (Get-Command Get-PnpDevice)) { 
    [Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
    Write-Host " ✖" -ForegroundColor Red
    Write-Message -Level Error "Windows Management Framework 5.1 is missing.`nPlease install the required runtime modules from https://www.microsoft.com/en-us/download/details.aspx?id=54616. $($Session.Branding.ProductLabel) will shut down."
    (New-Object -ComObject Wscript.Shell).Popup("Windows Management Framework 5.1 is missing.`nPlease install the required runtime modules.`n`n$($Session.Branding.ProductLabel) will shut down.`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
    exit
}
[Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
Write-Host " ✔" -ForegroundColor Green
Remove-Variable RecommendedPWSHversion

$Session.IsLocalAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")

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

Write-Message -Level Verbose "Importing modules..."
[Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.y)
try { 
    Add-Type -Path ".\Cache\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll" -ErrorAction Stop
    Write-Host "    (~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll" -ForegroundColor Green -NoNewline
}
catch { 
    if (Test-Path -LiteralPath ".\Cache\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll" -ErrorAction Ignore) { Remove-Item ".\Cache\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll" -Force }
    Add-Type -Path ".\Includes\OpenCL\*.cs" -OutputAssembly ".\Cache\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll"
    Add-Type -Path ".\Cache\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll"
    Write-Host "    (~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll" -ForegroundColor Green -NoNewline
}

try { 
    Add-Type -Path ".\Cache\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll" -ErrorAction Stop
    Write-Host ", ~CPUID_$($PSVersionTable.PSVersion.ToString()).dll" -ForegroundColor Green -NoNewline
}
catch { 
    if (Test-Path -LiteralPath ".\Cache\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll" -ErrorAction Ignore) { Remove-Item ".\Cache\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll" -Force }
    Add-Type -Path ".\Includes\CPUID.cs" -OutputAssembly ".\Cache\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll"
    Add-Type -Path ".\Cache\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll"
    Write-Host ", ~CPUID_$($PSVersionTable.PSVersion.ToString()).dll" -ForegroundColor Green -NoNewline
}

Import-Module NetSecurity -ErrorAction Ignore
Write-Host ", NetSecurity" -ForegroundColor Green -NoNewline
Import-Module Defender -ErrorAction Ignore -SkipEditionCheck
Write-Host ", Defender)" -ForegroundColor Green
[Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.y)
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

$Session.BrainData = @{ }
$Session.Brains = @{ }
$Session.CoreLoopCounter = [Int64]0
$Session.CoreCycleError = @()
$Session.CPUfeatures = (Get-CpuId).Features
$Session.CycleStarts = @()
$Session.Donation = [System.Collections.SortedList]::new([StringComparer]::OrdinalIgnoreCase)
$Session.MiningEarnings = $Session.MiningProfit = $Session.MiningPowerCost = [Double]::NaN
$Session.NewMiningStatus = if ($Session.Config.StartupMode -match "Paused|Running") { $Session.Config.StartupMode } else { "Idle" }
$Session.RestartCycle = $true
$Session.SuspendCycle = $false
$Session.WatchdogTimers = [System.Collections.Generic.List[PSCustomObject]]::new()

$Session.RegexAlgoIsEthash = "^Autolykos2$|^EtcHash$|^Ethash$|^EthashB3$|^EthashSHA256$|^UbqHash$|^Xhash$"
$Session.RegexAlgoIsProgPow = "^EvrProgPow$|^FiroPow$|^KawPow$|^MeowPow$|^PhiHash$|^ProgPow|^SCCpow$"
$Session.RegexAlgoHasDynamicDAG = "^Autolykos2$|^EtcHash$|^Ethash$|^EthashB3$|^EthashSHA256$|^EvrProgPow$|^FiroPow$|^KawPow$|^MeowPow$|^Octopus$|^PhiHash$|^ProgPow|^SCCpow$|^UbqHash$|^Xhash$"
$Session.RegexAlgoHasStaticDAG = "^FishHash$|^HeavyHashKarlsenV2$"
$Session.RegexAlgoHasDAG = (($Session.RegexAlgoHasDynamicDAG -split "\|") + ($Session.RegexAlgoHasStaticDAG -split "\|") | Sort-Object) -join "|"
[Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
Write-Host " ✔" -ForegroundColor Green

$Session.Summary = "Loading miner device information.<br>This may take a while..."
Write-Message -Level Verbose "$($Session.Summary)"

$Session.SupportedCPUDeviceVendors = @("AMD", "INTEL")
$Session.SupportedGPUDeviceVendors = @("AMD", "INTEL", "NVIDIA")

$Session.Devices = Get-Device

if ($Session.Devices.where({ $_.Type -eq "GPU" -and $_.Vendor -eq "AMD" }).OpenCL.DriverVersion -and (Get-Item -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Khronos\OpenCL\Vendors).Property -notlike "*\amdocl64.dll") { 
    Write-Message -Level Error "OpenCL driver installation for AMD GPU devices is incomplete"
    Write-Message -Level Error "Please create the missing registry key as described in https://github.com/ethereum-mining/ethminer/issues/2001#issuecomment-662288143. $($Session.Branding.ProductLabel) will shut down."
    (New-Object -ComObject Wscript.Shell).Popup("The OpenCL driver installation for AMD GPU devices is incomplete.`nPlease create the missing registry key as described here:`n`nhttps://github.com/ethereum-mining/ethminer/issues/2001#issuecomment-662288143`n`n$($Session.Branding.ProductLabel) will shut down.", 0, "Terminating error - cannot continue!", 4112) | Out-Null
    exit
}

$Session.Devices.where({ $_.Type -eq "CPU" -and $_.Vendor -notin $Session.SupportedCPUDeviceVendors }).ForEach({ $_.State = [DeviceState]::Unsupported; $_.Status = "Unavailable"; $_.StatusInfo = "Unsupported CPU vendor: '$($_.Vendor)'" })
$Session.Devices.where({ $_.Type -eq "GPU" -and $_.Vendor -notin $Session.SupportedGPUDeviceVendors }).ForEach({ $_.State = [DeviceState]::Unsupported; $_.Status = "Unavailable"; $_.StatusInfo = "Unsupported GPU vendor: '$($_.Vendor)'" })
$Session.Devices.where({ $_.State -ne [DeviceState]::Unsupported -and $_.Type -eq "GPU" -and -not ($_.CUDAversion -or $_.OpenCL.DriverVersion) }).ForEach({ $_.State = [DeviceState]::Unsupported; $_.Status = "Unavailable"; $_.StatusInfo = "Unsupported GPU model: '$($_.Model)'" })

$Session.Devices.where({ $Session.Config.ExcludeDeviceName -contains $_.Name -and $_.State -ne [DeviceState]::Unsupported }).ForEach({ $_.State = [DeviceState]::Disabled; $_.Status = "Idle"; $_.StatusInfo = "Disabled (ExcludeDeviceName: '$($_.Name)')" })

# Build driver version table
$Session.DriverVersion = [PSCustomObject]@{ }
if ($Session.Devices.CUDAversion) { $Session.DriverVersion | Add-Member "CUDA" ($Session.Devices.CUDAversion | Sort-Object -Top 1) }
$Session.DriverVersion | Add-Member "CIM" ([PSCustomObject]@{ })
$Session.DriverVersion.CIM | Add-Member "CPU" ([System.Version](($Session.Devices.where({ $_.Type -eq "CPU" }).CIM.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))
$Session.DriverVersion.CIM | Add-Member "AMD" ([System.Version](($Session.Devices.where({ $_.Type -eq "GPU" -and $_.Vendor -eq "AMD" }).CIM.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))
$Session.DriverVersion.CIM | Add-Member "NVIDIA" ([System.Version](($Session.Devices.where({ $_.Type -eq "GPU" -and $_.Vendor -eq "NVIDIA" }).CIM.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))
$Session.DriverVersion | Add-Member "OpenCL" ([PSCustomObject]@{ })
$Session.DriverVersion.OpenCL | Add-Member "CPU" ([System.Version](($Session.Devices.where({ $_.Type -eq "CPU" }).OpenCL.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))
$Session.DriverVersion.OpenCL | Add-Member "AMD" ([System.Version](($Session.Devices.where({ $_.Type -eq "GPU" -and $_.Vendor -eq "AMD" }).OpenCL.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))
$Session.DriverVersion.OpenCL | Add-Member "NVIDIA" ([System.Version](($Session.Devices.where({ $_.Type -eq "GPU" -and $_.Vendor -eq "NVIDIA" }).OpenCL.DriverVersion | Select-Object -First 1) -split " " | Select-Object -First 1))

[Console]::SetCursorPosition($Session.CursorPosition.X, $Session.CursorPosition.Y)
Write-Host " ✔  ($($Session.Devices.count) device$(if ($Session.Devices.count -ne 1) { "s" }) found" -ForegroundColor Green -NoNewline
if ($Session.Devices.where({ $_.State -eq [DeviceState]::Unsupported })) { Write-Host " [$($Session.Devices.where({ $_.State -eq [DeviceState]::Unsupported }).Count) unsupported device$(if ($Session.Devices.where({ $_.State -eq [DeviceState]::Unsupported }).Count -ne 1){ "s" })]" -ForegroundColor DarkYellow -NoNewline } 
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
    Write-Message -Level Warn "No valid API port; using port $(if ($Session.Devices.where({ $_.State -ne [DeviceState]::Unsupported }).Count -eq 1) { $Session.MinerBaseAPIport } else { "range $($Session.MinerBaseAPIport) - $(4000 + $Session.Devices.where({ $_.State -ne [DeviceState]::Unsupported }).Count - 1)" }) for miner communication."
}

function MainLoop { 

    if ($Session.MinersRunning) { 
        # Set process priority to BelowNormal to avoid hashrate drops on systems with weak CPUs
        (Get-Process -Id $PID).PriorityClass = "BelowNormal"
    }
    else { 
        (Get-Process -Id $PID).PriorityClass = "Normal"
    }

    if ($Session.NewMiningStatus -ne "Idle") { 
        # Start balances tracker
        if ($Session.Config.BalancesTrackerPollInterval -gt 0) { Start-BalancesTracker } else { Stop-BalancesTracker }

        # Check internet connection every 10 minutes
        if ($Session.NetworkChecked -lt [DateTime]::Now.ToUniversalTime().AddMinutes(-10)) { 
            $NetworkInterface = (Get-NetConnectionProfile).where({ $_.IPv4Connectivity -eq "Internet" }).InterfaceIndex
            $Session.MyIPaddress = if ($NetworkInterface) { (Get-NetIPAddress -InterfaceIndex $NetworkInterface -AddressFamily IPV4).IPAddress } else { $null }
            Remove-Variable NetworkInterface
            if ($Session.MyIPaddress) { $Session.NetworkChecked = [DateTime]::Now.ToUniversalTime() }
        }

        if ($Session.MyIPaddress) { 
            # Read exchange rates at least every 30 minutes
            if ((Compare-Object $Session.AllCurrencies $Session.BalancesCurrencies).where({ $_.SideIndicator -eq "=>"}) -or $Session.RatesUpdated -lt [DateTime]::Now.ToUniversalTime().AddMinutes(-((30, $Session.Config.RatesUpdateInterval) | Measure-Object -Minimum).Minimum)) { Get-Rate }
        }
        Else { 
            Write-Message -Level Error "No internet connection - will retry in $($Session.Config.Interval) seconds..."
            Start-Sleep -Seconds $Session.Config.Interval
        }
    }

    # If something (pause button, idle timer, WebGUI/config) has set the RestartCycle flag, stop and start mining to switch modes immediately
    if ($Session.RestartCycle -or ($LegacyGUIform -and -not $LegacyGUIelements.MiningSummaryLabel.Text)) { 
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

            Stop-Brain @($Session.Brains.Keys.where({ $_ -notin (Get-PoolBaseName $Session.Config.PoolName) }))

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
                        $Message += " Click the 'Start mining' button to make money."
                        $Session.Summary = $Message
                        Remove-Variable Message
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
                    }

                    $LegacyGUIelements.ButtonStart.Enabled = $true
                    $LegacyGUIelements.ButtonStop.Enabled = $true

                    Write-Host ""
                    $Message = "$($Session.Branding.ProductLabel) is paused."
                    Write-Message -Level Info $Message
                    $Message += " Click the 'Start mining' button to make money.<br>"
                    ((@(if ($Session.Config.UsemBTC) { "mBTC" } else { ($Session.Config.PayoutCurrency) }) + @($Session.Config.ExtraCurrencies)) | Select-Object -Unique).where({ $Session.Rates.$_.($Session.Config.FIATcurrency) }).ForEach(
                        { 
                            $Message += "1 $_ = {0:N$(Get-DecimalsFromValue -Value $Session.Rates.$_.($Session.Config.FIATcurrency) -DecimalsMax $Session.Config.DecimalsMax)} $($Session.Config.FIATcurrency)&ensp;&ensp;&ensp;" -f $Session.Rates.$_.($Session.Config.FIATcurrency)
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
                        $Message += " Mining processes are starting..."
                        $Session.Summary = $Message
                        Remove-Variable Message
                        Update-GUIstatus
                    }

                    Start-Brain @(Get-PoolBaseName $Session.Config.PoolName)
                    Start-CoreCycle $Session.Config.IdleDetection
                    if ($Session.Config.BalancesTrackerPollInterval -gt 0) { Start-BalancesTracker } else { Stop-BalancesTracker }

                    $LegacyGUIelements.ButtonPause.Enabled = $true
                    $LegacyGUIelements.ButtonStop.Enabled = $true
                    if (-not $Session.MiningStatus) { $host.UI.RawUI.FlushInputBuffer() }
                    break
                }
            }
            Update-GUIstatus
            $Session.MiningStatus = $Session.NewMiningStatus
        }
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
                        if ([DateTime]::Now.ToUniversalTime() -gt $Session.EndCycleTime) { $Session.EndCycleTime = [DateTime]::Now.ToUniversalTime() }
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
                        $Session.Config.ShowPoolBalances = -not $Session.Config.ShowPoolBalances
                        Write-Host "`nKey '$_' pressed: Listing pool balances is now " -NoNewline; if ($Session.Config.ShowPoolBalances) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                        break
                    }
                    "2" { 
                        $Session.Config.ShowAllMiners = -not $Session.Config.ShowAllMiners
                        Write-Host "`nKey '$_' pressed: Listing all optimal miners is now " -NoNewline; if ($Session.Config.ShowAllMiners) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                        break
                    }
                    "3" { 
                        $Session.Config.UIstyle = if ($Session.Config.UIstyle -eq "light") { "full" } else { "light" }
                        Write-Host "`nKey '$_' pressed: UI style is now " -NoNewline; Write-Host "$($Session.Config.UIstyle)" -ForegroundColor Blue -NoNewline; Write-Host " (Information about miners run in the past 24hrs, failed miners in the past 24hrs & watchdog timers will " -NoNewline; if ($Session.Config.UIstyle -eq "light") { Write-Host "not " -ForegroundColor Red -NoNewline }; Write-Host "be shown)"
                        break
                    }
                    "4" { 
                        $Session.Config.LegacyGUI = -not $Session.Config.LegacyGUI
                        Write-Host "`nKey '$_' pressed: Legacy GUI is now " -NoNewline; if ($Session.Config.LegacyGUI) { Write-Host "enabled" -ForegroundColor Green } else { Write-Host "disabled" -ForegroundColor DarkYellow }
                        if ($LegacyGUIform.ShowInTaskbar -ne $Session.Config.LegacyGUI) { 
                            if ($Session.Config.LegacyGUI) { 
                                $LegacyGUIform.WindowState = $Session.WindowStateOriginal
                            }
                            elseif ($LegacyGUIform.WindowState -ne [System.Windows.Forms.FormWindowState]::Minimized) { 
                                $Session.WindowStateOriginal = $LegacyGUIform.WindowState
                                $LegacyGUIform.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
                            }
                            $LegacyGUIform.ShowInTaskbar = $Session.Config.LegacyGUI
                        }
                    }
                    "5" { 
                        $Session.Config.WebGUI = -not $Session.Config.WebGUI
                        $CursorPosition = $Host.UI.RawUI.CursorPosition
                        Write-Host "`nKey '$_' pressed"
                        if ($Session.Config.WebGUI) { Start-APIserver } else { Stop-APIserver }
                        [Console]::SetCursorPosition($CursorPosition.X, $CursorPosition.y)
                        Write-Host "`nKey '$_' pressed: API and web GUI server is " -NoNewline; if ($Session.APIport) { Write-Host "running on port $($Session.APIport)" -ForegroundColor Green } else { Write-Host "stopped" -ForegroundColor DarkYellow }
                        [Console]::SetCursorPosition(0, ($Session.CursorPosition.Y + 1))
                        Remove-Variable CursorPosition
                        break
                    }
                    "a" { 
                        $Session.Config.ShowColumnAccuracy = -not $Session.Config.ShowColumnAccuracy
                        Write-Host "`nKey '$_' pressed: '" -NoNewline; Write-Host "A" -ForegroundColor Cyan -NoNewline; Write-Host "ccuracy' column visibility is now " -NoNewline; if ($Session.Config.ShowColumnAccuracy) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                        break
                    }
                    "b" { 
                        $Session.Config.ShowColumnEarningsBias = -not $Session.Config.ShowColumnEarningsBias
                        Write-Host "`nKey '$_' pressed: 'Earnings " -NoNewline; Write-Host "b" -ForegroundColor Cyan -NoNewline; Write-Host "ias' column visibility is now " -NoNewline; if ($Session.Config.ShowColumnEarningsBias) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                        break
                    }
                    "c" { 
                        $Session.Config.ShowColumnCurrency = -not $Session.Config.ShowColumnCurrency
                        Write-Host "`nKey '$_' pressed: '" -NoNewline; Write-Host "C" -ForegroundColor Cyan -NoNewline; Write-Host "urrency' column visibility is now " -NoNewline; if ($Session.Config.ShowColumnCurrency) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                        break
                    }
                    "e" { 
                        $Session.Config.ShowColumnEarnings = -not $Session.Config.ShowColumnEarnings
                        Write-Host "`nKey '$_' pressed: '" -NoNewline; Write-Host "E" -ForegroundColor Cyan -NoNewline; Write-Host "arnings' column visibility is now " -NoNewline; if ($Session.Config.ShowColumnEarnings) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                        break
                    }
                    "h" { 
                        Write-Host "`nHot key legend:                              Status:"
                        Write-Host "1: Toggle listing pool balances              [" -NoNewline; if ($Session.Config.ShowPoolBalances) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                        Write-Host "2: Toggle listing all optimal miners         [" -NoNewline; if ($Session.Config.ShowAllMiners) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                        Write-Host "3: Toggle UI style [full or light]           [" -NoNewline; Write-Host "$($Session.Config.UIstyle)" -ForegroundColor Blue -NoNewline; Write-Host "]"
                        Write-Host "4: Toggle legacy GUI                         [" -NoNewline; if ($Session.Config.LegacyGUI) { Write-Host "enabled" -ForegroundColor Green -NoNewline } else { Write-Host "disabled" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                        Write-Host "5: Toggle API server and web GUI             [" -NoNewline; if ($Session.APIport) { Write-Host "running on port $($Session.APIport)" -ForegroundColor Green -NoNewline } elseif ($Session.Config.APIport -and $Session.Config.WebGUI -and -not $Session.APIport) { Write-Host "error" -ForegroundColor Red -NoNewline } else { Write-Host "disabled" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                        Write-Host
                        Write-Host "a: Toggle '" -NoNewline; Write-Host "A" -ForegroundColor Cyan -NoNewline; Write-Host "ccuracy' column visibility       [" -NoNewline; if ($Session.Config.ShowColumnAccuracy) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                        Write-Host "b: Toggle 'Earnings " -NoNewline; Write-Host "b" -ForegroundColor Cyan -NoNewline; Write-Host "ias' column visibility  [" -NoNewline; if ($Session.Config.ShowColumnEarningsBias) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                        Write-Host "c: Toggle '" -NoNewline; Write-Host "C" -ForegroundColor Cyan -NoNewline; Write-Host "urrency' column visibility       [" -NoNewline; if ($Session.Config.ShowColumnCurrency) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                        Write-Host "e: Toggle '" -NoNewline; Write-Host "E" -ForegroundColor Cyan -NoNewline; Write-Host "arnings' column visibility       [" -NoNewline; if ($Session.Config.ShowColumnEarnings) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                        Write-Host "m: Toggle '" -NoNewline; Write-Host "M" -ForegroundColor Cyan -NoNewline; Write-Host "iner fee' column visibility      [" -NoNewline; if ($Session.Config.ShowColumnMinerFee) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                        Write-Host "n: Toggle 'Coin" -NoNewline; Write-Host "N" -ForegroundColor Cyan -NoNewline; Write-Host "ame' column visibility       [" -NoNewline; if ($Session.Config.ShowColumnCoinName) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                        if ($Session.CalculatePowerCost) { 
                            Write-Host "o: Toggle 'Power c" -NoNewline; Write-Host "o" -ForegroundColor Cyan -NoNewline; Write-Host "st' column visibility     [" -NoNewline; if ($Session.Config.ShowColumnPowerCost) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                        }
                        Write-Host "p: Toggle '" -NoNewline; Write-Host "P" -ForegroundColor Cyan -NoNewline; Write-Host "ool fee' column visibility       [" -NoNewline; if ($Session.Config.ShowColumnPoolFee) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                        if ($Session.CalculatePowerCost) { 
                            Write-Host "r: Toggle 'P" -NoNewline; Write-Host "r" -ForegroundColor Cyan -NoNewline; Write-Host "ofit bias' column visibility    [" -NoNewline; if ($Session.Config.ShowColumnProfitBias) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                        }
                        Write-Host "s: Toggle 'Ha" -NoNewline; Write-Host "s" -ForegroundColor Cyan -NoNewline; Write-Host "hrate(s)' column visibility    [" -NoNewline; if ($Session.Config.ShowColumnHashrate) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                        if ($Session.CalculatePowerCost) { 
                            Write-Host "t: Toggle 'Profi" -NoNewline; Write-Host "t" -ForegroundColor Cyan -NoNewline; Write-Host "' column visibility         [" -NoNewline; if ($Session.Config.ShowColumnProfit) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                        }
                        Write-Host "u: Toggle '" -NoNewline; Write-Host "U" -ForegroundColor Cyan -NoNewline; Write-Host "ser' column visibility           [" -NoNewline; if ($Session.Config.ShowColumnUser) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                        if ($Session.CalculatePowerCost) { 
                            Write-Host "w: Toggle 'Po" -NoNewline; Write-Host "w" -ForegroundColor Cyan -NoNewline; Write-Host "er (W)' column visibility      [" -NoNewline; if ($Session.Config.CalculatePowerCost -and $Session.Config.ShowColumnPowerConsumption) { Write-Host "on" -ForegroundColor Green -NoNewline } else { Write-Host "off" -ForegroundColor DarkYellow -NoNewline }; Write-Host "]"
                        }
                        Write-Host "`nq: " -NoNewline; Write-Host "Q" -ForegroundColor Blue -NoNewline; Write-Host "uit $($Session.Branding.ProductLabel)"
                        break
                    }
                    "m" { 
                        $Session.Config.ShowColumnMinerFee = -not $Session.Config.ShowColumnMinerFee
                        Write-Host "`nKey '$_' pressed: '" -NoNewline; Write-Host "M" -ForegroundColor Cyan -NoNewline; Write-Host "iner 'Fees' column visibility is now " -NoNewline; if ($Session.Config.ShowColumnMinerFee) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                        break
                    }
                    "n" { 
                        $Session.Config.ShowColumnCoinName = -not $Session.Config.ShowColumnCoinName
                        Write-Host "`nKey '$_' pressed: 'Coin" -NoNewline; Write-Host "N" -ForegroundColor Cyan -NoNewline; Write-Host "ame' column visibility is now " -NoNewline; if ($Session.Config.ShowColumnCoinName) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                        break
                    }
                    "o" { 
                        if ($Session.CalculatePowerCost) { 
                            $Session.Config.ShowColumnPowerCost = -not $Session.Config.ShowColumnPowerCost
                            Write-Host "`nKey '$_' pressed: 'Power c" -NoNewline; Write-Host "o" -ForegroundColor Cyan -NoNewline; Write-Host "st' column visibility is now " -NoNewline; if ($Session.Config.ShowColumnPowerCost) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                        }
                        break
                    }
                    "p" { 
                        $Session.Config.ShowColumnPoolFee = -not $Session.Config.ShowColumnPoolFee
                        Write-Host "`nKey '$_' pressed: '"-NoNewline; Write-Host "P" -ForegroundColor Cyan -NoNewline; Write-Host "ool fees' column visibility is now " -NoNewline; if ($Session.Config.ShowColumnPoolFee) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
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
                            $Session.Config.ShowColumnProfitBias = -not $Session.Config.ShowColumnProfitBias
                            Write-Host "`nKey '$_' pressed: 'P" -NoNewline; Write-Host "r" -ForegroundColor Cyan -NoNewline; Write-Host "ofit bias' column visibility is now " -NoNewline; if ($Session.Config.ShowColumnProfitBias) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                        }
                        break
                    }
                    "s" { 
                        $Session.Config.ShowColumnHashrate = -not $Session.Config.ShowColumnHashrate
                        Write-Host "`nKey '$_' pressed: 'Ha" -NoNewline; Write-Host "s" -ForegroundColor Cyan -NoNewline; Write-Host "hrates(s)' column visibility is now " -NoNewline; if ($Session.Config.ShowColumnHashrate) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                        break
                    }
                    "t" { 
                        if ($Session.CalculatePowerCost) { 
                            $Session.Config.ShowColumnProfit = -not $Session.Config.ShowColumnProfit
                            Write-Host "`nKey '$_' pressed: '" -NoNewline; Write-Host "P" -ForegroundColor Cyan -NoNewline; Write-Host "rofit' column visibility is now " -NoNewline; if ($Session.Config.ShowColumnProfit) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                        }
                        break
                    }
                    "u" { 
                        $Session.Config.ShowColumnUser = -not $Session.Config.ShowColumnUser
                        Write-Host "`nKey '$_' pressed: '" -NoNewline; Write-Host "U" -ForegroundColor Cyan -NoNewline; Write-Host "ser' column visibility is now " -NoNewline; if ($Session.Config.ShowColumnUser) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
                        break
                    }
                    "w" { 
                        if ($Session.CalculatePowerCost) { 
                            $Session.Config.ShowColumnPowerConsumption = -not $Session.Config.ShowColumnPowerConsumption
                            Write-Host "`nKey '$_' pressed: 'Po" -NoNewline; Write-Host "w" -ForegroundColor Cyan -NoNewline; Write-Host "er (W)' column visibility is now " -NoNewline; if ($Session.Config.ShowColumnPowerConsumption) { Write-Host "on" -ForegroundColor Green } else { Write-Host "off" -ForegroundColor DarkYellow }
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
                }
                Remove-Variable Message
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

    if ($LegacyGUIform.ShowInTaskbar -ne $Session.Config.LegacyGUI) { 
        if ($Session.Config.LegacyGUI) { 
            $LegacyGUIform.WindowState = $Session.WindowStateOriginal
        }
        elseif ($LegacyGUIform.WindowState -ne [System.Windows.Forms.FormWindowState]::Minimized) { 
            $Session.WindowStateOriginal = $LegacyGUIform.WindowState
            $LegacyGUIform.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
        }
        $LegacyGUIform.ShowInTaskbar = $Session.Config.LegacyGUI
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
            if ($Session.Config.ShowPoolBalances) { 
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
                if ($Session.MiningStatus -eq "Running" -and $Session.Miners.where({ $_.Available })) { 
                    # Miner list format
                    [System.Collections.ArrayList]$MinerTable = @(
                        @{ Label = "Miner"; Expression = { $_.Name } }
                        if ($Session.Config.ShowColumnMinerFee -and $Session.Miners.Workers.Fee) { @{ Label = "Miner fee"; Expression = { $_.Workers.ForEach({ "{0:P2}" -f [Double]$_.Fee }) }; Align = "right" } }
                        if ($Session.Config.ShowColumnEarningsBias) { @{ Label = "Earnings bias"; Expression = { if ([Double]::IsNaN($_.Earnings_Bias)) { "n/a" } else { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Earnings_Bias * $Session.Rates.BTC.($Session.Config.FIATcurrency)) } }; Align = "right" } }
                        if ($Session.Config.ShowColumnEarnings) { @{ Label = "Earnings"; Expression = { if ([Double]::IsNaN($_.Earnings)) { "n/a" } else { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Earnings * $Session.Rates.BTC.($Session.Config.FIATcurrency)) } }; Align = "right" } }
                        if ($Session.Config.ShowColumnPowerCost -and $Session.Config.CalculatePowerCost -and $Session.MiningPowerCost) { @{ Label = "Power cost"; Expression = { if ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } else { "-{0:n$($Session.Config.DecimalsMax)}" -f ($_.PowerCost * $Session.Rates.BTC.($Session.Config.FIATcurrency)) } }; Align = "right" } }
                        if ($Session.Config.ShowColumnProfitBias -and $Session.MiningPowerCost) { @{ Label = "Profit bias"; Expression = { if ([Double]::IsNaN($_.Profit_Bias)) { "n/a" } else { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Profit_Bias * $Session.Rates.BTC.($Session.Config.FIATcurrency)) } }; Align = "right" } }
                        if ($Session.Config.ShowColumnProfit -and $Session.MiningPowerCost) { @{ Label = "Profit"; Expression = { if ([Double]::IsNaN($_.Profit)) { "n/a" } else { "{0:n$($Session.Config.DecimalsMax)}" -f ($_.Profit * $Session.Rates.BTC.($Session.Config.FIATcurrency)) } }; Align = "right" } }
                        if ($Session.Config.ShowColumnPowerConsumption -and $Session.Config.CalculatePowerCost) { @{ Label = "Power (W)"; Expression = { if ($_.MeasurePowerConsumption) { if ($_.Status -eq "Running") { "Measuring..." } else { "Unmeasured" } } else { if ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } else { "$($_.PowerConsumption.ToString("N2"))" } } }; Align = "right" } }
                        if ($Session.Config.ShowColumnAccuracy) { @{ Label = "Accuracy"; Expression = { $_.Workers.ForEach({ "{0:P0}" -f [Double]$_.Pool.Accuracy }) }; Align = "right" } }
                        if ($Session.Config.ShowColumnPoolFee -and $Session.Miners.Workers.Pool.Fee) { @{ Label = "Pool fee"; Expression = { $_.Workers.ForEach({ "{0:P2}" -f [Double]$_.Pool.Fee }) }; Align = "right" } }
                        if ($Session.Config.ShowColumnHashrate) { @{ Label = "Hashrate"; Expression = { if ($_.Benchmark) { if ($_.Status -eq "Running") { "Benchmarking..." } else { "Benchmark pending" } } else { $_.Workers.ForEach({ $_.Hashrate | ConvertTo-Hash }) } }; Align = "right" } }
                        if ($Session.Config.ShowColumnUser) { @{ Label = "User"; Expression = { $_.Workers.Pool.User } } }
                        if ($Session.Config.ShowColumnCurrency) { @{ Label = "Currency"; Expression = { if ($_.Workers.Pool.Currency -match "\w") { $_.Workers.Pool.Currency } } } }
                        if ($Session.Config.ShowColumnCoinName) { @{ Label = "CoinName"; Expression = { if ($_.Workers.Pool.CoinName -match "\w" ) { $_.Workers.Pool.CoinName } } } }
                    )
                    # Display top 5 optimal miners and all benchmarking of power consumption measuring miners
                    $Bias = if ($Session.CalculatePowerCost -and -not $Session.Config.IgnorePowerCost) { "Profit_Bias" } else { "Earnings_Bias" }
                    ($Session.Miners.where({ $_.Optimal -or $_.Benchmark -or $_.MeasurePowerConsumption }) | Group-Object { $_.BaseName_Version_Device -replace ".+-" } | Sort-Object -Property Name).ForEach(
                        { 
                            $MinersDeviceGroup = $_.Group | Sort-Object { $_.Name, [String]$_.Algorithms } -Unique
                            $MinersDeviceGroupNeedingBenchmark = $MinersDeviceGroup.where({ $_.Available -and $_.Benchmark })
                            $MinersDeviceGroupNeedingPowerConsumptionMeasurement = $MinersDeviceGroup.where({ $_.Available -and $_.MeasurePowerConsumption })
                            $MinersDeviceGroup.where(
                                { 
                                    $Session.Config.ShowAllMiners -or <# List all miners #>
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
                        if ($Session.Config.ShowColumnPowerConsumption -and $Session.Config.CalculatePowerCost) { @{ Label = "Power (W)"; Expression = { if ([Double]::IsNaN($_.PowerConsumption_Live)) { "n/a" } else { "$($_.PowerConsumption_Live.ToString("N2"))" } }; Align = "right" } }
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

                if ($Session.Config.UIstyle -eq "full" -or $Session.MinersNeedingBenchmark -or $Session.MinersNeedingPowerConsumptionMeasurement) { 

                    [System.Collections.ArrayList]$MinersActivatedLast24Hrs = $Session.Miners.where({ $_.Activated -and $_.EndTime.ToLocalTime().AddHours(24) -gt [DateTime]::Now })

                    if ($ProcessesIdle = $MinersActivatedLast24Hrs.where({ $_.Status -eq "Idle" })) { 
                        Write-Host "$($ProcessesIdle.Count) previously executed miner$(if ($ProcessesIdle.Count -ne 1) { "s" }) (past 24 hrs):"
                        [System.Collections.ArrayList]$MinerTable = @(
                            @{ Label = "Name"; Expression = { $_.Name } }
                            if ($Session.Config.ShowColumnPowerConsumption -and $Session.Config.CalculatePowerCost) { @{ Label = "Power (W)"; Expression = { if ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } else { "$($_.PowerConsumption.ToString("N2"))" } }; Align = "right" } }
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

                    if ($ProcessesFailed = $MinersActivatedLast24Hrs.where({ $_.Status -eq "Failed" })) { 
                        Write-Host -ForegroundColor Red "$($ProcessesFailed.Count) failed miner$(if ($ProcessesFailed.Count -ne 1) { "s" }) (past 24 hrs):"
                        [System.Collections.ArrayList]$MinerTable = @(
                            @{ Label = "Name"; Expression = { $_.Name } }
                            if ($Session.Config.ShowColumnPowerConsumption -and $Session.Config.CalculatePowerCost) { @{ Label = "Power (W)"; Expression = { if ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } else { "$($_.PowerConsumption.ToString("N2"))" } }; Align = "right" } }
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
                        $Session.WatchdogTimers.where({ $_.Kicked -gt $Session.Timer.AddSeconds(-$Session.WatchdogReset) }) | Sort-Object -Property Kicked, @{ Expression = { $_.MinerBaseName_Version_Device -replace ".+-" } } | Format-Table -Wrap (
                            @{ Label = "Miner watchdog timer"; Expression = { $_.MinerName } },
                            @{ Label = "Pool"; Expression = { $_.PoolName } },
                            @{ Label = "Algorithm"; Expression = { $_.Algorithm } },
                            @{ Label = "Device(s)"; Expression = { $_.MinerBaseName_Version_Device -replace ".+-" } },
                            @{ Label = "Last updated"; Expression = { "{0:mm} min {0:ss} sec ago" -f ([DateTime]::Now.ToUniversalTime() - $_.Kicked) }; Align = "right" }
                        ) | Out-Host
                    }
                }

                if ($Session.MiningStatus -eq "Running" -and $Global:CoreCycleRunspace.Job.IsCompleted -eq $false) { 

                    if ($Session.Config.UIstyle -ne "full" -and $Session.MinersBenchmarkingOrMeasuring) { Write-Host -ForegroundColor DarkYellow "$(if ($Session.MinersNeedingBenchmark) { "Benchmarking" })$(if ($Session.MinersNeedingBenchmark -and $Session.MinersNeedingPowerConsumptionMeasurement) { " / " })$(if ($Session.MinersNeedingPowerConsumptionMeasurement) { "Measuring power consumption" }): Temporarily switched UI style to 'full'. (Information about miners run in the past, failed miners & watchdog timers will be shown)`n" }

                    $Colour = if ($Session.MinersRunning -and ($Session.MinersNeedingBenchmark -or $Session.MinersNeedingPowerConsumptionMeasurement)) { "DarkYello" } else { "White" }
                    Write-Host -ForegroundColor $Colour ($Session.Summary -replace "\.\.\.<br>", "... " -replace "<br>", " " -replace "\s*/\s*", "/" -replace "\s*=\s*", "=")
                    Remove-Variable Colour

                    if ($Session.Miners.where({ $_.Available -and -not ($_.Benchmark -or $_.MeasurePowerConsumption) })) { 
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

        $Error.Clear()
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()
    }
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
        # Always accept changed config when StartupMode is running
        Write-Message -Level Warn "Configuration has changed during update. Verify and save your configuration using the configuration editor (http://localhost:$($Session.Config.APIport)/configedit.html)"
        $Session.Summary = "Verify your settings and save the configuration.<br>Then click the 'Start mining' button."
        (New-Object -ComObject Wscript.Shell).Popup("The configuration has changed during update:`n`n$($Session.ConfigurationHasChangedDuringUpdate -join $nl)`n`nVerify and save the configuration using the configuration editor (http://localhost:$($Session.Config.APIport)/configedit.html).`n`n`Start making money by clicking 'Start mining'.`n`nHappy Mining!", 0, "$($Session.Branding.ProductLabel) v$($Session.Branding.Version) - configuration has changed", (4096 + 64)) | Out-Null
    }
}

Write-Host ""

. .\Includes\LegacyGUI.ps1
$LegacyGUIform.ShowInTaskbar = $Session.Config.LegacyGUI
$LegacyGUIform.ShowDialog() | Out-Null