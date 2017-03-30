defmodule Helix.Server.Service.API.Server do

  alias Helix.Server.Controller.Server, as: ServerController
  alias Helix.Server.Model.Server

  @doc """
  Creates a server, requires valid `server_type` and `poi_id` (point of
  interest id), optionally accepts a `motherboard_id` that is linked to
  the server at the moment of creation
  """
  def create(server_type, poi_id, motherboard_id \\ nil) do
    params = %{
      server_type: server_type,
      poi_id: poi_id,
      motherboard_id: motherboard_id
    }

    create(params)
  end

  @spec create(Server.creation_params) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
  def create(params) do
    ServerController.create(params)
  end

  @spec fetch(HELL.PK.t) :: Server.t | nil
  @doc """
  Fetches Server data by its `id`
  """
  def fetch(server_id) do
    ServerController.fetch(server_id)
  end

  @spec find([Server.find_params], meta :: []) :: [Server.t]
  @doc """
  Search for servers

  ## Options

    * `:id` - filters by ids within a list
    * `:type` - filters by type
  """
  def find(params, meta \\ []) do
    ServerController.find(params, meta)
  end

  @doc """
  Attaches a Motherboard to the Server

  This function will fail with already attached motherboards and servers
  """
  @spec attach(Server.t, HELL.PK.t) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
    | {:error, reason :: term}
  def attach(server, motherboard_id) do
    ServerController.attach(server, motherboard_id)
  end

  @doc """
  Detaches any attached Motherboard from a Server

  This function is idempotent at best
  """
  @spec detach(Server.t) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
  def detach(server) do
    ServerController.detach(server)
  end
end
