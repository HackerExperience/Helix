defmodule Helix.Server.WS.Routes do

  alias HELF.Router

  @routes %{
    "server.create" => %{
      broker: "server.create",
      atoms: ~w/server_type poi_id motherboard_id/a
    },
    "server.fetch" => %{
      broker: "server.fetch",
      atoms: ~w/server_id/a
    },
    "server.attach" => %{
      broker: "server.create",
      atoms: ~w/server motherboard_id/a
    },
    "server.detach" => %{
      broker: "server.detach",
      atoms: ~w/server/a
    }
  }

  def register_routes do
    Enum.each(@routes, fn {topic, params} ->
      Router.register(topic, params.broker, params.atoms)
    end)
  end
end
