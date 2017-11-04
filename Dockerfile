FROM erlang:20-slim

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

WORKDIR /opt/sites/fsa-reactive-gateway
COPY ./fsa-reactive-gateway /opt/sites/fsa-reactive-gateway/

EXPOSE 6060

CMD ["/opt/sites/fsa-reactive-gateway/bin/gateway", "foreground"]
