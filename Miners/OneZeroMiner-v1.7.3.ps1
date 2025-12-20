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
Version:        6.7.12
Version date:   2025/12/20
#>

# Qubitcoin: 
# Performance improvement for CMP cards(~5%)
# Minor improvement for the other gpus

if (-not ($Devices = $Session.EnabledDevices.where({ $_.Type -eq "AMD" -or ($_.Type -eq "NVIDIA" -and $_.OpenCL.ComputeCapability -ge "6.0" -and $_.OpenCL.DriverVersion -ge [System.Version]"528.33.00") }))) { return }

$URI = "https://github.com/OneZeroMiner/onezerominer/releases/download/v1.7.3/onezerominer-win64-1.7.3.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\onezerominer.exe"
$DeviceEnumerator = "Type_Slot"

$Algorithms = @( 
    @{ Algorithms = @("XelisHashV3", "");      Type = "AMD"; Fee = @(0.02); MinMemGiB = 2; WarmupTimes = @(180, 10); ExcludePools = @(@(), @()); Arguments = @(" -a xelishashv3") }

    @{ Algorithms = @("CrypticHashV2", "");    Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 2; WarmupTimes = @(180, 10);  ExcludePools = @(@(), @()); Arguments = @(" -a cryptix_ox8") }
    @{ Algorithms = @("DynexSolve", "");       Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 2; WarmupTimes = @(180, 120); ExcludePools = @(@(), @()); Arguments = @(" -a dynex") }
    @{ Algorithms = @("QHash", "");            Type = "NVIDIA"; Fee = @(0.03); MinMemGiB = 2; WarmupTimes = @(180, 10);  ExcludePools = @(@(), @()); Arguments = @(" -a qhash") }
    @{ Algorithms = @("Qhash", "XelisHashV3"); Type = "NVIDIA"; Fee = @(0.03); MinMemGiB = 2; WarmupTimes = @(180, 10);  ExcludePools = @(@(), @()); Arguments = @(" -a qhash"," --a2 xelishashv3") }
    @{ Algorithms = @("XelisHashV3", "");      Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 2; WarmupTimes = @(180, 10);  ExcludePools = @(@(), @()); Arguments = @(" -a xelishashv3") }
)

# $Algorithms = $Algorithms.where({ $MinerPools[0][$_.Algorithms[0]] })
$Algorithms = $Algorithms.where({ -not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]] })

if ($Algorithms) { 

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.where({ $_.Type -eq $Type }).ForEach(
                { 
                    $MinMemGiB = $_.MinMemGiB

                    if ($AvailableMinerDevices = $MinerDevices.where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                        $ExcludePools = $_.ExcludePools
                        foreach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].where({ $ExcludePools[0] -notcontains $_.Name })) { 
                            foreach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].where({ $ExcludePools[1] -notcontains $_.Name })) { 

                                $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(if ($Pool1) { "&$($Pool1.AlgorithmVariant)" })"

                                $Arguments = "$($_.Arguments[0]) -o stratum+$(if ($Pool0.PoolPorts[1]) { "ssl" })://$($Pool0.Host):$($Pool0.PoolPorts | Select-Object -Last 1) -w $($Pool0.User)$(if ($Pool0.WorkerName -and $Pool0.User -notmatch "\.$($Pool0.WorkerName)$") { ".$($Pool0.WorkerName)" }) -p $($Pool0.Pass)"

                                if (($_.Algorithms[1])) { $Arguments += "$($_.Arguments[1]) --o2 stratum$(if ($Pool1.PoolPorts[1]) { "+ssl" })://$($Pool1.Host):$($Pool1.PoolPorts | Select-Object -Last 1) --w2 $($Pool1.User)$(if ($Pool1.WorkerName -and $Pool1.User -notmatch "\.$($Pool1.WorkerName)$") { ".$($Pool1.WorkerName)" }) --p2 $($Pool1.Pass)" }

                                [PSCustomObject]@{ 
                                    API         = "OneZero"
                                    Arguments   = "$Arguments$(if (($Pool0.PoolPorts[1] -or $Pool1.PoolPorts[1]) -and $Session.Config.SSLallowSelfSignedCertificate) { " --no-cert-validation" }) --api-port $MinerAPIPort --hashrate-avg 5 --disable-telemetry --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                    DeviceNames = $AvailableMinerDevices.Name
                                    Fee         = $_.Fee # Dev fee
                                    Name        = $MinerName
                                    Path        = $Path
                                    Port        = $MinerAPIPort
                                    Type        = $Type
                                    URI         = $URI
                                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                    Workers     = @(($Pool0, $Pool1).where({ $_ }).ForEach({ @{ Pool = $_ } }))
                                }
                            }
                        }
                    }
                }
            )
        }
    )
}