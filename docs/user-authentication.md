---
id: user-authentication
title: User authentication
sidebar_label: User authentication
---

RIG uses [JSON Web Tokens](https://jwt.io/) (JWT, for short) for authenticating users.

> RIG can also be used without having any authentication at all, as long as frontends only subscribe to public topics.

It's important to understand that RIG does *not* handle authentication itself, but relies on _your_ authentication service to do that. One of our goals is to _keep RIG free from any business logic_. This enables an important property: even if your authentication mechanism changes completely, you won't have to restart RIG. Your clients' connections won't be interrupted and you can roll out your changes incrementally, which makes for a nicer user experience.

## Authentication token

RIG uses [JSON Web Tokens (JWT)](https://en.wikipedia.org/wiki/JSON_Web_Token) to identify users. In development mode, RIG will happily accept any token, which makes running simple or manual tests a bit easier.

In production, RIG will validate the token using its signature. RIG currently supports symmetric hashing only (HS256, HS384, HS512). Please make sure to use keys of appropriate length, as described in [the spec](https://tools.ietf.org/html/rfc7518#section-3.2). For example, if you use HS256, your secret key should be at least 32 character (256 bit) in length. Support for validation by private key (RS256, etc) is in the works.

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
  "exp": 99999999,
  "jti": "1521227425",
  "user": "alice"
}
```

Ignoring the standard fields, the only field relevant for RIG is "user", which is used to associate the connection with a user ID. If needed, the name of that field can be changed easily, using an environment variable.
