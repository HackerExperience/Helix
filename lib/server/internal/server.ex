defmodule Helix.Server.Internal.Server do

  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Server.Model.Server
  alias Helix.Server.Repo

  @spec fetch(Server.id) ::
    Server.t
    | nil
  def fetch(server_id) do
    server_id
    |> Server.Query.by_server()
    |> Repo.one
  end

  @spec fetch_by_motherboard(Motherboard.t | Motherboard.id) ::
    Server.t
    | nil
  def fetch_by_motherboard(motherboard) do
    motherboard
    |> Server.Query.by_motherboard()
    |> Repo.one()
  end

  @spec create(Server.creation_params) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> Server.create_changeset()
    |> Repo.insert()
  end

  @spec attach(Server.t, Motherboard.id) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
  def attach(server, mobo_id) do
    result = server
      |> Server.update_changeset(%{motherboard_id: mobo_id})
      |> Repo.update()

    with {:ok, _} <- result do
      CacheAction.update_server(server)
    end

    result
  end

  @spec detach(Server.t | Server.id) ::
    :ok
  def detach(server = %Server{}) do
    server
    |> Server.Query.by_server()
    |> Repo.update_all(set: [motherboard_id: nil])

    CacheAction.purge_component(server.motherboard_id)
    CacheAction.update_server(server)

    :ok
    end
  def detach(server_id) do
    server_id
    |> fetch()
    |> detach()
  end

  @spec delete(Server.t | Server.id) ::
    :ok
  def delete(server) do
    server
    |> Server.Query.by_server()
    |> Repo.delete_all()

    CacheAction.purge_server(server)

    :ok
  end
end
