defmodule Helix.Server.Internal.Server do

  alias Helix.Hardware.Model.Component
  alias Helix.Server.Model.Server
  alias Helix.Server.Repo

  import Ecto.Query, only: [where: 3]

  @spec create(Server.creation_params) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> Server.create_changeset()
    |> Repo.insert()
  end

  @spec fetch(Server.id) ::
    Server.t
    | nil
  def fetch(server_id),
    do: Repo.get(Server, server_id)

  @spec fetch_by_motherboard(Component.id) ::
    Server.t
    | nil
  def fetch_by_motherboard(motherboard_id) do
    motherboard_id
    |> Server.Query.by_motherboard()
    |> Repo.one()
  end

  @spec delete(Server.id) ::
    :ok
  def delete(server_id) do
    Server
    |> where([s], s.server_id == ^server_id)
    |> Repo.delete_all()

    :ok
  end

  @spec attach(Server.t, Component.id) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
  def attach(server, mobo_id) do
    server
    |> Server.update_changeset(%{motherboard_id: mobo_id})
    |> Repo.update()
  end

  @spec detach(Server.t) ::
    :ok
  def detach(%Server{server_id: id}),
    do: detach(id)
  def detach(server) do
    server
    |> Server.Query.by_id()
    |> Repo.update_all(set: [motherboard_id: nil])

    :ok
  end
end
