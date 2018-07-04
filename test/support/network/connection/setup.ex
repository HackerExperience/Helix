defmodule Helix.Test.Network.Setup.Connection do

  alias Ecto.Changeset
  alias Helix.Network.Model.Network
  alias Helix.Network.Repo, as: NetworkRepo

  alias HELL.TestHelper.Random
  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Server.Component.Setup, as: ComponentSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper

  @internet_id NetworkHelper.internet_id()

  @doc """
  See doc on `fake_connection/1`
  """
  def connection(opts \\ []) do
    {_, related = %{changeset: changeset}} = fake_connection(opts)
    {:ok, inserted} = NetworkRepo.insert(changeset)
    {inserted, related}
  end

  @doc """
  Opts:
  - network_id: Set network id. Defaults to internet id.
  - ip: Set NC ip. Defaults to randomly generated IP
  - nic_id: Set NC nic. Defaults to nil
  - real_nic: Whether to generate a real nic. Defaults to false
  - entity_id: Which entity owns that NetworkConnection. Defaults to random one.
  """
  def fake_connection(opts \\ []) do
    network_id = Keyword.get(opts, :network_id, @internet_id)
    ip = Keyword.get(opts, :ip, Random.ipv4())

    {nic_id, nic} =
      cond do
        opts[:nic_id] ->
          {opts[:nic_id], nil}

        opts[:real_nic] ->
          {nic, _} = ComponentSetup.component(type: :nic)
          {nic.component_id, nic}

        true ->
          {nil, nil}
      end

    entity_id = Keyword.get(opts, :entity_id, EntityHelper.id())

    params =
      %{
        network_id: network_id,
        ip: ip,
        nic_id: nic_id,
        entity_id: entity_id
      }

    changeset = Network.Connection.create_changeset(params)

    nc = Changeset.apply_changes(changeset)

    related =
      %{
        params: params,
        changeset: changeset,
        network_id: network_id,
        ip: ip,
        nic: nic
      }

    {nc, related}
  end
end
