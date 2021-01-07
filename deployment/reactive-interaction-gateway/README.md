# reactive-interaction-gateway

![Version: 1.0.1](https://img.shields.io/badge/Version-1.0.1-informational?style=flat-square) ![AppVersion: 3.0.0-alpha.1](https://img.shields.io/badge/AppVersion-3.0.0-alpha.1-informational?style=flat-square)

A Helm chart for Kubernetes

**Homepage:** <https://github.com/Accenture/reactive-interaction-gateway>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| kevinbader |  | https://github.com/kevinbader |
| mmacai |  | https://github.com/mmacai |
| Knappek |  | https://github.com/Knappek |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| deployment.env.API_HTTPS_PORT | int | `4011` | See docs/rig-ops-guide.md |
| deployment.env.API_HTTP_PORT | int | `4010` | See docs/rig-ops-guide.md |
| deployment.env.DISCOVERY_TYPE | string | `"dns"` | See docs/rig-ops-guide.md |
| deployment.env.INBOUND_HTTPS_PORT | int | `4001` | See docs/rig-ops-guide.md |
| deployment.env.INBOUND_PORT | int | `4000` | See docs/rig-ops-guide.md |
| deployment.env.LOG_LEVEL | string | `"warn"` | See docs/rig-ops-guide.md |
| deployment.env.NODE_COOKIE | string | `"magiccookie"` | See docs/rig-ops-guide.md |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"accenture/reactive-interaction-gateway"` |  |
| nodeSelector | object | `{}` |  |
| replicaCount | int | `1` |  |
| resources | object | `{}` |  |
| service.type | string | `"ClusterIP"` |  |
| tolerations | list | `[]` |  |
