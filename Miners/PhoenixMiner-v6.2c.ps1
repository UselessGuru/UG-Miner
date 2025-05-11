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
Version:        6.4.24
Version date:   2025/05/11
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "AMD" -or $_.OpenCL.ComputeCapability -ge "5.0" }))) { Return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/PhoenixMiner/PhoenixMiner_6.2c_Windows.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\PhoenixMiner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    @{ Algorithms = @("EtcHash", "");        Type = "AMD"; Fee = @(0.0065);   MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";          ExcludePools = @(@(), @()); Arguments = " -amd -eres 2 -coin ETC" } # GMiner-v3.44 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    @{ Algorithms = @("EtcHash", "Blake2s"); Type = "AMD"; Fee = @(0.009, 0); MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";          ExcludePools = @(@(), @()); Arguments = " -amd -eres 2 -coin ETC -dcoin blake2s" }
    @{ Algorithms = @("Ethash", "");         Type = "AMD"; Fee = @(0.0065);   MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";          ExcludePools = @(@(), @()); Arguments = " -amd -eres 2" } # GMiner-v3.44 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    @{ Algorithms = @("Ethash", "Blake2s");  Type = "AMD"; Fee = @(0.009, 0); MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";          ExcludePools = @(@(), @()); Arguments = " -amd -eres 2 -dcoin blake2s" }
    @{ Algorithms = @("UbqHash", "");        Type = "AMD"; Fee = @(0.0065);   MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";          ExcludePools = @(@(), @()); Arguments = " -amd -eres 2 -coin UBQ" }
    @{ Algorithms = @("UbqHash", "Blake2s"); Type = "AMD"; Fee = @(0.009, 0); MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = "^RDNA[12]$"; ExcludePools = @(@(), @()); Arguments = " -amd -eres 1 -coin UBQ -dcoin blake2s" }

    @{ Algorithms = @("EtcHash", "");        Type = "NVIDIA"; Fee = @(0.0065);   MinMemGiB = 0.77; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 2 -coin ETC" } # GMiner-v3.44 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    @{ Algorithms = @("EtcHash", "Blake2s"); Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 2 -coin ETC -dcoin blake2s" }
    @{ Algorithms = @("Ethash", "");         Type = "NVIDIA"; Fee = @(0.0065);   MinMemGiB = 0.77; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 2" } # GMiner-v3.442 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    @{ Algorithms = @("Ethash", "Blake2s");  Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 2 -dcoin blake2s" }
    @{ Algorithms = @("UbqHash", "");        Type = "NVIDIA"; Fee = @(0.0065);   MinMemGiB = 0.77; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 2 -coin UBQ" }
    @{ Algorithms = @("UbqHash", "Blake2s"); Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 2 -coin UBQ -dcoin blake2s" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] })
$Algorithms = $Algorithms.Where({ $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] })

If ($Algorithms) { 

    # Intensities for 2. algorithm
    $IntensityValues = [PSCustomObject]@{ 
        "Blake2s" = @(10, 20, 30, 40)
    }

    If (-not $Config.DryRun) { 
        # Build command sets for intensities
        $Algorithms = $Algorithms.ForEach(
            { 
                $_.PsObject.Copy()
                If ($_.Algorithms[1]) { 
                    $Intensity = $_.Intensity
                    $WarmupTimes = $_.WarmupTimes.PsObject.Copy()
                    If ($_.Type -eq "NVIDIA" -and $Intensity) { $Intensity *= 5 } # Nvidia allows much higher intensity
                    ForEach ($Intensity in $IntensityValues.($_.Algorithms[1]) | Select-Object) { 
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
            $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    If ($SupportedMinerDevices = $MinerDevices.Where({ $_.Architecture -notmatch $ExcludeGPUarchitectures })) { 

                        # $ExcludePools = $_.ExcludePools
                        # ForEach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $ExcludePools[0] -notcontains $_.Name[0] -and (($_.Algorithm -eq "EtcHash" -and $_.Epoch -lt 602) -or $_.Epoch -lt 302) })) { 
                        ForEach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ ($_.Algorithm -eq "EtcHash" -and $_.Epoch -lt 602) -or $_.Epoch -lt 302 })) { 
                            # ForEach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $ExcludePools[1] -notcontains $_.Name[1] })) { 
                            ForEach ($Pool1 in $MinerPools[1][$_.Algorithms[1]]) { 

                                $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB
                                If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 
                                    If ($_.Type -eq "AMD" -and $_.Algorithms[1]) { 
                                        If ($Pool0.DAGSizeGiB -ge 4) { Return } # AMD: doesn't support Blake2s dual mining with DAG larger 4GB
                                        $AvailableMinerDevices = $AvailableMinerDevices.Where({ [System.Version]$_.CIM.DriverVersion -le [System.Version]"27.20.22023.1004" }) # doesn't support Blake2s dual mining on drivers newer than 21.8.1 (27.20.22023.1004)
                                    }

                                    If ($AvailableMinerDevices) { 

                                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(If ($Pool1) { "&$($Pool1.AlgorithmVariant)$(If ($_.Intensity) { "-$($_.Intensity)" })"})"

                                        $Arguments = $_.Arguments
                                        $Arguments += " -pool $(If ($Pool0.PoolPorts[1]) { "ssl://" })$($Pool0.Host):$($Pool0.PoolPorts | Select-Object -Last 1) -wal $($Pool0.User)"
                                        $Arguments += Switch ($Pool0.Protocol) { 
                                            "ethproxy"     { " -proto 2" }
                                            "minerproxy"   { " -proto 1" }
                                            "ethstratum1"  { " -proto 4" }
                                            "ethstratum2"  { " -proto 5" }
                                            "ethstratumnh" { " -proto 5" }
                                            "qtminer"      { " -proto 3" }
                                            Default        { " -proto 1" }
                                        }
                                        If ($Config.SSLallowSelfSignedCertificate -and $Pool0.PoolPorts[1]) { $Arguments += " -weakssl" } # https://bitcointalk.org/index.php?topic=2647654.msg60032993#msg60032993
                                        If ($Pool0.WorkerName) { $Arguments += " -worker $($Pool0.WorkerName)" }
                                        $Arguments += " -pass $($Pool0.Pass)"

                                        If ($Pool0.DAGSizeGiB -gt 0) { 
                                            If ("MiningPoolHub", "ProHashing" -contains $Pool0.Name) { $Arguments += " -proto 1" }
                                            ElseIf ($Pool0.Name -eq "NiceHash") { $Arguments += " -proto 4" }
                                        }

                                        # kernel 3 does not support dual mining
                                        If (($AvailableMinerDevices.Memory | Measure-Object -Minimum).Minimum / 1GB -ge 2 * $MinMemGiB -and -not $_.Algorithms[1]) { # Faster kernels require twice as much VRAM
                                            If ($AvailableMinerDevices.Vendor -eq "AMD") { $Arguments += " -clkernel 3" }
                                            ElseIf ($AvailableMinerDevices.Vendor -eq "NVIDIA") { $Arguments += " -nvkernel 3" }
                                        }

                                        If ($_.Algorithms[1]) { 
                                            $Arguments += " -dpool $(If ($Pool1.PoolPorts[1]) { "ssl://" })$($Pool1.Host):$($Pool1.PoolPorts | Select-Object -Last 1) -dwal $($Pool1.User) -dpass $($Pool1.Pass)"
                                            If ($Config.SSLallowSelfSignedCertificate -and $Pool1.PoolPorts[1]) { $Arguments += " -weakssl2" } # https://bitcointalk.org/index.php?topic=2647654.msg60032993#msg60032993
                                            If ($Pool1.WorkerName) { $Arguments += " -dworker $($Pool1.WorkerName)" }
                                            If ($_.Intensity) { $Arguments += " -sci $($_.Intensity)" }
                                        }

                                        # Allow more time to build larger DAGs, must use type cast to keep values in $_
                                        $WarmupTimes = [UInt16[]]$_.WarmupTimes
                                        $WarmupTimes[0] += [UInt16](($Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB) * 2)

                                        # Apply tuning parameters
                                        If ($Variables.ApplyMinerTweaks) { $_.Arguments += $_.Tuning }

                                        [PSCustomObject]@{ 
                                            API         = "EthMiner"
                                            Arguments   = "$Arguments -vmdag 0 -log 0 -wdog 0 -cdmport $MinerAPIPort -gpus $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:d}' -f ($_ + 1) }) -join ',')"
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
                }
            )
        }
    )
}