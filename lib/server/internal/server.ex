defmodule Helix.Server.Internal.Server do

  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Server.Model.Server
  alias Helix.Server.Repo

  @typep repo_return ::
    {:ok, Server.t}
    | {:error, Server.changeset}

  @spec fetch(Server.id) ::
    Server.t
    | nil
  def fetch(id),
    do: Repo.get(Server, id)

  @spec fetch_by_motherboard(Motherboard.idt) ::
    Server.t
    | nil
  def fetch_by_motherboard(motherboard) do
    motherboard
    |> Server.Query.by_motherboard()
    |> Repo.one()
  end

  @spec create(Server.creation_params) ::
    repo_return
  def create(params) do
    params
    |> Server.create_changeset()
    |> Repo.insert()
  end

  @spec set_hostname(Server.t, Server.hostname) ::
    repo_return
  @doc """
  Updates the server hostname.
  """
  def set_hostname(server, hostname) do
    server
    |> Server.set_hostname(hostname)
    |> update()
  end

  @spec attach(Server.t, Motherboard.id) ::
    repo_return
  def attach(server, mobo_id) do
    result =
      server
      |> Server.update_changeset(%{motherboard_id: mobo_id})
      |> Repo.update()

    with {:ok, _} <- result do
      CacheAction.update_server(server)
    end

    result
  end

  @spec detach(Server.t) ::
    :ok
  def detach(server = %Server{}) do
    server
    |> Server.detach_motherboard()
    |> Repo.update!()

    CacheAction.purge_component(server.motherboard_id)
    CacheAction.update_server(server)

    :ok
  end

  @spec delete(Server.t) ::
    :ok
  def delete(server) do
    Repo.delete(server)

    CacheAction.purge_server(server)

    :ok
  end

  @spec update(Server.changeset) ::
    repo_return
  defp update(changeset),
    do: Repo.update(changeset)
end
