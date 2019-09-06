FROM elixir:1.9-alpine as build

# Install Elixir & Erlang environment dependencies
RUN apk add --no-cache make gcc g++
RUN mix local.hex --force
RUN mix local.rebar --force

ENV MIX_ENV=prod
WORKDIR /opt/sites/rig

# Copy release config
COPY version /opt/sites/rig/
COPY rel /opt/sites/rig/rel/
COPY vm.args /opt/sites/rig/

# Copy necessary files for dependencies
COPY mix.exs /opt/sites/rig/
COPY mix.lock /opt/sites/rig/

# Install project dependencies and compile them
RUN mix deps.get && mix deps.compile && mix deps.clean mime --build

# Copy application files
COPY config /opt/sites/rig/config
COPY lib /opt/sites/rig/lib

# Compile and release application production code
RUN mix compile
RUN mix distillery.release

FROM erlang:22-alpine

LABEL org.label-schema.name="Reactive Interaction Gateway"
LABEL org.label-schema.description="Reactive API Gateway and Event Hub"
LABEL org.label-schema.url="https://accenture.github.io/reactive-interaction-gateway/"
LABEL org.label-schema.vcs-url="https://github.com/Accenture/reactive-interaction-gateway"

RUN apk add --no-cache bash

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

WORKDIR /opt/sites/rig
COPY --from=build /opt/sites/rig/_build/prod/rel/rig /opt/sites/rig/

# Proxy
EXPOSE 4000
# Internal APIs
EXPOSE 4010

CMD trap exit INT; trap exit TERM; /opt/sites/rig/bin/rig foreground & wait
