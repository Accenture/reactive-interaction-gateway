FROM elixir:1.5

# Install Elixir & Erlang environment dependencies
RUN mix local.hex --force
RUN mix local.rebar --force

ENV MIX_ENV=prod

WORKDIR /opt/sites/fsa-reactive-gateway

# Copy necessary files for dependencies
COPY mix.exs /opt/sites/fsa-reactive-gateway
COPY mix.lock /opt/sites/fsa-reactive-gateway

# Install project dependencies
RUN mix deps.get

# Copy application files
COPY config /opt/sites/fsa-reactive-gateway/config
COPY lib /opt/sites/fsa-reactive-gateway/lib

# Initialize release & compile application
RUN mix release.init
# Release application production code
CMD ["mix", "release"]
