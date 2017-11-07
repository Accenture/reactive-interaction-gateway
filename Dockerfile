FROM erlang:20-slim

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

WORKDIR /opt/sites/rig
COPY ./_rig /opt/sites/rig/

EXPOSE 6060

CMD ["/opt/sites/rig/bin/rig", "foreground"]
