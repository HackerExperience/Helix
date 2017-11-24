defmodule Helix.Server.Action.Flow.Server do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Server

  @spec setup(Server.type, Entity.t, Component.mobo, Event.relay) ::
    {:ok, Server.t}
  def setup(type, entity = %Entity{}, mobo = %Component{type: :mobo}, _relay) do
    flowing do
      with \
        {:ok, server} <- ServerAction.create(type),
        on_fail(fn -> ServerAction.delete(server) end),

        {:ok, server} <- ServerAction.attach(server, mobo.component_id),
        on_fail(fn -> ServerAction.detach(server) end),

        {:ok, _} <- EntityAction.link_server(entity, server),
        on_fail(fn -> EntityAction.unlink_server(server) end)
      do
        {:ok, server}
      end
    end
  end

  @spec set_hostname(Server.t, Server.hostname, Event.relay) ::
    {:ok, Server.t}
    | {:error, :internal}
  @doc """
  Updates the server hostname.

  Currently does not emit anything.
  """
  def set_hostname(server, hostname, _relay),
    do: ServerAction.set_hostname(server, hostname)
end
