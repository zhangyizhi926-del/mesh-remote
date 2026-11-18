// Set the EasyTier CIDR and, if needed, the relay's public /32 or /128.
const directCidrs = ["10.77.0.0/24"];

const directRules = [
  "PROCESS-NAME,easytier-core.exe,DIRECT",
  "PROCESS-NAME,easytier-gui.exe,DIRECT",
  ...directCidrs.map((cidr) =>
    `${cidr.includes(":") ? "IP-CIDR6" : "IP-CIDR"},${cidr},DIRECT,no-resolve`,
  ),
];

function main(config) {
  config.tun = config.tun || {};
  const exclusions = config.tun["route-exclude-address"];
  config.tun["route-exclude-address"] = [
    ...new Set([...(Array.isArray(exclusions) ? exclusions : []), ...directCidrs]),
  ];

  const rules = Array.isArray(config.rules) ? config.rules : [];
  config.rules = [
    ...directRules,
    ...rules.filter((rule) => !directRules.includes(rule)),
  ];
  return config;
}
