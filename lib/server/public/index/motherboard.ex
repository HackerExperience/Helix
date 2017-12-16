defmodule Helix.Server.Public.Index.Motherboard do

  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Server.Model.Motherboard
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery

  @type index ::
    %{
      motherboard_id: Motherboard.id | nil,
      network_connections: [Network.Connection.t]
    }

  @type rendered_index ::
    %{
      motherboard_id: String.t,
      slots: rendered_slots,
      network_connections: rendered_network_connections
    }

  @typep rendered_slots ::
    %{
      slot_id :: String.t => %{
        type: String.t,
        component_id: String.t
      }
    }

  @typep rendered_network_connections ::
    %{
      nic_id :: String.t => %{
        network_id: String.t,
        ip: String.t
      }
    }

  @spec index(Server.t) ::
    index
  def index(%Server{motherboard_id: nil}) do
    %{
      motherboard_id: nil,
      network_connections: []
    }
  end

  def index(server = %Server{}) do
    motherboard = MotherboardQuery.fetch(server.motherboard_id)

    network_connections =
      motherboard
      |> MotherboardQuery.get_nics()
      |> Enum.reduce([], fn nic, acc ->

        if nic do
          nc = NetworkQuery.Connection.fetch_by_nic(nic)

          acc ++ [nc]
        else
          acc
        end
      end)

    %{
      motherboard: motherboard,
      network_connections: network_connections,
    }
  end

  @spec render_index(Server.t) ::
    rendered_index
  def render_index(%{motherboard_id: nil}) do
    %{
      motherboard_id: nil,
      slots: %{},
      network_connections: %{}
    }
  end

  def render_index(index) do
    %{
      motherboard_id: to_string(index.motherboard.motherboard_id),
      slots: render_slots(index.motherboard),
      network_connections: render_network_connections(index.network_connections)
    }
  end

  @spec render_slots(Motherboard.t) ::
    rendered_slots
  defp render_slots(motherboard = %Motherboard{}) do
    used_slots =
      motherboard.slots
      |> Enum.map(fn {slot_id, component} ->
        comp_data =
          %{
            type: to_string(component.type),
            component_id: to_string(component.component_id)
          }

        {to_string(slot_id), comp_data}
      end)
      |> Enum.into(%{})

    free_slots =
      motherboard
      |> MotherboardQuery.get_free_slots()
      |> Enum.reduce(%{}, fn {comp_type, free_slots}, acc ->
        free_slots
        |> Enum.map(fn slot_id ->

          {to_string(slot_id), %{type: to_string(comp_type), component_id: nil}}
        end)
        |> Enum.into(%{})
        |> Map.merge(acc)
      end)

    Map.merge(used_slots, free_slots)
  end

  @spec render_network_connections([Network.Connection.t]) ::
    rendered_network_connections
  defp render_network_connections(network_connections) do
    network_connections
    |> Enum.reduce(%{}, fn nc, acc ->
      client_nip =
        %{
          network_id: to_string(nc.network_id),
          ip: nc.ip
        }

      %{}
      |> Map.put(to_string(nc.nic_id), client_nip)
      |> Map.merge(acc)
    end)
  end
end
