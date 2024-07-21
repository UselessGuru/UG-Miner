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
File:           UG-Miner.ps1
Version:        6.2.19
Version date:   2024/07/21
#>

using module .\Includes\Include.psm1
using module .\Includes\APIServer.psm1

Param(
    [Parameter(Mandatory = $false)]
    [String[]]$Algorithm = @(), # i.e. @("Equihash1445", "Ethash", "KawPow") etc.
    [Parameter(Mandatory = $false)] 
    [String]$APILogfile = "", # API will log all requests to this file, leave empty to disable
    [Parameter(Mandatory = $false)]
    [Int]$APIPort = 3999, # TCP Port for API & Web GUI
    [Parameter(Mandatory = $false)]
    [Switch]$AutoReboot = $true, # If true will reboot computer when a miner is completely dead, e.g. unresponsive
    [Parameter(Mandatory = $false)]
    [Switch]$AutoUpdate = $true, # If true will automatically update to the new version
    [Parameter(Mandatory = $false)]
    [Int]$AutoUpdateCheckInterval = 1, # If true will periodically check for a new program version every n days (0 to disable)
    [Parameter(Mandatory = $false)]
    [Switch]$BackupOnAutoUpdate = $true, # If true will backup installed version before update to the new version
    [Parameter(Mandatory = $false)]
    [Double]$BadShareRatioThreshold = 0.05, # Allowed ratio of bad shares (total / bad) as reported by the miner. If the ratio exceeds the configured threshold then the miner will get marked as failed. Allowed values: 0.00 - 1.00. 0 disables this check
    [Parameter(Mandatory = $false)]
    [Boolean]$BalancesKeepAlive = $true, # If true will force mining at a pool to protect your earnings (some pools auto-purge the wallet after longer periods of inactivity, see '\Data\PoolData.Json' BalancesKeepAlive properties)
    [Parameter(Mandatory = $false)]
    [Boolean]$BalancesShowSums = $true, #Show 1hr / 6hrs / 24hr / 7day & 30day pool earning sums in web dashboard
    [Parameter(Mandatory = $false)]
    [Boolean]$BalancesShowAverages = $true, # Show 1hr / 24hr & 7day pool earning averages in web dashboard
    [Parameter(Mandatory = $false)]
    [Boolean]$BalancesShowInAllCurrencies = $true, # If true pool balances will be shown in all currencies in web dashboard
    [Parameter(Mandatory = $false)]
    [Boolean]$BalancesShowInMainCurrency = $true, # If true pool balances will be shown in main currency in web dashboard
    [Parameter(Mandatory = $false)]
    [String[]]$BalancesTrackerExcludePools = @(), # Balances tracker will not track these pools
    [Parameter(Mandatory = $false)]
    [Switch]$BalancesTrackerLog = $false, # If true will store all balance tracker data in .\Logs\EarningTrackerLog.csv
    [Parameter(Mandatory = $false)]
    [UInt16]$BalancesTrackerPollInterval = 5, # minutes, Interval duration to trigger background task to collect pool balances & earnings data; set to 0 to disable
    [Parameter(Mandatory = $false)]
    [Switch]$BenchmarkAllPoolAlgorithmCombinations,
    [Parameter(Mandatory = $false)]
    [Switch]$CalculatePowerCost = $true, # If true power consumption will be read from miners and calculate power cost, required for true profit calculation
    [Parameter(Mandatory = $false)]
    [String]$ConfigFile = ".\Config\Config.json", # Config file name
    [Parameter(Mandatory = $false)]
    [Int]$CPUMiningReserveCPUcore = 1, # Number of CPU cores reserved for main script processing. Helps to get more stable hashrates and faster core loop processing.
    [Parameter(Mandatory = $false)]
    [Int]$CPUMinerProcessPriority = "-2", # Process priority for CPU miners
    [Parameter(Mandatory = $false)]
    [String[]]$Currency = @(), # i.e. @("ETC", EVR", "KIIRO") etc.
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
    [Double]$EarningsAdjustmentFactor = 1, # Default factor with which multiplies the prices reported by ALL pools. Allowed values: 0.0 - 10.0
    [Parameter(Mandatory = $false)]
    [String[]]$ExcludeDeviceName = @(), # Array of disabled devices, e.g. @("CPU#00", "GPU#02"); by default all devices are enabled
    [Parameter(Mandatory = $false)]
    [String[]]$ExcludeMinerName = @(), # List of miners to be excluded; Either specify miner short name, e.g. "PhoenixMiner" (without '-v...') to exclude any version of the miner, or use the full miner name incl. version information
    [Parameter(Mandatory = $false)]
    [String[]]$ExtraCurrencies = @("ETC", "ETH", "mBTC"), # Extra currencies used in balances summary, Enter 'real-world' or crypto currencies, mBTC (milli BTC) is also allowed
    [Parameter(Mandatory = $false)]
    [Int]$GPUMinerProcessPriority = "-1", # Process priority for GPU miners
    [Parameter(Mandatory = $false)]
    [Switch]$IdleDetection = $false, # If true will start mining only if system is idle for $IdleSec seconds
    [Parameter(Mandatory = $false)]
    [Int]$IdleSec = 120, # seconds the system must be idle before mining starts (if IdleDetection)
    [Parameter(Mandatory = $false)]
    [Switch]$IgnoreMinerFee = $false, # If true will ignore miner fee for earning & profit calculation
    [Parameter(Mandatory = $false)]
    [Switch]$IgnorePoolFee = $false, # If true will ignore pool fee for earning & profit calculation
    [Parameter(Mandatory = $false)]
    [Switch]$IgnorePowerCost = $false, # If true ill ignore power cost in best miner selection, instead miners with best earnings will be selected
    [Parameter(Mandatory = $false)]
    [Int]$Interval = 90, # Average cycle loop duration (seconds), min 60, max 3600
    [Parameter(Mandatory = $false)]
    [Switch]$LegacyGUI = $false, # If true will start legacy GUI
    [Parameter(Mandatory = $false)]
    [Switch]$LegacyGUIStartMinimized = $true, # If true will start legacy GUI as minimized window
    [Parameter(Mandatory = $false)]
    [Switch]$LogBalanceAPIResponse = $false, # If true will log the pool balance API data
    [Parameter(Mandatory = $false)]
    [String[]]$LogToFile = @("Error", "Warn", "Info", "Verbose"), # Log level detail to be written to log file, see Write-Message function; any of @("Error", "Warn", "Info", "Verbose", "Debug")
    [Parameter(Mandatory = $false)]
    [String[]]$LogToScreen = @("Error", "Warn", "Info", "Verbose"), # Log level detail to be written to screen, see Write-Message function; any of @("Error", "Warn", "Info", "Verbose", "Debug")
    [Parameter(Mandatory = $false)]
    [String]$LogViewerConfig = ".\Utils\UG-Miner_LogReader.xml", # Path to external log viewer config file
    [Parameter(Mandatory = $false)]
    [String]$LogViewerExe = ".\Utils\SnakeTail.exe", # Path to optional external log reader (SnakeTail) [https://github.com/snakefoot/snaketail-net], leave empty to disable
    [Parameter(Mandatory = $false)]
    [String]$MainCurrency = (Get-Culture).NumberFormat.CurrencySymbol, # Default main 'real-money' currency, i.e. GBP, USD, AUD, NZD etc. Do not use crypto currencies
    [Parameter(Mandatory = $false)]
    [Double]$MinAccuracy = 0.5, # Use only pools with price accuracy greater than the configured value. Allowed values: 0.0 - 1.0 (0% - 100%)
    [Parameter(Mandatory = $false)]
    [Int]$MinCycle = 1, # Minimum number of full cycles a miner must mine the same available algorithm@pool continously before switching is allowed (e.g. 3 would force a miner to stick mining algorithm@pool for min. 3 cycles before switching to another algorithm or pool)
    [Parameter(Mandatory = $false)]
    [Int]$MinDataSample = 20, # Minimum number of hashrate samples required to store hashrate
    [Parameter(Mandatory = $false)]
    [Switch]$MinerInstancePerDeviceModel = $true, # If true will UG-Miner will create separate miner instances for each device model. This will increase profitability, but will take longer to select the best miner
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
    [Switch]$NiceHashWalletIsInternal = $false, # Set to $true if NiceHashWallet is a NiceHash internal wallet (lower pool fees)
    [Parameter(Mandatory = $false)]
    [String]$NiceHashWallet = "", # NiceHash wallet, if left empty $Wallets[BTC] is used
    [Parameter(Mandatory = $false)]
    [String]$NiceHashOrganizationId = "", # NiceHash Organization Id (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [Switch]$OpenFirewallPorts = $true, # If true will open firewall ports for all miners (requires admin rights!)
    [Parameter(Mandatory = $false)]
    [String]$PayoutCurrency = "BTC", # i.e. BTC, LTC, ZEC, ETH etc., Default PayoutCurrency for all pools that have no other currency configured, PayoutCurrency is also a per pool setting (to be configured in 'PoolsConfig.json')
    [Parameter(Mandatory = $false)]
    [Int]$PoolAPIAllowedFailureCount = 3, # Max number of pool API request attempts
    [Parameter(Mandatory = $false)]
    [Int]$PoolAPIRetryInterval = 3, # Time (in seconds) until pool API request retry. Note: Do not set this value too small to avoid temporary blocking by pool
    [Parameter(Mandatory = $false)]
    [Int]$PoolAPITimeout = 20, # Time (in seconds) until it aborts the pool request (useful if a pool's API is stuck). Note: do not set this value too small or NM will not be able to get any pool data
    [Parameter(Mandatory = $false)]
    [String]$PoolsConfigFile = ".\Config\PoolsConfig.json", # PoolsConfig file name
    [Parameter(Mandatory = $false)]
    [String[]]$PoolName = @("Hiveon", "MiningDutch", "NiceHash", "NLPool", "ProHashing", "ZergPoolCoins", "ZPool"), 
    [Parameter(Mandatory = $false)]
    [Int]$PoolTimeout = 20, # Time (in seconds) until it aborts the pool request (useful if a pool's API is stuck). Note: do not set this value too small or NM will not be able to get any pool data
    [Parameter(Mandatory = $false)]
    [Hashtable]$PowerPricekWh = @{ "00:00" = 0.26; "12:00" = 0.3 }, # Price of power per kW⋅h (in $Currency, e.g. CHF), valid from HH:mm (24hr format)
    [Parameter(Mandatory = $false)]
    [Hashtable]$PowerConsumption = @{ }, # Static power consumption per device in watt, e.g. @{ "GPU#03" = 25, "GPU#04 = 55" } (in case HWiNFO cannot read power consumption)
    [Parameter(Mandatory = $false)]
    [Double]$PowerConsumptionIdleSystemW = 60, # Watt, Power consumption of idle system. Part of profit calculation.
    [Parameter(Mandatory = $false)]
    [Double]$ProfitabilityThreshold = -99, # Minimum profit threshold, if profit is less than the configured value (in $Currency, e.g. CHF) mining will stop (except for benchmarking & power consumption measuring)
    [Parameter(Mandatory = $false)]
    [String]$ProHashingAPIKey = "", # ProHashing API Key (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [String]$ProHashingMiningMode = "PPS", # Either PPS (Pay Per Share) or PPLNS (Pay per Last N Shares)
    [Parameter(Mandatory = $false)]
    [String]$ProHashingUserName = "UselessGuru", # ProHashing UserName, if left empty then $UserName is used
    [Parameter(Mandatory = $false)]
    [String]$Proxy = "", # i.e http://192.0.0.1:8080
    [Parameter(Mandatory = $false)]
    [String]$Region = "Europe", # Used to determine pool nearest to you. One of "Asia", "Europe", "HongKong", "Japan", "Russia", "USA East", "USA West"
    [Parameter(Mandatory = $false)]
    [Switch]$ReportToServer = $false, # If true will report worker status to central monitoring server
    [Parameter(Mandatory = $false)]
    [Switch]$ShowAccuracy = $true, # Show pool data accuracy column in main text window miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowAllMiners = $false, # Always show all miners in main text window miner overview (if false, only the best miners will be shown except when in benchmark / PowerConsumption measurement)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowChangeLog = $true, # If true will show the changlog when an update is available
    [Parameter(Mandatory = $false)]
    [Switch]$ShowCoinName = $true, # Show CoinName column in main text window miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowConsole = $true, # If true will console window will be shown
    [Parameter(Mandatory = $false)]
    [Switch]$ShowCurrency = $true, # Show Currency column in main text window miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowEarning = $true, # Show miner earning column in main text window miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowEarningBias = $true, # Show miner earning bias column in main text window miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowMinerFee = $true, # Show miner fee column in main text window miner overview (if fees are available, t.b.d. in miner files, property '[Double]Fee')
    [Parameter(Mandatory = $false)]
    [Switch]$ShowPoolBalances = $false, # Display pool balances & earnings information in main text window, requires BalancesTrackerPollInterval -gt 0
    [Parameter(Mandatory = $false)]
    [Switch]$ShowPool = $true, # Show pool column in main text window miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowPoolFee = $true, # Show pool fee column in main text window miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowPowerCost = $true, # Show Power cost column in main text window miner overview (if power price is available, see PowerPricekWh)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowProfit = $true, # Show miner profit column in main text window miner overview (if power price is available, see PowerPricekWh)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowProfitBias = $true, # Show miner profit bias column in main text window miner overview (if power price is available, see PowerPricekWh)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowPowerConsumption = $true, # Show Power consumption column in main text window miner overview (if power price is available, see PowerPricekWh)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowShares = $true, # Show share data in log
    [Parameter(Mandatory = $false)]
    [Switch]$ShowUser = $false, # Show pool user name column in main text window miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowWorkerStatus = $true, # Show worker status from other rigs (data retrieved from monitoring server)
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
    [Switch]$Transcript = $false, # Enable to write PowerShell transcript files (for debugging)
    [Parameter(Mandatory = $false)]
    [Switch]$UseColorForMinerStatus = $true, # If true miners in web and legacy GUI will be shown with colored background depending on status
    [Parameter(Mandatory = $false)]
    [Switch]$UsemBTC = $true, # If true will display BTC values in milli BTC
    [Parameter(Mandatory = $false)]
    [Switch]$UseMinerTweaks = $false, # If true will apply miner specific tweaks, e.g mild overclock. This may improve profitability at the expense of system stability (Admin rights are required)
    [Parameter(Mandatory = $false)]
    [String]$UIStyle = "light", # light or full. Defines level of info displayed in main text window
    [Parameter(Mandatory = $false)]
    [Double]$UnrealPoolPriceFactor = 1.5, # Ignore pool if price is more than $Config.UnrealPoolPriceFactor higher than average price of all other pools with same algorithm & currency
    [Parameter(Mandatory = $false)]
    [Double]$UnrealMinerEarningFactor = 5, # Ignore miner if resulting profit is more than $Config.UnrealPoolPriceFactor higher than average price of all other miners with same algo
    [Parameter(Mandatory = $false)]
    [Switch]$UseAnycast = $true, # If true pools (currently ZergPool only) will use anycast for best network performance and ping times
    [Parameter(Mandatory = $false)]
    [Hashtable]$Wallets = @{ "BTC" = "1GPSq8txFnyrYdXL8t6S94mYdF8cGqVQJF" }, 
    [Parameter(Mandatory = $false)]
    [Switch]$Watchdog = $true, # if true will automatically put pools and/or miners temporarily on hold it they fail $WatchdogCount times in a row
    [Parameter(Mandatory = $false)]
    [Int]$WatchdogCount = 3, # Number of watchdog timers
    [Parameter(Mandatory = $false)]
    [Switch]$WebGUI = $true, # If true launch web GUI (recommended)
    [Parameter(Mandatory = $false)]
    [String]$WorkerName = [System.Net.Dns]::GetHostName()
)

Set-Location (Split-Path $MyInvocation.MyCommand.Path)

@"
UG-Miner
Copyright (c) 2018-$([DateTime]::Now.Year) UselessGuru
This is free software, and you are welcome to redistribute it under certain conditions.
https://github.com/UselessGuru/UG-Miner/blob/master/LICENSE
"@
Write-Host "`nCopyright and license notices must be preserved.`n" -ForegroundColor Yellow

# Initialize thread safe global variables
$Global:Config = [Hashtable]::Synchronized(@{ })
$Global:Stats = [Hashtable]::Synchronized(@{ })
$Global:Variables = [Hashtable]::Synchronized(@{ })

# Load Branding
$Variables.Branding = [PSCustomObject]@{ 
    BrandName    = "UG-Miner"
    BrandWebSite = "https://github.com/UselessGuru/UG-Miner"
    ProductLabel = "UG-Miner"
    Version      = [System.Version]"6.2.19"
}

$WscriptShell = New-Object -ComObject Wscript.Shell
$host.UI.RawUI.WindowTitle = "$($Variables.Branding.ProductLabel) $($Variables.Branding.Version)"

If ($PSVersiontable.PSVersion -lt [System.Version]"7.0.0") { 
    Write-Host "`nUnsupported PWSH version $($PSVersiontable.PSVersion.ToString()) detected.`n$($Variables.Branding.BrandName) requires at least PWSH version 7.0.0 (Recommended is 7.4.3) which can be downloaded from https://github.com/PowerShell/powershell/releases.`n`n" -ForegroundColor Red
    $WscriptShell.Popup("Unsupported PWSH version $($PSVersiontable.PSVersion.ToString()) detected.`n`n$($Variables.Branding.BrandName) requires at least PWSH version (Recommended is 7.4.3) which can be downloaded from https://github.com/PowerShell/powershell/releases.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
    Exit
}

# Internet connection must be available
If ($NetRoute = ((Get-NetRoute).Where({ $_.DestinationPrefix -eq "0.0.0.0/0" }) | Get-NetIPInterface).Where({ $_.ConnectionState -eq "Connected" })) { 
    $MyIP = ((Get-NetIPAddress -InterfaceIndex $NetRoute.ifIndex -AddressFamily IPV4).IPAddress)
}
If ($MyIP) { 
    $Variables.MyIP = $MyIP
}
Else { 
    $Variables.MyIP = $null
    Write-Host "Terminating Error - No internet connection." -ForegroundColor "Red"
    $WscriptShell.Popup("No internet connection", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
    Exit
}
Remove-Variable MyIp, NetRoute -ErrorAction Ignore

# Create directories
If (-not (Test-Path -LiteralPath ".\Cache" -PathType Container)) { New-Item -Path . -Name "Cache" -ItemType Directory | Out-Null }
If (-not (Test-Path -LiteralPath ".\Config" -PathType Container)) { New-Item -Path . -Name "Config" -ItemType Directory | Out-Null }
If (-not (Test-Path -LiteralPath ".\Logs" -PathType Container)) { New-Item -Path . -Name "Logs" -ItemType Directory | Out-Null }
If (-not (Test-Path -LiteralPath ".\Stats" -PathType Container)) { New-Item "Stats" -ItemType Directory -Force | Out-Null }

# Expand paths
$Variables.MainPath = (Split-Path $MyInvocation.MyCommand.Path)
$Variables.ConfigFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ConfigFile)
$Variables.PoolsConfigFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PoolsConfigFile)

$Variables.AllCommandLineParameters = [Ordered]@{ }
($MyInvocation.MyCommand.Parameters.psBase.Keys.Where({ $_ -ne "ConfigFile" -and (Get-Variable $_ -ErrorAction Ignore) }) | Sort-Object).ForEach(
    { 
        $Variables.AllCommandLineParameters.$_ = Get-Variable $_ -ValueOnly
        If ($MyInvocation.MyCommandLineParameters.$_ -is [Switch]) { $Variables.AllCommandLineParameters.$_ = [Boolean]$Variables.AllCommandLineParameters.$_ }
        Remove-Variable $_
    }
)

Write-Host "$($Variables.Branding.ProductLabel) is getting ready. Please wait..."

Write-Host "`nPreparing environment and loading data files..."
Initialize-Environment

# Read configuration
[Void](Read-Config -ConfigFile $Variables.ConfigFile)

Write-Message -Level Info "Starting $($Variables.Branding.ProductLabel)® v$($Variables.Branding.Version) © 2017-$([DateTime]::Now.Year) UselessGuru"
Write-Host ""

# Update config file to include all new config items
If (-not $Config.ConfigFileVersion -or [System.Version]::Parse($Config.ConfigFileVersion) -lt $Variables.Branding.Version) { 
    Update-ConfigFile -ConfigFile $Variables.ConfigFile
}

# Start transcript log
If ($Config.Transcript) { Start-Transcript -Path ".\Debug\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)-Transcript_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log" }

# Start Log reader (SnakeTail) [https://github.com/snakefoot/snaketail-net]
Start-LogReader

If (-not $Variables.FreshConfig) { Write-Message -Level Info "Using configuration file '$($Variables.ConfigFile)'." }
Write-Host ""

#Prerequisites check
Write-Message -Level Verbose "Verifying pre-requisites..."
$Prerequisites = @(
    "$env:SystemRoot\System32\MSVCR120.dll", 
    "$env:SystemRoot\System32\VCRUNTIME140.dll", 
    "$env:SystemRoot\System32\VCRUNTIME140_1.dll"
)

If ($PrerequisitesMissing = @($Prerequisites.Where({ -not (Test-Path -LiteralPath $_ -PathType Leaf) }))) { 
    $PrerequisitesMissing.ForEach({ Write-Message -Level Warn "$_ is missing." })
    Write-Message -Level Error "Please install the required runtime modules. Download and extract"
    Write-Message -Level Error "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/Visual-C-Runtimes-All-in-One-Sep-2019/Visual-C-Runtimes-All-in-One-Sep-2019.zip"
    Write-Message -Level Error "and run 'install_all.bat' (Admin rights are required)."
    $WscriptShell.Popup("Prerequisites missing.`nPlease install the required runtime modules.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
    Exit
}
Remove-Variable Prerequisites, PrerequisitesMissing

If ([System.Environment]::OSVersion.Version -lt [Version]"10.0.0.0" -and -not (Get-Command Get-PnpDevice)) { 
    Write-Message -Level Error "Windows Management Framework 5.1 is missing."
    Write-Message -Level Error "Please install the required runtime modules from https://www.microsoft.com/en-us/download/details.aspx?id=54616"
    $WscriptShell.Popup("Windows Management Framework 5.1 is missing.`nPlease install the required runtime modules.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
    Exit
}

Write-Message -Level Verbose "Pre-requisites verification OK."

# Check if new version is available
Get-Version

$Variables.VerthashDatPath = ".\Cache\VertHash.dat"
If (Test-Path -LiteralPath $Variables.VerthashDatPath -PathType Leaf) { 
    Write-Message -Level Verbose "Verifying integrity of VertHash data file '$($Variables.VerthashDatPath)'..."
}
$VertHashDatCheckJob = Start-ThreadJob -ScriptBlock { (Get-FileHash -Path ".\Cache\VertHash.dat").Hash -eq "A55531E843CD56B010114AAF6325B0D529ECF88F8AD47639B6EDEDAFD721AA48" } -StreamingHost $null -ThrottleLimit ((Get-CimInstance CIM_VideoController).Count + 1)

Write-Host "Importing modules..." -ForegroundColor Yellow
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

# Unblock files
If (Get-Item .\* -Stream Zone.*) { 
    Write-Host "Unblocking files that were downloaded from the internet..." -ForegroundColor Yellow
    If (Get-Command "Unblock-File" -ErrorAction Ignore) { Get-ChildItem -Path . -Recurse | Unblock-File }
    If ((Get-Command "Get-MpPreference") -and (Get-MpComputerStatus) -and (Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)) { 
        Start-Process "pwsh" "-Command Import-Module Defender; Add-MpPreference -ExclusionPath '$(Convert-Path .)'" -Verb runAs
    }
}

Write-Message -Level Verbose "Setting variables..."
$nl = "`n" # Must use variable, cannot join with '`n' with Write-Host

# Getting exchange rates
[Void](Get-Rate)

# Align CUDA id with nvidia-smi order
$env:CUDA_DEVICE_ORDER = 'PCI_BUS_ID'
# For AMD
$env:GPU_FORCE_64BIT_PTR = 1
$env:GPU_MAX_HEAP_SIZE = 100
$env:GPU_USE_SYNC_OBJECTS = 1
$env:GPU_MAX_ALLOC_PERCENT = 100
$env:GPU_SINGLE_ALLOC_PERCENT = 100
$env:GPU_MAX_WORKGROUP_SIZE = 256

$Variables.BrainData = @{ }
$Variables.Brains = @{ }
$Variables.IsLocalAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
$Variables.Miners = [Miner[]]@()
$Variables.MiningEarning = $Variables.MiningProfit = $Variables.MiningPowerCost = [Double]::NaN
$Variables.NewMiningStatus = If ($Config.StartupMode -match 'Paused|Running') { $Config.StartupMode } Else { "Idle" }
$Variables.RestartCycle = $true
$Variables.Pools = [Pool[]]@()
$Variables.ScriptStartTime = (Get-Process -id $PID).StartTime.ToUniversalTime()
$Variables.SuspendCycle = $false
$Variables.WatchdogTimers = [PSCustomObject[]]@()

$Variables.RegexAlgoIsEthash = "^Autolykos2|^Etc?hash|^FishHash|^UbqHash"
$Variables.RegexAlgoIsProgPow = "^EvrProgPow|^FiroPow.*|^KawPow|^MeowPow|^ProgPow"
$Variables.RegexAlgoHasDynamicDAG = "^Autolykos2|^Etc?hash|^EvrProgPow|^FiroPow*|^KawPow|^MeowPow|^Octopus|^ProgPow|^UbqHash"
$Variables.RegexAlgoHasStaticDAG = "^FishHash"
$Variables.RegexAlgoHasDAG = "$($Variables.RegexAlgoHasDynamicDAG)|$($Variables.RegexAlgoHasStaticDAG)"

$Variables.Summary = "Loading miner device information.<br>This may take a while..."
Write-Message -Level Verbose $Variables.Summary

$Variables.SupportedCPUDeviceVendors = @("AMD", "INTEL")
$Variables.SupportedGPUDeviceVendors = @("AMD", "INTEL", "NVIDIA")
$Variables.GPUArchitectureDbNvidia.PSObject.Properties.ForEach({ $_.Value.Model = $_.Value.Model -join '|' })
$Variables.GPUArchitectureDbAMD.PSObject.Properties.ForEach({ $_.Value = $_.Value -join '|' })

$Variables.Devices = Get-Device

$Variables.Devices.Where({ $_.Type -eq "CPU" -and $_.Vendor -notin $Variables.SupportedCPUDeviceVendors }).ForEach({ $_.State = [DeviceState]::Unsupported; $_.Status = "Unavailable"; $_.StatusInfo = "Unsupported CPU vendor: '$($_.Vendor)'" })
$Variables.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -notin $Variables.SupportedGPUDeviceVendors }).ForEach({ $_.State = [DeviceState]::Unsupported; $_.Status = "Unavailable"; $_.StatusInfo = "Unsupported GPU vendor: '$($_.Vendor)'" })
$Variables.Devices.Where({ $_.State -ne [DeviceState]::Unsupported -and $_.Type -eq "GPU" -and -not ($_.CUDAversion -or $_.OpenCL.DriverVersion) }).ForEach({ $_.State = [DeviceState]::Unsupported; $_.Status = "Unavailable"; $_.StatusInfo = "Unsupported GPU model: '$($_.Model)'" })

$Variables.Devices.Where({ $_.Name -in $Config.ExcludeDeviceName -and $_.State -ne [DeviceState]::Unsupported }).ForEach({ $_.State = [DeviceState]::Disabled; $_.Status = "Idle"; $_.StatusInfo = "Disabled (ExcludeDeviceName: '$($_.Name)')" })

If ($Variables.FreshConfig) { 
    # MinerInstancePerDeviceModel: Default to $true if more than one device model per vendor
    $Variables.MinerInstancePerDeviceModel = (($Variables.Devices.Where({ $_.State -eq [DeviceState]::Enabled }) | Group-Object Vendor).ForEach({ ($_.Group.Model | Sort-Object -Unique).Count }) | Measure-Object -Maximum).Maximum -gt 1
}

# Build driver version table
$Variables.DriverVersion = [PSCustomObject]@{ }
$Variables.DriverVersion | Add-Member "CIM" ([PSCustomObject]@{ })
$Variables.DriverVersion.CIM | Add-Member "CPU" ([Version](($Variables.Devices.Where({ $_.Type -eq "CPU" }).CIM.DriverVersion | Select-Object -First 1) -split ' ' | Select-Object -First 1))
$Variables.DriverVersion.CIM | Add-Member "AMD" ([Version](($Variables.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -eq "AMD" }).CIM.DriverVersion | Select-Object -First 1) -split ' ' | Select-Object -First 1))
$Variables.DriverVersion.CIM | Add-Member "NVIDIA" ([Version](($Variables.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -eq "NVIDIA" }).CIM.DriverVersion | Select-Object -First 1) -split ' ' | Select-Object -First 1))
$Variables.DriverVersion | Add-Member "OpenCL" ([PSCustomObject]@{ })
$Variables.DriverVersion.OpenCL | Add-Member "CPU" ([Version](($Variables.Devices.Where({ $_.Type -eq "CPU" }).OpenCL.DriverVersion | Select-Object -First 1) -split ' ' | Select-Object -First 1))
$Variables.DriverVersion.OpenCL | Add-Member "AMD" ([Version](($Variables.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -eq "AMD" }).OpenCL.DriverVersion | Select-Object -First 1) -split ' ' | Select-Object -First 1))
$Variables.DriverVersion.OpenCL | Add-Member "NVIDIA" ([Version](($Variables.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -eq "NVIDIA" }).OpenCL.DriverVersion | Select-Object -First 1) -split ' ' | Select-Object -First 1))

If ($Variables.DriverVersion.OpenCL.NVIDIA) { 
    $Variables.DriverVersion | Add-Member "CUDA" ([Version]($Variables.CUDAVersionTable.($Variables.CUDAVersionTable.Keys.Where({ $_ -le ([System.Version]$Variables.DriverVersion.OpenCL.NVIDIA).Major }) | Sort-Object -Bottom 1)))
    $Variables.Devices.Where({ $_.Type -eq "GPU" -and $_.Vendor -eq "NVIDIA" }).ForEach({ $_.CUDAVersion = [Version]$Variables.DriverVersion.CUDA })
}

# Driver version changed
If (([System.IO.File]::ReadAllLines("$PWD\Cache\DriverVersion.json") | ConvertFrom-Json | ConvertTo-Json -Compress) -ne ($Variables.DriverVersion | ConvertTo-Json -Compress)) { 
    If (Test-Path -LiteralPath ".\Cache\DriverVersion.json" -PathType Leaf) { Write-Message -Level Warn "Graphis card driver version data changed. It is recommended to re-benchmark all miners." }
    $Variables.DriverVersion | ConvertTo-Json | Out-File -LiteralPath ".\Cache\DriverVersion.json" -Force
}

# Rename existing switching log
If (Test-Path -LiteralPath ".\Logs\SwitchingLog.csv" -PathType Leaf) { Get-ChildItem -Path ".\Logs\SwitchingLog.csv" -File | Rename-Item -NewName { "SwitchingLog$($_.LastWriteTime.toString('_yyyy-MM-dd_HH-mm-ss')).csv" } }

If ($VertHashDatCheckJob | Wait-Job -Timeout 60 | Receive-Job -Wait -AutoRemoveJob) { 
    Write-Message -Level Verbose "VertHash data file integrity check: OK."
}
Else { 
    If (Test-Path -LiteralPath $Variables.VerthashDatPath -PathType Leaf -ErrorAction Ignore) { 
        Remove-Item -Path $Variables.VerthashDatPath -Force
        Write-Message -Level Warn "VertHash data file '$($Variables.VerthashDatPath)' is corrupt -> file deleted. It will be re-downloaded if needed."
    }
}
Remove-Variable VertHashDatCheckJob

# Start API server
If ($Config.WebGUI) { Start-APIServer }

Function MainLoop { 

    If ($Variables.NewMiningStatus -eq "Running") {
        If ($Config.IdleDetection) {
            Start-IdleDetection
            If ($Variables.IdleDetectionRunspace) { 
                If ($Variables.IdleDetectionRunspace.MiningStatus -eq "Suspended") { 
                    If ($Global:CoreRunspace) { 
                        Write-Message -Level Info "Ending cycle (System activity detected)."
                        Stop-Core
                        Write-Host "System activity detected. Mining is suspended."
                        $Variables.Summary = "Mining is suspended until system is idle for $($Config.IdleSec) second$(If ($Config.IdleSec -ne 1) { "s" })."
                        Write-Message -Level Verbose $Variables.Summary
                        If ($LegacyGUIform) { Update-GUIstatus }
                    }
                }
                If ($Variables.IdleDetectionRunspace.MiningStatus -eq "Running") {
                    If (-not $Global:CoreRunspace) { 
                        If ($Variables.Timer) { 
                            $Variables.Summary = "Resuming mining.<br>System has been idle for $($Config.IdleSec) second$(If ($Config.IdleSec -ne 1) { "s" })."
                            Write-Message -Level Verbose ($Variables.Summary -replace '<br>', ' ')
                            Write-Host ($Variables.Summary -replace '<br>', ' ')
                            $LegacyGUIminingSummaryLabel.Text = ($Variables.Summary -replace '<br>', ' ')
                        }
                        If ($LegacyGUIform) { Update-GUIstatus }
                        Start-Core
                    }
                }
            }
        }
        Else { 
            Stop-IdleDetection
            If (-not $Global:CoreRunspace) { Start-Core }
        }
    }

    # Core watchdog. Sometimes core loop gets stuck
    If (-not $Variables.SuspendCycle -and $Variables.MyIP -and $Variables.EndCycleTime -and $Variables.MiningStatus -eq "Running" -and $Global:CoreRunspace -and [DateTime]::Now.ToUniversalTime() -gt $Variables.EndCycleTime.AddSeconds(15 * $Config.Interval)) { 
        Write-Message -Level Warn "Core cycle is stuck - restarting..."
        Stop-Core
        $Variables.EndCycleTime = [DateTime]::Now.ToUniversalTime()
        $Variables.MiningStatus = $Variables.NewMiningStatus
        Start-Core
    }

    # If something (pause button, idle timer, WebGUI/config) has set the RestartCycle flag, stop and start mining to switch modes immediately
    If ($Variables.RestartCycle -or ($LegacyGUIform -and -not $LegacyGUIminingSummaryLabel.Text)) { 
        $Variables.RestartCycle = $false

        If ($Variables.NewMiningStatus -ne $Variables.MiningStatus -or ($Variables.PoolName -and (Compare-Object $Config.PoolName $Variables.PoolName))) { 

            # Keep only the last 10 files
            Get-ChildItem -Path ".\Logs\$($Variables.Branding.ProductLabel)_*.log" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse
            Get-ChildItem -Path ".\Logs\SwitchingLog_*.csv" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse
            Get-ChildItem -Path "$($Variables.ConfigFile)_*.backup" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse

            If ([Net.ServicePointManager]::SecurityProtocol -notmatch [Net.SecurityProtocolType]::Tls12) { [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12 }

            If ($Config.Proxy -eq "") { $PSDefaultParameterValues.Remove("*:Proxy") }
            Else { $PSDefaultParameterValues["*:Proxy"] = $Config.Proxy }

            # Set process priority to BelowNormal to avoid hashrate drops on systems with weak CPUs
            (Get-Process -Id $PID).PriorityClass = "BelowNormal"

            Switch ($Variables.NewMiningStatus) { 
                "Idle" { 
                    If ($Variables.MiningStatus) { 
                        $Variables.Summary = "'Stop Mining' button clicked."
                        Write-Host "`n"
                        Write-Message -Level Info $Variables.Summary

                        Stop-Core
                        Stop-IdleDetection
                        Stop-Brain
                        Stop-BalancesTracker
                        # If ($Config.ReportToServer) { Write-MonitoringData }

                        # Load currency exchange rates
                        [Void](Get-Rate)
                    }

                    If (-not $Variables.FreshConfig) { 
                        $Variables.Summary = "$($Variables.Branding.ProductLabel) is stopped.<br>Click the 'Start mining' button to make money."
                        Write-Host "`n"
                        Write-Message -Level Info ($Variables.Summary -replace '<br>', ' ')
                    }

                    Break
                }
                "Paused" { 
                    $Variables.Summary = "'Pause Mining' button clicked."
                    Write-Host "`n"
                    Write-Message -Level Info $Variables.Summary
                    # Allow up to 30 seconds for all miners to get stopped
                    $Counter = 30
                    While ($Counter -gt 30 -and $Variables.Miners.Where({ $_.Status -in @([MinerStatus]::DryRun, [MinerStatus]::Running) })) {
                        Start-Sleep -Seconds 1
                        $Counter --
                    }
                    Remove-Variable Counter

                    Stop-Core
                    Stop-IdleDetection
                    Stop-Brain @($Variables.Brains.psBase.Keys.Where({ $_ -notin (Get-PoolBaseName $Variables.PoolName) }))
                    Start-Brain @(Get-PoolBaseName $Variables.PoolName)
                    If ($Config.BalancesTrackerPollInterval -gt 0) { Start-BalancesTracker }
                    # If ($Config.ReportToServer) { Write-MonitoringData }

                    $Variables.Summary = "$($Variables.Branding.ProductLabel) is paused.<br>Click the 'Start mining' button to make money."
                    Write-Host "`n"
                    Write-Message -Level Info ($Variables.Summary -replace '<br>', ' ')
                    Break
                }
                "Running" { 
                    If ($Variables.MiningStatus -and $Variables.NewMiningStatus) { 
                        $Variables.Summary = "'Start Mining' button clicked."
                        Write-Host "`n"
                        Write-Message -Level Info $Variables.Summary
                    }
                    Start-Brain @(Get-PoolBaseName $Config.PoolName)
                    If (-not $Config.IdleDetection -and -not $Global:CoreRunspace) { Start-Core }
                    If ($Config.BalancesTrackerPollInterval -gt 0) { Start-BalancesTracker }
                    Break
                }
            }
            $Variables.MiningStatus = $Variables.NewMiningStatus
        }
        If ($LegacyGUIform) { Update-GUIstatus }
        If ($Config.BalancesTrackerPollInterval -gt 0 -and $Variables.NewMiningStatus -ne "Idle") { Start-BalancesTracker } Else { Stop-BalancesTracker }
    }

    If ($Config.ShowConsole) { 
        Show-Console
        If ($host.UI.RawUI.KeyAvailable) { 
            $KeyPressed = [System.Console]::ReadKey($true)
            Start-Sleep -Milliseconds 300
            $host.UI.RawUI.FlushInputBuffer()

            If ($KeyPressed.Key -eq "p" -and $KeyPressed.Modifiers -eq 5 <# <Alt><Crl>#>) { 
                If (-not $Global:CoreRunspace.AsyncObject.IsCompleted -eq $false) { 
                    # Core is complete / gone. Cycle cannot be suspended anymore
                    $Variables.SuspendCycle = $false
                } 
                Else { 
                    $Variables.SuspendCycle = -not $Variables.SuspendCycle
                    If ($Variables.SuspendCycle) { 
                        Write-Host "'<Ctrl><Alt>P' pressed. Core cycle is suspended until you press '<Ctrl><Alt>P' again." -ForegroundColor Cyan 
                    }
                    Else { 
                        Write-Host "'<Ctrl><Alt>P' pressed. Core cycle is running again." -ForegroundColor Cyan 
                        If ([DateTime]::Now.ToUniversalTime() -gt $Variables.EndCycleTime) { $Variables.EndCycleTime = [DateTime]::Now.ToUniversalTime() }
                    }
                }
            }
            Else { 
                Switch ($KeyPressed.KeyChar) { 
                    "1" { 
                        $Variables.ShowPoolBalances = -not $Variables.ShowPoolBalances
                        Write-Host "`nListing Pool Balances set to " -NoNewline; If ($Variables.ShowPoolBalances) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "."
                        Start-Sleep -Seconds 2
                        $Variables.RefreshNeeded = $true
                        Break
                    }
                    "2" { 
                        $Variables.ShowAllMiners = -not $Variables.ShowAllMiners
                        Write-Host "`nListing all optimal miners set to " -NoNewline; If ($Variables.ShowAllMiners) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "."
                        Start-Sleep -Seconds 2
                        $Variables.RefreshNeeded = $true
                        Break
                    }
                    "3" { 
                        $Variables.UIStyle = If ($Variables.UIStyle -eq "light") { "full" } Else { "light" }
                        Write-Host "`nUI style set to " -NoNewline; Write-Host "$($Variables.UIStyle)" -ForegroundColor Blue -NoNewline; Write-Host " (Information about miners run in the past 24hrs, failed miners in the past 24hrs & watchdog timers will " -NoNewline; If ($Variables.UIStyle -eq "light") { Write-Host "not " -ForegroundColor Red -NoNewline }; Write-Host "be shown)."
                        Start-Sleep -Seconds 2
                        $Variables.RefreshNeeded = $true
                        Break
                    }
                    "a" { 
                        $Variables.ShowAccuracy = -not $Variables.ShowAccuracy
                        Write-Host "`n'" -NoNewline; Write-Host "A" -ForegroundColor Cyan -NoNewline; Write-Host "ccuracy' column visibility set to " -NoNewline; If ($Variables.ShowAccuracy) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "."
                        Start-Sleep -Seconds 2
                        $Variables.RefreshNeeded = $true
                        Break
                    }
                    "c" { 
                        If ($Variables.CalculatePowerCost) { 
                            $Variables.ShowPowerCost = -not $Variables.ShowPowerCost
                            Write-Host "`n'Power " -NoNewline; Write-Host "C" -ForegroundColor Cyan -NoNewline; Write-Host "ost' column visibility set to " -NoNewline; If ($Variables.ShowPowerCost) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "."
                            Start-Sleep -Seconds 2
                            $Variables.RefreshNeeded = $true
                        }
                        Break
                    }
                    "e" { 
                        $Variables.ShowEarning = -not $Variables.ShowEarning
                        Write-Host "`n'" -NoNewline; Write-Host "E" -ForegroundColor Cyan -NoNewline; Write-Host "arnings' column visibility set to " -NoNewline; If ($Variables.ShowEarning) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "."
                        Start-Sleep -Seconds 2
                        $Variables.RefreshNeeded = $true
                        Break
                    }
                    "f" { 
                        $Variables.ShowPoolFee = -not $Variables.ShowPoolFee
                        Write-Host "`n'Pool "-NoNewline; Write-Host "F" -ForegroundColor Cyan -NoNewline; Write-Host "ees' column visibility set to " -NoNewline; If ($Variables.ShowPoolFee) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "."
                        Start-Sleep -Seconds 2
                        $Variables.RefreshNeeded = $true
                        Break
                    }
                    "h" { 
                        Write-Host "`nHot key legend:"
                        Write-Host "1: Toggle Listing pool balances (currently " -NoNewline; If ($Variables.ShowPoolBalances) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host ")"
                        Write-Host "2: Toggle Listing all optimal miners (currently " -NoNewline; If ($Variables.ShowAllMiners) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host ")"
                        Write-Host "3: Toggle UI style [full or light] (currently " -NoNewline; Write-Host "$($Variables.UIStyle)" -ForegroundColor Blue -NoNewline; Write-Host ")"
                        Write-Host
                        Write-Host "a: Toggle '" -NoNewline; Write-Host "A" -ForegroundColor Cyan -NoNewline; Write-Host "ccuracy' column visibility (currently " -NoNewline; If ($Variables.ShowAccuracy) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host ")"
                        If ($Variables.CalculatePowerCost) { 
                            Write-Host "c: Toggle 'Power" -NoNewline; Write-Host "C" -ForegroundColor Cyan -NoNewline; Write-Host "ost' column visibility (currently " -NoNewline; If ($Variables.ShowPowerCost) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host ")"
                        }
                        Write-Host "e: Toggle '" -NoNewline; Write-Host "E" -ForegroundColor Cyan -NoNewline; Write-Host "arnings' column visibility (currently " -NoNewline; If ($Variables.ShowEarning) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host ")"
                        Write-Host "f: Toggle Pool '" -NoNewline; Write-Host "F" -ForegroundColor Cyan -NoNewline; Write-Host "ees' column visibility (currently " -NoNewline; If ($Variables.ShowPoolFee) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host ")"
                        Write-Host "i: Toggle 'EarningB" -NoNewline; Write-Host "i" -ForegroundColor Cyan -NoNewline; Write-Host "as' column visibility (currently " -NoNewline; If ($Variables.ShowEarningBias) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host ")"
                        Write-Host "m: Toggle " -NoNewline; Write-Host "M" -ForegroundColor Cyan -NoNewline; Write-Host "iner 'Fees' column visibility (currently " -NoNewline; If ($Variables.ShowMinerFee) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host ")"
                        Write-Host "n: Toggle 'Coin" -NoNewline; Write-Host "N" -ForegroundColor Cyan -NoNewline; Write-Host "ame' column visibility (currently " -NoNewline; If ($Variables.ShowCoinName) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host ")"
                        Write-Host "p: Toggle '" -NoNewline; Write-Host "P" -ForegroundColor Cyan -NoNewline; Write-Host "ool' column visibility (currently " -NoNewline; If ($Variables.ShowPool) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host ")"
                        If ($Variables.CalculatePowerCost) { 
                            Write-Host "r: Toggle 'P" -NoNewline; Write-Host "r" -ForegroundColor Cyan -NoNewline; Write-Host "ofitBias' column visibility (currently " -NoNewline; If ($Variables.ShowProfitBias) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host ")"
                        }
                        If ($Variables.CalculatePowerCost) { 
                            Write-Host "t: Toggle 'Profi" -NoNewline; Write-Host "t" -ForegroundColor Cyan -NoNewline; Write-Host "' column visibility (currently " -NoNewline; If ($Variables.ShowProfit) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host ")"
                        }
                        Write-Host "u: Toggle '" -NoNewline; Write-Host "U" -ForegroundColor Cyan -NoNewline; Write-Host "ser' column visibility (currently " -NoNewline; If ($Variables.ShowUser) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host ")"
                        If ($Variables.CalculatePowerCost) { 
                            Write-Host "w: Toggle 'Po" -NoNewline; Write-Host "w" -ForegroundColor Cyan -NoNewline; Write-Host "erConsumption' column visibility (currently " -NoNewline; If ($Config.CalculatePowerCost -and $Variables.ShowPowerConsumption) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host ")"
                        }
                        Write-Host "y: Toggle 'Currenc" -NoNewline; Write-Host "y" -ForegroundColor Cyan -NoNewline; Write-Host "' column visibility (currently " -NoNewline; If ($Variables.ShowCurrency) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host ")"
                        Break
                    }
                    "i" { 
                        $Variables.ShowEarningBias = -not $Variables.ShowEarningBias
                        Write-Host "`n'EarningB" -NoNewline; Write-Host "i" -ForegroundColor Cyan -NoNewline; Write-Host "as' column visibility set to " -NoNewline; If ($Variables.ShowEarningBias) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "."
                        Start-Sleep -Seconds 2
                        $Variables.RefreshNeeded = $true
                        Break
                    }
                    "m" { 
                        $Variables.ShowMinerFee = -not $Variables.ShowMinerFee
                        Write-Host "`nM" -ForegroundColor Cyan -NoNewline; Write-Host "iner 'Fees' column visibility set to " -NoNewline; If ($Variables.ShowMinerFee) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "."
                        Start-Sleep -Seconds 2
                        $Variables.RefreshNeeded = $true
                        Break
                    }
                    "n" { 
                        $Variables.ShowCoinName = -not $Variables.ShowCoinName
                        Write-Host "`n'Coin" -NoNewline; Write-Host "N" -ForegroundColor Cyan -NoNewline; Write-Host "ame' column visibility set to " -NoNewline; If ($Variables.ShowCoinName) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "."
                        Start-Sleep -Seconds 2
                        $Variables.RefreshNeeded = $true
                        Break
                    }
                    "p" { 
                        $Variables.ShowPool = -not $Variables.ShowPool
                        Write-Host "`n'" -NoNewline; Write-Host "P" -ForegroundColor Cyan -NoNewline; Write-Host "ool' column visibility set to " -NoNewline; If ($Variables.ShowPool) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "."
                        Start-Sleep -Seconds 2
                        $Variables.RefreshNeeded = $true
                        Break
                    }
                    "r" { 
                        If ($Variables.CalculatePowerCost) { 
                            $Variables.ShowProfitBias = -not $Variables.ShowProfitBias
                            Write-Host "`n'P" -NoNewline; Write-Host "r" -ForegroundColor Cyan -NoNewline; Write-Host "ofitBias' column visibility set to " -NoNewline; If ($Variables.ShowProfitBias) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "."
                            Start-Sleep -Seconds 2
                            $Variables.RefreshNeeded = $true
                        }
                        Break
                    }
                    "t" { 
                        If ($Variables.CalculatePowerCost) { 
                            $Variables.ShowProfit = -not $Variables.ShowProfit
                            Write-Host "`n'" -NoNewline; Write-Host "P" -ForegroundColor Cyan -NoNewline; Write-Host "rofit' column visibility set to " -NoNewline; If ($Variables.ShowProfit) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "."
                            Start-Sleep -Seconds 2
                            $Variables.RefreshNeeded = $true
                        }
                        Break
                    }
                    "u" { 
                        $Variables.ShowUser = -not $Variables.ShowUser
                        Write-Host "`n'" -NoNewline; Write-Host "U" -ForegroundColor Cyan -NoNewline; Write-Host "ser' column visibility set to " -NoNewline; If ($Variables.ShowUser) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "."
                        Start-Sleep -Seconds 2
                        $Variables.RefreshNeeded = $true
                        Break
                    }
                    "w" { 
                        If ($Variables.CalculatePowerCost) { 
                            $Variables.ShowPowerConsumption = -not $Variables.ShowPowerConsumption
                            Write-Host "`n'Po" -NoNewline; Write-Host "w" -ForegroundColor Cyan -NoNewline; Write-Host "erConsumption' column visibility set to " -NoNewline; If ($Variables.ShowPowerConsumption) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "."
                            Start-Sleep -Seconds 2
                            $Variables.RefreshNeeded = $true
                        }
                        Break
                    }
                    "y" { 
                        $Variables.ShowCurrency = -not $Variables.ShowCurrency
                        Write-Host "`n'Currenc" -NoNewline; Write-Host "y" -ForegroundColor Cyan -NoNewline; Write-Host "' column visibility set to " -NoNewline; If ($Variables.ShowCurrency) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "."
                        Start-Sleep -Seconds 2
                        $Variables.RefreshNeeded = $true
                        Break
                    }
                }
            }
            Remove-Variable KeyPressed
        }
    }
    Else { 
        Hide-Console
    }

    If ($Variables.RefreshNeeded) { 
        $Variables.RefreshNeeded = $false

        If ($Config.WebGUI) { Start-APIServer } Else { Stop-APIServer }

        $host.UI.RawUI.WindowTitle = "$($Variables.Branding.ProductLabel) $($Variables.Branding.Version) - Runtime: {0:dd} days {0:hh} hrs {0:mm} mins - Path: $($Variables.Mainpath)" -f [TimeSpan]([DateTime]::Now.ToUniversalTime() - $Variables.ScriptStartTime)
        If ($LegacyGUIform) { 
            $LegacyGUIform.Text = $host.UI.RawUI.WindowTitle 

            # Refresh selected tab
            Update-TabControl
            If ($Variables.MyIP) { 
                $LegacyGUIminingSummaryLabel.Text = ""
                $LegacyGUIminingSummaryLabel.SendToBack()
                (($Variables.Summary -replace 'Power Cost', '<br>Power Cost' -replace ' / ', '/' -replace '&ensp;', ' ' -replace '   ', '  ') -split '<br>').ForEach({ $LegacyGUIminingSummaryLabel.Text += "`r`n$_" })
                $LegacyGUIminingSummaryLabel.Text += "`r`n "
                If ($Variables.MiningProfit -ge 0) { $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Green }
                ElseIf ($Variables.MiningProfit -lt 0) { $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Red }
                Else { $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Black }
            }
            Else { 
                Write-Message -Level Error $Variables.Message
                $LegacyGUIminingSummaryLabel.ForeColor = [System.Drawing.Color]::Red
                $LegacyGUIminingSummaryLabel.Text = "Error: $($Variables.Summary)"
            }
        }

        If ($Config.ShowConsole) { 
            If ($Variables.CycleStarts.Count -gt 1) { Clear-Host }

            # Get and display earnings stats
            If ($Variables.Balances -and $Variables.ShowPoolBalances) { 
                $Variables.Balances.Values.ForEach(
                    { 
                        If ($_.Currency -eq "BTC" -and $Config.UsemBTC) { $Currency = "mBTC"; $mBTCfactor = 1000 } Else { $Currency = $_.Currency; $mBTCfactor = 1 }
                        Write-Host "$($_.Pool -replace ' Internal$', ' (Internal Wallet)' -replace ' External$', ' (External Wallet)') [$($_.Wallet)]" -ForegroundColor Green
                        If ($Config.BalancesShowSums) { 
                            Write-Host ("Earnings last 1 hour:   {0:n$($Config.DecimalsMax)} {1} / {2:n$($Config.DecimalsMax)} {3}" -f ($_.Growth1 * $mBTCfactor), $Currency, ($_.Growth1 * $Variables.Rates.($_.Currency).($Config.MainCurrency)), $Config.MainCurrency)
                            Write-Host ("Earnings last 6 hours:  {0:n$($Config.DecimalsMax)} {1} / {2:n$($Config.DecimalsMax)} {3}" -f ($_.Growth6 * $mBTCfactor), $Currency, ($_.Growth6 * $Variables.Rates.($_.Currency).($Config.MainCurrency)), $Config.MainCurrency)
                            Write-Host ("Earnings last 24 hours: {0:n$($Config.DecimalsMax)} {1} / {2:n$($Config.DecimalsMax)} {3}" -f ($_.Growth24 * $mBTCfactor), $Currency, ($_.Growth24 * $Variables.Rates.($_.Currency).($Config.MainCurrency)), $Config.MainCurrency)
                            Write-Host ("Earnings last 7 days:   {0:n$($Config.DecimalsMax)} {1} / {2:n$($Config.DecimalsMax)} {3}" -f ($_.Growth168 * $mBTCfactor), $Currency, ($_.Growth168 * $Variables.Rates.($_.Currency).($Config.MainCurrency)), $Config.MainCurrency)
                            Write-Host ("Earnings last 30 days:  {0:n$($Config.DecimalsMax)} {1} / {2:n$($Config.DecimalsMax)} {3}" -f ($_.Growth720 * $mBTCfactor), $Currency, ($_.Growth720 * $Variables.Rates.($_.Currency).($Config.MainCurrency)), $Config.MainCurrency)
                        }
                        If ($Config.BalancesShowAverages) { 
                            Write-Host ("≈ average / hour:       {0:n$($Config.DecimalsMax)} {1} / {2:n$($Config.DecimalsMax)} {3}" -f ($_.AvgHourlyGrowth * $mBTCfactor), $Currency, ($_.AvgHourlyGrowth * $Variables.Rates.($_.Currency).($Config.MainCurrency)), $Config.MainCurrency)
                            Write-Host ("≈ average / day:        {0:n$($Config.DecimalsMax)} {1} / {2:n$($Config.DecimalsMax)} {3}" -f ($_.AvgDailyGrowth * $mBTCfactor), $Currency, ($_.AvgDailyGrowth * $Variables.Rates.($_.Currency).($Config.MainCurrency)), $Config.MainCurrency)
                            Write-Host ("≈ average / week:       {0:n$($Config.DecimalsMax)} {1} / {2:n$($Config.DecimalsMax)} {3}" -f ($_.AvgWeeklyGrowth * $mBTCfactor), $Currency, ($_.AvgWeeklyGrowth * $Variables.Rates.($_.Currency).($Config.MainCurrency)), $Config.MainCurrency)
                        }
                        Write-Host "Balance:                " -NoNewline; Write-Host ("{0:n$($Config.DecimalsMax)} {1} / {2:n$($Config.DecimalsMax)} {3}" -f ($_.Balance * $mBTCfactor), $Currency, ($_.Balance * $Variables.Rates.($_.Currency).($Config.MainCurrency)), $Config.MainCurrency) -ForegroundColor Yellow
                        Write-Host "                        $(($_.Balance / $_.PayoutThreshold).ToString('P2')) of $(($_.PayoutThreshold * $mBTCfactor).ToString()) $Currency payment threshold"
                        Write-Host "Projected payment date: $(If ($_.ProjectedPayDate -is [DateTime]) { $_.ProjectedPayDate.ToString("G") } Else { $_.ProjectedPayDate })`n"
                    }
                )
                Remove-Variable Currency, mBTCfactor -ErrorAction Ignore
            }

            If ($Variables.MyIP) { 
                If ($Variables.MiningStatus -eq "Running" -and $Variables.Miners.Where({ $_.Available })) { 
                    # Miner list format
                    [System.Collections.ArrayList]$MinerTable = @(
                        @{ Label = "Miner"; Expression = { $_.Name } }
                        If ($Variables.ShowMinerFee -and ($Variables.Miners.Workers.Fee)) { @{ Label = "Fee"; Expression = { $_.Workers.Fee.ForEach({ "{0:P2}" -f [Double]$_ }) }; Align = "right" } }
                        If ($Variables.ShowEarningBias) { @{ Label = "EarningBias"; Expression = { If ([Double]::IsNaN($_.Earning_Bias)) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Earning_Bias * $Variables.Rates.($Config.PayoutCurrency).($Config.MainCurrency)) } }; Align = "right" } }
                        If ($Variables.ShowEarning) { @{ Label = "Earning"; Expression = { If ([Double]::IsNaN($_.Earning)) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Earning * $Variables.Rates.($Config.PayoutCurrency).($Config.MainCurrency)) } }; Align = "right" } }
                        If ($Variables.ShowPowerCost -and $Config.CalculatePowerCost -and $Variables.MiningPowerCost) { @{ Label = "PowerCost"; Expression = { If ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } Else { "-{0:n$($Config.DecimalsMax)}" -f ($_.PowerCost * $Variables.Rates.($Config.PayoutCurrency).($Config.MainCurrency)) } }; Align = "right" } }
                        If ($Variables.MiningPowerCost -and $Variables.ShowProfitBias) { @{ Label = "ProfitBias"; Expression = { If ([Double]::IsNaN($_.Profit_Bias)) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Profit_Bias * $Variables.Rates.($Config.PayoutCurrency).($Config.MainCurrency)) } }; Align = "right" } }
                        If ($Variables.MiningPowerCost -and $Variables.ShowProfit) { @{ Label = "Profit"; Expression = { If ([Double]::IsNaN($_.Profit)) { "n/a" } Else { "{0:n$($Config.DecimalsMax)}" -f ($_.Profit * $Variables.Rates.($Config.PayoutCurrency).($Config.MainCurrency)) } }; Align = "right" } }
                        If ($Variables.ShowPowerConsumption -and $Config.CalculatePowerCost) { @{ Label = "PowerConsumption"; Expression = { If ($_.MeasurePowerConsumption) { If ($_.Status -eq "Running") { "Measuring..." } Else { "Unmeasured" } } Else { If ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } Else { "$($_.PowerConsumption.ToString("N2")) W" } } }; Align = "right" } }
                        If ($Variables.ShowAccuracy) { @{ Label = "Accuracy"; Expression = { $_.Workers.Pool.Accuracy.ForEach({ "{0:P0}" -f [Double]$_ }) }; Align = "right" } }
                        @{ Label = "Algorithm"; Expression = { $_.Workers.Pool.Algorithm -join ' & ' } }
                        If ($Variables.ShowPool) { @{ Label = "Pool"; Expression = { $_.Workers.Pool.Name -join ' & ' } } }
                        If ($Variables.ShowPoolFee -and ($Variables.Miners.Workers.Pool.Fee)) { @{ Label = "Fee"; Expression = { $_.Workers.Pool.Fee.ForEach({ "{0:P2}" -f [Double]$_ }) }; Align = "right" } }
                        @{ Label = "Hashrate"; Expression = { If ($_.Benchmark) { If ($_.Status -eq "Running") { "Benchmarking..." } Else { "Benchmark pending" } } Else { $_.Workers.ForEach({ $_.Hashrate | ConvertTo-Hash }) } }; Align = "right" }
                        If ($Variables.ShowUser) { @{ Label = "User"; Expression = { $_.Workers.Pool.User -join ' & ' } } }
                        If ($Variables.ShowCurrency) { @{ Label = "Currency"; Expression = { If ($_.Workers.Pool.Currency) { $_.Workers.Pool.Currency } } } }
                        If ($Variables.ShowCoinName) { @{ Label = "CoinName"; Expression = { If ($_.Workers.Pool.CoinName) { $_.Workers.Pool.CoinName } } } }
                    )
                    # Display optimal miners list
                    $Bias = If ($Variables.CalculatePowerCost -and -not $Config.IgnorePowerCost) { "Profit_Bias" } Else { "Earning_Bias" }
                    ($Variables.MinersOptimal | Group-Object { [String]$_.DeviceNames }).ForEach(
                        { 
                            $MinersDeviceGroup = $_.Group | Sort-Object { $_.Name, [String]$_.Algorithms } -Unique
                            $MinersDeviceGroupNeedingBenchmark = @($MinersDeviceGroup.Where({ $_.Benchmark }))
                            $MinersDeviceGroupNeedingPowerConsumptionMeasurement = @($MinersDeviceGroup.Where({ $_.MeasurePowerConsumption }))
                            $MinersDeviceGroup.Where(
                                { 
                                    $Variables.ShowAllMiners -or <# List all miners #>
                                    $MinersDeviceGroupNeedingBenchmark.Count -gt 0 -or <# List all miners when benchmarking #>
                                    $MinersDeviceGroupNeedingPowerConsumptionMeasurement.Count -gt 0 -or <# List all miners when measuring power consumption #>
                                    $_.$Bias -ge ($MinersDeviceGroup.$Bias | Sort-Object -Bottom 5 | Select-Object -Index 0) <# Always list at least the top 5 miners per device group #>
                                } 
                            ) | Sort-Object -Property @{ Expression = { $_.Benchmark }; Descending = $true }, @{ Expression = { $_.MeasurePowerConsumption }; Descending = $true }, @{ Expression = { $_.KeepRunning }; Descending = $true }, @{ Expression = { $_.Prioritize }; Descending = $true }, @{ Expression = { $_.$Bias }; Descending = $true }, @{ Expression = { $_.Name }; Descending = $false }, @{ Expression = { $_.Algorithms[0] }; Descending = $false }, @{ Expression = { $_.Algorithms[1] }; Descending = $false } | 
                            Format-Table $MinerTable -GroupBy @{ Name = "Device$(If ($MinersDeviceGroup[0].DeviceNames.Count -gt 1) { " group" })"; Expression = { "$($MinersDeviceGroup[0].DeviceNames -join ',') [$(($Variables.EnabledDevices.Where({ $_.Name -In $MinersDeviceGroup[0].DeviceNames })).Model -join ', ')]" } } -AutoSize | Out-Host

                            # Display benchmarking progress
                            If ($MinersDeviceGroupNeedingBenchmark) { 
                                "Benchmarking for device$(If (($MinersDeviceGroup.DeviceNames | Select-Object -Unique).Count -gt 1) { " group" }) '$(($MinersDeviceGroup.DeviceNames | Sort-Object -Unique) -join ',')' in progress: $($MinersDeviceGroupNeedingBenchmark.Count) miner$(If ($MinersDeviceGroupNeedingBenchmark.Count -gt 1) { 's' }) left to complete benchmark." | Out-Host
                            }
                            # Display power consumption measurement progress
                            If ($MinersDeviceGroupNeedingPowerConsumptionMeasurement) { 
                                "Power consumption measurement for device$(If (($MinersDeviceGroup.DeviceNames | Sort-Object -Unique).Count -gt 1) { " group" }) '$(($MinersDeviceGroup.DeviceNames | Sort-Object -Unique) -join ',')' in progress: $($MinersDeviceGroupNeedingPowerConsumptionMeasurement.Count) miner$(If ($MinersDeviceGroupNeedingPowerConsumptionMeasurement.Count -gt 1) { 's' }) left to complete measuring." | Out-Host
                            }
                        }
                    )
                    Remove-Variable Bias, MinerTable, MinersDeviceGroup, MinersDeviceGroupNeedingBenchmark, MinersDeviceGroupNeedingPowerConsumptionMeasurement -ErrorAction Ignore
                }

                If ($Variables.MinersBest) { 
                    Write-Host "`nRunning $(If ($Variables.MinersBest.Count -eq 1) { "miner:" } Else { "miners: $($Variables.MinersBest.Count)" })"
                    [System.Collections.ArrayList]$MinerTable = @(
                        @{ Label = "Name"; Expression = { $_.Name } }
                        If ($Config.CalculatePowerCost -and $Variables.ShowPowerConsumption) { @{ Label = "PowerConsumption"; Expression = { If ([Double]::IsNaN($_.PowerConsumption_Live)) { "n/a" } Else { "$($_.PowerConsumption_Live.ToString("N2")) W" } }; Align = "right" } }
                        @{ Label = "Hashrate"; Expression = { $_.Hashrates_Live.ForEach({ If ([Double]::IsNaN($_)) { "n/a" } Else { $_ | ConvertTo-Hash } }) -join ' & ' }; Align = "right" }
                        @{ Label = "Active (this run)"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f ([DateTime]::Now.ToUniversalTime() - $_.BeginTime) } }
                        @{ Label = "Active (total)"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f ($_.TotalMiningDuration) } }
                        @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_" } } } }
                        @{ Label = "Device(s)"; Expression = { $_.DeviceNames -join ',' } }
                        @{ Label = "Command"; Expression = { $_.CommandLine } }
                    )
                    $Variables.MinersBest | Sort-Object -Property { $_.DeviceNames } | Format-Table $MinerTable -Wrap | Out-Host
                    Remove-Variable MinerTable
                }

                If ($Variables.UIStyle -eq "full" -or $Variables.MinersNeedingBenchmark -or $Variables.MinersNeedingPowerConsumptionMeasurement) { 
                    If ($Variables.UIStyle -ne "full") { 
                        Write-Host "$(If ($Variables.MinersNeedingBenchmark) { "Benchmarking" })$(If ($Variables.MinersNeedingBenchmark -and $Variables.MinersNeedingPowerConsumptionMeasurement) { " / " })$(If ($Variables.MinersNeedingPowerConsumptionMeasurement) { "Measuring power consumption" }): Temporarily switched UI style to 'Full' (Information about miners run in the past, failed miners & watchdog timers will be shown)`n" -ForegroundColor Yellow
                    }

                    $MinersActivatedLast24Hrs = @($Variables.Miners.Where({ $_.Activated -and $_.EndTime.ToLocalTime().AddHours(24) -gt [DateTime]::Now }))

                    If ($ProcessesIdle = $MinersActivatedLast24Hrs.Where({ $_.Status -eq "Idle" })) { 
                        Write-Host "$($ProcessesIdle.Count) previously executed miner$(If ($ProcessesIdle.Count -ne 1) { "s" }) (past 24 hrs):"
                        [System.Collections.ArrayList]$MinerTable = @(
                            @{ Label = "Name"; Expression = { $_.Name } }
                            If ($Config.CalculatePowerCost -and $Variables.ShowPowerConsumption) { @{ Label = "PowerConsumption"; Expression = { If ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } Else { "$($_.PowerConsumption.ToString("N2")) W" } }; Align = "right" } }
                            @{ Label = "Hashrate"; Expression = { $_.Workers.Hashrate.ForEach({ $_ | ConvertTo-Hash }) -join ' & ' }; Align = "right" }
                            @{ Label = "Time since last run"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f $([DateTime]::Now - $_.EndTime.ToLocalTime()) } }
                            @{ Label = "Active (total)"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f $_.TotalMiningDuration } }
                            @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { $_ } } } }
                            @{ Label = "Device(s)"; Expression = { $_.DeviceNames -join ',' } }
                            @{ Label = "Command"; Expression = { $_.CommandLine } }
                        )
                        $ProcessesIdle | Sort-Object { $_.EndTime } -Descending | Format-Table $MinerTable -Wrap | Out-Host
                        Remove-Variable MinerTable
                    }
                    Remove-Variable ProcessesIdle

                    If ($ProcessesFailed = $MinersActivatedLast24Hrs.Where({ $_.Status -eq "Failed" })) { 
                        Write-Host -ForegroundColor Red "$($ProcessesFailed.Count) failed $(If ($ProcessesFailed.Count -eq 1) { "miner" } Else { "miners" }) (past 24 hrs):"
                        [System.Collections.ArrayList]$MinerTable = @(
                            @{ Label = "Name"; Expression = { $_.Name } }
                            If ($Config.CalculatePowerCost -and $Variables.ShowPowerConsumption) { @{ Label = "PowerConsumption"; Expression = { If ([Double]::IsNaN($_.PowerConsumption)) { "n/a" } Else { "$($_.PowerConsumption.ToString("N2")) W" } }; Align = "right" } }
                            @{ Label = "Hashrate"; Expression = { $_.Workers.Hashrate.ForEach({ $_ | ConvertTo-Hash }) -join ' & ' }; Align = "right" }
                            @{ Label = "Time since last fail"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f $([DateTime]::Now - $_.EndTime.ToLocalTime()) } }
                            @{ Label = "Active (total)"; Expression = { "{0:dd}d {0:hh}h {0:mm}m {0:ss}s" -f $_.TotalMiningDuration } }
                            @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { $_ } } } }
                            @{ Label = "Device(s)"; Expression = { $_.DeviceNames -join ',' } }
                            @{ Label = "Command"; Expression = { $_.CommandLine } }
                        )
                        $ProcessesFailed | Sort-Object { If ($_.EndTime) { $_.EndTime } Else { [DateTime]0 } } | Format-Table $MinerTable -Wrap | Out-Host
                        Remove-Variable MinerTable
                    }
                    Remove-Variable MinersActivatedLast24Hrs, ProcessesFailed

                    If ($Config.Watchdog) { 
                        # Display watchdog timers
                        $Variables.WatchdogTimers.Where({ $_.Kicked -gt $Variables.Timer.AddSeconds(-$Variables.WatchdogReset) }) | Sort-Object -Property MinerName, Kicked | Format-Table -Wrap (
                            @{Label = "Miner Watchdog Timer"; Expression = { $_.MinerName } }, 
                            @{Label = "Pool"; Expression = { $_.PoolName } }, 
                            @{Label = "Algorithm"; Expression = { $_.Algorithm } }, 
                            @{Label = "Device(s)"; Expression = { $_.DeviceNames -join ',' } }, 
                            @{Label = "Last Updated"; Expression = { "{0:mm} min {0:ss} sec ago" -f ([DateTime]::Now.ToUniversalTime() - $_.Kicked) }; Align = "right" }
                        ) | Out-Host
                    }
                }

                If ($Variables.MiningStatus -eq "Running") { 
                    If ($Variables.Timer) { 
                        Write-Host ($Variables.Summary -replace '\.\.\.<br>', '... ' -replace '<br>', $nl -replace '&ensp;', ' ' -replace '\s*/\s*', '/' -replace '\s*=\s*', '=')
                    }
                    If ($Variables.Miners.Where({ $_.Available -and -not ($_.Benchmark -or $_.MeasurePowerConsumption) })) { 
                        If ($Variables.MiningProfit -lt 0) { 
                            # Mining causes a loss
                            Write-Host -ForegroundColor Red ("Mining is currently NOT profitable and causes a loss of {0} {1:n$($Config.DecimalsMax)} / day (including Base Power Cost)." -f $Config.MainCurrency, (-$Variables.MiningProfit * $Variables.Rates.($Config.PayoutCurrency).($Config.MainCurrency)))
                        }
                        If ($Variables.MiningProfit -lt $Config.ProfitabilityThreshold) { 
                            # Mining profit is below the configured threshold
                            Write-Host -ForegroundColor Blue ("Mining profit ({0} {1:n$($Config.DecimalsMax)}) is below the configured threshold of {0} {2:n$($Config.DecimalsMax)} / day. Mining is suspended until threshold is reached." -f $Config.MainCurrency, ($Variables.MiningProfit * $Variables.Rates.($Config.PayoutCurrency).($Config.MainCurrency)), $Config.ProfitabilityThreshold)
                        }
                    }

                    If ($Variables.CycleStarts.Count -gt 1 -or $Variables.Miners) { 
                        $StatusInfo = "Last refresh: $($Variables.BeginCycleTime.ToLocalTime().ToString('G'))   |   Next refresh: $(If ($Variables.EndCycleTime) { $($Variables.EndCycleTime.ToLocalTime().ToString('G')) } Else { 'n/a (Mining is suspended)' })   |   Hot Keys: $(If ($Variables.CalculatePowerCost) { "[123acefimnprtuwy]" } Else { "[123aefimnruwy]" })   |   Press 'h' for help"
                        Write-Host ("-" * $StatusInfo.Length)
                        Write-Host -ForegroundColor Yellow $StatusInfo
                        Remove-Variable StatusInfo
                    }
                }
            }
            Else { 
                Write-Host -ForegroundColor Red "$((Get-Date).ToString('G')): $($Variables.Summary)"
            }
        }
        $Error.Clear()
        [System.GC]::Collect()
    }
}

If ($Variables.FreshConfig) { 
    $Variables.NewMiningStatus = "Idle" # Must click 'Starrt mining' in GUI
    Write-Message -Level Warn "No configuration file found. Edit and save your configuration using the configuration editor (http://localhost:$($Config.APIport)/configedit.html)"
    $Variables.Summary = "Edit your settings and save the configuration.<br>Then click the 'Start mining' button."
}

While ($true) { 
    If ($Config.LegacyGUI) { 
        If (-not $LegacyGUIform.CanSelect) { 
            . .\Includes\LegacyGUI.ps1
        }
        # Show legacy GUI
        $LegacyGUIform.ShowDialog() | Out-Null
    }
    ElseIf (-not $Variables.FreshConfig) { 
        [Void](MainLoop)
        Start-Sleep -Milliseconds 50
    }

    $Error.Clear()
}