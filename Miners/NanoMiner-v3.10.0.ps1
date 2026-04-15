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
Version:        6.8.1
Version date:   2026/04/15
#>

if (-not ($Devices = $Session.EnabledDevices.Where({ $_.Type -eq "CPU" -or @("AMD", "INTEL") -contains $_.Type -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.OpenCL.DriverVersion -ge [System.Version]"455.23") }))) { return }

$URI = "https://github.com/nanopool/nanominer/releases/download/v3.10.0/nanominer-windows-3.10.0.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\nanominer.exe"
$DeviceEnumerator = "Type_Slot"

$Algorithms = @(
    @{ Algorithm = "Autolykos2";         Type = "AMD"; Fee = @(0.025); MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = " "; ExcludePools = @("NiceHash"); Arguments = " -algo Autolykos" }
    @{ Algorithm = "EtcHash";            Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " -algo Etchash" } # PhoenixMiner-v6.2c is fastest
    @{ Algorithm = "Ethash";             Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " -algo Ethash" } # PhoenixMiner-v6.2c is fastest
    @{ Algorithm = "EthashB3";           Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " -algo EthashB3" }
    @{ Algorithm = "EvrProgPow";         Type = "AMD"; Fee = @(0.02);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " -algo Evrprogpow" }
    @{ Algorithm = "FiroPow";            Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " -algo FiroPow" }
    @{ Algorithm = "FishHash";           Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " -algo Fishhash" }
    @{ Algorithm = "HeavyHashKarlsenV2"; Type = "AMD"; Fee = @(0.01);  MinMemGiB = 2;    Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " -algo Karlsen" }
    @{ Algorithm = "KawPow";             Type = "AMD"; Fee = @(0.02);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " -algo KawPow" } # TeamRedMiner-v0.10.21 is fastest
    @{ Algorithm = "UbqHash";            Type = "AMD"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " -algo Ubqhash" } # PhoenixMiner-v6.2c is fastest
    @{ Algorithm = "VertHash";           Type = "AMD"; Fee = @(0.01);  MinMemGiB = 3;    Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " -algo Verthash" }

#   @{ Algorithm = "Randomx";    Type = "CPU"; Fee = @(0.02); WarmupTimes = @(45, 0); ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -algo Randomx" } # ASIC
    @{ Algorithm = "RandomNevo"; Type = "CPU"; Fee = @(0.02); WarmupTimes = @(45, 0); ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -algo RandomNEVO" }
    @{ Algorithm = "VerusHash";  Type = "CPU"; Fee = @(0.02); WarmupTimes = @(69, 0); ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -algo Verushash" }

    @{ Algorithm = "EtcHash";            Type = "INTEL"; Fee = @(0.01); MinMemGiB = 1.08; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -algo Etchash" }
    @{ Algorithm = "Ethash";             Type = "INTEL"; Fee = @(0.01); MinMemGiB = 1.08; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -algo Ethash" }
    @{ Algorithm = "UbqHash";            Type = "INTEL"; Fee = @(0.01); MinMemGiB = 1.08; WarmupTimes = @(75, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -algo Ubqhash" }

    @{ Algorithm = "Autolykos2";         Type = "NVIDIA"; Fee = @(0.025); MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @("NiceHash"); Arguments = " -algo Autolykos" } # Trex-v0.26.8 is fastest
    @{ Algorithm = "EtcHash";            Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " -algo Etchash" } # PhoenixMiner-v6.2c is fastest
    @{ Algorithm = "Ethash";             Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " -algo Ethash" } # PhoenixMiner-v6.2c is fastest
    @{ Algorithm = "EthashB3";           Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " -algo EthashB3" }
    @{ Algorithm = "EvrProgPow";         Type = "NVIDIA"; Fee = @(0.02);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " -algo Evrprogpow" }
    @{ Algorithm = "FiroPow";            Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " -algo FiroPow" }
    @{ Algorithm = "FishHash";           Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " -algo Fishhash" }
    @{ Algorithm = "HeavyHashKarlsenV2"; Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 2;    Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " -algo Karlsen" }
    @{ Algorithm = "KawPow";             Type = "NVIDIA"; Fee = @(0.02);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " -algo KawPow" } # Trex-v0.26.8 is fastest
    @{ Algorithm = "Octopus";            Type = "NVIDIA"; Fee = @(0.02);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " -algo Octopus" }
    @{ Algorithm = "UbqHash";            Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1.08; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " -algo Ubqhash" } # PhoenixMiner-v6.2c is fastest
)

$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ -not $_.Algorithm -or $MinerPools[1][$_.Algorithm] })

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
                            $PrerequisiteURI  = "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/VertHashDataFile/VertHash.dat"
                        }
                        else { 
                            $PrerequisitePath = ""
                            $PrerequisiteURI  = ""
                        }

                        $ExcludePools = $_.ExcludePools
                        foreach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 

                            $MinMemGiB = $_.MinMemGiB + $Pool.DAGsizeGiB + $Pool1.DAGsizeGiB
                            if ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                                $Arguments = $_.Arguments
                                $Arguments = if ($Pool.PoolPorts[1] -and $Pool.SSLselfSignedCertificate -ne $true) { "$Arguments -pool1 $($Pool.Host):$($Pool.PoolPorts[1])" } else { "$Arguments -pool1 $($Pool.Host):$($Pool.PoolPorts[0]) -useSSL false" }
                                $Arguments = "$Arguments -wallet $($Pool.User)"
                                if ($_.Type -ne "CPU") { $Arguments = "$Arguments -devices $(($AvailableMinerDevices | Sort-Object -Property Name -Unique).ForEach({ '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" }

                                if ($_.Type -eq "CPU") { $Arguments = "$Arguments -cpuThreads $($AvailableMinerDevices.CIM.NumberOfLogicalProcessors - $($Session.Config.CPUMiningReserveCPUcore))" }
                                $Arguments = "$Arguments -mport 0 -webPort $MinerAPIPort -rigName $($Session.Config.Pools.($Pool.Name).WorkerName) -rigPassword x -checkForUpdates false -noLog true -watchdog false"

                                # Apply tuning parameters
                                if ($Session.ApplyMinerTweaks) { $Arguments = "$Arguments$($_.Tuning)" }

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
                                    Workers          = @(@{ Pool = $Pool })
                                }
                            }
                        }
                    }
                }
            )
        }
    )
}