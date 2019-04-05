---
id: api-gateway
title: API Gateway
sidebar_label: API Gateway
---

RIG includes a basic API Gateway implementation (a configurable, distributed HTTP reverse proxy). Provided a route is configured, RIG will forward any matching HTTP request to the respective service or event stream, wait for the reply and forward that reply to the original caller.

## API Endpoint Configuration

The configuration should be passed at startup. Additionally, RIG provides an API to add, change or remove routes at runtime. These changes are replicated throughout the cluster, but they are not persisted; that is, if all RIG nodes are shut down, any changes to the proxy configuration are lost. Check out the [Advanced API documentation](api-gateway-synchronization.md) to learn more.

To pass the configuration at startup, RIG uses an environment variable called `PROXY_CONFIG_FILE`. This variable can be used to either pass the _path_ to an existing JSON file, or to directly pass the configuration as a JSON string. Let's configure a simple endpoint to show how this works.

> The configuration JSON (file) holds a list of API definitions. Refer to the [API documentation](./api-gateway-management.md) for details.

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
  accenture/reactive-interaction-gateway
```

Note that this way we don't need a Docker volume, which might work better in your environment. Again, we should be able to reach the demo service:

```bash
$ curl localhost:4000
Hi, I'm a demo service!
```

## Dynamic URL parameters

It's a common case that you want to fetch detail for some entity e.g. `/books/123`. To make sure the dynamic value `123` is correctly matched and forwarded API endpoint can be configured like this:

```json
[{
  "id": "my-service",
  "version_data": {
    "default": {
      "endpoints": [{
        "id": "my-detail-endpoint",
        "method": "GET",
        "path": "/books/{book_id}"
      }]
    }
  },
  ...
}]
```

Dynamic values in `path` have to be wrapped by curly braces. Value inside curly braces is up to you.

## Publishing to event streams

As an alternative to standard HTTP to HTTP communication, we offer a way how to produce event to Kafka/Kinesis via HTTP request. This means, that frontend can still send regular HTTP request and RIG will publish content of this request to Kafka topic or Kinesis stream. We distinguish between two types of such request -- sync and async.

### Sync

Sync means that as you send HTTP request to RIG, it publishes event to Kafka/Kinesis and waits for signal from consumer to receive event with the same correlation ID. If such event is consumed, HTTP process is notified and client gets back response, otherwise it's timeout. The correlation ID is attached to Cloud events extension in published event called `rigExtension`. In you backend systems you have to make sure that this field will be included also in event that should finish this entire process.

Configuration of such API endpoint might look like this:

```json
[{
  ...
  "version_data": {
    "default": {
      "endpoints": [{
        "id": "my-endpoint",
        "method": "POST",
        "path": "/",
        "target": "kafka",
        "response_from": "kafka"
      }]
    }
  },
  ...
}]
```

> Important fields are `target` and `response_from`. Both of them describe what event stream to use. Currently it's either Kafka or Kinesis. It's recommended to use `POST` http method. `path` name is up to you.

This type of endpoint requires specific HTTP request body:

```json
{
	"event": {
		"id": "069711bf-3946-4661-984f-c667657b8d85",
		"type": "com.example",
		"time": "2018-04-05T17:31:00Z",
		"specversion": "0.2",
		"source": "/cli",
		"contenttype": "application/json",
		"data":{
			"foo": "bar"
		}
	},
	"partition": "your_partition_key"
}
```

As you can it needs 2 fields -- `event` and `partition`. `event` holds event itself (have to comply with Cloud events spec) and `partition` describes partition key to use.

Topic/stream configuration is handled by environment variables. See `PROXY_KAFKA_*` and `PROXY_KINESIS_*` variables in [Operator's Guide](./rig-ops-guide.md).

### Async

Async works in a similar with a difference that RIG won't wait for response. This means as HTTP requests hits RIG, event is published and response sent right away to client.

Configuration of such API endpoint is almost the same, just this time **no `response_from` field**:

```json
[{
  ...
  "version_data": {
    "default": {
      "endpoints": [{
        "id": "my-endpoint",
        "method": "POST",
        "path": "/",
        "target": "kafka"
      }]
    }
  },
  ...
}]
```

HTTP request body and configuration is the same as for sync.

## Auth

If there is a need RIG can do simple auth check for endpoints. Currently supports JWT.

API configuration is following:

```json
[{
  "id": "my-service",
  "auth_type": "jwt",
  "auth": {
    "use_header": true,
    "header_name": "Authorization",
    "use_query": false,
    "query_name": ""
  },
  "version_data": {
    "default": {
      "endpoints": [{
        "id": "my-unsecured-endpoint",
        "method": "GET",
        "path": "/unsecured",
        "secured": false
      },{
        "id": "my-secured-endpoint",
        "method": "GET",
        "path": "/secured",
        "secured": true
      }]
    }
  },
  ...
}]
```

Important blocks are `auth_type` and `auth`. `auth_type` sets which auth mechanism to use -- currently `jwt` or `none`. `auth` sets where to find token that should be used. It's possible to send token in 2 places -- HTTP headers (`use_header`) and as URL query parameter (`use_query`). `header_name` and `query_name` define lookup key in headers/query. If you want you can use headers and query at the same time.

Once you set how to use auth, you can simply define which API endpoint should be secured via `secured` property. Auth check is by default turned off.

## Headers transformations

Headers transformations are supported in a very simple way. Assume following API configuration:

```json
[{
  "id": "my-service",
  "version_data": {
    "default": {
      "transform_request_headers": {
        "add_headers": {
          "host": "my-very-different-host.com",
          "custom-header": "custom-value"
        }
      },
      "endpoints": [{
        "id": "my-endpoint",
        "method": "GET",
        "path": "/"
      },{
        "id": "my-transformed-endpoint",
        "method": "GET",
        "path": "/transformed",
        "transform_request_headers": true
      }]
    }
  },
  ...
}]
```

Via `transform_request_headers` you can set which headers should be overridden or added. In this case RIG would override `host` header and add completely new header `custom-header`. Same as with you can define per endpoint if you want to transform headers using `transform_request_headers` property. Headers transformation is by default turned off.

## URL rewriting

```json
[{
  "id": "my-service",
  "version_data": {
    "default": {
      "endpoints": [{
        "id": "my-endpoint",
        "method": "GET",
        "path": "/",
        "path_replacement": "/different-endpoint"
      },{
        "id": "my-transformed-endpoint",
        "method": "GET",
        "path_regex": "/foo/.+/bar/.+",
        "path_replacement": "/bar/\1/foo/\2"
      }]
    }
  },
  ...
}]
```

Using first endpoint, if you send GET request to `/` RIG will forward the request to GET `/different-endpoint`. In second case we are using `path_regex` instead `path` for some matching (e.g. to get dynamic values such as IDs). As you send GET request to `/foo/1/bar/2` RIG will forward it to GET `/bar/1/foo/2`.
