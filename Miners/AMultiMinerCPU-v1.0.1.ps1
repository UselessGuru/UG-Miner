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
Version:        6.7.27
Version date:   2026/02/10
#>

if (-not ($AvailableMinerDevices = $Session.EnabledDevices.Where({ $_.Type -eq "CPU" }))) { return }

$URI = "https://github.com/Alterdot/a.multiminer/releases/download/v1.0.1/a.multiminer-v1.0.1-win64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\a.multiminer.exe"

# Algorithm parameter values are case sensitive!
$Algorithms = @( 
    @{ Algorithm = "Argon2d16000"; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d16000" }
    @{ Algorithm = "Argon2d250";   WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d250" }
    @{ Algorithm = "Argon2d500";   WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d500" }
    @{ Algorithm = "Argon2d4096";  WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d4096" }
)

$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

if ($Algorithms) { 

    $MinerAPIPort = $Session.MinerBaseAPIport + ($AvailableMinerDevices.Id | Sort-Object -Top 1)

    $Algorithms.ForEach(
        { 
            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($_.Algorithm)"

            # $ExcludePools = $_.ExcludePools
            # foreach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name })) { 
            foreach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] })) { 

                [PSCustomObject]@{ 
                    API         = "CcMiner"
                    Arguments   = "$($_.Arguments) --url $($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User) --pass $($Pool.Pass) --quiet --threads $($AvailableMinerDevices.CIM.NumberOfLogicalProcessors - $Session.Config.CPUMiningReserveCPUcore) --api-bind $($MinerAPIPort)"
                    DeviceNames = $AvailableMinerDevices.Name
                    Fee         = @(0) # Dev fee
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