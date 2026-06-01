# Run this like
# while($true) {.\netstat-process-mapping.ps1}
# to capture what processes and related executable paths made connections to other remote hosts


Get-Date -Format o | Out-File -Encoding Ascii -append  tcp-connects-established-and-their-processes.txt

# Get-NetTCPConnection -State Established | Select-Object -Property LocalPort,RemoteAddress,RemotePort,State,@{name='ProcessName ';expression={(Get-Process -Id $_.OwningProcess).Path}} | where {$_.RemoteAddress -ne "::1"} | where {$_.RemoteAddress -ne "127.0.0.1"} | Format-Table | Out-File -Encoding Ascii -append tcp-connects-established-and-their-processes.txt

Get-NetTCPConnection -State Established | Select-Object LocalPort,RemoteAddress,RemotePort,State,OwningProcess,@{Name='cmdline';expression={(Get-WmiObject Win32_Process -filter "ProcessId = $($_.OwningProcess)").commandline}} | where {$_.RemoteAddress -ne "::1"} | where {$_.RemoteAddress -ne "127.0.0.1"} | Format-Table | Out-File -Encoding Ascii -append tcp-connects-established-and-their-processes.txt