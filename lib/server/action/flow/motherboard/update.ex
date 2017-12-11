# TODO: Move to motherboard action (outside flow)
defmodule Helix.Server.Action.Motherboard.Update do

  import HELL.Macros

  alias Helix.Network.Action.Network, as: NetworkAction
  alias Helix.Network.Model.Network
  alias Helix.Server.Repo, as: ServerRepo

  alias Helix.Server.Query.Component, as: ComponentQuery

  alias Helix.Server.Internal.Motherboard, as: MotherboardInternal

  def update(nil, mobo_data, entity_ncs) do
    {:ok, new_mobo} =
      MotherboardInternal.setup(mobo_data.mobo, mobo_data.components)

    hespawn fn ->
      update_network_connections(mobo_data, entity_ncs)
    end

    {:ok, new_mobo, []}
  end

  def update(
    motherboard,
    mobo_data,
    entity_ncs)
  do
    {:ok, {:ok, new_mobo}} =
      ServerRepo.transaction fn ->
        MotherboardInternal.unlink_all(motherboard)
        MotherboardInternal.setup(mobo_data.mobo, mobo_data.components)
      end

    hespawn fn ->
      update_network_connections(mobo_data, entity_ncs)
    end

    {:ok, new_mobo, []}
  end

  defp update_network_connections(mobo_data, entity_ncs) do
    # Secondary index used to figure out whether a specific NIP was specified on
    # `mobo_data.network_connections`.
    assigned_nips =
      Enum.reduce(mobo_data.network_connections, [], fn {_, nip}, acc ->
        acc ++ [nip]
      end)

    entity_ncs

    # Get the required operations we may have to do on NetworkConnections...
    |> Enum.reduce([], fn nc, acc ->
        cond do
          # The NIC already has an NC attached to it
          Map.has_key?(mobo_data.network_connections, nc.nic_id) ->
            nip = mobo_data.network_connections[nc.nic_id]

            # The given NC is the same as before; we don't have to do anything
            if {nc.network_id, nc.ip} == nip do
              acc

            # There will be a new NC attached to this NIC, so we have to
            # remove the previous NC reference to this NIC, as it's no longer
            # used. Certainly we'll also have to update the new NC to point
            # to this NIC. That's done on another iteration at :set_nic below
            else
              acc ++ [{:nilify_nic, nc}]
            end

          # TODO: What if NIP is in use? Henforce!
          # The current NC nic is not in use, but its nip is being assigned.
          # This means the NC will start being used, so we need to link it to
          # the underlying NIC.
          {nc.network_id, nc.ip} in assigned_nips ->
            {nic_id, _} =
              mobo_data.network_connections
              |> Enum.find(fn {_, {network_id, ip}} ->
                  network_id == nc.network_id and ip == nc.ip
                end)

            acc ++ [{:set_nic, nc, nic_id}]

          # This NC is not modified at all by the mobo update
          true ->
            acc

        end
      end)

    # Perform those NetworkConnection operations
    |> Enum.each(&perform_network_op/1)
  end

  defp perform_network_op({:nilify_nic, nc = %Network.Connection{}}),
    do: {:ok, _} = NetworkAction.Connection.update_nic(nc, nil)
  defp perform_network_op({:set_nic, nc = %Network.Connection{}, nic_id}) do
    nic = ComponentQuery.fetch(nic_id)

    {:ok, _} = NetworkAction.Connection.update_nic(nc, nic)
  end
end
