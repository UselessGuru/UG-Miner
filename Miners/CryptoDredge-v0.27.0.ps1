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
Version:        6.2.13
Version date:   2024/06/30
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -ge "5.0" -and $_.Architecture -ne "Other" }))) { Return }

$URI = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.4" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/CryptoDredge/CryptoDredge_0.27.0_cuda_11.4_windows.zip"; Break }
    Default { Return }
}
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\CryptoDredge.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "Argon2d4096";       Fee = @(0.01); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(60, 0);  ExcludePools = @();                Arguments = " --algo argon2d4096 --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Argon2d500";        Fee = @(0.01); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(60, 0);  ExcludePools = @();                Arguments = " --algo argon2d-dyn --intensity 6" }
    [PSCustomObject]@{ Algorithm = "Argon2dNim";        Fee = @(0.01); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 0);  ExcludePools = @();                Arguments = " --algo argon2d-nim --intensity 6" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";      Fee = @(0.01); MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(30, 0);  ExcludePools = @();                Arguments = " --algo chukwa --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Argon2ChukwaV2";    Fee = @(0.01); MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(30, 0);  ExcludePools = @();                Arguments = " --algo chukwa2 --intensity 8" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";    Fee = @(0.01); MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(30, 0);  ExcludePools = @();                Arguments = " --algo cnconceal --intensity 8" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";    Fee = @(0.01); MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(30, 0);  ExcludePools = @();                Arguments = " --algo cngpu --intensity 8" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";  Fee = @(0.01); MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(30, 0);  ExcludePools = @();                Arguments = " --algo cnheavy --intensity 8" }
    [PSCustomObject]@{ Algorithm = "CryptonightTurtle"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(30, 0);  ExcludePools = @();                Arguments = " --algo cnturtle --intensity 8" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";    Fee = @(0.01); MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(30, 0);  ExcludePools = @();                Arguments = " --algo cnupx2 --intensity 8" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";    Fee = @(0.01); MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(75, 15); ExcludePools = @();                Arguments = " --algo cnhaven --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Ethash";            Fee = @(0.01); MinMemGiB = 1.25; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @("MiningPoolHub"); Arguments = " --algo ethash" }
    [PSCustomObject]@{ Algorithm = "FiroPow";           Fee = @(0.01); MinMemGiB = 1.25; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @();                Arguments = " --algo firopow" }
    [PSCustomObject]@{ Algorithm = "KawPow";            Fee = @(0.01); MinMemGiB = 1.25; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @();                Arguments = " --algo kawpow --intensity 8" } # TTMiner-v5.0.3 is fastest
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

If ($Algorithms) { 

    ($Devices | Select-Object Model -Unique).ForEach(
        { 
            If ($MinerDevices = $Devices | Where-Object Model -EQ $_.Model) { 
                $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

                $Algorithms.ForEach(
                    { 
                        $MinComputeCapability = $_.MinComputeCapability
                        If ($SupportedMinerDevices = $MinerDevices.Where({ [Double]$_.OpenCL.ComputeCapability -ge $MinComputeCapability })) { 

                            $ExcludePools = $_.ExcludePools
                            ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $_.Name -notin $ExcludePools})) { 

                                $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                                If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($_.Algorithm)"

                                    $Arguments = $_.Arguments
                                    $Arguments += " --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User)"
                                    If ($Pool.WorkerName -and $Pool.User -notmatch "\.$($Pool.WorkerName)$") { $Arguments += " --worker $($Pool.WorkerName)" }
                                    $Arguments += " --pass $($Pool.Pass)"

                                    [PSCustomObject]@{ 
                                        API         = "CcMiner"
                                        Arguments   = "$Arguments --cpu-priority $($Config.GPUMinerProcessPriority + 2) --no-watchdog --no-crashreport --retries 1 --retry-pause 1 --api-type ccminer-tcp --api-bind=127.0.0.1:$($MinerAPIPort) --device $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
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
                    }
                )
            }
        }
    )
}