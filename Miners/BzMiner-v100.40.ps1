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
Version date:   2026/09/01
#>

# Big Nvidia & AMD pearl optimizations
# Further randomx optimizations

if (-not ($Devices = $Session.EnabledDevices.Where{ "AMD", "CPU", "INTEL" -contains $_.Type -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.OpenCL.DriverVersion -ge [System.Version]"460.27.03") })) { return }

$URI = "https://github.com/bzminer/bzminer/releases/download/v100.40/bzminer_v100.40_windows.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\bzminer.exe"
$DeviceEnumerator = "Bus"

$Algorithms = @(
    @{ Algorithms = @("Autolykos2", "");  Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.44; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo ergo") }
    @{ Algorithms = @("EtcHash", "");     Type = "AMD"; Fee = @(0.005); MinMemGiB = 1.08; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo etc") }
    @{ Algorithms = @("Ethash", "");      Type = "AMD"; Fee = @(0.005); MinMemGiB = 1.08; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo ethw") }
    @{ Algorithms = @("KawPow", "");      Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.08; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo kawpow") }
    @{ Algorithms = @("JanusHash", "");   Type = "AMD"; Fee = @(0.02);  MinMemGiB = 2;    WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo warthog") }
    @{ Algorithms = @("PearlHash", "");   Type = "AMD"; Fee = @(0.02);  MinMemGiB = 1;    WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo pearl") }
#   @{ Algorithms = @("SHA256d", "");     Type = "AMD"; Fee = @(0);     MinMemGiB = 1.24; WarmupTimes = @(45, 5);  ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo sha256d") } # ASIC
    @{ Algorithms = @("Verus", "");       Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1;    WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo verus") }
    @{ Algorithms = @("PearlHash", "");   Type = "AMD"; Fee = @(0.02);  MinMemGiB = 1;    WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo pearl") }
    @{ Algorithms = @("XelisHashV3", ""); Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.08; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo xelis") }

    @{ Algorithms = @("Autolykos2", "");  Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1.24; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo ergo") }
    @{ Algorithms = @("EtcHash", "");     Type = "INTEL"; Fee = @(0.005); MinMemGiB = 1.08; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo etc") }
    @{ Algorithms = @("Ethash", "");      Type = "INTEL"; Fee = @(0.005); MinMemGiB = 1.08; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo ethw") }
    @{ Algorithms = @("KawPow", "");      Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1.08; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo kawpow") }
    @{ Algorithms = @("JanusHash", "");   Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 2;    WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo warthog") }
    @{ Algorithms = @("PearlHash", "");   Type = "INTEL"; Fee = @(0.02);  MinMemGiB = 1;    WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo pearl") }
#   @{ Algorithms = @("SHA256d", "");     Type = "INTEL"; Fee = @(0);     MinMemGiB = 1.24; WarmupTimes = @(45, 5);  ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo sha256d") } # ASIC
    @{ Algorithms = @("Verus", "");       Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1.08; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo verus") }
    @{ Algorithms = @("XelisHashV3", ""); Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1.08; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo xelis") }

    @{ Algorithms = @("Autolykos2", "");  Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1.24; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo ergo") }
    @{ Algorithms = @("EtcHash", "");     Type = "NVIDIA"; Fee = @(0.005); MinMemGiB = 1.24; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo etc") }
    @{ Algorithms = @("Ethash", "");      Type = "NVIDIA"; Fee = @(0.005); MinMemGiB = 1.24; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo ethw") }
    @{ Algorithms = @("KawPow", "");      Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1.08; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo kawpow") }
    @{ Algorithms = @("JanusHash", "");   Type = "NVIDIA"; Fee = @(0.02);  MinMemGiB = 2;    WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo warthog") }
    @{ Algorithms = @("PearlHash", "");   Type = "NVIDIA"; Fee = @(0.02);  MinMemGiB = 1;    WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo pearl") }
#   @{ Algorithms = @("SHA256d", "");     Type = "NVIDIA"; Fee = @(0);     MinMemGiB = 1.24; WarmupTimes = @(45, 5);  ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo sha256d") } # ASIC
    @{ Algorithms = @("Verus", "");       Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1;    WarmupTimes = @(45, 5);  ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo verus") }
    @{ Algorithms = @("XelisHashV3", ""); Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1.24; WarmupTimes = @(45, 5);  ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --algo xelis") }
    
)

$Algorithms = $Algorithms.Where{ $MinerPools[0][$_.Algorithms[0]] }
$Algorithms = $Algorithms.Where{ -not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]] }

if ($Algorithms) { 

    ($Devices | Group-Object -Property Type, Model).ForEach{ 
        $MinerDevices = $_.Group
        $Model = $MinerDevices[0].Model
        $Type = $MinerDevices[0].Type

        $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Bottom 1)

        $Algorithms.Where{ $_.Type -eq $Type }.ForEach{ 
            $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
            $ExcludeGPUmodel = $_.ExcludeGPUmodel
            if ($SupportedMinerDevices = $MinerDevices.Where{ $_.Model -notmatch $ExcludeGPUmodel -and $_.Architecture -notmatch $ExcludeGPUarchitectures }) { 

                $ExcludePools = $_.ExcludePools
                foreach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where{ $ExcludePools[0] -notcontains $_.Name }) { 
                    foreach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where{ $ExcludePools[1] -notcontains $_.Name }) { 

                        $MinMemGiB = $_.MinMemGiB + $Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB
                        if ($AvailableMinerDevices = $SupportedMinerDevices.Where{ $_.MemoryGiB -ge $MinMemGiB }) { 

                            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(if ($Pool1) { "&$($Pool1.AlgorithmVariant)" })"

                            $Arguments = $_.Arguments[0]
                            $Arguments = switch ($Pool0.Protocol) { 
                                "ethproxy"     { "$Arguments --pool ethproxy"; break }
                                "ethstratum1"  { "$Arguments --pool ethstratum"; break }
                                "ethstratum2"  { "$Arguments --pool ethstratum2"; break }
                                "ethstratumnh" { "$Arguments --pool ethstratum"; break }
                                default        { "$Arguments --pool stratum" }
                            }
                            $Arguments = if ($Pool0.PoolPorts[1]) { "$Arguments+ssl://" } else { "$Arguments+tcp://" }
                            $Arguments = "$Arguments$($Pool0.Host):$($Pool0.PoolPorts | Select-Object -Last 1)"
                            $Arguments = "$Arguments --user $($Pool0.User -replace "\..*") --pass $($Pool0.Pass) --worker $(if ($Pool0.WorkerName) { $Pool0.WorkerName } elseif ($Pool0.User -like "*.*") { $Pool0.User -replace ".+\." } else { $Session.Config.WorkerName })"

                            # if ($_.Algorithms[1]) { 
                            #     $Arguments = "$Arguments$($_.Arguments[1])"
                            #     $Arguments = switch ($Pool1.Protocol) { 
                            #         "ethproxy"     { "$Arguments --p2 ethproxy"; break }
                            #         "ethstratum1"  { "$Arguments --p2 ethstratum"; break }
                            #         "ethstratum2"  { "$Arguments --p2 ethstratum2"; break }
                            #         "ethstratumnh" { "$Arguments --p2 ethstratum"; break }
                            #         default        { "$Arguments --p2 stratum" }
                            #     }
                            #     $Arguments = if ($Pool1.PoolPorts[1]) { "$Arguments+ssl://" } else { "$Arguments+tcp://" }
                            #     $Arguments = "$Arguments$($Pool1.Host):$($Pool1.PoolPorts | Select-Object -Last 1)"
                            #     $Arguments = "$Arguments --user $($Pool1.User -replace "\..*") --pass $($Pool1.Pass) --worker $(if ($Pool1.WorkerName) { $Pool1.WorkerName } elseif ($Pool1.User -like "*.*") { $Pool1.User -replace ".+\." } else { $Session.Config.WorkerName })"
                            # }

                            # Allow more time to build larger DAGs, must use type cast to keep values in $_
                            $WarmupTimes = [UInt16[]]$_.WarmupTimes
                            $WarmupTimes[0] += [UInt16](($Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB) * 2)

                            @{ 
                                API         = "BzMiner"
                                Arguments   = "$Arguments --hashrate-window 5 --http_enabled --http_address 127.0.0.1 --http_port $MinerAPIPort --no-watchdog --disable_udp --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach{ '{0:x}:00' -f $_ } -join " ")"
                                DeviceNames = $AvailableMinerDevices.Name
                                Fee         = $_.Fee # Dev fee
                                MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                                Name        = $MinerName
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = $Type
                                URI         = $URI
                                WarmupTimes = $WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers     = @(($Pool0, $Pool1).ForEach{ if ($_) { @{ Pool = $_ } } })
                            }
                        }
                    }
                }
            }
        }
    }
}