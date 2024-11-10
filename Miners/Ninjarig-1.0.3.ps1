<#
Copyright (c) 2018-2024 UselessGuru

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
Version:        6.3.13
Version date:   2024/11/10
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -ge "5.0" }))) { Return }

$URI = "https://github.com/UselessGuru/miner-binaries/releases/download/v1.0.3/ninjarig_v1.0.3.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\ninjarig.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    @{ Algorithm = "Chukwa"; MinerSet = 2; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " -a argon2/chukwa" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

If ($Algorithms) { 

    ($Devices | Sort-Object Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $AvailableMinerDevices = $Devices.Where({ $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIPort + ($AvailableMinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.ForEach(
                { 
                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($_.Algorithm)"

                    # $ExcludePools = $_.ExcludePools
                    # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 
                    ForEach ($Pool in $MinerPools[0][$_.Algorithm]) { 

                        If ("MiningPoolHub", "NiceHash", "ProHashing" -contains $Pool.Name) { $Arguments += " --nicehash" }
                        If ($Pool.PoolPorts[1]) { $Arguments += " --tls" }

                        [PSCustomObject]@{ 
                            API         = "XmRig"
                            Arguments   = "$($_.Arguments) --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User) --pass $($Pool.Pass) --keepalive --api-port=$MinerAPIPort --donate-level 0 -R 1 --use-gpu=CUDA -t $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                            DeviceNames = $AvailableMinerDevices.Name
                            Fee         = @(0) # Dev fee
                            MinerSet    = $_.MinerSet
                            MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                            Name        = $MinerName
                            Path        = $Path
                            Port        = $MinerAPIPort
                            Type        = "NVIDIA"
                            URI         = $URI
                            WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                            Workers     = @(@{ Pool = $Pool })
                        }
                    }
                }
            )
        }
    )
}