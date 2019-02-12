---
id: metrics-details
title: Metrics Details
sidebar_label: Metrics Details
---

## Introduction

RIG is providing it's Metrics as [**"Prometheus"**](https://prometheus.io) format. Prometheus is CNCFs second graduated project and therefore can be assumed as de-facto standard.

This metrics can be used to be included into a monitoring platform like [**Grafana**](https://grafana.com/)

## RIG Specific Metrics

Currently there are no RIG specific metrics implemented yet. We are exposing the standard metrics providing information about the running application itself.

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
