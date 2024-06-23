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
Version:        6.2.11
Version date:   2024/06/23
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "INTEL" -or ($_.Type -eq "AMD" -and $_.Architecture -match "GCN4|RDNA[1|2|3]") -or $_.OpenCL.ComputeCapability -ge "6.0" }))) { Return }

$URI = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.88/lolMiner_v1.88_Win64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\lolminer.exe"
$DeviceEnumerator = "Bus"

$Algorithms = @(
    [PSCustomObject]@{ Algorithms = @("Autolykos2");                   Type = "AMD"; Fee = @(0.015);      MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(45, 20);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo AUTOLYKOS2" }
    [PSCustomObject]@{ Algorithms = @("BeamV3");                       Type = "AMD"; Fee = @(0.01);       MinMemGiB = 6.0;  MinerSet = 0; WarmupTimes = @(45, 50);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo BEAM-III" }
    [PSCustomObject]@{ Algorithms = @("Blake3");                       Type = "AMD"; Fee = @(0.0075);     MinMemGiB = 2.0;  MinerSet = 1; WarmupTimes = @(45, 20);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo ALEPH" }
    [PSCustomObject]@{ Algorithms = @("Cuckoo29");                     Type = "AMD"; Fee = @(0.02);       MinMemGiB = 8.0;  MinerSet = 0; WarmupTimes = @(45, 70);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo C29AE" }
    [PSCustomObject]@{ Algorithms = @("Cuckaroo29B");                  Type = "AMD"; Fee = @(0.02);       MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(45, 70);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo CR29-40" }
    [PSCustomObject]@{ Algorithms = @("Cuckaroo29S");                  Type = "AMD"; Fee = @(0.02);       MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(45, 70);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo CR29-32" }
    [PSCustomObject]@{ Algorithms = @("Cuckaroo30CTX");                Type = "AMD"; Fee = @(0.025);      MinMemGiB = 7.8;  MinerSet = 2; WarmupTimes = @(45, 70);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo C30CTX" }
#   [PSCustomObject]@{ Algorithms = @("Cuckatoo31");                   Type = "AMD"; Fee = @(0.02);       MinMemGiB = 4.0;  MinerSet = 3; WarmupTimes = @(60, 80);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo C31" } # ASIC
#   [PSCustomObject]@{ Algorithms = @("Cuckatoo32");                   Type = "AMD"; Fee = @(0.02);       MinMemGiB = 4.0;  MinerSet = 3; WarmupTimes = @(60, 70);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo C32" } # ASIC
    [PSCustomObject]@{ Algorithms = @("Equihash1254");                 Type = "AMD"; Fee = @(0.015);      MinMemGiB = 3.0;  MinerSet = 0; WarmupTimes = @(45, 70);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo ZEL --pers ZelProof" }
    [PSCustomObject]@{ Algorithms = @("Equihash1445");                 Type = "AMD"; Fee = @(0.01);       MinMemGiB = 3.0;  MinerSet = 1; WarmupTimes = @(30, 60);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo EQUI144_5" } # FPGA
    [PSCustomObject]@{ Algorithms = @("Equihash1927");                 Type = "AMD"; Fee = @(0.01);       MinMemGiB = 3.0;  MinerSet = 0; WarmupTimes = @(45, 70);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo EQUI192_7" } # FPGA
    [PSCustomObject]@{ Algorithms = @("EtcHash");                      Type = "AMD"; Fee = @(0.007);      MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 70);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo ETCHASH" } # PhoenixMiner-v6.2c is faster
#   [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake3");            Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo ETCHASH --dualmode ALEPHDUAL" } # No hashrate for second algorithm
#   [PSCustomObject]@{ Algorithms = @("EtcHash", "HeavyHashKarlsen");  Type = "AMD"; Fee = @(0.01, 0);    MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 90);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo ETCHASH --dualmode KARLSENDUAL" } # No hashrate for second algorithm
#   [PSCustomObject]@{ Algorithms = @("EtcHash", "SHA512256d");        Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90);  ExcludeGPUArchitecture = "^GCN4$";                  ExcludePools = @(@(), @());           Arguments = " --algo ETCHASH --dualmode RXDDUAL" } # https://github.com/Lolliedieb/lolMiner-releases/issues/1986
    [PSCustomObject]@{ Algorithms = @("Ethash");                       Type = "AMD"; Fee = @(0.007);      MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 70);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
#   [PSCustomObject]@{ Algorithms = @("Ethash", "Blake3");             Type = "AMD"; Fee = @(0.01, 0);    MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo ETHASH --dualmode ALEPHDUAL" } #
#   [PSCustomObject]@{ Algorithms = @("Ethash", "HeavyHashKarlsen");   Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 90);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo ETHASH --dualmode KARLSENDUAL" } # No hashrate for second algorithm
#   [PSCustomObject]@{ Algorithms = @("Ethash", "SHA512256d");         Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90);  ExcludeGPUArchitecture = "^GCN4$";                  ExcludePools = @(@(), @());           Arguments = " --algo ETHASH --dualmode RXDDUAL" } # https://github.com/Lolliedieb/lolMiner-releases/issues/1986
    [PSCustomObject]@{ Algorithms = @("EthashB3");                     Type = "AMD"; Fee = @(0.01);       MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 70);  ExcludeGPUArchitecture = "^_GCN4$";                  ExcludePools = @(@("ZergPool"), @()); Arguments = " --algo ETHASHB_3" } # https://github.com/Lolliedieb/lolMiner-releases/issues/1992
    [PSCustomObject]@{ Algorithms = @("EthashB3", "Blake3");           Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90);  ExcludeGPUArchitecture = "^_GCN4$";                  ExcludePools = @(@("ZergPool"), @()); Arguments = " --algo ETHASHB_3 --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "HeavyHashKarlsen"); Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 90);  ExcludeGPUArchitecture = "^_GCN4$";                  ExcludePools = @(@("ZergPool"), @()); Arguments = " --algo ETHASHB_3 --dualmode KARLSENDUAL" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "HeavyHashPyrin");   Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90);  ExcludeGPUArchitecture = "^_GCN4$";                  ExcludePools = @(@("ZergPool"), @()); Arguments = " --algo ETHASHB_3 --dualmode PYRINDUAL" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "SHA512256d");       Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 100); ExcludeGPUArchitecture = "^_GCN4$";                  ExcludePools = @(@("ZergPool"), @()); Arguments = " --algo ETHASHB_3 --dualmode RXDDUAL" } # https://github.com/Lolliedieb/lolMiner-releases/issues/1986
    [PSCustomObject]@{ Algorithms = @("Flux");                         Type = "AMD"; Fee = @(0.01);       MinMemGiB = 1.00; MinerSet = 2; WarmupTimes = @(45, 70);  ExcludeGPUArchitecture = "^GCN4$";                  ExcludePools = @(@(), @());           Arguments = " --algo FLUX" }
    [PSCustomObject]@{ Algorithms = @("FishHash");                     Type = "AMD"; Fee = @(0.0075);     MinMemGiB = 6.0;  MinerSet = 1; WarmupTimes = @(45, 20);  ExcludeGPUArchitecture = "";                        ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH" }
    [PSCustomObject]@{ Algorithms = @("FishHash", "Blake3");           Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(45, 90);  ExcludeGPUArchitecture = "^GCN4$|^GCN5\d$";         ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithms = @("FishHash", "HeavyHashKarlsen"); Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(60, 90);  ExcludeGPUArchitecture = "^GCN4$|^GCN5\d$";         ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode KARLSENDUAL" }
    [PSCustomObject]@{ Algorithms = @("FishHash", "HeavyHashPyrin");   Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(45, 90);  ExcludeGPUArchitecture = "^GCN4$|^GCN5\d$|^RDNA1$"; ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode PYRINDUAL" }
    [PSCustomObject]@{ Algorithms = @("FishHash", "SHA512256d");       Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(45, 90);  ExcludeGPUArchitecture = "^GCN4$|^GCN5\d$";         ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode RXDDUAL" }
    [PSCustomObject]@{ Algorithms = @("HeavyHashKarlsen");             Type = "AMD"; Fee = @(0.0075);     MinMemGiB = 2.0;  MinerSet = 1; WarmupTimes = @(90, 30);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo KARLSEN" }
    [PSCustomObject]@{ Algorithms = @("HeavyHashPyrin");               Type = "AMD"; Fee = @(0.0075);     MinMemGiB = 2.0;  MinerSet = 1; WarmupTimes = @(90, 30);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo PYRIN" }
    [PSCustomObject]@{ Algorithms = @("IronFish");                     Type = "AMD"; Fee = @(0.0075);     MinMemGiB = 2.0;  MinerSet = 1; WarmupTimes = @(45, 20);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@("NiceHash"), @()); Arguments = " --algo IRONFISH" }
    [PSCustomObject]@{ Algorithms = @("NexaPow");                      Type = "AMD"; Fee = @(0.02);       MinMemGiB = 3.0;  MinerSet = 2; WarmupTimes = @(30, 60);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo NEXA" }
    [PSCustomObject]@{ Algorithms = @("SHA512256d");                   Type = "AMD"; Fee = @(0.0075);     MinMemGiB = 1.0;  MinerSet = 0; WarmupTimes = @(60, 70);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo RADIANT" }
    [PSCustomObject]@{ Algorithms = @("UbqHash");                      Type = "AMD"; Fee = @(0.007);      MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 70);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo UBQHASH" }
    [PSCustomObject]@{ Algorithms = @("UbqHash", "Blake3");            Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 90);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo UBQHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithms = @("UbqHash", "HeavyHashKarlsen");  Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 90);  ExcludeGPUArchitecture = " ";                       ExcludePools = @(@(), @());           Arguments = " --algo UBQHASH --dualmode KARLSENDUAL" } # No hashrate for second algorithm
    [PSCustomObject]@{ Algorithms = @("UbqHash", "SHA512256d");        Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 90);  ExcludeGPUArchitecture = "^GCN4$";                  ExcludePools = @(@(), @());           Arguments = " --algo UBQHASH --dualmode RXDDUAL" } # https://github.com/Lolliedieb/lolMiner-releases/issues/1986

    [PSCustomObject]@{ Algorithms = @("Autolykos2");   Type = "INTEL"; Fee = @(0.015); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = " "; ExcludePools = @(@(), @()); AutoCoinPers = "";             Arguments = " --algo AUTOLYKOS2" }
    [PSCustomObject]@{ Algorithms = @("BeamV3");       Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = " "; ExcludePools = @(@(), @()); AutoCoinPers = "";             Arguments = " --algo BEAM-III" }
    [PSCustomObject]@{ Algorithms = @("Equihash1254"); Type = "INTEL"; Fee = @(0.015); MinMemGiB = 3.0;  MinerSet = 0; WarmupTimes = @(45, 70); ExcludeGPUArchitecture = " "; ExcludePools = @(@(), @()); AutoCoinPers = " --pers auto"; Arguments = " --algo ZEL --pers ZelProof" }
    [PSCustomObject]@{ Algorithms = @("Equihash1445"); Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 3.0;  MinerSet = 1; WarmupTimes = @(30, 60); ExcludeGPUArchitecture = " "; ExcludePools = @(@(), @()); AutoCoinPers = " --pers auto"; Arguments = " --algo EQUI144_5" } # FPGA
    [PSCustomObject]@{ Algorithms = @("EtcHash");      Type = "INTEL"; Fee = @(0.007); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = " "; ExcludePools = @(@(), @()); AutoCoinPers = "";             Arguments = " --algo ETCHASH" } # PhoenixMiner-v6.2c is faster

    [PSCustomObject]@{ Algorithms = @("Autolykos2");                   Type = "NVIDIA"; Fee = @(0.015);      MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo AUTOLYKOS2" }
    [PSCustomObject]@{ Algorithms = @("Blake3");                       Type = "NVIDIA"; Fee = @(0.075);      MinMemGiB = 2.0;  MinerSet = 1; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ALEPH" }
    [PSCustomObject]@{ Algorithms = @("BeamV3");                       Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 3.0;  MinerSet = 2; WarmupTimes = @(45, 50); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo BEAM-III" } # NBMiner-v42.3 is fastest
    [PSCustomObject]@{ Algorithms = @("Cuckoo29");                     Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 8.0;  MinerSet = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo C29AE" }
    [PSCustomObject]@{ Algorithms = @("Cuckaroo29B");                  Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo CR29-40" }
    [PSCustomObject]@{ Algorithms = @("Cuckaroo29S");                  Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo CR29-32" }
    [PSCustomObject]@{ Algorithms = @("Cuckaroo30CTX");                Type = "NVIDIA"; Fee = @(0.025);      MinMemGiB = 8.0;  MinerSet = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo C30CTX" }
#   [PSCustomObject]@{ Algorithms = @("Cuckatoo31");                   Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 4.0;  MinerSet = 3; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo C31" } # ASIC
#   [PSCustomObject]@{ Algorithms = @("Cuckatoo32");                   Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 4.0;  MinerSet = 3; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo C32" } # ASIC
    [PSCustomObject]@{ Algorithms = @("Equihash1254");                 Type = "NVIDIA"; Fee = @(0.015);      MinMemGiB = 3.0;  MinerSet = 1; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ZEL --pers ZelProof" } # MiniZ-v2.4.d is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithms = @("Equihash1445");                 Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 3.0;  MinerSet = 1; WarmupTimes = @(30, 60); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo EQUI144_5" } # FPGA
    [PSCustomObject]@{ Algorithms = @("Equihash2109");                 Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo EQUI210_9" }
    [PSCustomObject]@{ Algorithms = @("EtcHash");                      Type = "NVIDIA"; Fee = @(0.007);      MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETCHASH" } # PhoenixMiner-v6.2c is faster
#   [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake3");            Type = "NVIDIA"; Fee = @(0.01, 0);    MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETCHASH --dualmode ALEPHDUAL --maxdualimpact *" } # No hashrate for second algorithm
#   [PSCustomObject]@{ Algorithms = @("EtcHash", "HeavyHashKarlsen");  Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 90); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETCHASH --dualmode KARLSENDUAL --maxdualimpact *" } # No hashrate for second algorithm
#   [PSCustomObject]@{ Algorithms = @("EtcHash", "SHA512256d");        Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETCHASH --dualmode RXDDUAL --maxdualimpact *" } # https://github.com/Lolliedieb/lolMiner-releases/issues/1986
    [PSCustomObject]@{ Algorithms = @("Ethash");                       Type = "NVIDIA"; Fee = @(0.007);      MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
#   [PSCustomObject]@{ Algorithms = @("Ethash", "Blake3");             Type = "NVIDIA"; Fee = @(0.01, 0);    MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETHASH --dualmode ALEPHDUAL --maxdualimpact *" } # No hashrate for second algorithm
#   [PSCustomObject]@{ Algorithms = @("Ethash", "HeavyHashKarlsen");   Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 90); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETHASH --dualmode KARLSENDUAL --maxdualimpact *" } # No hashrate for second algorithm
#   [PSCustomObject]@{ Algorithms = @("Ethash", "SHA512256d");         Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETHASH --dualmode RXDDUAL --maxdualimpact *" } # https://github.com/Lolliedieb/lolMiner-releases/issues/1986
    [PSCustomObject]@{ Algorithms = @("EthashB3");                     Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 70); ExcludeGPUArchitecture = " ";                ExcludePools = @(@("ZergPool"), @()); Arguments = " --algo E_THASHB3" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "Blake3");           Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = " ";                ExcludePools = @(@("ZergPool"), @()); Arguments = " --algo E_THASHB3 --dualmode ALEPHDUAL --maxdualimpact *" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "HeavyHashPyrin");   Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = " ";                ExcludePools = @(@("ZergPool"), @()); Arguments = " --algo E_THASHB3 --dualmode PYRINDUAL --maxdualimpact *" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "HeavyHashKarlsen"); Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = " ";                ExcludePools = @(@("ZergPool"), @()); Arguments = " --algo E_THASHB3 --dualmode KARLSENDUAL --maxdualimpact *" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "SHA512256d");       Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 90); ExcludeGPUArchitecture = " ";                ExcludePools = @(@("ZergPool"), @()); Arguments = " --algo E_THASHB3 --dualmode RXDDUAL --maxdualimpact *" }
    [PSCustomObject]@{ Algorithms = @("FishHash");                     Type = "NVIDIA"; Fee = @(0.0075);     MinMemGiB = 6.0;  MinerSet = 1; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH" }
    [PSCustomObject]@{ Algorithms = @("FishHash", "Blake3");           Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(60, 90); ExcludeGPUArchitecture = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode ALEPHDUAL --maxdualimpact *" }
    [PSCustomObject]@{ Algorithms = @("FishHash", "HeavyHashPyrin");   Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(60, 90); ExcludeGPUArchitecture = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode PYRINDUAL --maxdualimpact *" }
    [PSCustomObject]@{ Algorithms = @("FishHash", "HeavyHashKarlsen"); Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(60, 90); ExcludeGPUArchitecture = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode KARLSENDUAL --maxdualimpact *" }
    [PSCustomObject]@{ Algorithms = @("FishHash", "SHA512256d");       Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(60, 90); ExcludeGPUArchitecture = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode RXDDUAL --maxdualimpact *" }
    [PSCustomObject]@{ Algorithms = @("HeavyHashKarlsen");             Type = "NVIDIA"; Fee = @(0.0075);     MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = " ";                 ExcludePools = @(@(), @());           Arguments = " --algo KARLSEN" }
    [PSCustomObject]@{ Algorithms = @("HeavyHashPyrin");               Type = "NVIDIA"; Fee = @(0.0075);     MinMemGiB = 2.0;  MinerSet = 1; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = " ";                 ExcludePools = @(@(), @());           Arguments = " --algo PYRIN" }
    [PSCustomObject]@{ Algorithms = @("IronFish");                     Type = "NVIDIA"; Fee = @(0.0075);     MinMemGiB = 2.0;  MinerSet = 1; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo IRONFISH" }
    [PSCustomObject]@{ Algorithms = @("NexaPow");                      Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 3.0;  MinerSet = 1; WarmupTimes = @(30, 60); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo NEXA" }
    [PSCustomObject]@{ Algorithms = @("SHA512256d");                   Type = "NVIDIA"; Fee = @(0.0075);     MinMemGiB = 1.0;  MinerSet = 2; WarmupTimes = @(60, 20); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo RADIANT" } 
    [PSCustomObject]@{ Algorithms = @("UbqHash");                      Type = "NVIDIA"; Fee = @(0.007);      MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo UBQHASH" }
    [PSCustomObject]@{ Algorithms = @("UbqHash", "Blake3");            Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo UBQHASH --dualmode ALEPHDUAL --maxdualimpact *" }
#   [PSCustomObject]@{ Algorithms = @("UbqHash", "HeavyHashKarlsen");  Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo UBQHASH --dualmode KARLSENDUAL --maxdualimpact *" } # No hashrate for second algorithm
#   [PSCustomObject]@{ Algorithms = @("UbqHash", "SHA512256d");        Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 90); ExcludeGPUArchitecture = " ";                ExcludePools = @(@(), @());           Arguments = " --algo UBQHASH --dualmode RXDDUAL --maxdualimpact *" } # https://github.com/Lolliedieb/lolMiner-releases/issues/1986
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms.Where({ -not $_.Algorithms[1] }).ForEach({ $_.Algorithms += "" })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] -and $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]].Name -notin $_.ExcludePools[0] })
$Algorithms = $Algorithms.Where({ $MinerPools[1][$_.Algorithms[1]].Name -notin $_.ExcludePools[1] })

If ($Algorithms) { 

    # MaxDualImpact for 2. algorithm; The maximum impact on the eth mining speed in dual mining in %. Default is * for automatic mode
    $MaxDualImpactValues = @("*", 5, 10, 15, 20)

    # Build command sets for MaxDualImpact (only seems to work with AMD, no 2nd hashrates for GTX1660Super when --maxdualimpact is a number)
    $Algorithms = $Algorithms.ForEach(
        { 
            If ($_.Type -eq "AMD" -and $_.Algorithms[1]) { 
                ForEach ($MaxDualImpact in $MaxDualImpactValues) { 
                    $_ | Add-Member MaxDualImpact $MaxDualImpact -Force
                    $_.PsObject.Copy()
                }
            }
            Else { 
                $_.PsObject.Copy()
            }
        }
    )

    ($Devices | Select-Object Type, Model -Unique).ForEach(
        { 
            If ($MinerDevices = $Devices | Where-Object Type -eq $_.Type | Where-Object Model -EQ $_.Model) { 
                $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

                ($Algorithms | Where-Object Type -EQ $_.Type).ForEach(
                    { 
                        $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
                        If ($AvailableMinerDevices = $MinerDevices.Where({ $_.Architecture -notmatch $ExcludeGPUArchitecture })) { 

                            $ExcludePools = $_.ExcludePools
                            ForEach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $_.Name -notin $ExcludePools[0] })) { 
                                ForEach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $_.Name -notin $ExcludePools[1] })) { 

                                    $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB
                                    # Windows 10 requires more memory on some algos
                                    If ($_.Algorithms[0] -match '^Cuckaroo.*$|^Cuckoo.*$' -and ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0")) { $MinMemGiB += 1 }
                                    If ($AvailableMinerDevices = $AvailableMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($Pool0.AlgorithmVariant)$(If ($Pool1) { "&$($Pool1.AlgorithmVariant)" })$(If ($_.MaxDualImpact -gt 0) { "-$($_.MaxDualImpact)" })"

                                        $Arguments = $_.Arguments
                                        $CoinPers = If ($_.Algorithms[0] -in @("Equihash1445", "Equihash1927")) { Get-EquihashCoinPers -Command " --pers " -Currency $Pool0.Currency -DefaultCommand "" } Else { "" }
                                        If ($CoinPers) { $Arguments += $CoinPers }
                                        If ($_.Algorithms[0] -notin @("Equihash1445", "Equihash1927") -or $CoinPers) { 
                                            $Arguments += " --pool $($Pool0.Host):$(($Pool0.PoolPorts | Select-Object -Last 1))"
                                            $Arguments += " --user $($Pool0.User)$(If ($Pool0.WorkerName -and $Pool0.User -notmatch "\.$($Pool0.WorkerName)$") { ".$($Pool0.WorkerName)" })"
                                            $Arguments += " --pass $($Pool0.Pass)"
                                            $Arguments += If ($Pool0.PoolPorts[1]) { " --tls on" } Else { " --tls off" }
                                            $Arguments += Switch ($Pool0.Protocol) { 
                                                "ethproxy"     { " --ethstratum ETHPROXY" }
                                                "ethstratum1"  { " --ethstratum ETHV1" }
                                                "ethstratum2"  { " --ethstratum ETHV1" }
                                                "ethstratumnh" { " --ethstratum ETHV1" }
                                                Default        { "" }
                                            }

                                            If ($_.Algorithms[1]) { 
                                                $Arguments += " --dualpool $($Pool1.Host):$($Pool1.PoolPorts | Select-Object -Last 1)"
                                                $Arguments += " --dualuser $($Pool1.User)$(If ($Pool1.WorkerName -and $Pool1.User -notmatch "\.$($Pool1.WorkerName)$") { ".$($Pool1.WorkerName)" })"
                                                $Arguments += " --dualpass $($Pool1.Pass)"
                                                If ($_.MaxDualImpact) { $Arguments += " --maxdualimpact $($_.MaxDualImpact)" }
                                                $Arguments += If ($Pool1.PoolPorts[1]) { " --dualtls on" } Else { " --dualtls off" }
                                            }

                                            [PSCustomObject]@{ 
                                                API         = "lolMiner"
                                                Arguments   = "$Arguments --log off --apiport $MinerAPIPort --shortstats 1 --longstats 5 --digits 6 --watchdog exit --dns-over-https 1 --devicesbypcie --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0}:0' -f $_ }) -join ',')"
                                                DeviceNames = $AvailableMinerDevices.Name
                                                Fee         = $_.Fee # Dev fee
                                                MinerSet    = $_.MinerSet
                                                MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                                                Name        = $MinerName
                                                Path        = $Path
                                                Port        = $MinerAPIPort
                                                Type        = $_.Type
                                                URI         = $URI
                                                WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                                Workers     = @(($Pool0, $Pool1).Where({ $_ }).ForEach({ @{ Pool = $_ } }))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                )
            }
        }
    )
}