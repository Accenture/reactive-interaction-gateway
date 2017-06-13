FROM elixir:1.3.4

# Install Elixir & Erlang environment dependencies
RUN mix local.hex --force
RUN mix local.rebar --force

WORKDIR /opt/sites/fsa-reactive-gateway
COPY . /opt/sites/fsa-reactive-gateway

ARG KAFKA_URL
ENV MIX_ENV=prod \
    PORT=6060 \
    KAFKA_URL=$KAFKA_URL

# Install project dependencies
RUN mix deps.get
# Digest Phoenix static files
RUN mix phoenix.digest
# Initialize release & compile application
RUN mix release.init
# Release application production code
CMD ["mix", "release"]