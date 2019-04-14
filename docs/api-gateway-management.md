---
id: api-gateway-management
title: API Gateway Management
sidebar_label: API Gateway Management
---

RIG offers an API for creating, changing, and removing API endpoint definitions at runtime. Changes caused by calling the API on one RIG node will automatically get distributed among the cluster, so all nodes share the same configuration without having to sync anything manually. Check out the [API Gateway Synchronization](api-gateway-synchronization.md) to learn more.

## Swagger

Easiest way how to work with internal REST API is via Swagger.

> __NOTE:__ API running on port `4010` is intended to be internal and thus not publicly exposed without any authorization -- to prevent malicious actions.

```bash
docker run -p 4000:4000 -p 4010:4010 accenture/reactive-interaction-gateway

## Notice the "Schemes" field to select between http and https
# Visit http://localhost:4010/swagger-ui
```

You'll right away see list of all internal APIs.

## Create new API

`POST /v1/apis`

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
          "id": "post-auth-register",
          "path": "/auth/register",
          "method": "POST",
          "secured": false
        }
      ]
    }
  },
  "proxy": {
    "use_env": true,
    "target_url": "AUTH_HOST",
    "port": 6666
  }
}
```

## Read list of APIs

`GET /v1/apis`

This is also way how to check if your APIs were loaded properly.

## Read detail of specific API

`GET /v1/apis/:api_id`

## Update API

`PUT /v1/apis/:api_id`

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
          "id": "post-auth-register",
          "path": "/auth/register",
          "method": "POST",
          "secured": false
        }
      ]
    }
  },
  "proxy": {
    "use_env": true,
    "target_url": "AUTH_HOST",
    "port": 6666
  }
}
```

## Delete API

`DELETE /v1/apis/:api_id`
