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

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "AMD" -or ($_.Type -eq "NVIDIA" -and $_.CUDAVersion -ge [Version]"10.2") }))) { Return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/Kudaraidee/kudaraidee-v1.2.0a-win64.7z"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\Multiminer.exe"
$DeviceEnumerator = @{ AMD = "Type_Index"; NVIDIA = "Type_Vendor_Index" }

# Algorithm parameter values are case sensitive!
$Algorithms = @( 
    @{ Algorithm = "Argon2d250";   Type = "AMD"; MinMemGiB = 2; Blocksize = 250;   MinerSet = 2; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d250 --use-gpu OpenCL" }
    @{ Algorithm = "Argon2d8192";  Type = "AMD"; MinMemGiB = 2; Blocksize = 8192;  MinerSet = 2; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d8192 --use-gpu OpenCL" }
    @{ Algorithm = "Argon2d500";   Type = "AMD"; MinMemGiB = 2; Blocksize = 500;   MinerSet = 2; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d500 --use-gpu OpenCL" }
    @{ Algorithm = "Argon2d4096";  Type = "AMD"; MinMemGiB = 2; Blocksize = 4096;  MinerSet = 2; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d4096 --use-gpu OpenCL" }
    @{ Algorithm = "Argon2d16000"; Type = "AMD"; MinMemGiB = 2; Blocksize = 16000; MinerSet = 1; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d16000 --use-gpu OpenCL" }

    @{ Algorithm = "Argon2d250";   Type = "NVIDIA"; MinMemGiB = 2; Blocksize = 250;   MinerSet = 2; WarmupTimes = @(60, 60); ExcludePools = @(); Arguments = " --algo argon2d250 --use-gpu CUDA" }
    @{ Algorithm = "Argon2d8192";  Type = "NVIDIA"; MinMemGiB = 2; Blocksize = 8192;  MinerSet = 2; WarmupTimes = @(60, 60); ExcludePools = @(); Arguments = " --algo argon2d8192 --use-gpu CUDA" }
    @{ Algorithm = "Argon2d500";   Type = "NVIDIA"; MinMemGiB = 2; Blocksize = 500;   MinerSet = 2; WarmupTimes = @(60, 60); ExcludePools = @(); Arguments = " --algo argon2d500 --use-gpu CUDA" }
    @{ Algorithm = "Argon2d4096";  Type = "NVIDIA"; MinMemGiB = 2; Blocksize = 4096;  MinerSet = 2; WarmupTimes = @(60, 60); ExcludePools = @(); Arguments = " --algo argon2d4096 --use-gpu CUDA" }
    @{ Algorithm = "Argon2d16000"; Type = "NVIDIA"; MinMemGiB = 2; Blocksize = 16000; MinerSet = 0; WarmupTimes = @(60, 60); ExcludePools = @(); Arguments = " --algo argon2d16000 --use-gpu CUDA" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

If ($Algorithms) { 

    ($Devices | Select-Object Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    $MinMemGiB = $_.MinMemGiB
                    If ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($_.Algorithm)"

                        # $ExcludePools = $_.ExcludePools
                        # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name })) { 
                        ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] })) { 

                            $BlockSize = $_.BlockSize
                            # 1 GB memory reserve, then 1 thread per 4GB
                            $Threads = [Math]::Ceiling(($AvailableMinerDevices.ForEach({ ($_.MemoryGiB - 1) / 4 }) | Measure-Object -Minimum).Minimum)

                            # Reserve 250KB for AMD driver, for NVIDIA
                            $GPUmemory = ($AvailableMinerDevices.ForEach({ $_.MemoryGiB }) | Measure-Object -Minimum).Minimum
                            If ($_.Type -eq "AMD") { $GPUmemory -= 0.25 } Else { $GPUmemory = $GPUmemory * 0.95 - 0.4 }
                            $BatchSize = [Math]::Floor(($GPUmemory * 0.5MB / $Blocksize / $Threads) * 2)

                            [PSCustomObject]@{ 
                                API         = "CcMiner"
                                Arguments   = "$($_.Arguments) --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User) --pass $($Pool.Pass) --gpu-batchsize $BatchSize --threads $Threads --retry-pause 1 --api-bind 127.0.0.1:$($MinerAPIPort) --gpu-id $((($AvailableMinerDevices.($DeviceEnumerator.($_.Type)) | Sort-Object -Unique).ForEach({ '{0:x}' -f ($_ + 1)})) -join ',')"
                                DeviceNames = $AvailableMinerDevices.Name
                                Fee         = @(0) # Dev fee
                                MinerSet    = $_.MinerSet
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