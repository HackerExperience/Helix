defmodule Helix.Server.Query.Server do

  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Server.Model.Server
  alias Helix.Server.Repo

  @spec fetch(HELL.PK.t) ::
    Server.t
    | nil
  @doc """
  Fetches a server
  """
  def fetch(server_id) do
    ServerInternal.fetch(server_id)
  end

  @spec fetch_by_motherboard(HELL.PK.t) ::
    Server.t
    | nil
  @doc """
  Fetches the server that mounts the `motherboard`
  """
  def fetch_by_motherboard(motherboard) do
    Repo.get_by(Server, motherboard_id: motherboard)
  end
end
