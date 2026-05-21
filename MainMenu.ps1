$script:apiConfigPath = "C:\Users\Collin\FILES\GAMING\SteamLibrary\steamapps\common\rocketleague\TAGame\Config\DefaultStatsAPI.ini"
$script:dbPath        = Join-Path -Path $PSScriptRoot -ChildPath "test.db"
$script:logFileName   = "rl_tracker_output.log"
$script:logFullPath   = Join-Path -Path $PSScriptRoot -ChildPath $script:logFileName
$script:isFirstTime = $true
if (Test-Path $script:dbPath) { $script:isFirstTime = $true }


#* THIS IS CURRENTLY WORKING FOR RAW LOG DUMPS

#TODO - Move listener to seperate script
#TODO - Delimit json objects from raw dumps
#TODO   - Convert to PSCustomObejcts for dot notation prop access
#TODO   - Verify and insert into SQLite DB (CSV too much overhead)
#TODO - Verify more buffer invalid-char & overflow exceptioms (unlikely -> static/simple api) 

function Show-Menu {
    do {
        #Clear-Host
        Write-Host "RL HotStats Main Menu" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1 - Start Tracker"
        Write-Host "2 - Analyze History"
        Write-Host "3 - Configure Options"
        Write-Host "Q - Exit"
        Write-Host ""
        $choice = Read-Host "Please select an option (1-4)"
    
        switch ($choice) {
            '1' {
                Start-Tracker
            }
            '2' {
    
            }
            '3' {
    
            }
            '4' {
                Write-Host "Exiting RLHotstats. Goodbye!" -ForegroundColor Yellow
            }
            default {
                Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($choice.ToUpper() -ne 'Q')
}

function New-TcpJsonBuffer {
    #*  In-memory queue: TCP chunks go in; complete JSON envelopes are popped out.

    return @{
        Content = [System.Text.StringBuilder]::new()
    }
}

function Add-TcpJsonBuffer {
    param(
        $Buffer,
        [string]$Chunk
    )

    if ([string]::IsNullOrEmpty($Chunk)) { return }

    [void]$Buffer.Content.Append($Chunk)
}

function Find-TcpJsonEnvelopeEnd {
    param(
        [string]$Text,
        [int]$Start
    )

    if ($Start -ge $Text.Length -or $Text[$Start] -ne '{') {
        return -1
    }

    $depth    = 0
    $inString = $false
    $escaped  = $false
    $i        = $Start

    while ($i -lt $Text.Length) {
        $char = $Text[$i]

        if ($inString) {
            if ($escaped) {
                if ($char -eq 'u' -and ($i + 4) -lt $Text.Length) {
                    $i += 4
                }

                $escaped = $false
                $i++
                continue
            }

            if ($char -eq '\') {
                $escaped = $true
                $i++
                continue
            }

            if ($char -eq '"') {
                $inString = $false
            }

            $i++
            continue
        }

        switch ($char) {
            '"' { $inString = $true }
            '{' { $depth++ }
            '}' {
                $depth--

                if ($depth -eq 0) {
                    return $i
                }
            }
        }

        $i++
    }

    return -1
}

function Pop-TcpJsonBufferEnvelopes {
    param($Buffer)

    $envelopes = [System.Collections.Generic.List[string]]::new()
    $text      = $Buffer.Content.ToString()
    $marker    = '{"Event":'
    $cursor    = 0

    while ($true) {
        $start = $text.IndexOf($marker, $cursor)
        if ($start -lt 0) { break }

        $end = Find-TcpJsonEnvelopeEnd -Text $text -Start $start
        if ($end -lt 0) { break }

        $envelopes.Add($text.Substring($start, $end - $start + 1))
        $cursor = $end + 1
    }

    $remainder = if ($cursor -lt $text.Length) { $text.Substring($cursor) } else { '' }

    [void]$Buffer.Content.Clear()
    [void]$Buffer.Content.Append($remainder)

    return $envelopes
}

function ConvertFrom-RlJson {
    param(
        [string]$Json,
        [switch]$Deep,
        [int]$Depth = 64
    )

    if ([string]::IsNullOrWhiteSpace($Json)) { return $null }

    if ($PSVersionTable.PSVersion.Major -ge 7) {
        return ($Json | ConvertFrom-Json -Depth $Depth)
    }

    if ($Deep) {
        #  PS 5.1 has no -Depth; use Script serializer for nested RL payloads
        Add-Type -AssemblyName System.Web.Extensions
        $serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
        $serializer.MaxJsonLength  = [int]::MaxValue
        $serializer.RecursionLimit = 100

        return $serializer.DeserializeObject($Json)
    }

    return ($Json | ConvertFrom-Json)
}

function Start-Tracker {
    $hostIp         = '127.0.0.1'
    $port           = 49123
    $readBufferSize = 2048                                                    #  Syscall chunk size (matches BufferTest.ps1)

    Write-Host "Connecting to ${hostIp}:${port}..." -ForegroundColor Green

    $client     = $null
    $stream     = $null
    $writer     = $null
    $jsonBuffer = New-TcpJsonBuffer
    $encoder    = [System.Text.Encoding]::UTF8

    try {
        $client = [System.Net.Sockets.TcpClient]::new()
        $client.Connect($hostIp, $port)
    }
    catch {
        Write-Host "ERROR: Could not connect to ${hostIp}:${port}. Is Rocket League running?" -ForegroundColor Red
        return
    }

    try {
        $stream     = $client.GetStream()
        $byteBuffer = [byte[]]::new($readBufferSize)
        $writer     = [System.IO.StreamWriter]::new($script:logFullPath, $true, $encoder)
        $writer.AutoFlush = $true                                                #  Flush each line so Ctrl+C does not lose data

        $sessionStart = (Get-Date).ToString("o")
        $writer.WriteLine("`n--- Session started: $sessionStart ---")

        Write-Host "Connected. Logging envelopes to '$($script:logFullPath)'. Press Ctrl+C to stop." -ForegroundColor Green

        while ($client.Connected) {
            #  Block until data arrives (same pattern as BufferTest.ps1)
            $bytesRead = $stream.Read($byteBuffer, 0, $byteBuffer.Length)

            if ($bytesRead -eq 0) {
                Write-Host "Connection closed by server." -ForegroundColor Yellow
                $writer.WriteLine("--- Connection closed by server ---")
                break
            }

            $chunk = $encoder.GetString($byteBuffer, 0, $bytesRead)
            Add-TcpJsonBuffer -Buffer $jsonBuffer -Chunk $chunk

            foreach ($jsonText in (Pop-TcpJsonBufferEnvelopes -Buffer $jsonBuffer)) {
                $timestamp = (Get-Date).ToString("o")
                $writer.WriteLine("[$timestamp] $jsonText")

                $envelope = ConvertFrom-RlJson -Json $jsonText

                if ($envelope.Data -is [string] -and $envelope.Data.Length -gt 0) {
                    $envelope.Data = ConvertFrom-RlJson -Json $envelope.Data -Deep
                }

                Write-Host $envelope.Event -ForegroundColor Yellow
            }
        }
    }
    finally {
        if ($null -ne $writer) {
            $writer.WriteLine("--- Session ended: $((Get-Date).ToString('o')) ---")
            $writer.Close()
        }

        if ($null -ne $stream) { $stream.Close() }
        if ($null -ne $client) { $client.Close() }
        Write-Host "Disconnected. Log saved to '$($script:logFullPath)'." -ForegroundColor Yellow
    }
}


#_ START
Show-Menu