"""
@AUTHOR: Christian Friedrich
@CONTACT: christianfriedrich06@gmail.com
"""

$script:COUNT = 0;
$script:OK = 0;
$script:CLOSED = 0;
$script:TIMEOUTS = 0;
$script:ERRORS = 0;

$VerbosePreference = "Continue";

function testOpenTCPPort {
    param(
        [string]$h = "127.0.0.1",  # host
        [int]$port = 80,
        [int]$timeout_tcp = 1000
    )
    $result = "";
    try {
        $tcpObj = New-Object System.Net.Sockets.TcpClient;
        $connection = $tcpObj.BeginConnect($h, $port, $null, $null);
        $attempt_successfull = $connection.AsyncWaitHandle.WaitOne($timeout_tcp);
        if ($attempt_successfull) {
            $result += "TCP Connection on ${h}:${port} OK";
            $tcpObj.EndConnect($connection);
            $script:OK++;
        }  else {  # async try failed
            $result += "TCP Connection on ${h}:${port} CLOSED";
            $script:CLOSED++;
        }
    }  catch {
        $result += $_.Exception.Message;
        $script:ERRORS++;
    }  finally {
        $script:COUNT++;
        $tcpObj.Close();
    }
    return $result;
}

function testOpenUDPPort {
    param(
        [string]$h = "127.0.0.1",
        [int]$port = 80,
        [int]$timeout_udp = 1000
    )
    $result = "";
    $udpObj = New-Object System.Net.Sockets.UdpClient;
    $udpObj.Client.ReceiveTimeout = $timeout_udp;
    $udpObj.Connect($h, $port);
    $ascii_encoded = New-Object System.Text.ASCIIEncoding;
    $byte_message = $ascii_encoded.GetBytes("Hello $($h) @ $(Get-Date)");
    [void]$udpObj.Send($byte_message, $byte_message.length);
    $host_endpoint = New-Object IPEndpoint([ipaddress]::Any,0);
    try {
        $received_bytes = $udpObj.Receive([ref]$host_endpoint);
        [string]$response = $ascii_encoded.GetString($received_bytes);
        if ($response) {
            $result += "UDP Connection on ${h}:${port} OK";
            $script:OK++;
        }
    }  catch [System.Net.Sockets.SocketException] {
        $error_code = $_.Exception.ErrorCode;
        if ($error_code -eq 10054) {  # Port is closed
            $result += "UDP Connection on ${h}:${port} CLOSED";
            $script:CLOSED++;
        } elseif ($error_code -eq 10060) {  # Port is open but Server responds too slow
            $result += "UDP Connection on ${h}:${port} TIMEOUT";
            $script:TIMEOUTS++;
        } else {
            $result += "Unknown SocketError: ${$error_code} See https://learn.microsoft.com/en-us/dotnet/api/system.net.sockets.socketerror?view=net-5.0 for more information";
            $script:ERRORS++;
        }
    }  catch {
        $result +=  $_.Exception.Message;
        $script:ERRORS++;
    }  finally {
        $script:COUNT++;
        $udpObj.Close();
    }
    return $result;
}

function testOpenRangeFile {
    param (
        [string]$h = "127.0.0.1",  # host
        [string]$filepath = "./ports.txt",
        [bool]$tcp = $true,
        [bool]$udp = $true,
        [int]$timeout = 1000
    )
    $result = "Testing OPEN PORT RANGE on $h with given FILE: $filepath";
    $result += "`r`Target: $h | TCP: $tcp UDP: $udp | TIMEOUT[Msec]: $timeout";
    $result += Get-Date -Format "`r`DATE: dd.MM.yyyy HH:mm:ss";
    $result += "`r`---------------------------------------------------------------------------";
    Write-Verbose "Testing OPEN PORT RANGE on $h with given FILE: $filepath";
    try {
        $fileContent = Get-Content -path $filepath;
        if ($tcp -and $udp) {
            $protocols = "TCP", "UDP";
        } elseif ($tcp) {
            $protocols = "TCP";
        } else {
            $protocols = "UDP";
        }
        if ("TCP" -in $protocols) {
            foreach ($line in $fileContent) {
                $tcpresults = testOpenTCPPort -h $h -port $line -timeout_tcp $timeout
                $result += "`r` ${tcpresults}";
                Write-Verbose ($tcpresults);
            }
        }
        if ("UDP" -in $protocols) {
            foreach ($line in $fileContent) {
                $udpresults = testOpenUDPPort -h $h -port $line -timeout_tcp $timeout
                $result += "`r` ${udpresults}";
                Write-Verbose ($udpresults);
            }
        }
    } catch [System.IO.FileNotFoundException] {
        $fileError = "File not found: $_.Exception.Message"
        $result += "`r` $(fileError)";
        Write-Verbose $fileError;
    } catch {
        $errorMsg = "$_.Exception.Message";
        $result += "`r` ${$errorMsg}";
        Write-Verbose $errorMsg;
    }
    return $result;
}

function testOpenRange {
    param (
        [string]$h = "127.0.0.1",  # host
        [int]$startport = 80,
        [int]$endport = 80,
        [bool]$tcp = $true,
        [bool]$udp = $true,
        [int]$timeout = 1000
    )
    $result = "Testing OPEN PORT RANGE on $h between PORTS $startport AND $endport (inclusive)";
    $result += "`r`Target: $h | TCP: $tcp UDP: $udp | TIMEOUT[Msec]: $timeout";
    $result += Get-Date -Format "`r`DATE: dd.MM.yyyy HH:mm:ss";
    $result += "`r`---------------------------------------------------------------------------";
    Write-Verbose "Testing OPEN PORT RANGE on $h between PORTS $startport AND $endport (inclusive)"
    if ($tcp -and $udp) {
        $protocols = "TCP", "UDP";
    } elseif ($tcp) {
        $protocols = "TCP";
    } else {
        $protocols = "UDP";
    }
    
    foreach ($protocol in $protocols) {
        for ($i = $startport; $i -le $endport; $i++) {
            if ($protocol -eq "TCP") {
                $tcpresults = (testOpenTCPPort -h $h -port $i -timeout_tcp $timeout);
                $result += "`r` ${tcpresults}";
                Write-Verbose ($tcpresults);
            } elseif ($protocol -eq "UDP") {
                $udpresults = testOpenUDPPort -h $h -port $i -timeout_tcp $timeout;
                $result += "`r` ${udpresults}";
                Write-Verbose ($udpresults);
            }
        }
    }
    return $result;
}

function createReportFooter {
    $result = "---------------------------------------------------------------------------";
    $result += Get-Date -Format "`r`FINISH DATE: dd.MM.yyyy HH:mm:ss";
    $result += "`r`FINISH DATE: AMOUNT: ${script:COUNT} | OK: ${script:OK} ";
    $result += "| CLOSED: ${script:CLOSED} | TIMEOUTS: ${script:TIMEOUTS} ";
    $result += "| ERRORS: ${script:ERRORS}"
    return $result;
}

function getParamPosition {
    param (
        [string]$key,
        [string[]]$arr
    )
    if ($key -in $arr) {
        return $arr.IndexOf($key);
    }
    return -1;
}

function Main {
    param (
        [Parameter(Mandatory=$true)]
        [string]$host_ip,
        [switch]$tcp,
        [switch]$udp
    )
    $cleanedHostIP = $host_ip.Replace(".", "-");
    $cleanedDate = Get-Date -Format "dd-MM-yyyy-HH-mm-ss";
    $reportfile = "REPORT${cleanedHostIP}-$($cleanedDate).txt"
    $tcpInArgs = ("-tcp" -in $args);
    $udpInArgs = ("-udp" -in $args);
    $filePos = getParamPosition -key "-filepath" -arr $args;
    $startportPos = getParamPosition -key "-start" -arr $args;
    $endportPos = getParamPosition -key "-end" -arr $args;
    $timeoutInMSecPos = getParamPosition -key "-timeout" -arr $args;
    $timeoutValue = $args[$timeoutInMSecPos + 1];
    $reportText = "";
    if (!$tcpInArgs -and !$udpInArgs) {
        $tcpInArgs = $true;
    }
    if ($timeoutInMSecPos -eq -1) {
        $timeoutValue = 1000;
    }
    if ($filePos -ne -1) {  # in args
        $filepathValue = $args[$filePos + 1];
        $rangeFileOutput = testOpenRangeFile -h $host_ip -filepath $filepathValue -tcp $tcpInArgs -udp $udpInArgs -timeout $timeoutValue;
        $reportText += $rangeFileOutput;
    }  elseif (($startportPos -ne -1) -and ($endportPos -ne -1)) {
        $startportValue = [int]$args[$startportPos + 1];
        $endportValue = [int]$args[$endportPos + 1];
        $rangeFileOutput = testOpenRange -h $host_ip -startport $startportValue -endport $endportValue -tcp $tcpInArgs -udp $udpInArgs -timeout $timeoutValue;
        $reportText += $rangeFileOutput;
    }  else {
        Write-Error "No Params given, please use -filepath [relative/path/to/file] OR -start [startport] -end [endport] as additional params";
    }
    $footerText = createReportFooter;
    $reportText += "`r` ${footerText}";
    $reportText | Out-File -FilePath $reportfile;
}

Main
