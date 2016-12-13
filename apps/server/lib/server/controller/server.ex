defmodule HELM.Server.Controller.Server do

  alias HELF.Broker
  alias HELM.Server.Repo
  alias HELM.Server.Model.Server, as: MdlServer, warn: false
  import Ecto.Query, only: [where: 3]

  @spec create(MdlServer.creation_params) :: {:ok, MdlServer.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> MdlServer.create_changeset()
    |> Repo.insert()
  end

  @spec find(HELL.PK.t) :: {:ok, MdlServer.t} | {:error, :notfound}
  def find(server_id) do
    case Repo.get_by(MdlServer, server_id: server_id) do
      nil ->
        {:error, :notfound}
      server ->
      {:ok, server}
    end
  end

  @spec update(HELL.PK.t, MdlServer.update_params) :: {:ok, MdlServer.t} | {:error, :notfound | Ecto.Changeset.t}
  def update(server_id, params) do
    with {:ok, server} <- find(server_id) do
      server
      |> MdlServer.update_changeset(params)
      |> Repo.update()
    end
  end

  @spec delete(HELL.PK.t) :: no_return
  def delete(server_id) do
    MdlServer
    |> where([s], s.server_id == ^server_id)
    |> Repo.delete_all()

    :ok
  end

  @spec attach(server :: HELL.PK.t, motherboard :: HELL.PK.t) :: {:ok, MdlServer.t} | {:error, reason :: term}
  def attach(server_id, mobo_id) do
    with \
      {:ok, server} <- find(server_id),
      {_, {:ok, _}} <- Broker.call("hardware:get", {:motherboard, mobo_id})
    do
      server
      |> MdlServer.update_changeset(%{motherboard_id: mobo_id})
      |> Repo.update()
    end
  end

  @spec detach(HELL.PK.t) :: {:ok, MdlServer.t} | {:error, Ecto.Changeset.t} | {:error, :notfound}
  def detach(server_id) do
    with {:ok, server} <- find(server_id) do
      server
      |> MdlServer.update_changeset(%{motherboard_id: nil})
      |> Repo.update()
    end
  end
end