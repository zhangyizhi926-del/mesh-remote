# 移动端配置

1. Android 可从 [EasyTier 官方发布](https://github.com/EasyTier/EasyTier/releases)下载客户端。HarmonyOS NEXT 使用与系统版本兼容的原生构建，可查阅 [EasyTier 图形界面安装指南](https://easytier.cn/guide/installation_gui.html)。安装后授权 VPN 连接。
2. 填入与 Windows 和中继一致的网络名、密钥。为移动端选择不同的虚拟地址，例如 Windows 用 10.77.0.10/24，平板用 10.77.0.20/24。使用云中继时填写自己的中继地址及端口。同一 LAN 则填写宿主机的局域网地址和 EasyTier 的监听端口。
3. 在 Moonlight 中手动添加宿主机的虚拟地址，并在宿主机的 Apollo 或 Sunshine 管理页输入配对 PIN。
4. 从 1080p、60 FPS 和适中的码率开始。确认硬件解码稳定后，再提高分辨率、帧率或码率。若宿主机使用虚拟显示器，可按设备显示比例选择分辨率。

换网络后连接失败时，先确认 EasyTier 的 VPN 正在运行、虚拟地址未冲突、初始节点仍可达。某些移动系统限制同时运行的 VPN 数量，检查设备上的其他 VPN 或代理是否抢占连接。
