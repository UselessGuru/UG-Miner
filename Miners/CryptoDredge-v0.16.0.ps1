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
Version:        6.7.26
Version date:   2026/02/01
#>

if (-not ($Devices = $Session.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -ge "5.0" }))) { return }

$URI = switch ($Session.DriverVersion.CUDA) { 
    { $_ -ge [System.Version]"10.0" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/CryptoDredge/CryptoDredge_0.16.0_cuda_10.0_windows.zip"; break }
    { $_ -ge [System.Version]"9.2" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/CryptoDredge/CryptoDredge_0.16.0_cuda_9.2_windows.zip"; break }
    default { return }
}
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\CryptoDredge.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    @{ Algorithm = "Allium";    Fee = @(0.01); MinMemGiB = 2; WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo allium --intensity 8" } # FPGA
    @{ Algorithm = "Exosis";    Fee = @(0.01); MinMemGiB = 2; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo exosis --intensity 8" }
    @{ Algorithm = "Dedal";     Fee = @(0.01); MinMemGiB = 2; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo dedal --intensity 8" }
    @{ Algorithm = "HMQ1725";   Fee = @(0.01); MinMemGiB = 2; WarmupTimes = @(60, 0); ExcludePools = @(); Arguments = " --algo hmq1725 --intensity 8" } # CryptoDredge v0.26.0 is fastest
    @{ Algorithm = "Neoscrypt"; Fee = @(0.01); MinMemGiB = 2; WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo neoscrypt --intensity 6" } # FPGA
#   @{ Algorithm = "Phi";       Fee = @(0.01); MinMemGiB = 2; WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo phi --intensity 8" } # ASIC
    @{ Algorithm = "Phi2";      Fee = @(0.01); MinMemGiB = 2; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo phi2 --intensity 8" }
    @{ Algorithm = "Pipe";      Fee = @(0.01); MinMemGiB = 2; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo pipe --intensity 8" }
)

$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

if ($Algorithms) { 

    ($Devices | Sort-Object -Property Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.Where({ $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.ForEach(
                { 
                    $MinMemGiB = $_.MinMemGiB

                    if ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($_.Algorithm)"

                        $ExcludePools = $_.ExcludePools
                        foreach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name })) { 

                            $Arguments = "$($_.Arguments) --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User)"
                            if ($Pool.WorkerName -and $Pool.User -notmatch "\.$($Pool.WorkerName)$") { $Arguments += ".$($Pool.WorkerName)" }
                            $Arguments += " --pass $($Pool.Pass)"

                            [PSCustomObject]@{ 
                                API         = "CcMiner"
                                Arguments   = "$Arguments --cpu-priority $($Session.Config.GPUMinerProcessPriority + 2) --no-watchdog --no-crashreport --retries 1 --retry-pause 1 --api-type ccminer-tcp --api-bind 127.0.0.1:$($MinerAPIPort) --device $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                DeviceNames = $AvailableMinerDevices.Name
                                Fee         = $_.Fee # Dev fee
                                Name        = $MinerName
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = "NVIDIA"
                                URI         = $URI
                                WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers     = @(@{ Pool = $Pool })
                            }
                        }
                    }
                }
            )
        }
    )
}