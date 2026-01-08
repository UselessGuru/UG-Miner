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
Version:        6.7.19
Version date:   2026/01/08
#>

if (-not ($Devices = $Session.EnabledDevices.Where({ $_.Type -eq "AMD" -or $_.OpenCL.ComputeCapability -ge "5.0" }))) { return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/PhoenixMiner/PhoenixMiner_6.2c_Windows.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\PhoenixMiner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    @{ Algorithms = @("EtcHash", "");        Type = "AMD"; Fee = @(0.0065);   MinMemGiB = 0.77; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";          ExcludePools = @(@(), @()); Arguments = " -amd -eres 2 -coin ETC" } # GMiner-v3.44 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    @{ Algorithms = @("EtcHash", "Blake2s"); Type = "AMD"; Fee = @(0.009, 0); MinMemGiB = 0.77; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";          ExcludePools = @(@(), @()); Arguments = " -amd -eres 2 -coin ETC -dcoin blake2s" }
    @{ Algorithms = @("Ethash", "");         Type = "AMD"; Fee = @(0.0065);   MinMemGiB = 0.77; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";          ExcludePools = @(@(), @()); Arguments = " -amd -eres 2" } # GMiner-v3.44 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    @{ Algorithms = @("Ethash", "Blake2s");  Type = "AMD"; Fee = @(0.009, 0); MinMemGiB = 0.77; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";          ExcludePools = @(@(), @()); Arguments = " -amd -eres 2 -dcoin blake2s" }
    @{ Algorithms = @("UbqHash", "");        Type = "AMD"; Fee = @(0.0065);   MinMemGiB = 0.77; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";          ExcludePools = @(@(), @()); Arguments = " -amd -eres 2 -coin UBQ" }
    @{ Algorithms = @("UbqHash", "Blake2s"); Type = "AMD"; Fee = @(0.009, 0); MinMemGiB = 0.77; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^RDNA[12]$"; ExcludePools = @(@(), @()); Arguments = " -amd -eres 1 -coin UBQ -dcoin blake2s" }

    @{ Algorithms = @("EtcHash", "");        Type = "NVIDIA"; Fee = @(0.0065);   MinMemGiB = 0.77; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 2 -coin ETC" } # GMiner-v3.44 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    @{ Algorithms = @("EtcHash", "Blake2s"); Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGiB = 0.77; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 2 -coin ETC -dcoin blake2s" }
    @{ Algorithms = @("Ethash", "");         Type = "NVIDIA"; Fee = @(0.0065);   MinMemGiB = 0.77; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 2" } # GMiner-v3.442 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    @{ Algorithms = @("Ethash", "Blake2s");  Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGiB = 0.77; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 2 -dcoin blake2s" }
    @{ Algorithms = @("UbqHash", "");        Type = "NVIDIA"; Fee = @(0.0065);   MinMemGiB = 0.77; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 2 -coin UBQ" }
    @{ Algorithms = @("UbqHash", "Blake2s"); Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGiB = 0.77; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 2 -coin UBQ -dcoin blake2s" }
)

$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] })
$Algorithms = $Algorithms.Where({ -not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]] })

if ($Algorithms) { 

    # Intensities for 2. algorithm
    $IntensityValues = [PSCustomObject]@{ 
        "Blake2s" = @(10, 20, 30, 40)
    }

    if (-not $Session.Config.DryRun) { 
        # Build command sets for intensities
        $Algorithms = $Algorithms.ForEach(
            { 
                $_.PsObject.Copy()
                if ($_.Algorithms[1]) { 
                    $Intensity = $_.Intensity
                    $WarmupTimes = $_.WarmupTimes.PsObject.Copy()
                    if ($_.Type -eq "NVIDIA" -and $Intensity) { $Intensity *= 5 } # Nvidia allows much higher intensity
                    foreach ($Intensity in $IntensityValues.($_.Algorithms[1]) | Select-Object) { 
                        $_.Intensity = $Intensity
                        # Allow extra time for auto tuning
                        $_.WarmupTimes[1] = $WarmupTimes[1] + 45
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
                    if ($SupportedMinerDevices = $MinerDevices.Where({ $_.Architecture -notmatch $ExcludeGPUarchitectures })) { 

                        # $ExcludePools = $_.ExcludePools
                        # foreach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $ExcludePools[0] -notcontains $_.Name[0] -and (($_.Algorithm -eq "EtcHash" -and $_.Epoch -lt 602) -or $_.Epoch -lt 302) })) { 
                        foreach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ ($_.Algorithm -eq "EtcHash" -and $_.Epoch -lt 602) -or $_.Epoch -lt 302 })) { 
                            # foreach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $ExcludePools[1] -notcontains $_.Name[1] })) { 
                            foreach ($Pool1 in $MinerPools[1][$_.Algorithms[1]]) { 

                                $MinMemGiB = $_.MinMemGiB + $Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB
                                if ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 
                                    if ($_.Type -eq "AMD" -and $_.Algorithms[1]) { 
                                        if ($Pool0.DAGsizeGiB -ge 4) { return } # AMD: doesn't support Blake2s dual mining with DAG larger 4GB
                                        $AvailableMinerDevices = $AvailableMinerDevices.Where({ [System.Version]$_.CIM.DriverVersion -le [System.Version]"27.20.22023.1004" }) # doesn't support Blake2s dual mining on drivers newer than 21.8.1 (27.20.22023.1004)
                                    }

                                    if ($AvailableMinerDevices) { 

                                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(if ($Pool1) { "&$($Pool1.AlgorithmVariant)$(if ($_.Intensity) { "-$($_.Intensity)" })"})"

                                        $Arguments = "$($_.Arguments) -pool $(if ($Pool0.PoolPorts[1]) { "ssl://" })$($Pool0.Host):$($Pool0.PoolPorts | Select-Object -Last 1) -wal $($Pool0.User) -pass $($Pool0.Pass)"
                                        $Arguments += switch ($Pool0.Protocol) { 
                                            "ethproxy"     { " -proto 2"; break }
                                            "minerproxy"   { " -proto 1"; break }
                                            "ethstratum1"  { " -proto 4"; break }
                                            "ethstratum2"  { " -proto 4"; break }
                                            "ethstratumnh" { " -proto 4"; break }
                                            "qtminer"      { " -proto 3"; break }
                                            default        { " -proto 1" }
                                        }
                                        if ($Session.Config.SSLallowSelfSignedCertificate -and $Pool0.PoolPorts[1]) { $Arguments += " -weakssl" } # https://bitcointalk.org/index.php?topic=2647654.msg60032993#msg60032993
                                        if ($Pool0.WorkerName) { $Arguments += " -worker $($Pool0.WorkerName)" }

                                        # kernel 3 does not support dual mining
                                        if (($AvailableMinerDevices.Memory | Measure-Object -Minimum).Minimum / 1GB -ge 2 * $MinMemGiB -and -not $_.Algorithms[1]) {
                                            # Faster kernels require twice as much VRAM
                                            if ($AvailableMinerDevices.Vendor -eq "AMD") { $Arguments += " -clkernel 3" }
                                            elseif ($AvailableMinerDevices.Vendor -eq "NVIDIA") { $Arguments += " -nvkernel 3" }
                                        }

                                        if ($_.Algorithms[1]) { 
                                            $Arguments += " -dpool $(if ($Pool1.PoolPorts[1]) { "ssl://" })$($Pool1.Host):$($Pool1.PoolPorts | Select-Object -Last 1) -dwal $($Pool1.User) -dpass $($Pool1.Pass)"
                                            if ($Session.Config.SSLallowSelfSignedCertificate -and $Pool1.PoolPorts[1]) { $Arguments += " -weakssl2" } # https://bitcointalk.org/index.php?topic=2647654.msg60032993#msg60032993
                                            if ($Pool1.WorkerName) { $Arguments += " -dworker $($Pool1.WorkerName)" }
                                            if ($_.Intensity) { $Arguments += " -sci $($_.Intensity)" }
                                        }

                                        # Allow more time to build larger DAGs, must use type cast to keep values in $_
                                        $WarmupTimes = [UInt16[]]$_.WarmupTimes
                                        $WarmupTimes[0] += [UInt16](($Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB) * 2)

                                        # Apply tuning parameters
                                        if ($Session.ApplyMinerTweaks) { $_.Arguments += $_.Tuning }

                                        [PSCustomObject]@{ 
                                            API         = "EthMiner"
                                            Arguments   = "$Arguments -vmdag 0 -log 0 -wdog 0 -gsi 10 -cdmport $MinerAPIPort -gpus $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:d}' -f ($_ + 1) }) -join ',')"
                                            DeviceNames = $AvailableMinerDevices.Name
                                            Fee         = $_.Fee # Dev fee
                                            MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                                            Name        = $MinerName
                                            Path        = $Path
                                            Port        = $MinerAPIPort
                                            Type        = $Type
                                            URI         = $URI
                                            WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                            Workers     = @(($Pool0, $Pool1).Where({ $_ }).ForEach({ @{ Pool = $_ } }))
                                        }
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