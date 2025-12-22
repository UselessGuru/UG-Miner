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
Version:        6.7.13
Version date:   2025/12/22
#>

if (-not ($Devices = $Session.EnabledDevices.where({ $_.Type -eq "AMD" -and $Session.DriverVersion.CIM.AMD -lt [System.Version]"26.20.15011.10003" }))) { return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/ClaymoreNeoscrypt/Claymore-Neoscrypt-v1.2.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\NeoScryptMiner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    @{ Algorithm = "Neoscrypt"; MinMemGiB = 2; WarmupTimes = @(45, 0); ExcludeGPUarchitectures = "^RDNA[123]$"; ExcludePools = @(); Arguments = "" } # FPGA
)

$Algorithms = $Algorithms.where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

if ($Algorithms) { 

    ($Devices | Sort-Object -Property Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.where({ $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    $MinMemGiB = $_.MinMemGiB
                    if ($AvailableMinerDevices = $MinerDevices.where({ $_.MemoryGiB -ge $MinMemGiB -and $_.Architecture -notmatch $ExcludeGPUarchitectures })) { 

                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($_.Algorithm)"

                        # $ExcludePools = $_.ExcludePools
                        # foreach ($Pool in $MinerPools[0][$_.Algorithm].where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name })) { 
                        foreach ($Pool in $MinerPools[0][$_.Algorithm].where({ $_.PoolPorts[0] })) { 

                            # Disable dev fee mining
                            if ($Session.Config.DisableMinerFee) { 
                                $Arguments += " --nofee 1"
                                $Fee = @(0)
                            }
                            else { 
                                $Fee = if ($Pool.PoolPorts[1]) { @(2.5) } else { @(2) }
                            }

                            [PSCustomObject]@{ 
                                API         = "EthMiner"
                                Arguments   = "$($_.Arguments) -pool $(if ($Pool.PoolPorts[1]) { "stratum+ssl" } else { "stratum+tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) -wal $($Pool.User)$(if ($Pool.Pass) { " -psw $($Pool.Pass)" }) -mport -$MinerAPIPort -di $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                DeviceNames = $AvailableMinerDevices.Name
                                Fee         = $Fee # Dev fee
                                Name        = $MinerName
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = "AMD"
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