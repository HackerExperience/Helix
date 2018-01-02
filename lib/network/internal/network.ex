defmodule Helix.Network.Internal.Network do

  alias Helix.Network.Model.Network
  alias Helix.Network.Repo

  def fetch(network_id = %Network.ID{}) do
    network_id
    |> Network.Query.by_id()
    |> Repo.one()
  end

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
  def delete(network = %Network{type: :internet}),
    do: raise "One does not simply delete the Internet"
  def delete(network = %Network{}) do
    network
    |> Repo.delete()

    :ok
  end
end
