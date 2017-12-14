FROM elixir:1.5 as build

# Install Elixir & Erlang environment dependencies
RUN mix local.hex --force
RUN mix local.rebar --force

ENV MIX_ENV=prod

WORKDIR /opt/sites/rig

# Copy necessary files for dependencies
COPY mix.exs /opt/sites/rig/
COPY mix.lock /opt/sites/rig/
COPY apps/rig/mix.exs /opt/sites/rig/apps/rig/
COPY apps/rig/mix.lock /opt/sites/rig/apps/rig/

# Install project dependencies
RUN mix deps.get

# Copy application files
COPY config /opt/sites/rig/config
COPY apps/rig/config /opt/sites/rig/apps/rig/config
COPY apps/rig/lib /opt/sites/rig/apps/rig/lib
COPY apps/rig/priv /opt/sites/rig/apps/rig/priv

# Initialize release & compile application
RUN mix release.init
# Release application production code
RUN mix release


FROM erlang:20-slim

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

WORKDIR /opt/sites/rig
COPY --from=build /opt/sites/rig/_build/prod/rel/rig /opt/sites/rig/

EXPOSE 4000

CMD ["/opt/sites/rig/bin/rig", "foreground"]
