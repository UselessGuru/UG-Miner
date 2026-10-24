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
Version:        6.9.0
Version date:   2026/10/24
#>

# NEW DUAL MINING PEARL + C29! (Nvidia only, see below)
# c29 improvement on 6gb gpus
# fixed (again) amd gpus not mining on mmpos
# bc250 enabled cu's are now opt-in
# bc250 now allows core lock below 1500
# updated docs to explain more about bc250 options

if (-not ($Devices = $Session.EnabledDevices.Where{ "AMD", "CPU", "INTEL" -contains $_.Type -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.OpenCL.DriverVersion -ge [System.Version]"460.27.03") })) { return }

$URL = "https://github.com/bzminer/bzminer/releases/download/v100.51/bzminer_v100.51_windows.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\bzminer.exe"
$DeviceEnumerator = "Bus"

$Algorithms = @(
    @{ Algorithms = @("Autolykos2", "");  Type = "AMD"; Fee = @(0.01);  MinMemGiBfree = 1.44; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --cpu 0 --intel 0 --nvidia 0 --algo1 ergo") }
    @{ Algorithms = @("Cuckoo29", "");    Type = "AMD"; Fee = @(0.01);  MinMemGiBfree = 2;    WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --cpu 0 --intel 0 --nvidia 0 --algo1 c29") }
    @{ Algorithms = @("EtcHash", "");     Type = "AMD"; Fee = @(0.005); MinMemGiBfree = 1.08; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --cpu 0 --intel 0 --nvidia 0 --algo1 etc") }
    @{ Algorithms = @("Ethash", "");      Type = "AMD"; Fee = @(0.005); MinMemGiBfree = 1.08; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --cpu 0 --intel 0 --nvidia 0 --algo1 ethw") }
    @{ Algorithms = @("KawPow", "");      Type = "AMD"; Fee = @(0.01);  MinMemGiBfree = 1.08; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --cpu 0 --intel 0 --nvidia 0 --algo1 kawpow") }
    @{ Algorithms = @("JanusHash", "");   Type = "AMD"; Fee = @(0.02);  MinMemGiBfree = 2;    WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --cpu 0 --intel 0 --nvidia 0 --algo1 warthog") }
    @{ Algorithms = @("PearlHash", "");   Type = "AMD"; Fee = @(0.02);  MinMemGiBfree = 4;    WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --cpu 0 --intel 0 --nvidia 0 --algo1 pearl") }
#   @{ Algorithms = @("SHA256d", "");     Type = "AMD"; Fee = @(0);     MinMemGiBfree = 1.24; WarmupTimes = @(45, 5);  ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --cpu 0 --intel 0 --nvidia 0 --algo1 sha256d") } # ASIC
    @{ Algorithms = @("XelisHashV3", ""); Type = "AMD"; Fee = @(0.01);  MinMemGiBfree = 1.08; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --cpu 0 --intel 0 --nvidia 0 --algo1 xelis") }

    @{ Algorithms = @("VerusHash", ""); Type = "CPU"; Fee = @(0.01);  MinMemGiBfree = 0; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" --algo1 verus") }

    @{ Algorithms = @("Autolykos2", "");  Type = "INTEL"; Fee = @(0.01);  MinMemGiBfree = 1.24; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --nvidia 0 --algo1 ergo") }
    @{ Algorithms = @("Cuckoo29", "");    Type = "INTEL"; Fee = @(0.01);  MinMemGiBfree = 2;    WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --nvidia 0 --algo1 c29") }
    @{ Algorithms = @("EtcHash", "");     Type = "INTEL"; Fee = @(0.005); MinMemGiBfree = 1.08; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --nvidia 0 --algo1 etc") }
    @{ Algorithms = @("Ethash", "");      Type = "INTEL"; Fee = @(0.005); MinMemGiBfree = 1.08; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --nvidia 0 --algo1 ethw") }
    @{ Algorithms = @("KawPow", "");      Type = "INTEL"; Fee = @(0.01);  MinMemGiBfree = 1.08; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --nvidia 0 --algo1 kawpow") }
    @{ Algorithms = @("JanusHash", "");   Type = "INTEL"; Fee = @(0.01);  MinMemGiBfree = 2;    WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --nvidia 0 --algo1 warthog") }
    @{ Algorithms = @("PearlHash", "");   Type = "INTEL"; Fee = @(0.02);  MinMemGiBfree = 4;    WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --nvidia 0 --algo1 pearl") }
#   @{ Algorithms = @("SHA256d", "");     Type = "INTEL"; Fee = @(0);     MinMemGiBfree = 1.24; WarmupTimes = @(45, 5);  ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --nvidia 0 --algo1 sha256d") } # ASIC
    @{ Algorithms = @("XelisHashV3", ""); Type = "INTEL"; Fee = @(0.01);  MinMemGiBfree = 1.08; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --nvidia 0 --algo1 xelis") }

    @{ Algorithms = @("Autolykos2", "");        Type = "NVIDIA"; Fee = @(0.01);  MinMemGiBfree = 1.24; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --intel 0 --algo1 ergo") }
    @{ Algorithms = @("Cuckoo29", "");          Type = "NVIDIA"; Fee = @(0.01);  MinMemGiBfree = 2;    WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --intel 0 --algo1 c29") }
    @{ Algorithms = @("EtcHash", "");           Type = "NVIDIA"; Fee = @(0.005); MinMemGiBfree = 1.24; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --intel 0 --algo1 etc") }
    @{ Algorithms = @("Ethash", "");            Type = "NVIDIA"; Fee = @(0.005); MinMemGiBfree = 1.24; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --intel 0 --algo1 ethw") }
    @{ Algorithms = @("KawPow", "");            Type = "NVIDIA"; Fee = @(0.01);  MinMemGiBfree = 1.08; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --intel 0 --algo1 kawpow") }
    @{ Algorithms = @("JanusHash", "");         Type = "NVIDIA"; Fee = @(0.02);  MinMemGiBfree = 2;    WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --intel 0 --algo1 warthog") }
    @{ Algorithms = @("PearlHash", "");         Type = "NVIDIA"; Fee = @(0.02);  MinMemGiBfree = 4;    WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --intel 0 --algo1 pearl") }
    @{ Algorithms = @("PearlHash", "Cuckoo29"); Type = "NVIDIA"; Fee = @(0.02);  MinMemGiBfree = 4;    WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --intel 0 --algo1 pearl --algo2 c29") }
#   @{ Algorithms = @("SHA256d", "");           Type = "NVIDIA"; Fee = @(0);     MinMemGiBfree = 1.24; WarmupTimes = @(45, 5);  ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --intel 0 --algo1 sha256d") } # ASIC
    @{ Algorithms = @("XelisHashV3", "");       Type = "NVIDIA"; Fee = @(0.01);  MinMemGiBfree = 1.24; WarmupTimes = @(45, 5);  ExcludeGPUarchitectures = " "; ExcludeGPUmodel = " "; ExcludePools = @(@(), @()); Arguments = @(" --amd 0 --cpu 0 --intel 0 --algo1 xelis") }
    
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

                        $MinMemGiBfree = $_.MinMemGiBfree + $Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB
                        if ($AvailableMinerDevices = $SupportedMinerDevices.Where{ $_.MemoryGiBfree -ge $MinMemGiBfree }) { 

                            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(if ($Pool1) { "&$($Pool1.AlgorithmVariant)" })"

                            $Arguments = $_.Arguments[0]
                            $Arguments = switch ($Pool0.Protocol) { 
                                "ethproxy"     { "$Arguments --pool1 ethproxy"; break }
                                "ethstratum1"  { "$Arguments --pool1 ethstratum"; break }
                                "ethstratum2"  { "$Arguments --pool1 ethstratum2"; break }
                                "ethstratumnh" { "$Arguments --pool1 ethstratum"; break }
                                default        { "$Arguments --pool1 stratum" }
                            }
                            $Arguments = if ($Pool0.PoolPorts[1]) { "$Arguments+ssl://" } else { "$Arguments+tcp://" }
                            $Arguments = "$Arguments$($Pool0.Host):$($Pool0.PoolPorts | Select-Object -Last 1)"
                            $Arguments = "$Arguments --user1 $($Pool0.User) --pass1 $($Pool0.Pass)"

                            if ($_.Algorithms[1]) { 
                                $Arguments = "$Arguments$($_.Arguments[1])"
                                $Arguments = switch ($Pool1.Protocol) { 
                                    "ethproxy"     { "$Arguments --pool2 ethproxy"; break }
                                    "ethstratum1"  { "$Arguments --pool2 ethstratum"; break }
                                    "ethstratum2"  { "$Arguments --pool2 ethstratum2"; break }
                                    "ethstratumnh" { "$Arguments --pool2 ethstratum"; break }
                                    default        { "$Arguments --pool2 stratum" }
                                }
                                $Arguments = if ($Pool1.PoolPorts[1]) { "$Arguments+ssl://" } else { "$Arguments+tcp://" }
                                $Arguments = "$Arguments$($Pool1.Host):$($Pool1.PoolPorts | Select-Object -Last 1)"
                                $Arguments = "$Arguments --user2 $($Pool1.User) --pass2"
                            }

                            # Allow more time to build larger DAGs, must use type cast to keep values in $_
                            $WarmupTimes = [UInt16[]]$_.WarmupTimes
                            $WarmupTimes[0] += [UInt16](($Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB) * 2)

                            @{ 
                                API         = "BzMiner"
                                Arguments   = "$Arguments --hashrate-window 5 --http_enabled --http_address 127.0.0.1 --http_port $MinerAPIPort --no-watchdog$(if ($Type -ne "CPU") { " --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach{ '{0:x}:00' -f $_ } -join " ")" })"
                                DeviceNames = $AvailableMinerDevices.Name
                                DownloadURL = $URL
                                Fee         = $_.Fee # Dev fee
                                MinerURL    = "http://127.0.0.1:$($MinerAPIPort)"
                                Name        = $MinerName
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = $Type
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