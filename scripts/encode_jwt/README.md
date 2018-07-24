# EncodeJwt

Create JWTs that can be used with RIG, mainly for testing purposes.

Usage:

```bash
mix deps.get
mix escript.build
./encode_jwt --help
./encode_jwt --secret myJwtSecret --user alice --exp 1893456000
```
