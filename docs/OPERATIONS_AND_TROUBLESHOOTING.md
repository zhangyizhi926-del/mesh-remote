# 部署与故障排查

## 云服务器部署

需要 Linux、systemd 247 或更新版、sudo 权限和可从控制端访问的公网 IPv4。以下命令在仓库根目录运行。先从 [EasyTier Releases](https://github.com/EasyTier/EasyTier/releases/tag/v2.6.4) 获取 Linux 对应架构版本，核对发布页提供的校验信息，解压后将对应的可执行文件路径替换到第一条命令。

~~~bash
sudo install -m 0755 ./easytier-core /usr/local/bin/easytier-core
sudo install -d -m 0750 /etc/mesh-remote
sudo install -m 0600 -o root -g root relay/relay.example.toml /etc/mesh-remote/relay.toml
sudoedit /etc/mesh-remote/relay.toml
~~~

已有配置时直接用 sudoedit 编辑。把网络名和密钥换成实际值，各端填写一致。可使用 openssl rand -hex 32 生成随机密钥并妥善保存。模板把 TCP 33445 和 UDP 33446 绑定到所有 IPv4 接口。放行这两个端口的主机防火墙和云安全组入站规则。若变更端口，同步调整两层防火墙和客户端填入的初始节点。

~~~bash
sudo /usr/local/bin/easytier-core --check-config --disable-env-parsing -c /etc/mesh-remote/relay.toml >/dev/null 2>&1
sudo install -m 0644 relay/systemd/mesh-remote-relay.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now mesh-remote-relay.service
systemctl is-active mesh-remote-relay.service
ss -lntu | grep -E ':(33445|33446)\b'
~~~

配置校验返回非零时先修复 TOML 再启动。服务通过 systemd 凭据传入配置，并关闭 EasyTier 进程输出，避免配置解析错误把密钥写进日志。需要诊断时，在停掉服务后以受控方式检查输出，分享前删除凭据和实际地址。

停用或回滚时，运行 sudo systemctl disable --now mesh-remote-relay.service，撤回本次添加的入站规则。保留私有配置以便恢复。

### 可选流量保护

安装 vnStat 2.x 和 jq，运行 ip route show default 确认云服务器出口网卡，并用 vnstat -i <接口> --json m 确认当前计数。模板按系统本地日历月计算该网卡的总发送字节数。填写与账单周期相符且留有余量的阈值。若需要计入安装前的月内流量，用 BASELINE_MONTH（YYYY-MM）和 BASELINE_TX_BYTES 填写尚未计入 vnStat 的部分。

~~~bash
sudo install -m 0600 relay/quota.conf.example /etc/mesh-remote/quota.conf
sudoedit /etc/mesh-remote/quota.conf
sudo install -m 0755 relay/check-traffic-quota.sh /usr/local/sbin/mesh-remote-check-quota
sudo install -m 0644 relay/systemd/mesh-remote-quota.{service,timer} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl start mesh-remote-quota.service
sudo systemctl enable --now mesh-remote-quota.timer
~~~

计数越过停止阈值后服务停止并保留停止标记。核对账单并确认可以恢复时，先检查阈值，再删除 /var/lib/mesh-remote-quota/stopped 并启动中继。停用配额守护时运行 sudo systemctl disable --now mesh-remote-quota.timer。检查记录见 journalctl -u mesh-remote-quota.service。

## Windows 启动与验证

首次使用先前台运行。确认可用后，可使用 EasyTier 客户端提供的开机启动功能，或用任务计划程序在开机时调用已安装的 easytier-core.exe，并通过 -c 引用受保护的绝对配置路径。以 SYSTEM 启动时，程序目录和配置目录应仅允许管理员和 SYSTEM 写入。

在另一台已入网的 Windows 设备验证，使用实际地址和 CLI 路径：

~~~powershell
.\windows\Verify-Mesh.ps1 -HostMeshIP 10.77.0.10 -EasyTierCli .\easytier\win\easytier-cli.exe
~~~

脚本检查 EasyTier CLI 能否查询节点，以及串流主机的默认 TCP 47989 是否可达。更改串流端口时使用 -Port。用 Moonlight 完成配对并播放，验证视频、音频和输入。

| 现象 | 检查项 |
| --- | --- |
| 设备未入网 | 核对网络名、密钥和各自的虚拟 IP，确认初始节点可达。 |
| 连通但无法配对 | 在宿主机完成串流账户初始化，检查 Windows 防火墙启用状态、有效策略和串流程序。 |
| 刚加节点就掉线或走错路径 | 检查地址重叠、代理 TUN 排除和已有 VPN 路由。 |
| 看到 TCP 路径时延明显升高 | 用 easytier-cli peer 和 route 检查实际路径，确认 UDP 可达。可单独在本机 TOML 的 flags 段试用 disable_tcp_hole_punching = true，重启后比较。 |
| 配对成功但画面卡顿 | 降低客户端码率或帧率并核对硬件编解码，分别测试直连和中继。 |

防火墙脚本处理指定程序的本地持久允许规则。在 Windows 防火墙高级安全界面检查组策略、端口级规则和其他程序路径的有效入站策略。更换串流软件前从应用导出所需设置和配对状态，按原应用的卸载与恢复步骤处理。

已有部署需迁移时，保留自己的二进制和私有配置，并记录旧单元、定时器和防火墙规则。先验证新私有配置、端口和客户端，安排切换时间。同一监听端口仅能由一项服务占用，切换时有短暂停机。
