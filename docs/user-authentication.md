---
id: user-authentication
title: User authentication
sidebar_label: User authentication
---

RIG uses [JSON Web Tokens](https://jwt.io/) (JWT, for short) for authenticating users.

> RIG can also be used without having any authentication at all, as long as frontends only subscribe to public topics.

RIG can handle authentication itself in a very simple way or you can use _your_ own authentication service to do that. One of our goals is to keep RIG free from any business logic. This enables an important property: even if your authentication mechanism changes completely, you won't have to restart RIG. Your clients' connections won't be interrupted and you can roll out your changes incrementally, which makes for a nicer user experience.

## Authentication token

RIG currently supports symmetric hashing only (HS256, RS256). Please make sure to use keys of appropriate length, as described in [the spec](https://tools.ietf.org/html/rfc7518#section-3.2). For example, if you use HS256, your secret key should be at least 32 character (256 bit) in length. You can validate token also by private key (RS256, etc). To see what is possible to configure check [Operator's guide](rig-ops-guide.md#configuration).

### Expected fields

RIG expects very few fields to be present in a token. Here's an example of a valid one:

```javascript
// Header:
{
  "alg": "HS256",
  "typ": "JWT"
}
// Payload:
{
  "exp": 99999999
}
```
