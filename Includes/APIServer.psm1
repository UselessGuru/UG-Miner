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
File:           \Includes\APIServer.psm1
Version:        6.3.7
Version date:   2024/10/05
#>

Function Start-APIServer { 

    $APIVersion = "0.5.4.24"

    If ($Variables.APIRunspace.AsyncObject.IsCompleted -or $Config.APIport -ne $Variables.APIRunspace.APIport) { 
        Stop-APIServer
    }

    # Initialize API & Web GUI
    If ($Config.APIport -and -not $Variables.APIRunspace.APIport) { 

        Write-Message -Level Verbose "Initializing API & Web GUI on 'http://localhost:$($Config.APIport)'..."

        $TCPclient = New-Object -TypeName System.Net.Sockets.TCPClient
        $AsyncResult = $TCPclient.BeginConnect("127.0.0.1", $Config.APIport, $null, $null)
        If ($AsyncResult.AsyncWaitHandle.WaitOne(100)) { 
            Write-Message -Level Error "Error initializing API & Web GUI on port $($Config.APIport). Port is in use."
            [Void]$TCPclient.EndConnect($AsyncResult)
            [Void]$TCPclient.Dispose()
        }
        Else { 
            [Void]$TCPclient.Dispose()

            # Start API server
            If ($Config.APILogFile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): API ($APIVersion) started." | Out-File $Config.APILogFile -Force -ErrorAction Ignore }

            # Setup runspace to launch the API server in a separate thread
            $Runspace = [RunspaceFactory]::CreateRunspace()
            $Runspace.ApartmentState = "STA"
            $Runspace.Name = "APIServer"
            $Runspace.ThreadOptions = "ReuseThread"
            $Runspace.Open()

            $Runspace.SessionStateProxy.SetVariable("Config", $Config)
            $Runspace.SessionStateProxy.SetVariable("Stats", $Stats)
            $Runspace.SessionStateProxy.SetVariable("Variables", $Variables)
            [Void]$Runspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)

            $Runspace.SessionStateProxy.SetVariable("APIVersion", $APIVersion)
            $Runspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)

            $PowerShell = [PowerShell]::Create()
            $PowerShell.Runspace = $Runspace
            $Powershell.AddScript(
                { 
                    $ScriptBody = "using module .\Includes\Include.psm1"; $Script = [ScriptBlock]::Create($ScriptBody); . $Script

                    $GCStopWatch = [System.Diagnostics.StopWatch]::New()
                    $GCStopWatch.Start()

                    (Get-Process -Id $PID).PriorityClass = "Normal"

                    # Set the starting directory
                    $BasePath = "$PWD\web"

                    If ($Config.Transcript) { Start-Transcript -Path ".\Debug\APIServer-Transcript_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log" }

                    # List of possible mime types for files
                    $MIMETypes = @{ 
                        ".js"   = "application/x-javascript"
                        ".html" = "text/html"
                        ".htm"  = "text/html"
                        ".json" = "application/json"
                        ".css"  = "text/css"
                        ".txt"  = "text/plain"
                        ".ico"  = "image/x-icon"
                        ".ps1"  = "text/html" # ps1 files get executed, assume their response is html
                    }

                    # Setup the listener
                    $Server = New-Object System.Net.HttpListener
                    $Variables.APIRunspace.APIServer = $Server
                    $Variables.APIRunspace.APIport = $Config.APIport 

                    # Listening on anything other than localhost requires admin privileges
                    $Server.Prefixes.Add("http://localhost:$($Config.APIport)/")
                    $Server.Start()

                    While ($Server.IsListening) { 
                        $Context = $Server.GetContext()
                        $Request = $Context.Request

                        # Determine the requested resource and parse query strings
                        $Path = $Request.Url.LocalPath

                        If ($Request.HttpMethod -eq "GET") { 
                            # Parse any parameters in the URL - $Request.Url.Query looks like "+ ?a=b&c=d&message=Hello%20world"
                            # Decode any url escaped characters in the key and value
                            $Parameters = @{ }
                            ($Request.Url.Query -replace "\?" -split "&").Foreach(
                                { 
                                    $Key, $Value = $_ -split "="
                                    # Decode any url escaped characters in the key and value
                                    $Key = [System.Web.HttpUtility]::UrlDecode($Key)
                                    $Value = [System.Web.HttpUtility]::UrlDecode($Value)
                                    # $Key = [URI]::UnescapeDataString($Key)
                                    # $Value = [URI]::UnescapeDataString($Value)
                                    If ($Key -and $Value) { 
                                        $Parameters.$Key = $Value
                                    }
                                }
                            )
                            If ($Config.APILogFile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): $($Request.Url)" | Out-File $Config.APILogFile -Append -ErrorAction Ignore }

                        }
                        ElseIf ($Request.HttpMethod -eq "POST") { 
                            $Length = $Request.contentlength64
                            $Buffer = New-Object "byte[]" $Length

                            [Void]$Request.inputstream.read($Buffer, 0, $Length)
                            $Body = [System.Text.Encoding]::ascii.getstring($Buffer)

                            If ($Config.APILogFile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): $($Request.Url) POST:$Body" | Out-File $Config.APILogFile -Append -ErrorAction Ignore }

                            $Parameters = @{ }
                            ($Body -split "&").ForEach(
                                { 
                                    $Key, $Value = $_ -split "="
                                    # Decode any url escaped characters in the key and value
                                    $Key = [System.Web.HttpUtility]::UrDecode($Key)
                                    $Value = [System.Web.HttpUtility]::UrlDecode($Value)
                                    If ($Key -and $Value) { 
                                        $Parameters.$Key = $Value
                                    }
                                }
                            )
                            Remove-Variable Body
                        }

                        # Create a new response and the defaults for associated settings
                        $Response = $Context.Response
                        $ContentType = "application/json"
                        $StatusCode = 200
                        $Data = ""

                        # Set the proper content type, status code and data for each resource
                        Switch ($Path) { 
                            "/functions/algorithm/disable" { 
                                # Disable algorithm@pool in poolsconfig.json
                                $PoolNames = @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore).Name
                                $Algorithms = @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore).Algorithm
                                If ($Pools = @($Variables.Pools.Where({ $PoolNames -contains $_.Name -and $Algorithms -contains $_.Algorithm }))) { 
                                    $PoolsConfig = [System.IO.File]::ReadAllLines($Config.PoolsConfigFile) | ConvertFrom-Json
                                    ForEach ($Pool in $Pools) { 
                                        If ($PoolsConfig.($Pool.Name).Algorithm -like "-*") { 
                                            $PoolsConfig.($Pool.Name).Algorithm = @($PoolsConfig.($Pool.Name).Algorithm += "-$($Pool.Algorithm)" | Sort-Object -Unique)
                                            $Pool.Reasons = [System.Collections.Generic.List[String]]@($Pool.Reasons.Add("Algorithm disabled (`-$($Pool.Algorithm)` in $($Pool.Name) pool config)") | Sort-Object -Unique)
                                        }
                                        Else { 
                                            $PoolsConfig.($Pool.Name).Algorithm = @($PoolsConfig.($Pool.Name).Algorithm.Where({ $_ -ne "+$($Pool.Algorithm)" }) | Sort-Object -Unique)
                                            $Pool.Reasons = [System.Collections.Generic.List[String]]@($Pool.Reasons.Add("Algorithm not enabled in $($Pool.Name) pool config") | Sort-Object -Unique)
                                        }
                                        $Pool.Available = $false
                                        $Data += "$($Pool.Algorithm)@$($Pool.Name)"
                                    }
                                    Remove-Variable Pool
                                    $Message = "$($Pools.Count) $(If ($Pools.Count -eq 1) { "pool" } Else { "pools" }) disabled."
                                    Write-Message -Level Verbose "Web GUI: $Message"
                                    $Data = "$($Data -join "`n")`n`n$Message"
                                    $PoolsConfig | Get-SortedObject | ConvertTo-Json -Depth 10 | Out-File -LiteralPath $Variables.PoolsConfigFile -Force
                                }
                                Else { 
                                    $Data = "No matching stats found."
                                }
                                Break
                            }
                            "/functions/algorithm/enable" { 
                                # Enable algorithm@pool in poolsconfig.json
                                $PoolNames = @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore).Name
                                $Algorithms = @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore).Algorithm
                                If ($Pools = @($Variables.Pools.Where({ $PoolNames -contains $_.Name -and $Algorithms -contains $_.Algorithm }))) { 
                                    $PoolsConfig = [System.IO.File]::ReadAllLines($Config.PoolsConfigFile) | ConvertFrom-Json
                                    ForEach ($Pool in $Pools) { 
                                        If ($PoolsConfig.($Pool.Name).Algorithm -like "+*") { 
                                            $PoolsConfig.($Pool.Name).Algorithm = @($PoolsConfig.($Pool.Name).Algorithm += "+$($Pool.Algorithm)" | Sort-Object -Unique)
                                            $Pool.Reasons = [System.Collections.Generic.List[String]]@($Pool.Reasons.Where({ $_ -ne "Algorithm not enabled in $($Pool.Name) pool config" }) | Sort-Object -Unique)
                                        }
                                        Else { 
                                            $PoolsConfig.($Pool.Name).Algorithm = @($PoolsConfig.($Pool.Name).Algorithm.Where({ $_ -ne "-$($Pool.Algorithm)" }) | Sort-Object -Unique)
                                            $Pool.Reasons = [System.Collections.Generic.List[String]]@($Pool.Reasons.Where({ $_ -ne "Algorithm disabled (`-$($Pool.Algorithm)` in $($Pool.Name) pool config)" }) | Sort-Object -Unique)
                                        }
                                        If (-not $Pool.Reasons) { $Pool.Available = $true }
                                        $Data += "$($Pool.Algorithm)@$($Pool.Name)"
                                    }
                                    Remove-Variable Pool
                                    $Message = "$($Pools.Count) $(If ($Pools.Count -eq 1) { "pool" } Else { "pools" }) enabled."
                                    Write-Message -Level Verbose "Web GUI: $Message"
                                    $Data = "$($Data -join "`n")`n`n$Message"
                                    $PoolsConfig | Get-SortedObject | ConvertTo-Json -Depth 10 | Out-File -LiteralPath $Variables.PoolsConfigFile -Force
                                }
                                Else { 
                                    $Data = "No matching stats found."
                                }
                                Break
                            }
                            "/functions/api/stop" { 
                                Write-Message -Level Verbose "API: API stopped!"
                                Return
                            }
                            "/functions/balancedata/remove" { 
                                If ($Parameters.Data) { 
                                    $BalanceDataEntries = $Variables.BalancesData
                                    $Variables.BalancesData = @((Compare-Object $Variables.BalancesData @($Parameters.Data | ConvertFrom-Json -ErrorAction Ignore) -PassThru -Property DateTime, Pool, Currency, Wallet).Where({ $_.SideIndicator -eq "<=" }) | Select-Object -ExcludeProperty SideIndicator)
                                    $Variables.BalancesData | ConvertTo-Json | Out-File ".\Data\BalancesTrackerData.json"
                                    $RemovedEntriesCount = $BalanceDataEntries.Count - $Variables.BalancesData.Count
                                    If ($RemovedEntriesCount -gt 0) { 
                                        $Message = "$RemovedEntriesCount $(If ($RemovedEntriesCount -eq 1) { "balance data entry" } Else { "balance data entries" }) removed."
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data = $Message
                                    }
                                    Else { 
                                        $Data = "No matching entries found."
                                    }
                                    Break
                                }
                            }
                            "/functions/config/device/disable" { 
                                ForEach ($Key in $Parameters.Keys) { 
                                    If ($Values = @(($Parameters.$Key -split ",").Where({ $_ -notin $Config.ExcludeDeviceName }))) { 
                                        Try { 
                                            $ExcludeDeviceName = $Config.ExcludeDeviceName
                                            $Config.ExcludeDeviceName = @((@($Config.ExcludeDeviceName) + $Values) | Sort-Object -Unique)
                                            Write-Config -ConfigFile $Variables.ConfigFile -Config $Config
                                            $Data = "Device configuration changed`n`nOld values:"
                                            $Data += "`nExcludeDeviceName: '[$($ExcludeDeviceName -join ", ")]'"
                                            $Data += "`n`nNew values:"
                                            $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ", ")]'"
                                            $Data += "`n`nConfiguration saved to '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`nIt will become active in next cycle."
                                            ForEach ($DeviceName in $Values) { 
                                                $Variables.Devices.Where({ $_.Name -eq $DeviceName }).ForEach(
                                                    { 
                                                        $_.State = [DeviceState]::Disabled
                                                        If ("Benchmarking", "Running", "WarmingUp" -contains $_.SubStatus) { $_.StatusInfo = "$($_.StatusInfo); will get disabled at end of cycle" }
                                                        Else { 
                                                            $_.StatusInfo = "Disabled (ExcludeDeviceName: '$($_.Name)')"
                                                            $_.Status = "Idle"
                                                        }
                                                    }
                                                )
                                            }
                                            Remove-Variable DeviceName
                                            Write-Message -Level Verbose "Web GUI: Device$(If ($Values.Count -ne 1) { "s" }) '$($Values -join ", ")' disabled. Configuration file '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))' updated."
                                        }
                                        Catch { 
                                            $Data = "Error saving configuration file '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`n`n[ $($_) ]"
                                        }
                                    }
                                    Else { 
                                        $Data = "No configuration change."
                                    }
                                }
                                Remove-Variable Key
                                Break
                            }
                            "/functions/config/device/enable" { 
                                ForEach ($Key in $Parameters.Keys) { 
                                    If ($Values = @(($Parameters.$Key -split ",").Where({ $Config.ExcludeDeviceName -contains $_ }))) { 
                                        Try { 
                                            $ExcludeDeviceName = $Config.ExcludeDeviceName
                                            $Config.ExcludeDeviceName = @($Config.ExcludeDeviceName.Where({ $_ -notin $Values }) | Sort-Object -Unique)
                                            Write-Config -ConfigFile $Variables.ConfigFile -Config $Config
                                            $Variables.FreshConfig = $false
                                            $Data = "Device configuration changed`n`nOld values:"
                                            $Data += "`nExcludeDeviceName: '[$($ExcludeDeviceName -join ", ")]'"
                                            $Data += "`n`nNew values:"
                                            $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ", " )]'"
                                            $Data += "`n`nConfiguration saved to '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`nIt will become active in next cycle."
                                            $Variables.Devices.Where({ $Values -contains $_.Name }).ForEach(
                                                { 
                                                    $_.State = [DeviceState]::Enabled
                                                    If ($_.StatusInfo -like "* {*@*}; will get disabled at end of cycle") { $_.StatusInfo = $_.StatusInfo -replace "; will get enabled at end of cycle" }
                                                    Else { $_.Status = $_.StatusInfo = $_.SubStatus = "Idle" }
                                                }
                                            )
                                            Write-Message -Level Verbose "Web GUI: Device$(If ($Values.Count -ne 1) { "s" }) '$($Values -join ", ")' enabled. Configuration file '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))' updated."
                                        }
                                        Catch { 
                                            $Data = "Error saving configuration file '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`n`n[ $($_) ]."
                                        }
                                    }
                                    Else { 
                                        $Data = "No configuration change."
                                    }
                                }
                                Remove-Variable Key
                                Break
                            }
                            "/functions/config/set" { 
                                Try { 
                                    $TempConfig = ($Key | ConvertFrom-Json -AsHashtable)
                                    Write-Config -ConfigFile $Variables.ConfigFile -Config $TempConfig
                                    Write-Message -Level Verbose "Web GUI: Configuration saved. It will become fully active in the next cycle."
                                    $TempConfig.Keys.ForEach({ $Config.$_ = $TempConfig.$_ })
                                    Remove-Variable TempConfig

                                    $Variables.Devices.Where({ $_.State -ne [DeviceState]::Unsupported }).ForEach(
                                        { 
                                            If ($Config.ExcludeDeviceName -contains $_.Name) { 
                                                $_.State = [DeviceState]::Disabled
                                                If ($_.Status -like "Mining *}") { $_.Status = "$($_.Status); will get disabled at end of cycle" }
                                            }
                                            Else { 
                                                $_.State = [DeviceState]::Enabled
                                                If ($_.Status -like "*; will get disabled at end of cycle") { $_.Status = $_.Status -replace "; will get disabled at end of cycle" }
                                                If ($_.Status -like "Disabled *") { $_.Status = "Idle" }
                                            }
                                        }
                                    )
                                    $Variables.RestartCycle = $true
                                    $Variables.FreshConfig = $false
                                    $Data = "Configuration saved to '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`nIt will become fully active in the next cycle."
                                }
                                Catch { 
                                    $Data = "Error saving configuration file '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`n`n[ $($_) ]."
                                }
                                Break
                            }
                            "/functions/file/edit" { 
                                $Data = Edit-File $Parameters.FileName
                                Break
                            }
                            "/functions/file/showcontent" { 
                                $Data = (Get-Content -Path $Parameters.FileName -Raw)
                                $ContentType = "text/html"
                                Break
                            }
                            "/functions/log/get" { 
                                $Lines = If ([Int]$Parameters.Lines) { [Int]$Parameters.Lines } Else { 100 }
                                $Data = "$((Get-Content -Path $Variables.LogFile -Tail $Lines).ForEach({ "$($_)`n" }))"
                                Break
                            }
                            "/functions/mining/getstatus" { 
                                If ($Variables.FreshConfig) { 
                                    $Data = "FreshConfig" | ConvertTo-Json
                                }
                                Else { 
                                    $Data = $Variables.NewMiningStatus | ConvertTo-Json
                                }
                                Break
                            }
                            "/functions/mining/pause" { 
                                If ($Variables.MiningStatus -ne "Paused") { 
                                    $Variables.NewMiningStatus = "Paused"
                                    $Data = "Mining is being paused...`n$(If ($Variables.BalancesTrackerPollInterval -gt 0) { If ($Variables.BalancesTrackerRunning) { "Balances tracker running." } Else { "Balances tracker starting..." } })"
                                    $Variables.SuspendCycle = $false
                                    $Variables.RestartCycle = $true
                                }
                                Break
                            }
                            "/functions/mining/start" { 
                                If ($Variables.MiningStatus -ne "Running") { 
                                    $Variables.NewMiningStatus = "Running"
                                    $Data = "Mining processes starting...`n$(If ($Variables.BalancesTrackerPollInterval -gt 0) { If ($Variables.BalancesTrackerRunning) { "Balances tracker running." } Else { "Balances tracker starting..." } })"
                                    $Variables.SuspendCycle = $false
                                    $Variables.RestartCycle = $true
                                }
                                Break
                            }
                            "/functions/mining/stop" { 
                                If ($Variables.MiningStatus -ne "Idle") { 
                                    $Variables.NewMiningStatus = "Idle"
                                    $Data = "$($Variables.Branding.ProductLabel) is stopping...`n"
                                    $Variables.SuspendCycle = $false
                                    $Variables.RestartCycle = $true
                                }
                                Break
                            }
                            "/functions/querypoolapi" { 
                                If (-not $Config.PoolsConfig.$($Parameters.Pool).BrainConfig.$($Parameters.Type)) { 
                                    $Data = "No pool configuration data for '/functions/querypoolapi?Pool=$($Parameters.Pool)&Type=$($Parameters.Type)'."
                                }
                                ElseIf (-not ($Data = (Invoke-RestMethod -Uri $Config.PoolsConfig.$($Parameters.Pool).BrainConfig.$($Parameters.Type) -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec 5) | ConvertTo-Json)) { 
                                    $Data = "No data for '/functions/querypoolapi?Pool=$($Parameters.Pool)&Type=$($Parameters.Type)'."
                                }
                                break
                            }
                            "/functions/removeorphanedminerstats" { 
                                If ($StatNames = Remove-ObsoleteMinerStats) { 
                                    $Data = $StatNames | ConvertTo-Json
                                }
                                Else { 
                                    $Data = "No matching stats found."
                                }
                                Break
                            }
                            "/functions/getminerdetail" { 
                                $Miner = $Variables.Miners.Where({ $_.Info -eq $Key })
                                If ($Miner) { 
                                    $Data = $Miner | ConvertTo-Json -Depth 10
                                }
                                Else { 
                                    $Data = "Miner with key '$Key' not found."
                                }
                                Break
                            }
                            "/functions/stat/disable" { 
                                If ($Parameters.Miners) { 
                                    If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info)) { 
                                        $Data = @()
                                        $Miners.Where({ -not $_.Disabled }).ForEach(
                                            { 
                                                $Data += $_.Name
                                                ForEach ($Worker in $_.Workers) { 
                                                    Disable-Stat -Name "$($_.Name)_$($Worker.Pool.Algorithm)_Hashrate"
                                                    $Worker.Hashrate = [Double]::NaN
                                                }
                                                Remove-Variable Worker
                                                $_.Disabled = $true
                                                $_.Reasons += "Disabled by user"
                                                $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -ne "Disabled by user" }) | Sort-Object -Unique)
                                            }
                                        )
                                        $Data = $Data | Sort-Object -Unique
                                        $Message = "$($Data.Count) $(If ($Data.Count -eq 1) { "miner" } Else { "miners" }) disabled."
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data = "$($Data -join "`n")`n`n$Message"
                                    }
                                    Else { 
                                        $Data = "No matching miner stats found."
                                    }
                                    Break
                                }
                            }
                            "/functions/stat/enable" { 
                                If ($Parameters.Miners) { 
                                    If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info)) { 
                                        $Data = @()
                                        $Miners.Where({ $_.Disabled }).ForEach(
                                            { 
                                                $Data += $_.Name
                                                ForEach ($Worker in $_.Workers) { 
                                                    Enable-Stat -Name "$($_.Name)_$($Worker.Pool.Algorithm)_Hashrate"
                                                }
                                                Remove-Variable Worker
                                                $_.Disabled = $false
                                                $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -ne "Disabled by user" }) | Sort-Object -Unique)
                                                If (-not $_.Reasons) { $_.Available = $true }
                                            }
                                        )
                                        $Data = $Data | Sort-Object -Unique
                                        $Message = "$($Data.Count) $(If ($Data.Count -eq 1) { "miner" } Else { "miners" }) enabled."
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data = "$($Data -join "`n")`n`n$Message"
                                    }
                                    Else { 
                                        $Data = "No matching miner stats found."
                                    }
                                    Break
                                }
                            }
                            "/functions/stat/get" { 
                                If ($TempStats = @(If ($null -ne $Parameters.Value) { (Get-Stat).Where({ $_.Name -like "*_$($Parameters.Type)" -and $_.Live -eq $Parameters.Value }) } Else { Get-Stat })) { 
                                    If ($null -ne $Parameters.Value) { 
                                       ($TempStats.Name | Sort-Object).ForEach({ $Data += "$($_ -replace "(_Hashrate|_PowerConsumption)$")`n" })
                                        If ($Parameters.Type -eq "Hashrate") { $Data += "`n$($TempStats.Count) stat file$(If ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)H/s hashrate." }
                                        ElseIf ($Parameters.Type -eq "PowerConsumption") { $Data += "`n$($TempStats.Count) stat file$(If ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)W power consumption." }
                                    }
                                    Else { 
                                        $Data = $TempStats | ConvertTo-Json
                                    }
                                }
                                Else { 
                                    $Data = "No matching stats found."
                                }
                                Break
                            }
                            "/functions/stat/remove" { 
                                If ($Parameters.Pools) { 
                                    If ($Pools = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Pools | Select-Object) @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Algorithm, Currency, Name)) { 
                                        $Data = @()
                                        ($Pools | Sort-Object -Property Name, Algorithm, Currency).ForEach(
                                            { 
                                                $StatName = "$($_.Name)_$($_.Algorithm)$(If ($_.Currency) { "-$($_.Currency)" })"
                                                $Data += $StatName
                                                Remove-Stat -Name "$($StatName)_Profit"
                                                $_.Available = $true
                                                $_.Disabled = $false
                                                $_.Price = $_.Price_Bias = $_.StablePrice = $_.Accuracy = [Double]::Nan
                                                $_.Reasons = [System.Collections.Generic.List[String]]@()
                                            }
                                        )
                                        $Data = $Data | Sort-Object -Unique
                                        $Message = "Reset pool stats for $($Pools.Count) $(If ($Pools.Count -eq 1) { "pool" } Else { "pools" })."
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data = "$($Data -join "`n")`n`n$Message"
                                    }
                                    Else { 
                                        $Data = "No matching pool stats found."
                                    }
                                    Break
                                }
                                ElseIf ($Parameters.Miners -and $Parameters.Type -eq "Hashrate") { 
                                    If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info)) { 
                                        $Data = @()
                                        $Miners.ForEach(
                                            { 
                                                $_.Activated = 0 # To allow 3 attempts
                                                $_.Available = $true
                                                $_.Benchmark = $true
                                                $_.Data = New-Object System.Collections.Generic.List[PSCustomObject]
                                                $_.Disabled = $false
                                                $_.Earning_Accuracy = [Double]::NaN
                                                $Data += $_.Name
                                                ForEach ($Worker in $_.Workers) { 
                                                    Remove-Stat -Name "$($_.Name)_$($Worker.Pool.Algorithm)_Hashrate"
                                                    $Worker.Hashrate = [Double]::NaN
                                                }
                                                Remove-Variable Worker

                                                # Clear power consumption
                                                Remove-Stat -Name "$($_.Name)_PowerConsumption"
                                                $_.PowerConsumption = $_.PowerCost = $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = [Double]::NaN

                                                # Remove watchdog
                                                $Variables.WatchdogTimers = @($Variables.WatchdogTimers | Where-Object MinerName -NE $_.Name)

                                                $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -ne "Disabled by user" }))
                                                $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -ne "0 H/s Stat file" }))
                                                $_.Reasons = [System.Collections.Generic.List[String]] @($_.Reasons.Where({ $_ -notlike "Unreal profit data *" }) | Sort-Object -Unique)
                                                If (-not $_.Reasons) { $_.Available = $true }
                                                If ($_.Status -eq "Disabled") { $_.Status = "Idle" }
                                            }
                                        )
                                        $Data = $Data | Sort-Object -Unique
                                        $Message = "Re-benchmark triggered for $($Data.Count) $(If ($Data.Count -eq 1) { "miner" } Else { "miners" })."
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data = "$($Data -join "`n")`n`n$Message"
                                    }
                                    Else { 
                                        $Data = "No matching hashrate stats found."
                                    }
                                    Break
                                }
                                ElseIf ($Parameters.Miners -and $Parameters.Type -eq "PowerConsumption") { 
                                    If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info)) { 
                                        $Data = @()
                                        $Miners.ForEach(
                                            { 
                                                If ($_.Earning -eq 0) { $_.Available = $true }
                                                If ($Variables.CalculatePowerCost) { 
                                                    $_.MeasurePowerConsumption = $true
                                                    $_.Activated = 0 # To allow 3 attempts
                                                }
                                                $_.PowerConsumption = [Double]::NaN
                                                $StatName = $_.Name
                                                $Data += $StatName
                                                Remove-Stat -Name "$($StatName)_PowerConsumption"
                                                $_.PowerConsumption = $_.PowerCost = $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = [Double]::NaN
                                                If ($_.Status -eq "Disabled") { $_.Status = "Idle" }
                                            }
                                        )
                                        $Data = $Data | Sort-Object -Unique
                                        $Message = "Re-measure power consumption triggered for $($Data.Count) $(If ($Data.Count -eq 1) { "miner" } Else { "miners" })."
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data = "$($Data -join "`n")`n`n$Message"
                                    }
                                    Else { 
                                        $Data = "No matching power consumption stats found."
                                    }
                                    Break
                                }
                                If ($TempStats = @(If ($null -ne $Parameters.Value) { (Get-Stat).Where({ $_.Name -like "*_$($Parameters.Type)" -and $_.Live -eq $Parameters.Value }) } Else { Get-Stat })) { 
                                    $Data = @()
                                    ($TempStats | Sort-Object -Property Name).ForEach(
                                        { 
                                            Remove-Stat -Name $_.Name
                                            $Data += $_.Name -replace "(_Hashrate|_PowerConsumption)$"
                                        }
                                    )
                                    $Data = $Data | Sort-Object -Unique
                                    If ($Parameters.Type -eq "Hashrate") { $Message = "Reset $($TempStats.Count) stat file$(If ($TempStats.Count -ne 1) { "s" })$(If ($null -ne $Parameters.Value) { " with $($Parameters.Value)H/s hashrate" })." }
                                    ElseIf ($Parameters.Type -eq "PowerConsumption") { $Message = "Reset $($TempStats.Count) stat file$(If ($TempStats.Count -ne 1) { "s" })$(If ($null -ne $Parameters.Value) { " with $($Parameters.Value)W power consumption" })." }
                                    ElseIf ($Parameters.Type -eq "Profit") { $Message = "Reset $($TempStats.Count) pool stat file$(If ($TempStats.Count -ne 1) { "s" })." }
                                    Write-Message -Level Info "Web GUI: $Message"
                                    $Data = "$($Data -join "`n")`n`n$Message"
                                }
                                Else { 
                                    $Data = "No matching stats found."
                                }
                                Break
                            }
                            "/functions/stat/set" { 
                                If ($Parameters.Miners -and $Parameters.Type -eq "Hashrate" -and $null -ne $Parameters.Value) { 
                                    $Data = @()
                                    If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info)) { 
                                        $Miners.ForEach(
                                            { 
                                                If ($Parameters.Value -le 0 -and $Parameters.Type -eq "Hashrate") { $_.Available = $false; $_.Disabled = $true }
                                                $Data += $_.Name
                                                ForEach ($Algorithm in $_.Algorithms) { 
                                                    $StatName = "$($_.Name)_$($Algorithm)_$($Parameters.Type)"
                                                    If ($Parameters.Value -eq 0) {
                                                        # Miner failed
                                                        Remove-Stat -Name $StatName
                                                        Set-Stat -Name $StatName -Value $Parameters.Value -FaultDetection $false | Out-Null
                                                        $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = $_.Earning_Accuracy = [Double]::NaN
                                                        $_.Available = $false
                                                        $_.Disabled = $false
                                                        If ($_.Reasons -notcontains "0 H/s Stat file") { $_.Reasons.Add("0 H/s Stat file") }
                                                        $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -notlike "Disabled by user" }) | Sort-Object -Unique)
                                                        $_.Status = [MinerStatus]::Failed
                                                    }
                                                }
                                                Remove-Variable Algorithm
                                            }
                                        )
                                        $Data = $Data | Sort-Object -Unique
                                        $Message = "$(If ($Data.Count -eq 1) { "The miner is" } Else { "$($Data.Count) miners are" }) $(If ($Parameters.Value -eq 0) { "marked as failed" } ElseIf ($Parameters.Value -eq -1) { "disabled" } Else { "set to value $($Parameters.Value)" })." 
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data = "$($Data -join "`n")`n`n$Message" 
                                    }
                                    Else { 
                                        $Data = "No matching miners found."
                                    }
                                    Break
                                }
                            }
                            "/functions/switchinglog/clear" { 
                                Get-ChildItem -Path ".\Logs\switchinglog.csv" -File | Remove-Item -Force
                                $Data = "Switching log '.\Logs\switchinglog.csv' cleared."
                                Write-Message -Level Verbose "Web GUI: $Data"
                                Break
                            }
                            "/functions/variables/get" { 
                                If ($Key) { 
                                    $Data = $Variables.($Key -replace "\\|/", "." -split "\."[-1]) | Get-SortedObject | ConvertTo-Json -Depth 10
                                }
                                Else { 
                                    $Data = $Variables.psBase.Keys | Sort-Object | ConvertTo-Json -Depth 1
                                }
                                Break
                            }
                            "/functions/watchdogtimers/remove" { 
                                $Data = @()
                                ForEach ($Miner in @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore)) { 
                                    # Update miner
                                    $Variables.Miners.Where({ $_.Name -eq $Miner.Name -and $_.Reasons -like "Miner suspended by watchdog *" }).ForEach(
                                        { 
                                            $Data += "$($_.Name)"
                                            $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -notlike "Miner suspended by watchdog *" }) | Sort-Object -Unique)
                                            If (-not $_.Reasons) { $_.Available = $true }
                                        }
                                    )

                                    # Remove Watchdog timers
                                    $Variables.WatchdogTimers = @($Variables.WatchdogTimers.Where({ $_.MinerName -ne $Miner.Name }))
                                }
                                Remove-Variable Miner

                                ForEach ($Pool in @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore)) { 
                                    # Update pool
                                    $Variables.Pools.Where({ $_.Name -eq $Pool.Name -and $_.Algorithm -eq $Pool.Algorithm -and $_.Reasons -like "Pool suspended by watchdog *" }).ForEach(
                                        { 
                                            $Data += "$($_.Key) ($($_.Region))"
                                            $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -notlike "Pool suspended by watchdog *" }) | Sort-Object -Unique)
                                            If (-not $_.Reasons) { $_.Available = $true }
                                        }
                                    )

                                    # Remove Watchdog timers
                                    $Variables.WatchdogTimers = @($Variables.WatchdogTimers.Where({ $_.PoolName -ne $Pool.Name -or $_.Algorithm -ne $Pool.Algorithm }))
                                }
                                Remove-Variable Pool
                                If ($Data) { 
                                    $Data = $Data | Sort-Object -Unique
                                    $Message = "$($Data.Count) watchdog $(If ($Data.Count -eq 1) { "timer" } Else { "timers" }) removed."
                                    Write-Message -Level Verbose "Web GUI: $Message"
                                    $Data = "$($Data -join "`n")`n`n$Message"
                                }
                                Else { 
                                    $Data = "No matching watchdog timer found."
                                }
                                Break
                            }
                            "/functions/watchdogtimers/reset" { 
                                $Variables.WatchDogTimers = @()
                                $Variables.Miners.ForEach(
                                    { 
                                        $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -notlike "Miner suspended by watchdog *" }) | Sort-Object -Unique)
                                        $_.Where({ -not $_.Reasons }).ForEach({ $_.Available = $true })
                                    }
                                )
                                $Variables.Pools.ForEach(
                                    { 
                                        $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -notlike "*Pool suspended by watchdog" }) | Sort-Object -Unique)
                                        $_.Where({ -not $_.Reasons }).ForEach({ $_.Available = $true })
                                    }
                                )
                                Write-Message -Level Verbose "Web GUI: All watchdog timers reset."
                                $Data = "Watchdog timers will be recreated in next cycle."
                                Break
                            }
                            "/algorithms" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Algorithms | Select-Object)
                                Break
                            }
                            "/algorithms/lastused" { 
                                $Data = ConvertTo-Json -Depth 10 $Variables.AlgorithmsLastUsed
                                Break
                            }
                            "/allcurrencies" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.AllCurrencies)
                                break
                            }
                            "/apiversion" { 
                                $Data = $APIVersion
                                Break
                            }
                            "/balances" { 
                                $Data = ConvertTo-Json -Depth 10 ($Variables.Balances | Sort-Object -Property DateTime -Bottom 10000 | Select-Object)
                                Break
                            }
                            "/balancedata" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.BalancesData | Sort-Object -Property DateTime -Descending)
                                Break
                            }
                            "/btc" { 
                                $Data = $Variables.Rates.BTC.($Config.FIATcurrency)
                                Break
                            }
                            "/balancescurrencies" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.BalancesCurrencies)
                                break
                            }
                            "/braindata" { 
                                $Data = ConvertTo-Json -Depth 2 ($Variables.BrainData | Get-SortedObject)
                                Break
                            }
                            "/coinnames" { 
                                $Data = [System.IO.File]::ReadAllLines(".\Data\CoinNames.json")
                                Break
                            }
                            "/config" { 
                                $Data = ConvertTo-Json -Depth 10 ([System.IO.File]::ReadAllLines($Variables.ConfigFile) | ConvertFrom-Json -Depth 10 | Get-SortedObject)
                                If (-not ($Data | ConvertFrom-Json).ConfigFileVersion) { 
                                    $Data = ConvertTo-Json -Depth 10 ($Config | Select-Object -ExcludeProperty PoolsConfig)
                                }
                                Break
                            }
                            "/configfile" { 
                                $Data = $Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\")
                                break
                            }
                            "/configrunning" { 
                                $Data = ConvertTo-Json -Depth 10 ($Config | Get-SortedObject)
                                Break
                            }
                            "/cpufeatures" { 
                                $Data = ConvertTo-Json $Variables.CPUfeatures
                                Break
                            }
                            "/currency" { 
                                $Data = $Config.FIATcurrency
                                Break
                            }
                            "/currencyalgorithm" { 
                                $Data = [System.IO.File]::ReadAllLines("$PWD\Data\CurrencyAlgorithm.json")
                                Break
                            }
                            "/dagdata" { 
                                $Data = ConvertTo-Json -Depth 10 ($Variables.DAGdata | Select-Object)
                                Break
                            }
                            "/devices" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Devices | Sort-Object -Property Name)
                                Break
                            }
                            "/devices/enabled" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Devices.Where({ $_.State -eq "Enabled" }) | Sort-Object -Property Name)
                                Break
                            }
                            "/devices/disabled" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Devices.Where({ $_.State -eq "Disabled" }) | Sort-Object -Property Name)
                                Break
                            }
                            "/devices/unsupported" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Devices.Where({ $_.State -eq "Unsupported" }) | Sort-Object -Property Name)
                                Break
                            }
                            "/donationdata" { 
                                $Data = ConvertTo-Json $Variables.DonationData
                                Break
                            }
                            "/donationlog" { 
                                $Data = ConvertTo-Json $Variables.DonationLog
                                Break
                            }
                            "/driverversion" { 
                                $Data = ConvertTo-Json -Depth 10 ($Variables.DriverVersion | Select-Object)
                                Break
                            }
                            "/earningschartdata" { 
                                $Data = ConvertTo-Json $Variables.EarningsChartData
                                Break
                            }
                            "/equihashcoinpers" { 
                                $Data = [System.IO.File]::ReadAllLines("$PWD\Data\EquihashCoinPers.json")
                                Break
                            }
                            "/extracurrencies" { 
                                $Data = ConvertTo-Json -Depth 10 $Config.ExtraCurrencies
                                break
                            }
                            "/fiatcurrencies" { 
                                $Data = ConvertTo-Json -Depth 10 ($Variables.FIATcurrencies | Select-Object)
                                Break
                            }
                            "/miners" { 
                                $Data = ConvertTo-Json -Depth 4 -Compress @(($Variables.Miners | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp).ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty WorkersRunning)
                                Break
                            }
                            "/miners/available" { 
                                $Bias = If ($Variables.CalculatePowerCost -and -not $Config.IgnorePowerCost) { "Profit_Bias" } Else { "Earning_Bias" }
                                $Data = ConvertTo-Json -Depth 4 @($Variables.Miners.Where({ $_.Available }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp | Sort-Object DeviceNames, @{ Expression = $Bias; Descending = $true })
                                Remove-Variable Bias
                                Break
                            }
                            "/miners/bestperdevice" { 
                                $Data = ConvertTo-Json -Depth 4 @(($Variables.MinersBestPerDevice | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp).ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty WorkersRunning | Sort-Object -Property DeviceName)
                                Break
                            }
                            "/miners/best" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.MinersBest | Sort-Object DeviceNames | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, StatEnd, StatStart, SideIndicator, ValidDataSampleTimestamp)
                                Break
                            }
                            "/miners/disabled" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.Miners.Where({ $_.Status -eq [MinerStatus]::Disabled }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp | Sort-Object -Property { $_.DeviceNames }, EndTime)
                                Break
                            }
                            "/miners/failed" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.Miners.Where({ $_.Status -eq [MinerStatus]::Failed }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp | Sort-Object -Property { $_.DeviceNames }, EndTime)
                                Break
                            }
                            "/miners/launched" { 
                                $Data = ConvertTo-Json -Depth 4 @(($Variables.MinersBest | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp).ForEach({ $_.Workers = $_.WorkersRunning; $_ }) | Select-Object -ExcludeProperty WorkersRunning)
                                Break
                            }
                            "/miners/missingbinary" { 
                                $Data = ConvertTo-Json -Depth 4 @(($Variables.MinersMissingBinary | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp) | Select-Object -ExcludeProperty WorkersRunning)
                                Break
                            }
                            "/miners/missingfirewallrule" { 
                                $Data = ConvertTo-Json -Depth 4 @(($Variables.MinersMissingFirewallRule | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp) | Select-Object -ExcludeProperty WorkersRunning)
                                Break
                            }
                            "/miners/missingprerequisite" { 
                                $Data = ConvertTo-Json -Depth 4 @(($Variables.MinersMissingPrerequisite | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp) | Select-Object -ExcludeProperty WorkersRunning)
                                Break
                            }
                            "/miners/optimal" { 
                                $Bias = If ($Variables.CalculatePowerCost -and -not $Config.IgnorePowerCost) { "Profit_Bias" } Else { "Earning_Bias" }
                                $Data = ConvertTo-Json -Depth 4 @($Variables.MinersOptimal | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp)
                                Remove-Variable Bias
                                Break
                            }
                            "/miners/running" { 
                                $Data = ConvertTo-Json -Depth 4 @(($Variables.Miners.Where({ $_.Status -eq [MinerStatus]::Running }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp).ForEach({ $_.Workers = $_.WorkersRunning; $_ }) | Select-Object -ExcludeProperty WorkersRunning)
                                Break
                            }
                            "/miners/unavailable" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.Miners.Where({ $_.Available -ne $true }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp | Sort-Object -Property { $_.DeviceNames }, Name, Algorithm)
                                Break
                            }
                            "/miningpowercost" { 
                                $Data = $Variables.MiningPowerCost
                                Break
                            }
                            "/miningearning" { 
                                $Data = $Variables.MiningEarning
                                Break
                            }
                            "/miningprofit" { 
                                $Data = $Variables.MiningProfit
                                Break
                            }
                            "/poolname" { 
                                $Data = ConvertTo-Json -Depth 10 $Config.PoolName
                                break
                            }
                            "/pooldata" { 
                                $Data = ConvertTo-Json -Depth 10 $Variables.PoolData
                                break
                            }
                            "/poolsconfig" { 
                                $Data = ConvertTo-Json -Depth 10 ($Config.PoolsConfig | Select-Object)
                                Break
                            }
                            "/poolsconfigfile" { 
                                $Data = $Config.PoolsConfigFile.Replace("$(Convert-Path ".\")\", ".\")
                                Break
                            }
                            "/pools" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Pools | Sort-Object -Property Algorithm, Name, Region)
                                Break
                            }
                            "/pools/added" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsAdded | Sort-Object -Property Algorithm, Name, Region)
                                Break
                            }
                            "/pools/available" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Pools.Where({ $_.Available }) | Sort-Object -Property Algorithm, Name, Region)
                                Break
                            }
                            "/pools/best" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsBest | Sort-Object -Property Algorithm, Name, Region)
                                Break
                            }
                            "/pools/expired" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsExpired | Sort-Object -Property Algorithm, Name, Region)
                                Break
                            }
                            "/pools/new" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsNew | Sort-Object -Property Algorithm, Name, Region)
                                Break
                            }
                            "/pools/minersprimaryalgorithm" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.MinerPools[0] | Select-Object)
                                Break
                            }
                            "/pools/minerssecondaryalgorithm" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.MinerPools[1] | Select-Object)
                                Break
                            }
                            "/pools/lastearnings" { 
                                $Data = ConvertTo-Json -Depth 10 $Variables.PoolsLastEarnings
                                Break
                            }
                            "/pools/lastused" { 
                                $Data = ConvertTo-Json -Depth 10 $Variables.PoolsLastUsed
                                Break
                            }
                            "/pools/unavailable" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Pools.Where({ -not $_.Available }) | Sort-Object -Property Algorithm, Name, Region)
                                Break
                            }
                            "/pools/updated" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsUpdated | Sort-Object -Property Algorithm, Name, Region)
                                Break
                            }
                            "/poolreasons" { 
                                $Data = ConvertTo-Json -Depth 10 ($Variables.Pools.Where({ -not $_.Available }).Reasons | Sort-Object -Unique)
                                Break
                            }
                            "/poolvariants" { 
                                $Data = ConvertTo-Json -Depth 10 $Variables.PoolVariants
                                break
                            }
                            "/rates" { 
                                $Data = ConvertTo-Json -Depth 10 ($Variables.Rates | Select-Object)
                                Break
                            }
                            "/refreshtimestamp" { 
                                $Data = $Variables.RefreshTimestamp | ConvertTo-Json
                                break
                            }
                            "/regions" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Regions[0] | Sort-Object)
                                Break
                            }
                            "/regionsdata" { 
                                $Data = ConvertTo-Json -Depth 10 $Variables.Regions
                                Break
                            }
                            "/stats" { 
                                $Data = ConvertTo-Json -Depth 10 ($Stats | Select-Object)
                                Break
                            }
                            "/summarytext" { 
                                $Data = ConvertTo-Json -Depth 10 @((($Variables.Summary -replace " / ", "/" -replace "&ensp;", " " -replace "   ", "  ") -split "<br>").trim())
                                Break
                            }
                            "/summary" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Summary | Select-Object)
                                Break
                            }
                            "/switchinglog" { 
                                $Data = ConvertTo-Json -Depth 10 @([System.IO.File]::ReadAllLines("$PWD\Logs\switchinglog.csv") | ConvertFrom-Csv | Select-Object -Last 1000 | Sort-Object -Property DateTime -Descending)
                                Break
                            }
                            "/unprofitablealgorithms" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.UnprofitableAlgorithms | Select-Object)
                                Break
                            }
                            "/version" { 
                                $Data = ConvertTo-Json @("$($Variables.Branding.ProductLabel) Version: $($Variables.Branding.Version)", "API Version: $($Variables.APIVersion)", "PWSH Version: $($PSVersionTable.PSVersion.ToString())")
                                Break
                            }
                            "/watchdogtimers" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.WatchdogTimers | Select-Object)
                                Break
                            }
                            "/wallets" { 
                                $Data = ConvertTo-Json -Depth 10 ($Config.Wallets | Select-Object)
                                Break
                            }
                            "/watchdogexpiration" { 
                                $Data = $Variables.WatchdogReset
                                Break
                            }
                            "/workers" { 
                                If ($Config.ShowWorkerStatus -and $Config.MonitoringUser -and $Config.MonitoringServer -and $Variables.WorkersLastUpdated -lt [DateTime]::Now.AddSeconds(-30)) { 
                                    Read-MonitoringData
                                }
                                $Workers = [System.Collections.ArrayList]@(
                                    $Variables.Workers | Select-Object @(
                                        @{ Name = "Algorithm"; Expression = { ($_.data.ForEach({ $_.Algorithm -split "," -join " & " })) -join "<br>" } },
                                        @{ Name = "Benchmark Hashrate"; Expression = { ($_.data.ForEach({ ($_.EstimatedSpeed.ForEach({ If ([Double]$_ -gt 0) { "$($_ | ConvertTo-Hash)/s" -replace "\s+", " " } Else { "-" } })) -join " & " })) -join "<br>" } },
                                        @{ Name = "Currency"; Expression = { $_.Data.Currency | Select-Object -Unique } },
                                        @{ Name = "EstimatedEarning"; Expression = { [Decimal](($_.Data.Earning | Measure-Object -Sum).Sum * $Variables.Rates.BTC.($_.Data.Currency | Select-Object -Unique)) } },
                                        @{ Name = "EstimatedProfit"; Expression = { [Decimal]($_.Profit * $Variables.Rates.BTC.($_.Data.Currency | Select-Object -Unique)) } },
                                        @{ Name = "LastSeen"; Expression = { "$($_.date)" } },
                                        @{ Name = "Live Hashrate"; Expression = { ($_.data.ForEach({ ($_.CurrentSpeed.ForEach({ If ([Double]$_ -gt 0) { "$($_ | ConvertTo-Hash)/s" -replace "\s+", " " } Else { "-" } })) -join " & " })) -join "<br>" } },
                                        @{ Name = "Miner"; Expression = { $_.data.name -join "<br>" } },
                                        @{ Name = "Pool"; Expression = { ($_.data.ForEach({ (($_.Pool -split ",").ForEach({ $_ -replace "Internal$", " (Internal)" -replace "External", " (External)" })) -join " & " })) -join "<br>" } },
                                        @{ Name = "Status"; Expression = { $_.status } },
                                        @{ Name = "Version"; Expression = { $_.version } },
                                        @{ Name = "Worker"; Expression = { $_.worker } }
                                    ) | Sort-Object -Property "Worker"
                                )
                                $Data = ConvertTo-Json @($Workers | Select-Object) -Depth 4
                                Break
                            }
                            Default { 
                                # Set index page
                                If ($Path -eq "/") { $Path = "/index.html" }

                                # Check if there is a file with the requested path
                                $Filename = "$BasePath$Path"
                                If (Test-Path -LiteralPath $Filename -PathType Leaf) { 
                                    # If the file is a PowerShell script, execute it and return the output. A $Parameters parameter is sent built from the query string
                                    # Otherwise, just return the contents of the file
                                    $File = Get-ChildItem $Filename -File

                                    If ($File.Extension -eq ".ps1") { 
                                        $Data = & $File.FullName -Parameters $Parameters
                                    }
                                    Else { 
                                        $Data = Get-Content $Filename -Raw

                                        # Process server side includes for html files
                                        # Includes are in the traditional '<!-- #include file="/path/filename.html" -->' format used by many web servers
                                        If ($File.Extension -eq ".html") { 
                                            $IncludeRegex = [regex]'<!-- *#include *file="(.*)" *-->'
                                            $IncludeRegex.Matches($Data).Foreach(
                                                { 
                                                    $IncludeFile = $BasePath + "/" + $_.Groups[1].Value
                                                    If (Test-Path -LiteralPath $IncludeFile -PathType Leaf) { 
                                                        $IncludeData = Get-Content $IncludeFile -Raw
                                                        $Data = $Data -replace $_.Value, $IncludeData
                                                    }
                                                }
                                            )
                                        }
                                    }

                                    # Set content type based on file extension
                                    If ($MIMETypes.ContainsKey($File.Extension)) { 
                                        $ContentType = $MIMETypes[$File.Extension]
                                    }
                                    Else { 
                                        # If it's an unrecognized file type, prompt for download
                                        $ContentType = "application/octet-stream"
                                    }
                                }
                                Else { 
                                    $StatusCode = 404
                                    $ContentType = "text/html"
                                    $Data = "URI '$Path' is not a valid resource."
                                }
                            }
                        }

                        # If $Data is null, the API will just return whatever data was in the previous request. Instead, show an error
                        # This happens if the script just started and hasn't filled all the properties in yet.
                        If ($null -eq $Data) { 
                            $Data = @{ "Error" = "API data not available" } | ConvertTo-Json
                        }

                        # Send the response
                        $Response.Headers.Add("Content-Type", $ContentType)
                        $Response.StatusCode = $StatusCode
                        $ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes($Data)
                        $Response.ContentLength64 = $ResponseBuffer.Length
                        # If ($Config.APILogFile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Response: $Data" | Out-File $Config.APILogFile -Append -ErrorAction Ignore }
                        $Response.OutputStream.Write($ResponseBuffer, 0, $ResponseBuffer.Length)
                        $Response.Close()

                        If ($GCStopWatch.Elapsed.TotalSeconds -gt 120) { 
                            [System.GC]::Collect()
                            $GCStopWatch.Restart()
                        }
                    }
                    # Only gets here if something is wrong and the server couldn't start or stops listening
                    $Server.Stop()
                    $Server.Close()
                    $Server.Dispose()
                }
            ) # End of $APIServer

            $Variables.APIRunspace = @{ }
            $Variables.APIRunspace.AsyncObject = $Powershell.BeginInvoke()
            $Variables.APIRunspace.PowerShell  = $PowerShell
            $Variables.APIRunspace.StartTime   = [DateTime]::Now.ToUniversalTime()

            # Wait for API to get ready
            $RetryCount = 3
            While (-not ($Variables.APIVersion) -and $RetryCount -gt 0) { 
                Try { 
                    If ($Variables.APIVersion = (Invoke-RestMethod "http://localhost:$($Variables.APIRunspace.APIport)/apiversion" -TimeoutSec 1 -ErrorAction Stop)) { 
                        Write-Message -Level Info "Web GUI and API (version $($Variables.APIVersion)) running on http://localhost:$($Variables.APIRunspace.APIport)."
                        # Start Web GUI (show configuration edit if no existing config)
                        If ($Config.WebGUI) { Start-Process "http://localhost:$($Variables.APIRunspace.APIport)/$(If ($Variables.FreshConfig) { "configedit.html" })" }
                        Break
                    }
                }
                Catch { }
                $RetryCount--
                Start-Sleep -Seconds 1
            }
            If (-not $Variables.APIVersion) { Write-Message -Level Error "Error initializing API & Web GUI on port $($Config.APIport)." }
        }
    }
}

Function Stop-APIServer { 
    If ($Variables.APIRunspace) { 
        Write-Message -Level Verbose "Stopping API & Web GUI on port $($Config.APIport)."
        If ($Variables.APIRunspace.APIServer) { 
            If ($Variables.APIRunspace.APIServer.IsListening) { $Variables.APIRunspace.APIServer.Stop() }
            $Variables.APIRunspace.APIServer.Close()
        }
        If ($Variables.APIRunspace.APIport) { $Variables.APIRunspace.Remove("APIport") }
        $Variables.APIRunspace.PowerShell.Stop() | Out-Null
        If (-not $Variables.APIRunspace.AsyncObject.IsCompleted) { $Variables.APIRunspace.PowerShell.EndInvoke($Variables.APIRunspace.AsyncObject) | Out-Null }
        $Variables.APIRunspace.PowerShell.Runspace.Close() | Out-Null
        $Variables.APIRunspace.PowerShell.Dispose() | Out-Null
        $Variables.Remove("APIRunspace")
        $Variables.Remove("APIVersion")

        $Error.Clear()
        [System.GC]::Collect()
    }
}
