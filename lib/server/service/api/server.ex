defmodule Helix.Server.Service.API.Server do

  alias HELL.Constant
  alias Helix.Server.Controller.Server, as: ServerController
  alias Helix.Server.Model.Server

  @doc """
  Creates a server of given type

  Optionally accepts a point of interest
  """
  @spec create(Constant.t, HELL.PK.t | nil) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
  def create(server_type, poi_id \\ nil) do
    ServerController.create(%{server_type: server_type, poi_id: poi_id})
  end

  @spec fetch(HELL.PK.t) :: Server.t | nil
  @doc """
  Fetches a server
  """
  def fetch(server_id) do
    ServerController.fetch(server_id)
  end

  @spec find([ServerController.find_param], meta :: []) :: [Server.t]
  @doc """
  Search for servers

  ## Params

    * `:id` - filters by ids within a list
    * `:type` - filters by type
  """
  def find(params, meta \\ []) do
    ServerController.find(params, meta)
  end

  @doc """
  Attaches a motherboard to the server

  This function will fail if either the `motherboard_id` or the `server`
  are attached
  """
  @spec attach(Server.t, HELL.PK.t) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
  def attach(server, motherboard_id) do
    ServerController.attach(server, motherboard_id)
  end

  @doc """
  Detaches the motherboard linked to server

  This function is idempotent
  """
  @spec detach(Server.t) ::
    :ok
  def detach(server) do
    ServerController.detach(server)
  end
end
