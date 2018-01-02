defmodule Helix.Network.Internal.Network do

  alias Helix.Network.Model.Network
  alias Helix.Network.Repo

  @spec fetch(Network.id) ::
    Network.t
    | nil
  def fetch(network_id = %Network.ID{}) do
    network_id
    |> Network.Query.by_id()
    |> Repo.one()
  end

  @spec create(Network.name, Network.type) ::
    {:ok, Network.t}
    | {:error, Network.changeset}
  def create(name, type) do
    params = %{
      name: name,
      type: type
    }

    params
    |> Network.create()
    |> Repo.insert()
  end

  @spec delete(Network.t) ::
    :ok
    | no_return
  def delete(%Network{type: :internet}),
    do: raise "One does not simply delete the Internet"
  def delete(network = %Network{}) do
    network
    |> Repo.delete()

    :ok
  end
end
