defmodule Helix.Network.Query.Network do

  alias Helix.Network.Model.Network
  alias Helix.Network.Repo

  @spec fetch(Network.id) ::
    Network.t
    | nil
  def fetch(id),
    do: Repo.get(Network, id)

  @spec internet() ::
    Network.t
  @doc """
  Returns the record for the global network called "The Internet"
  """
  def internet,
    do: Repo.get(Network, "::")
end
