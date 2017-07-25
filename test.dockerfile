FROM elixir:1.3.4

# Install Elixir & Erlang environment dependencies
RUN mix local.hex --force

ENV MIX_ENV=test

WORKDIR /opt/sites/fsa-reactive-gateway

# Copy necessary files for dependencies
COPY mix.exs /opt/sites/fsa-reactive-gateway
COPY mix.lock /opt/sites/fsa-reactive-gateway

# Install project dependencies
RUN mix deps.get

# Copy application files
COPY . /opt/sites/fsa-reactive-gateway

# Run tests
CMD ["mix", "test"]