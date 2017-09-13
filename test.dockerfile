FROM elixir:1.5

# Install Elixir & Erlang environment dependencies
RUN mix local.hex --force
RUN mix local.rebar --force

ENV MIX_ENV=test

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
COPY test /opt/sites/fsa-reactive-gateway/test
COPY web /opt/sites/fsa-reactive-gateway/web

# Run tests
CMD ["mix", "test"]
