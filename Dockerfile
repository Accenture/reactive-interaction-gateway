FROM elixir:1.7-alpine as build

# Install Elixir & Erlang environment dependencies
RUN mix local.hex --force
RUN mix local.rebar --force
RUN apk add --no-cache make \
    gcc \
    g++

ENV MIX_ENV=prod

WORKDIR /opt/sites/rig

# Copy release config
COPY version /opt/sites/rig/
COPY rel /opt/sites/rig/rel/
COPY vm.args /opt/sites/rig/

# Copy necessary files for dependencies
COPY mix.exs /opt/sites/rig/
COPY mix.lock /opt/sites/rig/
COPY apps/rig/mix.exs /opt/sites/rig/apps/rig/
COPY apps/rig_api/mix.exs /opt/sites/rig/apps/rig_api/
COPY apps/rig_auth/mix.exs /opt/sites/rig/apps/rig_auth/
COPY apps/rig_inbound_gateway/mix.exs /opt/sites/rig/apps/rig_inbound_gateway/
COPY apps/rig_outbound_gateway/mix.exs /opt/sites/rig/apps/rig_outbound_gateway/

# Install project dependencies
RUN mix deps.get

# Copy application files

COPY config /opt/sites/rig/config

COPY apps/rig/config /opt/sites/rig/apps/rig/config
COPY apps/rig/lib /opt/sites/rig/apps/rig/lib

COPY apps/rig_api/config /opt/sites/rig/apps/rig_api/config
COPY apps/rig_api/lib /opt/sites/rig/apps/rig_api/lib
COPY apps/rig_api/priv /opt/sites/rig/apps/rig_api/priv

COPY apps/rig_auth/config /opt/sites/rig/apps/rig_auth/config
COPY apps/rig_auth/lib /opt/sites/rig/apps/rig_auth/lib

COPY apps/rig_inbound_gateway/config /opt/sites/rig/apps/rig_inbound_gateway/config
COPY apps/rig_inbound_gateway/lib /opt/sites/rig/apps/rig_inbound_gateway/lib
COPY apps/rig_inbound_gateway/priv /opt/sites/rig/apps/rig_inbound_gateway/priv

COPY apps/rig_outbound_gateway/config /opt/sites/rig/apps/rig_outbound_gateway/config
COPY apps/rig_outbound_gateway/lib /opt/sites/rig/apps/rig_outbound_gateway/lib

# Compile and release application production code
RUN mix release

FROM erlang:21-alpine

RUN apk add --no-cache bash

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

WORKDIR /opt/sites/rig
COPY --from=build /opt/sites/rig/_build/prod/rel/rig /opt/sites/rig/

# Proxy
EXPOSE 4000
# Internal APIs
EXPOSE 4010

CMD ["/opt/sites/rig/bin/rig", "foreground"]
