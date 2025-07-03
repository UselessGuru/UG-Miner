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
Version:        6.4.35
Version date:   2025/07/03
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -ne "NVIDIA" -or $_.OpenCL.ComputeCapability -ge "5.0" }))) { Return }

$URI = "https://github.com/fireice-uk/xmr-stak/releases/download/2.10.8/xmr-stak-win64-2.10.8.7z"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\xmr-stak.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    @{ Algorithm = "CryptonightBittube2"; MinMemGiB = 4; Type = "AMD"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noCPU --noNVIDIA --amd" }
    @{ Algorithm = "CryptonightGpu";      MinMemGiB = 2; Type = "AMD"; MinerSet = 0; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noCPU --noNVIDIA --amd" }
    @{ Algorithm = "CryptonightLite";     MinMemGiB = 1; Type = "AMD"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noCPU --noNVIDIA --amd" }
    @{ Algorithm = "CryptonightLiteV1";   MinMemGiB = 1; Type = "AMD"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noCPU --noNVIDIA --amd" }
    @{ Algorithm = "CryptonightLiteItbc"; MinMemGiB = 1; Type = "AMD"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noCPU --noNVIDIA --amd" }
    @{ Algorithm = "CryptonightHeavy";    MinMemGiB = 1; Type = "AMD"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noCPU --noNVIDIA --amd" } # XmRig-v6.24.0 is fastest
#   @{ Algorithm = "CryptonightHeavyXhv"; MinMemGiB = 4; Type = "AMD"; MinerSet = 0; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noCPU --noNVIDIA --amd" } # PARSE error: Invalid job length
    @{ Algorithm = "CryptonightMsr";      MinMemGiB = 2; Type = "AMD"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noCPU --noNVIDIA --amd" }
#   @{ Algorithm = "CryptonightR";        MinMemGiB = 2; Type = "AMD"; MinerSet = 3; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noCPU --noNVIDIA --amd" } # ASIC
    @{ Algorithm = "CryptonightDouble";   MinMemGiB = 2; Type = "AMD"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noCPU --noNVIDIA --amd" } # XmRig-v6.24.0 is fastest
    @{ Algorithm = "CryptonightRwz";      MinMemGiB = 2; Type = "AMD"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noCPU --noNVIDIA --amd" }
    @{ Algorithm = "CryptonightV1";       MinMemGiB = 2; Type = "AMD"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noCPU --noNVIDIA --amd" }
    @{ Algorithm = "CryptonightV2";       MinMemGiB = 2; Type = "AMD"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noCPU --noNVIDIA --amd" }
    @{ Algorithm = "CryptonightXtl";      MinMemGiB = 2; Type = "AMD"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noCPU --noNVIDIA --amd" }

#   @{ Algorithm = "CryptonightBittube2"; Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --noAMD --noNVIDIA --cpu" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightGpu";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 20); ExcludePools = @(); Arguments = " --noAMD --noNVIDIA --cpu" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightLite";     Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --noAMD --noNVIDIA --cpu" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightLiteV1";   Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --noAMD --noNVIDIA --cpu" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightLiteItbc"; Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --noAMD --noNVIDIA --cpu" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightHeavy";    Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --noAMD --noNVIDIA --cpu" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightHeavyXhv"; Type = "CPU"; MinerSet = 1; WarmupTimes = @(45, 20); ExcludePools = @(); Arguments = " --noAMD --noNVIDIA --cpu" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightMsr";      Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --noAMD --noNVIDIA --cpu" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightR";        Type = "CPU"; MinerSet = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --noAMD --noNVIDIA --cpu" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightDouble";   Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --noAMD --noNVIDIA --cpu" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightRwz";      Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --noAMD --noNVIDIA --cpu" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightV1";       Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --noAMD --noNVIDIA --cpu" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightV2";       Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --noAMD --noNVIDIA --cpu" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightXtl";      Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --noAMD --noNVIDIA --cpu" } # Not profitable with CPU

    @{ Algorithm = "CryptonightBittube2"; MinMemGiB = 4; Type = "NVIDIA"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    @{ Algorithm = "CryptonightGpu";      MinMemGiB = 2; Type = "NVIDIA"; MinerSet = 1; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    @{ Algorithm = "CryptonightLite";     MinMemGiB = 1; Type = "NVIDIA"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    @{ Algorithm = "CryptonightLiteV1";   MinMemGiB = 1; Type = "NVIDIA"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    @{ Algorithm = "CryptonightLiteItbc"; MinMemGiB = 1; Type = "NVIDIA"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    @{ Algorithm = "CryptonightHeavy";    MinMemGiB = 1; Type = "NVIDIA"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" } # CryptoDredge-v0.27.0 is fastest
#   @{ Algorithm = "CryptonightHeavyXhv"; MinMemGiB = 4; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" } # PARSE error: Invalid job length
    @{ Algorithm = "CryptonightMsr";      MinMemGiB = 2; Type = "NVIDIA"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
#   @{ Algorithm = "CryptonightR";        MinMemGiB = 2; Type = "NVIDIA"; MinerSet = 3; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" } # ASIC
    @{ Algorithm = "CryptonightDouble";   MinMemGiB = 2; Type = "NVIDIA"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" } # XmRig-v6.24.0 is fastest
    @{ Algorithm = "CryptonightRwz";      MinMemGiB = 2; Type = "NVIDIA"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    @{ Algorithm = "CryptonightV1";       MinMemGiB = 2; Type = "NVIDIA"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    @{ Algorithm = "CryptonightV2";       MinMemGiB = 2; Type = "NVIDIA"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    @{ Algorithm = "CryptonightXtl";      MinMemGiB = 2; Type = "NVIDIA"; MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

If ($Algorithms) { 

    $Currency = @{ 
        "CryptonightBittube2" = "cryptonight_bittube2"
        "CryptonightGpu"      = "cryptonight_gpu"
        "CryptonightLite"     = "cryptonight_lite"
        "CryptonightLiteV1"   = "cryptonight_lite_v7"
        "CryptonightLiteItbc" = "cryptonight_lite_v7_xor"
        "CryptonightHeavy"    = "cryptonight_heavy"
        "CryptonightHeavyXhv" = "cryptonight_haven"
        "CryptonightMsr"      = "cryptonight_masari"
        "CryptonightR"        = "cryptonight_r"
        "CryptonightDouble"   = "cryptonight_v8_double"
        "CryptonightRwz"      = "cryptonight_v8_reversewaltz"
        "CryptonightV1"       = "cryptonight_v7"
        "CryptonightXtl"      = "cryptonight_v7_stellite"
        "CryptonightV2"       = "cryptonight_v8"
    }

    $Coins = @("aeon7", "bbscoin", "bittube", "freehaven", "graft", "haven", "intense", "masari", "monero" ,"qrl", "ryo", "stellite", "turtlecoin")

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    $MinMemGiB = $_.MinMemGiB
                    If ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -gt $MinMemGiB })) { 

                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($_.Algorithm)"

                        # $ExcludePools = $_.ExcludePools
                        # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 
                        ForEach ($Pool in $MinerPools[0][$_.Algorithm]) { 

                            # Note: For fine tuning directly edit the config files in the miner binary directory
                            $ConfigFileName = [System.Web.HttpUtility]::UrlEncode("$((@("Config") + @($_.Type) + @(($Model.ForEach({ $Model = $_; "$(@($AvailableMinerDevices.Where({ $_.Model -EQ $Model })).Count)x$Model($((($AvailableMinerDevices | Sort-Object -Property Name).Where({ $_.Model -eq $Model })).Name -join ';'))" }) | Select-Object) -join '-') + @($MinerAPIPort) | Select-Object) -join '-').txt")
                            $MinerThreadsConfigFileName = [System.Web.HttpUtility]::UrlEncode("$((@("ThreadsConfig") + @($_.Type) + @($_.Algorithm) + @(($Model.ForEach({ $Model = $_; "$(@($AvailableMinerDevices.Where({ $_.Model -eq $Model })).Count)x$Model($((($AvailableMinerDevices | Sort-Object -Property Name).Where({ $_.Model -eq $Model })).Name -join ';'))" }) | Select-Object) -join '-') | Select-Object) -join '-').txt")
                            $PlatformThreadsConfigFileName = [System.Web.HttpUtility]::UrlEncode("$((@($_.Type) + @($_.Algorithm) + @((($MinerDevices.Model | Sort-Object -Unique).ForEach({ $Model = $_; "$(@($MinerDevices.Where({ $_.Model -eq $Model })).Count)x$Model($((($MinerDevices | Sort-Object -Property Name).Where({ $_.Model -eq $Model })).Name -join ';'))" }) | Select-Object) -join '-') | Select-Object) -join '-').txt")
                            $PoolFileName = [System.Web.HttpUtility]::UrlEncode("$((@("PoolConf") + @($($_.Algorithm).Name) + @($_.Algorithm) + @($Pool.User) + @($Pool.Pass) | Select-Object) -join '-').txt")

                            $Arguments = [PSCustomObject]@{ 
                                PoolFile = [PSCustomObject]@{ 
                                    FileName = $PoolFileName
                                    Content  = [PSCustomObject]@{ 
                                        pool_list = @(
                                            [PSCustomObject]@{ 
                                                pool_address    = "$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1)"
                                                wallet_address  = $Pool.User
                                                pool_password   = $Pool.Pass
                                                use_nicehash    = $($Pool.Name -eq "NiceHash")
                                                use_tls         = [Boolean]$Pool.PoolPorts[1]
                                                tls_fingerprint = ""
                                                pool_weight     = 1
                                                rig_id          = $Pool.WorkerName
                                            }
                                        )
                                        currency = If ($Coins -icontains $Pool.CoinName) { $Pool.CoinName } Else { $Currency.($_.Algorithm) }
                                    }
                                }
                                ConfigFile = [PSCustomObject]@{ 
                                    FileName = $ConfigFileName
                                    Content  = [PSCustomObject]@{ 
                                        call_timeout    = 10
                                        retry_time      = 10
                                        giveup_limit    = 0
                                        verbose_level   = 99
                                        print_motd      = $true
                                        h_print_time    = 60
                                        aes_override    = $null
                                        use_slow_memory = "warn"
                                        tls_secure_algo = $true
                                        daemon_mode     = $false
                                        flush_stdout    = $false
                                        output_file     = ""
                                        httpd_port      = [UInt16]$MinerAPIPort
                                        http_login      = ""
                                        http_pass       = ""
                                        prefer_ipv4     = $true
                                    }
                                }
                                Arguments = " --poolconf $PoolFileName --config $ConfigFileName$($_.Arguments) $MinerThreadsConfigFileName --noUAC --httpd $MinerAPIPort" -replace ' \s+'
                                Devices  = @($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique)
                                HwDetectArguments = " --poolconf $PoolFileName --config $ConfigFileName$($_.Arguments) $PlatformThreadsConfigFileName --httpd $MinerAPIPort" -replace ' \s+'
                                MinerThreadsConfigFileName = $MinerThreadsConfigFileName
                                Platform = $Platform
                                PlatformThreadsConfigFileName = $PlatformThreadsConfigFileName
                                Threads = 1
                            }

                            If ($AvailableMinerDevices.PlatformId) { $Arguments.ConfigFile.Content | Add-Member "platform_index" (($AvailableMinerDevices | Select-Object PlatformId -Unique).PlatformId) }

                            [PSCustomObject]@{ 
                                API         = "Fireice"
                                Arguments   = $Arguments | ConvertTo-Json -Depth 10 -Compress
                                DeviceNames = $AvailableMinerDevices.Name
                                Fee         = @(0.02) # dev fee
                                MinerSet    = $_.MinerSet
                                MinerUri    = "http://127.0.0.1:$($MinerAPIPort)/h"
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