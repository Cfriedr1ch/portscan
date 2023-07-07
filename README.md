# portscan
TCP / UDP Portscanner in Powershell

## Description
The Port Scanner Scans for Open TCP AND/OR UDP Ports in a given range or with a given file with ports in each line.

## Input-File
seperate the Ports with newlines
e.g ports.txt:

80
21
22
9999

## Usage
Use one of the following commands in Powershell Command line
```powershell
# Tests the given TCP/UDP ports in ports.txt File if they are open or closed.
.\portscan.ps1 -tcp -udp -filepath ".\ports.txt"

# Tests the given TCP/UDP ports in range between 80 - 85 (80,81,82,83,84,85) if they are open or closed.
.\portscan.ps1 -tcp -udp -start 80 -end 85
```