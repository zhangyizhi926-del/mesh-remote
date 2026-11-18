#requires -Version 5.1
#requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$ProgramPath,

    [Parameter(Mandatory)]
    [System.Net.IPAddress]$HostMeshIP,

    [Parameter(Mandatory)]
    [string]$MeshSubnet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$program = Get-Item -LiteralPath $ProgramPath
if ($program.PSIsContainer -or $program.Name -ine "sunshine.exe") {
    throw "ProgramPath must identify the installed Apollo or Sunshine sunshine.exe."
}

if ($MeshSubnet -notmatch '^(?<Network>\d{1,3}(\.\d{1,3}){3})/(?<Prefix>[1-9]|[12][0-9]|3[0-2])$') {
    throw "MeshSubnet must be an IPv4 CIDR."
}
$network = [System.Net.IPAddress]::Parse($Matches.Network)
$prefix = [int]$Matches.Prefix
if ($HostMeshIP.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
    throw "HostMeshIP must be an IPv4 address."
}
$networkBytes = $network.GetAddressBytes()
$hostBytes = $HostMeshIP.GetAddressBytes()
for ($byte = 0; $byte -lt 4; $byte++) {
    $bits = [Math]::Max(0, [Math]::Min(8, $prefix - 8 * $byte))
    $mask = (255 -shl (8 - $bits)) -band 255
    if (($networkBytes[$byte] -band $mask) -ne $networkBytes[$byte] -or
        ($hostBytes[$byte] -band $mask) -ne $networkBytes[$byte]) {
        throw "MeshSubnet must use its network address and include HostMeshIP."
    }
}
if (-not (Get-NetIPAddress -AddressFamily IPv4 -IPAddress $HostMeshIP.IPAddressToString -ErrorAction SilentlyContinue)) {
    throw "Start EasyTier and verify that HostMeshIP is assigned locally."
}

$rules = @(Get-NetFirewallApplicationFilter -PolicyStore PersistentStore |
    Where-Object { [Environment]::ExpandEnvironmentVariables([string]$_.Program) -ieq $program.FullName } |
    Get-NetFirewallRule |
    Where-Object { $_.Direction -eq "Inbound" -and $_.Action -eq "Allow" -and $_.Enabled -eq "True" })
$addresses = @{ LocalAddress = $HostMeshIP.IPAddressToString; RemoteAddress = $MeshSubnet }
if ($rules.Count -eq 0) {
    if ($PSCmdlet.ShouldProcess($program.FullName, "Allow inbound traffic on the mesh only")) {
        $ruleParameters = @{
            DisplayName = "Mesh Remote streaming host"
            Program = $program.FullName
            Direction = "Inbound"
            Action = "Allow"
            Profile = "Any"
        }
        New-NetFirewallRule @ruleParameters @addresses | Out-Null
    }
} else {
    foreach ($rule in $rules) {
        if ($PSCmdlet.ShouldProcess($rule.DisplayName, "Limit inbound traffic to the mesh")) {
            $rule | Get-NetFirewallAddressFilter | Set-NetFirewallAddressFilter @addresses | Out-Null
        }
    }
}
