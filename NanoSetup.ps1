#this NanoSetup script will be executed on startup by SetupComplete.cmd and is capable
#of customizing a Nano Server post deployment to achieve tasks that could not be completed
#in the image creation process.
#this script will demo how to:
#set the IP address on an UP adapter
#Set DNS server
#Disable IPv6 on all adapters
#Disable all unused adapters
#join a domain
#reboot


#region === Edit settings here ===
#declare IP variables
$NetParam = @{
    IPAddress      = '172.16.96.28'
    PrefixLength   = 24 # This means subnet mask = 255.255.255.0
    DefaultGateway = '172.16.96.1'
    AddressFamily  = 'IPv4'
}
$DNSServers = ('172.16.96.5', '172.16.96.6') 
#declare switches 
$DisableIPv6 = $true # Set to $false to skpi disabling IPv6 binding on all network adapters
$DisableUnsuedAdapters = $true # Set to $false to skip disabling all unconnected network adapters
#declare Domain join option
$BlobPath = 'c:\temp\odjblob' # Full path to blob path for domain join (set to '' to skip domain join)
#endregion

#region === DO NOT TOUCH FROM HERE ===

#required for some cmdlets to work properly
cmd /c 'Set LOCALAPPDATA=%USERPROFILE%\AppData\Local'

#get an adapter that is up to apply IP information to
#note this is just for example and grabbing the first up adapter may not be appropriate for your environment
$upIndex = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1 | Select-Object -ExpandProperty ifIndex
$NetParam += @{InterfaceIndex = $upIndex}

#clear any existing IP configuration
Remove-NetIPAddress -InterfaceIndex $upIndex -AddressFamily $NetParam['IPType'] -Confirm:$false

#set specifiec IP address
New-NetIPAddress @NetParam

#set DNS for up adapter
Set-DnsClientServerAddress -InterfaceIndex $upIndex -ServerAddresses $DNSServers

#disable ipv6 on all adapters
if ($DisableIPv6) {
    Get-NetAdapterBinding -ComponentID 'ms_tcpip6' | disable-NetAdapterBinding -ComponentID ms_tcpip6 -PassThru
}

#disable all unused adapters
if ($DisableUnsuedAdapters) {
    Get-NetAdapter | Where-Object { $_.status -eq 'Disconnected' } | Disable-NetAdapter -Confirm:$false
}

#join the domain
if ($BlobPath -ne '') {
    djoin /requestodj /loadfile $BlobPath /windowspath c:\windows /localos
}

#reboot
Restart-Computer
#endregion