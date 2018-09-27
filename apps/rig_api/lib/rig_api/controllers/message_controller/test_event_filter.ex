defmodule RigApi.MessageController.TestEventFilter do
  @moduledoc false

  def forward_event(cloud_event) do
    send(self(), {:cloud_event_sent, cloud_event})
  end
end
