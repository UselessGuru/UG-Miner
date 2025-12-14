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
Version:        6.7.8
Version date:   2025/12/14
#>

# Improved performance and efficiency of Sha3x code for RDNA1 and newer AMD cards as well as Turing and newer Nvidia cards by 1-3% depending on the actual hardware architecture.
# Added a hint that oc was reset when miner closes and it actually had set options that got successfully reset.
# Fixed a bug when mining Grin Cuckatoo-32 not submitting shares in 1.96(a)

if (-not ($Devices = $Session.EnabledDevices.where({ $_.Type -eq "INTEL" -or ($_.Type -eq "AMD" -and $_.Architecture -match "GCN4|RDNA[1|2|3]") -or $_.OpenCL.ComputeCapability -ge "6.0" }))) { return }

$URI = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.98a/lolMiner_v1.98a_Win64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\lolminer.exe"
$DeviceEnumerator = "Bus"

$Algorithms = @(
    @{ Algorithms = @("Autolykos2", "");                 Type = "AMD"; Fee = @(0.015);       MinMemGiB = 1.24; WarmupTimes = @(45, 20);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo AUTOLYKOS2" }
    @{ Algorithms = @("Autolykos2", "HeavyHashPyrinV2"); Type = "AMD"; Fee = @(0.015, 0.01); MinMemGiB = 1.24; WarmupTimes = @(45, 20);  ExcludeGPUarchitectures = "^GCN\d+$"; ExcludePools = @(@(), @());           Arguments = " --algo AUTOLYKOS2 --dualmode PYRINV2DUAL" }
    @{ Algorithms = @("Autolykos2", "SHA3x");            Type = "AMD"; Fee = @(0.015, 0.01); MinMemGiB = 1.24; WarmupTimes = @(45, 20);  ExcludeGPUarchitectures = "^GCN\d+$"; ExcludePools = @(@(), @());           Arguments = " --algo AUTOLYKOS2 --dualmode SHA3XDUAL" }
    @{ Algorithms = @("BeamV3", "");                     Type = "AMD"; Fee = @(0.01);        MinMemGiB = 6.0;  WarmupTimes = @(45, 50);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo BEAM-III" }
    @{ Algorithms = @("Blake3", "");                     Type = "AMD"; Fee = @(0.0075);      MinMemGiB = 2.0;  WarmupTimes = @(45, 20);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo ALEPH" }
    @{ Algorithms = @("Cuckoo29", "");                   Type = "AMD"; Fee = @(0.02);        MinMemGiB = 8.0;  WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@("NiceHash"), @()); Arguments = " --algo C29AE" }
    @{ Algorithms = @("Cuckaroo29", "");                 Type = "AMD"; Fee = @(0.02);        MinMemGiB = 6.0;  WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo CR29" }
    @{ Algorithms = @("Cuckaroo29B", "");                Type = "AMD"; Fee = @(0.02);        MinMemGiB = 6.0;  WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo CR29-40" }
    @{ Algorithms = @("Cuckaroo29B", "");                Type = "AMD"; Fee = @(0.02);        MinMemGiB = 6.0;  WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo CR29-40" }
    @{ Algorithms = @("Cuckaroo29S", "");                Type = "AMD"; Fee = @(0.02);        MinMemGiB = 6.0;  WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo CR29-32" }
    @{ Algorithms = @("Cuckaroo30CTX", "");              Type = "AMD"; Fee = @(0.025);       MinMemGiB = 7.8;  WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo C30CTX" }
#   @{ Algorithms = @("Cuckatoo31", "");                 Type = "AMD"; Fee = @(0.02);        MinMemGiB = 4.0;  WarmupTimes = @(60, 80);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo C31" } # ASIC
#   @{ Algorithms = @("Cuckatoo32", "");                 Type = "AMD"; Fee = @(0.02);        MinMemGiB = 4.0;  WarmupTimes = @(60, 70);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo C32" } # ASIC
    @{ Algorithms = @("Equihash1254", "");               Type = "AMD"; Fee = @(0.015);       MinMemGiB = 3.0;  WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo ZEL --pers ZelProof" }
    @{ Algorithms = @("Equihash1445", "");               Type = "AMD"; Fee = @(0.01);        MinMemGiB = 3.0;  WarmupTimes = @(30, 60);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo EQUI144_5" } # FPGA
    @{ Algorithms = @("Equihash1927", "");               Type = "AMD"; Fee = @(0.01);        MinMemGiB = 3.0;  WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo EQUI192_7" } # FPGA
    @{ Algorithms = @("Equihash2109", "");               Type = "AMD"; Fee = @(0.01);        MinMemGiB = 3.0;  WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algp EQUI201_9" }
    @{ Algorithms = @("EtcHash", "");                    Type = "AMD"; Fee = @(0.007);       MinMemGiB = 1.24; WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo ETCHASH" } # PhoenixMiner-v6.2c is faster
    @{ Algorithms = @("EtcHash", "Blake3");              Type = "AMD"; Fee = @(0.01, 0);     MinMemGiB = 1.24; WarmupTimes = @(60, 100); ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo ETCHASH --dualmode ALEPHDUAL" }
    @{ Algorithms = @("Ethash", "");                     Type = "AMD"; Fee = @(0.007);       MinMemGiB = 1.24; WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
    @{ Algorithms = @("Ethash", "Blake3");               Type = "AMD"; Fee = @(0.01, 0);     MinMemGiB = 1.24; WarmupTimes = @(60, 100); ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo ETHASH --dualmode ALEPHDUAL" }
    @{ Algorithms = @("EthashB3", "");                   Type = "AMD"; Fee = @(0.01);        MinMemGiB = 1.24; WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = "^GCN\d+$"; ExcludePools = @(@(), @());           Arguments = " --algo ETHASHB3" } # https://github.com/Lolliedieb/lolMiner-releases/issues/1992
    @{ Algorithms = @("EthashB3", "Blake3");             Type = "AMD"; Fee = @(0.01, 0);     MinMemGiB = 1.24; WarmupTimes = @(45, 90);  ExcludeGPUarchitectures = "^GCN\d+$"; ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo ETHASHB3 --dualmode ALEPHDUAL" }
    @{ Algorithms = @("EthashB3", "SHA512256d");         Type = "AMD"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; WarmupTimes = @(45, 100); ExcludeGPUarchitectures = "^GCN\d+$"; ExcludePools = @(@(), @());           Arguments = " --algo ETHASHB3 --dualmode RXDDUAL" } # https://github.com/Lolliedieb/lolMiner-releases/issues/1986
    @{ Algorithms = @("Flux", "");                       Type = "AMD"; Fee = @(0.01);        MinMemGiB = 1.00; WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = "^GCN\d+$"; ExcludePools = @(@(), @());           Arguments = " --algo FLUX" }
    @{ Algorithms = @("FishHash", "");                   Type = "AMD"; Fee = @(0.0075);      MinMemGiB = 1.24; WarmupTimes = @(45, 20);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH" }
    @{ Algorithms = @("FishHash", "Blake3");             Type = "AMD"; Fee = @(0.01, 0);     MinMemGiB = 1.24; WarmupTimes = @(45, 90);  ExcludeGPUarchitectures = "^GCN\d+$"; ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo FISHHASH --dualmode ALEPHDUAL" }
    @{ Algorithms = @("FishHash", "HeavyHashPyrinV2");   Type = "AMD"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; WarmupTimes = @(45, 90);  ExcludeGPUarchitectures = "^GCN\d+$"; ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode PYRINV2DUAL" }
    @{ Algorithms = @("FishHash", "SHA512256d");         Type = "AMD"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; WarmupTimes = @(45, 90);  ExcludeGPUarchitectures = "^GCN\d+$"; ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode RXDDUAL" }
    @{ Algorithms = @("FishHash", "SHA3x");              Type = "AMD"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; WarmupTimes = @(45, 90);  ExcludeGPUarchitectures = "^GCN\d+$"; ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode SHA3XDUAL" }
    @{ Algorithms = @("HeavyHashKarlsen", "");           Type = "AMD"; Fee = @(0.0075);      MinMemGiB = 2.0;  WarmupTimes = @(90, 30);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo KARLSEN" }
    @{ Algorithms = @("HeavyHashKarlsenV2", "");         Type = "AMD"; Fee = @(0.01);        MinMemGiB = 1.24; WarmupTimes = @(90, 30);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo KARLSENV2" }
    @{ Algorithms = @("HeavyHashKarlsenV2", "SHA3x");    Type = "AMD"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; WarmupTimes = @(90, 30);  ExcludeGPUarchitectures = "^GCN\d+$"; ExcludePools = @(@(), @());           Arguments = " --algo KARLSENV2 --dualmode SHA3XDUAL" }
    @{ Algorithms = @("HeavyHashPyrin", "");             Type = "AMD"; Fee = @(0.01);        MinMemGiB = 2.0;  WarmupTimes = @(90, 30);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo PYRIN" }
    @{ Algorithms = @("HeavyHashPyrinV2", "");           Type = "AMD"; Fee = @(0.01);        MinMemGiB = 2.0;  WarmupTimes = @(90, 30);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo PYRINV2" }
    @{ Algorithms = @("NexaPow", "");                    Type = "AMD"; Fee = @(0.02);        MinMemGiB = 3.0;  WarmupTimes = @(30, 60);  ExcludeGPUarchitectures = "^GCN\d+$"; ExcludePools = @(@(), @());           Arguments = " --algo NEXA" }
    @{ Algorithms = @("Octopus", "");                    Type = "AMD"; Fee = @(0.02);        MinMemGiB = 1.24; WarmupTimes = @(60, 70);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@("NiceHash"), @()); Arguments = " --algo OCTOPUS" }
    @{ Algorithms = @("Octopus", "SHA3x");               Type = "AMD"; Fee = @(0.02, 0.01);  MinMemGiB = 1.24; WarmupTimes = @(60, 70);  ExcludeGPUarchitectures = "^GCN\d+$"; ExcludePools = @(@("NiceHash"), @()); Arguments = " --algo OCTOPUS --dualmode SHA3XDUAL" }
    @{ Algorithms = @("SHA512256d", "");                 Type = "AMD"; Fee = @(0.0075);      MinMemGiB = 1.0;  WarmupTimes = @(60, 70);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo RADIANT" }
    @{ Algorithms = @("SHA3x", "");                      Type = "AMD"; Fee = @(0.01);        MinMemGiB = 1.0;  WarmupTimes = @(60, 70);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo SHA3X" }
    @{ Algorithms = @("UbqHash", "");                    Type = "AMD"; Fee = @(0.007);       MinMemGiB = 1.24; WarmupTimes = @(60, 70);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @());           Arguments = " --algo UBQHASH" }

    @{ Algorithms = @("Autolykos2", "");   Type = "INTEL"; Fee = @(0.015); MinMemGiB = 1.24; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo AUTOLYKOS2" }
    @{ Algorithms = @("BeamV3", "");       Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 6.0;  WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo BEAM-III" }
    @{ Algorithms = @("Equihash1254", ""); Type = "INTEL"; Fee = @(0.015); MinMemGiB = 3.0;  WarmupTimes = @(45, 70); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo ZEL --pers ZelProof" }
    @{ Algorithms = @("Equihash1445", ""); Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 3.0;  WarmupTimes = @(30, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo EQUI144_5" } # FPGA
    @{ Algorithms = @("EtcHash", "");      Type = "INTEL"; Fee = @(0.007); MinMemGiB = 1.24; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo ETCHASH" } # PhoenixMiner-v6.2c is faster

    @{ Algorithms = @("Autolykos2", "");                         Type = "NVIDIA"; Fee = @(0.015);       MinMemGiB = 1.24; WarmupTimes = @(45, 20);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo AUTOLYKOS2" }
    @{ Algorithms = @("Autolykos2", "HeavyHashPyrinV2");         Type = "NVIDIA"; Fee = @(0.015, 0.01); MinMemGiB = 1.24; WarmupTimes = @(45, 20);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo AUTOLYKOS2 --dualmode PYRINV2DUAL --maxdualimpact *" }
    @{ Algorithms = @("Autolykos2", "SHA3x");                    Type = "NVIDIA"; Fee = @(0.015, 0.01); MinMemGiB = 1.24; WarmupTimes = @(45, 20);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo AUTOLYKOS2 --dualmode SHA3XDUAL --maxdualimpact *" }
    @{ Algorithms = @("Blake3", "");                             Type = "NVIDIA"; Fee = @(0.075);       MinMemGiB = 2.0;  WarmupTimes = @(45, 30);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ALEPH" }
    @{ Algorithms = @("BeamV3", "");                             Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 3.0;  WarmupTimes = @(45, 50);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo BEAM-III" }
    @{ Algorithms = @("Cuckoo29", "");                           Type = "NVIDIA"; Fee = @(0.02);        MinMemGiB = 8.0;  WarmupTimes = @(45, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@("NiceHash"), @()); Arguments = " --algo C29AE" }
    @{ Algorithms = @("Cuckaroo29", "");                         Type = "NVIDIA"; Fee = @(0.02);        MinMemGiB = 6.0;  WarmupTimes = @(45, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo CR29" }
    @{ Algorithms = @("Cuckaroo29B", "");                        Type = "NVIDIA"; Fee = @(0.02);        MinMemGiB = 6.0;  WarmupTimes = @(45, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo CR29-40" }
    @{ Algorithms = @("Cuckaroo29S", "");                        Type = "NVIDIA"; Fee = @(0.02);        MinMemGiB = 6.0;  WarmupTimes = @(45, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo CR29-32" }
    @{ Algorithms = @("Cuckaroo30CTX", "");                      Type = "NVIDIA"; Fee = @(0.025);       MinMemGiB = 8.0;  WarmupTimes = @(45, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo C30CTX" }
#   @{ Algorithms = @("Cuckatoo31", "");                         Type = "NVIDIA"; Fee = @(0.02);        MinMemGiB = 4.0;  WarmupTimes = @(60, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo C31" } # ASIC
#   @{ Algorithms = @("Cuckatoo32", "");                         Type = "NVIDIA"; Fee = @(0.02);        MinMemGiB = 4.0;  WarmupTimes = @(60, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo C32" } # ASIC
    @{ Algorithms = @("Equihash1254", "");                       Type = "NVIDIA"; Fee = @(0.015);       MinMemGiB = 3.0;  WarmupTimes = @(45, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ZEL --pers ZelProof" } # MiniZ-v2.5e is fastest, but has 2% miner fee
    @{ Algorithms = @("Equihash1445", "");                       Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 3.0;  WarmupTimes = @(30, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo EQUI144_5" } # FPGA
#   @{ Algorithms = @("Equihash1927", "");                       Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 3.0;  WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo EQUI192_7" } # Does not work on Nvidia
    @{ Algorithms = @("Equihash2109", "");                       Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 2.0;  WarmupTimes = @(45, 30);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo EQUI210_9" }
    @{ Algorithms = @("EtcHash", "");                            Type = "NVIDIA"; Fee = @(0.007);       MinMemGiB = 1.24; WarmupTimes = @(45, 0);   ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETCHASH" } # PhoenixMiner-v6.2c is faster
    @{ Algorithms = @("EtcHash", "Blake3");                      Type = "NVIDIA"; Fee = @(0.01, 0);     MinMemGiB = 1.24; WarmupTimes = @(90, 100); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo ETCHASH --dualmode ALEPHDUAL --maxdualimpact *" }
    @{ Algorithms = @("Ethash", "");                             Type = "NVIDIA"; Fee = @(0.007);       MinMemGiB = 1.24; WarmupTimes = @(45, 0);   ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
    @{ Algorithms = @("Ethash", "Blake3");                       Type = "NVIDIA"; Fee = @(0.01, 0);     MinMemGiB = 1.24; WarmupTimes = @(60, 100); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo ETHASH --dualmode ALEPHDUAL --maxdualimpact *" }
    @{ Algorithms = @("EthashB3", "");                           Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 1.24; WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETHASHB3" }
    @{ Algorithms = @("EthashB3", "Blake3");                     Type = "NVIDIA"; Fee = @(0.01, 0);     MinMemGiB = 1.24; WarmupTimes = @(45, 90);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo ETHASHB3 --dualmode ALEPHDUAL --maxdualimpact *" }
    @{ Algorithms = @("EthashB3", "SHA512256d");                 Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; WarmupTimes = @(60, 90);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETHASHB3 --dualmode RXDDUAL --maxdualimpact *" }
    @{ Algorithms = @("FishHash", "");                           Type = "NVIDIA"; Fee = @(0.0075);      MinMemGiB = 1.24; WarmupTimes = @(45, 20);  ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH" }
    @{ Algorithms = @("FishHash", "Blake3");                     Type = "NVIDIA"; Fee = @(0.01, 0);     MinMemGiB = 1.24; WarmupTimes = @(75, 90);  ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo FISHHASH --dualmode ALEPHDUAL --maxdualimpact *" }
    @{ Algorithms = @("FishHash", "HeavyHashPyrinV2");           Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; WarmupTimes = @(75, 90);  ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode PYRINV2DUAL --maxdualimpact *" }
    @{ Algorithms = @("FishHash", "SHA512256d");                 Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; WarmupTimes = @(75, 90);  ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode RXDDUAL --maxdualimpact *" }
    @{ Algorithms = @("FishHash", "SHA3x");                      Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; WarmupTimes = @(75, 90);  ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode SHA3XDUAL --maxdualimpact *" }
    @{ Algorithms = @("Flux", "");                               Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 1.00; WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo FLUX" }
    @{ Algorithms = @("HeavyHashKarlsen", "");                   Type = "NVIDIA"; Fee = @(0.0075);      MinMemGiB = 2.0;  WarmupTimes = @(30, 0);   ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo KARLSEN" }
    @{ Algorithms = @("HeavyHashKarlsenV2", "");                 Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 1.24; WarmupTimes = @(30, 0);   ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo KARLSENV2" }
    @{ Algorithms = @("HeavyHashKarlsenV2", "HeavyHashPyrinV2"); Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; WarmupTimes = @(30, 0);   ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo KARLSENV2 --dualmode PYRINV2DUAL --maxdualimpact *" }
    @{ Algorithms = @("HeavyHashKarlsenV2", "SHA3x");            Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; WarmupTimes = @(30, 0);   ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo KARLSENV2 --dualmode SHA3XDUAL --maxdualimpact *" }
    @{ Algorithms = @("HeavyHashPyrin", "");                     Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 2.0;  WarmupTimes = @(30, 0);   ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo PYRIN" }
    @{ Algorithms = @("HeavyHashPyrinV2", "");                   Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 2.0;  WarmupTimes = @(30, 0);   ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo PYRINV2" }
    @{ Algorithms = @("NexaPow", "");                            Type = "NVIDIA"; Fee = @(0.02);        MinMemGiB = 3.0;  WarmupTimes = @(30, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo NEXA" }
    @{ Algorithms = @("Octopus", "");                            Type = "NVIDIA"; Fee = @(0.02);        MinMemGiB = 1.24; WarmupTimes = @(60, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@("NiceHash"), @()); Arguments = " --algo OCTOPUS --mode a" }
    @{ Algorithms = @("Octopus", "SHA3x");                       Type = "NVIDIA"; Fee = @(0.02, 0.01);  MinMemGiB = 1.24; WarmupTimes = @(60, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@("NiceHash"), @()); Arguments = " --algo OCTOPUS --mode a --dualmode SHA3XDUAL --maximaldualimpact *" }
    @{ Algorithms = @("SHA512256d", "");                         Type = "NVIDIA"; Fee = @(0.0075);      MinMemGiB = 1.0;  WarmupTimes = @(60, 20);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo RADIANT" }
    @{ Algorithms = @("SHA3x", "");                              Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 1.0;  WarmupTimes = @(60, 20);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo SHA3X" }
    @{ Algorithms = @("UbqHash", "");                            Type = "NVIDIA"; Fee = @(0.007);       MinMemGiB = 1.24; WarmupTimes = @(45, 0);   ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo UBQHASH" }
)

$Algorithms = $Algorithms.where({ $MinerPools[0][$_.Algorithms[0]] })
$Algorithms = $Algorithms.where({ -not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]] })

if ($Algorithms) { 

    if (-not $Session.Config.DryRun) { 
        # MaxDualImpact for 2. algorithm; The maximum impact on the eth mining speed in dual mining in %. Default is * for automatic mode
        $MaxDualImpactValues = @("*", 5, 10, 15, 20)

        # Build command sets for MaxDualImpact (only seems to work with AMD, no hashrates for second algorithm with GTX 1660 Super when --maxdualimpact is a number)
        $Algorithms = $Algorithms.ForEach(
            { 
                if ($_.Type -eq "AMD" -and $_.Algorithms[1]) { 
                    foreach ($MaxDualImpactValue in $MaxDualImpactValues) { 
                        $_.MaxDualImpact = $MaxDualImpactValue
                        $_.PsObject.Copy()
                    }
                }
                else { 
                    $_.PsObject.Copy()
                }
            }
        )
    }

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.where({ $_.Type -eq $Type }).ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    if ($SupportedMinerDevices = $MinerDevices.where({ $_.Architecture -notmatch $ExcludeGPUarchitectures })) { 

                        $ExcludePools = $_.ExcludePools
                        foreach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].where({ $ExcludePools[0] -notcontains $_.Name })) { 
                            foreach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].where({ $ExcludePools[1] -notcontains $_.Name })) { 

                                $MinMemGiB = $_.MinMemGiB + $Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB
                                # Windows 10 requires more memory on some algos
                                if ($_.Algorithms[0] -match '^Cuckaroo.*$|^Cuckoo.*$' -and ([System.Environment]::OSVersion.Version -ge [System.Version]"10.0.0.0")) { $MinMemGiB += 1 }
                                if ($AvailableMinerDevices = $SupportedMinerDevices.where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(if ($Pool1) { "&$($Pool1.AlgorithmVariant)$(if ($_.MaxDualImpact) { "-$($_.MaxDualImpact)" })"})"

                                    $Arguments = $_.Arguments

                                    $CoinPers = if ("Equihash1445", "Equihash1927" -contains $_.Algorithms[0]) { Get-EquihashCoinPers -Command " --pers " -Currency $Pool0.Currency -DefaultCommand "" }

                                    if ($_.Algorithms[0] -notin @("Equihash1445", "Equihash1927") -or $CoinPers) { 
                                        if ($CoinPers) { $Arguments += $CoinPers }
                                        $Arguments += " --pool $($Pool0.Host):$(($Pool0.PoolPorts | Select-Object -Last 1))"
                                        $Arguments += " --user $($Pool0.User)$(if ($Pool0.Protocol -ne "ethproxy" -and $Pool0.WorkerName -and $Pool0.User -notmatch "\.$($Pool0.WorkerName)$") { ".$($Pool0.WorkerName)" }) --pass $($Pool0.Pass)"
                                        $Arguments += if ($Pool0.PoolPorts[1]) { " --tls on" } else { " --tls off" }
                                        switch ($Pool0.Protocol) { 
                                            "ethproxy"     { $Arguments += " --worker $($Pool0.WorkerName)$ --ethstratum ETHPROXY"; break }
                                            "ethstratum1"  { $Arguments += " --ethstratum ETHV1"; break }
                                            "ethstratum2"  { $Arguments += " --ethstratum ETHV1"; break }
                                            "ethstratumnh" { $Arguments += " --ethstratum ETHV1" }
                                        }

                                        if ($_.Algorithms[1]) { 
                                            $Arguments += " --dualpool $($Pool1.Host):$($Pool1.PoolPorts | Select-Object -Last 1)"
                                            $Arguments += " --dualuser $($Pool1.User)$(if ($Pool1.WorkerName -and $Pool1.User -notmatch "\.$($Pool1.WorkerName)$") { ".$($Pool1.WorkerName)" }) --dualpass $($Pool1.Pass)"
                                            if ($_.MaxDualImpact) { $Arguments += " --maxdualimpact $($_.MaxDualImpact)" }
                                            $Arguments += if ($Pool1.PoolPorts[1]) { " --dualtls on" } else { " --dualtls off" }
                                        }

                                        [PSCustomObject]@{ 
                                            API         = "lolMiner"
                                            Arguments   = "$Arguments --log off --apiport $MinerAPIPort --shortstats 1 --longstats 5 --digits 6 --watchdog exit --dns-over-https 1 --devicesbypcie --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0}:0' -f $_ }) -join ',')"
                                            DeviceNames = $AvailableMinerDevices.Name
                                            Fee         = $_.Fee # Dev fee
                                            MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                                            Name        = $MinerName
                                            Path        = $Path
                                            Port        = $MinerAPIPort
                                            Type        = $Type
                                            URI         = $URI
                                            WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                            Workers     = @(($Pool0, $Pool1).where({ $_ }).ForEach({ @{ Pool = $_ } }))
                                        }
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