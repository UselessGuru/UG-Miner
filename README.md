# UG-Miner

UG-Miner monitors mining pools in real-time in order to find the most profitable algorithm
and runs the most profitable miner.

Version 6.4.8 / Updated 2025/02/04


Copyright (c) 2018-2025 UselessGuru

This is free software, and you are welcome to redistribute it under certain conditions.  
https://github.com/UselessGuru/UG-Miner/blob/master/LICENSE

This project is updated & maintained by UselessGuru.

UG-Miner code is partly based on

- MultiPoolMiner<sup>(*)</sup>  
  https://github.com/MultiPoolMiner/MultiPoolMiner

- NPlusMiner<sup>(*)</sup>  
  https://github.com/MrPlusGH/NPlusMiner

- NemosMiner<sup>(*)</sup>  
  https://github.com/Minerx117/NemosMiner
  
  <sup>(*)</sup>These projects are no longer maintained

## Main features:

- Web & legacy GUI
- Easy configuration
- Automatic benchmark each algorithm to get optimal speeds
- Idle detection
- Fully automated
- Automatically downloads miner binaries
- Automatic updates
- Earnings graph & balances tracker
- Low developer fee of 1% (can be set to 0%)
- Calculate power cost<sup>(1)</sup>

- Miner switching log
- Supported pools: 
   - [HashCryptos](<https://hashcryptos.com/>)
   - [Hiveon](<https://hiveon.net/>)<sup>(2)</sup>
   - [MiningDutch](<https://www.mining-dutch.nl/>)
   - [NiceHash](<https://www.nicehash.com/>)<sup>(3)</sup>
   - [ProHashing](<https://prohashing.com/>)
   - [ZergPool](<https://zergpool.com/>)<sup>(4)</sup>
   - [ZPool](<https://zpool.ca/>)<sup>(4)</sup>

<sup>(1)</sup> Optional installation of HWiNFO required, see [ConfigHWinfo64.pdf](<https://github.com/UselessGuru/UG-Miner/blob/main/ConfigHWinfo64.pdf>)

<sup>(2)</sup> Pool does not support auto-exchange to BTC or other currencies.  
    You need to configure a wallet address for each currency you want to mine.

<sup>(3)</sup> Registration with NiceHash is required. For some countries private usage is not longer possible.  

<sup>(4)</sup> Pool does not support auto-exchange for some currencies.  
    You need to configure a wallet address for each non-auto-exchangable currency you want to mine.

## Easy configuration, easy start

   Run **UG-Miner.bat** or **UG-Miner_AsAdmin.bat**
   1. Edit configuration (http://localhost:3999/configedit.html)
   2. Set your wallet address(es) and username(s) <sup>(*)</sup>
   3. Select your pool(s)
   4. Save configuration
   5. Start mining

   <sup>(*)</sup> To enable MiningDutch or ProHashing you must configure a username

It is recommended to run UG-Miner with local computer administrator rights (UG-Miner_AsAdmin.bat) to ensure file permissions and firewall rules can be set without user intervention. 

![alt text](https://github.com/UselessGuru/UG-Miner-Extras/releases/download/Images/UG-Miner_FirstStart.png "UG-Miner Web GUI")

### Pools

UG-Miner polls the pools in regular intervals to get up-to-date pricing and coin availablilty data.  
You must select at least one pool.  
If you select several pools, then your earnings might be split across differnt pools. UG-Miner will always direct the miners to the pools with the highest earnings.  
It is recommended to keep the number of configured pools to a minimum as this will might your earnings and it could take longer to reach the pools payout thresholds.

#### Poolnames ending in *24h:

\+ use calculations based on 24hr prices to get a more stable estimate  
\+ are NOT sensible to price spikes  
\+ show less switching than following current or plus price estimate  
\- lower estimated profitability in exchange for less switching

#### Poolnames ending in *Plus:

\+ use calculations based on 24hr actual and current estimate prices to get a more realistic estimate  
\+ include some trust index based on past 1hr current estimate variation from 24hr  
\+ are NOT sensible to price spikes  
\+ show less switching than following current estimate and more switching than following the 24hr actual  
\+ better estimated profitability

#### Poolnames without *24h/Plus

\+ use current price data in pool API to calculate profit (no estimates or advanced calculations)  
\- are sensible to price spikes  
\- show more switching

### Algorithm selection

+[algorithm] to enable algorithm  
-[algorithm] to disable algorithm

If '+' is used, then only the explicitly enabled algorithms are used  
If '-' is used, then all algorithms except the disabled ones are used

Do not combine '+' and '-' for the same algorithm.

#### Examples:
Algorithm list = '-ethash'  
Will mine anything but ethash

Algorithm list = '-ethash,-kawpow'  
Will mine anything but ethash and kawpow

Algorithm list = +ethash  
Will mine only ethash

Algorithm list = '+ethash,+kawpow'  
Will mine only ethash and kawpow

Algorithm list blank  
Will mine all available algorithms

### Currency selection

+[currency] to enable currency  
-[currency] to disable currency

If '+' is used, then only the explicitly enabled currencies are used  
If '-' is used, then all currencies except the disabled ones are used

Do not combine '+' and '-' for the same currency.

#### Examples:
Currency list = '-EVR'  
Will mine anything but EVR

Currency list = '-EVR,-KIIRO'  
Will mine anything but EVR and KIIRO

Currency list = '+EVR'  
Will mine only EVR

Currency list = '+EVR,+KIIRO'  
Will mine only EVR and KIIRO

Currency list blank  
Will mine all available currencies

## Idle detection

The idle detection functionality (if enabled in the configuration) will suspend mining when UG-Miner detects any mouse or keyboard activitity.  
Mining will resume when no further activity is detected for a configurable number of seconds.

Pool brains will still run in the background avoiding the learning phase on resume.

BalancesTracker will still run in the background to keep the pool balances up to date.

## Web & legacy GUI

### Web GUI

UG-Miner can be controlled & configured through the Web GUI.  
For most scenarios there is no need to edit configration files manually.  
Some settings can be configured per [advanced pool configuration](<https://github.com/UselessGuru/UG-Miner?tab=readme-ov-file#advanced-per-pool-configuration>).

![alt text](https://github.com/UselessGuru/UG-Miner-Extras/releases/download/Images/UG-Miner_Dashboard.png "UG-Miner Web GUI Dashboard")

### Legacy GUI

![alt text](https://github.com/UselessGuru/UG-Miner-Extras/releases/download/Images/UG-Miner_LegacyGUI.png "UG-Miner Legacy GUI")

## PreRun

UG-Miner can run a batch script prior switching to a specific miner and/or algorithm.

The prerun scripts can be used to apply per miner/algorithm overclocking settings via nvidiaInspector or OverdriveNTool.  

Before starting a miner executable UG-Miner wiil try to launch one of the following 3 prerun scripts (in this order):

1. \<MinerName\>\_\<AlgorithmName\>.bat / \<MinerName\>\_\<AlgorithmName1&AlgorithmName2\>.bat  
   Create a file named \<MinerName\>\_\<AlgorithmName\>.bat in the '[UG-Miner directory]\\Utils\\prerun' folder, e.g.  
   'MiniZ-v2.4.d-1xRadeonRX5808GB_EtcHash.bat'  
   'BzMiner-v21.4.0-1xRTX306012GB_Ethash&SHA512256d.bat'  
   (use the algorithm base name, not the algorithm variant name)  

3. \<AlgorithmName\>.bat / \<AlgorithmName1&AlgorithmName2\>.bat  
   Create a file named \<AlgorithmName\>.bat in the '[UG-Miner directory]\\Utils\\prerun' folder, e.g.  
   'Ethash.bat'  
   'Ethash&SHA512256d.bat'  
   (use the algorithm base name, not the algorithm variant name)    

5. default.bat  
   If neither of the two above exist UG-Miner will try to launch '[UG-Miner directory]\\Utils\\prerun\default.bat'

**Use overclock with caution!**

## Advanced per pool configuration

**This is for advanced users. Do not use if you do not know what you are doing.**

The file 'Config\PoolsConfig.json' contains configuration details for the pools.

A separate section can be added for each pool. If a pool is listed in this file, the specific settings will be taken into account. If not, the built-in default values will be used.


**Available per pool configuration options**

- Algorithm: List of included or excluded algorithms per pool
- Currency: List of included or excluded currencies per pool
- EarningsAdjustmentFactor: This adds a multiplicator on estimations presented by the pool  
  (e.g. You feel that a pool is exaggerating its estimations by 10%: Set EarningsAdjustmentFactor to 0.9)
- Exclude region: One or more of 'Europe', 'HongKong', 'India', 'Japan', 'Russia', 'Singapore', 'USA East', 'USA West'
- MinWorker: Minimum workers mining the algorithm at the pool; if less miners are mining the algorithm then the pool will be markes as unavailable
- PayoutThreshold[Currency]: Minimum balance required for payout (to use same value for ALL currencies use [*] as currency)
- SSL: Either 'Prefer' (use SSL pool connection where available, otherwise use non-encrypted connection), 'Never' (pools that do only support SSL connection are marked as unavailable) or 'Always' (pools that do not allow SSL connection are marked as unavailable)
- SSLallowSelfSignedCertificate [true|false]: If true will allow SSL/TLS connection with self signed certificates (this is a security issue and allows 'Man in the middle attacks')
- Wallets[Currency]: Your wallet address for [Currency]; some pools, e.g. Hiveon, require wallets in each supported currency

See 'Data\PoolsConfig-Template.json' for all available pool configuration options and the basic file structure of 'Config\PoolsConfig.json'.

**Usage**

- Edit 'Config\PoolsConfig.json' (**be careful with json formatting!**)
- Add an entry for the pool you want to customize  
  The name must be the pool base name (omit *24hrs or *Plus), e.g ZergPool (even if you have configured ZergPoolPlus in the pool list)
- Add the pool specific configuration items

Note: The configuration editor in the Web GUI only updates the generic pool settings. Pool specific settings override the generic settings.

## Balances tracking

UG-Miner displays the available balances and calculates an estimation of when the pool payment threshold will be reached.

Supported pools:

 - HashCryptos
 - Hiveon
 - MiningDutch
 - NiceHash
 - ProHashing
 - ZergPool
 - Zpool

## Miner switching log

A simple miner switching log in csv format is written to '[UG-Miner directory]\Logs\SwitchingLog.csv'.

## Console display options

In the main text window (session console) the following hot keys are supported:
```
Hot key legend:
1: Toggle Listing pool balances                    [off]
2: Toggle Listing all optimal miners               [off]
3: Toggle UI style [full or light]                 [light]

a: Toggle 'Accuracy' column visibility             [on]
c: Toggle 'Power cost' column visibility           [on]
e: Toggle 'Earnings' column visibility             [off]
f: Toggle Pool 'Fees' column visibility            [on]
i: Toggle 'Earning bias' column visibility         [on]
m: Toggle Miner 'fees' column visibility           [on]
n: Toggle 'CoinName' column visibility             [on]
p: Toggle 'Pool' column visibility                 [on]
r: Toggle 'Profit bias' column visibility          [on]
t: Toggle 'Profit' column visibility               [off]
u: Toggle 'User' column visibility                 [on]
w: Toggle 'Power consumption' column visibility    [on]
y: Toggle 'Currency' column visibility             [on]
```
UI style can be set to 'light' or 'full':

- light (default)  
  Information about miners run in the past 24hrs, failed miners in the past 24hrs & watchdog timers will be not be shown

- full  
  Information about miners run in the past 24hrs, failed miners in the past 24hrs & watchdog timers will be shown

UIStyle automatically switches to full during benchmarking or when measuring power cunsumption.

## Requirements

Windows 10.x and PowerShell Version 7.x or higher is required.

UG-Miner works best with the latest PWSH version 7.5.0.  
[Download Installer for version 7.5.0](https://github.com/PowerShell/PowerShell/releases/download/v7.5.0/PowerShell-7.5.0-win-x64.msi)  

Some miners may need 'Visual C+ RunTimes. Download and extract  
[Visual C+ RunTimes](https://github.com/UselessGuru/UG-Miner-Extras/releases/download/Visual-C-Runtimes-All-in-One-Sep-2019/Visual-C-Runtimes-All-in-One-Sep-2019.zip)  
then run install_all.bat file.

Virtual memory settings  
When running multiple cards its recommended to increase Virtual Memory. 16GB is optimal.

Recommended/optimal Windows Nvidia driver  
[Windows Nvidia driver 537.42](https://us.download.nvidia.com/Windows/537.42/537.42-desktop-win10-win11-64bit-international-dch-whql.exe)  
If you use older drivers some miners will not be available.

Recommended/optimal Windows AMD driver  
[Windows 10/11 AMD GPU Driver 7/25/2023](https://www.amd.com/en/support)

UG-Miner is currently tested on the following rigs: 

- Windows11-1xGTX1030-2GB/1xRTX-3060-12GB/1xGTX750Ti-2GB/1xRX5700-8GB/1xRX6600-8GB/Inteli5-8600K
- Windows11-1xMX250/Inteli10-10210u

## Developer donation

The default donation fee is approx. 1% (15 minutes per day). It can be increased or decreased in the configuration editor.

Please help support the great team behind UG-Miner by leaving mining donations turned on.

We want to stay completely transparent on the way fees are managed in the product.  
Donation cycle occurs only once in 24hrs (or once until midnight if UG-Miner has been running less than 24hrs).  
Donation start time is randomized each day.  
It will then mine for UselessGuru for the configured duration.  

Example for default parameters (15 minutes):

- UG-Miner was started at 10:00h
- First donation cycle starts somewhen between 10:01h and 23:45h and will then donate for 15 minutes, then mine for you again until the next donation run.
- After 00:00h the donation start time is randomized again.
- When donation start time is reached it will then donate for 15 minutes, then mine for you again until the next donation run.

The donation data is stored in 'Data\DonationData.json'.  
All donation time and addresses are recorded in the donation log file 'Log\DonationLog.csv'.

## Known issues

- Balance Tracker / Earnings Graph: Date change does not respect local time zone (accumulated data is calculated in UTC time)
- UG-Miner has issues with new Windows Terminal when the default terminal application is set to 'Let windows decide' or 'Windows Terminal'.
  -> It is recommended to set it to 'Windows Console Host'

## Experimental support for running multiple instances (not recommended)

More than one instance of UG-Miner can run on the same rig. Each instance must be placed in its own directory.  
You must use non-overlapping port ranges (configuration item 'APIport').  
Do not use the same miner devices in more than one instance (this will give invalid hash rate & power consumption readings causing incorrect best miner selection).

## Copyright & licenses

Licensed under the GNU General Public License v3.0  
Permissions of this strong copyleft license are conditioned on making available complete source code of licensed works 
and modifications, which include larger works using a licensed work, under the same license.  
Copyright and license notices must be preserved. Contributors provide an express grant of patent rights.  
https://github.com/UselessGuru/UG-Miner/blob/master/LICENSE

## Happy mining :-)
