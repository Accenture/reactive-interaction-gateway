---
id: api-gateway
title: API Gateway
sidebar_label: API Gateway
---

RIG includes a basic API Gateway implemention (a configurable, distributed HTTP reverse proxy). In a nutshell, this means that RIG will forward a given HTTP request to another service, wait for the reply and forward that reply to the original caller.

Initial configuration of available endpoints can be done using a static file. There is also an API that can be used to add/change/remove routes at runtime.

## File-based configuration

A JSON file can be used to provide an initial configuration to RIG. When using Docker, you can mount the file into the container:

```bash
docker run \
  -e PROXY_CONFIG_FILE=config.json -v config.json:config.json \
  accenture/reactive-interaction-gateway
```

The file contains a list of API definitions. The definitions are expected in the same format as the HTTP request body outlined below.

## Proxy HTTP API

RIG also offers an API for creating, changing, and removing API endpoint definitions at runtime. If you're running multiple RIG instances, changes done on one instance will be synchronized to the other instances automatically. Check out the TODO API documentation to learn more.
