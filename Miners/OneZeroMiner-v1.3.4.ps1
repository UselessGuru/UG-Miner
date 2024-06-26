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
Version:        6.2.12
Version date:   2024/06/26
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "NVIDIA" -and $_.OpenCL.DriverVersion -ge [Version]"450.80.02" }))) { Return }

$URI = "https://github.com/OneZeroMiner/onezerominer/releases/download/v1.3.4/onezerominer-win64-1.3.4.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\onezerominer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @( 
    [PSCustomObject]@{ Algorithm = "DynexSolve"; Fee = @(0.03); MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(180, 120); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = @(" --algo dynex") }
    [PSCustomObject]@{ Algorithm = "XelisHash";  Fee = @(0.03); MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(180, 120); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = @(" --algo xelis") }
)

# $Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
# $Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })

If ($Algorithms) { 

    ($Devices | Select-Object Model -Unique).ForEach(
        { 
            If ($MinerDevices = @($Devices | Where-Object Model -EQ $_.Model) ) { 
                $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

                $Algorithms.ForEach(
                    { 
                        $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
                        $MinMemGiB = $_.MinMemGiB
                        If ($AvailableMinerDevices = $MinerDevices.Where({ $_.Architecture -notin $ExcludeGPUArchitecture -and $_.MemoryGiB -ge $MinMemGiB })) { 

                            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($_.Algorithm)"

                            # $ExcludePools = $_.ExcludePools
                            # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.Name -notin $ExcludePools })) { 
                            ForEach ($Pool in $MinerPools[0][$_.Algorithm]) { 

                                [PSCustomObject]@{ 
                                    API         = "OneZero"
                                    Arguments   = "$($_.Arguments) --pool $(If ($Pool.PoolPorts[1]) { "ssl://" })$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --wallet $($Pool.User) --pass $($Pool.Pass)$(If ($Pool.PoolPorts[1] -and $Config.SSLAllowSelfSignedCertificate) { " --no-cert-validation" }) --api-port $MinerAPIPort --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                    DeviceNames = $AvailableMinerDevices.Name
                                    Fee         = $_.Fee # Dev fee
                                    MinerSet    = $_.MinerSet
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
                    }
                )
            }
        }
    )
}