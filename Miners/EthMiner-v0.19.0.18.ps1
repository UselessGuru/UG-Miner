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
Version:        6.2.17
Version date:   2024/07/13
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "AMD" -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.CUDAVersion -ge [Version]"9.1") }))) { Return }

$URI = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.6" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/EthMiner/ethminer-0.19.0-18-cuda11.6-windows-vs2019-amd64.zip"; Break }
    { $_ -ge "10.0" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/EthMiner/ethminer-0.19.0-18-cuda10.0-windows-amd64.zip"; Break }
    Default           { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/EthMiner/ethminer-0.19.0-18-cuda9.1-windows-amd64.zip" }
}
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\ethminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

# AMD miners may need https://github.com/ethereum-mining/ethminer/issues/2001
# NVIDIA Enable Hardware-Accelerated GPU Scheduling

$Algorithms = @(
    @{ Algorithm = "Ethash"; Type = "AMD"; MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(); Arguments = " --opencl --opencl-devices" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool

    @{ Algorithm = "Ethash"; Type = "NVIDIA"; MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(); Arguments = " --cuda --cuda-devices" } # PhoenixMiner-v6.2c is fastest but has dev fee
)

# $Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
# $Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })

If ($Algorithms) { 

    ($Devices | Select-Object Type, Model -Unique).ForEach(
        { 
            If ($MinerDevices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model) { 
                $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

                ($Algorithms | Where-Object Type -eq $_.Type).ForEach(
                    { 
                        # $ExcludePools = $_.ExcludePools
                        # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.Name -notin $ExcludePools })) { 
                        ForEach ($Pool in $MinerPools[0][$_.Algorithm]) { 

                            $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                            If ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($Pool.AlgorithmVariant)"

                                $Pass = "$($Pool.Pass)"

                                $Protocol = Switch ($Pool.Protocol) { 
                                    "ethstratum1"  { "stratum2"; Break }
                                    "ethstratum2"  { "stratum3"; Break }
                                    "ethstratumnh" { "stratum2"; Break }
                                    Default        { "stratum" }
                                }
                                $Protocol += If ($Pool.PoolPorts[1]) { "+tls" } Else { "+tcp" }

                                [PSCustomObject]@{ 
                                    API         = "EthMiner"
                                    Arguments   = " --pool $($Protocol)://$([System.Web.HttpUtility]::UrlEncode("$($Pool.User)")):$([System.Web.HttpUtility]::UrlEncode($Pass))@$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --exit --api-port -$MinerAPIPort $($_.Arguments) $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ' ')"
                                    DeviceNames = $AvailableMinerDevices.Name
                                    EnvVars     = @("SSL_NOVERIFY=TRUE")
                                    Fee         = @(0) # Dev fee
                                    MinerSet    = $_.MinerSet
                                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                                    Name        = $MinerName
                                    Path        = $Path
                                    Port        = $MinerAPIPort
                                    Type        = $_.Type
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