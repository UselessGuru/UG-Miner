# UG-Miner

UG-Miner monitors mining pools in real-time in order to find the most profitable algorithm

Updated  2024/06/23


Copyright (c) 2018-2024 UselessGuru

This is free software, and you are welcome to redistribute it
under certain conditions.
https://github.com/UselessGuru/UG-Miner/blob/master/LICENSE

Updated & maintained by UselessGuru

UG-Miner code is partly based on

- MultiPoolMiner which can be found here: https://github.com/MultiPoolMiner/MultiPoolMiner (Project is no longer maintained)
- NPlusMiner which can be found here: https://github.com/MrPlusGH/NPlusMiner (Project is no longer maintained)
- NemosMiner which can be found here: https://github.com/Minerx117/NemosMiner (Project is no longer maintained)

*****

**Main features:**
   - Web & legacy GUI
   - Easy configuration
   - Auto benchmark each algorithm to get optimal speeds
   - Fully automated
   - Auto downloads miner binaries
   - Auto updates
   - Earnings graph
   - Low developer fee of 1% (can be set to 0)
   - Calculate power cost (optional software installation required)
   - Supports these pools: 
       - HashCryptos
       - Hiveon
       - MiningDutch
       - MiningPoolHub (*)
       - NiceHash
       - ProHashing
       - ZergPool
       - ZPool

         (*) MiningPoolHub is no longer trustworthy. Outstanding balances will not get paid and support will not respond. Use at your own risk!


*****

Easy configuration, easy start:

      Run UG-Miner.bat
      1. Edit configuration (http://localhost:3999/configedit.html)
      2. Set your Wallet address(es) and Username(s)
      3. Select your pool(s)
      4. Save configuration
      5. Start mining

      Note: 2. you only need to change the username if you are using MiningDutch, MiningPoolhub or ProHashing

![alt text](https://github.com/UselessGuru/UG-Miner-Extras/releases/download/Images/UG-Miner_FirstStart.png "UG-Miner Web GUI")

   Algorithm selection / removal

      +[algorithm] to enable algorithm
      -[algorithm] to disable algorithm

      If '+' is used, then only the explicitly enabled algorithms are used
      If '-' is used, then all algorithms except the disabled ones are used

      Do not combine + and - for the same algorithm

      Examples:
      Algorithm list = '-ethash'
      Will mine anything but ethash

      Algorithm list = '-ethash,-kawpow'
      Will mine anything but ethash and kawpow

      Algorithm list = +ethash
      Will mine only ethash

      Algorithm list = '+ethash,+kawpow'
      Will mine only ethash and kawpow

      Algorithm list blank
      Will mine anything


   Currency selection / removal

      +[currency] to enable currency
      -[currency] to disable currency

      If '+' is used, then only the explicitly enabled currencies are used
      If '-' is used, then all currencies except the disabled ones are used

      Do not combine + and - for the same currency

      Examples:
      Currency list = '-EVR'
      Will mine anything but EVR

      Currency list = '-EVR,-KIIRO'
      Will mine anything but EVR and KIIRO

      Currency list = '+EVR'
      Will mine only EVR

      Currency list = '+EVR,+KIIRO'
      Will mine only EVR and KIIRO

      Currency list blank
      Will mine anything


   Pools Variants

      *24hr  - uses last 24hour price data in pool API to calculate profit (no estimates or advanced calculations)

      *Plus - uses advanced calculations to reduce uneeded switching

      normal - uses current price data in pool API to calculate profit (no estimates or advanced calculations)


   Developer Donation

      Donation fee is approx. 1% (15 minutes per day) anf can be increased or decreased in the configuration editor.
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

      The donation data is stored in '[UG-Miner directory]\Data\DonationData.json'.
      All donation time and addresses are recorded in the domation log file '[UG-Miner directory]\Log\DonateLog.json'.


   Web & Legacy GUI

      UG-Miner relies on config files. There is no need to edit bat files. Simply run UG-Miner.bat
      Set the config in the Web GUI (http://localhost:3999/configedit.html), apply & start mining.


![alt text](https://github.com/UselessGuru/UG-Miner-Extras/releases/download/Images/UG-Miner_Dashboard.png "UG-Miner Web GUI Dashboard")


   Pause mining

      Ability to pause miners while keeping other jobs running (pause button). This will stop mining activity.
      Brains will still run in the background avoiding the learning phase on resume.
      BalancesTracker will still run in the background to keep the pool balances up to date.

   PreRun

      Ability to run a batch prior switching to a specific miner and/or algorithm.
      The prerun scripts can be used to set per miner/algorithm OC via nvidiaInspector or OverdriveNTool.
      Before starting a miner executable UG-Miner is trying to launch one of the following 3 prerun scripts (in this order):
      1. <MinerName>_<Algorithm>.bat
         Simply create a file named <MinerName>_<AlgorithmName>.bat in prerun folder, e.g. 'MiniZ-v2.4.d-1xRadeonRX5808GB-EtcHash.bat' or 'Wildrig-v0.40.5-1xGTX10606GB_Ghostrider.bat'
      2. <Algorithm>.bat
         Simply create a file named <AlgorithmName>.bat in prerun folder, e.g. 'Ethash.bat'
      3. default.bat
         If neither of the two above exist, UG-Miner will try to launch 'prerun\default.bat'
      Use overclock with caution

   Per pool config (Advanced, see 'Data\PoolsConfig-Template.json')

      **This is for advanced users. Do not use if you do not know what you are doing.**

      The file 'Config\PoolsConfig.json' contains configuration details for the pools.
      A separate section can be added for each pool base name. If a pool is listed in this file,
      the specific settings will be taken into account. If not, the built in default values will be used.
      See 'Data\PoolData.json' for the basic structure of the file 'Config\PoolsConfig.json'

      You can set specific options per pool. For example, you can mine NiceHash on the internal wallet and other pools on a valid wallet. See 'PoolsConfig-Template.json' for some pool specific configuration options.

      Available options:
         - Wallets[Currency]: Your wallet address for [Currency]; some pools, e.g. Hiveon require wallets in each supported currency
         - UserName: your MPH or ProHashing user name
         - WorkerName: your worker name
         - EarningsAdjustmentFactor: See explanation below
         - Algorithm: List of included or excluded algorithms per pool
         - Corrency: List of included or excluded currencies per pool
         - PayoutThreshold[Currency]: pool will allow payout if this amount is reached

      Usage:
         - Edit 'Config\PoolsConfig.json'
         - Add an entry for the pool you want to customize
            - The name must be the pool base name (omit *24hrs or *Plus), e.g ZergPool (even if you have configured ZergPoolPlus in the pool list)
            - (**careful with json formatting ;)**

      Note that the GUI only updates default values (valid for ALL pools unless there is pool specific configuration setting defined in 'Config\PoolConfig.json'). Any other changes need to be done manually.

   EarningsAdjustmentFactor

      When using advanced per pool configuration, it is possible to add an earnings adjustment factor for a specific pool. This simply adds a multiplicator on estimations presented by the pool.

      Example scenario:
         - You feel that a pool is exaggerating its estimations by 10% - Set EarningsAdjustmentFactor to 0.9

   Pool Variants

   Poolnames ending in *24hr

      * use calculations based on 24hr prices to get a more stable estimate
      * are NOT sensible to spikes
      * show less switching than following current or plus price estimate
      * lower estimated profitability in exchange for less switching

   Poolnames ending in *Plus

      * use calculations based on 24hr actual and current estimate prices to get a more realistic estimate
      * include some trust index based on past 1hr current estimate variation from 24hr
      * are NOT sensible to spikes
      * show less switching than following current estimate and more switching than following the 24hr actual
      * better estimated profitability

   Balances Tracking

      Displays available balances and an estimation of when the pool payment threshold will be reached.
      Supported pools:
         - HashCryptos
         - Hiveon (*)
         - MiningDutch
         - MiningPoolHub
         - NiceHash (internal & external wallet)
         - ProHashing
         - ZergPool
         - Zpool
      (*) Pool does not support auto-exchange to other currencies.

      If mining more than one pool, UG-Miner shows stats for all supported pools.
      Press key 'b' in the console window to show/hide earnings.

   Support for running multiple instances (not recommended)

      **Experimental**
      More than one instance of UG-Miner can run on the same rig
      Each instance must be placed in its own directory
      Must use non-overlapping port ranges (configuration item '$APIport')
      Do not use the same miner devices in more than one instance (this will give invalid hash rate
      & power consumption readings causing incorrect best miner selection)

   Miner Switching Log

      A simple miner switching log in csv format  is writte to '[UG-Miner directory]\Logs\SwitchingLog.csv'.

   Console Display Options

      Use -UIStyle light or -UIStyle full in config.json
         Full = Usual display (Default)
         Light = Show only current mining info
      UIStyle automatically switches to full during benchmarking.

      In session console the following hot keys are supported:
 
      1: Toggle Listing pool balances (currently off)
      2: Toggle Listing all optimal miners (currently off)
      3: Toggle UI style [full or light] (currently light)

      a: Toggle 'Accuracy' column visibility (currently on)
      c: Toggle 'PowerCost' column visibility (currently on)
      e: Toggle 'Earnings' column visibility (currently off)
      f: Toggle Pool 'Fees' column visibility (currently on)
      i: Toggle 'EarningBias' column visibility (currently on)
      m: Toggle Miner 'Fees' column visibility (currently on)
      n: Toggle 'CoinName' column visibility (currently on)
      p: Toggle 'Pool' column visibility (currently on)
      r: Toggle 'ProfitBias' column visibility (currently on)
      t: Toggle 'Profit' column visibility (currently off)
      u: Toggle 'User' column visibility (currently on)
      w: Toggle 'PowerConsumption' column visibility (currently on)
      y: Toggle 'Currency' column visibility (currently on)

***Requirements***

PowerShell Version 7.x is required:

UG-Miner works best with the latest PWSH version 7.2.x. Versions 7.3.x and later have a memory leak and are therefore not recommended.

[Download Installer for version 7.2.21](https://github.com/PowerShell/PowerShell/releases/download/v7.2.19/PowerShell-7.2.21-win-x64.msi)

**Some miners may need 'Visual C+ RunTimes download/extract, run install_all.bat file**

[Visual C+ RunTimes](https://github.com/UselessGuru/UG-Miner-Extras/releases/download/Visual-C-Runtimes-All-in-One-Sep-2019/Visual-C-Runtimes-All-in-One-Sep-2019.zip)

**Virtual memory settings**

When running multiple cards its recommended to increase Virtual Memory. 64GB is optimal.

**Recommended/optimal Windows Nvidia driver**

[Windows Nvidia driver 537.42](https://us.download.nvidia.com/Windows/537.42/537.42-desktop-win10-win11-64bit-international-dch-whql.exe)
If you use older drivers some miners will not be available.

**Recommended/optimal Windows AMD driver**

[Windows 10/11 AMD GPU Driver 7/25/2023](https://www.amd.com/en/support)

   UG-Miner is currently tested on the following Rigs: 

      Windows11-1xGTX1030-2GB/1xGTX-1060Super-6GB/1xGTX750Ti-2GB/1xRX580-8GB/1xRX5700-8GB/Inteli5-8600K
      Windows11-1xMX250/Inteli10-10210u

*****

Licensed under the GNU General Public License v3.0
Permissions of this strong copyleft license are conditioned on making available complete source code of licensed works and modifications, which include larger works using a licensed work, under the same license.
Copyright and license notices must be preserved. Contributors provide an express grant of patent rights.
https://github.com/UselessGuru/UG-Miner/blob/master/LICENSE

Happy Mining
