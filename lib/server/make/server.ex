defmodule Helix.Server.Make.Server do

  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Server.Action.Flow.Server, as: ServerFlow
  alias Helix.Server.Action.Flow.Motherboard, as: MotherboardFlow
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery

  @type net_data ::
    %{
      network: Network.t,
      ip: Network.ip,
      speed: %{dlk: pos_integer, ulk: pos_integer}
    }

  @spec desktop(Entity.t, net_data) ::
    {:ok, Server.t, %{}}
  def desktop(entity = %Entity{}, net_data),
    do: server(entity, :desktop, net_data)

  @spec npc(Entity.t, net_data) ::
    {:ok, Server.t, %{}}
  def npc(entity = %Entity{}, net_data),
    do: server(entity, :npc, net_data)

  @spec server(Entity.t, Server.type, net_data | nil) ::
    {:ok, Server.t, %{}}
  defp server(entity = %Entity{}, type, net_data) do
    relay = nil

    # Setup mobo. TODO: Custom hardware for NPC
    {:ok, motherboard, mobo} = MotherboardFlow.initial_hardware(entity, relay)

    {:ok, server} = ServerFlow.setup(type, entity, mobo, relay)

    # `net_data` specifies what NIP that server should get, as well as its speed
    # It may be empty (`nil`) though you most likely never want that.
    if net_data do
      [nic] = MotherboardQuery.get_nics(motherboard)

      {:ok, _, _} =
        MotherboardFlow.setup_network(
          entity, nic, net_data.network, net_data.ip, net_data.speed
        )
    end

    {:ok, server, %{}}
  end
end
