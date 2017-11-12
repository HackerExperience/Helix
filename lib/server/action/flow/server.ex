defmodule Helix.Server.Action.Flow.Server do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Entity.Model.Entity
  alias Helix.Hardware.Action.Flow.Hardware, as: HardwareFlow
  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Server.Model.Server

  @spec setup_server(Entity.t) ::
    {:ok, Server.t}
  def setup_server(entity) do
    flowing do
      with \
        {:ok, server} <- ServerAction.create(:desktop),
        on_fail(fn -> ServerAction.delete(server) end),

        {:ok, motherboard_id} <- HardwareFlow.setup_bundle(entity),

        {:ok, server} <- ServerAction.attach(server, motherboard_id),
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
