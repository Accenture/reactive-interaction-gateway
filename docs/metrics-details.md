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
Documentation to these standard metrics can be found [**here**](https://github.com/deadtrickster/prometheus.ex/tree/master/pages)

## Example Grafana Dashboards

Some example grafana dashboard for the standard metrics can be found [**here**](https://github.com/deadtrickster/beam-dashboards)

_Kudus to [**deadtrickster**](https://github.com/deadtrickster) for his awesome prometheus integration package_