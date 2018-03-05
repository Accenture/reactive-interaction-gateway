FROM maven:3-jdk-8-alpine as java-build

COPY kinesis-client /opt/sites/rig/kinesis-client

WORKDIR /opt/sites/rig/kinesis-client

# Compile AWS Kinesis Java application
RUN mvn package

FROM elixir:1.6-alpine as elixir-build

# Install Elixir & Erlang environment dependencies
RUN mix local.hex --force
RUN mix local.rebar --force
RUN apk update && apk add make \
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
COPY apps/rig/mix.exs /opt/sites/rig/apps/rig/
COPY apps/rig_api/mix.exs /opt/sites/rig/apps/rig_api/
COPY apps/rig_auth/mix.exs /opt/sites/rig/apps/rig_auth/
COPY apps/rig_inbound_gateway/mix.exs /opt/sites/rig/apps/rig_inbound_gateway/
COPY apps/rig_outbound_gateway/mix.exs /opt/sites/rig/apps/rig_outbound_gateway/

# Install project dependencies
RUN mix deps.get

# Copy application files
COPY config /opt/sites/rig/config

COPY apps/rig/config /opt/sites/rig/apps/rig/config
COPY apps/rig/lib /opt/sites/rig/apps/rig/lib

COPY apps/rig_api/config /opt/sites/rig/apps/rig_api/config
COPY apps/rig_api/lib /opt/sites/rig/apps/rig_api/lib
COPY apps/rig_api/priv /opt/sites/rig/apps/rig_api/priv

COPY apps/rig_auth/config /opt/sites/rig/apps/rig_auth/config
COPY apps/rig_auth/lib /opt/sites/rig/apps/rig_auth/lib

COPY apps/rig_inbound_gateway/config /opt/sites/rig/apps/rig_inbound_gateway/config
COPY apps/rig_inbound_gateway/lib /opt/sites/rig/apps/rig_inbound_gateway/lib
COPY apps/rig_inbound_gateway/priv /opt/sites/rig/apps/rig_inbound_gateway/priv

COPY apps/rig_outbound_gateway/config /opt/sites/rig/apps/rig_outbound_gateway/config
COPY apps/rig_outbound_gateway/lib /opt/sites/rig/apps/rig_outbound_gateway/lib

# Compile and release application production code
RUN mix release

FROM erlang:20-alpine

RUN apk update && apk add bash

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV REPLACE_OS_VARS=true

# Install Java
RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk/jre
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

ENV JAVA_VERSION 8u111
ENV JAVA_ALPINE_VERSION 8.151.12-r0

RUN set -x \
	&& apk add --no-cache \
		openjdk8-jre="$JAVA_ALPINE_VERSION" \
	&& [ "$JAVA_HOME" = "$(docker-java-home)" ]

WORKDIR /opt/sites/rig
COPY --from=elixir-build /opt/sites/rig/_build/prod/rel/rig /opt/sites/rig/
COPY --from=java-build opt/sites/rig/kinesis-client /opt/sites/rig/kinesis-client

# Proxy
EXPOSE 4000
# Internal APIs
EXPOSE 4010

CMD ["/opt/sites/rig/bin/rig", "foreground"]
