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

using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices.Where({ ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 1.2") -or $_.OpenCL.ComputeCapability -ge "5.0" }))) { Return }

$URI = "https://github.com/develsoftware/GMinerRelease/releases/download/3.44/gminer_3_44_windows64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\miner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
#   [PSCustomObject]@{ Algorithms = @("Autolykos2");   Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.24; Tuning = ""; MinerSet = 2; WarmupTimes = @(30, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 1 --algo autolykos2 --cuda 0 --opencl 1" } # Algorithm not yet supported
#   [PSCustomObject]@{ Algorithms = @("Cuckatoo32");   Type = "AMD"; Fee = @(0.05);  MinMemGiB = 8.0;  Tuning = ""; MinerSet = 3; WarmupTimes = @(30, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 1 --algo cuckatoo32 --cuda 0 --opencl 1" } # ASIC
    [PSCustomObject]@{ Algorithms = @("Equihash1254"); Type = "AMD"; Fee = @(0.02);  MinMemGiB = 1.8;  Tuning = ""; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 1 --algo equihash125_4 --cuda 0 --opencl 1" } # lolMiner-v1.86 is fastest
#   [PSCustomObject]@{ Algorithms = @("Equihash1445"); Type = "AMD"; Fee = @(0.02);  MinMemGiB = 1.8;  Tuning = ""; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludePools = @(@("ProHashing"), @()); AutoCoinPers = " --pers auto"; Arguments = " --nvml 1 --algo equihash144_5 --cuda 0 --opencl 1" } # FPGA # https://github.com/develsoftware/GMinerRelease/issues/906
    [PSCustomObject]@{ Algorithms = @("Equihash2109"); Type = "AMD"; Fee = @(0.02);  MinMemGiB = 2.8;  Tuning = ""; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 1 --algo equihash210_9 --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithms = @("Ethash");       Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.24; Tuning = ""; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 1 --algo ethash --cuda 0 --opencl 1" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("KawPow");       Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.24; Tuning = ""; MinerSet = 2; WarmupTimes = @(45, 30); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 1 --algo kawpow --cuda 0 --opencl 1" }

    [PSCustomObject]@{ Algorithms = @("Autolykos2");                   Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo autolykos2 --cuda 1 --opencl 0" }
#   [PSCustomObject]@{ Algorithms = @("Autolykos2", "HeavyHashKaspa"); Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @("NiceHash"));   AutoCoinPers = "";             Arguments = " --nvml 0 --algo autolykos2 --dalgo kheavyhash --cuda 1 --opencl 0" } # ASIC
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "SHA512256d");     Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo autolykos2 --dalgo radiant --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("BeamV3");                       Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 6.0;  Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo beamhash --cuda 1 --opencl 0" }
#   [PSCustomObject]@{ Algorithms = @("Cuckatoo32");                   Type = "NVIDIA"; Fee = @(0.05);       MinMemGiB = 8.0;  Tuning = " --mt 2"; MinerSet = 3; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo cuckatoo32 --cuda 1 --opencl 0" } # ASIC
    [PSCustomObject]@{ Algorithms = @("Cuckaroo30CTX");                Type = "NVIDIA"; Fee = @(0.05);       MinMemGiB = 8.0;  Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo cortex --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("Cuckoo29");                     Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 6.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo aeternity --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("Equihash1254");                 Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 3.0;  Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo equihash125_4 --cuda 1 --opencl 0" } # MiniZ-v2.4.d is fastest
    [PSCustomObject]@{ Algorithms = @("Equihash1445");                 Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 2.1;  Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@("ProHashing"), @()); AutoCoinPers = " --pers auto"; Arguments = " --nvml 0 --algo equihash144_5 --cuda 1 --opencl 0" } # FPGA
    [PSCustomObject]@{ Algorithms = @("Equihash2109");                 Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 1.0;  Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo equihash210_9 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("EtcHash");                      Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @("NiceHash"));   AutoCoinPers = "";             Arguments = " --nvml 0 --algo etchash --cuda 1 --opencl 0" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EtcHash", "IronFish");          Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo etchash --dalgo ironfish --cuda 1 --opencl 0" }
#   [PSCustomObject]@{ Algorithms = @("EtcHash", "HeavyHashKaspa");    Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo etchash --dalgo kheavyhash --cuda 1 --opencl 0" } # ASIC
    [PSCustomObject]@{ Algorithms = @("EtcHash", "SHA512256d");        Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo etchash --dalgo radiant --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("Ethash");                       Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo ethash --cuda 1 --opencl 0" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("Ethash", "IronFish");           Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo ethash --dalgo ironfish --cuda 1 --opencl 0" }
#   [PSCustomObject]@{ Algorithms = @("Ethash", "HeavyHashKaspa");     Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo ethash --dalgo kheavyhash --cuda 1 --opencl 0" } # ASIC
    [PSCustomObject]@{ Algorithms = @("Ethash", "SHA512256d");         Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo ethash --dalgo radiant --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("FiroPow");                      Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo firo --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("IronFish");                     Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@("NiceHash"), @());   AutoCoinPers = "";             Arguments = " --nvml 0 --algo ironfish --cuda 1 --opencl 0" } # XmRig-v6.21.3.15 is almost as fast but has no fee
    [PSCustomObject]@{ Algorithms = @("KawPow");                       Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo kawpow --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("HeavyHashKarlsen");             Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo karlsen --cuda 1 --opencl 0" }
#   [PSCustomObject]@{ Algorithms = @("HeavyHashKaspa");               Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo kaspa --cuda 1 --opencl 0" } # ASIC
    [PSCustomObject]@{ Algorithms = @("Octopus");                      Type = "NVIDIA"; Fee = @(0.03);       MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo octopus --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("Octopus", "IronFish");          Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @("NiceHash"));   AutoCoinPers = "";             Arguments = " --nvml 0 --algo octopus --dalgo ironfish --cuda 1 --opencl 0" }
#   [PSCustomObject]@{ Algorithms = @("Octopus", "HeavyHashKaspa");    Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo octopus --dalgo kheavyhash --cuda 1 --opencl 0" } # ASIC
    [PSCustomObject]@{ Algorithms = @("Octopus", "SHA512256d");        Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo octopus --dalgo radiant --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("ProgPowSero");                  Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo sero --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("SHA512256d");                   Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.0;  Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --nvml 0 --algo radiant --cuda 1 --opencl 0" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms.Where({ -not $_.Algorithms[1] }).ForEach({ $_.Algorithms += "" })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] -and $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]].Name -notin $_.ExcludePools[0] })
$Algorithms = $Algorithms.Where({ $MinerPools[1][$_.Algorithms[1]].Name -notin $_.ExcludePools[1] })

If ($Algorithms) { 

    ($Devices | Select-Object Type, Model -Unique).ForEach(
        { 
            If ($MinerDevices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model) { 
                $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

                ($Algorithms | Where-Object Type -EQ $_.Type).ForEach(
                    { 
                        $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
                        If ($AvailableMinerDevices = $MinerDevices.Where({ $_.Architecture -notin $ExcludeGPUArchitecture })) { 

                            $ExcludePools = $_.ExcludePools
                            ForEach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $_.Name -notin $ExcludePools[0] })) { 
                                ForEach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $_.Name -notin $ExcludePools[1] })) { 

                                    $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB
                                    If ($AvailableMinerDevices = $AvailableMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($Pool0.AlgorithmVariant)$(If ($Pool1) { "&$($Pool1.AlgorithmVariant)" })"

                                        $Arguments = $_.Arguments
                                        $Arguments += " --server $($Pool0.Host):$($Pool0.PoolPorts | Select-Object -Last 1)"
                                        $Arguments += Switch ($Pool0.Protocol) { 
                                            "ethstratum1"  { " --proto stratum" }
                                            "ethstratum2"  { " --proto stratum" }
                                            "ethstratumnh" { " --proto stratum" }
                                            Default        { "" }
                                        }
                                        If ($Pool0.PoolPorts[1]) { $Arguments += " --ssl 1" }
                                        $Arguments += " --user $($Pool0.User)"
                                        $Arguments += " --pass $($Pool0.Pass)"
                                        If ($Pool0.WorkerName -and $Pool0.User -notmatch "\.$($Pool0.WorkerName)$") { $Arguments += " --worker $($Pool0.WorkerName)" }
                                        If ($_.AutoCoinPers) { $Arguments += $(Get-EquihashCoinPers -Command " --pers " -Currency $Pool.Currency -DefaultCommand $_.AutoCoinPers) }

                                        If (($_.Algorithms[1])) { 
                                            $Arguments += " --dserver $($Pool1.Host):$($Pool1.PoolPorts | Select-Object -Last 1)"
                                            If ($Pool1.PoolPorts[1]) { $Arguments += " --dssl 1" }
                                            $Arguments += " --duser $($Pool1.User)"
                                            $Arguments += " --dpass $($Pool1.Pass)"
                                            If ($Pool1.WorkerName -and $Pool1.User -notmatch "\.$($Pool1.WorkerName)$") { $Arguments += " --dworker $($Pool1.WorkerName)" }
                                        }

                                        # Apply tuning parameters
                                        If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                                        # Contest ETH address (if ETH wallet is specified in config)
                                        # $Arguments += If ($Config.Wallets.ETH) { " --contest_wallet $($Config.Wallets.ETH)" } Else { " --contest_wallet 0x92e6F22C1493289e6AD2768E1F502Fc5b414a287" }

                                        [PSCustomObject]@{ 
                                            API         = "Gminer"
                                            Arguments   = "$Arguments --api $MinerAPIPort --watchdog 0 --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ' ')"
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
                )
            }
        }
    )
}