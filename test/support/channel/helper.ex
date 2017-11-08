defmodule Helix.Test.Channel.Helper do

  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server

  def server_topic_name(server_id = %Server.ID{}),
    do: "server:" <> to_string(server_id)
  def server_topic_name(network_id = %Network.ID{}, ip, counter \\ 0) do
    network_id = to_string(network_id)
    counter = to_string(counter)

    "server:" <> network_id <> "@" <> ip <> "#" <> counter
  end
end
