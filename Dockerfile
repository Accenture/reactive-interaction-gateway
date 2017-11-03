FROM elixir:1.5 as build

# Install Elixir & Erlang environment dependencies
RUN mix local.hex --force
RUN mix local.rebar --force

ENV MIX_ENV=prod \
    PORT=6060 \
    ORIGIN=https://lwa.accenture.com

WORKDIR /opt/sites/fsa-reactive-gateway

# Copy necessary files for dependencies
COPY mix.exs /opt/sites/fsa-reactive-gateway
COPY mix.lock /opt/sites/fsa-reactive-gateway

# Install project dependencies
RUN mix deps.get

# Copy application files
COPY config /opt/sites/fsa-reactive-gateway/config
COPY lib /opt/sites/fsa-reactive-gateway/lib
COPY priv /opt/sites/fsa-reactive-gateway/priv

# Initialize release & compile application
RUN mix release.init
# Release application production code
RUN mix release


FROM erlang:20-slim

WORKDIR /opt/sites/fsa-reactive-gateway
COPY --from=build /opt/sites/fsa-reactive-gateway/_build/prod/rel/gateway /opt/sites/fsa-reactive-gateway/

EXPOSE 6060

CMD ["/opt/sites/fsa-reactive-gateway/bin/gateway", "foreground"]
