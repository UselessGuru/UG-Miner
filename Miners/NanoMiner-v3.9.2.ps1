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
Version:        6.3.2
Version date:   2024/09/09
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "CPU" -or $_.Type -ne "NVIDIA" -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.OpenCL.DriverVersion -ge [Version]"455.23") }))) { Return }

$URI = "https://github.com/nanopool/nanominer/releases/download/v3.9.2/nanominer-windows-3.9.2.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\nanominer.exe"
$DeviceEnumerator = "Slot"

$Algorithms = @(
    @{ Algorithms = @("Autolykos2");                   Type = "AMD"; Fee = @(0.025);        MinMemGiB = 1.08; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = @();       ExcludePools = @(@("NiceHash"), @());                                     Arguments = @(" -algo Autolykos") } # NBMiner-v42.3 is fastest
#   @{ Algorithms = @("Autolykos2", "HeavyHashKaspa"); Type = "AMD"; Fee = @(0.025, 0.025); MinMemGiB = 1.24; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 10); ExcludeGPUarchitectures = @();       ExcludePools = @(@("NiceHash"), @("NiceHash", "ProHashing", "ZergPool")); Arguments = @(" -algo Autolykos", " -algo Kaspa -protocol JSON-RPC") } # NBMiner-v42.3 is fastest
    @{ Algorithms = @("Blake3");                       Type = "AMD"; Fee = @(0.01);         MinMemGiB = 2;    MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45,  0); ExcludeGPUarchitectures = @();       ExcludePools = @(@(), @());                                               Arguments = @(" -algo Alephium") }
    @{ Algorithms = @("EtcHash");                      Type = "AMD"; Fee = @(0.01);         MinMemGiB = 1.08; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45,  0); ExcludeGPUarchitectures = @();       ExcludePools = @(@(), @());                                               Arguments = @(" -algo Etchash") } # PhoenixMiner-v6.2c is fastest
#   @{ Algorithms = @("EtcHash", "HeavyHashKaspa");    Type = "AMD"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @("GCN4"); ExcludePools = @(@(), @("NiceHash", "ProHashing", "ZergPool"));           Arguments = @(" -algo Etchash"," -algo Kaspa -protocol JSON-RPC") } # ASIC
    @{ Algorithms = @("Ethash");                       Type = "AMD"; Fee = @(0.01);         MinMemGiB = 1.08; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(@(), @());                                               Arguments = @(" -algo Ethash") } # PhoenixMiner-v6.2c is fastest
#   @{ Algorithms = @("Ethash", "HeavyHashKaspa");     Type = "AMD"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @("GCN4"); ExcludePools = @(@(), @("NiceHash", "ProHashing", "ZergPool"));           Arguments = @(" -algo Ethash"," -algo Kaspa -protocol JSON-RPC") } # ASIC
    @{ Algorithms = @("EthashB3");                     Type = "AMD"; Fee = @(0.01);         MinMemGiB = 1.08; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @();       ExcludePools = @(@(), @());                                               Arguments = @(" -algo EthashB3") }
#   @{ Algorithms = @("EthashB3", "HeavyHashKaspa");   Type = "AMD"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @("GCN4"); ExcludePools = @(@(), @("NiceHash", "ProHashing", "ZergPool"));           Arguments = @(" -algo EthashB3", " -algo Kaspa -protocol JSON-RPC") } # ASIC
    @{ Algorithms = @("EvrProgPow");                   Type = "AMD"; Fee = @(0.02);         MinMemGiB = 1.08; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @();       ExcludePools = @(@(), @());                                               Arguments = @(" -algo Evrprogpow") }
    @{ Algorithms = @("FiroPow");                      Type = "AMD"; Fee = @(0.01);         MinMemGiB = 1.08; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(@(), @());                                               Arguments = @(" -algo FiroPow") }
    @{ Algorithms = @("FishHash");                     Type = "AMD"; Fee = @(0.01);         MinMemGiB = 1.08; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(@(), @());                                               Arguments = @(" -algo Fishhash") } # https://github.com/nanopool/nanominer/issues/427
    @{ Algorithms = @("HeavyHashKarlsen");             Type = "AMD"; Fee = @(0.01);         MinMemGiB = 2;    MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(@(), @());                                               Arguments = @(" -algo Karlsen") }
    @{ Algorithms = @("HeavyHashPyrin");               Type = "AMD"; Fee = @(0.01);         MinMemGiB = 2;    MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(@(), @());                                               Arguments = @(" -algo Pyrin") }
#   @{ Algorithms = @("HeavyHashKaspa");               Type = "AMD"; Fee = @(0.01);         MinMemGiB = 2;    MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(@("NiceHash", "ProHashing", "ZergPool"), @());           Arguments = @(" -algo Kaspa -protocol JSON-RPC") } # ASIC
    @{ Algorithms = @("KawPow");                       Type = "AMD"; Fee = @(0.02);         MinMemGiB = 1.08; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(@("ProHashing"), @());                                   Arguments = @(" -algo KawPow") } # TeamRedMiner-v0.10.21 is fastest
    @{ Algorithms = @("UbqHash");                      Type = "AMD"; Fee = @(0.01);         MinMemGiB = 1.08; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(@(), @());                                               Arguments = @(" -algo Ubqhash") } # PhoenixMiner-v6.2c is fastest
    @{ Algorithms = @("VertHash");                     Type = "AMD"; Fee = @(0.01);         MinMemGiB = 3;    MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(@(), @());                                               Arguments = @(" -algo Verthash") }

#   @{ Algorithms = @("Randomx");    Type = "CPU"; Fee = @(0.02); MinerSet = 3; WarmupTimes = @(45, 0); ExcludeGPUarchitectures = @(); ExcludePools = @(@(), @()); Arguments = @(" -algo Randomx") } # ASIC
    @{ Algorithms = @("RandomNevo"); Type = "CPU"; Fee = @(0.02); MinerSet = 3; WarmupTimes = @(45, 0); ExcludeGPUarchitectures = @(); ExcludePools = @(@(), @()); Arguments = @(" -algo RandomNEVO") }
    @{ Algorithms = @("VerusHash");  Type = "CPU"; Fee = @(0.02); MinerSet = 3; WarmupTimes = @(69, 0); ExcludeGPUarchitectures = @(); ExcludePools = @(@(), @()); Arguments = @(" -algo Verushash") }

    @{ Algorithms = @("EtcHash");                    Type = "INTEL"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = @(); ExcludePools = @(@(), @());                                     Arguments = @(" -algo Etchash") }
#   @{ Algorithms = @("EtcHash", "HeavyHashKaspa");  Type = "INTEL"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = @(); ExcludePools = @(@(), @("NiceHash", "ProHashing", "ZergPool")); Arguments = @(" -algo Etchash", " -algo Kaspa -protocol JSON-RPC") } # ASIC
    @{ Algorithms = @("Ethash");                     Type = "INTEL"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(@(), @());                                     Arguments = @(" -algo Ethash") }
#   @{ Algorithms = @("Ethash", "HeavyHashKaspa");   Type = "INTEL"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @(); ExcludePools = @(@(), @("NiceHash", "ProHashing", "ZergPool")); Arguments = @(" -algo Ethash", " -algo Kaspa -protocol JSON-RPC") } # ASIC
    @{ Algorithms = @("EthashB3");                   Type = "INTEL"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(@(), @());                                     Arguments = @(" -algo EthashB3") }
#   @{ Algorithms = @("EthashB3", "HeavyHashKaspa"); Type = "INTEL"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @(); ExcludePools = @(@(), @("NiceHash", "ProHashing", "ZergPool")); Arguments = @(" -algo EthashB3", " -algo Kaspa -protocol JSON-RPC") } # ASIC
    @{ Algorithms = @("EvrProgPow");                 Type = "INTEL"; Fee = @(0.02);       MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(@(), @());                                     Arguments = @(" -algo Evrprogpow") }
    @{ Algorithms = @("FishHash");                   Type = "INTEL"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(@(), @());                                     Arguments = @(" -algo Fishhash") }
    @{ Algorithms = @("HeavyHashKarlsen");           Type = "INTEL"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(@(), @());                                     Arguments = @(" -algo Karlsen") }
#   @{ Algorithms = @("HeavyHashKaspa");             Type = "INTEL"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(@("NiceHash", "ProHashing", "ZergPool"), @()); Arguments = @(" -algo Kaspa -protocol JSON-RPC") } # ASIC
    @{ Algorithms = @("KawPow");                     Type = "INTEL"; Fee = @(0.02);       MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(@("ProHashing"), @());                         Arguments = @(" -algo KawPow") } # Trex-v0.26.8 is fastest
    @{ Algorithms = @("Octopus");                    Type = "INTEL"; Fee = @(0.02);       MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(@(), @());                                     Arguments = @(" -algo Octopus") } # NBMiner-v42.3 is faster
    @{ Algorithms = @("UbqHash");                    Type = "INTEL"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(75, 45); ExcludeGPUarchitectures = @(); ExcludePools = @(@(), @());                                     Arguments = @(" -algo Ubqhash") }

    @{ Algorithms = @("Autolykos2");                 Type = "NVIDIA"; Fee = @(0.025);      MinMemGiB = 1.08; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();        ExcludePools = @(@("NiceHash"), @());                            Arguments = @(" -algo Autolykos") } # Trex-v0.26.8 is fastest    @{ Algorithms = @("Autolykos2", "HeavyHashKaspa"); Type = "NVIDIA"; Fee = @(0.025, 0.025); MinMemGiB = 1.24; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@("NiceHash"), @("NiceHash", "ProHashing", "ZergPool")); ExcludeGPUarchitectures = @();        Arguments = @(" -algo Autolykos", " -algo Kaspa -protocol JSON-RPC") } # ASIC
    @{ Algorithms = @("Blake3");                     Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @("Other"); ExcludePools = @(@(), @());                                      Arguments = @(" -algo Alephium") }
    @{ Algorithms = @("EtcHash");                    Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();        ExcludePools = @(@(), @());                                      Arguments = @(" -algo Etchash") } # PhoenixMiner-v6.2c is fastest
#   @{ Algorithms = @("EtcHash", "HeavyHashKaspa");  Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @();        ExcludePools = @(@(), @("NiceHash", "ProHashing", "ZergPool"));  Arguments = @(" -algo Etchash", " -algo Kaspa -protocol JSON-RPC") } # ASIC
    @{ Algorithms = @("Ethash");                     Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @("Other"); ExcludePools = @(@(), @());                                      Arguments = @(" -algo Ethash") } # PhoenixMiner-v6.2c is fastest
#   @{ Algorithms = @("Ethash", "HeavyHashKaspa");   Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @("Other"); ExcludePools = @(@(), @("NiceHash", "ProHashing", "ZergPool"));  Arguments = @(" -algo Ethash", " -algo Kaspa -protocol JSON-RPC") } # ASIC
    @{ Algorithms = @("EthashB3");                   Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @("Other"); ExcludePools = @(@(), @());                                      Arguments = @(" -algo EthashB3") }
#   @{ Algorithms = @("EthashB3", "HeavyHashKaspa"); Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @("Other"); ExcludePools = @(@(), @("NiceHash", "ProHashing", "ZergPool"));  Arguments = @(" -algo EthashB3", " -algo Kaspa -protocol JSON-RPC") } # ASIC
    @{ Algorithms = @("EvrProgPow");                 Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 1.08; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();        ExcludePools = @(@(), @());                                      Arguments = @(" -algo Evrprogpow") }
    @{ Algorithms = @("FiroPow");                    Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 0; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();        ExcludePools = @(@(), @());                                      Arguments = @(" -algo FiroPow") }
    @{ Algorithms = @("FishHash");                   Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();        ExcludePools = @(@(), @());                                      Arguments = @(" -algo Fishhash") }
    @{ Algorithms = @("HeavyHashKarlsen");           Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();        ExcludePools = @(@(), @());                                      Arguments = @(" -algo Karlsen") }
    @{ Algorithms = @("HeavyHashPyrin");             Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();        ExcludePools = @(@(), @());                                      Arguments = @(" -algo Pyrin") }
#   @{ Algorithms = @("HeavyHashKaspa");             Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();        ExcludePools = @(@("NiceHash", "ProHashing", "ZergPool"), @());  Arguments = @(" -algo Kaspa -protocol JSON-RPC") } # ASIC
    @{ Algorithms = @("KawPow");                     Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 1.08; MinerSet = 0; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();        ExcludePools = @(@("ProHashing"), @());                          Arguments = @(" -algo KawPow") } # Trex-v0.26.8 is fastest
    @{ Algorithms = @("Octopus");                    Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 1.08; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();        ExcludePools = @(@(), @());                                      Arguments = @(" -algo Octopus") } # NBMiner-v42.3 is faster
    @{ Algorithms = @("UbqHash");                    Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();        ExcludePools = @(@(), @());                                      Arguments = @(" -algo Ubqhash") } # PhoenixMiner-v6.2c is fastest
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms.Where({ -not $_.Algorithms[1] }).ForEach({ $_.Algorithms += "" })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] -and $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] })
$Algorithms = $Algorithms.Where({ $Config.SSL -ne "Always" -or ($MinerPools[0][$_.Algorithms[0]].SSLselfSignedCertificate -ne $true -and (-not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]].SSLselfSignedCertificate -eq $false)) })

If ($Algorithms) { 

    ($Devices | Select-Object Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    If ($SupportedMinerDevices = $MinerDevices.Where({ $_.Type -eq "CPU" -or $ExcludeGPUarchitectures -notcontains $_.Architecture })) { 

                        If ($_.Algorithm -eq "VertHash" -and (Get-Item -Path $Variables.VerthashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                            $PrerequisitePath = $Variables.VerthashDatPath
                            $PrerequisiteURI = "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/VertHashDataFile/VertHash.dat"
                        }
                        Else { 
                            $PrerequisitePath = ""
                            $PrerequisiteURI = ""
                        }
    
                        $ExcludePools = $_.ExcludePools
                        ForEach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $ExcludePools[0] -notcontains $_.Name[0] -and ($Config.SSL -ne "Always" -or $_.SSLselfSignedCertificate -ne $true) }) | Select-Object -Last $(If ($_.Type -eq "CPU") { 1 } Else { $MinerPools[0][$_.Algorithms[0]].Count })) { 
                            ForEach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $ExcludePools[1] -notcontains $_.Name[1] -and ($Config.SSL -ne "Always" -or $_.SSLselfSignedCertificate -ne $true) }) | Select-Object -Last $(If ($_.Type -eq "CPU") { 1 } Else { $MinerPools[1][$_.Algorithms[1]].Count })) { 
                                $Pools = @(($Pool0, $Pool1).Where({ $_ }))

                                $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB
                                If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.Type -eq "CPU" -or $_.MemoryGiB -ge $MinMemGiB })) { 

                                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(If ($Pool1) { "&$($Pool1.AlgorithmVariant)" })"

                                    $Arguments = ""
                                    ForEach ($Pool in $Pools) { 
                                        $Arguments += "$($_.Arguments[$Pools.IndexOf($Pool)])"
                                        $Arguments += If ($Pool.PoolPorts[1] -and $Pool.SSLselfSignedCertificate -ne $true) { " -pool1 $($Pool.Host):$($Pool.PoolPorts[1])" } Else { " -pool1 $($Pool.Host):$($Pool.PoolPorts[0]) -useSSL false" }
                                        $Arguments += " -wallet $($Pool.User -replace '\..+')"
                                        $Arguments += " -rigName $($Pool.User)$(If ($Pool.WorkerName -and $Pool.User -notmatch "\.$($Pool.WorkerName)$") { $Pool.WorkerName })"
                                        $Arguments += " -rigPassword $($Pool.Pass)"
                                        $Arguments += " -devices $(($AvailableMinerDevices | Sort-Object Name -Unique).ForEach({ '{0:x}' -f $_.$DeviceEnumerator }) -join ',')"
                                    }
                                    Remove-Variable Pool

                                    $Arguments += " -mport 0 -webPort $MinerAPIPort -checkForUpdates false -noLog true -watchdog false"

                                    # Apply tuning parameters
                                    If ($Variables.ApplyMinerTweaks) { $Arguments += $_.Tuning }

                                    [PSCustomObject]@{ 
                                        API              = "NanoMiner"
                                        Arguments        = $Arguments
                                        DeviceNames      = $AvailableMinerDevices.Name
                                        Fee              = $_.Fee # Dev fee
                                        MinerSet         = $_.MinerSet
                                        MinerUri         = "http://127.0.0.1:$($MinerAPIPort)/#/"
                                        Name             = $MinerName
                                        Path             = $Path
                                        Port             = $MinerAPIPort
                                        PrerequisitePath = $PrerequisitePath
                                        PrerequisiteURI  = $PrerequisiteURI
                                        Type             = $_.Type
                                        URI              = $URI
                                        WarmupTimes      = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
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