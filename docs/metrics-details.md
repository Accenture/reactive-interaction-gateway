---
id: metrics-details
title: Metrics Details
sidebar_label: Metrics Details
---

## Introduction

RIG is providing it's Metrics as [**"Prometheus"**](https://prometheus.io) format. Prometheus is CNCFs second graduated project and therefore can be assumed as de-facto standard.

This metrics can be used to be included into a monitoring platform like [**Grafana**](https://grafana.com/)

## RIG Specific Metrics

### Proxy Metrics - `rig_proxy_requests_total` ###

With this metric the usage of RIGs API Proxy/Gateway can be monitored.

Following Labels are provided:
- **method** - The HTTP method called for this request Following possible values:
  - `GET`
  - `POST`
  - `PUT`
  - `PATCH`
  - `DELETE`
  - `HEAD`
  - `OPTIONS`
- **path** - The path used for this request.
- **target** - The target for this request. Grabbed from proxy parametrization. Following possible values:
  - `http`
  - `kafka`
  - `kinesis`
  - `N/A` - Not available, due to missing parametrization
- **response_from** - Where the response is provided from. Grabbed from proxy parametrization. Following possible values:
  - `http`
  - `kafka`
  - `N/A` - Not available, due to missing parametrization
- **status** - The *internal* status for the request. Attention: this status only tracks the internal rig process status. Once forwarded we track as "ok". We expect that called services are monitored on it's own. Following possible status codes:
  - `ok` - if forwarded successfully
  - `not_found` - if the provided `method` and/or `path` isn't found in the proxy parametrization
  - `bad_gateway` - Could not connect to the parameterized backend (e.g. offline)
  - `method_not_allowed` - If HTTP method is used that is not provided in the list above
  - `gateway_timeout` - On timeout for async response. May only occur if endpoint parameter `response_from` is set to `kafka` or `kinesis`

****
### Standard Metrics ###
We are exposing the standard metrics providing information about the running application itself.

Following standard metrics are currently provided:
- erlang_vm_memory_ets_tables - *Erlang VM ETS Tables count*
- erlang_vm_memory_atom_bytes_total (Labels: Free, Used) - *The total amount of memory currently allocated for atoms. This memory is part of the memory presented as system memory.*
- erlang_vm_port_limit - *The maximum number of simultaneously existing ports at the local node*
- etc.

Detailed documentation to these standard metrics can be found [**here**](https://github.com/deadtrickster/prometheus.ex/tree/master/pages)

## Usecase

To use RIG-Metrics for monitoring in Grafana, following steps are required:
- Add the RIG-Metrics endpoint to the Prometheus config-file `prometheus.yml` + start the Prometheus server
  - In your RIG-Logs you should see continuous calls to the `/metrics`-Endpoint (Prometheus is implemented that it will actively gather data from the configured enpoints)
- In the Grafana frontend add Prometheus as a new datasource
- Now RIG-Metrics can be used to create dashboards

**Note**: This usecase was only described on a very high level to get an idea on how to use metrics. We highly recommed to check out the [**Prometheus**](https://prometheus.io/docs/prometheus/latest/getting_started/) and [**Grafana**](https://prometheus.io/docs/visualization/grafana/) Tutorials if you plan to set this up

## Example Grafana Dashboards

Some example grafana dashboard for the standard metrics can be found [**here**](https://github.com/deadtrickster/beam-dashboards)

_Kudus to [**deadtrickster**](https://github.com/deadtrickster) for his awesome prometheus integration package_
