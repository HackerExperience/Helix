defmodule Helix.Server.Controller.Server do

  alias HELF.Broker
  alias Helix.Server.Model.Server
  alias Helix.Server.Repo

  import Ecto.Query, only: [where: 3]

  @spec create(Server.creation_params) :: {:ok, Server.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> Server.create_changeset()
    |> Repo.insert()
  end

  @spec find(HELL.PK.t) :: {:ok, Server.t} | {:error, :notfound}
  def find(server_id) do
    case Repo.get_by(Server, server_id: server_id) do
      nil ->
        {:error, :notfound}
      server ->
      {:ok, server}
    end
  end

  @spec update(HELL.PK.t, Server.update_params) :: {:ok, Server.t} | {:error, :notfound | Ecto.Changeset.t}
  def update(server_id, params) do
    with {:ok, server} <- find(server_id) do
      server
      |> Server.update_changeset(params)
      |> Repo.update()
    end
  end

  @spec delete(HELL.PK.t) :: no_return
  def delete(server_id) do
    Server
    |> where([s], s.server_id == ^server_id)
    |> Repo.delete_all()

    :ok
  end

  @spec attach(server :: HELL.PK.t, motherboard :: HELL.PK.t) :: {:ok, Server.t} | {:error, reason :: term}
  def attach(server_id, mobo_id) do
    with \
      {:ok, server} <- find(server_id),
      msg = %{component_type: :motherboard, component_id: mobo_id},
      {_, {:ok, _}} <- Broker.call("hardware:get", msg)
    do
      server
      |> Server.update_changeset(%{motherboard_id: mobo_id})
      |> Repo.update()
    end
  end

  @spec detach(HELL.PK.t) :: {:ok, Server.t} | {:error, Ecto.Changeset.t} | {:error, :notfound}
  def detach(server_id) do
    with {:ok, server} <- find(server_id) do
      server
      |> Server.update_changeset(%{motherboard_id: nil})
      |> Repo.update()
    end
  end
end