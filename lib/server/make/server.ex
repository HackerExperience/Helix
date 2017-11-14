defmodule Helix.Server.Make.Server do

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Action.Flow.Server, as: ServerFlow
  alias Helix.Server.Model.Server

  @spec desktop(Entity.t) ::
    Server.t
  def desktop(entity = %Entity{}),
    do: server(entity, :desktop)

  @spec server(Entity.t, Server.type) ::
    Server.t
  defp server(entity = %Entity{}, _type) do
    # if type != :desktop,
    #   do: raise "pls wait server refactor"

    {:ok, server} = ServerFlow.setup_server(entity)
    server
  end
end
