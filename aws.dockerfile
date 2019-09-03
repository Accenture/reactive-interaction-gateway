FROM maven:3-jdk-8-alpine as java-build

COPY kinesis-client /opt/sites/rig/kinesis-client

WORKDIR /opt/sites/rig/kinesis-client

# Compile AWS Kinesis Java application
RUN mvn package

FROM elixir:1.9-alpine as elixir-build

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

# Install project dependencies
RUN mix deps.get

# Copy application files

COPY config /opt/sites/rig/config
COPY lib /opt/sites/rig/lib

# Compile and release application production code
RUN mix compile
RUN mix distillery.release

FROM erlang:22-alpine

RUN apk add --no-cache bash

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV REPLACE_OS_VARS=true
ENV KINESIS_OTP_JAR=/opt/sites/rig/kinesis-client/local-maven-repo/org/erlang/otp/jinterface/1.8.1/jinterface-1.8.1.jar

# Install Java
RUN apk add --no-cache openjdk8-jre

WORKDIR /opt/sites/rig
COPY --from=elixir-build /opt/sites/rig/_build/prod/rel/rig /opt/sites/rig/
COPY --from=java-build opt/sites/rig/kinesis-client /opt/sites/rig/kinesis-client

# Proxy
EXPOSE 4000
# Internal APIs
EXPOSE 4010

CMD trap exit INT; trap exit TERM; /opt/sites/rig/bin/rig foreground & wait
