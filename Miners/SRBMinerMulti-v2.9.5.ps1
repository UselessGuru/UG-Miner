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
Version:        6.5.4
Version date:   2025/08/04
#>

If (-not ($Devices = $Session.EnabledDevices.Where({ $_.Type -eq "CPU" -or $_.Type -eq "INTEL" -or ($_.Type -eq "AMD" -and $_.Architecture -notmatch "GCN[1-3]" -and $_.OpenCL.ClVersion -ge "OpenCL C 2.0") -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.OpenCL.DriverVersion -ge "510.00") }))) { Return }

$URI = "https://github.com/doktor83/SRBMiner-Multi/releases/download/2.9.5/SRBMiner-Multi-2-9-5-win64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\SRBMiner-MULTI.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

# Added algorithm 'randomalpha' (Unicity coin) for CPU mining, fee 1.0%
# Performance/efficiency improvements for algorithm 'nxlhash' on AMD RDNA and NVIDIA GPU's
# Fixed broken dual mining of algorithms 'autolykos2/sha256dt' and 'autolykos2/heavyhash' on NVIDIA 5000 series [blackwell]
# Removed algorithm 'xehash'
# Removed algorithm 'astrixhash'
# Removed algorithm 'clchash'
# Removed algorithm 'yespowerdogemone'

# Algorithm parameter values are case sensitive!
$Algorithms = @( 
    @{ Algorithms = @("0x10", "");                      Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm 0x10") }
    @{ Algorithms = @("Argon2d16000", "");              Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm argon2d_16000") }
    @{ Algorithms = @("Argon2d500", "");                Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm argon2d_dynamic") }
    @{ Algorithms = @("Argon2Chukwa", "");              Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm argon2id_chukwa") }
    @{ Algorithms = @("Argon2Chukwa2", "");             Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm argon2id_chukwa2") }
    @{ Algorithms = @("Autolykos2", "");                Type = "AMD"; Fee = @(0.01);           MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload") }
    @{ Algorithms = @("Autolykos2", "Decred");          Type = "AMD"; Fee = @(0.01, 0.01);     MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm blake3_decred") }
    @{ Algorithms = @("Autolykos2", "HeavyHash");       Type = "AMD"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm heavyhash") }
    @{ Algorithms = @("Autolykos2", "SHA3x");           Type = "AMD"; Fee = @(0.01, 0.0065);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm sha3xh") }
    @{ Algorithms = @("Autolykos2", "WalaHash");        Type = "AMD"; Fee = @(0.01, 0.02);     MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm walahash") }
    @{ Algorithms = @("CryptonightGpu", "");            Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm cryptonight_gpu") }
    @{ Algorithms = @("CryptonightHeavyXhv", "");       Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm cryptonight_xhv") }
    @{ Algorithms = @("CryptonightTurtle", "");         Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm cryptonight_turtle") } # TeamRedMiner-v0.10.21 is fastest
    @{ Algorithms = @("CryptonightUpx", "");            Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm cryptonight_upx") }
    @{ Algorithms = @("CurveHash", "");                 Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 2;    MinerSet = 1; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm curvehash") }
    @{ Algorithms = @("Decred", "");                    Type = "AMD"; Fee = @(0.01);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm blake3_decred") }
    @{ Algorithms = @("EtcHash", "");                   Type = "AMD"; Fee = @(0.0065);         MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm etchash") } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithms = @("EtcHash", "Decred");             Type = "AMD"; Fee = @(0.0065, 0.01);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm etchash", " --algorithm blake3_decred") }
    @{ Algorithms = @("EtcHash", "HeavyHash");          Type = "AMD"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm etchash", " --algorithm heavyhash") }
    @{ Algorithms = @("EtcHash", "SHA256dt");           Type = "AMD"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm etchash", " --algorithm sha256dt") }
    @{ Algorithms = @("Ethash", "");                    Type = "AMD"; Fee = @(0.0065);         MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethash") } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithms = @("Ethash", "Decred");              Type = "AMD"; Fee = @(0.0065, 0.01);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethash", " --algorithm blake3_decred") }
    @{ Algorithms = @("Ethash", "HeavyHash");           Type = "AMD"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethash", " --algorithm heavyhash") }
    @{ Algorithms = @("Ethash", "SHA256dt");            Type = "AMD"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethash", " --algorithm sha256dt") }
    @{ Algorithms = @("EthashB3", "");                  Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethashb3") }
    @{ Algorithms = @("EthashB3", "Decred");            Type = "AMD"; Fee = @(0.0085, 0.01);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethashb3", " --algorithm blake3_decred") }
    @{ Algorithms = @("EthashB3", "SHA256dt");          Type = "AMD"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 40); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethashb3", " --algorithm sha256dt") }
    @{ Algorithms = @("EthashR5", "");                  Type = "AMD"; Fee = @(0.02);           MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethashr5") }
    @{ Algorithms = @("EvoHash", "");                   Type = "AMD"; Fee = @(0.01);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm evohash") }
    @{ Algorithms = @("EvrProgPow", "");                Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm evrprogpow") }
    @{ Algorithms = @("FiroPow", "");                   Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm firopow") }
    @{ Algorithms = @("FishHash", "");                  Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fishhash") }
    @{ Algorithms = @("FishHash", "Decred");            Type = "AMD"; Fee = @(0.0085, 0.01);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fishhash", " --algorithm blake3_decred") }
    @{ Algorithms = @("FishHash", "SHA3x");             Type = "AMD"; Fee = @(0.0085, 0.0065); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fishhash", " --algorithm sha3x") }
    @{ Algorithms = @("FishHash", "WalaHash");          Type = "AMD"; Fee = @(0.0085, 0.01);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fishhash", " --algorithm walahash") }
    @{ Algorithms = @("FpHash", "");                    Type = "AMD"; Fee = @(0.01);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fphash") }
    @{ Algorithms = @("HeavyHash", "");                 Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm heavyhash") } # FPGA
    @{ Algorithms = @("HeavyHashKarlsenV2", "");        Type = "AMD"; Fee = @(0.01);           MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm karlsenhashv2") }
    @{ Algorithms = @("HeavyHashKarlsenV2", "Decred");  Type = "AMD"; Fee = @(0.01, 0.02);     MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm karlsenhashv2", " --algorithm blake3_decred") }
    @{ Algorithms = @("KawPow", "");                    Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm kawpow") }
    @{ Algorithms = @("Liberty", "");                   Type = "AMD"; Fee = @(0.02);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm blake3_lbrt") }
    @{ Algorithms = @("Lyra2v2Webchain", "");           Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm lyra2v2_webchain") }
    @{ Algorithms = @("MeowPow", "");                   Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(75, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm meowpow") }
    @{ Algorithms = @("PhiHash", "");                   Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm phihash") }
    @{ Algorithms = @("ProgPowEpic", "");               Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm progpow_epic") }
    @{ Algorithms = @("ProgPowQuai", "");               Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm progpow_quai") }
    @{ Algorithms = @("ProgPowSero", "");               Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm progpow_sero") }
    @{ Algorithms = @("ProgPowTelestai", "");           Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm progpow_telestai") }
    @{ Algorithms = @("ProgPowVeil", "");               Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm progpow_veil") }
    @{ Algorithms = @("ProgPowZ", "");                  Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm progpow_zano") }
    @{ Algorithms = @("SCCpow", "");                    Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm firopow") }
    @{ Algorithms = @("SHA256dt", "");                  Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm sha256dt") }
    @{ Algorithms = @("SHA3x", "");                     Type = "AMD"; Fee = @(0.0065);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm sha256x") }
    @{ Algorithms = @("VertHash", "");                  Type = "AMD"; Fee = @(0.01);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = "^Other$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm verthash --verthash-dat-path ..\.$($Session.VertHashDatPath)") }
    @{ Algorithms = @("WalaHash", "");                  Type = "AMD"; Fee = @(0.01);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm walahash") }
    @{ Algorithms = @("XeChain", "");                   Type = "AMD"; Fee = @(0.01);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(90, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm xechain") }
    @{ Algorithms = @("Yescrypt", "");                  Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(90, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm yescrypt") }
    @{ Algorithms = @("YescryptR8", "");                Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(90, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm yescryptr8") }
    @{ Algorithms = @("YescryptR16", "");               Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm yescryptr16") }
    @{ Algorithms = @("YescryptR32", "");               Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(90, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm yescryptr32") }

    @{ Algorithms = @("Argon2d16000", "");         Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm argon2d_16000") }
    @{ Algorithms = @("Argon2d500", "");           Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm argon2d_dynamic") }
    @{ Algorithms = @("Argon2Chukwa", "");         Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm argon2id_chukwa") }
    @{ Algorithms = @("Argon2Chukwa2", "");        Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm argon2id_chukwa2") }
#   @{ Algorithms = @("CryptonightGpu", "");       Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(120, 30); ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm cryptonight_gpu --cpu-threads-intensity 2") } # Not profitable with CPU
#   @{ Algorithms = @("CryptonightHeavyxXhv", ""); Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm cryptonight_xhv --cpu-threads-intensity 2") } # Not profitable with CPU
#   @{ Algorithms = @("CryptonightTurtle", "");    Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm cryptonight_turtle --cpu-threads-intensity 2") } # Not profitable with CPU
#   @{ Algorithms = @("CryptonightUpx", "");       Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm cryptonight_upx --cpu-threads-intensity 2") } # Not profitable with CPU
    @{ Algorithms = @("CpuPower", "");             Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 20);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm cpupower") }
#   @{ Algorithms = @("CurveHash", "");            Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 20);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm curvehash") } # Not profitable with CPU
    @{ Algorithms = @("Ghostrider", "");           Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(180, 60); ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm ghostrider") }
    @{ Algorithms = @("Lyra2v2Webchain", "");      Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm lyra2v2_webchain") }
#   @{ Algorithms = @("Mike", "");                 Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(30, 60);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm mike") } # No results in time
    @{ Algorithms = @("MinotaurX", "");            Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(40, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm minotaurx") }
#   @{ Algorithms = @("Panthera"), "";             Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm panthera") } # Broken with 2.7.1
    @{ Algorithms = @("RandomAlpha", "");          Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomalpha --Randomx-use-1gb-pages") }
    @{ Algorithms = @("RandomL", "");              Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randoml --Randomx-use-1gb-pages") }
    @{ Algorithms = @("RandomSfx", "");            Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomsfx --Randomx-use-1gb-pages") }
#   @{ Algorithms = @("RandomxArq", "");           Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomarq --Randomx-use-1gb-pages") } # FPGA
    @{ Algorithms = @("RandomxEpic", "");          Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomepic --Randomx-use-1gb-pages") }
    @{ Algorithms = @("RandomxScash", "");         Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(90, 20);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomscash --Randomx-use-1gb-pages") }
    @{ Algorithms = @("RandomXeq", "");            Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(90, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomxeq --Randomx-use-1gb-pages") }
    @{ Algorithms = @("RandomYada", "");           Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomyada --Randomx-use-1gb-pages") }
    @{ Algorithms = @("Randomy", "");              Type = "CPU"; Fee = @(0.01);   MinerSet = 2; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomy") }
    @{ Algorithms = @("RinHash", "");              Type = "CPU"; Fee = @(0.01);   MinerSet = 2; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm rinhash") }
    @{ Algorithms = @("VerusHash", "");            Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 20);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm verushash") }
    @{ Algorithms = @("YescryptR16", "");          Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yescryptr16") }
    @{ Algorithms = @("YescryptR32", "");          Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 45);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yescryptr32") }
    @{ Algorithms = @("YescryptR8", "");           Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yescryptr8") }
    @{ Algorithms = @("Yespower", "");             Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 40);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespower") }
    @{ Algorithms = @("Yespower2b", "");           Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespower2b") }
    @{ Algorithms = @("YespowerAdvc", "");         Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 40);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespoweradvc") }
    @{ Algorithms = @("YespowerIc", "");           Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespoweric") }
    @{ Algorithms = @("YespowerLtncg", "");        Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespowerltncg") }
    @{ Algorithms = @("YespowerMgpc", "");         Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespowermgpc") }
    @{ Algorithms = @("YespowerR16", "");          Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespowerr16") }
    @{ Algorithms = @("YespowerSugar", "");        Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespowersugar") }
    @{ Algorithms = @("YespowerTide", "");         Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespowertide") }
    @{ Algorithms = @("YespowerURX", "");          Type = "CPU"; Fee = @(0);      MinerSet = 1; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm YespowerURX") }
    @{ Algorithms = @("Yescrypt", "");             Type = "CPU"; Fee = @(0.0085); MinerSet = 2; WarmupTimes = @(90, 20);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yescrypt") }
    @{ Algorithms = @("XelisHashV2", "");          Type = "CPU"; Fee = @(0.015);  MinerSet = 2; WarmupTimes = @(90, 20);  ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-gpu --algorithm xelishashv2") }
    @{ Algorithms = @("XelisV2PepePow", "");       Type = "CPU"; Fee = @(0.015);  MinerSet = 2; WarmupTimes = @(90, 20);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm xelishashv2_pepew") }

    @{ Algorithms = @("Autolykos2", "");                Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload") }
    @{ Algorithms = @("Autolykos2", "Decred");          Type = "INTEL"; Fee = @(0.01, 0.01);     MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm blake3_decred") }
    @{ Algorithms = @("Autolykos2", "HeavyHash");       Type = "INTEL"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm heavyhash") }
    @{ Algorithms = @("Autolykos2", "SHA3x");           Type = "INTEL"; Fee = @(0.01, 0.0065);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm sha3x") }
    @{ Algorithms = @("Autolykos2", "WalaHash");        Type = "INTEL"; Fee = @(0.01, 0.01);     MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm walahash") }
    @{ Algorithms = @("CryptonightGpu", "");            Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm cryptonight_gpu") }
    @{ Algorithms = @("Decred", "");                    Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm blake3_decred") }
    @{ Algorithms = @("EtcHash", "");                   Type = "INTEL"; Fee = @(0.0065);         MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm etchash") }
    @{ Algorithms = @("EtcHash", "Decred");             Type = "INTEL"; Fee = @(0.0065, 0.01);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm etchash", " --algorithm blake3_decred") }
    @{ Algorithms = @("EtcHash", "HeavyHash");          Type = "INTEL"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm etchash", " --algorithm heavyhash") }
    @{ Algorithms = @("EtcHash", "SHA256dt");           Type = "INTEL"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm etchash", " --algorithm sha256dt") }
    @{ Algorithms = @("Ethash", "");                    Type = "INTEL"; Fee = @(0.0065);         MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethash") }
    @{ Algorithms = @("Ethash", "Decred");              Type = "INTEL"; Fee = @(0.0065, 0.01);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethash", " --algorithm blake3_decred") }
    @{ Algorithms = @("Ethash", "HeavyHash");           Type = "INTEL"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethash", " --algorithm heavyhash") }
    @{ Algorithms = @("Ethash", "SHA256dt");            Type = "INTEL"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethash", " --algorithm sha256dt") }
    @{ Algorithms = @("EthashB3", "");                  Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethashb3") }
    @{ Algorithms = @("EthashB3", "Decred");            Type = "INTEL"; Fee = @(0.0085, 0.01);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethashb3", " --algorithm blake3_decred") }
    @{ Algorithms = @("EthashB3", "SHA256dt");          Type = "INTEL"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethashb3", " --algorithm sha256dt") }
    @{ Algorithms = @("EthashR5", "");                  Type = "INTEL"; Fee = @(0.02);           MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethashr5") }
    @{ Algorithms = @("EvoHash", "");                   Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm evohash") }
    @{ Algorithms = @("FiroPow", "");                   Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm firopow") }
    @{ Algorithms = @("FishHash", "");                  Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm fishhash") }
    @{ Algorithms = @("FishHash", "Decred");            Type = "INTEL"; Fee = @(0.01, 0.01);     MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @());   Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm fishhash", " --algorithm blake3_decred") }
    @{ Algorithms = @("FishHash", "SHA3x");             Type = "INTEL"; Fee = @(0.01, 0.0065);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @());   Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm fishhash", " --algorithm sha3x") }
    @{ Algorithms = @("FishHash", "WalaHash");          Type = "INTEL"; Fee = @(0.01, 0.01);     MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @());   Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm fishhash", " --algorithm walahash") }
    @{ Algorithms = @("FpHash", "");                    Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm fphash") }
    @{ Algorithms = @("HeavyHash", "");                 Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm heavyhash") } # FPGA
    @{ Algorithms = @("HeavyHashKarlsenV2", "");        Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm karlsenhashv2") }
    @{ Algorithms = @("HeavyHashKarlsenV2", "Decred");  Type = "INTEL"; Fee = @(0.01, 0.02);     MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @());   Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm karlsenhashv2", " --algorithm blake3_decred") }
    @{ Algorithms = @("KawPow", "");                    Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @());   Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm kawpow") }
    @{ Algorithms = @("Liberty", "");                   Type = "iNTEL"; Fee = @(0.02);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm blake3_lbrt") }
    @{ Algorithms = @("MeowPow", "");                   Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@("ProHashing"), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm meowpow") }
    @{ Algorithms = @("PhiHash", "")    ;               Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm phihash") }
    @{ Algorithms = @("ProgPowEpic", "");               Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm progpow_epic") }
    @{ Algorithms = @("ProgPowQuai", "");               Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm progpow_quai") }
    @{ Algorithms = @("ProgPowSero", "");               Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm progpow_sero") }
    @{ Algorithms = @("ProgPowTelestai", "");           Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm progpow_telestai") }
    @{ Algorithms = @("ProgPowVeil", "");               Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm progpow_veil") }
    @{ Algorithms = @("ProgPowZ", "");                  Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm progpow_zano") }
    @{ Algorithms = @("FiroPow", "");                   Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm firopow") }
    @{ Algorithms = @("SHA256dt", "");                  Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm sha256dt") }
    @{ Algorithms = @("SHA256x", "");                   Type = "INTEL"; Fee = @(0.03);           MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm sha256x") }
    @{ Algorithms = @("VertHash", "");                  Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm verthash --verthash-dat-path ..\.$($Session.VertHashDatPath)") }
    @{ Algorithms = @("WalaHash", "");                  Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm walahash") }
    @{ Algorithms = @("XeChain", "");                   Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(90, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());             Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm xechain") }

    @{ Algorithms = @("Autolykos2", "");                Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(30, 20); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm autolykos2 --autolykos2-preload") }
    @{ Algorithms = @("Autolykos2", "Decred");          Type = "NVIDIA"; Fee = @(0.01, 0.01);     MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm autolykos2 --autolykos2-preload", " --algorithm blake3_decred") }
    @{ Algorithms = @("Autolykos2", "HeavyHash");       Type = "NVIDIA"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm autolykos2 --autolykos2-preload", " --algorithm heavyhash") }
    @{ Algorithms = @("Autolykos2", "SHA3x");           Type = "NVIDIA"; Fee = @(0.01, 0.0065);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 10); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm autolykos2 --autolykos2-preload", " --algorithm sha3x") }
    @{ Algorithms = @("Autolykos2", "WalaHash");        Type = "NVIDIA"; Fee = @(0.01, 0.02);     MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 10); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm autolykos2 --autolykos2-preload", " --algorithm walahash") }
    @{ Algorithms = @("CryptonightGpu", "");            Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm cryptonight_gpu") }
    @{ Algorithms = @("CryptonightHeavyXhv", "");       Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm cryptonight_xhv") }
    @{ Algorithms = @("Decred", "");                    Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(30, 20); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm blake3_decred") }
    @{ Algorithms = @("EtcHash", "");                   Type = "NVIDIA"; Fee = @(0.0065);         MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm etchash") } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithms = @("EtcHash", "Decred");             Type = "NVIDIA"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm etchash", " --algorithm blake3_decred") }
    @{ Algorithms = @("EtcHash", "HeavyHash");          Type = "NVIDIA"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm etchash", " --algorithm heavyhash") }
    @{ Algorithms = @("EtcHash", "SHA256dt");           Type = "NVIDIA"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm etchash", " --algorithm sha256dt") }
    @{ Algorithms = @("Ethash", "");                    Type = "NVIDIA"; Fee = @(0.0065);         MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethash") } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithms = @("Ethash", "Decred");              Type = "NVIDIA"; Fee = @(0.0065, 0.01);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethash", " --algorithm blake3_decred") }
    @{ Algorithms = @("Ethash", "HeavyHash");           Type = "NVIDIA"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethash", " --algorithm heavyhash") }
    @{ Algorithms = @("Ethash", "SHA256dt");            Type = "NVIDIA"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethash", " --algorithm sha256dt") }
    @{ Algorithms = @("EthashB3", "");                  Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethashb3") }
    @{ Algorithms = @("EthashB3", "Decred");            Type = "NVIDIA"; Fee = @(0.0085, 0.01);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethashb3", " --algorithm blake3_decred") }
    @{ Algorithms = @("EthashB3", "SHA256dt");          Type = "NVIDIA"; Fee = @(0.0085, 0.0085); MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethashb3", " --algorithm sha256dt") }
    @{ Algorithms = @("EthashR5", "");                  Type = "NVIDIA"; Fee = @(0.02);           MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethashr5") }
    @{ Algorithms = @("EvoHash", "");                   Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = "";                 ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm evohash") }
    @{ Algorithms = @("EvrProgPow", "");                Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm evrprogpow") }
    @{ Algorithms = @("FiroPow", "");                   Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm firopow") }
    @{ Algorithms = @("FishHash", "");                  Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm fishhash") }
    @{ Algorithms = @("FishHash", "Decred");            Type = "NVIDIA"; Fee = @(0.01, 0.01);     MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm fishhash", " --algorithm blake3_decred") }
    @{ Algorithms = @("FishHash", "SHA3x");             Type = "NVIDIA"; Fee = @(0.01, 0.0065);   MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm fishhash", " --algorithm sha3x") }
    @{ Algorithms = @("FishHash", "WalaHash");          Type = "NVIDIA"; Fee = @(0.01, 0.01);     MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm fishhash", " --algorithm walahash") }
    @{ Algorithms = @("FpHash", "");                    Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm fphash") }
    @{ Algorithms = @("HeavyHash", "");                 Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = "^Other$";          ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm heavyhash") } # FPGA
    @{ Algorithms = @("HeavyHashKarlsenV2", "");        Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm karlsenhashv2") }
    @{ Algorithms = @("HeavyHashKarlsenV2", "Decred");  Type = "NVIDIA"; Fee = @(0.01, 0.02);     MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm karlsenhashv2", " --algorithm blake3_decred") }
    @{ Algorithms = @("KawPow", "");                    Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = " ";                ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm kawpow") }
    @{ Algorithms = @("Liberty", "");                   Type = "NVIDIA"; Fee = @(0.02);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm blake3_lbrt") }
    @{ Algorithms = @("Lyra2v2Webchain", "");           Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm lyra2v2_webchain") }
    @{ Algorithms = @("MeowPow", "");                   Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm meowpow") }
    @{ Algorithms = @("PhiHash", "");                   Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm phihash") }
    @{ Algorithms = @("ProgPowEpic", "");               Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm progpow_epic") }
    @{ Algorithms = @("ProgPowQuai", "");               Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm progpow_quai") }
    @{ Algorithms = @("ProgPowSero", "");               Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm progpow_sero") }
    @{ Algorithms = @("ProgPowTelestai", "");           Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm progpow_telestai") }
    @{ Algorithms = @("ProgPowVeil", "");               Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm progpow_veil") }
    @{ Algorithms = @("ProgPowZ", "");                  Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm progpow_zano") }
    @{ Algorithms = @("SCCpow", "");                    Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm firopow") }
    @{ Algorithms = @("SHA256dt", "");                  Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm sha256dt") }
    @{ Algorithms = @("SHA256x", "");                   Type = "NVIDIA"; Fee = @(0.065);          MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm sha256x") }
    @{ Algorithms = @("VertHash", "");                  Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm verthash --verthash-dat-path ..\.$($Session.VertHashDatPath)") }
    @{ Algorithms = @("WalaHash", "");                  Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm walahash") }
    @{ Algorithms = @("XeChain", "");                   Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(90, 0);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm xechain") }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Session.ConfigRunning.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] })
$Algorithms = $Algorithms.Where({ -not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]] })

If ($Algorithms) { 

    If (-not $Session.ConfigRunning.DryRun) { 
        # Allowed max loss for 1. algorithm
        # $GpuDualMaxLosses = @(2, 4, 7, 10, 15, 21, 30)
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
                                        If ($Pool.Name -eq "NiceHash" ) { $Arguments += " --nicehash true" }
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

                                    If ($_.Algorithms[0] -eq "KawPow" -and "HashCryptos", "MiningDutch" -contains $Pool0) { $Arguments += " --retry-time 1" }

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
