---
id: api-gateway-management
title: API Gateway Management
sidebar_label: API Gateway Management
---

RIG offers an API for creating, changing, and removing API endpoint definitions at runtime.
Changes caused by calling the API on one RIG node will automatically get distributed among the
cluster, so all nodes share the same configuration without having to sync anything manually.

## Swagger

```bash
docker run -p 4000:4000 -p 4010:4010 accenture/reactive-interaction-gateway

# Visit http://localhost:4010/swagger-ui
# TODO fix swagger in official container
```

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
          "id": "get-auth-register",
          "path": "/auth/register",
          "method": "GET",
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
          "id": "get-auth-register",
          "path": "/auth/register",
          "method": "GET",
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
