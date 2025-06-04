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
Version:        6.4.29
Version date:   2025/06/04
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "INTEL" -or ($_.Type -eq "AMD" -and $_.Architecture -match "GCN4|RDNA[1|2|3]") -or $_.OpenCL.ComputeCapability -ge "6.0" }))) { Return }

$URI = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.95a/lolMiner_v1.95a_Win64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\lolminer.exe"
$DeviceEnumerator = "Bus"

$Algorithms = @(
    @{ Algorithms = @("Autolykos2", "");                   Type = "AMD"; Fee = @(0.015);       MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(45, 20);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo AUTOLYKOS2" }
    @{ Algorithms = @("Autolykos2", "HeavyHashPyrinV2");   Type = "AMD"; Fee = @(0.015, 0.01); MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(45, 20);  ExcludeGPUarchitectures = "^RDNA\d+$";        ExcludePools = @(@(), @());           Arguments = " --algo AUTOLYKOS2 --dualmode PYRINV2DUAL" }
#   @{ Algorithms = @("Autolykos2", "HeavyHashKarlsenV2"); Type = "AMD"; Fee = @(0.015, 0.01); MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(45, 20);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo AUTOLYKOS2 --dualmode KARLSENV2DUAL" }
    @{ Algorithms = @("BeamV3", "");                       Type = "AMD"; Fee = @(0.01);        MinMemGiB = 6.0;  MinerSet = 0; WarmupTimes = @(45, 50);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo BEAM-III" }
    @{ Algorithms = @("Blake3", "");                       Type = "AMD"; Fee = @(0.0075);      MinMemGiB = 2.0;  MinerSet = 1; WarmupTimes = @(45, 20);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ALEPH" }
    @{ Algorithms = @("Cuckoo29", "");                     Type = "AMD"; Fee = @(0.02);        MinMemGiB = 8.0;  MinerSet = 0; WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo C29AE" }
    @{ Algorithms = @("Cuckaroo29B", "");                  Type = "AMD"; Fee = @(0.02);        MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo CR29-40" }
    @{ Algorithms = @("Cuckaroo29S", "");                  Type = "AMD"; Fee = @(0.02);        MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo CR29-32" }
    @{ Algorithms = @("Cuckaroo30CTX", "");                Type = "AMD"; Fee = @(0.025);       MinMemGiB = 7.8;  MinerSet = 2; WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo C30CTX" }
#   @{ Algorithms = @("Cuckatoo31", "");                   Type = "AMD"; Fee = @(0.02);        MinMemGiB = 4.0;  MinerSet = 3; WarmupTimes = @(60, 80);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo C31" } # ASIC
#   @{ Algorithms = @("Cuckatoo32", "");                   Type = "AMD"; Fee = @(0.02);        MinMemGiB = 4.0;  MinerSet = 3; WarmupTimes = @(60, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo C32" } # ASIC
    @{ Algorithms = @("Equihash1254", "");                 Type = "AMD"; Fee = @(0.015);       MinMemGiB = 3.0;  MinerSet = 0; WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ZEL --pers ZelProof" }
    @{ Algorithms = @("Equihash1445", "");                 Type = "AMD"; Fee = @(0.01);        MinMemGiB = 3.0;  MinerSet = 1; WarmupTimes = @(30, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo EQUI144_5" } # FPGA
    @{ Algorithms = @("Equihash1927", "");                 Type = "AMD"; Fee = @(0.01);        MinMemGiB = 3.0;  MinerSet = 0; WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo EQUI192_7" } # FPGA
    @{ Algorithms = @("EtcHash", "");                      Type = "AMD"; Fee = @(0.007);       MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETCHASH" } # PhoenixMiner-v6.2c is faster
    @{ Algorithms = @("EtcHash", "Blake3");                Type = "AMD"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 100); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo ETCHASH --dualmode ALEPHDUAL" }
#   @{ Algorithms = @("EtcHash", "HeavyHashKarlsenV2");    Type = "AMD"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 90);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETCHASH --dualmode KARLSEV2NDUAL" } # No hashrate for second algorithm
    @{ Algorithms = @("Ethash", "");                       Type = "AMD"; Fee = @(0.007);       MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
    @{ Algorithms = @("Ethash", "Blake3");                 Type = "AMD"; Fee = @(0.01, 0);     MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 100); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo ETHASH --dualmode ALEPHDUAL" }
#   @{ Algorithms = @("Ethash", "HeavyHashKarlsenV2");     Type = "AMD"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 90);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETHASH --dualmode KARLSENV2DUAL" } # No hashrate for second algorithm
    @{ Algorithms = @("EthashB3", "");                     Type = "AMD"; Fee = @(0.01);        MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = "^GCN\d+$";         ExcludePools = @(@(), @());           Arguments = " --algo ETHASHB3" } # https://github.com/Lolliedieb/lolMiner-releases/issues/1992
    @{ Algorithms = @("EthashB3", "Blake3");               Type = "AMD"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90);  ExcludeGPUarchitectures = "^GCN\d+$";         ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo ETHASHB3 --dualmode ALEPHDUAL" }
    @{ Algorithms = @("EthashB3", "SHA512256d");           Type = "AMD"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 100); ExcludeGPUarchitectures = "^GCN\d+$";         ExcludePools = @(@(), @());           Arguments = " --algo ETHASHB3 --dualmode RXDDUAL" } # https://github.com/Lolliedieb/lolMiner-releases/issues/1986
    @{ Algorithms = @("Flux", "");                         Type = "AMD"; Fee = @(0.01);        MinMemGiB = 1.00; MinerSet = 2; WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = "^GCN\d+$";         ExcludePools = @(@(), @());           Arguments = " --algo FLUX" }
    @{ Algorithms = @("FishHash", "");                     Type = "AMD"; Fee = @(0.0075);      MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(45, 20);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH" }
    @{ Algorithms = @("FishHash", "Blake3");               Type = "AMD"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90);  ExcludeGPUarchitectures = "^GCN\d+$";         ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo FISHHASH --dualmode ALEPHDUAL" }
    @{ Algorithms = @("FishHash", "HeavyHashPyrinV2");     Type = "AMD"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90);  ExcludeGPUarchitectures = "^GCN\d+$|^RDNA1$"; ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode PYRINV2DUAL" }
    @{ Algorithms = @("FishHash", "SHA512256d");           Type = "AMD"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90);  ExcludeGPUarchitectures = "^GCN\d+$";         ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode RXDDUAL" }
    @{ Algorithms = @("HeavyHashKarlsen", "");             Type = "AMD"; Fee = @(0.0075);      MinMemGiB = 2.0;  MinerSet = 1; WarmupTimes = @(90, 30);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo KARLSEN" }
    @{ Algorithms = @("HeavyHashKarlsenV2", "");           Type = "AMD"; Fee = @(0.01);        MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(90, 30);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo KARLSENV2" }
    @{ Algorithms = @("HeavyHashPyrinV2", "");             Type = "AMD"; Fee = @(0.01);        MinMemGiB = 2.0;  MinerSet = 1; WarmupTimes = @(90, 30);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo PYRINV2 " }
    @{ Algorithms = @("NexaPow", "");                      Type = "AMD"; Fee = @(0.02);        MinMemGiB = 3.0;  MinerSet = 2; WarmupTimes = @(30, 60);  ExcludeGPUarchitectures = "^GCN\d+$";         ExcludePools = @(@(), @());           Arguments = " --algo NEXA" }
    @{ Algorithms = @("Octopus", "");                      Type = "AMD"; Fee = @(0.02);        MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@("NiceHash"), @()); Arguments = " --algo OCTOPUS" }
    @{ Algorithms = @("SHA512256d", "");                   Type = "AMD"; Fee = @(0.0075);      MinMemGiB = 1.0;  MinerSet = 0; WarmupTimes = @(60, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo RADIANT" }
    @{ Algorithms = @("UbqHash", "");                      Type = "AMD"; Fee = @(0.007);       MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo UBQHASH" }
    @{ Algorithms = @("UbqHash", "Blake3");                Type = "AMD"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 90);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo UBQHASH --dualmode ALEPHDUAL" }
#   @{ Algorithms = @("UbqHash", "HeavyHashKarlsenV2");    Type = "AMD"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 90);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo UBQHASH --dualmode KARLSENV2DUAL" } # No hashrate for second algorithm

    @{ Algorithms = @("Autolykos2", "");   Type = "INTEL"; Fee = @(0.015); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo AUTOLYKOS2" }
    @{ Algorithms = @("BeamV3", "");       Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo BEAM-III" }
    @{ Algorithms = @("Equihash1254", ""); Type = "INTEL"; Fee = @(0.015); MinMemGiB = 3.0;  MinerSet = 0; WarmupTimes = @(45, 70); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo ZEL --pers ZelProof" }
    @{ Algorithms = @("Equihash1445", ""); Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 3.0;  MinerSet = 1; WarmupTimes = @(30, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo EQUI144_5" } # FPGA
    @{ Algorithms = @("EtcHash", "");      Type = "INTEL"; Fee = @(0.007); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo ETCHASH" } # PhoenixMiner-v6.2c is faster

    @{ Algorithms = @("Autolykos2", "");                         Type = "NVIDIA"; Fee = @(0.015);       MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 20);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo AUTOLYKOS2" }
    @{ Algorithms = @("Autolykos2", "HeavyHashPyrinV2");         Type = "NVIDIA"; Fee = @(0.015, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 20);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo AUTOLYKOS2 --dualmode PYRINV2DUAL --maxdualimpact *" }
    @{ Algorithms = @("Blake3", "");                             Type = "NVIDIA"; Fee = @(0.075);       MinMemGiB = 2.0;  MinerSet = 1; WarmupTimes = @(45, 30);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ALEPH" }
    @{ Algorithms = @("BeamV3", "");                             Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 3.0;  MinerSet = 2; WarmupTimes = @(45, 50);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo BEAM-III" }
    @{ Algorithms = @("Cuckoo29", "");                           Type = "NVIDIA"; Fee = @(0.02);        MinMemGiB = 8.0;  MinerSet = 2; WarmupTimes = @(45, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo C29AE" }
    @{ Algorithms = @("Cuckaroo29B", "");                        Type = "NVIDIA"; Fee = @(0.02);        MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(45, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo CR29-40" }
    @{ Algorithms = @("Cuckaroo29S", "");                        Type = "NVIDIA"; Fee = @(0.02);        MinMemGiB = 6.0;  MinerSet = 2; WarmupTimes = @(45, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo CR29-32" }
    @{ Algorithms = @("Cuckaroo30CTX", "");                      Type = "NVIDIA"; Fee = @(0.025);       MinMemGiB = 8.0;  MinerSet = 2; WarmupTimes = @(45, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo C30CTX" }
#   @{ Algorithms = @("Cuckatoo31", "");                         Type = "NVIDIA"; Fee = @(0.02);        MinMemGiB = 4.0;  MinerSet = 3; WarmupTimes = @(60, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo C31" } # ASIC
#   @{ Algorithms = @("Cuckatoo32", "");                         Type = "NVIDIA"; Fee = @(0.02);        MinMemGiB = 4.0;  MinerSet = 3; WarmupTimes = @(60, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo C32" } # ASIC
    @{ Algorithms = @("Equihash1254", "");                       Type = "NVIDIA"; Fee = @(0.015);       MinMemGiB = 3.0;  MinerSet = 1; WarmupTimes = @(45, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ZEL --pers ZelProof" } # MiniZ-v2.5e is fastest, but has 2% miner fee
    @{ Algorithms = @("Equihash1445", "");                       Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 3.0;  MinerSet = 1; WarmupTimes = @(30, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo EQUI144_5" } # FPGA
    @{ Algorithms = @("Equihash2109", "");                       Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(45, 30);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo EQUI210_9" }
    @{ Algorithms = @("EtcHash", "");                            Type = "NVIDIA"; Fee = @(0.007);       MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 0);   ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETCHASH" } # PhoenixMiner-v6.2c is faster
    @{ Algorithms = @("EtcHash", "Blake3");                      Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(90, 100); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo ETCHASH --dualmode ALEPHDUAL --maxdualimpact *" }
#   @{ Algorithms = @("EtcHash", "HeavyHashKarlsenV2");          Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(90, 100); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETCHASH --dualmode KARLSEV2NDUAL --maxdualimpact *" } # No hashrate for second algorithm
    @{ Algorithms = @("Ethash", "");                             Type = "NVIDIA"; Fee = @(0.007);       MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
    @{ Algorithms = @("Ethash", "Blake3");                       Type = "NVIDIA"; Fee = @(0.01, 0);     MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 100); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo ETHASH --dualmode ALEPHDUAL --maxdualimpact *" }
#   @{ Algorithms = @("Ethash", "HeavyHashKarlsenV2");           Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(90, 100); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETHASH --dualmode KARLSENV2DUAL --maxdualimpact *" } # No hashrate for second algorithm
    @{ Algorithms = @("EthashB3", "");                           Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETHASHB3" }
    @{ Algorithms = @("EthashB3", "Blake3");                     Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo ETHASHB3 --dualmode ALEPHDUAL --maxdualimpact *" }
#   @{ Algorithms = @("EthashB3", "HeavyHashKarlsenV2");         Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETHASHB3 --dualmode KARLSENV2DUAL --maxdualimpact *" }
    @{ Algorithms = @("EthashB3", "SHA512256d");                 Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 90);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo ETHASHB3 --dualmode RXDDUAL --maxdualimpact *" }
    @{ Algorithms = @("FishHash", "");                           Type = "NVIDIA"; Fee = @(0.0075);      MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(45, 20);  ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH" }
    @{ Algorithms = @("FishHash", "Blake3");                     Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(75, 90);  ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo FISHHASH --dualmode ALEPHDUAL --maxdualimpact *" }
    @{ Algorithms = @("FishHash", "HeavyHashPyrinV2");           Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(75, 90);  ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode PYRINV2DUAL --maxdualimpact *" }
    @{ Algorithms = @("FishHash", "SHA512256d");                 Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(75, 90);  ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo FISHHASH --dualmode RXDDUAL --maxdualimpact *" }
    @{ Algorithms = @("HeavyHashKarlsen", "");                   Type = "NVIDIA"; Fee = @(0.0075);      MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(30, 0);   ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo KARLSEN" }
    @{ Algorithms = @("HeavyHashKarlsenV2", "");                 Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(30, 0);   ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo KARLSENV2" }
    @{ Algorithms = @("HeavyHashKarlsenV2", "HeavyHashPyrinV2"); Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(30, 0);   ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo KARLSENV2 --dualmode PYRINV2DUAL --maxdualimpact *" }
    @{ Algorithms = @("HeavyHashPyrinV2", "");                   Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(30, 0);   ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = " --algo PYRINV2 " }
    @{ Algorithms = @("NexaPow", "");                            Type = "NVIDIA"; Fee = @(0.02);        MinMemGiB = 3.0;  MinerSet = 1; WarmupTimes = @(30, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo NEXA" }
    @{ Algorithms = @("Octopus", "");                            Type = "NVIDIA"; Fee = @(0.02);        MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 70);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@("NiceHash"), @()); Arguments = " --algo OCTOPUS --mode a" }
    @{ Algorithms = @("SHA512256d", "");                         Type = "NVIDIA"; Fee = @(0.0075);      MinMemGiB = 1.0;  MinerSet = 2; WarmupTimes = @(60, 20);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo RADIANT" }
    @{ Algorithms = @("UbqHash", "");                            Type = "NVIDIA"; Fee = @(0.007);       MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo UBQHASH" }
    @{ Algorithms = @("UbqHash", "Blake3");                      Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 90);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo UBQHASH --dualmode ALEPHDUAL --maxdualimpact *" }
#   @{ Algorithms = @("UbqHash", "HeavyHashKarlsenV2");          Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 90);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = " --algo UBQHASH --dualmode KARLSENV2DUAL --maxdualimpact *" } # No hashrate for second algorithm
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] })
$Algorithms = $Algorithms.Where({ $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] })

If ($Algorithms) { 

    If (-not $Config.DryRun) { 
        # MaxDualImpact for 2. algorithm; The maximum impact on the eth mining speed in dual mining in %. Default is * for automatic mode
        $MaxDualImpactValues = @("*", 5, 10, 15, 20)

        # Build command sets for MaxDualImpact (only seems to work with AMD, no hashrates for second algorithm with GTX 1660 Super when --maxdualimpact is a number)
        $Algorithms = $Algorithms.ForEach(
            { 
                If ($_.Type -eq "AMD" -and $_.Algorithms[1]) { 
                    ForEach ($MaxDualImpactValue in $MaxDualImpactValues) { 
                        $_.MaxDualImpact = $MaxDualImpactValue
                        $_.PsObject.Copy()
                    }
                }
                Else { 
                    $_.PsObject.Copy()
                }
            }
        )
    }

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    If ($SupportedMinerDevices = $MinerDevices.Where({ $_.Architecture -notmatch $ExcludeGPUarchitectures })) { 

                        $ExcludePools = $_.ExcludePools
                        ForEach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $ExcludePools[0] -notcontains $_.Name })) { 
                            ForEach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $ExcludePools[1] -notcontains $_.Name })) { 

                                $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB
                                # Windows 10 requires more memory on some algos
                                If ($_.Algorithms[0] -match '^Cuckaroo.*$|^Cuckoo.*$' -and ([System.Environment]::OSVersion.Version -ge [System.Version]"10.0.0.0")) { $MinMemGiB += 1 }
                                If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(If ($Pool1) { "&$($Pool1.AlgorithmVariant)$(If ($_.MaxDualImpact -ne "*") { "-$($_.MaxDualImpact)" })"})"

                                    $Arguments = $_.Arguments
                                    $CoinPers = If ("Equihash1445", "Equihash1927" -contains $_.Algorithms[0]) { Get-EquihashCoinPers -Command " --pers " -Currency $Pool0.Currency -DefaultCommand "" } Else { "" }
                                    If ($CoinPers) { $Arguments += $CoinPers }
                                    If ($_.Algorithms[0] -notin @("Equihash1445", "Equihash1927") -or $CoinPers) { 
                                        $Arguments += " --pool $($Pool0.Host):$(($Pool0.PoolPorts | Select-Object -Last 1))"
                                        $Arguments += " --user $($Pool0.User)$(If ($Pool0.Protocol -ne "ethproxy" -and $Pool0.WorkerName -and $Pool0.User -notmatch "\.$($Pool0.WorkerName)$") { ".$($Pool0.WorkerName)" })"
                                        $Arguments += " --pass $($Pool0.Pass)"
                                        $Arguments += If ($Pool0.PoolPorts[1]) { " --tls on" } Else { " --tls off" }
                                        Switch ($Pool0.Protocol) { 
                                            "ethproxy"     { $Arguments += " --worker $($Pool0.WorkerName)$ --ethstratum ETHPROXY" }
                                            "ethstratum1"  { $Arguments += " --ethstratum ETHV1" }
                                            "ethstratum2"  { $Arguments += " --ethstratum ETHV1" }
                                            "ethstratumnh" { $Arguments += " --ethstratum ETHV1" }
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
                                            Type        = $Type
                                            URI         = $URI
                                            WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
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
    )
}