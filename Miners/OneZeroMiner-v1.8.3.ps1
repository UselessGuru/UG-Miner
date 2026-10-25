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
Version:        6.9.1
Version date:   2026/10/25
#>

# Performance improvement for 20xx, 30xx, 40xx, and 50xx series (locked mem 810 kernel)
# Fixed the H100 invalid proof size of v1.8.2
# Fixed a bug related to the invalid hits messages
# Fixed a bug that could cause rejected shares if the gpu was shared with an another process

if (-not ($Devices = $Session.EnabledDevices.Where{ $_.Type -eq "AMD" -or ($_.Type -eq "NVIDIA" -and $_.OpenCL.ComputeCapability -ge "6.0" -and $_.OpenCL.DriverVersion -ge [System.Version]"528.33.00") })) { return }

$URL = "https://github.com/OneZeroMiner/onezerominer/releases/download/v1.8.3/onezerominer-win64-1.8.3.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\onezerominer.exe"
$DeviceEnumerator = "Type_Slot"

$Algorithms = @( 
    @{ Algorithms = @("CrypticHashV2", "");    Type = "AMD"; Fee = @(0.02); MinMemGiBfree = 2; WarmupTimes = @(180, 10);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" -a cryptix_ox8") }
    @{ Algorithms = @("DynexSolve", "");       Type = "AMD"; Fee = @(0.02); MinMemGiBfree = 2; WarmupTimes = @(180, 120); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" -a dynex") }
    @{ Algorithms = @("QHash", "");            Type = "AMD"; Fee = @(0.03); MinMemGiBfree = 2; WarmupTimes = @(180, 10);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" -a qhash") }
    @{ Algorithms = @("Qhash", "XelisHashV3"); Type = "AMD"; Fee = @(0.03); MinMemGiBfree = 2; WarmupTimes = @(180, 10);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" -a qhash", " --a2 xelishashv3") }
    @{ Algorithms = @("XelisHashV3", "");      Type = "AMD"; Fee = @(0.02); MinMemGiBfree = 2; WarmupTimes = @(180, 10);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" -a xelishashv3") }

     
    @{ Algorithms = @("CrypticHashV2", "");    Type = "NVIDIA"; Fee = @(0.02); MinMemGiBfree = 2; WarmupTimes = @(180, 10);  ExcludePools = @(@(), @()); Arguments = @(" -a cryptix_ox8") }
    @{ Algorithms = @("DynexSolve", "");       Type = "NVIDIA"; Fee = @(0.02); MinMemGiBfree = 2; WarmupTimes = @(180, 120); ExcludePools = @(@(), @()); Arguments = @(" -a dynex") }
    @{ Algorithms = @("PearlHash", "");        Type = "NVIDIA"; Fee = @(0.03); MinMemGiBfree = 2; WarmupTimes = @(180, 10);  ExcludePools = @(@(), @()); Arguments = @(" -a pearlhash") }
    @{ Algorithms = @("QHash", "");            Type = "NVIDIA"; Fee = @(0.03); MinMemGiBfree = 2; WarmupTimes = @(180, 10);  ExcludePools = @(@(), @()); Arguments = @(" -a qhash") }
    @{ Algorithms = @("Qhash", "XelisHashV3"); Type = "NVIDIA"; Fee = @(0.03); MinMemGiBfree = 2; WarmupTimes = @(180, 10);  ExcludePools = @(@(), @()); Arguments = @(" -a qhash", " --a2 xelishashv3") }
    @{ Algorithms = @("Quantus", "");          Type = "NVIDIA"; Fee = @(0.02); MinMemGiBfree = 2; WarmupTimes = @(180, 10);  ExcludePools = @(@(), @()); Arguments = @(" -a qantus") }
    @{ Algorithms = @("XelisHashV3", "");      Type = "NVIDIA"; Fee = @(0.02); MinMemGiBfree = 2; WarmupTimes = @(180, 10);  ExcludePools = @(@(), @()); Arguments = @(" -a xelishashv3") }
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
            if ($SupportedMinerDevices = $MinerDevices.Where{ $_.Type -eq "CPU" -or $_.Architecture -notmatch $ExcludeGPUarchitectures }) { 

                $ExcludePools = $_.ExcludePools
                foreach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where{ $ExcludePools[0] -notcontains $_.Name }) { 
                    foreach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where{ $ExcludePools[1] -notcontains $_.Name }) { 

                        $MinMemGiBfree = $_.MinMemGiBfree
                        if ($AvailableMinerDevices = $SupportedMinerDevices.Where{ $_.MemoryGiBfree -ge $MinMemGiBfree }) { 

                            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(if ($Pool1) { "&$($Pool1.AlgorithmVariant)" })"

                            $Arguments = "$($_.Arguments[0]) --pool $(if ($Pool0.PoolPorts[1]) { "+ssl://$($Pool0.Host):$($Pool0.PoolPorts[1])" } else { "://$($Pool0.Host):$($Pool0.PoolPorts[0])" }) --wallet $($Pool0.User) --pass $($Pool0.Pass)"

                            if (($_.Algorithms[1])) { $Arguments = "$Arguments$($_.Arguments[1]) --o2 stratum$(if ($Pool1.PoolPorts[1]) { "+ssl://$($Pool1.Host):$($Pool1.PoolPorts[1])" } else { "://$($Pool1.Host):$($Pool1.PoolPorts[0])" }) --w2 $($Pool1.User) --p2 $($Pool1.Pass)" }

                            @{ 
                                API         = "OneZero"
                                Arguments   = "$Arguments$(if (($Pool0.PoolPorts[1] -or $Pool1.PoolPorts[1]) -and $Session.Config.SSLallowSelfSignedCertificate) { " --no-cert-validation" }) --api-port $MinerAPIPort --hashrate-avg 5 --disable-telemetry --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach{ '{0:x}' -f $_ } -join ',')"
                                DeviceNames = $AvailableMinerDevices.Name
                                DownloadURL = $URL
                                Fee         = $_.Fee # Dev fee
                                Name        = $MinerName
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = $Type
                                WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers     = @(($Pool0, $Pool1).ForEach{ if ($_) { @{ Pool = $_ } } })
                            }
                        }
                    }
                }
            }
        }
    }
}