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
Version:        6.7.7
Version date:   2025/12/12
#>

if (-not ($Devices = $Session.EnabledDevices.where({ $_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 2.0" -and $_.Architecture -ne "RDNA3" }))) { return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/TeamRedMiner/teamredminer-v0.10.21-win.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\teamredminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    @{ Algorithms = @("Autolykos2", "");                   SecondaryAlgorithmPrefix = "";        Fee = @(0.02);       MinMemGiB = 0.77; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=autolykos2" }
    @{ Algorithms = @("Autolykos2", "Blake3");             SecondaryAlgorithmPrefix = "alph";    Fee = @(0.02, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo=autolykos2" }
    @{ Algorithms = @("Autolykos2", "FishHash");           SecondaryAlgorithmPrefix = "iron";    Fee = @(0.02, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo=autolykos2" } # Pools with support at this time are Herominers, Flexpool and Kryptex
    @{ Algorithms = @("Autolykos2", "HeavyHashKarlsea");   SecondaryAlgorithmPrefix = "karlsen"; Fee = @(0.02, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=autolykos2" }
#   @{ Algorithms = @("Autolykos2", "HeavyHashKaspa");     SecondaryAlgorithmPrefix = "kas";     Fee = @(0.02, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=autolykos2" } # ASIC
    @{ Algorithms = @("Autolykos2", "HeavyHashPyrin");     SecondaryAlgorithmPrefix = "pyrin";   Fee = @(0.02, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=autolykos2" }
    @{ Algorithms = @("Blake3", "");                       SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@("NiceHash"), @()); Arguments = " --algo=alph" }
    @{ Algorithms = @("Chukwa", "");                       SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=trtl_chukwa" }
    @{ Algorithms = @("Chukwa2", "");                      SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=trtl_chukwa2" }
    @{ Algorithms = @("CryptonightCcx", "");               SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=cn_conceal --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightHeavy", "");             SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=cn_heavy --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightHaven", "");             SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=cn_haven --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightHeavyTube", "");         SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=cn_saber --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
#   @{ Algorithms = @("CryptonightR", "");                 SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=cnr --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" } # ASIC
    @{ Algorithms = @("CryptonightV1", "");                SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=cnv8 --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightDouble", "");            SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 4.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=cnv8_dbl --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" } # XmRig-v6.24.0 is fastest
    @{ Algorithms = @("CryptonightHalf", "");              SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=cnv8_half --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightTurtle", "");            SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=cnv8_trtl --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightRwz", "");               SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=cnv8_rwz --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightUpx", "");               SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 3.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=cnv8_upx2 --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CuckarooD29", "");                  SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=cuckarood29_grin" } # 2GB is not enough
#   @{ Algorithms = @("Cuckatoo31", "");                   SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 3.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=cuckatoo31_grin" } # ASIC
    @{ Algorithms = @("EtcHash", "");                      SecondaryAlgorithmPrefix = "";        Fee = @(0.01);       MinMemGiB = 0.77; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=etchash" } # PhoenixMiner-v6.2c is fastest
    @{ Algorithms = @("EtcHash", "Blake3");                SecondaryAlgorithmPrefix = "alph";    Fee = @(0.01, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo=etchash" }
    @{ Algorithms = @("EtcHash", "FishHash");              SecondaryAlgorithmPrefix = "iron";    Fee = @(0.01, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo=etchash" } # Pools with support at this time are Herominers, Flexpool and Kryptex
    @{ Algorithms = @("EtcHash", "HeavyHashKarlsen");      SecondaryAlgorithmPrefix = "karlsen"; Fee = @(0.01, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=etchash" }
#   @{ Algorithms = @("EtcHash", "HeavyHashKaspa");        SecondaryAlgorithmPrefix = "kas";     Fee = @(0.01, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=etchash" } # ASIC
    @{ Algorithms = @("EtcHash", "HeavyHashPyrin");        SecondaryAlgorithmPrefix = "pyrin";   Fee = @(0.01, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=etchash" }
    @{ Algorithms = @("Ethash", "");                       SecondaryAlgorithmPrefix = "";        Fee = @(0.01);       MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=ethash" } # PhoenixMiner-v6.2c is fastest
    @{ Algorithms = @("Ethash", "Blake3");                 SecondaryAlgorithmPrefix = "alph";    Fee = @(0.01, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo=ethash" }
    @{ Algorithms = @("Ethash", "FishHash");               SecondaryAlgorithmPrefix = "iron";    Fee = @(0.01, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo=ethash" } # Pools with support at this time are Herominers, Flexpool and Kryptex
    @{ Algorithms = @("Ethash", "HeavyHashKarlsen");       SecondaryAlgorithmPrefix = "karlsen"; Fee = @(0.01, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=ethash" }
#   @{ Algorithms = @("Ethash", "HeavyHashKaspa");         SecondaryAlgorithmPrefix = "kas";     Fee = @(0.01, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=ethash" } # ASIC
    @{ Algorithms = @("Ethash", "HeavyHashPyrin");         SecondaryAlgorithmPrefix = "pyrin";   Fee = @(0.01, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=ethash" }
    @{ Algorithms = @("EthashSHA256", "");                 SecondaryAlgorithmPrefix = "";        Fee = @(0.01);       MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=abel" }
    @{ Algorithms = @("EthashSHA256", "Blake3");           SecondaryAlgorithmPrefix = "alph";    Fee = @(0.01, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo=abel" }
    @{ Algorithms = @("EthashSHA256", "FishHash");         SecondaryAlgorithmPrefix = "iron";    Fee = @(0.01, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo=abel" }
    @{ Algorithms = @("EthashSHA256", "HeavyHashKarlsen"); SecondaryAlgorithmPrefix = "karlsen"; Fee = @(0.01, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=abel" }
#   @{ Algorithms = @("EthashSHA256", "HeavyHashKaspa");   SecondaryAlgorithmPrefix = "kas";     Fee = @(0.01, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=abel" } # ASIC
    @{ Algorithms = @("EthashSHA256", "HeavyHashPyrin");   SecondaryAlgorithmPrefix = "pyrin";   Fee = @(0.01, 0.01); MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=abel" }
    @{ Algorithms = @("FiroPow", "");                      SecondaryAlgorithmPrefix = "";        Fee = @(0.02);       MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = "^RDNA3$";         ExcludePools = @(@(), @());           Arguments = " --algo=firopow" } # Wildrig-v0.46.5 is fastest on Polaris
    @{ Algorithms = @("FishHash", "");                     SecondaryAlgorithmPrefix = "";        Fee = @(0.01);       MinMemGiB = 0.77; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@("NiceHash"), @()); Arguments = " --algo=ironfish" } # Pools with support at this time are Herominers, Flexpool and Kryptex
    @{ Algorithms = @("KawPow", "");                       SecondaryAlgorithmPrefix = "";        Fee = @(0.02);       MinMemGiB = 0.77; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=kawpow" } # Wildrig-v0.46.5 is fastest on Polaris
    @{ Algorithms = @("HeavyHashKarlsen", "");             SecondaryAlgorithmPrefix = "";        Fee = @(0.01);       MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=karlsen" }
#   @{ Algorithms = @("HeavyHashKaspa", "");               SecondaryAlgorithmPrefix = "";        Fee = @(0.01);       MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=kas" } # ASIC
    @{ Algorithms = @("HeavyHashPyrin", "");               SecondaryAlgorithmPrefix = "";        Fee = @(0.01);       MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = " --algo=pyrin" }
#   @{ Algorithms = @("Lyra2Z", "");                       SecondaryAlgorithmPrefix = "";        Fee = @(0.03);       MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=lyra2z" } # ASIC
#   @{ Algorithms = @("Lyra2RE3", "");                     SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=lyra2rev3" } # ASIC
#   @{ Algorithms = @("MTP", "");                          SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 2.0;  WarmupTimes = @(45, 45); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=mtp" } # Algorithm is dead
    @{ Algorithms = @("Nimiq", "");                        SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 4.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA3$";  ExcludePools = @(@(), @());           Arguments = " --algo=nimiq" }
    @{ Algorithms = @("Phi2", "");                         SecondaryAlgorithmPrefix = "";        Fee = @(0.03);       MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=phi2" }
    @{ Algorithms = @("VertHash", "");                     SecondaryAlgorithmPrefix = "";        Fee = @(0.02);       MinMemGiB = 4.0;  WarmupTimes = @(75, 15); ExcludeGPUarchitectures = "^GCN1$";          ExcludePools = @(@(), @());           Arguments = " --algo=verthash --verthash_file=..\.$($Session.VertHashDatPath)" }
#   @{ Algorithms = @("X16r", "");                         SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 4.0;  WarmupTimes = @(60, 60); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=x16r" } # ASIC
    @{ Algorithms = @("X16rv2", "");                       SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 4.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=x16rv2" }
    @{ Algorithms = @("X16s", "");                         SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=x16s" }
    @{ Algorithms = @("X16rt", "");                        SecondaryAlgorithmPrefix = "";        Fee = @(0.025);      MinMemGiB = 2.0;  WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^GCN1$|^RDNA\d$"; ExcludePools = @(@(), @());           Arguments = " --algo=x16rt" } # FPGA
)

$Algorithms = $Algorithms.where({ $MinerPools[0][$_.Algorithms[0]] })
$Algorithms = $Algorithms.where({ -not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]] })
$Algorithms = $Algorithms.where({ $_.Algorithms[0] -ne "EtcHash" -or $MinerPools[0][$_.Algorithms[0]].Epoch -lt 383 }) # Miner supports EtcHash up to epoch 382

if ($Algorithms) { 

    ($Devices | Sort-Object -Property Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.where({ $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    if ($SupportedMinerDevices = $MinerDevices.where({ $_.Architecture -notmatch $ExcludeGPUarchitectures })) { 

                        if ($_.Algorithms -contains "VertHash" -and (Get-Item -Path $Session.VertHashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                            $PrerequisitePath = $Session.VertHashDatPath
                            $PrerequisiteURI = "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/VertHashDataFile/VertHash.dat"
                        }
                        else { 
                            $PrerequisitePath = ""
                            $PrerequisiteURI = ""
                        }

                        $ExcludePools = $_.ExcludePools
                        foreach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].where({ $ExcludePools[0] -notcontains $_.Name })) { 
                            foreach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].where({ $ExcludePools[1] -notcontains $_.Name })) { 

                                $MinMemGiB = $_.MinMemGiB + $Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB
                                if ($AvailableMinerDevices = $SupportedMinerDevices.where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(if ($Pool1) { "&$($Pool1.AlgorithmVariant)" })"

                                    $Arguments = "$($_.Arguments) --pool_force_ensub --url=$(if ($Pool0.PoolPorts[1]) { "stratum+ssl" } else { "stratum+tcp" })://$($Pool0.Host):$($Pool0.PoolPorts | Select-Object -Last 1)"
                                    switch ($Pool0.Protocol) { 
                                        "ethstratumnh" { $Arguments += " --eth_stratum_mode=nicehash"; break }
                                    }
                                    $Arguments += " --user=$($Pool0.User)$(if ($Pool0.WorkerName -and $Pool0.User -notmatch "\.$($Pool0.WorkerName)$") { ".$($Pool0.WorkerName)" }) --pass=$($Pool0.Pass)"

                                    if ($_.SecondaryAlgorithmPrefix) { 
                                        $Arguments += " --$($_.SecondaryAlgorithmPrefix)_start"
                                        $Arguments += " --url=$(if ($Pool1.PoolPorts[1]) { "stratum+ssl" } else { "stratum+tcp" })://$($Pool1.Host):$($Pool1.PoolPorts | Select-Object -Last 1)"
                                        $Arguments += " --user=$($Pool1.User)$(if ($Pool1.WorkerName -and $Pool1.User -notmatch "\.$($Pool1.WorkerName)$") { ".$($Pool1.WorkerName)" })"
                                        $Arguments += " --pass=$($Pool1.Pass)"
                                        $Arguments += " --$($_.SecondaryAlgorithmPrefix)_end"
                                    }
                                    if ($_.Algorithms[0] -match '^Et(c)hash.+' -and $AvailableMinerDevices.Model -notmatch "^Radeon RX [0-9]{3} .+") { $_.Fee = @(0.0075) } # Polaris cards 0.75%

                                    [PSCustomObject]@{ 
                                        API              = "Xgminer"
                                        Arguments        = "$Arguments --no_gpu_monitor --init_style=3 --hardware=gpu --api_listen=127.0.0.1:$MinerAPIPort --devices=$(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:d}' -f $_ }) -join ',')"
                                        DeviceNames      = $AvailableMinerDevices.Name
                                        Fee              = $_.Fee # Dev fee
                                        Name             = $MinerName
                                        Path             = $Path
                                        Port             = $MinerAPIPort
                                        PrerequisitePath = $PrerequisitePath
                                        PrerequisiteURI  = $PrerequisiteURI
                                        Type             = "AMD"
                                        URI              = $URI
                                        WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                        Workers          = @(($Pool0, $Pool1).where({ $_ }).ForEach({ @{ Pool = $_ } }))
                                    }
                                }
                            }
                        }
                    }
                }
            )
        }
    )
}