defmodule RigKafka.NetworkOutageTest do
  @moduledoc """
  Recovery test that shows how RIG deals with a network outage.

  This test suite is not run by ExUnit, but invoked from an external script via remsh.
  The reason is that we need Docker to simulate a network fault, and we cannot do that
  using more than one RIG node when running on the host, so the RIG nodes need to be
  run inside containers as well. The actual test code is then invoked by the test
  script - running on the host - using a remote shell to execute code inside the RIG
  instances.

  """
  alias RigKafka

  @doc """
  Test setup, designed to run on the Docker _host_.
  """
  def setup_two_nodes_and_one_broker_and_one_topic_and_one_partition do
    # set up two docker networks for kafka, one for RIG nodes
    # run the kafka broker, assign both Kafka networks
    # run two RIG instances, one in each Kafka network + connected to RIG network
    # (remsh) connect RIG instances with each other
  end

  def a_connection_loss_causes_the_partition_to_be_reassigned_to_the_other_node do
    # (remsh) check that on node 1 RigKafka is ready
    # (remsh) check that on node 2 RigKafka is ready

    # remove one Kafka network from Kafka broker

    # (remsh) check that one of the node has lost connection

    # produce Kafka message (starting/using brod's default client)
    # assert that the message went through

    # remove other Kafka network from Kafka broker

    # produce another Kafka message
    # refute that the message went through

    # reconnect the first Kafka network to the broker

    # produce a third Kafka message
    # assert that the message came through again (what happens to the second message??)
  end
end
