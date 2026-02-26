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
Version:        6.7.30
Version date:   2026/02/26
#>

if (-not ($AvailableMinerDevices = $Session.EnabledDevices.Where({ $_.Type -eq "CPU" }))) { return }

if ($AvailableMinerDevices.CPUfeatures -contains "AVX2")    { $URI = "https://github.com/hellcatz/hminer/releases/download/v0.59.1/hellminer_win64_avx2.zip" }
elseif ($AvailableMinerDevices.CPUfeatures -contains "AVX") { $URI = "https://github.com/hellcatz/hminer/releases/download/v0.59.1/hellminer_win64_avx.zip" }
else                                                        { $URI = "https://github.com/hellcatz/hminer/releases/download/v0.59.1/hellminer_win64.zip" }

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\hellminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    @{ Algorithm = "VerusHash"; Fee = @(0.01); WarmupTimes = @(45, 90); ExcludePools = @("NiceHash"); Arguments = "" }
)

$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

if ($Algorithms) { 

    $MinerAPIPort = $Session.MinerBaseAPIport + ($AvailableMinerDevices.Id | Sort-Object -Top 1)

    $Algorithms.ForEach(
        { 
            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($_.Algorithm)"

            $ExcludePools = $_.ExcludePools
            foreach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name })) { 

                [PSCustomObject]@{ 
                    API         = "HellMiner"
                    Arguments   = " --pool=stratum+$(if ($Pool.PoolPorts[1]) { "ssl" } else { "tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user=$($Pool.User) --pass=$($Pool.Pass) --api-port=$MinerAPIPort"
                    DeviceNames = $AvailableMinerDevices.Name
                    Fee         = $_.Fee # Dev fee
                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
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