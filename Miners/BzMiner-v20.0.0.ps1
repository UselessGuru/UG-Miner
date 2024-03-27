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
Version:        6.2.2
Version date:   2024/03/28
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -in @("AMD", "INTEL") -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.OpenCL.DriverVersion -ge [Version]"460.27.03") }))) { Return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/BzMiner/bzminer_v20.0.0_windows.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\bzminer.exe"
$DeviceEnumerator = "Bus"

$Algorithms = @(
    [PSCustomObject]@{ Algorithms = @("Autolykos2");       Type = "AMD"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@("Nicehash"), @());   Arguments = @(" -a ergo") }
    [PSCustomObject]@{ Algorithms = @("Blake3");           Type = "AMD"; Fee = @(0.005);      MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@(), @());             Arguments = @(" -a alph") }
    [PSCustomObject]@{ Algorithms = @("DynexSolve");       Type = "AMD"; Fee = @(0.005);      MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@(), @());             Arguments = @(" -a dynex") }
    [PSCustomObject]@{ Algorithms = @("EtcHash");          Type = "AMD"; Fee = @(0.005);      MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @("GCN4"); ExcludeGPUModel = ""; ExcludePools = @(@(), @());             Arguments = @(" -a etchash") } # https://github.com/bzminer/bzminer/issues/264
    [PSCustomObject]@{ Algorithms = @("Ethash");           Type = "AMD"; Fee = @(0.005);      MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @("GCN4"); ExcludeGPUModel = ""; ExcludePools = @(@(), @());             Arguments = @(" -a ethash") } # https://github.com/bzminer/bzminer/issues/264
    [PSCustomObject]@{ Algorithms = @("Ethash3B");         Type = "AMD"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@(), @());             Arguments = @(" -a rethereum") }
    [PSCustomObject]@{ Algorithms = @("HeavyHashKarlsen"); Type = "AMD"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@("Nicehash"), @());   Arguments = @(" -a karlsen") }
    [PSCustomObject]@{ Algorithms = @("HeavyHashKaspa");   Type = "AMD"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@("ProHashing"), @()); Arguments = @(" -a kaspa") }
    [PSCustomObject]@{ Algorithms = @("IronFish");         Type = "AMD"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@("Nicehash"), @());   Arguments = @(" -a ironfish") }# https://github.com/bzminer/bzminer/issues/260
    [PSCustomObject]@{ Algorithms = @("KawPow");           Type = "AMD"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("GCN4"); ExcludeGPUModel = ""; ExcludePools = @(@(), @());             Arguments = @(" -a rvn") } # https://github.com/bzminer/bzminer/issues/264
    [PSCustomObject]@{ Algorithms = @("NexaPow");          Type = "AMD"; Fee = @(0.02);       MinMemGiB = 3;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@(), @());             Arguments = @(" -a nexa") }
    [PSCustomObject]@{ Algorithms = @("SHA512256d");       Type = "AMD"; Fee = @(0.01);       MinMemGiB = 1;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@(), @());             Arguments = @(" -a radiant") }
    [PSCustomObject]@{ Algorithms = @("SHA256dt");         Type = "AMD"; Fee = @(0.01);       MinMemGiB = 1;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@(), @());             Arguments = @(" -a novo") }
    [PSCustomObject]@{ Algorithms = @("SHA3d");            Type = "AMD"; Fee = @(0.01);       MinMemGiB = 1;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@(), @());             Arguments = @(" -a kylacoin") }
    [PSCustomObject]@{ Algorithms = @("Skein2");           Type = "AMD"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@(), @());             Arguments = @(" -a woodcoin") }

    
    [PSCustomObject]@{ Algorithms = @("Blake3");           Type = "INTEL"; Fee = @(0.005); MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a alph") }
    [PSCustomObject]@{ Algorithms = @("DynexSolve");       Type = "INTEL"; Fee = @(0.005); MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a dynex") }
    [PSCustomObject]@{ Algorithms = @("EtcHash");          Type = "INTEL"; Fee = @(0.005); MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @(); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a etchash") }
    [PSCustomObject]@{ Algorithms = @("Ethash");           Type = "INTEL"; Fee = @(0.005); MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @(); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a ethash") }
    [PSCustomObject]@{ Algorithms = @("Ethash3B");         Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @(); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a rethereum") }
    [PSCustomObject]@{ Algorithms = @("HeavyHashKarlsen"); Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a karlsen") }
    [PSCustomObject]@{ Algorithms = @("IronFish");         Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = ""; ExcludePools = @(@("Nicehash"), @()); Arguments = @(" -a ironfish") } # https://github.com/bzminer/bzminer/issues/260
    [PSCustomObject]@{ Algorithms = @("KawPow");           Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a rvn") }
    [PSCustomObject]@{ Algorithms = @("SHA512256d");       Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a radiant") }

    [PSCustomObject]@{ Algorithms = @("Autolykos2");                   Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "";            ExcludePools = @(@("Nicehash"), @());             Arguments = @(" -a ergo") }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "HeavyHashKaspa"); Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@("Nicehash"), @("ProHashing")); Arguments = @(" -a ergo", " --a2 kaspa") }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "SHA512256d");     Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@("Nicehash"), @());             Arguments = @(" -a ergo", " --a2 radiant") }
    [PSCustomObject]@{ Algorithms = @("Blake3");                       Type = "NVIDIA"; Fee = @(0.005);      MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "";            ExcludePools = @(@(), @());                       Arguments = @(" -a alph") }
    [PSCustomObject]@{ Algorithms = @("DynexSolve");                   Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @("Other"); ExcludeGPUModel = "";            ExcludePools = @(@(), @());                       Arguments = @(" -a dynex") }
    [PSCustomObject]@{ Algorithms = @("EtcHash");                      Type = "NVIDIA"; Fee = @(0.005);      MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 20); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "";            ExcludePools = @(@(), @());                       Arguments = @(" -a etchash") }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake3");            Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "";            ExcludePools = @(@(), @());                       Arguments = @(" -a etchash", " --a2 alph") }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "HeavyHashKaspa");    Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @("ProHashing"));           Arguments = @(" -a etchash", " --a2 kaspa") }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "IronFish");          Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "";            ExcludePools = @(@(), @("Nicehash"));             Arguments = @(" -a etchash", " --a2 ironfish") } # https://github.com/bzminer/bzminer/issues/260
    [PSCustomObject]@{ Algorithms = @("EtcHash", "SHA512256d");        Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());                       Arguments = @(" -a etchash", " --a2 radiant") }
    [PSCustomObject]@{ Algorithms = @("Ethash");                       Type = "NVIDIA"; Fee = @(0.005);      MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 10); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "";            ExcludePools = @(@(), @());                       Arguments = @(" -a ethash") }
    [PSCustomObject]@{ Algorithms = @("Ethash", "Blake3");             Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "";            ExcludePools = @(@(), @());                       Arguments = @(" -a ethash", " --a2 alph") }
    [PSCustomObject]@{ Algorithms = @("Ethash", "HeavyHashKaspa");     Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());                       Arguments = @(" -a ethash", " --a2 kaspa") }
    [PSCustomObject]@{ Algorithms = @("Ethash", "IronFish");           Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "";            ExcludePools = @(@(), @("Nicehash"));             Arguments = @(" -a ethash", " --a2 ironfish") } # https://github.com/bzminer/bzminer/issues/260
    [PSCustomObject]@{ Algorithms = @("Ethash", "SHA512256d");         Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());                       Arguments = @(" -a ethash", " --a2 radiant") }
    [PSCustomObject]@{ Algorithms = @("Ethash3B");                     Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 20); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "";            ExcludePools = @(@(), @());                       Arguments = @(" -a rethereum") }
    [PSCustomObject]@{ Algorithms = @("HeavyHashKarlsen");             Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "";            ExcludePools = @(@("Nicehash"), @());             Arguments = @(" -a karlsen") }
    [PSCustomObject]@{ Algorithms = @("HeavyHashKaspa");               Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@("ProHashing"), @());           Arguments = @(" -a kaspa") }
    [PSCustomObject]@{ Algorithms = @("IronFish");                     Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "";            ExcludePools = @(@("Nicehash"), @());             Arguments = @(" -a ironfish") } # https://github.com/bzminer/bzminer/issues/260
    [PSCustomObject]@{ Algorithms = @("KawPow");                       Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(75, 15); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());                       Arguments = @(" -a rvn") }
    [PSCustomObject]@{ Algorithms = @("NexaPow");                      Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 3;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "";            ExcludePools = @(@(), @());                       Arguments = @(" -a nexa") }
    [PSCustomObject]@{ Algorithms = @("SHA512256d");                   Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());                       Arguments = @(" -a radiant") }
    [PSCustomObject]@{ Algorithms = @("SHA256dt");                     Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());                       Arguments = @(" -a novo") }
    [PSCustomObject]@{ Algorithms = @("SHA3d");                        Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());                       Arguments = @(" -a kylacoin") }
    [PSCustomObject]@{ Algorithms = @("Skein2");                       Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludeGPUModel = "";            ExcludePools = @(@(), @());                       Arguments = @(" -a woodcoin") }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms.Where({ -not $_.Algorithms[1] }) | ForEach-Object { $_.Algorithms += "" }
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] -and $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]].Name -notin $_.ExcludePools[0] })
$Algorithms = $Algorithms.Where({ $MinerPools[1][$_.Algorithms[1]].Name -notin $_.ExcludePools[1] })
$Algorithms = $Algorithms.Where({ $Config.SSL -ne "Always" -or ($MinerPools[0][$_.Algorithms[0]].SSLSelfSignedCertificate -ne $true -and (-not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]].SSLSelfSignedCertificate -ne $true)) })

If ($Algorithms) { 

    ($Devices | Select-Object Type, Model -Unique).ForEach(
        { 
            If ($Miner_Devices = $Devices | Where-Object Model -EQ $_.Model) { 
                $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

                ($Algorithms | Where-Object Type -EQ $_.Type).ForEach(
                    { 
                        $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
                        $ExcludeGPUModel = $_.ExcludeGPUModel
                        If ($AvailableMiner_Devices = $Miner_Devices.Where({ (-not $ExcludeGPUModel -or $_.Model -notmatch $ExcludeGPUModel) -and $_.Architecture -notin $ExcludeGPUArchitecture })) { 

                            $ExcludePools = $_.ExcludePools
                            ForEach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $_.Name -notin $ExcludePools[0] -and ($_.Ethash.Epoch -eq $null -or $_.Ethash.Epoch -gt 0) -and ($Config.SSL -ne "Always" -or $_.SSLSelfSignedCertificate -ne $true) })) { 
                                ForEach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $_.Name -notin $ExcludePools[1] -and ($Config.SSL -ne "Always" -or $_.SSLSelfSignedCertificate -ne $true) })) { 

                                    $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB
                                    If ($AvailableMiner_Devices = $AvailableMiner_Devices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                        $Miner_Name = "$Name-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)-$($Pool0.AlgorithmVariant)$(If ($Pool1) { "&$($Pool1.AlgorithmVariant)" })"

                                        $Arguments = $_.Arguments[0]
                                        Switch ($Pool0.Protocol) { 
                                            "ethproxy"     { $Arguments += " -p ethproxy" }
                                            "ethstratum1"  { $Arguments += " -p ethstratum" }
                                            "ethstratum2"  { $Arguments += " -p ethstratum2" }
                                            "ethstratumnh" { $Arguments += " -p ethstratum" }
                                            Default        { $Arguments += " -p stratum"}
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

                                        # Apply tuning parameters
                                        If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                                        [PSCustomObject]@{ 
                                            API              = "BzMiner"
                                            Arguments        = "$Arguments -v 3 --nc 1 --no_watchdog --http_enabled 1 --http_port $MinerAPIPort --enable $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0}:0' -f $_ }) -join ' ')"
                                            DeviceNames      = $AvailableMiner_Devices.Name
                                            Fee              = $_.Fee # Dev fee
                                            MinerSet         = $_.MinerSet
                                            MinerUri         = "http://127.0.0.1:$($MinerAPIPort)"
                                            Name             = $Miner_Name
                                            Path             = $Path
                                            Port             = $MinerAPIPort
                                            Type             = $_.Type
                                            URI              = $Uri
                                            WarmupTimes      = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                            Workers          = @(($Pool0, $Pool1).Where({ $_ }) | ForEach-Object { @{ Pool = $_ } })
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