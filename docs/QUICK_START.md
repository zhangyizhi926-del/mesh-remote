# 快速上手 / Quick Start

[简体中文](#简体中文) · [English](#english) · [项目总览](../README.md) · [Project overview](../README.en.md)

## 简体中文

准备一台运行 Apollo 或 Sunshine 的 Windows 宿主机，以及一台能安装 EasyTier 和 Moonlight 的控制端。同一局域网内可先直连。如果校园 Wi-Fi 隔离了设备，或两端不在同一个可互通的网络，使用双方均可访问的私有中继。

1. **选择网段。** 为本次部署生成强随机网络密钥。所有节点使用相同的组网名和密钥，各自使用不同的虚拟地址。示例宿主机用 10.77.0.10/24，控制端用 10.77.0.20/24。若与现有 LAN、VPN 或代理 TUN 冲突，换一个私网网段。
2. **准备 EasyTier。** 下载适合宿主机架构的 CLI 包，解压到项目内的 easytier/win/，保留包中的 DLL 和驱动文件。组网客户端请选对应操作系统的包。[EasyTier v2.6.4 发布页](https://github.com/EasyTier/EasyTier/releases/tag/v2.6.4) · [移动端配置](HARMONYOS_AND_MOBILE_GUIDE.md)
3. **配置初始节点。** 使用云中继时，先按下方步骤部署，并把 Windows 模板中的 relay.example.com 换成自己的中继域名。使用同一 LAN 时，删除 Windows 模板内的两个 [[peer]] 段，把控制端初始节点设为 TCP 协议、宿主机的实际局域网 IP、端口 11010，按需对该 LAN 放行 Windows 上的 TCP 11010。[云中继部署步骤](#linux-relay-setup)
4. **启动 Windows 节点。** 在仓库根目录复制模板，然后编辑 .local/windows.toml，填写组网名、密钥、宿主机虚拟地址和初始节点。

   ~~~powershell
   New-Item -ItemType Directory -Force .local | Out-Null
   if (-not (Test-Path .\.local\windows.toml)) {
       Copy-Item .\easytier\windows.example.toml .\.local\windows.toml
   }
   ~~~

   保存配置后，在管理员 PowerShell 的仓库目录启动 EasyTier，保持终端运行。可用第二个终端执行 easytier-cli.exe peer 和 route 检查路径。

   ~~~powershell
   if (Select-String -Quiet -SimpleMatch '<REPLACE_WITH_A_UNIQUE_SECRET>' .\.local\windows.toml) {
       throw '请先设置自己的组网密钥。'
   }
   & .\easytier\win\easytier-core.exe --check-config --disable-env-parsing -c .\.local\windows.toml *> $null
   if ($LASTEXITCODE -ne 0) { throw 'EasyTier 无法读取配置，请检查 TOML。' }
   & .\easytier\win\easytier-core.exe --disable-env-parsing -c .\.local\windows.toml *> $null
   ~~~

5. **连接控制端。** 在 EasyTier 填写相同的组网名和密钥，使用控制端自己的虚拟地址及第 3 步选定的初始节点。使用云中继时，模板支持 TCP 33445 或 UDP 33446。若校园网限制 UDP，核对 TCP 端点在两端是否均可达。
6. **配置并配对串流。** 在宿主机安装串流软件，访问 https://localhost:47990 完成初次设置。关闭 UPnP，将管理网页设为仅本机。管理员 PowerShell 中可用下列脚本限制 Windows 上该程序的本地入站允许规则。按实际安装路径和地址替换参数，可先加 -WhatIf 预览。[Apollo 下载](https://github.com/ClassicOldSong/Apollo/releases) · [Sunshine 下载](https://github.com/LizardByte/Sunshine/releases)

   ~~~powershell
   .\windows\Set-StreamingFirewall.ps1 -ProgramPath "$env:ProgramFiles\Apollo\sunshine.exe" -HostMeshIP 10.77.0.10 -MeshSubnet 10.77.0.0/24
   ~~~

   在 Moonlight 手动添加宿主机虚拟 IP，用宿主机管理页完成 PIN 配对。以 1080p / 60 FPS 启动串流，检查画面、音频和输入。可从另一台入网的 Windows 设备运行 Verify-Mesh.ps1 检查 TCP 连通性。[Moonlight 下载](https://moonlight-stream.org/) · [日常验证](../README.md#日常快速体检与常用命令)

## English

Start with a Windows host running Apollo or Sunshine and a client that supports EasyTier and Moonlight. Try a direct LAN connection if the devices can reach each other. Use a private relay reachable from both sides if campus Wi-Fi isolates clients or the devices are on separate networks.

1. **Choose a mesh subnet.** Generate a strong random network secret. Use the same network name and secret on all nodes and assign each device its own virtual IP. The example uses 10.77.0.10/24 for the host and 10.77.0.20/24 for the client. Choose another private subnet if it overlaps with a LAN, VPN, or proxy TUN interface.
2. **Get EasyTier.** Download the CLI package for the host's architecture and extract it into easytier/win/ in the checkout. Keep the bundled DLLs and driver files beside the executables. Choose a client package for the other device's operating system. [EasyTier v2.6.4 release](https://github.com/EasyTier/EasyTier/releases/tag/v2.6.4) · [Mobile setup (中文)](HARMONYOS_AND_MOBILE_GUIDE.md)
3. **Set the initial peer.** For a cloud relay, follow the steps below and replace relay.example.com with your relay address in the Windows template. For LAN use, remove both [[peer]] blocks from the Windows template, then point the client at the Windows host's actual LAN IP on TCP port 11010. Allow inbound TCP 11010 from the LAN if the host firewall requires it. [Linux relay setup](#linux-relay-setup)
4. **Start the Windows mesh node.** Copy the template from the repository root and edit .local/windows.toml with your network name, secret, host mesh IP, and initial peers.

   ~~~powershell
   New-Item -ItemType Directory -Force .local | Out-Null
   if (-not (Test-Path .\.local\windows.toml)) {
       Copy-Item .\easytier\windows.example.toml .\.local\windows.toml
   }
   ~~~

   Save the config, then start EasyTier from an elevated PowerShell at the repository root. Keep that terminal open. Run easytier-cli.exe peer and route from a second terminal to inspect the path.

   ~~~powershell
   if (Select-String -Quiet -SimpleMatch '<REPLACE_WITH_A_UNIQUE_SECRET>' .\.local\windows.toml) {
       throw 'Set your own mesh network secret first.'
   }
   & .\easytier\win\easytier-core.exe --check-config --disable-env-parsing -c .\.local\windows.toml *> $null
   if ($LASTEXITCODE -ne 0) { throw 'EasyTier could not read the TOML configuration.' }
   & .\easytier\win\easytier-core.exe --disable-env-parsing -c .\.local\windows.toml *> $null
   ~~~

5. **Join from the client.** In EasyTier, enter the same network name and secret, the client's own virtual address, and the initial peer chosen in step 3. The cloud template offers TCP 33445 or UDP 33446. If campus Wi-Fi restricts UDP, check TCP reachability from both devices.
6. **Set up streaming and pair.** Install Apollo or Sunshine on the host. Open https://localhost:47990, complete initial setup, disable UPnP, and set management UI access to localhost only. Run the following from elevated PowerShell to scope the program's local inbound allow rules. Substitute your installation path and mesh addresses. Add -WhatIf to preview the changes. [Apollo downloads](https://github.com/ClassicOldSong/Apollo/releases) · [Sunshine downloads](https://github.com/LizardByte/Sunshine/releases)

   ~~~powershell
   .\windows\Set-StreamingFirewall.ps1 -ProgramPath "$env:ProgramFiles\Apollo\sunshine.exe" -HostMeshIP 10.77.0.10 -MeshSubnet 10.77.0.0/24
   ~~~

   Add the host's virtual IP manually in Moonlight and enter the PIN in the host's management UI. Start a 1080p / 60 FPS stream and verify video, audio, and input. Use Verify-Mesh.ps1 from another Windows mesh node to check TCP connectivity. [Moonlight downloads](https://moonlight-stream.org/) · [Routine checks](../README.en.md#routine-checks-and-commands)

## Linux relay setup

选择可从两端访问的 Linux 云服务器，需 systemd 247 或更新版。下载并解压与服务器架构匹配的 EasyTier CLI。以下命令在仓库根目录运行，把第一条命令中的二进制路径换成实际路径。

Use a Linux cloud server reachable from both devices with systemd 247 or later. Download and extract EasyTier for the server's architecture. Run the following from the repository root, substituting the binary's real location in the first command. [EasyTier v2.6.4 release](https://github.com/EasyTier/EasyTier/releases/tag/v2.6.4)

~~~bash
sudo install -m 0755 ./easytier-core /usr/local/bin/easytier-core
sudo install -d -m 0750 -o root -g root /etc/mesh-remote
sudo test -f /etc/mesh-remote/relay.toml ||
  sudo install -m 0600 -o root -g root relay/relay.example.toml /etc/mesh-remote/relay.toml
sudoedit /etc/mesh-remote/relay.toml
~~~

编辑网络名和密钥，使其与两端一致。按模板在服务器防火墙和云安全组开放 TCP 33445、UDP 33446。若修改了端口，同步更新两层防火墙及客户端的初始节点。

Set the same network name and secret as the two devices. Allow incoming TCP 33445 and UDP 33446 in the host firewall and cloud firewall. If you change the ports, update both firewalls and the initial peer addresses on the devices.

~~~bash
sudo /usr/local/bin/easytier-core --check-config --disable-env-parsing -c /etc/mesh-remote/relay.toml >/dev/null 2>&1 &&
  sudo install -m 0644 relay/systemd/mesh-remote-relay.service /etc/systemd/system/ &&
  sudo systemctl daemon-reload &&
  sudo systemctl enable --now mesh-remote-relay.service
systemctl is-active mesh-remote-relay.service
ss -lntu | grep -E ':(33445|33446)\b'
~~~

启动失败时检查 TOML 和端口占用。需要流量配额、开机启动或回滚步骤时，请查阅[部署与故障排查](OPERATIONS_AND_TROUBLESHOOTING.md)。

If startup fails, check the TOML and whether the ports are already in use. See [deployment and troubleshooting (中文)](OPERATIONS_AND_TROUBLESHOOTING.md) for traffic quotas, startup, and rollback.
