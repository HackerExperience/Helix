defmodule Helix.Server.Action.Component.NIC do

  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Component
  alias Helix.Server.Internal.Component, as: ComponentInternal

  def update(
    nic = %Component{},
    custom = %{network_id: %Network.ID{}, ulk: _, dlk: _})
  do
    ComponentInternal.update_custom(nic, custom)
  end

  def update_network_id(nic = %Component{}, network_id = %Network.ID{}),
    do: ComponentInternal.update_custom(nic, %{network_id: network_id})

  def update_transfer_speed(nic = %Component{}, %{dlk: dlk, ulk: ulk}),
    do: ComponentInternal.update_custom(nic, %{dlk: dlk, ulk: ulk})
end
