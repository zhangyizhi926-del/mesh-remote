# Mesh Remote

用 EasyTier 建立加密虚拟网络，让 Moonlight 连接运行 Apollo 或 Sunshine 的 Windows 主机。设备优先直连。跨网直连困难时，可以在支持 systemd 的 Linux 云服务器上部署私有中继。

| 设备 | 需要安装 | 示例 |
| --- | --- | --- |
| Windows 宿主机 | EasyTier、Apollo 或 Sunshine | 虚拟地址 10.77.0.10/24 |
| 控制端 | EasyTier、Moonlight | 虚拟地址 10.77.0.20/24 |
| Linux 云服务器（可选） | EasyTier | relay.example.com，TCP 33445 和 UDP 33446 |

## 快速上手

1. **规划组网。** 选择不与 LAN、VPN 或代理 TUN 冲突的私网 IPv4 网段，给两端分配不同的地址。生成一个强随机网络密钥，让两端和可选中继使用相同的网络名与密钥。表格中的地址和域名供参考。
2. **下载 EasyTier。** 从 [EasyTier Releases](https://github.com/EasyTier/EasyTier/releases/tag/v2.6.4) 获取与操作系统、CPU 架构一致的包。把 Windows CLI 包解压到 easytier/win/，保留包内的 DLL。跨网中继按[云服务器部署](docs/OPERATIONS_AND_TROUBLESHOOTING.md#云服务器部署)配置。同一 LAN 可跳过云端部署。
3. **启动 Windows 节点。** 在项目根目录运行下面的 PowerShell 命令。首次复制后编辑 .local/windows.toml，填写自己的网络名、密钥、虚拟地址和中继域名。仅在 LAN 内使用时，删除两个 [[peer]] 段，把控制端初始节点设为 tcp://<Windows 实际局域网 IP>:11010，按需仅对该 LAN 放行进入 EasyTier 的 TCP 11010。

   ~~~powershell
   New-Item -ItemType Directory -Force .local | Out-Null
   if (-not (Test-Path .\.local\windows.toml)) {
       Copy-Item .\easytier\windows.example.toml .\.local\windows.toml
   }
   ~~~

   编辑配置后，在管理员 PowerShell 中启动节点。

   ~~~powershell
   if (Select-String -Quiet -SimpleMatch '<REPLACE_WITH_A_UNIQUE_SECRET>' .\.local\windows.toml) {
       throw '请先设置自己的网络密钥。'
   }
   & .\easytier\win\easytier-core.exe --check-config --disable-env-parsing -c .\.local\windows.toml *> $null
   if ($LASTEXITCODE -ne 0) { throw 'EasyTier 无法读取配置，请检查 TOML。' }
   & .\easytier\win\easytier-core.exe --disable-env-parsing -c .\.local\windows.toml *> $null
   ~~~

   保持该终端运行。另开终端，用 easytier-cli.exe 的 peer 和 route 子命令检查节点。
4. **连接控制端。** 客户端填写同一网络名和密钥、自己的虚拟地址，以及能从该设备访问的初始节点。可选中继地址为 tcp://<中继域名>:33445 或 udp://<中继域名>:33446。参见[移动端配置](docs/HARMONYOS_AND_MOBILE_GUIDE.md)。
5. **启动串流。** 安装 [Apollo](https://github.com/ClassicOldSong/Apollo/releases) 或 [Sunshine](https://github.com/LizardByte/Sunshine/releases)，在宿主机访问 https://localhost:47990 完成初次设置。关闭 UPnP，并把管理网页的访问范围设为仅本机。用下面的脚本把程序的本地入站允许规则限制在虚拟组网地址。将路径和地址换成实际值，可先加 -WhatIf 预览变更。

   ~~~powershell
   .\windows\Set-StreamingFirewall.ps1 -ProgramPath "$env:ProgramFiles\Apollo\sunshine.exe" -HostMeshIP 10.77.0.10 -MeshSubnet 10.77.0.0/24
   ~~~

   在 Moonlight 里手动添加 Windows 的**虚拟地址**，按提示在宿主机输入配对 PIN。串流端口只需在虚拟网络内可达。

## 按需配置

- [启动、验证、流量配额与故障排查](docs/OPERATIONS_AND_TROUBLESHOOTING.md)
- [HarmonyOS 与 Android](docs/HARMONYOS_AND_MOBILE_GUIDE.md)
- [Clash Verge Rev 与代理 TUN](windows/CLASH_CANDIDATES.md)
- [网络架构与 Tailscale 备选方案](docs/ARCHITECTURE.md)

真实配置、密钥、配对状态和日志放在受访问权限保护的本地目录。提交只包含使用示例地址和占位符的模板。
