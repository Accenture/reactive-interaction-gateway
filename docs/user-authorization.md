---
id: user-authorization
title: User Authorization
sidebar_label: User Authorization
---

RIG supports the [JSON Web Tokens](https://jwt.io/) (JWT) standard for authorizing users when forwarding HTTP requests, or when handling event subscription or submission requests.

Note that RIG does _not_ do _authentication_ - you will need to provide a service for that yourself. In terms of tokens, this means that RIG won't ever issue JWTs itself; instead, RIG only checks their validity using a shared secret key or a public key, depending on the algorithm used. Please refer to the [Operator's Guide](rig-ops-guide) for the corresponding configuration options.

Also note the following:

- For incoming HTTP requests, JWT validation can be enabled on a per endpoint basis using the `secured` option.
- Event subscriptions can be secured using JWT validation by setting `SUBSCRIPTION_CHECK` to `jwt_validation`.
- Likewise, event submissions can be secured using JWT validation by setting `SUBMISSION_CHECK` to `jwt_validation`.

> For symmetric hashing (HS256, RS256), please make sure you are using keys of appropriate length, as described in [the spec](https://tools.ietf.org/html/rfc7518#section-3.2). For example, if you use HS256, your secret key should be at least 32 character (256 bit) in length.

Example of a minimal JWT:

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
