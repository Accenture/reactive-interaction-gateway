✓

Rig.Common:
  - config ✓

Rig.Mesh: [done]
  - the thing that runs the Phoenix PubSub server ✓

Rig.Auth:
  - bundles all things authentication, like JWT validation or OAuth2 stuff (when it's there)
  - has jwt secret key, etc.

Rig.InboundGateway:
  - the thing that provides a http port for frontends, forwarding connections to configured backends
  - the thing that holds the connections
    - so the phx transports go here
  - the thing that manages the blacklist
  - the thing that manages the backend configs
  - the thing that does rate limiting
  - the thing that logs requests to Kafka (this is not in the Outbound Gateway, but uses the same Brod client id, so in turn the same Kafka connection)
  - deps: [
      {:rig_auth, in_umbrella: true},
      {:rig_common, in_umbrella: true},
      {:rig_mesh, in_umbrella: true},
    ]

Rig.OutboundGateway: [done]
  - from Kafka ✓
  - from SQS
  - deps: [
      {:rig_common, in_umbrella: true},
    ]

Rig.Api:
  - the thing that provides an API to the outbound gateway ✓
  - the thing that provides a http port for managing RIG
  - the thing that provides an API for allowing users to join other channels (which is limited by duration)
  - the thing that provides an API for configuring endpoints
  - the thing that provides an API for getting info about the connection state in Presence, the contents in the blacklist and the status of connections to other nodes via Node.list
  - will be OAuth2 "resource server" when OAuth2 is enabled (then :rig_auth will be a dep)
  - deps: [
      {:rig_inbound_gateway, in_umbrella: true},
      {:rig_outbound_gateway, in_umbrella: true},
    ]

Rig.AdminFrontend:
  - the thing that provides a http port for accessing the admin UI
  - uses only APIs for displaying/changing stuff
  - integrates with the proxy thing (displays info about connections, allows to change the backend configuration)
  - integrates with the thing that accepts messages (displays info about its sources)
  - "integrates" with other endpoints -- in fact, it only uses Presence to get connection, blacklist and config information, and uses Node.list to show connected instances
  - will be OAuth2 "app" when OAuth2 is enabled (then :rig_auth will be a dep)
  - deps: [
      {:rig_api, in_umbrella: true}
    ]

Rig.Monitor:
  - uses the API thing
  - connects to Prometheus
  - connects to ...?
  - deps: [
      {:rig_api, in_umbrella: true}
    ]