defmodule Helix.Test.Channel.Helper do

  def server_topic_name(network_id, ip, counter \\ 0) do
    network_id = to_string(network_id)
    counter = to_string(counter)

    "server:" <> network_id <> "@" <> ip <> "#" <> counter
  end
end
