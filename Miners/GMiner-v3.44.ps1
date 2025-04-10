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
Version:        6.4.23
Version date:   2025/04/10
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 1.2") -or $_.OpenCL.ComputeCapability -ge "5.0" }))) { Return }

$URI = "https://github.com/develsoftware/GMinerRelease/releases/download/3.44/gminer_3_44_windows64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\miner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
#   @{ Algorithms = @("Autolykos2", "");   Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.24; Tuning = ""; MinerSet = 2; WarmupTimes = @(30, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo autolykos2 --cuda 0 --opencl 1" } # Algorithm not yet supported
#   @{ Algorithms = @("Cuckatoo32", "");   Type = "AMD"; Fee = @(0.05);  MinMemGiB = 8.0;  Tuning = ""; MinerSet = 3; WarmupTimes = @(30, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo cuckatoo32 --cuda 0 --opencl 1" } # ASIC
    @{ Algorithms = @("Equihash1254", ""); Type = "AMD"; Fee = @(0.02);  MinMemGiB = 2.1;  Tuning = ""; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo equihash125_4 --cuda 0 --opencl 1" } # lolMiner-v1.94a is fastest
#   @{ Algorithms = @("Equihash1445", ""); Type = "AMD"; Fee = @(0.02);  MinMemGiB = 1.8;  Tuning = ""; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludePools = @(@("ProHashing"), @()); AutoCoinPers = " --pers auto"; Arguments = " --algo equihash144_5 --cuda 0 --opencl 1" } # FPGA # https://github.com/develsoftware/GMinerRelease/issues/906
    @{ Algorithms = @("Equihash2109", ""); Type = "AMD"; Fee = @(0.02);  MinMemGiB = 2.8;  Tuning = ""; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo equihash210_9 --cuda 0 --opencl 1" }
    @{ Algorithms = @("Ethash", "");       Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.24; Tuning = ""; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo ethash --cuda 0 --opencl 1" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithms = @("KawPow", "");       Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.24; Tuning = ""; MinerSet = 2; WarmupTimes = @(45, 30); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo kawpow --cuda 0 --opencl 1" }

    @{ Algorithms = @("AstroBWTv3", "");               Type = "NVIDIA"; Fee = @(0.05);       MinMemGiB = 13.0; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(30, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo dero --cuda 1 --opencl 0" }
    @{ Algorithms = @("Autolykos2", "");               Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(30, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo autolykos2 --cuda 1 --opencl 0" }
#   @{ Algorithms = @("Autolykos2", "HeavyHashKaspa"); Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @("NiceHash"));   AutoCoinPers = "";             Arguments = " --algo autolykos2 --dalgo kheavyhash --cuda 1 --opencl 0" } # ASIC
    @{ Algorithms = @("Autolykos2", "SHA512256d");     Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo autolykos2 --dalgo radiant --cuda 1 --opencl 0" }
    @{ Algorithms = @("BeamV3", "");                   Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 6.0;  Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(30, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo beamhash --cuda 1 --opencl 0" }
#   @{ Algorithms = @("Cuckatoo32", "");               Type = "NVIDIA"; Fee = @(0.05);       MinMemGiB = 8.0;  Tuning = " --mt 2"; MinerSet = 3; WarmupTimes = @(30, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo cuckatoo32 --cuda 1 --opencl 0" } # ASIC
    @{ Algorithms = @("Cuckaroo30CTX", "");            Type = "NVIDIA"; Fee = @(0.05);       MinMemGiB = 8.0;  Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(30, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo cortex --cuda 1 --opencl 0" }
    @{ Algorithms = @("Cuckoo29", "");                 Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 6.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(30, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo aeternity --cuda 1 --opencl 0" }
    @{ Algorithms = @("Equihash1254", "");             Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 3.0;  Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo equihash125_4 --cuda 1 --opencl 0" } # MiniZ-v2.4e is fastest
    @{ Algorithms = @("Equihash1445", "");             Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 2.1;  Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePools = @(@("ProHashing"), @()); AutoCoinPers = " --pers auto"; Arguments = " --algo equihash144_5 --cuda 1 --opencl 0" } # FPGA
    @{ Algorithms = @("Equihash2109", "");             Type = "NVIDIA"; Fee = @(0.02);       MinMemGiB = 1.0;  Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo equihash210_9 --cuda 1 --opencl 0" }
    @{ Algorithms = @("EtcHash", "");                  Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @("NiceHash"));   AutoCoinPers = "";             Arguments = " --algo etchash --cuda 1 --opencl 0" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithms = @("EtcHash", "IronFish");          Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo etchash --dalgo ironfish --cuda 1 --opencl 0" }
#   @{ Algorithms = @("EtcHash", "HeavyHashKaspa");    Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 15); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo etchash --dalgo kheavyhash --cuda 1 --opencl 0" } # ASIC
    @{ Algorithms = @("EtcHash", "SHA512256d");        Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 90); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo etchash --dalgo radiant --cuda 1 --opencl 0" }
    @{ Algorithms = @("Ethash", "");                   Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo ethash --cuda 1 --opencl 0" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithms = @("Ethash", "IronFish");           Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 20); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo ethash --dalgo ironfish --cuda 1 --opencl 0" }
#   @{ Algorithms = @("Ethash", "HeavyHashKaspa");     Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 15); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo ethash --dalgo kheavyhash --cuda 1 --opencl 0" } # ASIC
    @{ Algorithms = @("Ethash", "SHA512256d");         Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 90); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo ethash --dalgo radiant --cuda 1 --opencl 0" }
    @{ Algorithms = @("FiroPow", "");                  Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo firo --cuda 1 --opencl 0" }
    @{ Algorithms = @("IronFish", "");                 Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludePools = @(@("NiceHash"), @());   AutoCoinPers = "";             Arguments = " --algo ironfish --cuda 1 --opencl 0" } # XmRig-v6.22.0.3 is almost as fast but has no fee
    @{ Algorithms = @("KawPow", "");                   Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo kawpow --cuda 1 --opencl 0" }
    @{ Algorithms = @("HeavyHashKarlsen", "");         Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo karlsen --cuda 1 --opencl 0" }
#   @{ Algorithms = @("HeavyHashKaspa", "");           Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 2.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo kaspa --cuda 1 --opencl 0" } # ASIC
    @{ Algorithms = @("Octopus", "");                  Type = "NVIDIA"; Fee = @(0.03);       MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo octopus --cuda 1 --opencl 0" }
    @{ Algorithms = @("Octopus", "IronFish");          Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 20); ExcludePools = @(@(), @("NiceHash"));   AutoCoinPers = "";             Arguments = " --algo octopus --dalgo ironfish --cuda 1 --opencl 0" }
#   @{ Algorithms = @("Octopus", "HeavyHashKaspa");    Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 20); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo octopus --dalgo kheavyhash --cuda 1 --opencl 0" } # ASIC
    @{ Algorithms = @("Octopus", "SHA512256d");        Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 20); ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo octopus --dalgo radiant --cuda 1 --opencl 0" }
    @{ Algorithms = @("ProgPowSero", "");              Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.24; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo sero --cuda 1 --opencl 0" }
    @{ Algorithms = @("SHA512256d", "");               Type = "NVIDIA"; Fee = @(0.01);       MinMemGiB = 1.0;  Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             AutoCoinPers = "";             Arguments = " --algo radiant --cuda 1 --opencl 0" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] })
$Algorithms = $Algorithms.Where({ $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] })

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    If ($SupportedMinerDevices = $MinerDevices) { 

                        $ExcludePools = $_.ExcludePools
                        ForEach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $ExcludePools[0] -notcontains $_.Name })) { 
                            ForEach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $ExcludePools[1] -notcontains $_.Name })) { 

                                $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB
                                If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(If ($Pool1) { "&$($Pool1.AlgorithmVariant)" })"

                                    $Arguments = $_.Arguments
                                    $Arguments += " --server $($Pool0.Host):$($Pool0.PoolPorts | Select-Object -Last 1)"
                                    Switch ($Pool0.Protocol) { 
                                        "ethstratum1"  { $Arguments += " --proto stratum" }
                                        "ethstratum2"  { $Arguments += " --proto stratum" }
                                        "ethstratumnh" { $Arguments += " --proto stratum" }
                                    }
                                    If ($Pool0.PoolPorts[1]) { $Arguments += " --ssl 1" }
                                    $Arguments += " --user $($Pool0.User)"
                                    $Arguments += " --pass $($Pool0.Pass)"
                                    If ($Pool0.WorkerName -and $Pool0.User -notmatch "\.$($Pool0.WorkerName)$") { $Arguments += " --worker $($Pool0.WorkerName)" }
                                    If ($_.AutoCoinPers) { $Arguments += $(Get-EquihashCoinPers -Command " --pers " -Currency $Pool0.Currency -DefaultCommand $_.AutoCoinPers) }

                                    If (($_.Algorithms[1])) { 
                                        $Arguments += " --dserver $($Pool1.Host):$($Pool1.PoolPorts | Select-Object -Last 1)"
                                        If ($Pool1.PoolPorts[1]) { $Arguments += " --dssl 1" }
                                        $Arguments += " --duser $($Pool1.User)"
                                        $Arguments += " --dpass $($Pool1.Pass)"
                                        If ($Pool1.WorkerName -and $Pool1.User -notmatch "\.$($Pool1.WorkerName)$") { $Arguments += " --dworker $($Pool1.WorkerName)" }
                                    }

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
            )
        }
    )
}