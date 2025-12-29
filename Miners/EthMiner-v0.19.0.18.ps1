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
Version:        6.7.15
Version date:   2025/12/29
#>

if (-not ($Devices = $Session.EnabledDevices.Where({ $_.Type -eq "AMD" -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.CUDAversion -ge [System.Version]"9.1") }))) { return }

$URI = switch ($Session.DriverVersion.CUDA) { 
    { $_ -ge [System.Version]"11.6" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/EthMiner/ethminer-0.19.0-18-cuda11.6-windows-vs2019-amd64.zip"; break }
    { $_ -ge [System.Version]"10.0" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/EthMiner/ethminer-0.19.0-18-cuda10.0-windows-amd64.zip"; break }
    default { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/EthMiner/ethminer-0.19.0-18-cuda9.1-windows-amd64.zip" }
}
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\ethminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

# AMD miners may need https://github.com/ethereum-mining/ethminer/issues/2001
# NVIDIA Enable Hardware-Accelerated GPU Scheduling

$Algorithms = @(
    @{ Algorithm = "Ethash"; Type = "AMD"; MinMemGiB = 1.24; WarmupTimes = @(45, 10); ExcludePools = @(); Arguments = " --opencl --opencl-devices" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool

    @{ Algorithm = "Ethash"; Type = "NVIDIA"; MinMemGiB = 1.24; WarmupTimes = @(45, 10); ExcludePools = @(); Arguments = " --cuda --cuda-devices" } # PhoenixMiner-v6.2c is fastest but has dev fee
)

$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

if ($Algorithms) { 

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    # $ExcludePools = $_.ExcludePools
                    # foreach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 
                    foreach ($Pool in $MinerPools[0][$_.Algorithm]) { 

                        $MinMemGiB = $_.MinMemGiB + $Pool.DAGsizeGiB
                        if ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                            $Protocol = switch ($Pool.Protocol) { 
                                "ethstratum1" { "stratum2"; break }
                                "ethstratum2" { "stratum2"; break }
                                "ethstratumnh" { "stratum2"; break }
                                default { "stratum" }
                            }
                            $Protocol += if ($Pool.PoolPorts[1]) { "+tls" } else { "+tcp" }

                            [PSCustomObject]@{ 
                                API         = "EthMiner"
                                Arguments   = " --pool $($Protocol)://$([System.Web.HttpUtility]::UrlEncode($Pool.User)):$([System.Web.HttpUtility]::UrlEncode($Pool.Pass))@$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --exit --api-port -$MinerAPIPort$($_.Arguments) $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join " ")"
                                DeviceNames = $AvailableMinerDevices.Name
                                EnvVars     = @("SSL_NOVERIFY=TRUE")
                                Fee         = @(0) # Dev fee
                                MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                                Name        = $MinerName
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = $Type
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