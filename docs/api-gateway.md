---
id: api-gateway
title: API Gateway
sidebar_label: API Gateway
---

RIG includes a basic API Gateway implementation (a configurable, distributed HTTP reverse proxy). Provided a route is configured, RIG will forward any matching HTTP request to the respective service, wait for the reply and forward that reply to the original caller.

The configuration should be passed at startup. Additionally, RIG provides an API to add, change or remove routes at runtime. These changes are replicated throughout the cluster, but they are not persisted; that is, if all RIG nodes are shut down, any changes to the proxy configuration are lost. Check out the [Advanced API documentation](api-gateway-synchronization.md) to learn more.

To pass the configuration at startup, RIG uses an environment variable called `PROXY_CONFIG_FILE`. This variable can be used to either pass the _path_ to an existing JSON file, or to directly pass the configuration as a JSON string. Let's configure a simple endpoint to show how this works.

> The configuration JSON (file) holds a list of API definitions. Refer to the [API documentation](https://github.com/Accenture/reactive-interaction-gateway/blob/master/guides/configuration.md#api-gateway) for details.

We define an endpoint configuration like this:

```json
[{
  "id": "my-service",
  "version_data": {
    "default": {
      "endpoints": [{
        "id": "my-endpoint",
        "method": "GET",
        "path": "/"
      }]
    }
  },
  "proxy": {
    "use_env": true,
    "target_url": "API_HOST",
    "port": 3000
  }
}]
```

This defines a single service called "my-service". The URL is read from an given environment variable in this case (`use_env: true`). Because we want to run RIG inside a Docker container, we cannot use `localhost`. Instead, we can use `host.docker.internal` within the container to refer to the Docker host. This way, the service URL is resolved to `http://host.docker.internal:3000`. The service has one endpoint called "my-endpoint" at path `/`, which forwards `GET` requests to the same path (`http://host.docker.internal:3000/`).

As a demo service, we use a small Node.js script:

```js
const http = require("http");
const port = 3000;
const handler = (_req, res) => res.end("Hi, I'm a demo service!\n");
const server = http.createServer(handler);
server.listen(port, err => {
  if (err) {
    return console.error(err);
  }
  console.log(`server is listening on ${port}`);
})
```

Using Docker, our configuration can be put into a file and mounted into the container. Also, we set `API_HOST` to the Docker host URL as mentioned above. On Linux or Mac, this looks like this:

```bash
$ cat <<EOF >config.json
<paste the configuration from above>
EOF
$ docker run \
  -e API_HOST=http://host.docker.internal \
  -v "$(pwd)"/config.json:/config.json \
  -e PROXY_CONFIG_FILE=/config.json \
  -p 4000:4000 -p 4010:4010 \
  -e HTTPS_CERTFILE=cert/selfsigned.pem \
  -e HTTPS_KEYFILE=cert/selfsigned_key.pem \
  accenture/reactive-interaction-gateway
```

After that we should be able to reach our small demo service through RIG:

```bash
$ curl localhost:4000
Hi, I'm a demo service!
```

Alternatively, instead of using a file we can also pass the configuration directly:

```bash
$ config="$(cat config.json)"
$ docker run \
  -e API_HOST=http://host.docker.internal \
  -e PROXY_CONFIG_FILE="$config" \
  -p 4000:4000 -p 4010:4010 \
  -e HTTPS_CERTFILE=cert/selfsigned.pem \
  -e HTTPS_KEYFILE=cert/selfsigned_key.pem \
  accenture/reactive-interaction-gateway
```

Note that this way we don't need a Docker volume, which might work better in your environment. Again, we should be able to reach the demo service:

```bash
$ curl localhost:4000
Hi, I'm a demo service!
```
