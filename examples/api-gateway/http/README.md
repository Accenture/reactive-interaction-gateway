# API Gateway

Example code that can be used as a playground for https://accenture.github.io/reactive-interaction-gateway/docs/api-gateway.html.

```bash
# test with RIG 3
docker-compose -f docker-compose.3.0.0.yml up --build

# test with RIG 2.4.0
docker-compose -f docker-compose.2.4.0.yml up --build

# call from postman or curl as a GET request
http://localhost:4000/foo
```
