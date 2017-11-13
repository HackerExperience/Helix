defmodule Helix.Server.Make.Server do

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Action.Flow.Server, as: ServerFlow
  alias Helix.Server.Model.Server

  @type server_data ::
    %{
      type: Server.type
    }

  @doc """
  Data:

  - *type: Server type. `:desktop`, `:mobile`.
  - hardware: Specs?
  """
  def server(entity = %Entity{}, data) do
    if data.type != :desktop,
      do: raise "pls wait server refactor"

    {:ok, server} = ServerFlow.setup_server(entity)
    server
  end
end
