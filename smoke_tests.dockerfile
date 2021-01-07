FROM elixir:1.11.2-alpine

WORKDIR /opt/sites/rig
ENV MIX_ENV=test

# Install Elixir & Erlang environment dependencies
RUN apk add --no-cache make gcc g++
COPY .tool-versions /opt/sites/rig/
RUN mix local.hex --force
RUN mix local.rebar --force

# Copy necessary files for dependencies
COPY mix.exs /opt/sites/rig/
COPY mix.lock /opt/sites/rig/

# Install project dependencies and compile them
RUN mix deps.get && mix deps.compile && mix deps.clean mime --build

# Copy application files
COPY priv /opt/sites/rig/priv
COPY config /opt/sites/rig/config
COPY lib /opt/sites/rig/lib
COPY test /opt/sites/rig/test

# Proxy
EXPOSE 4000
# Internal APIs
EXPOSE 4010

# Precompile
RUN mix compile

CMD ["mix", "test", "--only", "smoke"]
