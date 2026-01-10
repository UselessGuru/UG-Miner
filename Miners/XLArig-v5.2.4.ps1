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
Version:        6.7.20
Version date:   2026/01/10
#>

# https://github.com/scala-network/XLArig/issues/59; Need to remove temp fix in \Includes\MinerAPIs\XMrig.psm1 when resolved

if (-not ($AvailableMinerDevices = $Session.EnabledDevices.Where({ $_.Type -eq "CPU" }))) { return }

$URI = "https://github.com/scala-network/XLArig/releases/download/v5.2.4/xlarig-v5.2.4-win64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\xlarig.exe"

$Algorithms = @(
    @{ Algorithm = "Panthera"; WarmupTimes = @(15, 0); ExcludePools = @(); Arguments = " --algo=panthera" }
)

$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

if ($Algorithms) { 

    $MinerAPIPort = $Session.MinerBaseAPIport + ($AvailableMinerDevices.Id | Sort-Object -Top 1)

    $Algorithms.ForEach(
        { 
            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($_.Algorithm)"

            $Fee = if ($Session.Config.DisableMinerFee) { 0 } else { 5 }

            # $ExcludePools = $_.ExcludePools
            # foreach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name })) { 
            foreach ($Pool in $MinerPools[0][$_.Algorithm]) { 

                $RigID = if ($Pool.WorkerName) { $Pool.WorkerName } elseif ($Pool.User -like "*.*") { $Pool.User -replace ".+\." } else { $Session.Config.WorkerName }

                [PSCustomObject]@{ 
                    API         = "XmRig"
                    Arguments   = "$($_.Arguments)$(if ($Pool.Name -eq "NiceHash") { " --nicehash" }) --url=stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user=$($Pool.User) --pass=$($Pool.Pass) --rig-id $RigID --donate-level=$Fee --http-enabled --http-host=127.0.0.1 --http-port=$($MinerAPIPort) --api-worker-id=$RigID --api-id=$($MinerName) --http-port=$MinerAPIPort --threads=$($AvailableMinerDevices.CIM.NumberOfLogicalProcessors - $Session.Config.CPUMiningReserveCPUcore) --retry-pause 1 --keepalive"
                    DeviceNames = $AvailableMinerDevices.Name
                    Fee         = @($Fee) # Dev fee
                    MinerUri    = "http://workers.xmrig.info/worker?url=$([System.Web.HTTPUtility]::UrlEncode("http://127.0.0.1:$($MinerAPIPort)"))?Authorization=Bearer $([System.Web.HTTPUtility]::UrlEncode($MinerName))"
                    Name        = $MinerName
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = "CPU"
                    URI         = $URI
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                    Workers     = @(@{ Pool = $Pool })
                }
            }
        }
    )
}