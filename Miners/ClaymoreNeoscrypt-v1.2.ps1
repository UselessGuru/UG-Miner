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
Version:        6.2.2
Version date:   2024/03/28
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "AMD" -and $Variables.DriverVersion.CIM.AMD -lt [Version]"26.20.15011.10003" }))) { Return }

$URI = "https://github.com/UselessGuru/miners/releases/download/ClaymoreNeoscrypt/claymore_neoscrypt_1.2.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\NeoScryptMiner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "Neoscrypt"; MinMemGiB = 2; MinerSet = 2; WarmupTimes = @(45, 0); ExcludeGPUArchitecture = @("RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(); Arguments = "" } # FPGA
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

If ($Algorithms) { 

    ($Devices | Select-Object Model -Unique).ForEach(
        { 
            If ($Miner_Devices = $Devices | Where-Object Model -EQ $_.Model) { 

                $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

                $Algorithms.ForEach(
                    { 
                        $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
                        $MinMemGiB  = $_.MinMemGiB 
                        If ($AvailableMiner_Devices = $Miner_Devices.Where({ $_.Architecture -notin $ExcludeGPUArchitecture -and $_.MemoryGiB -ge $MinMemGiB })) { 

                            $Miner_Name = "$Name-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)-$($_.Algorithm)"

                            $ExcludePools = $_.ExcludePools
                            ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $_.Name -notin $ExcludePools })) { 

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
                                    Arguments   = "$($_.Arguments) -pool $(If ($Pool.PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) -wal $($Pool.User)$(If ($Pool.Pass) { " -psw $($Pool.Pass)" }) -mport -$MinerAPIPort -di $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                    DeviceNames = $AvailableMiner_Devices.Name
                                    Fee         = $Fee # Dev fee
                                    MinerSet    = $_.MinerSet
                                    Name        = $Miner_Name
                                    Path        = $Path
                                    Port        = $MinerAPIPort
                                    Type        = "AMD"
                                    URI         = $Uri
                                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                    Workers     = @(@{ Pool = $Pool })
                                }
                            }
                        }
                    }
                )
            }
        }
    )
}