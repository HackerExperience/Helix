defmodule Helix.Server.Action.Motherboard.Update do

  import HELL.Macros

  alias Helix.Network.Action.Network, as: NetworkAction
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Server.Action.Component, as: ComponentAction
  alias Helix.Server.Model.Motherboard
  alias Helix.Server.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Server.Query.Component, as: ComponentQuery
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery
  alias Helix.Server.Repo, as: ServerRepo

  @internet_id NetworkQuery.internet().network_id

  def detach(motherboard = %Motherboard{}) do
    MotherboardInternal.unlink_all(motherboard)

    hespawn fn ->
      motherboard
      |> MotherboardQuery.get_nics()
      |> Enum.each(fn nic ->
        nc = NetworkQuery.Connection.fetch_by_nic(nic.component_id)

        if nc do
          perform_network_op({:nilify_nic, nc})
        end
      end)
    end

    :ok
  end

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
    ncs = mobo_data.network_connections

    entity_ncs

    # Get the required operations we may have to do on NetworkConnections...
    |> Enum.reduce([], fn nc, acc ->
        cond do
          # The NIC already has an NC attached to it
          mobo_nc = has_nic?(ncs, nc.nic_id) ->
            # The given NC is the same as before; we don't have to do anything
            if nc == mobo_nc.network_connection do
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
          mobo_nc = has_nip?(ncs, nc.network_id, nc.ip) ->
            acc ++ [{:set_nic, nc, mobo_nc.nic_id}]

          # This NC is not modified at all by the mobo update
          true ->
            acc
        end
      end)

    # Perform those NetworkConnection operations
    |> Enum.each(&perform_network_op/1)
  end

  defp has_nic?(ncs, nic_id),
    do: Enum.find(ncs, &(&1.nic_id == nic_id))

  defp has_nip?(ncs, network_id, ip),
    do: Enum.find(ncs, &(&1.network_id == network_id and &1.ip == ip))

  defp perform_network_op({:nilify_nic, nc = %Network.Connection{}}),
    do: {:ok, _} = NetworkAction.Connection.update_nic(nc, nil)
  defp perform_network_op({:set_nic, nc = %Network.Connection{}, nic_id}) do
    nic = ComponentQuery.fetch(nic_id)

    {:ok, _} = NetworkAction.Connection.update_nic(nc, nic)

    # Update the NIC custom
    # Note that by default the NIC is assumed to belong to the internet, that's
    # why we'll only update it in case it's on a different network.
    unless nc.network_id == @internet_id do
      ComponentAction.NIC.update_network_id(nic, nc.network_id)
    end
  end
end
