defmodule Helix.Server.Action.Component.NIC do

  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Component
  alias Helix.Server.Internal.Component, as: ComponentInternal

  def update_network_id(nic = %Component{}, network_id = %Network.ID{}) do
    nic
    |> ComponentInternal.update_custom(%{network_id: network_id})
  end

  def update_transfer_speed(nic = %Component{}, dlk: dlk, ulk: ulk) do
    nic
    |> ComponentInternal.update_custom(%{dlk: dlk, ulk: ulk})
  end
end
