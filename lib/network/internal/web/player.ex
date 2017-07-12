defmodule Helix.Network.Internal.DNS do

  alias Helix.Network.Model.DNS.Unicast
  alias Helix.Network.Model.DNS.Anycast
  alias Helix.Network.Repo

  @spec register_unicast(Unicast.creation_params) ::
    {:ok, Unicast.t}
    | {:error, Ecto.Changeset.t}
  def register_unicast(params) do
    params
    |> Unicast.create_changeset()
    |> Repo.insert
  end

  @spec deregister_unicast(String.t) :: no_return
  def deregister_unicast(name) do
    name
    |> Unicast.Query.by_name()
    |> Repo.delete_all()

    :ok
  end

  @spec register_anycast(Anycast.creation_params) ::
    {:ok, Anycast.t}
    | {:error, Ecto.Changeset.t}
  def register_anycast(params) do
    params
    |> Anycast.create_changeset()
    |> Repo.insert
  end

  @spec deregister_anycast(String.t) :: no_return
  def deregister_anycast(name) do
    name
    |> Anycast.Query.by_name()
    |> Repo.delete_all()

    :ok
  end

  @spec lookup_unicast(String.t) :: Unicast.t | nil
  def lookup_unicast(name) do
    name
    |> Unicast.Query.by_name()
    |> Repo.one
  end

  @spec lookup_anycast(String.t) :: Anycast.t | nil
  def lookup_anycast(name) do
    name
    |> Anycast.Query.by_name()
    |> Repo.one
  end
end
