---
id: jwt-blacklisting
title: JWT Blacklisting
sidebar_label: JWT Blacklisting
---

[JWT](https://jwt.io/) Blacklisting is one of the RIG's core features. Imagine a use case where someone does a malicious action using specific JWT. By blacklisting this JWT, you can prevent any other malicious actions. Once it's blacklisted, user is not able to do any action within the RIG (unless it's an unsecured action -- e.g. unsecured reverse proxy endpoint).

You can blacklist a JWT via REST API call to `POST :4010/v3/session-blacklist` and in body specify the `sessionId` and `validityInSeconds`. `sessionId` is by default expecting [JWT ID - JTI](https://tools.ietf.org/html/rfc7519#page-10), but you can change it via `JWT_SESSION_FIELD` env var.

Blacklist is using so called [ETS](http://erlang.org/doc/man/ets.html) tables to store JTIs and their expiration time. These information are automatically synchronized across RIG cluster. That means you can blacklist a JWT via whatever RIG node and it will apply to all RIG nodes. Blacklisted JTIs in ETS tables are cleaned up based on the `validityInSeconds` property provided in a request.

> `validityInSeconds` should be ideally set to at least _**JWT expiration time - current time**_.

## API

There are 2 APIs that are easily accessible via built-in Swagger UI (`your_host:4010/swagger-ui`).

- `POST :4010/v3/session-blacklist` - to blacklist a JWT
- `GET :4010/v3/session-blacklist/{sessionId}` - to check whether JWT is blacklisted at the moment

## Example

JWT used below has the following payload:

```json
{
  "sub": "1234567890",
  "name": "John Doe",
  "iat": 1516239022,
  "jti": "johndoe",
  "exp": 4516239022
}
```

Run in terminal:

```bash
# run RIG - note the "secured" field in the PROXY_CONFIG_FILE
docker run -d --name rig \
-e PROXY_CONFIG_FILE='[{"id":"service","name":"service","auth_type":"jwt","auth":{"use_header":true,"header_name":"Authorization","use_query":false,"query_name":""},"versioned":false,"version_data":{"default":{"endpoints":[{"id":"secured","path_regex":"todos/1","method":"GET","secured":true}]}},"proxy":{"target_url":"http://jsonplaceholder.typicode.com","port":80}}]' \
-e JWT_SECRET_KEY='rigsecret' \
-p 4000:4000 \
-p 4010:4010 \
accenture/reactive-interaction-gateway

# check if JWT is blacklisted - should return "Not found.", that means it's not blacklisted
curl "http://localhost:4010/v3/session-blacklist/johndoe" \
-H "accept: application/json"

# call an API - should return some data
curl http://localhost:4000/todos/1 \
-H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJqdGkiOiJqb2huZG9lIiwiZXhwIjo0NTE2MjM5MDIyfQ.gPP_Ya_QphNAas3NXqqlfwvyzy_TSN5sh_eMqX0Xnf4"

# blacklist the JWT for 60 seconds
curl -X POST "http://localhost:4010/v3/session-blacklist" -H "accept: application/json" -H "content-type: application/json" -d "{ \"validityInSeconds\": 60,\"sessionId\": \"johndoe\"}"

# check if JWT is blacklisted - should return empty response, that means it's blacklisted
curl "http://localhost:4010/v3/session-blacklist/johndoe" \
-H "accept: application/json"

# call an API - should return "Authentication failed."
curl http://localhost:4000/todos/1 \
-H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJqdGkiOiJqb2huZG9lIiwiZXhwIjo0NTE2MjM5MDIyfQ.gPP_Ya_QphNAas3NXqqlfwvyzy_TSN5sh_eMqX0Xnf4"
```

You can restrict access also to your WS/SSE/Longpolling connections/subscriptions via `SUBSCRIPTION_CHECK` env var, check the [ops guide](./rig-ops-guide.md).
