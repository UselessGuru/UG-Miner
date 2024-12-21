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
Version:        6.3.22
Version date:   2024/12/21
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ "AMD", "INTEL" -contains $_.Type -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.OpenCL.DriverVersion -ge [System.Version]"460.27.03") }))) { Return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/BzMiner/bzminer_v21.5.3_windows.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\bzminer.exe"
$DeviceEnumerator = "Bus"

$Algorithms = @(
    @{ Algorithms = @("Autolykos2");                      Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = @();                 ExcludeGPUmodel = ""; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a ergo") }
    @{ Algorithms = @("Blake3");                          Type = "AMD"; Fee = @(0.005); MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = @();                 ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a alph") } #https://github.com/bzminer/bzminer/issues
    @{ Algorithms = @("DynexSolve");                      Type = "AMD"; Fee = @(0.005); MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = @();                 ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a dynex") }
    @{ Algorithms = @("EtcHash");                         Type = "AMD"; Fee = @(0.005); MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = @("GCN4");           ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a etchash") } # https://github.com/bzminer/bzminer/issues/264
    @{ Algorithms = @("Ethash");                          Type = "AMD"; Fee = @(0.005); MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = @("GCN4");           ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a ethash") } # https://github.com/bzminer/bzminer/issues/264
    @{ Algorithms = @("EthashB3");                        Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = @("RDNA1", "RDNA2"); ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a rethereum") } # https://github.com/bzminer/bzminer/issues/324
    @{ Algorithms = @("FishHash");                        Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.24; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                 ExcludeGPUmodel = ""; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a ironfish") } # https://github.com/bzminer/bzminer/issues/260
    @{ Algorithms = @("FishHash", "JanusHash");           Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.24; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                 ExcludeGPUmodel = ""; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a ironfish", " --a2 warthog") } # https://github.com/bzminer/bzminer/issues/260
    @{ Algorithms = @("HeavyHashKarlsenV2");              Type = "AMD"; Fee = @(0.01);  MinMemGiB = 2;    MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @();                 ExcludeGPUmodel = ""; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a karlsen") }
    @{ Algorithms = @("HeavyHashKarlsenV2", "JanusHash"); Type = "AMD"; Fee = @(0.01);  MinMemGiB = 2;    MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @();                 ExcludeGPUmodel = ""; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a karlsen", " --a2 warthog") }
#   @{ Algorithms = @("HeavyHashKaspa");                  Type = "AMD"; Fee = @(0.01);  MinMemGiB = 2;    MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = @();                 ExcludeGPUmodel = ""; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a kaspa") } # ASIC
    @{ Algorithms = @("JanusHash");                       Type = "AMD"; Fee = @(0.01);  MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                 ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a warthog") }
    @{ Algorithms = @("KawPow");                          Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.08; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = @("GCN4");           ExcludeGPUmodel = ""; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a rvn") } # https://github.com/bzminer/bzminer/issues/264
    @{ Algorithms = @("NexaPow");                         Type = "AMD"; Fee = @(0.02);  MinMemGiB = 3;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = @();                 ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a nexa") }
    @{ Algorithms = @("SHA512256d");                      Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = @("GCN1");           ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a radiant") }
    @{ Algorithms = @("SHA256dt");                        Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = @();                 ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a novo") }
    @{ Algorithms = @("SHA3d");                           Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = @();                 ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a kylacoin") }
    @{ Algorithms = @("Skein2");                          Type = "AMD"; Fee = @(0.01);  MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = @();                 ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a woodcoin") }

#   @{ Algorithms = @("Blake3");                          Type = "INTEL"; Fee = @(0.005); MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a alph") } # https://github.com/bzminer/bzminer/issues
    @{ Algorithms = @("DynexSolve");                      Type = "INTEL"; Fee = @(0.005); MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a dynex") }
    @{ Algorithms = @("EtcHash");                         Type = "INTEL"; Fee = @(0.005); MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 25); ExcludeGPUarchitectures = @(); ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a etchash") }
    @{ Algorithms = @("Ethash");                          Type = "INTEL"; Fee = @(0.005); MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = @(); ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a ethash") }
    @{ Algorithms = @("EthashB3");                        Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = @(); ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a rethereum") }
    @{ Algorithms = @("FishHash");                        Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1.24; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @(); ExcludeGPUmodel = ""; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a ironfish") } # https://github.com/bzminer/bzminer/issues/260
    @{ Algorithms = @("FishHash", "JanusHash");           Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1.24; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @(); ExcludeGPUmodel = ""; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a ironfish", " --a2 warthog") } # https://github.com/bzminer/bzminer/issues/260
    @{ Algorithms = @("HeavyHashKarlsenV2");              Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = @(); ExcludeGPUmodel = ""; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a karlsen") }
    @{ Algorithms = @("HeavyHashKarlsenV2", "JanusHash"); Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = @(); ExcludeGPUmodel = ""; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a karlsen", " --a2 warthog") }
    @{ Algorithms = @("JanusHash");                       Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @(); ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a warthog") }
    @{ Algorithms = @("KawPow");                          Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a rvn") }
    @{ Algorithms = @("SHA512256d");                      Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludeGPUmodel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a radiant") }

    @{ Algorithms = @("Autolykos2");                      Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "";            ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a ergo") }
#   @{ Algorithms = @("Autolykos2", "HeavyHashKaspa");    Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "^MX[1|2]\d+"; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a ergo", " --a2 kaspa") } # ASIC
    @{ Algorithms = @("Autolykos2", "SHA512256d");        Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "^MX[1|2]\d+"; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a ergo", " --a2 radiant") }
#   @{ Algorithms = @("Blake3");                          Type = "NVIDIA"; Fee = @(0.005);      MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 5);  ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "";            ExcludePools = @(@(), @());           Arguments = @(" -a alph") } # https://github.com/bzminer/bzminer/issues
    @{ Algorithms = @("DynexSolve");                      Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = @("Other"); ExcludeGPUmodel = "";            ExcludePools = @(@(), @());           Arguments = @(" -a dynex") }
    @{ Algorithms = @("EtcHash");                         Type = "NVIDIA"; Fee = @(0.005);      MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "";            ExcludePools = @(@(), @());           Arguments = @(" -a etchash") }
    @{ Algorithms = @("EtcHash", "Blake3");               Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "";            ExcludePools = @(@(), @("NiceHash")); Arguments = @(" -a etchash", " --a2 alph") }
    @{ Algorithms = @("EtcHash", "FishHash");             Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "";            ExcludePools = @(@(), @("NiceHash")); Arguments = @(" -a etchash", " --a2 ironfish") } # https://github.com/bzminer/bzminer/issues/260
#   @{ Algorithms = @("EtcHash", "HeavyHashKaspa");       Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());           Arguments = @(" -a etchash", " --a2 kaspa") } # ASIC
#   @{ Algorithms = @("EtcHash", "SHA512256d");           Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(90, 60); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());           Arguments = @(" -a etchash", " --a2 radiant") } # https://github.com/bzminer/bzminer/issues/328
    @{ Algorithms = @("Ethash");                          Type = "NVIDIA"; Fee = @(0.005);      MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 10); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "";            ExcludePools = @(@(), @());           Arguments = @(" -a ethash") }
    @{ Algorithms = @("Ethash", "Blake3");                Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "";            ExcludePools = @(@(), @("NiceHash")); Arguments = @(" -a ethash", " --a2 alph") }
    @{ Algorithms = @("Ethash", "FishHash");              Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "";            ExcludePools = @(@(), @("NiceHash")); Arguments = @(" -a ethash", " --a2 ironfish") } # https://github.com/bzminer/bzminer/issues/260
#   @{ Algorithms = @("Ethash", "HeavyHashKaspa");        Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "^MX[1|2]\d+"; ExcludePools = @(@(), @("NiceHash")); Arguments = @(" -a ethash", " --a2 kaspa") } # ASIC
    @{ Algorithms = @("Ethash", "SHA512256d");            Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(90, 60); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());           Arguments = @(" -a ethash", " --a2 radiant") }
    @{ Algorithms = @("EthashB3");                        Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "";            ExcludePools = @(@(), @());           Arguments = @(" -a rethereum") }
    @{ Algorithms = @("FishHash");                        Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.24; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "";            ExcludePools = @(@(), @());           Arguments = @(" -a ironfish") }
    @{ Algorithms = @("FishHash", "JanusHash");           Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.24; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "";            ExcludePools = @(@(), @());           Arguments = @(" -a ironfish", " --a2 warthog") }
    @{ Algorithms = @("HeavyHashKarlsenV2");              Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "";            ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a karlsen") }
    @{ Algorithms = @("HeavyHashKarlsenV2", "JanusHash"); Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "";            ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a karlsen", " --a2 warthog") }
#   @{ Algorithms = @("HeavyHashKaspa");                  Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "^MX[1|2]\d+"; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a kaspa") } # ASIC
    @{ Algorithms = @("JanusHash");                       Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "";            ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -a warthog") }
    @{ Algorithms = @("KawPow");                          Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());           Arguments = @(" -a rvn") }
    @{ Algorithms = @("NexaPow");                         Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 3;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "";            ExcludePools = @(@(), @());           Arguments = @(" -a nexa") }
    @{ Algorithms = @("SHA512256d");                      Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 5);  ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());           Arguments = @(" -a radiant") }
    @{ Algorithms = @("SHA256dt");                        Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 5);  ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());           Arguments = @(" -a novo") }
    @{ Algorithms = @("SHA3d");                           Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 5);  ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());           Arguments = @(" -a kylacoin") }
    @{ Algorithms = @("Skein2");                          Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 5);  ExcludeGPUarchitectures = @();        ExcludeGPUmodel = "";            ExcludePools = @(@(), @());           Arguments = @(" -a woodcoin") }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms.Where({ -not $_.Algorithms[1] }).ForEach({ $_.Algorithms += "" })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] -and $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] })
$Algorithms = $Algorithms.Where({ $Config.SSL -ne "Always" -or ($MinerPools[0][$_.Algorithms[0]].SSLselfSignedCertificate -ne $true -and (-not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]].SSLselfSignedCertificate -eq $false)) })

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Model -eq $Model -and $_.Type -eq $Type })
            $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    $ExcludeGPUmodel = $_.ExcludeGPUmodel
                    If ($SupportedMinerDevices = $MinerDevices.Where({ (-not $ExcludeGPUmodel -or $_.Model -notmatch $ExcludeGPUmodel) -and $ExcludeGPUarchitectures -notcontains $_.Architecture })) { 

                        $ExcludePools = $_.ExcludePools
                        ForEach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $ExcludePools[0] -notcontains $_.Name -and ($Config.SSL -ne "Always" -or $_.SSLselfSignedCertificate -ne $true) })) { 
                            ForEach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $ExcludePools[1] -notcontains $_.Name -and ($Config.SSL -ne "Always" -or $_.SSLselfSignedCertificate -ne $true) })) { 

                                $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB
                                If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(If ($Pool1) { "&$($Pool1.AlgorithmVariant)" })"

                                    $Arguments = $_.Arguments[0]
                                    Switch ($Pool0.Protocol) { 
                                        "ethproxy"     { $Arguments += " -p ethproxy" }
                                        "ethstratum1"  { $Arguments += " -p ethstratum" }
                                        "ethstratum2"  { $Arguments += " -p ethstratum2" }
                                        "ethstratumnh" { $Arguments += " -p ethstratum" }
                                        Default        { $Arguments += " -p stratum" }
                                    }
                                    $Arguments += If ($Pool0.PoolPorts[1]) { "+ssl://" } Else { "+tcp://" }
                                    $Arguments += "$($Pool0.Host):$($Pool0.PoolPorts | Select-Object -Last 1)"
                                    $Arguments += " -w $($Pool0.User)"
                                    $Arguments += " --pool_password $($Pool0.Pass)"
                                    $Arguments += " -r $($Config.WorkerName)"

                                    If ($_.Algorithms[1]) { 
                                        $Arguments += $_.Arguments[1]
                                        Switch ($Pool1.Protocol) { 
                                            "ethproxy"     { $Arguments += " --p2 ethproxy" }
                                            "ethstratum1"  { $Arguments += " --p2 ethstratum" }
                                            "ethstratum2"  { $Arguments += " --p2 ethstratum2" }
                                            "ethstratumnh" { $Arguments += " --p2 ethstratum" }
                                            Default        { $Arguments += " --p2 stratum" }
                                        }
                                        $Arguments += If ($Pool1.PoolPorts[1]) { "+ssl://" } Else { "+tcp://" }
                                        $Arguments += "$($Pool1.Host):$($Pool1.PoolPorts | Select-Object -Last 1)"
                                        $Arguments += " --w2 $($Pool1.User)"
                                        $Arguments += " --pool_password2 $($Pool1.Pass)"
                                        $Arguments += " --r2 $($Config.WorkerName)"
                                    }

                                    # Allow more time to build larger DAGs, must use type cast to keep values in $_
                                    $WarmupTimes = [UInt16[]]$_.WarmupTimes
                                    $WarmupTimes[0] += [UInt16](($Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB) * 2)

                                    # Apply tuning parameters
                                    If ($Variables.ApplyMinerTweaks) { $Arguments += $_.Tuning }

                                    [PSCustomObject]@{ 
                                        API              = "BzMiner"
                                        Arguments        = "$Arguments -v 2 --nc 1 --no_watchdog --avg_hr_ms 1000 --restart_on_disconnect 0 --http_enabled 1 --http_port $MinerAPIPort --enable $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0}:0' -f $_ }) -join ' ')"
                                        DeviceNames      = $AvailableMinerDevices.Name
                                        Fee              = $_.Fee # Dev fee
                                        MinerSet         = $_.MinerSet
                                        MinerUri         = "http://127.0.0.1:$($MinerAPIPort)"
                                        Name             = $MinerName
                                        Path             = $Path
                                        Port             = $MinerAPIPort
                                        Type             = $_.Type
                                        URI              = $URI
                                        WarmupTimes      = $WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                        Workers          = @(($Pool0, $Pool1).Where({ $_ }).ForEach({ @{ Pool = $_ } }))
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