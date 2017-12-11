defmodule Helix.Server.Action.Flow.Server do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Action.Motherboard, as: MotherboardAction
  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Server

  @spec setup(Server.type, Entity.t, Component.mobo, Event.relay) ::
    {:ok, Server.t}
  @doc """
  Creates a new server of `type`. The server's motherboard must be passed.

  Currently does not emit anything.
  """
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

  def update_mobo(
    server = %Server{},
    cur_mobo_data,
    new_mobo_data,
    entity_ncs,
    relay)
  do
    new_mobo_id = new_mobo_data.mobo.component_id

    flowing do
      with \
        {:ok, new_mobo, events} <-
          MotherboardAction.update(
            cur_mobo_data, new_mobo_data, entity_ncs
          ),
        on_success(fn -> Event.emit(events, from: relay) end),

        {:ok, new_server} <- update_server_mobo(server, new_mobo_id)
      do
        {:ok, new_server, new_mobo}
      end
    end
  end

  defp update_server_mobo(%Server{motherboard_id: mobo_id}, mobo_id),
    do: {:ok, mobo_id}
  defp update_server_mobo(server, nil),
    do: ServerAction.detach(server)
  defp update_server_mobo(server, mobo_id),
    do: ServerAction.attach(server, mobo_id)
end
