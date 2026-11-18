# Clash Verge Rev 与 TUN

使用 Clash Verge Rev 时，可把 [JavaScript 示例](clash-verge-mesh-patch.js)加到当前配置的脚本扩展。先把 directCidrs 改为自己的组网网段，如有需要再添加中继当前公网 IPv4 的 /32 或 IPv6 的 /128。

应用配置后检查 Clash Verge 的 TUN 设置。如果界面覆盖了脚本的 route-exclude-address，把相同的排除项也填入界面。中继地址发生变化时需同步更新排除项。EasyTier Windows 配置的 bind_device 可让连接使用物理网卡。

脚本只追加必要的 TUN 排除与前置直连规则，重复应用会去重。检查配置中原有的自定义规则、DNS、代理组和监听是否按预期工作。
