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
Version:        6.2.24
Version date:   2024/08/10
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -ge "5.0" -and $_.CUDAVersion -ge [Version]"9.1" }))) { Return }

$URI = "https://github.com/frkhash/frkhashminer/releases/download/v1.3.14/frkminer.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\frkminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"


$Algorithms = @(
    @{ Algorithm = "FrkHash"; Type = "NVIDIA"; MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(); Arguments = " --cuda" }
)

# $Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

If ($Algorithms) { 

    ($Devices | Select-Object Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type =  $_.Type
            $MinerDevices = $Devices.Where({ $_.Model -eq $Model -and $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    $MinMemGiB = $_.MinMemGiB
                    If ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($_.Algorithm)"

                        # $ExcludePools = $_.ExcludePools
                        # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 
                        ForEach ($Pool in $MinerPools[0][$_.Algorithm]) { 

                            [PSCustomObject]@{ 
                                API         = "EthMiner"
                                Arguments   = "$($_.Arguments) --pool $(If ($Pool.PoolPorts[1]) { "stratums" } Else { "stratum" })://$([System.Web.HttpUtility]::UrlEncode("$($Pool.User)")):$([System.Web.HttpUtility]::UrlEncode("$($Pool.Pass)"))@$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --exit --api-port -$MinerAPIPort --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0}' -f $_ }) -join ' ')"
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
    )
}