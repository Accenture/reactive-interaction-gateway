---
id: api-gateway
title: Forwarding Requests
sidebar_label: Forwarding Requests
---

RIG includes a configurable, distributed HTTP reverse proxy. Depending on the configuration, RIG forwards incoming HTTP requests to backend services, to a Kafka topic or to a Kinesis stream, then waits for the reply and forwards that reply to the original caller.

## API Endpoint Configuration

The configuration should be passed at startup. Additionally, RIG provides an API to add, change or remove routes at runtime. These changes are replicated throughout the cluster, but they are not persisted; that is, if all RIG nodes are shut down, any changes to the proxy configuration are lost. Check out the [API Gateway Synchronization](api-gateway-synchronization.md) to learn more.

To pass the configuration at startup, RIG uses an environment variable called `PROXY_CONFIG_FILE`. This variable can be used to either pass the _path_ to an existing JSON file, or to directly pass the configuration as a JSON string. Let's configure a simple endpoint to show how this works.

> The configuration JSON (file) holds a list of API definitions. Refer to the [API Gateway Management](./api-gateway-management.md) for details.
> You can also utilize [small playground](https://github.com/Accenture/reactive-interaction-gateway/tree/master/examples/api-gateway) in examples

We define an endpoint configuration like this:

```json
[
  {
    "id": "my-service",
    "version_data": {
      "default": {
        "endpoints": [
          {
            "id": "my-endpoint",
            "method": "GET",
            "path": "/"
          }
        ]
      }
    },
    "proxy": {
      "use_env": true,
      "target_url": "API_HOST",
      "port": 3000
    }
  }
]
```

This defines a single service called "my-service". The URL is read from an given environment variable in this case (`use_env: true`). Because we want to run RIG inside a Docker container, we cannot use `localhost`. Instead, we can use `host.docker.internal` within the container to refer to the Docker host. This way, the service URL is resolved to `http://host.docker.internal:3000`. The service has one endpoint called "my-endpoint" at path `/`, which forwards `GET` requests to the same path (`http://host.docker.internal:3000/`).

As a demo service, we use a small Node.js script:

```js
const http = require("http");
const port = 3000;
const handler = (_req, res) => res.end("Hi, I'm a demo service!\n");
const server = http.createServer(handler);
server.listen(port, (err) => {
  if (err) {
    return console.error(err);
  }
  console.log(`server is listening on ${port}`);
});
```

Using Docker, our configuration can be put into a file and mounted into the container. Also, we set `API_HOST` to the Docker host URL as mentioned above. On Linux or Mac, this looks like this:

```bash
$ cat <<EOF >config.json
<paste the configuration from above>
EOF
$ docker run -d \
  -e API_HOST=http://host.docker.internal \
  -v "$(pwd)"/config.json:/config.json \
  -e PROXY_CONFIG_FILE=/config.json \
  -p 4000:4000 -p 4010:4010 \
  accenture/reactive-interaction-gateway
```

After that we should be able to reach our small demo service through RIG:

```bash
$ curl \
    -H 'traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01' \
    -H 'tracestate: hello=tracing' \
    localhost:4000
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
$ curl \
    -H 'traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01' \
    -H 'tracestate: hello=tracing' \
    localhost:4000
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

Dynamic values in `path` have to be wrapped in curly braces. Value inside curly braces is up to you.

## Publishing to event streams

Instead of forwarding an HTTP request to an internal HTTP endpoint, RIG can also produce an event to a Kafka topic (or Kinesis stream). What looks like a standard HTTP call to the frontend, actually produces an event for backend services to consume.

Depending on the use case, the request may either return immediately or after a response has been produced to another Kafka topic (or Kinesis stream), as described below.

For fire-and-forget style requests, the endpoint configuration looks like this:

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
        "topic": "my-topic",
        "schema": "my-avro-schema"
      }]
    }
  },
  ...
}]
```

Note that the `target` field is set to `kafka` (for Kinesis use `kinesis`). The `topic` field is mandatory, but the `schema` field is optional. Alternatively (fallback to the previously used solution), you can define these values via environment variables, described by the `PROXY_KAFKA_*` and `PROXY_KINESIS_*` variables in the [Operator's Guide](./rig-ops-guide.md). Note that the `topic` and `schema` fields are just about publishing to event stream and have nothing to do with events consumption.

> Beware, that the fallback method is deprecated and will be removed in the version 3.0.

The endpoint expects the following request format:

```json
{
  "id": "069711bf-3946-4661-984f-c667657b8d85",
  "type": "com.example",
  "time": "2018-04-05T17:31:00Z",
  "specversion": "0.2",
  "source": "/cli",
  "contenttype": "application/json",
  "rig": {
    "target_partition": "the-partition-key"
  },
  "data": {
    "foo": "bar"
  }
}
```

> `target_partition` is optional, if not set -- RIG produces event to random Kafka/Kinesis partition.

### Wait for response

Sometimes it makes sense to provide a simple request-response API to something that runs asynchronously on the backend. For example, let's say there's a ticket reservation process that takes 10 seconds in total and involves three different services that communicate via message passing. For an external client, it may be simpler to wait 10 seconds for the response instead of polling for a response every other second.
A behavior like this can be configured using an endpoints' `response_from` property. When set to `kafka`, the response to the request is not taken from the `target` (e.g., for `target` = `http` this means the backend's HTTP response is ignored), but instead it's read from a Kafka topic. In order to enable RIG to correlate the response from the topic with the original request, RIG adds a correlation ID to the request (using a query parameter in case of `target` = `http`, or backed into the produced CloudEvent otherwise). **Backend services that work with the request need to include that correlation ID in their response; otherwise, RIG won't be able to forward it to the client (and times out).**

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
        "topic": "my-topic",
        "response_from": "kafka"
      }]
    }
  },
  ...
}]
```

> Note the presence of `response_from` field. This tells RIG to wait for different event with the same correlation ID.

#### Supported combinations (`target` -> `response_from`)

- HTTP -> `kafka`/`http_async`/`kinesis`
- Kafka -> `kafka`
- Kinesis -> **not supported**
- Nats -> `nats`

`http_async` means that correlated response has to be sent to internal `:4010/v2/responses` `POST` endpoint.

`response_from="kafka"` will try to decode Avro encoded message.

#### Supported formats

All `response_from` options are using message structures as below.

##### Binary

Message headers:

```plaintext
rig-correlation: "correlation_id_sent_by_rig"
rig-response-code: "201"
```

> `rig-correlation` is required.

Message body:

```json
{
  "foo": "bar"
}
```

##### Structured

Message body:

```json
{
  "rig": {
    "correlation": "correlation_id_sent_by_rig",
    "response_code": 201
  },
  "headers": {
    "foo": "bar"
  },
  "body": {
    "foo": "bar"
  }
}
```

> `rig.correlation` is required.

## Auth

RIG can do simple auth check for endpoints. Currently supports JWT.

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
        "path": "/unsecured"
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

Important blocks are `auth_type` and `auth`. `auth_type` sets which auth mechanism to use -- currently `jwt` or `none`. `auth` sets where to find token that should be used. It's possible to send token in 2 places -- HTTP headers (`use_header`) and as URL query parameter (`use_query`). `header_name` and `query_name` define lookup key in headers/query. You can use headers and query at the same time.

Once you set how to use auth, you can simply define which API endpoint should be secured via `secured` property. Auth check is by default disabled and `secured` field set to `false`.

> Make sure to use `Bearer ...` form as a value for auth header.

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

Via `transform_request_headers` you can set which headers should be overridden or added. In this case RIG would override `host` header and add completely new header `custom-header`. Same as with auth, you can define per endpoint if you want to transform headers using `transform_request_headers` property. Headers transformation is by default disabled and `transform_request_headers` field set to `false`.

## URL rewriting

With URL rewriting you can set how the incoming and outgoing request urls should look like.

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
        "path_regex": "/foo/([^/]+)/bar/([^/]+)",
        "path_replacement": "/bar/\\1/foo/\\2"
      }]
    }
  },
  ...
}]
```

In first case, sending GET request to `/` RIG will forward the request to GET `/different-endpoint`. In second case we are using `path_regex` instead of `path` (this is alternative to `## Dynamic URL parameters`). As you send GET request to `/foo/1/bar/2` RIG will forward it to GET `/bar/1/foo/2`.

## CORS

Quite often you need to deal with cross origin requests. CORS itself is configured via `CORS` environment variable, which defaults to `*`. In addition RIG requires to configure OPTIONS pre-flight endpoints:

```json
[{
  "id": "my-service",
  "version_data": {
    "default": {
      "endpoints": [{
        "id": "my-endpoint",
        "method": "GET",
        "path": "/"
      },{
        "id": "my-endpoint-preflight",
        "method": "OPTIONS",
        "path": "/"
      }]
    }
  },
  ...
}]
```

## Request logger

Every request going through reverse proxy can be tracked by loggers -- `console` or/and `kafka`. To enable such logging, set [`REQUEST_LOG`](./rig-ops-guide.md) to one or both of them (comma separated).

In case of Kafka, you can also set which Avro schema to use via [`KAFKA_LOG_SCHEMA`](./rig-ops-guide.md).
