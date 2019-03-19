---
id: https
title: HTTPS
sidebar_label: HTTPS
---

## HTTPS/TLS

In order to enable HTTPS, the `HTTPS_CERTFILE` and `HTTPS_KEYFILE` environment variables must be set. During development, this may be set to the self-signed certificate that comes with the repository:

```bash
$ export HTTPS_CERTFILE=cert/selfsigned.pem
$ export HTTPS_KEYFILE=cert/selfsigned_key.pem
$ mix phx.server
```

WARNING: only use the generated certificate for testing in a closed network environment, such as running a development RIG instance on localhost. For production, staging, or testing on the public internet, obtain a proper certificate, for example from [Let’s Encrypt](https://letsencrypt.org/).

For production you should use proper HTTPS certificates instead (for that reason the Docker image comes without certificates).

1. Create your own certificate
2. Store it on your machine
3. Run the docker image by mounting the files as shown here:

```bash
$ docker run \
  -v "$(pwd)"/cert/own-certificate.pem:/cert/own-certificate.pem \
  -e HTTPS_CERTFILE=/cert/own-certificate.pem \
  -v "$(pwd)"/cert/own-certificate_key.pem:/cert/own-certificate_key.pem \
  -e HTTPS_KEYFILE=/cert/own-certificate_key.pem \
  -p 4000:4000 -p 4010:4010 \
  -p 4001:4001 -p 4011:4011 \
  accenture/reactive-interaction-gateway
```

Refer to the [RIG operator guide](rig-ops-guide.md) to learn more about available configuration options.
