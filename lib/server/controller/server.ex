defmodule Helix.Server.Controller.Server do

  alias HELL.Constant
  alias Helix.Server.Model.Server
  alias Helix.Server.Repo

  import Ecto.Query, only: [where: 3]

  @type find_param ::
    {:id, [HELL.PK.t]}
    | {:type, Constant.t}

  @spec create(Server.creation_params) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> Server.create_changeset()
    |> Repo.insert()
  end

  @spec fetch(HELL.PK.t) :: Server.t | nil
  def fetch(server_id),
    do: Repo.get(Server, server_id)

  @spec find([find_param], meta :: []) :: [Server.t]
  def find(params, _meta \\ []) do
    params
    |> Enum.reduce(Server, &reduce_find_params/2)
    |> Repo.all()
  end

  @spec update(Server.t, Server.update_params) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
  def update(server, params) do
    server
    |> Server.update_changeset(params)
    |> Repo.update()
  end

  @spec delete(HELL.PK.t) :: no_return
  def delete(server_id) do
    Server
    |> where([s], s.server_id == ^server_id)
    |> Repo.delete_all()

    :ok
  end

  @spec attach(Server.t, motherboard :: HELL.PK.t) ::
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

  @spec reduce_find_params(find_param, Ecto.Queryable.t) :: Ecto.Queryable.t
  defp reduce_find_params({:id, id_list}, query),
    do: Server.Query.from_id_list(query, id_list)
  defp reduce_find_params({:type, type}, query),
    do: Server.Query.by_type(query, type)
end
