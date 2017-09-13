FROM erlang:20-slim

WORKDIR /opt/sites/fsa-reactive-gateway
COPY ./fsa-reactive-gateway /opt/sites/fsa-reactive-gateway/

EXPOSE 6060

CMD ["/opt/sites/fsa-reactive-gateway/bin/gateway", "foreground"]
