defmodule Helix.Test.Server.State.Helper do

  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server

  @ets_table_server :ets_server_websocket_channel_server
  @ets_table_entity :ets_server_websocket_channel_entity

  def lookup_server(server_id) do
    @ets_table_server
    |> :ets.lookup(to_string(server_id))
    |> result_or_false()
  end

  def lookup_entity(entity_id) do
    @ets_table_entity
    |> :ets.lookup(to_string(entity_id))
    |> result_or_false()
  end

  defp result_or_false([]),
    do: false
  defp result_or_false([result]),
    do: result

  def cast_server_entry(false),
    do: false
  def cast_server_entry(entry) do
    {server_id, entry_channels} = entry

    channels =
      Enum.map(entry_channels, fn {{network_id, ip}, counter} ->
        %{
          network_id: Network.ID.cast!(network_id),
          ip: ip,
          counter: counter
        }
      end)

    %{
      server_id: Server.ID.cast!(server_id),
      channels: channels
    }
  end

  def cast_entity_entry(false),
    do: false
  def cast_entity_entry(entry) do
    {entity_id, entry_servers} = entry

    servers =
      Enum.map(entry_servers, fn {server_id, {network_id, ip}, counter} ->
        %{
          server_id: Server.ID.cast!(server_id),
          network_id: Network.ID.cast!(network_id),
          ip: ip,
          counter: counter
        }
      end)

    %{
      entity_id: Entity.ID.cast!(entity_id),
      servers: servers
    }
  end
end
