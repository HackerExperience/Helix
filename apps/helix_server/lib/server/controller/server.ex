defmodule Helix.Server.Controller.Server do

  alias HELF.Broker
  alias Helix.Server.Model.Server
  alias Helix.Server.Repo

  import Ecto.Query, only: [where: 3]

  @type find_param ::
    {:id, [HELL.PK.t]}
    | {:type, String.t}

  @spec create(Server.creation_params) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
    | {:error, reason :: term}
  def create(params) do
    params
    |> Server.create_changeset()
    |> Repo.insert()
  end

  @spec fetch(HELL.PK.t) :: Server.t | nil
  def fetch(server_id),
    do: Repo.get(Server, server_id)

  @spec fetch_by_poi(HELL.PK.t) :: Server.t | nil
  def fetch_by_poi(poi_id),
    do: Repo.get_by(Server, poi_id: poi_id)

  @spec find([find_param], meta :: []) :: [Server.t]
  def find(params, _meta \\ []) do
    params
    |> Enum.reduce(Server, &reduce_find_params/2)
    |> Repo.all()
  end

  @spec update(Server.t, Server.update_params) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
    | {:error, reason :: term}
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
    | {:error, reason :: term}
  def attach(server, mobo_id) do
    msg = %{component_type: :motherboard, component_id: mobo_id}
    {_, result} = Broker.call("hardware.component.get", msg)

    case result do
      {:ok, _} ->
        server
        |> Server.update_changeset(%{motherboard_id: mobo_id})
        |> Repo.update()
      _ ->
        {:error, :internal}
    end
  end

  @spec detach(Server.t) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
    | {:error, reason ::term}
  def detach(server) do
    server
    |> Server.update_changeset(%{motherboard_id: nil})
    |> Repo.update()
  end

  @spec reduce_find_params(find_param, Ecto.Queryable.t) :: Ecto.Queryable.t
  defp reduce_find_params({:id, id_list}, query),
    do: Server.Query.from_id_list(query, id_list)
  defp reduce_find_params({:type, type}, query),
    do: Server.Query.by_type(query, type)
end
