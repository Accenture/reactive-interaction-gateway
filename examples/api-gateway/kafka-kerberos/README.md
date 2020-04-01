# Kerberos configuration demo

This demo sets up a basic Kafka cluster secured with Kerberos authentication, and sets up some basic ACLs to demonstrate authorisation.
The documentation below introduces the relevant components you need to understand to set up Kerberos in a Linux / JVM environment.


## Kerberos authentication process

Before configuring Kafka for Kerberos authentication, it is useful to understand the basics of Kerberos; the authentication process and some key terms.

_A note on what Kerberos is and is not: Kerberos is a *network authentication protocol* which allows a client application to connect to a network service in a way that allows the components to mutually verify each other's identities._
_It is put to good use in and integrated with network directory services, notably Windows Active Directory._
_Here, Kerberos identities are bound to network accounts and access privileges and, in the case of Windows, the SSPI API supports single sign-on and privilege impersonation natively in the OS._
_This is enabled by Kerberos, but Kerberos itself is not bound to such accounts and does not provide any such capability._

With that, let's work through the process for a client application making a connection into Kafka.

Kerberos involves three parties:

- a Kerberos Client, in this case our client application.
- a Kerberized Service, in this case Kafka.
- the Kerberos **Key Distribution Center (KDC)**

An important point to understand in this process is that the Client and Service each shares their own cryptographic key with the KDC.
By using this key to encrypt/decrypt tokens passed over the network, two network systems can verify each other's identities.
The Client and Service trust that they have only shared their secret with the KDC and so any correctly signed token must have originated from the KDC.
This is crucial.
During the Kerberos process the Client requests a token from the KDC _signed with the Service's key_ and presents this when making a connection.
The Service can then trust that the Client has valid credentials with the KDC and can be authenticated.

Other information is shared during the process to enable integrity checking and protection against various spoofing attacks.
For example, each signed token is:

* timestamped to bound the window for which it is valid
* linked to a network IP so that it is valid only from a single host

The first stage is that the Client application must authenticate itself with the KDC by proving that the Client knows the private credentials relating to the Client's Kerberos **Principal**.
The Principal is a a unique identity in the form {primary}/{instance}@{REALM} (more on these later).
The KDC authenticates the client using their shared cryptographic key and results in the client receiving a **Ticket Granting Ticket (TGT)**.
This is a cryptographic token that the Client may now use to prove that it has recently authenticated with the KDC.
The TGT is timestamped and includes an expiry time, typically a day.
The TGT is cached by the client to avoid having to re-authenticate unnecessarily.

Next, the Client wants to authenticate itself to the Kerberized Service.
For this to happen, the client must get a cryptographic token encrypted with the Kerberized Service's key - this token is a **Service Ticket** and is requested by the client from the KDC using the TGT and the requested service's principal name.
Including the TGT in this request is sufficient to prove that the client has already authenticated with the KDC allowing the service ticket to be returned.

Here is an important point to note - how does the client know the service principal name?
Very simply, it builds the principal with:

- {primary} = a client-side configured name for the service
- {instance} = the network address used to connect to the service
- {REALM} = the realm of the client and KDC.

In our example, our Client attempts to connect to the `kafka` Service on the host `kafka.kerberos-demo.local` in the realm `TEST.CONFLUENT.IO`.
Therefore, the service must be configured with a Service Principal Name of `kafka/kafka.kerberos-demo.local@TEST.CONFLUENT.IO`.

Now the Client can connect directly to the Kerberized Service, and include the Service Ticket.
As the Service ticket is signed with the Service principal's key, the Service can decrypt the token to authenticate the request.

Based on the above, each connection in the cluster must be established with the following in place:

* On the Kerberos Client:
    * A client principal and key to authenticate with the KDC, `{client name}@REALM`
    * This is the *User Principal Name*.
    * a configured name for the service to connect to, `{service name}`
    * the network address for the service, `{network address}`.    
* On the server:
  * a principal name & key in the form `{service name}/{network address}@REALM`.
  * This is the *Service Principal Name*.

As can be seen, the service principal must be constructed correctly to work.
However, the `{client name}` format is not mandated in the same way and is not bound to a network address.
Often the client name is a simple alphanumeric username, let's say 'john'.
However, you may sometimes see a client principal such as 'john/admin'.
In this form, 'admin' is called an _instance_ of the 'john' principal and can be used by 'john' to run services on the system with different credentials and privileges from the main account.
From the Kerberos perspective, the two principals are completely separate, but it can nonetheless be convenient to use this naming convention.


# Technical Components
## KDC
The KDC could be provided by MIT Kerberos, Windows Active Directory, Redhat Identity Manager and many others.
In this demo we use MIT kerberos.


## Kerberos libraries and tools

All the hosts must include Kerberos libraries and a shared configuration (krb5.conf) in order to use and trust the same KDC.

`kinit` is used to authenticate to the Kerberos server as principal, or if none is given, a system generated default (typically your login name at the default realm), and acquire a ticket granting ticket that can later be used to obtain tickets for other services.

`klist` reads and displays the current tickets in the credential cache (also known as the ticket file).

`kvno` acquires a service ticket for the specified Kerberos principals and prints out the key version numbers of each.

`kadmin` is an admin utility for working with the Kerberos database.

A common task when configuring for Kerberos is to build *keytab* files (short for Key Table).
Keytabs are files containing one or more Kerberos principal/credential pairs.
By having these in a file, services can automatically authenticate with the KDC without prompting the user and it is common to build and distribute keytabs as part of a deployment.
However, _as these files contain secret credentials, it is important to take care to protect against loss of these files_.

See [kerberos cheatsheet](../KerberosCheatsheet.md) for examples of using the Kerberos toolset.


## Simple Authentication and Security Layer (SASL)

SASL is a framework for authentication in network communications which in principle decouples authentication concerns from the application protocol.

Kafka and Zookeeper can use SASL as the authentication layer in communications (Mutual TLS being the notable alternative).

When SASL has been enabled, you must further specify a SASL *mechanism* to use - the process and protocol to use when authenticating a connection.
Applications must build support for each SASL mechanism - Kafka supports SCRAM(-SHA-256 | -SHA-512), PLAIN, OAUTHBEARER and GSSAPI.
*GSSAPI is the SASL mechanism which implements Kerberos*.


## Java Authentication and Authorization Services (JAAS)

JAAS is a Java's integrated, pluggable security service and Kafka uses the JAAS APIs to implement SASL authentication.
SASL authentication is configured using JAAS.
Kerberos is configured using the JAAS *LoginModule* `com.sun.security.auth.module.Krb5LoginModule`.

JAAS may be configured in a couple of places:

* By default it uses a .jaas file, a reference to which is passed in the `-Djava.security.auth.login.config=<file path>` JVM flag.
Each jaas file includes multiple named stanzas, representing different login contexts.

* An application can override this configuration and configure JAAS from application config.
Kafka configurations expose this option using properties `sasl.jaas.config`, which can variously be prefixed.
The value is the inline configuration for a single login context and, in Kafka, takes precedence over entries in a .jaas files.

https://docs.oracle.com/javase/8/docs/jre/api/security/jaas/spec/com/sun/security/auth/module/Krb5LoginModule.html


A Kerberos enabled Client or Service can be initiated in two ways:

1. Use `kinit` to cache a TGT locally, and then launch the process with this shared cache.
2. Configure a keytab to be used directly.

Configuration of the former is straight-forward as follows:

```
SomeLoginContext {
  com.sun.security.auth.module.Krb5LoginModule required
  useTicketCache = true;
};
```

The `useTicketCache = true` setting specifies that the TGT cache should be used.

By comparison, the latter approach has `useTicketCache = false` (the default) and then continues to specify details for using a keytab file:

```
SomeLoginContext {
    com.sun.security.auth.module.Krb5LoginModule required
    useKeyTab=true
    storeKey=true
    keyTab="/var/lib/secret/kafka1.key"
    principal="kafka/kafka1.kerberos-demo.local@TEST.CONFLUENT.IO";
};
```

The login context, as identified with `SomeLoginContext` above, can be used by a Client, a Service or both.
For Kafka, the names are defined in the application code as we will describe later.


# Kerberizing Kafka

To fully understand the steps required to Kerberize Kafka, we should understand each Client &rarr; Service connection which we wish to configure.
Each of these connections has a prototypical set of configurations required on the Client side and on the Service side.

The following are values you must decide upon at the cluster level:

* `{kafka-kerberos-service-name}` - name for the Kerberized Kafka service.
Typically `kafka` or `cp-kafka`.
* `{zookeeper-kerberos-service-name}` - name for the Kerberized Zookeeper service.
By default this is `zookeeper`.
* `{security-protocol}` - either `SASL_PLAINTEXT` of `SASL_SSL` if using in conjunction with TLS.

## Service Configurations

In a single node Broker/Zookeeper environment there are just two Kerberized services running.
We will configure these first and then the clients.

### Kafka Service

* Broker JAAS:
    * Login Context: `KafkaServer`
    * Use *keytab* method.
    * Ensure that the principal is a correctly formed service principal for each node: `{kafka-kerberos-service-name}/{FQDN}@{realm}`.
    * Example: [kafka/kafka.sasl.jaas.config](kafka/kafka.sasl.jaas.config)
* Broker Server Properties:
    * `sasl.enabled.mechanisms=GSSAPI` (more SASL mechanisms may be specified in a comma-separated list)
    * `sasl.kerberos.service.name={kafka-kerberos-service-name}`
    * `{listener_name}.{sasl_mechanism}.sasl.jaas.config` - jaas configuration on a per-listener basis.
    * Example: [kafka/server.properties](kafka/server.properties)

### Zookeeper Service

* Zookeeper JAAS:
    * Client API - Kerberize access to ZooKeeper data.
        * Login Context: `Server`.
        * Use *keytab* method.
        * Ensure that the principal is a correctly formed service principal for each node: `{zookeeper-kerberos-service-name}/{FQDN}@{realm}`.
        * Example: [zookeeper/zookeeper.sasl.jaas.config](zookeeper/zookeeper.sasl.jaas.config)
* Zookeeper Properties:
    * authProvider.1 = org.apache.zookeeper.server.auth.SASLAuthenticationProvider
    * requireClientAuthScheme=sasl
    * Example: [zookeeper/zookeeper.properties](zookeeper/zookeeper.properties)


## Client Configurations


### Kafka Broker &rarr; Zookeeper Service
Brokers connect to Zookeeper for cluster operations.

* Broker JAAS:
    * Login Context: `Client`
    * Use *keytab* method.
    * *Ensure that the same principal is configured for use on each broker.*
    * Example: [kafka/kafka.sasl.jaas.config](kafka/kafka.sasl.jaas.config).
* Broker JVM flags:
    * `-Dzookeeper.sasl.client.username={zookeeper-kerberos-service-name}` (OPTIONAL)


### Client &rarr; Kafka Service
Clients connecting in to Kafka may be any of:

* A Kafka producer
* A Kafka consumer
* A Kafka Admin client

Note that many applications are a combination of many of these - notably Streams applications and Kafka Connect.

* Client JAAS:
    * Login Context: `KafkaClient`
    * Can use *kinit* or *keytab* method.
    * Example: [client/client.sasl.jaas.config](client/client.sasl.jaas.config)
* Client Properties:
    * `sasl.kerberos.service.name={kafka-kerberos-service-name}`
    * `security.protocol={security-protocol}`
    * `sasl.jaas.config` - jaas override.
    * Examples: [client/producer.properties](client/producer.properties), [client/consumer.properties](client/consumer.properties), [client/command.properties](client/command.properties)


### Client &rarr; Zookeeper (Optional)
Historically, clients needed to connect directly to ZooKeeper for service discovery and admin operations.
However, the new Kafka Admin API allows all this functionality via Client &rarr; Kafka Broker connection, so this direct connection should not be required.

* JAAS:
   * LoginContext: `Client`
   * Can use *kinit* or *keytab* method.

 * JVM flags:
     * `-Dzookeeper.sasl.client.username={zookeeper-kerberos-service-name}` (OPTIONAL)

### Confluent Metrics Reporter &rarr; Kafka Service (Optional)

The Confluent metrics reporter runs as a plugin within the Kafka broker, but from a Kerberos point of view is configured as a network client.
The configuration, including inline Jaas, is specified within the broker properties using a keytab:

* `confluent.metrics.reporter.sasl.mechanism=GSSAPI`
* `confluent.metrics.reporter.security.protocol={security-protocol}`
* `confluent.metrics.reporter.sasl.kerberos.service.name={kafka-kerberos-service-name}`
* `confluent.metrics.reporter.sasl.jaas.config={inline jaas configuration}`
* Example: [kafka/server.properties](kafka/server.properties)

# Authentication is not enough!

The steps above are sufficient to support Kerberos authenticated connections within the cluster.
This does not make your cluster secure though!
The demo also applies a minimal level of authorisation to prevent unauthenticated network access to the brokers and Zookeeper.
The following should be reviewed in the broker server properties:

* `allow.everyone.if.no.acl.found=false` - default to no access.
* `authorizer.class.name=kafka.security.auth.SimpleAclAuthorizer` - enable the default authoriser for Kafka.
* `zookeeper.set.acl=true` - when storing ACL data in Zookeeper, apply Zookeeper access controls so that only the Broker &rarr; Zookeeper client principal can read and modify the lists.
* Example: [kafka/server.properties](kafka/server.properties)

# Putting it into action

In this demo we configure:

* A simple KDC to generate principals and keytabs.
* A single node Zookeeper with a Kerberized data access API.
* A single node Kafka broker with a Kerberized listener.
* Set up ACLs allowing `kafka-console-producer` and `kafka-console-consumer` usage.

_A basic knowledge of Docker is useful to follow the code, though only basic Docker techniques are used to keep the code readable._
_Each node is built using a `Dockerfile` into which configuration values are hard-coded, and the services are brought up using `docker-compose`._
_Kerberos keytabs and the krb5.conf file are shared amongst all nodes on the cluster using a shared Docker volume._

The demo is run using the [up](up) script, which orchestrates the following process:

* Builds and starts the KDC.
All nodes are joined to the KDC's realm by sharing `krb5.conf` amongst all nodes.
* Generates Kerberos principals and keytabs, sharing these on the shared Docker volume.
* Builds and starts Zookeeper, Kafka broker and Client.
* Uses the `admin` super user to configure ACLs for the `producer` and `consumer` users.
* Prints example usage to connect into Kafka with a Kerberos principal.
This is actually executed via the `client` node.

# Next up

* Extending Kerberos configuration to a full cluster (coming soon)
* Hardening access controls


# References

* https://www.youtube.com/watch?v=KD2Q-2ToloE Video overview of Kerberos authentication process.
