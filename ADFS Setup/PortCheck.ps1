$adfsbox = "0.0.0.0" \\IP for internal ADFS node goes here
$adfsProxy="0.0.0.0" \\IP for Proxy (in your DMZ) goes here
$ports = "49443","443","80","5985","5986"

foreach ($port in $ports)
{
     write-host "Checking $port"
    Test-NetConnection -Port $port -ComputerName $adfsbox
}

\\Output should look like:
\\
\\
\\ComputerName           : [ADFS NODE IP]
\\RemoteAddress          : [ADFS NODE IP]
\\RemotePort             : 49443
\\InterfaceAlias         : Ethernet0
\\SourceAddress          : [PROXY IP]
\\PingSucceeded          : True
\\PingReplyDetails (RTT) : 0 ms
\\TcpTestSucceeded       : True

\\ComputerName     : [ADFS NODE IP]
\\RemoteAddress    : [ADFS NODE IP]
\\RemotePort       : 443
\\InterfaceAlias   : Ethernet0
\\SourceAddress    : [PROXY IP]
\\TcpTestSucceeded : True

\\ComputerName           : [ADFS NODE IP]
\\RemoteAddress          : [ADFS NODE IP]
\\RemotePort             : 80
\\InterfaceAlias         : Ethernet0
\\SourceAddress          : [PROXY IP]
\\PingSucceeded          : True
\\PingReplyDetails (RTT) : 0 ms
\\TcpTestSucceeded       : True

\\ComputerName           : [ADFS NODE IP]
\\RemoteAddress          : [ADFS NODE IP]
\\RemotePort             : 5985
\\InterfaceAlias         : Ethernet0
\\SourceAddress          : [PROXY IP]
\\PingSucceeded          : True
\\PingReplyDetails (RTT) : 0 ms
\\TcpTestSucceeded       : True

\\ComputerName           : [ADFS NODE IP]
\\RemoteAddress          : [ADFS NODE IP]
\\RemotePort             : 5986
\\InterfaceAlias         : Ethernet0
\\SourceAddress          : [PROXY IP]
\\PingSucceeded          : True
\\PingReplyDetails (RTT) : 0 ms
\\TcpTestSucceeded       : True

