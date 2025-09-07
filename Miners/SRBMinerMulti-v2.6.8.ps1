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
Version:        6.5.11
Version date:   2025/09/07
#>

If (-not ($Devices = $Session.EnabledDevices.Where({ $_.Type -eq "CPU" -or $_.Type -eq "INTEL" -or ($_.Type -eq "AMD" -and $_.Architecture -notmatch "GCN[1-3]|RDNA4" -and $_.OpenCL.ClVersion -ge "OpenCL C 2.0") -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.OpenCL.DriverVersion -ge "510.00") }))) { Return }

$URI = "https://github.com/doktor83/SRBMiner-Multi/releases/download/2.6.8/SRBMiner-Multi-2-6-8-win64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\SRBMiner-MULTI.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

# Algorithm parameter values are case sensitive!
$Algorithms = @( 
    @{ Algorithms = @("Autolykos2", "Blake3");                   Type = "AMD"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm blake3_alephium") }
    @{ Algorithms = @("Autolykos2", "HeavyHashPyrin");           Type = "AMD"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm pyrinhash") }
    @{ Algorithms = @("Autolykos2", "HeavyHashPyrinV2");         Type = "AMD"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm pyrinhashv2") }
    @{ Algorithms = @("Autolykos2", "SHA256dt");                 Type = "AMD"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm sha256dt") }
    @{ Algorithms = @("Autolykos2", "SHA512256d");               Type = "AMD"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm sha512_256d_radiant") }
    @{ Algorithms = @("Blake3", "");                             Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm blake3_alephium") }
    @{ Algorithms = @("EtcHash", "Blake3");                      Type = "AMD"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm etchash", " --algorithm blake3_alephium") }
    @{ Algorithms = @("EtcHash", "SHA512256d");                  Type = "AMD"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm etchash", " --algorithm sha512_256d_radiant") }
    @{ Algorithms = @("Ethash", "Blake3");                       Type = "AMD"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethash", " --algorithm blake3_alephium") }
    @{ Algorithms = @("Ethash", "SHA512256d");                   Type = "AMD"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethash", " --algorithm sha512_256d_radiant") }
    @{ Algorithms = @("EthashB3", "Blake3");                     Type = "AMD"; Fee = @(0.0085, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethashb3", " --algorithm blake3_alephium") }
    @{ Algorithms = @("EthashB3", "HeavyHashKarlsen");           Type = "AMD"; Fee = @(0.0085, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethashb3", " --algorithm karlsenhash") }
    @{ Algorithms = @("EthashB3", "SHA512256d");                 Type = "AMD"; Fee = @(0.0085, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethashb3", " --algorithm sha512_256d_radiant") }
    @{ Algorithms = @("FishHash", "Blake3");                     Type = "AMD"; Fee = @(0.0085, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fishhash", " --algorithm blake3_alephium") }
    @{ Algorithms = @("FishHash", "HeavyHashKarlsen");           Type = "AMD"; Fee = @(0.0085, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fishhash", " --algorithm karlsenhash") }
    @{ Algorithms = @("FishHash", "HeavyHashPyrin");             Type = "AMD"; Fee = @(0.0085, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fishhash", " --algorithm pyrinhash") }
    @{ Algorithms = @("FishHash", "HeavyHashPyrinV2");           Type = "AMD"; Fee = @(0.0085, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fishhash", " --algorithm pyrinhashv2") }
    @{ Algorithms = @("FishHash", "SHA512256d");                 Type = "AMD"; Fee = @(0.0085, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fishhash", " --algorithm sha512_256d_radiant") }
    @{ Algorithms = @("HeavyHashKarlsen", "");                   Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm karlsenhash") }
    @{ Algorithms = @("HeavyHashKarlsenV2", "HeavyHashPyrinV2"); Type = "AMD"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm karlsenhashv2", " --algorithm pyrinhashv2") }
    @{ Algorithms = @("HeavyHashPyrinV2", "");                   Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm pyrinhashv2") }
    @{ Algorithms = @("ProgPowVeriblock", "");                   Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm progpow_veriblock") }
    @{ Algorithms = @("Pufferfish2BMB", "");                     Type = "AMD"; Fee = @(0.01);           MinMemGiB = 8;    MinerSet = 2; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm pufferfish2bmb") }
    @{ Algorithms = @("SHA3d", "");                              Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm sha3d") } # FPGA
    @{ Algorithms = @("SHA512256d", "");                         Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm sha512_256d_radiant") }
    @{ Algorithms = @("UbqHash", "");                            Type = "AMD"; Fee = @(0.0065);         MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ubqhash") }
    @{ Algorithms = @("VerusHash", "");                          Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm verushash") }

    @{ Algorithms = @("Panthera", "");       Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());              Arguments = @(" --disable-gpu --algorithm panthera") }
    @{ Algorithms = @("Pufferfish2BMB", ""); Type = "CPU"; Fee = @(0.01);   MinerSet = 2; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @());              Arguments = @(" --disable-gpu --algorithm pufferfish2bmb") }
    @{ Algorithms = @("RandomGrft", "");     Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @());              Arguments = @(" --disable-gpu --algorithm randomgrft --Randomx-use-1gb-pages") }
    @{ Algorithms = @("RandomNevo", "");     Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());              Arguments = @(" --disable-gpu --algorithm randomnevo --Randomx-use-1gb-pages") }
    @{ Algorithms = @("RandomxKeva", "");    Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @());              Arguments = @(" --disable-gpu --algorithm randomkeva --Randomx-use-1gb-pages") }
    @{ Algorithms = @("Flex", "");           Type = "CPU"; Fee = @(0.02);   MinerSet = 2; WarmupTimes = @(90, 20);  ExcludePools = @(@(), @());              Arguments = @(" --disable-gpu --algorithm flex") }
    @{ Algorithms = @("VerusHash", "");      Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @());              Arguments = @(" --disable-gpu --algorithm verushash") }

    @{ Algorithms = @("Autolykos2", "Blake3");                   Type = "INTEL"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm blake3_alephium") }
    @{ Algorithms = @("Blake3", "");                             Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm blake3_alephium") }
    @{ Algorithms = @("EtcHash", "Blake3");                      Type = "INTEL"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm etchash", " --algorithm blake3_alephium") }
    @{ Algorithms = @("EtcHash", "SHA512256d");                  Type = "INTEL"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm etchash", " --algorithm sha512_256d_radiant") }
    @{ Algorithms = @("Ethash", "Blake3");                       Type = "INTEL"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethash", " --algorithm blake3_alephium") }
    @{ Algorithms = @("Ethash", "SHA512256d");                   Type = "INTEL"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethash", " --algorithm sha512_256d_radiant") }
    @{ Algorithms = @("EthashB3", "Blake3");                     Type = "INTEL"; Fee = @(0.0085, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethashb3", " --algorithm blake3_alephium") }
    @{ Algorithms = @("EthashB3", "SHA512256d");                 Type = "INTEL"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethashb3", " --algorithm sha512_256d_radiant") }
    @{ Algorithms = @("HeavyHashPyrin", "");                     Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm pyrinhash") }
    @{ Algorithms = @("FishHash", "Blake3");                     Type = "INTEL"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm fishhash", " --algorithm blake3_alephium") }
    @{ Algorithms = @("FishHash", "HeavyHashPyrin");             Type = "INTEL"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm fishhash", " --algorithm pyrinhash") }
    @{ Algorithms = @("FishHash", "HeavyHashPyrinV2");           Type = "INTEL"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm fishhash", " --algorithm pyrinhashv2") }
    @{ Algorithms = @("FishHash", "SHA512256d");                 Type = "INTEL"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm fishhash", " --algorithm sha512_256d_radiant") }
    @{ Algorithms = @("HeavyHashKarlsenV2", "HeavyHashPyrinV2"); Type = "INTEL"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm karlsenhashv2", " --algorithm pyrinhashv2") }
    @{ Algorithms = @("ProgPowVeriblock", "");                   Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm progpow_veriblock") }
    @{ Algorithms = @("SHA3d", "");                              Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm sha3d") } # FPGA
    @{ Algorithms = @("SHA512256d", "");                         Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm sha512_256d_radiant") }
    @{ Algorithms = @("UbqHash", "");                            Type = "INTEL"; Fee = @(0.0065);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ubqhash") }
    @{ Algorithms = @("VerusHash", "");                          Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm verushash") }

    @{ Algorithms = @("Autolykos2", "Blake3");     Type = "NVIDIA"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm autolykos2 --autolykos2-preload", " --algorithm blake3_alephium") }
    @{ Algorithms = @("Autolykos2", "SHA512256d"); Type = "NVIDIA"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 10); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm autolykos2 --autolykos2-preload", " --algorithm sha512_256d_radiant") }
    @{ Algorithms = @("Blake3", "");               Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm blake3_alephium") }
    @{ Algorithms = @("EtcHash", "Blake3");        Type = "NVIDIA"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm etchash", " --algorithm blake3_alephium") }
    @{ Algorithms = @("EtcHash", "SHA512256d");    Type = "NVIDIA"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm etchash", " --algorithm sha512_256d_radiant") }
    @{ Algorithms = @("Ethash", "Blake3");         Type = "NVIDIA"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethash", " --algorithm blake3_alephium") }
    @{ Algorithms = @("Ethash", "SHA512256d");     Type = "NVIDIA"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethash", " --algorithm sha512_256d_radiant") }
    @{ Algorithms = @("EthashB3", "Blake3");       Type = "NVIDIA"; Fee = @(0.0085, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethashb3", " --algorithm blake3_alephium") }
    @{ Algorithms = @("EthashB3", "SHA512256d");   Type = "NVIDIA"; Fee = @(0.0085, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethashb3", " --algorithm sha512_256d_radiant") }
    @{ Algorithms = @("FishHash", "Blake3");       Type = "NVIDIA"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm fishhash", " --algorithm blake3_alephium") }
    @{ Algorithms = @("FishHash", "SHA512256d");   Type = "NVIDIA"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm fishhash", " --algorithm sha512_256d_radiant") }
    @{ Algorithms = @("HeavyHashKarlsen", "");     Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(15, 30); ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm karlsenhash") }
    @{ Algorithms = @("ProgPowVeriblock", "");     Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm progpow_veriblock") }
    @{ Algorithms = @("SHA3d", "");                Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm sha3d") } # FPGA
    @{ Algorithms = @("SHA512256d", "");           Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm sha512_256d_radiant") }
    @{ Algorithms = @("UbqHash", "");              Type = "NVIDIA"; Fee = @(0.0065);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ubqhash") }
    @{ Algorithms = @("VerusHash", "");            Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm verushash") }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Session.ConfigRunning.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] })
$Algorithms = $Algorithms.Where({ -not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]] })

If ($Algorithms) { 

    If (-not $Session.ConfigRunning.DryRun) { 
        # Allowed max loss for 1. algorithm
        $GpuDualMaxLosses = @(2, 4, 7, 10, 15, 21, 30)
        $GpuDualMaxLosses = @(5)

        # Build command sets for max loss
        $Algorithms = $Algorithms.ForEach(
            { 
                $_.PsObject.Copy()
                If ($_.Algorithms[1]) { 
                    ForEach ($GpuDualMaxLoss in $GpuDualMaxLosses) { 
                        $_.GpuDualMaxLoss = $GpuDualMaxLoss
                        $_.PsObject.Copy()
                    }
                }
            }
        )
    }

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Session.ConfigRunning.APIport + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    If ($SupportedMinerDevices = $MinerDevices.Where({ $_.Type -eq "CPU" -or $_.Architecture -notmatch $ExcludeGPUarchitectures })) { 

                        If ($_.Algorithms[0] -eq "VertHash" -and (Get-Item -Path $Session.VertHashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                            $PrerequisitePath = $Session.VertHashDatPath
                            $PrerequisiteURI = "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/VertHashDataFile/VertHash.dat"
                        }
                        Else { 
                            $PrerequisitePath = ""
                            $PrerequisiteURI = ""
                        }

                        $ExcludePools = $_.ExcludePools
                        ForEach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $ExcludePools[0] -notcontains $_.Name })) { 
                            ForEach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $ExcludePools[1] -notcontains $_.Name })) { 
                                $Pools = @(($Pool0, $Pool1).Where({ $_ }))

                                $MinMemGiB = $_.MinMemGiB + $Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB
                                If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -gt $MinMemGiB })) { 

                                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(If ($Pool1) { "&$($Pool1.AlgorithmVariant)$(If ($_.GpuDualMaxLoss) { "-$($_.GpuDualMaxLoss)" })"})"

                                    $Arguments = ""
                                    ForEach ($Pool in $Pools) { 
                                        If ($Pool.Algorithm -match $Session.RegexAlgoIsEthash) { 
                                            Switch ($Pool.Protocol) { 
                                                "minerproxy"   { $Arguments += " --esm 0"; Break }
                                                "ethproxy"     { $Arguments += " --esm 0"; Break }
                                                "ethstratum1"  { $Arguments += " --esm 1"; Break }
                                                "ethstratum2"  { $Arguments += " --esm 2"; Break }
                                                "ethstratumnh" { $Arguments += " --esm 2" }
                                            }
                                        }
                                        $Arguments += "$($_.Arguments[$Pools.IndexOf($Pool)]) --pool $($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --wallet $($Pool.User) --password $($Pool.Pass)"
                                        If ($Pool.WorkerName) { $Arguments += " --worker $($Pool.WorkerName)" }
                                        $Arguments += If ($Pool.PoolPorts[1]) { " --tls true" } Else { " --tls false" }
                                        If ($_.GpuDualMaxLoss) { $Arguments += " --gpu-dual-max-loss $($_.GpuDualMaxLoss)" }
                                    }
                                    Remove-Variable Pool

                                    If ($_.Type -eq "CPU") { 
                                        $Arguments += " --cpu-threads $($AvailableMinerDevices.CIM.NumberOfLogicalProcessors - $Session.ConfigRunning.CPUMiningReserveCPUcore)"
                                    }
                                    Else { 
                                        $Arguments += " --gpu-id $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                    }

                                    # Allow more time to build larger DAGs, must use type cast to keep values in $_
                                    $WarmupTimes = [UInt16[]]$_.WarmupTimes
                                    $WarmupTimes[0] += [UInt16](($Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB) * 2)

                                    # Apply tuning parameters
                                    If ($_.Type -eq "CPU" -and -not $Session.ApplyMinerTweaks) { $_.Arguments += " --disable-msr-tweaks" }

                                    [PSCustomObject]@{ 
                                        API              = "SRBMiner"
                                        Arguments        = "$Arguments --api-rig-name $($Session.ConfigRunning.PoolsConfig.($Pool0.Name).WorkerName) --api-enable --api-port $MinerAPIPort"
                                        DeviceNames      = $AvailableMinerDevices.Name
                                        Fee              = $_.Fee # Dev fee
                                        MinerSet         = $_.MinerSet
                                        MinerUri         = "http://127.0.0.1:$($MinerAPIPort)/stats"
                                        Name             = $MinerName
                                        Path             = $Path
                                        Port             = $MinerAPIPort
                                        PrerequisitePath = $PrerequisitePath
                                        PrerequisiteURI  = $PrerequisiteURI
                                        Type             = $Type
                                        URI              = $URI
                                        WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                        Workers           = @($Pools.ForEach({ @{ Pool = $_ } }))
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
