# UG-Miner

UG-Miner monitors mining pools in real-time in order to find the most profitable algorithm  
and runs the most profitable miner.

Version 6.6.6 / Updated 2025/11/19

Copyright (c) 2018-2025 UselessGuru

This is free software. You are welcome to redistribute it under certain conditions.  
https://github.com/UselessGuru/UG-Miner/blob/master/LICENSE

This project is updated & maintained by UselessGuru.

UG-Miner code is partly based on

- MultiPoolMiner<sup>(*)</sup>  
  https://github.com/MultiPoolMiner/MultiPoolMiner

- NemosMiner<sup>(*)</sup>  
  https://github.com/Minerx117/NemosMiner

- NPlusMiner<sup>(*)</sup>  
  https://github.com/MrPlusGH/NPlusMiner
  <sup>(*)</sup>These projects are no longer maintained

## Main features:

- Easy configuration
- Automatic benchmarking of all miners
- Idle detection
- Fully automated
- Automatically downloads miner binaries
- Automatic updates
- Web & legacy GUI
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
   - [ZPool](<https://zpool.ca/>)<sup>(4)</sup>

<sup>(1)</sup> Optional installation of HWiNFO required, see [ConfigHWinfo64.pdf](<https://github.com/UselessGuru/UG-Miner/blob/main/ConfigHWinfo64.pdf>)

<sup>(2)</sup> Pool does not support auto-exchange to BTC or other currencies.  
    You need to configure a wallet address for each currency you want to mine.

<sup>(3)</sup> Registration with NiceHash is required. For some countries private usage is no longer possible.  


## Easy configuration, easy start

   1. Download https://github.com/UselessGuru/UG-Miner/archive/refs/heads/main.zip and extract the zip file to a new folder of your choice.
   2. Run **[UG-Miner directory]\UG-Miner.bat** or **[UG-Miner directory]\UG-Miner_AsAdmin.bat**
   3. Edit configuration (http://localhost:3999/configedit.html)
   4. Set your wallet address(es) and username(s) <sup>(*)</sup>
   5. Select your pool(s)
   6. Save configuration
   7. Start mining

   <sup>(*)</sup> To enable MiningDutch or ProHashing you must configure a username.  
   To mine with NiceHash you must register and use the BTC address provided by NiceHash.

It is recommended to run UG-Miner with local computer administrator privileges (UG-Miner_AsAdmin.bat) to ensure file permissions and firewall rules can be set without user intervention. 

![alt text](https://github.com/UselessGuru/UG-Miner-Extras/releases/download/Images/UG-Miner_FirstStart.png "UG-Miner web GUI")

### Pools

UG-Miner polls the configured pools in regular intervals to get up-to-date pricing and coin availability information.  

You must select at least one pool.  
If you select several pools, then your earnings might be split across different pools. UG-Miner will always direct the miners to the pools with the highest earnings.  
It is recommended to keep the number of configured pools to a minimum as this might dilute your earnings and it could take longer to reach the pools payout thresholds.

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

If more than one algorithm is given, then the algorithms must be separated with commas. Do not use spaces in between the values.

If '+' is used, then only the explicitly enabled algorithms are used  
If '-' is used, then all algorithms except the disabled ones are used

Do not combine '+' and '-' concurrently.

This parameter is not case sensitive. 

#### Examples:
Algorithm list '-Ethash':  
Will mine anything but ethash

Algorithm list: '-Ethash(3GB),-Kawpow'  
Will mine anything but Ethash (3GB DAG size only) or Kawpow (any DAG size)

Algorithm list '+Ethash':  
Will mine only Ethash (any DAG size)

Algorithm list '+Ethash,+Kawpow(4GB)':  
Will mine only Ethash (any DAG size) and Kawpow (only 4GB DAG size)

Algorithm list blank:  
Will mine all available algorithms

### Currency selection

+[currency] to enable currency  
-[currency] to disable currency

If more than one currency is given, then the currencies must be separated with commas. Do not use spaces in between the values.

If '+' is used, then only the explicitly enabled currencies are used  
If '-' is used, then all currencies except the disabled ones are used

Do not combine '+' and '-' concurrently.

This parameter is not case sensitive. 

#### Examples:
Currency list '-EVR':  
Will mine anything except EVR

Currency list '-EVR,-KIIRO':  
Will mine anything except EVR and KIIRO

Currency list '+EVR':  
Will mine only EVR

Currency list '+EVR,+KIIRO':  
Will mine only EVR and KIIRO

Currency list blank:  
Will mine all available currencies

## Idle detection

The idle detection functionality (if enabled in the configuration) will suspend mining when UG-Miner detects any mouse or keyboard activitity.  
Mining will resume when no further activity is detected for a configurable number of seconds.

Pool brains will still run in the background avoiding the learning phase on resume.

BalancesTracker will still run in the background to keep the pool balances up to date.

## Web & legacy GUI

### Web GUI

UG-Miner can be controlled & configured through the web GUI.  
For most scenarios there is no need to edit configuration files manually.  
Some settings can be configured per [advanced pool configuration](<https://github.com/UselessGuru/UG-Miner?tab=readme-ov-file#advanced-per-pool-configuration>).

![alt text](https://github.com/UselessGuru/UG-Miner-Extras/releases/download/Images/UG-Miner_Dashboard.png "UG-Miner web GUI Dashboard")

### Legacy GUI

![alt text](https://github.com/UselessGuru/UG-Miner-Extras/releases/download/Images/UG-Miner_LegacyGUI.png "UG-Miner legacy GUI")

## PreRun

UG-Miner can run a batch script prior switching to a specific miner and/or algorithm.

The prerun scripts can be used to apply overclocking settings via any OC tool that can be parameterized via batch file commands (e.g. nvidiaInspector or OverdriveNTool).  

Before starting a miner executable UG-Miner will try to launch one of the following 3 prerun scripts (in this order):

1. \<MinerName\>\_\<AlgorithmName\>.bat / \<MinerName\>\_\<AlgorithmName1&AlgorithmName2\>.bat  
   Create a file named \<MinerName\>\_\<AlgorithmName\>.bat in the '[UG-Miner directory]\Utils\prerun' folder, e.g.  
   'MiniZ-v2.5e-1xRX66008GB_EtcHash.bat'  
   'lolMiner-v1.9.7-1xRTX306012GB_Ethash&SHA512256d.bat'  
   (use the algorithm base name, not the algorithm variant name)  

2. \<AlgorithmName\>.bat / \<AlgorithmName1&AlgorithmName2\>.bat  
   Create a file named \<AlgorithmName\>.bat in the '[UG-Miner directory]\Utils\prerun' folder, e.g.  
   'Ethash.bat'  
   'Ethash&SHA512256d.bat'  
   (use the algorithm base name, not the algorithm variant name)  

3. default.bat  
   If neither of the two files above exists UG-Miner will try to launch the generic '[UG-Miner directory]\Utils\prerun\default.bat'

**Use overclock with caution!**

## Advanced per pool configuration

**This is for advanced users. Do not use if you do not know what you are doing.**

UG-Miner stores pool specific configuration information in the file '[UG-Miner directory]\Config\PoolsConfig.json'.  
See '[UG-Miner directory]\Data\PoolsConfig-Template.json' for the basic file structure and all available pool configuration options.  
A separate section can be added to for each pool. If a pool is listed in this file, the specific settings will be taken into account, otherwise the built-in default values will be used.


**Available per pool configuration options**

- Algorithm [ALGORITHM]  
  List of included or excluded algorithms per pool
- Currency [CURRENCY]  
  List of included or excluded currencies per pool
- EarningsAdjustmentFactor [Number]  
  This adds a multiplicator on estimations presented by the pool  
  (e.g. You feel that a pool is exaggerating its estimations by 10%: Set EarningsAdjustmentFactor to 0.9)
- ExcludeRegion [REGION]  
  One or more of 'Australia', 'Asia', 'Brazil', 'Canada', 'Europe', 'HongKong', 'India', 'Kazakhstan', 'Russia', 'USA East', 'USA West'
- MinWorker [Number]  
  Minimum workers mining the algorithm at the pool; if less miners are mining the algorithm then the pool will be markes as unavailable
- PayoutThreshold [CURRENCY: Value]  
  Minimum balance required for payout (to use same value for ALL currencies use [*] as currency)
- PoolAllow0Hashrate [true|false]  
  Allow mining to the pool even when there is no 0 hashrate reported in the API
- SSL [ALWAYS|NEVER|PREFER]  
  One of 'Always' (pools that do not allow SSL connection are marked as unavailable), 'Never' (pools that do only support SSL connection are marked as unavailable) or 'Prefer' (use SSL pool connection where available, otherwise use non-encrypted connection)
- SSLallowSelfSignedCertificate [true|false]  
  If true will allow SSL/TLS connection with self signed certificates (this is a security issue and allows 'Man in the middle attacks')
- Wallet [CURRENCY: Wallet address]  
  Your wallet address for [CURRENCY]; some pools, e.g. Hiveon, require wallets in each supported currency

**Usage**

- Edit '[UG-Miner directory]\Config\PoolsConfig.json' (**be careful with json formatting!**)
- Add an entry for the pool you want to customize  
  The name must be the pool base name (omit *24hrs or *Plus), e.g ZPool (even if you have configured ZPoolPlus in the pool list)
- Add the pool specific configuration items

Note: The configuration editor in the web GUI only updates the generic pool settings. Pool specific settings override the generic settings.

## Balances tracking

UG-Miner displays the available balances and calculates an estimation of when the pool payment threshold will be reached.

Supported pools:

 - HashCryptos
 - Hiveon
 - MiningDutch <sup>(*)</sup>
 - NiceHash
 - ProHashing
 - Zpool

<sup>(*)</sup> Balances tracking is disabled by default. Collecting balances data is very time consuming.

## Miner switching log

A simple miner switching log in csv format is written to '[UG-Miner directory]\Logs\SwitchingLog.csv'.

## Console hot keys

In the main text window (session console) the following hot keys are supported:
```
Hot key legend:                              Status:
1: Toggle listing pool balances              [off]
2: Toggle listing all optimal miners         [off]
3: Toggle UI style [full or light]           [light]
4: Toggle legacy GUI                         [enabled]
5: Toggle API server and web GUI             [running on port 3999]

a: Toggle 'Accuracy' column visibility       [on]
b: Toggle 'Earnings bias' column visibility  [on]
c: Toggle 'Currency' column visibility       [on]
e: Toggle 'Earnings' column visibility       [on]
m: Toggle 'Miner fee' column visibility      [on]
n: Toggle 'CoinName' column visibility       [on]
o: Toggle 'Power cost' column visibility     [on]
p: Toggle 'Pool fee' column visibility       [on]
r: Toggle 'Profit bias' column visibility    [on]
s: Toggle 'Hashrate(s)' column visibility    [on]
t: Toggle 'Profit' column visibility         [on]
u: Toggle 'User' column visibility           [on]
w: Toggle 'Power (W)' column visibility      [on]

q: Quit UG-Miner
```
UI style can be set to 'light' or 'full':

- light (default)  
  Information about miners run in the past 24hrs, failed miners in the past 24hrs & watchdog timers will be not be shown

- full  
  Information about miners run in the past 24hrs, failed miners in the past 24hrs & watchdog timers will be shown

UI style automatically switches to full during benchmarking or when measuring power consumption.

## Requirements

Windows 10.x and PowerShell Version 7.x or higher is required.

UG-Miner works best with the latest PWSH version 7.5.4.  
[Download Installer for version 7.5.4](https://github.com/PowerShell/PowerShell/releases/download/v7.5.4/PowerShell-7.5.4-win-x64.msi)  

Some miners may need 'Visual C+' runtime libraries. Download and extract  
[Visual C+ RunTimes](https://github.com/UselessGuru/UG-Miner-Extras/releases/download/Visual-C-Runtimes-All-in-One-Sep-2019/Visual-C-Runtimes-All-in-One-Sep-2019.zip)  
then run install_all.bat file.

Virtual memory settings  
When running multiple cards its recommended to increase Virtual Memory. 16GB is optimal.

Recommended/optimal Windows Nvidia driver  
[Windows Nvidia driver 576.52](https://us.download.nvidia.com/Windows/576.52/576.52-desktop-win10-win11-64bit-international-dch-whql.exe)  
If you use older drivers some miners will not be available.

Recommended/optimal Windows AMD driver  
[Windows 10/11 AMD GPU Driver 7/25/2023](https://www.amd.com/en/support)

UG-Miner is currently tested on the following rigs: 

- Windows11-1xGTX1030-2GB/1xRTX-3060-12GB/1xGTX750Ti-2GB/1xRX5700-8GB/1xRX6600-8GB/Inteli5-8600K
- Windows11-1xMX250/Inteli10-10210u
- Windows11-1xMX150/Inteli10-8570u

## Developer donation

The default donation fee is approx. 1% (15 minutes per day). It can be increased or decreased in the configuration editor.

Please help support the great team behind UG-Miner by leaving mining donations turned on.

We want to stay completely transparent on the way fees are managed in the product.  
The donation cycle occurs only once in 24hrs (or once until midnight if UG-Miner has been running less than 24hrs).  
Donation start time is randomized each day.  
It will then mine for UselessGuru for the configured duration.  

Example for default parameters (15 minutes):

- UG-Miner was started at 10:00h
- First donation cycle starts somewhen between 10:01h and 23:45h and will then donate for 15 minutes. After that it will mine for you again until the next donation run.
- After 00:00h the donation start time is randomized again.
- When donation start time is reached it will then donate for 15 minutes. After that it will mine for you again until the next donation run.
The donation data is stored in '[UG-Miner directory]\Data\DonationData.json'.  
All donation times and addresses are recorded in the donation log file '[UG-Miner directory]\Log\DonationLog.csv'.

## Known issues

- Balance Tracker / Earnings Graph: Date change does not respect local time zone (accumulated data is calculated in UTC time)

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
