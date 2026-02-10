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
Version:        6.7.27
Version date:   2026/02/10
#>

# Added algorithm 'randomsnap' (Snap Coin) for CPU mining, fee 0.85%*
# Added NVIDIA GPU support for algorithm 'xelishashv3'
# Removed algorithm 'fphash'
# Fixed 1gb huge pages support for algorithm 'randomx'
# Bug fixes

if (-not ($Devices = $Session.EnabledDevices.Where({ $_.Type -eq "CPU" -or $_.Type -eq "INTEL" -or ($_.Type -eq "AMD" -and $_.Architecture -notmatch "GCN[1-3]" -and $_.OpenCL.ClVersion -ge "OpenCL C 2.0") -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.OpenCL.DriverVersion -ge "510.00") }))) { return }

$URI = "https://github.com/doktor83/SRBMiner-Multi/releases/download/3.1.3/SRBMiner-Multi-3-1-3-win64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\SRBMiner-MULTI.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

# Added algorithm 'randomjuno' (Juno Cash) for CPU mining, fee 0.85%*
# Performance improvement for algorithm 'xelishashv3' on some CPU's

# Algorithm parameter values are case sensitive!
$Algorithms = @( 
    @{ Algorithms = @("0x10", "");                      Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 2;    WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm 0x10") }
    @{ Algorithms = @("Argon2d16000", "");              Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm argon2d_16000") }
    @{ Algorithms = @("Argon2d500", "");                Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm argon2d_dynamic") }
    @{ Algorithms = @("Argon2Chukwa", "");              Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm argon2id_chukwa") }
    @{ Algorithms = @("Argon2Chukwa2", "");             Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm argon2id_chukwa2") }
    @{ Algorithms = @("Autolykos2", "");                Type = "AMD"; Fee = @(0.01);           MinMemGiB = 1.24; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload") }
    @{ Algorithms = @("Autolykos2", "Decred");          Type = "AMD"; Fee = @(0.01, 0.01);     MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm blake3_decred") }
    @{ Algorithms = @("Autolykos2", "HeavyHash");       Type = "AMD"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm heavyhash") }
    @{ Algorithms = @("Autolykos2", "SHA3x");           Type = "AMD"; Fee = @(0.01, 0.0065);   MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm sha3xh") }
    @{ Algorithms = @("Autolykos2", "WalaHash");        Type = "AMD"; Fee = @(0.01, 0.02);     MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm walahash") }
    @{ Algorithms = @("CryptonightGpu", "");            Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm cryptonight_gpu") }
    @{ Algorithms = @("CryptonightHeavyXhv", "");       Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm cryptonight_xhv") }
    @{ Algorithms = @("CryptonightTurtle", "");         Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm cryptonight_turtle") } # TeamRedMiner-v0.10.21 is fastest
    @{ Algorithms = @("CryptonightUpx", "");            Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm cryptonight_upx") }
    @{ Algorithms = @("CurveHash", "");                 Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 2;    WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm curvehash") }
    @{ Algorithms = @("Decred", "");                    Type = "AMD"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm blake3_decred") }
    @{ Algorithms = @("EtcHash", "");                   Type = "AMD"; Fee = @(0.0065);         MinMemGiB = 1.24; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm etchash") } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithms = @("EtcHash", "Decred");             Type = "AMD"; Fee = @(0.0065, 0.01);   MinMemGiB = 1.24; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm etchash", " --algorithm blake3_decred") }
    @{ Algorithms = @("EtcHash", "HeavyHash");          Type = "AMD"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm etchash", " --algorithm heavyhash") }
    @{ Algorithms = @("Ethash", "");                    Type = "AMD"; Fee = @(0.0065);         MinMemGiB = 1.24; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethash") } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithms = @("Ethash", "Decred");              Type = "AMD"; Fee = @(0.0065, 0.01);   MinMemGiB = 1.24; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethash", " --algorithm blake3_decred") }
    @{ Algorithms = @("Ethash", "HeavyHash");           Type = "AMD"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethash", " --algorithm heavyhash") }
    @{ Algorithms = @("EvoHash", "");                   Type = "AMD"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm evohash") }
    @{ Algorithms = @("EvrProgPow", "");                Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm evrprogpow") }
    @{ Algorithms = @("FiroPow", "");                   Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm firopow") }
    @{ Algorithms = @("FishHash", "");                  Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fishhash") }
    @{ Algorithms = @("FishHash", "Decred");            Type = "AMD"; Fee = @(0.0085, 0.01);   MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fishhash", " --algorithm blake3_decred") }
    @{ Algorithms = @("FishHash", "SHA3x");             Type = "AMD"; Fee = @(0.0085, 0.0065); MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fishhash", " --algorithm sha3x") }
    @{ Algorithms = @("FishHash", "WalaHash");          Type = "AMD"; Fee = @(0.0085, 0.01);   MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fishhash", " --algorithm walahash") }
    @{ Algorithms = @("HeavyHash", "");                 Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm heavyhash") } # FPGA
    @{ Algorithms = @("HeavyHashKarlsenV2", "");        Type = "AMD"; Fee = @(0.01);           MinMemGiB = 1.24; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm karlsenhashv2") }
    @{ Algorithms = @("HeavyHashKarlsenV2", "Decred");  Type = "AMD"; Fee = @(0.01, 0.02);     MinMemGiB = 1.24; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm karlsenhashv2", " --algorithm blake3_decred") }
    @{ Algorithms = @("KawPow", "");                    Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm kawpow") }
    @{ Algorithms = @("Lyra2v2Webchain", "");           Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm lyra2v2_webchain") }
    @{ Algorithms = @("MeowPow", "");                   Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(75, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm meowpow") }
    @{ Algorithms = @("PhiHash", "");                   Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm phihash") }
    @{ Algorithms = @("ProgPowEpic", "");               Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm progpow_epic") }
    @{ Algorithms = @("ProgPowSero", "");               Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm progpow_sero") }
    @{ Algorithms = @("ProgPowTelestai", "");           Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm progpow_telestai") }
    @{ Algorithms = @("ProgPowZ", "");                  Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm progpow_zano") }
    @{ Algorithms = @("SCCpow", "");                    Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm firopow") }
    @{ Algorithms = @("SHA3x", "");                     Type = "AMD"; Fee = @(0.0065);         MinMemGiB = 1;    WarmupTimes = @(45, 20); ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm sha256x") }
    @{ Algorithms = @("VertHash", "");                  Type = "AMD"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludeGPUarchitectures = "^Other$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm verthash --verthash-dat-path ..\.$($Session.VertHashDatPath)") }
    @{ Algorithms = @("WalaHash", "");                  Type = "AMD"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm walahash") }
    @{ Algorithms = @("XeChain", "");                   Type = "AMD"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(90, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm xechain") }
    @{ Algorithms = @("Xhash", "");                     Type = "AMD"; Fee = @(0.03);           MinMemGiB = 1.24; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm xhash") }
    @{ Algorithms = @("Yescrypt", "");                  Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(90, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm yescrypt") }
    @{ Algorithms = @("YescryptR8", "");                Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(90, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm yescryptr8") }
    @{ Algorithms = @("YescryptR16", "");               Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm yescryptr16") }
    @{ Algorithms = @("YescryptR32", "");               Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(90, 0);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm yescryptr32") }

    @{ Algorithms = @("Argon2d16000", "");         Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm argon2d_16000") }
    @{ Algorithms = @("Argon2d500", "");           Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm argon2d_dynamic") }
    @{ Algorithms = @("Argon2Chukwa", "");         Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(30, 15);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm argon2id_chukwa") }
    @{ Algorithms = @("Argon2Chukwa2", "");        Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(30, 15);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm argon2id_chukwa2") }
#   @{ Algorithms = @("CryptonightGpu", "");       Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(120, 30); ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm cryptonight_gpu --cpu-threads-intensity 2") } # Not profitable with CPU
#   @{ Algorithms = @("CryptonightHeavyxXhv", ""); Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(30, 15);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm cryptonight_xhv --cpu-threads-intensity 2") } # Not profitable with CPU
#   @{ Algorithms = @("CryptonightTurtle", "");    Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(30, 15);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm cryptonight_turtle --cpu-threads-intensity 2") } # Not profitable with CPU
#   @{ Algorithms = @("CryptonightUpx", "");       Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(30, 15);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm cryptonight_upx --cpu-threads-intensity 2") } # Not profitable with CPU
    @{ Algorithms = @("CpuPower", "");             Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 20);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm cpupower") }
#   @{ Algorithms = @("CurveHash", "");            Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 20);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm curvehash") } # Not profitable with CPU
    @{ Algorithms = @("Ghostrider", "");           Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(180, 60); ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm ghostrider") }
    @{ Algorithms = @("Lyra2v2Webchain", "");      Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(30, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm lyra2v2_webchain") }
#   @{ Algorithms = @("Mike", "");                 Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(30, 60);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm mike") } # No results in time
    @{ Algorithms = @("MinotaurX", "");            Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(40, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm minotaurx") }
#   @{ Algorithms = @("Panthera"), "";             Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm panthera") } # Broken with 2.7.1
    @{ Algorithms = @("RandomAlpha", "");          Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomalpha --Randomx-use-1gb-pages") }
    @{ Algorithms = @("RandomL", "");              Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randoml --Randomx-use-1gb-pages") }
    @{ Algorithms = @("RandomSfx", "");            Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(30, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomsfx --Randomx-use-1gb-pages") }
#   @{ Algorithms = @("RandomxArq", "");           Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomarq --Randomx-use-1gb-pages") } # FPGA
    @{ Algorithms = @("RandomxEpic", "");          Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(30, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomepic --Randomx-use-1gb-pages") }
    @{ Algorithms = @("RandomJuno", "");           Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(90, 20);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomjuno --Randomx-use-1gb-pages") }
    @{ Algorithms = @("RandomhScx", "");           Type = "CPU"; Fee = @(0.02);   WarmupTimes = @(90, 20);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomhscx --Randomx-use-1gb-pages") }
    @{ Algorithms = @("RandomScash", "");          Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(90, 20);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomscash --Randomx-use-1gb-pages") }
    @{ Algorithms = @("RandomSnap", "");           Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(90, 20);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomsnap --Randomx-use-1gb-pages") }
    @{ Algorithms = @("RandomXeq", "");            Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(90, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomxeq --Randomx-use-1gb-pages") }
    @{ Algorithms = @("RandomYada", "");           Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomyada --Randomx-use-1gb-pages") }
    @{ Algorithms = @("Randomy", "");              Type = "CPU"; Fee = @(0.01);   WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomy") }
    @{ Algorithms = @("RandomVirel", "");          Type = "CPU"; Fee = @(0.01);   WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm randomvirel") }
    @{ Algorithms = @("Rinhash", "");              Type = "CPU"; Fee = @(0.01);   WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm rinhash") }
    @{ Algorithms = @("VerusHash", "");            Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 20);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm verushash") }
    @{ Algorithms = @("YescryptR16", "");          Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yescryptr16") }
    @{ Algorithms = @("YescryptR32", "");          Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 45);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yescryptr32") }
    @{ Algorithms = @("YescryptR8", "");           Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yescryptr8") }
    @{ Algorithms = @("Yespower", "");             Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 40);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespower") }
    @{ Algorithms = @("Yespower2b", "");           Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespower2b") }
    @{ Algorithms = @("YespowerAdvc", "");         Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 40);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespoweradvc") }
    @{ Algorithms = @("YespowerEQPAY", "");        Type = "CPU"; Fee = @(0.002);  WarmupTimes = @(60, 40);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespowereqpay") }
    @{ Algorithms = @("YespowerInterchained", ""); Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespowerinterchained") }
    @{ Algorithms = @("YespowerIc", "");           Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespoweric") }
    @{ Algorithms = @("YespowerLtncg", "");        Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespowerltncg") }
    @{ Algorithms = @("YespowerMgpc", "");         Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespowermgpc") }
    @{ Algorithms = @("YespowerMwc", "");          Type = "CPU"; Fee = @(0.085);  WarmupTimes = @(60, 0);   ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespowermwc") }
    @{ Algorithms = @("YespowerR16", "");          Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespowerr16") }
    @{ Algorithms = @("YespowerSugar", "");        Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespowersugar") }
    @{ Algorithms = @("YespowerTide", "");         Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 25);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yespowertide") }
    @{ Algorithms = @("YespowerUrx", "");          Type = "CPU"; Fee = @(0);      WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm YespowerUrx") }
    @{ Algorithms = @("Yescrypt", "");             Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(90, 20);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm yescrypt") }
    @{ Algorithms = @("XelisHashV3", "");          Type = "CPU"; Fee = @(0.015);  WarmupTimes = @(90, 20);  ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-gpu --algorithm xelishashv3") }
    @{ Algorithms = @("XelisV2PepePow", "");       Type = "CPU"; Fee = @(0.015);  WarmupTimes = @(90, 20);  ExcludePools = @(@(), @());           Arguments = @(" --disable-gpu --algorithm xelishashv2_pepew") }

    @{ Algorithms = @("Autolykos2", "");                Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload") }
    @{ Algorithms = @("Autolykos2", "Decred");          Type = "INTEL"; Fee = @(0.01, 0.01);     MinMemGiB = 1.24; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm blake3_decred") }
    @{ Algorithms = @("Autolykos2", "HeavyHash");       Type = "INTEL"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm heavyhash") }
    @{ Algorithms = @("Autolykos2", "SHA3x");           Type = "INTEL"; Fee = @(0.01, 0.0065);   MinMemGiB = 1.24; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm sha3x") }
    @{ Algorithms = @("Autolykos2", "WalaHash");        Type = "INTEL"; Fee = @(0.01, 0.01);     MinMemGiB = 1.24; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm walahash") }
    @{ Algorithms = @("CryptonightGpu", "");            Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm cryptonight_gpu") }
    @{ Algorithms = @("Decred", "");                    Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 2;    WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm blake3_decred") }
    @{ Algorithms = @("EtcHash", "");                   Type = "INTEL"; Fee = @(0.0065);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm etchash") }
    @{ Algorithms = @("EtcHash", "Decred");             Type = "INTEL"; Fee = @(0.0065, 0.01);   MinMemGiB = 1.24; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm etchash", " --algorithm blake3_decred") }
    @{ Algorithms = @("EtcHash", "HeavyHash");          Type = "INTEL"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm etchash", " --algorithm heavyhash") }
    @{ Algorithms = @("Ethash", "");                    Type = "INTEL"; Fee = @(0.0065);         MinMemGiB = 1.24; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethash") }
    @{ Algorithms = @("Ethash", "Decred");              Type = "INTEL"; Fee = @(0.0065, 0.01);   MinMemGiB = 1.24; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethash", " --algorithm blake3_decred") }
    @{ Algorithms = @("Ethash", "HeavyHash");           Type = "INTEL"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethash", " --algorithm heavyhash") }
    @{ Algorithms = @("EvoHash", "");                   Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm evohash") }
    @{ Algorithms = @("FiroPow", "");                   Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm firopow") }
    @{ Algorithms = @("FishHash", "");                  Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm fishhash") }
    @{ Algorithms = @("FishHash", "Decred");            Type = "INTEL"; Fee = @(0.01, 0.01);     MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm fishhash", " --algorithm blake3_decred") }
    @{ Algorithms = @("FishHash", "SHA3x");             Type = "INTEL"; Fee = @(0.01, 0.0065);   MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm fishhash", " --algorithm sha3x") }
    @{ Algorithms = @("FishHash", "WalaHash");          Type = "INTEL"; Fee = @(0.01, 0.01);     MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm fishhash", " --algorithm walahash") }
    @{ Algorithms = @("HeavyHash", "");                 Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 2;    WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm heavyhash") } # FPGA
    @{ Algorithms = @("HeavyHashKarlsenV2", "");        Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm karlsenhashv2") }
    @{ Algorithms = @("HeavyHashKarlsenV2", "Decred");  Type = "INTEL"; Fee = @(0.01, 0.02);     MinMemGiB = 1.24; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm karlsenhashv2", " --algorithm blake3_decred") }
    @{ Algorithms = @("KawPow", "");                    Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm kawpow") }
    @{ Algorithms = @("MeowPow", "");                   Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm meowpow") }
    @{ Algorithms = @("PhiHash", "")    ;               Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm phihash") }
    @{ Algorithms = @("ProgPowEpic", "");               Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm progpow_epic") }
    @{ Algorithms = @("ProgPowSero", "");               Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm progpow_sero") }
    @{ Algorithms = @("ProgPowTelestai", "");           Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm progpow_telestai") }
    @{ Algorithms = @("ProgPowZ", "");                  Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm progpow_zano") }
    @{ Algorithms = @("FiroPow", "");                   Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm firopow") }
    @{ Algorithms = @("SHA256x", "");                   Type = "INTEL"; Fee = @(0.03);           MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm sha256x") }
    @{ Algorithms = @("VertHash", "");                  Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm verthash --verthash-dat-path ..\.$($Session.VertHashDatPath)") }
    @{ Algorithms = @("WalaHash", "");                  Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm walahash") }
    @{ Algorithms = @("XeChain", "");                   Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(90, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm xechain") }
    @{ Algorithms = @("Xhash", "");                     Type = "INTEL"; Fee = @(0.03);           MinMemGiB = 1.24; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm xhash") }

    @{ Algorithms = @("Autolykos2", "");                Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1.24; WarmupTimes = @(30, 20); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm autolykos2 --autolykos2-preload") }
    @{ Algorithms = @("Autolykos2", "Decred");          Type = "NVIDIA"; Fee = @(0.01, 0.01);     MinMemGiB = 1.24; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm autolykos2 --autolykos2-preload", " --algorithm blake3_decred") }
    @{ Algorithms = @("Autolykos2", "HeavyHash");       Type = "NVIDIA"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm autolykos2 --autolykos2-preload", " --algorithm heavyhash") }
    @{ Algorithms = @("Autolykos2", "SHA3x");           Type = "NVIDIA"; Fee = @(0.01, 0.0065);   MinMemGiB = 1.24; WarmupTimes = @(60, 10); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm autolykos2 --autolykos2-preload", " --algorithm sha3x") }
    @{ Algorithms = @("Autolykos2", "WalaHash");        Type = "NVIDIA"; Fee = @(0.01, 0.02);     MinMemGiB = 1.24; WarmupTimes = @(60, 10); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm autolykos2 --autolykos2-preload", " --algorithm walahash") }
    @{ Algorithms = @("CryptonightGpu", "");            Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(60, 30); ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm cryptonight_gpu") }
    @{ Algorithms = @("CryptonightHeavyXhv", "");       Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm cryptonight_xhv") }
    @{ Algorithms = @("Decred", "");                    Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(30, 20); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm blake3_decred") }
    @{ Algorithms = @("EtcHash", "");                   Type = "NVIDIA"; Fee = @(0.0065);         MinMemGiB = 1.24; WarmupTimes = @(45, 10); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm etchash") } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithms = @("EtcHash", "Decred");             Type = "NVIDIA"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm etchash", " --algorithm blake3_decred") }
    @{ Algorithms = @("EtcHash", "HeavyHash");          Type = "NVIDIA"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm etchash", " --algorithm heavyhash") }
    @{ Algorithms = @("Ethash", "");                    Type = "NVIDIA"; Fee = @(0.0065);         MinMemGiB = 1.24; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethash") } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithms = @("Ethash", "Decred");              Type = "NVIDIA"; Fee = @(0.0065, 0.01);   MinMemGiB = 1.24; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethash", " --algorithm blake3_decred") }
    @{ Algorithms = @("Ethash", "HeavyHash");           Type = "NVIDIA"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethash", " --algorithm heavyhash") }
    @{ Algorithms = @("EvoHash", "");                   Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = "";                 ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm evohash") }
    @{ Algorithms = @("EvrProgPow", "");                Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm evrprogpow") }
    @{ Algorithms = @("FiroPow", "");                   Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm firopow") }
    @{ Algorithms = @("FishHash", "");                  Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm fishhash") }
    @{ Algorithms = @("FishHash", "Decred");            Type = "NVIDIA"; Fee = @(0.01, 0.01);     MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm fishhash", " --algorithm blake3_decred") }
    @{ Algorithms = @("FishHash", "SHA3x");             Type = "NVIDIA"; Fee = @(0.01, 0.0065);   MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm fishhash", " --algorithm sha3x") }
    @{ Algorithms = @("FishHash", "WalaHash");          Type = "NVIDIA"; Fee = @(0.01, 0.01);     MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm fishhash", " --algorithm walahash") }
    @{ Algorithms = @("HeavyHash", "");                 Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(45, 20); ExcludeGPUarchitectures = "^Other$";          ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm heavyhash") } # FPGA
    @{ Algorithms = @("HeavyHashKarlsenV2", "");        Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1.24; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm karlsenhashv2") }
    @{ Algorithms = @("HeavyHashKarlsenV2", "Decred");  Type = "NVIDIA"; Fee = @(0.01, 0.02);     MinMemGiB = 1.24; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm karlsenhashv2", " --algorithm blake3_decred") }
    @{ Algorithms = @("KawPow", "");                    Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = " ";                ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm kawpow") }
    @{ Algorithms = @("Lyra2v2Webchain", "");           Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm lyra2v2_webchain") }
    @{ Algorithms = @("MeowPow", "");                   Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm meowpow") }
    @{ Algorithms = @("PhiHash", "");                   Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm phihash") }
    @{ Algorithms = @("ProgPowEpic", "");               Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm progpow_epic") }
    @{ Algorithms = @("ProgPowSero", "");               Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm progpow_sero") }
    @{ Algorithms = @("ProgPowTelestai", "");           Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm progpow_telestai") }
    @{ Algorithms = @("ProgPowZ", "");                  Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm progpow_zano") }
    @{ Algorithms = @("SCCpow", "");                    Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm firopow") }
    @{ Algorithms = @("SHA256x", "");                   Type = "NVIDIA"; Fee = @(0.065);          MinMemGiB = 1;    WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm sha256x") }
    @{ Algorithms = @("VertHash", "");                  Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm verthash --verthash-dat-path ..\.$($Session.VertHashDatPath)") }
    @{ Algorithms = @("WalaHash", "");                  Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm walahash") }
    @{ Algorithms = @("XeChain", "");                   Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(90, 0);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm xechain") }
    @{ Algorithms = @("Xhash", "");                     Type = "NVIDIA"; Fee = @(0.03);           MinMemGiB = 1.24; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm xhash") }
)

$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] })
$Algorithms = $Algorithms.Where({ -not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]] })

if ($Algorithms) { 

    if (-not $Session.Config.DryRun) { 
        # Allowed max loss for 1. algorithm
        # $GpuDualMaxLosses = @(2, 4, 7, 10, 15, 21, 30)
        $GpuDualMaxLosses = @(5)

        # Build command sets for max loss
        $Algorithms = $Algorithms.ForEach(
            { 
                $_.PsObject.Copy()
                if ($_.Algorithms[1]) { 
                    foreach ($GpuDualMaxLoss in $GpuDualMaxLosses) { 
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
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    if ($SupportedMinerDevices = $MinerDevices.Where({ $_.Type -eq "CPU" -or $_.Architecture -notmatch $ExcludeGPUarchitectures })) { 

                        if ($_.Algorithms[0] -eq "VertHash" -and (Get-Item -Path $Session.VertHashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                            $PrerequisitePath = $Session.VertHashDatPath
                            $PrerequisiteURI  = "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/VertHashDataFile/VertHash.dat"
                        }
                        else { 
                            $PrerequisitePath = ""
                            $PrerequisiteURI  = ""
                        }

                        $ExcludePools = $_.ExcludePools
                        foreach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $ExcludePools[0] -notcontains $_.Name })) { 
                            foreach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $ExcludePools[1] -notcontains $_.Name })) { 
                                $Pools = @(($Pool0, $Pool1).Where({ $_ }))

                                $MinMemGiB = $_.MinMemGiB + $Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB
                                if ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -gt $MinMemGiB })) { 

                                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(if ($Pool1) { "&$($Pool1.AlgorithmVariant)$(if ($_.GpuDualMaxLoss) { "-$($_.GpuDualMaxLoss)" })"})"

                                    $Arguments = ""
                                    foreach ($Pool in $Pools) { 
                                        if ($Pool.Algorithm -match $Session.RegexAlgoIsEthash) { 
                                            switch ($Pool.Protocol) { 
                                                "minerproxy"   { $Arguments += " --esm 0"; break }
                                                "ethproxy"     { $Arguments += " --esm 0"; break }
                                                "ethstratum1"  { $Arguments += " --esm 1"; break }
                                                "ethstratum2"  { $Arguments += " --esm 2"; break }
                                                "ethstratumnh" { $Arguments += " --esm 2" }
                                            }
                                        }
                                        $Arguments += "$($_.Arguments[$Pools.IndexOf($Pool)]) --pool $($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --wallet $($Pool.User) --password $($Pool.Pass)"
                                        if ($Pool.Name -eq "NiceHash" ) { $Arguments += " --nicehash true" }
                                        if ($Pool.WorkerName) { $Arguments += " --worker $($Pool.WorkerName)" }
                                        $Arguments += if ($Pool.PoolPorts[1]) { " --tls true" } else { " --tls false" }
                                        if ($_.GpuDualMaxLoss) { $Arguments += " --gpu-dual-max-loss $($_.GpuDualMaxLoss)" }
                                    }
                                    Remove-Variable Pool

                                    if ($_.Type -eq "CPU") { 
                                        $Arguments += " --cpu-threads $($AvailableMinerDevices.CIM.NumberOfLogicalProcessors - $Session.Config.CPUMiningReserveCPUcore)"
                                    }
                                    else { 
                                        $Arguments += " --gpu-id $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                    }

                                    # Allow more time to build larger DAGs, must use type cast to keep values in $_
                                    $WarmupTimes = [UInt16[]]$_.WarmupTimes
                                    $WarmupTimes[0] += [UInt16](($Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB) * 2)

                                    if ($_.Algorithms[0] -eq "KawPow" -and "HashCryptos", "MiningDutch" -contains $Pool0) { $Arguments += " --retry-time 1" }

                                    # Apply tuning parameters
                                    if ($_.Type -eq "CPU" -and -not $Session.ApplyMinerTweaks) { $_.Arguments += " --disable-msr-tweaks" }

                                    [PSCustomObject]@{ 
                                        API              = "SRBMiner"
                                        Arguments        = "$Arguments --api-rig-name $($Session.Config.Pools.($Pool0.Name).WorkerName) --api-enable --api-port $MinerAPIPort"
                                        DeviceNames      = $AvailableMinerDevices.Name
                                        Fee              = $_.Fee # Dev fee
                                        MinerUri         = "http://127.0.0.1:$($MinerAPIPort)/stats"
                                        Name             = $MinerName
                                        Path             = $Path
                                        Port             = $MinerAPIPort
                                        PrerequisitePath = $PrerequisitePath
                                        PrerequisiteURI  = $PrerequisiteURI
                                        Type             = $Type
                                        URI              = $URI
                                        WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                        Workers          = @($Pools.ForEach({ @{ Pool = $_ } }))
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
