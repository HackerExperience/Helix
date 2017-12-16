defmodule Helix.Server.Action.Flow.Server do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Action.Motherboard, as: MotherboardAction
  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Motherboard
  alias Helix.Server.Model.Server

  alias Helix.Server.Event.Motherboard.Updated, as: MotherboardUpdatedEvent
  alias Helix.Server.Event.Motherboard.UpdateFailed,
    as: MotherboardUpdateFailedEvent

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
    motherboard,
    new_mobo_data,
    entity_ncs,
    relay)
  do
    new_mobo_id = new_mobo_data.mobo.component_id

    flowing do
      with \
        {:ok, new_motherboard, events} <-
          MotherboardAction.update(motherboard, new_mobo_data, entity_ncs),
        on_success(fn -> Event.emit(events, from: relay) end),

        {:ok, new_server} <- update_server_mobo(server, new_mobo_id)
      do
        emit_motherboard_updated(new_server, relay)

        {:ok, new_server, new_motherboard}
      else
        _ ->
          emit_motherboard_update_failed(server, :internal, relay)
      end
    end
  end

  def detach_mobo(server = %Server{}, motherboard = %Motherboard{}, relay) do
    flowing do
      with \
        :ok <- MotherboardAction.detach(motherboard),
        {:ok, new_server} <- ServerAction.detach(server)
      do
        emit_motherboard_updated(new_server, relay)

        {:ok, new_server}
      else
        _ ->
          emit_motherboard_update_failed(server, :internal, relay)
      end
    end
  end

  defp update_server_mobo(server = %Server{motherboard_id: mobo_id}, mobo_id),
    do: {:ok, server}
  defp update_server_mobo(server, mobo_id),
    do: ServerAction.attach(server, mobo_id)

  defp emit_motherboard_updated(server, relay) do
    server
    |> MotherboardUpdatedEvent.new()
    |> Event.emit(from: relay)
  end

  defp emit_motherboard_update_failed(server, reason, relay) do
    server
    |> MotherboardUpdateFailedEvent.new(reason)
    |> Event.emit(from: relay)
  end
end
