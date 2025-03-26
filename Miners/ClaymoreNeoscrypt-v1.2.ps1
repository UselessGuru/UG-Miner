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
Version:        6.4.19
Version date:   2025/03/26
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "AMD" -and $Variables.DriverVersion.CIM.AMD -lt [System.Version]"26.20.15011.10003" }))) { Return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/ClaymoreNeoscrypt/Claymore-Neoscrypt-v1.2.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\NeoScryptMiner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    @{ Algorithm = "Neoscrypt"; MinMemGiB = 2; MinerSet = 2; WarmupTimes = @(45, 0); ExcludeGPUarchitectures = "^RDNA[123]$"; ExcludePools = @(); Arguments = "" } # FPGA
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.Where({ $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    $MinMemGiB = $_.MinMemGiB 
                    If ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB -and $_.Architecture -notmatch $ExcludeGPUarchitectures })) { 

                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($_.Algorithm)"

                        # $ExcludePools = $_.ExcludePools
                        # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name })) { 
                        ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] })) { 

                            # Disable dev fee mining
                            If ($Config.DisableMinerFee) { 
                                $Arguments += " --nofee 1"
                                $Fee = @(0)
                            }
                            Else { 
                                $Fee = If ($Pool.PoolPorts[1]) { @(2.5) } Else { @(2) }
                            }

                            [PSCustomObject]@{ 
                                API         = "EthMiner"
                                Arguments   = "$($_.Arguments) -pool $(If ($Pool.PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) -wal $($Pool.User)$(If ($Pool.Pass) { " -psw $($Pool.Pass)" }) -mport -$MinerAPIPort -di $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                DeviceNames = $AvailableMinerDevices.Name
                                Fee         = $Fee # Dev fee
                                MinerSet    = $_.MinerSet
                                Name        = $MinerName
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = "AMD"
                                URI         = $URI
                                WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers     = @(@{ Pool = $Pool })
                            }
                        }
                    }
                }
            )
        }
    )
}