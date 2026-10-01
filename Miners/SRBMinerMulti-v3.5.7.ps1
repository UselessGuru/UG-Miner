<#
Copyright (c) 2018-2026 UselessGuru

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
Version:        6.8.26
Version date:   2026/10/01
#>

# Keep algorithms 'progpow_sero', 'progpow_telestai', 'walahash', 'karlsenhashv2' and related dual implementations (these were removed in v3.5.7)

if (-not ($Devices = $Session.EnabledDevices.Where{ $_.Type -eq "CPU" -or $_.Type -eq "INTEL" -or ($_.Type -eq "AMD" -and $_.Architecture -notmatch "GCN[1-3]" -and $_.OpenCL.ClVersion -ge "OpenCL C 2.0") -or ($_.OpenCL.ComputeCapability -gt "5.0" -and $_.OpenCL.DriverVersion -ge "510.00") })) { return }

$URI = "https://github.com/doktor83/SRBMiner-Multi/releases/download/3.5.7/SRBMiner-Multi-3-5-7-win64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\SRBMiner-MULTI.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

# Algorithm names in arguments values are case sensitive!
$Algorithms = @( 
    @{ Algorithms = @("Autolykos2", "WalaHash");        Type = "AMD"; Fee = @(0.01, 0.02);   MinMemGiB = 1.24; WarmupTimes = @(45, 30);  ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm walahash") }
    @{ Algorithms = @("FishHash", "WalaHash");          Type = "AMD"; Fee = @(0.0085, 0.01); MinMemGiB = 1.24; WarmupTimes = @(45, 30);  ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fishhash", " --algorithm walahash") }
    @{ Algorithms = @("HeavyHashKarlsenV2", "");        Type = "AMD"; Fee = @(0.01);         MinMemGiB = 1.24; WarmupTimes = @(60, 0);   ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm karlsenhashv2") }
    @{ Algorithms = @("HeavyHashKarlsenV2", "Decred");  Type = "AMD"; Fee = @(0.01, 0.02);   MinMemGiB = 1.24; WarmupTimes = @(60, 30);  ExcludeGPUarchitectures = "^Other$|^GCN\d$"; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm karlsenhashv2", " --algorithm blake3_decred") }
    @{ Algorithms = @("ProgPowSero", "");               Type = "AMD"; Fee = @(0.0085);       MinMemGiB = 1.24; WarmupTimes = @(45, 30);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm progpow_sero") }
    @{ Algorithms = @("ProgPowTelestai", "");           Type = "AMD"; Fee = @(0.0085);       MinMemGiB = 1.24; WarmupTimes = @(75, 30);  ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm progpow_telestai") }
    @{ Algorithms = @("WalaHash", "");                  Type = "AMD"; Fee = @(0.01);         MinMemGiB = 1;    WarmupTimes = @(30, 0);   ExcludeGPUarchitectures = " ";               ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm walahash") }

    @{ Algorithms = @("Autolykos2", "WalaHash");        Type = "INTEL"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; WarmupTimes = @(45, 60);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm walahash") }
    @{ Algorithms = @("FishHash", "WalaHash");          Type = "INTEL"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; WarmupTimes = @(45, 30);  ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm fishhash", " --algorithm walahash") }
    @{ Algorithms = @("HeavyHashKarlsenV2", "");        Type = "INTEL"; Fee = @(0.0085);      MinMemGiB = 1.24; WarmupTimes = @(60, 0);   ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm karlsenhashv2") }
    @{ Algorithms = @("HeavyHashKarlsenV2", "Decred");  Type = "INTEL"; Fee = @(0.01, 0.02);  MinMemGiB = 1.24; WarmupTimes = @(60, 60);  ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm karlsenhashv2", " --algorithm blake3_decred") }
    @{ Algorithms = @("ProgPowSero", "");               Type = "INTEL"; Fee = @(0.0085);      MinMemGiB = 1.24; WarmupTimes = @(45, 30);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm progpow_sero") }
    @{ Algorithms = @("ProgPowTelestai", "");           Type = "INTEL"; Fee = @(0.0085);      MinMemGiB = 1.24; WarmupTimes = @(75, 30);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm progpow_telestai") }
    @{ Algorithms = @("WalaHash", "");                  Type = "INTEL"; Fee = @(0.01);        MinMemGiB = 1;    WarmupTimes = @(30, 30);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm walahash") }

    @{ Algorithms = @("Autolykos2", "WalaHash");        Type = "NVIDIA"; Fee = @(0.01, 0.02);  MinMemGiB = 1.24; WarmupTimes = @(60, 10);  ExcludeGPUarchitectures = "^Pascal$"; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm autolykos2 --autolykos2-preload", " --algorithm walahash") }
    @{ Algorithms = @("FishHash", "WalaHash");          Type = "NVIDIA"; Fee = @(0.01, 0.01);  MinMemGiB = 1.24; WarmupTimes = @(45, 30);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm fishhash", " --algorithm walahash") }
    @{ Algorithms = @("HeavyHashKarlsenV2", "");        Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 1.24; WarmupTimes = @(60, 0);   ExcludeGPUarchitectures = "^Pascal$"; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm karlsenhashv2") }
    @{ Algorithms = @("HeavyHashKarlsenV2", "Decred");  Type = "NVIDIA"; Fee = @(0.01, 0.02);  MinMemGiB = 1.24; WarmupTimes = @(60, 20);  ExcludeGPUarchitectures = "^Pascal$"; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm karlsenhashv2", " --algorithm blake3_decred") }
    @{ Algorithms = @("ProgPowSero", "");               Type = "NVIDIA"; Fee = @(0.0085);      MinMemGiB = 1.24; WarmupTimes = @(45, 30);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm progpow_sero") }
    @{ Algorithms = @("ProgPowTelestai", "");           Type = "NVIDIA"; Fee = @(0.0085);      MinMemGiB = 1.24; WarmupTimes = @(75, 30);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm progpow_telestai") }
    @{ Algorithms = @("WalaHash", "");                  Type = "NVIDIA"; Fee = @(0.01);        MinMemGiB = 1;    WarmupTimes = @(30, 30);  ExcludeGPUarchitectures = " ";        ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm walahash") }
)

$Algorithms = $Algorithms.Where{ $MinerPools[0][$_.Algorithms[0]] }
$Algorithms = $Algorithms.Where{ -not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]] }

if ($Algorithms) { 

    if (-not $Session.Config.DryRun) { 
        # Allowed max loss for 1. algorithm
        $GpuDualMaxLosses = @(2, 4, 7, 10, 15, 21, 30)

        # Build command sets for max loss
        $Algorithms = $Algorithms.ForEach{ 
            $_.PsObject.Copy()
            if ($_.Algorithms[1]) { 
                foreach ($GpuDualMaxLoss in $GpuDualMaxLosses) { 
                    $_.GpuDualMaxLoss = $GpuDualMaxLoss
                    $_.PsObject.Copy()
                }
            }
        }
        Remove-Variable GpuDualMaxLosses, GpuDualMaxLoss -ErrorAction Ignore
    }

    ($Devices | Group-Object -Property Type, Model).ForEach{ 
        $MinerDevices = $_.Group
        $Model = $MinerDevices[0].Model
        $Type = $MinerDevices[0].Type

        $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Bottom 1)

        $Algorithms.Where{ $_.Type -eq $Type }.ForEach{ 
            $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
            if ($SupportedMinerDevices = $MinerDevices.Where{ $_.Type -eq "CPU" -or $_.Architecture -notmatch $ExcludeGPUarchitectures }) { 

                if ($_.Algorithms[0] -eq "VertHash" -and ([System.IO.FileInfo]$Session.VertHashDatPath).Length -ne 1283457024) { 
                    $PrerequisitePath = $Session.VertHashDatPath
                    $PrerequisiteURI  = "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/VertHashDataFile/VertHash.dat"
                }
                else { 
                    $PrerequisitePath = ""
                    $PrerequisiteURI  = ""
                }

                $ExcludePools = $_.ExcludePools
                foreach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where{ $ExcludePools[0] -notcontains $_.Name }) { 
                    foreach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where{ $ExcludePools[1] -notcontains $_.Name }) { 
                        $Pools = @(($Pool0, $Pool1).Where{ $_ })

                        $MinMemGiB = $_.MinMemGiB + $Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB
                        if ($AvailableMinerDevices = $SupportedMinerDevices.Where{ $_.MemoryGiB -gt $MinMemGiB }) { 

                            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(if ($Pool1) { "&$($Pool1.AlgorithmVariant)$(if ($_.GpuDualMaxLoss) { "-DualMaxLoss $($_.GpuDualMaxLoss)" })"})"

                            $Arguments = ""
                            foreach ($Pool in $Pools) { 
                                if ($Pool.Algorithm -match $Session.RegexAlgoIsEthash) { 
                                    switch ($Pool.Protocol) { 
                                        "minerproxy"   { $Arguments = "$Arguments --esm 0"; break }
                                        "ethproxy"     { $Arguments = "$Arguments --esm 0"; break }
                                        "ethstratum1"  { $Arguments = "$Arguments --esm 1"; break }
                                        "ethstratum2"  { $Arguments = "$Arguments --esm 2"; break }
                                        "ethstratumnh" { $Arguments = "$Arguments --esm 2" }
                                    }
                                }
                                $Arguments = "$Arguments$($_.Arguments[$Pools.IndexOf($Pool)]) --pool $(if ($Pool.PoolPorts[1]) { "ssl://$($Pool.Host):$($Pool.PoolPorts[1])" } else { "tcp://$($Pool.Host):$($Pool.PoolPorts[0])" }) --wallet $($Pool.User) --password $($Pool.Pass)"
                                if ($Pool.Name -eq "NiceHash") { $Arguments = "$Arguments --nicehash true" }
                                if ($Pool.WorkerName) { $Arguments = "$Arguments --worker $($Pool.WorkerName)" }
                                if ($_.GpuDualMaxLoss) { $Arguments = "$Arguments --gpu-dual-max-loss $($_.GpuDualMaxLoss)" }
                            }
                            Remove-Variable Pool

                            if ($_.Type -eq "CPU") { 
                                $Arguments = "$Arguments --cpu-threads $($AvailableMinerDevices.CIM.NumberOfLogicalProcessors - $Session.Config.CPUMiningReserveCPUcore))"
                            }
                            else { 
                                $Arguments = "$Arguments --gpu-id $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach{ '{0:x}' -f $_ } -join ',')"
                            }

                            # Allow more time to build larger DAGs, must use type cast to keep values in $_
                            $WarmupTimes = [UInt16[]]$_.WarmupTimes
                            $WarmupTimes[0] += [UInt16](($Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB) * 2)

                            if ($_.Algorithms[0] -eq "KawPow" -and "HashCryptos", "MiningDutch" -contains $Pool0) { $Arguments = "$Arguments --retry-time 1" }

                            # Apply tuning parameters
                            if ($_.Type -eq "CPU" -and -not $Session.ApplyMinerTweaks) { $Arguments = "$Arguments --disable-msr-tweaks" }

                            @{ 
                                API              = "SRBMiner"
                                Arguments        = "$Arguments --api-rig-name $($Session.Config.PoolsConfig.($Pool0.Name).WorkerName) --api-enable --api-port $MinerAPIPort"
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
                                Workers          = @($Pools.ForEach{ @{ Pool = $_ } })
                            }
                        }
                    }
                }
            }
        }
    }
}
