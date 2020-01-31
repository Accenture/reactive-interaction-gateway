#!/bin/bash

echo "Using clients $CLIENTS"
echo "Waiting for clients to come online..."

while true; do
    status=$(curl -s "$CLIENTS:9999")

    if [[ $status == *"OK"* ]]; then
        break
    else
        echo "."
    fi

    sleep 1
done

echo "Starting loader..."