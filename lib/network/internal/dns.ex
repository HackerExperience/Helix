defmodule Helix.Network.Internal.DNS do

  alias Helix.Network.Model.DNS.Anycast
  alias Helix.Network.Model.DNS.Unicast
  alias Helix.Network.Model.Network
  alias Helix.Network.Repo

  @spec lookup_unicast(Network.idt, String.t) ::
    Unicast.t
    | nil
  def lookup_unicast(network, name) do
    network
    |> Unicast.Query.by_net_and_name(name)
    |> Repo.one()
  end

  @spec lookup_anycast(String.t) ::
    Anycast.t
    | nil
  def lookup_anycast(name) do
    name
    |> Anycast.Query.by_name()
    |> Repo.one()
  end

  @spec register_unicast(Unicast.creation_params) ::
    {:ok, Unicast.t}
    | {:error, Ecto.Changeset.t}
  def register_unicast(params) do
    params
    |> Unicast.create_changeset()
    |> Repo.insert()
  end

  @spec deregister_unicast(Network.idt, String.t) ::
    :ok
  def deregister_unicast(network, name) do
    network
    |> Unicast.Query.by_net_and_name(name)
    |> Repo.delete_all()

    :ok
  end

  @spec register_anycast(Anycast.creation_params) ::
    {:ok, Anycast.t}
    | {:error, Ecto.Changeset.t}
  def register_anycast(params) do
    params
    |> Anycast.create_changeset()
    |> Repo.insert()
  end

  @spec deregister_anycast(String.t) ::
    :ok
  def deregister_anycast(name) do
    name
    |> Anycast.Query.by_name()
    |> Repo.delete_all()

    :ok
  end
end
