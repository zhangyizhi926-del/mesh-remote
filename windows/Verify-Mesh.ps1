#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [System.Net.IPAddress]$HostMeshIP,

    [ValidateRange(1, 65535)]
    [int]$Port = 47989,

    [string]$EasyTierCli
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($EasyTierCli) {
    $cliPath = (Get-Item -LiteralPath $EasyTierCli).FullName
    & $cliPath peer
    if ($LASTEXITCODE -ne 0) {
        throw "EasyTier CLI could not query the local node."
    }
}

if (-not (Test-NetConnection -ComputerName $HostMeshIP.IPAddressToString -Port $Port -InformationLevel Quiet)) {
    throw "The streaming host did not answer on its mesh address (TCP $Port)."
}
Write-Output "Streaming host reachable over the mesh (TCP $Port)."
