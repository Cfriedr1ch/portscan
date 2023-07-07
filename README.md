# portscan
TCP / UDP Portscanner in Powershell

## Usage
```powershell
# Tests the given TCP/UDP ports in ports.txt File if they are open or closed.
.\portscan.ps1 -tcp -udp -filepath ".\ports.txt"
# Tests the given TCP/UDP ports in range between 80 - 85 (80,81,82,83,84,85) if they are open or closed.
.\portscan.ps1 -tcp -udp -start 80 -end 85
```