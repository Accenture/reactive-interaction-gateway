## Requirements

* `docker`
* `docker-compose`
* `kubectl` (>= v1.11)
* `timeout`
* `helm` (>= v3)

## Run 1

Send one message, send 1M ignored messages, send one message again.

### ENV Variables - Client
```ini
CLIENTS=1
TIMEOUT=10m
WAIT=30s
RIG_HOST=rig
```

### Start
```bash
./start_run1.sh
```

## Run 2

Send 100k messages to 100 clients.

### ENV Variables - Client
```ini
CLIENTS=100
TIMEOUT=30m
WAIT=30s
RIG_HOST=rig
```

### Start
```bash
./start_run2.sh
```

## Run 6

Send 1000 messages in 100 different event types to 1000 clients.

### ENV Variables - Client
```ini
CLIENTS=1000
TIMEOUT=1h
WAIT=30s
RIG_HOST=rig
```

### Start
```bash
./start_run6.sh
```

## Run 7

Not on k8s yet. 

