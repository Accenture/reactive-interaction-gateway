# Configuration

Adopting RIG into your system should be easy. If you struggle, please open an Issue, so we can
ease the process for everyone. The moving parts:

- The [static configuration](#static-configuration), which is about options like timeouts or
  Kafka topic names
- The [API gateway configuration](#api-gateway), static and/or at runtime
- The [message formats](#message-formats)
- The [authentication token format](#authentication-token)

## Static Configuration

Most of RIGs settings can be configured in the files found in the [config directory](../config/).
For example, take a look at the [main config file](../config/config.exs), where you find most of
the options, along with their default values. The file should also be self-explanatory; if it
isn't, feel free to create a PR to start the discussion.

TODO: describe how to override at runtime

## API Gateway

The API Gateway forwards requests to configured endpoints, then waits for the reply and finally
sends the reply back to the client. The available endpoints can be configured using a static file, or at runtime, using a dedicated API.

### Using a static file
A JSON file can be used to provide an initial configuration to RIG, e.g.,
```bash
$ PROXY_CONFIG_FILE=/path/to/config.json mix phx.server
```
or
```bash
$ docker run -e PROXY_CONFIG_FILE=config.json -v config.json:config.json rig
```
The file should contain a list of API definitions; for the format of the definitions, see [the body format of the "Create new API" endpoint below](#create-new-api).

### Using the Proxy API
RIG also offers an API for creating, changing, and removing API endpoint definitions at runtime.
Changes caused by calling the API on one RIG node will automatically get distributed among the
cluster, so all nodes share the same configuration without having to sync anything manually.

#### Endpoints

##### Create new API
`POST /apis`
```json
{
  "id": "new-service",
  "name": "new-service",
  "auth_type": "jwt",
  "auth": {
    "use_header": true,
    "header_name": "Authorization",
    "use_query": false,
    "query_name": ""
  },
  "versioned": false,
  "version_data": {
    "default": {
      "endpoints": [
        {
          "id": "get-auth-register",
          "path": "/auth/register",
          "method": "GET",
          "not_secured": true
        }
      ]
    }
  },
  "proxy": {
    "use_env": true,
    "target_url": "IS_HOST",
    "port": 6666
  }
}
```

##### Read list of APIs
`GET /apis`

##### Read detail of specific API
`GET /apis/:api_id`

##### Update API
`PUT /apis/:api_id`
```json
{
  "id": "new-service",
  "name": "new-service",
  "auth_type": "jwt",
  "auth": {
    "use_header": true,
    "header_name": "Authorization",
    "use_query": false,
    "query_name": ""
  },
  "versioned": false,
  "version_data": {
    "default": {
      "endpoints": [
        {
          "id": "get-auth-register",
          "path": "/auth/register",
          "method": "GET",
          "not_secured": true
        }
      ]
    }
  },
  "proxy": {
    "use_env": true,
    "target_url": "IS_HOST",
    "port": 6666
  }
}
```

##### Delete API
`DELETE /apis/:api_id`


## Message Formats

### Consuming Events
For consuming events from Kafka, the only field expected is a username.
For example:
```json
{"username":"SomeUser"}
```

### Producing Logs
For the format used for logging API calls to Kafka, see
[`Gateway.Kafka.log_proxy_api_call/3`](../lib/gateway/kafka.ex).

### Forwarding Events to Frontends
The format of the events pushed to the frontends depends on the transport
used. For example, when using Server-Sent Events, a message that on Kafka
looks like this:
```json
{"username":"SomeUser","greeting":"Hi there!"}
```
arrives at the browser like this:
```json
event: message
data: {"username":"SomeUser","greeting":"Hi there!"}

```

### Authentication Token
By default, RIG makes sure that requests to backend services are authorized (can be disabled per
service). For this to work, you need to use [JSON Web Tokens (JWT)](https://jwt.io/) as
authorization tokens. Of course, RIG has to know about the secret you're using for signing the
tokens in order to verify them. Additionally, the Reactive API Gateway expects some fields to be
present in the token's payload, specifically:
- "jti" (JWT ID) Claim
- "exp" (Expiration Time) Claim
- "user": same identifier used in the Kafka messages
- "roles": the list of roles a user has in the system. You can define privileged roles in the
  config; users that have one of those privileged roles in their "roles" claim are allowed to
  subscribe to any messages in the system, including those meant for other users.