defmodule Helix.Test.Network.Setup.Connection do

  alias Ecto.Changeset
  alias Helix.Network.Model.Network
  alias Helix.Network.Repo, as: NetworkRepo

  alias HELL.TestHelper.Random
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

    changeset = Network.Connection.create_changeset(network_id, ip, nic_id)

    nc = Changeset.apply_changes(changeset)

    related =
      %{
        changeset: changeset,
        network_id: network_id,
        ip: ip,
        nic: nic
      }

    {nc, related}
  end
end
