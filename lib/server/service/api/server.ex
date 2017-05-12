defmodule Helix.Server.Service.API.Server do

  alias HELL.Constant
  alias Helix.Server.Controller.Server, as: ServerController
  alias Helix.Server.Model.Server
  alias Helix.Server.Repo

  @spec create(Constant.t) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates a server of given type
  """
  def create(server_type) do
    ServerController.create(%{server_type: server_type})
  end

  @spec fetch(HELL.PK.t) ::
    Server.t
    | nil
  @doc """
  Fetches a server
  """
  def fetch(server_id) do
    ServerController.fetch(server_id)
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

  @spec attach(Server.t, HELL.PK.t) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Attaches a motherboard to the server

  This function will fail if either the `motherboard_id` or the `server`
  are attached
  """
  def attach(server, motherboard_id) do
    ServerController.attach(server, motherboard_id)
  end

  @spec detach(Server.t) ::
    :ok
  @doc """
  Detaches the motherboard linked to server

  This function is idempotent
  """
  def detach(server) do
    ServerController.detach(server)
  end

  @spec delete(Server.t) ::
    {:ok, Server.t}
    | {:error, reason :: term}
  @doc """
  Deletes `server`
  """
  def delete(server) do
    # TODO: Use an idempotent query
    Repo.delete(server)
  end
end
