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
Version:        6.7.16
Version date:   2025/12/31
#>

if (-not ($Devices = $Session.EnabledDevices.Where({ $_.Type -eq "CPU" -or @("AMD", "INTEL") -contains $_.Type -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.OpenCL.DriverVersion -ge [System.Version]"455.23") }))) { return }

$URI = "https://github.com/nanopool/nanominer/releases/download/v3.10.0/nanominer-windows-3.10.0.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\nanominer.exe"
$DeviceEnumerator = "Type_Slot"

$Algorithms = @(
    @{ Algorithms = @("Autolykos2", "");         Type = "AMD"; Fee = @(0.025); MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = " "; ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -algo Autolykos") }
    @{ Algorithms = @("EtcHash", "");            Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" -algo Etchash") } # PhoenixMiner-v6.2c is fastest
    @{ Algorithms = @("Ethash", "");             Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" -algo Ethash") } # PhoenixMiner-v6.2c is fastest
    @{ Algorithms = @("EthashB3", "");           Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" -algo EthashB3") }
    @{ Algorithms = @("EvrProgPow", "");         Type = "AMD"; Fee = @(0.02);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" -algo Evrprogpow") }
    @{ Algorithms = @("FiroPow", "");            Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" -algo FiroPow") }
    @{ Algorithms = @("FishHash", "");           Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" -algo Fishhash") }
    @{ Algorithms = @("HeavyHashKarlsenV2", ""); Type = "AMD"; Fee = @(0.01);  MinMemGiB = 2;    Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" -algo Karlsen") }
    @{ Algorithms = @("KawPow", "");             Type = "AMD"; Fee = @(0.02);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" -algo KawPow") } # TeamRedMiner-v0.10.21 is fastest
    @{ Algorithms = @("UbqHash", "");            Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @());           Arguments = @(" -algo Ubqhash") } # PhoenixMiner-v6.2c is fastest
    @{ Algorithms = @("VertHash", "");           Type = "AMD"; Fee = @(0.01);  MinMemGiB = 3;    Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@( ), @());          Arguments = @(" -algo Verthash") }

#   @{ Algorithms = @("Randomx", "");    Type = "CPU"; Fee = @(0.02); WarmupTimes = @(45, 0); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" -algo Randomx") } # ASIC
    @{ Algorithms = @("RandomNevo", ""); Type = "CPU"; Fee = @(0.02); WarmupTimes = @(45, 0); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" -algo RandomNEVO") }
    @{ Algorithms = @("VerusHash", "");  Type = "CPU"; Fee = @(0.02); WarmupTimes = @(69, 0); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" -algo Verushash") }

    @{ Algorithms = @("EtcHash", "");            Type = "INTEL"; Fee = @(0.01); MinMemGiB = 1.08; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" -algo Etchash") }
    @{ Algorithms = @("Ethash", "");             Type = "INTEL"; Fee = @(0.01); MinMemGiB = 1.08; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" -algo Ethash") }
    @{ Algorithms = @("EthashB3", "");           Type = "INTEL"; Fee = @(0.01); MinMemGiB = 1.08; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" -algo EthashB3") }
    @{ Algorithms = @("EvrProgPow", "");         Type = "INTEL"; Fee = @(0.02); MinMemGiB = 1.08; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" -algo Evrprogpow") }
    @{ Algorithms = @("FishHash", "");           Type = "INTEL"; Fee = @(0.01); MinMemGiB = 1.08; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" -algo Fishhash") }
    @{ Algorithms = @("HeavyHashKarlsenV2", ""); Type = "INTEL"; Fee = @(0.01); MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" -algo Karlsen") }
    @{ Algorithms = @("KawPow", "");             Type = "INTEL"; Fee = @(0.02); MinMemGiB = 1.08; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" -algo KawPow") } # Trex-v0.26.8 is fastest
    @{ Algorithms = @("Octopus", "");            Type = "INTEL"; Fee = @(0.02); MinMemGiB = 1.08; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" -algo Octopus") }
    @{ Algorithms = @("UbqHash", "");            Type = "INTEL"; Fee = @(0.01); MinMemGiB = 1.08; WarmupTimes = @(75, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" -algo Ubqhash") }

    @{ Algorithms = @("Autolykos2", "");         Type = "NVIDIA"; Fee = @(0.025); MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @(@("NiceHash"), @()); Arguments = @(" -algo Autolykos") } # Trex-v0.26.8 is fastest
    @{ Algorithms = @("EtcHash", "");            Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @());           Arguments = @(" -algo Etchash") } # PhoenixMiner-v6.2c is fastest
    @{ Algorithms = @("Ethash", "");             Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @());           Arguments = @(" -algo Ethash") } # PhoenixMiner-v6.2c is fastest
    @{ Algorithms = @("EthashB3", "");           Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @());           Arguments = @(" -algo EthashB3") }
    @{ Algorithms = @("EvrProgPow", "");         Type = "NVIDIA"; Fee = @(0.02);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @());           Arguments = @(" -algo Evrprogpow") }
    @{ Algorithms = @("FiroPow", "");            Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @());           Arguments = @(" -algo FiroPow") }
    @{ Algorithms = @("FishHash", "");           Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @());           Arguments = @(" -algo Fishhash") }
    @{ Algorithms = @("HeavyHashKarlsenV2", ""); Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 2;    Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @());           Arguments = @(" -algo Karlsen") }
    @{ Algorithms = @("KawPow", "");             Type = "NVIDIA"; Fee = @(0.02);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @());           Arguments = @(" -algo KawPow") } # Trex-v0.26.8 is fastest
    @{ Algorithms = @("Octopus", "");            Type = "NVIDIA"; Fee = @(0.02);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @());           Arguments = @(" -algo Octopus") }
    @{ Algorithms = @("UbqHash", "");            Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @());           Arguments = @(" -algo Ubqhash") } # PhoenixMiner-v6.2c is fastest
)

$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] })
$Algorithms = $Algorithms.Where({ -not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]] })
# $Algorithms = $Algorithms.Where({ $Session.Config.SSL -ne "Always" -or ($MinerPools[0][$_.Algorithms[0]].SSLselfSignedCertificate -ne $true -and (-not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]].SSLselfSignedCertificate -eq $false)) })

if ($Algorithms) { 

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    if ($SupportedMinerDevices = $MinerDevices.Where({ $_.Type -eq "CPU" -or $_.Architecture -notmatch $ExcludeGPUarchitectures })) { 

                        if ($_.Algorithm -eq "VertHash" -and (Get-Item -Path $Session.VertHashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                            $PrerequisitePath = $Session.VertHashDatPath
                            $PrerequisiteURI = "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/VertHashDataFile/VertHash.dat"
                        }
                        else { 
                            $PrerequisitePath = ""
                            $PrerequisiteURI = ""
                        }

                        $ExcludePools = $_.ExcludePools
                        foreach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $ExcludePools[0] -notcontains $_.Name })) { 
                            foreach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $ExcludePools[1] -notcontains $_.Name })) { 
                                $Pools = @(($Pool0, $Pool1).Where({ $_ }))

                                $MinMemGiB = $_.MinMemGiB + $Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB
                                if ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(if ($Pool1) { "&$($Pool1.AlgorithmVariant)" })"

                                    $Arguments = ""
                                    foreach ($Pool in $Pools) { 
                                        $Arguments += "$($_.Arguments[$Pools.IndexOf($Pool)])"
                                        $Arguments += if ($Pool.PoolPorts[1] -and $Pool.SSLselfSignedCertificate -ne $true) { " -pool1 $($Pool.Host):$($Pool.PoolPorts[1])" } else { " -pool1 $($Pool.Host):$($Pool.PoolPorts[0]) -useSSL false" }
                                        $Arguments += " -wallet $($Pool.User)"
                                        if ($_.Type -ne "CPU") { $Arguments += " -devices $(($AvailableMinerDevices | Sort-Object -Property Name -Unique).ForEach({ '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" }
                                    }
                                    Remove-Variable Pool

                                    if ($_.Type -eq "CPU") { $Arguments += " -cpuThreads $($AvailableMinerDevices.CIM.NumberOfLogicalProcessors - $($Session.Config.CPUMiningReserveCPUcore))" }
                                    $Arguments += " -mport 0 -webPort $MinerAPIPort -rigName $($Session.Config.Pools.($Pool0.Name).WorkerName) -rigPassword x -checkForUpdates false -noLog true -watchdog false"

                                    # Apply tuning parameters
                                    if ($Session.ApplyMinerTweaks) { $Arguments += $_.Tuning }

                                    [PSCustomObject]@{ 
                                        API              = "NanoMiner"
                                        Arguments        = $Arguments
                                        DeviceNames      = $AvailableMinerDevices.Name
                                        Fee              = $_.Fee # Dev fee
                                        MinerUri         = "http://127.0.0.1:$($MinerAPIPort)/#/"
                                        Name             = $MinerName
                                        Path             = $Path
                                        Port             = $MinerAPIPort
                                        PrerequisitePath = $PrerequisitePath
                                        PrerequisiteURI  = $PrerequisiteURI
                                        Type             = $Type
                                        URI              = $URI
                                        WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
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