FROM elixir:1.5 as build

# Install Elixir & Erlang environment dependencies
RUN mix local.hex --force
RUN mix local.rebar --force

ENV MIX_ENV=prod

WORKDIR /opt/sites/rig

# Copy necessary files for dependencies
COPY mix.exs mix.lock /opt/sites/rig/

# Install project dependencies
RUN mix deps.get

# Copy application files
COPY config /opt/sites/rig/config
COPY lib /opt/sites/rig/lib
COPY priv /opt/sites/rig/priv

COPY rel /opt/sites/rig/rel/
COPY vm.args /opt/sites/rig/

# Release application production code
RUN mix release

FROM erlang:20-slim

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV REPLACE_OS_VARS=true

WORKDIR /opt/sites/rig
COPY --from=build /opt/sites/rig/_build/prod/rel/rig /opt/sites/rig/

EXPOSE 4000

CMD ["/opt/sites/rig/bin/rig", "foreground"]
