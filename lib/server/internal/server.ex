defmodule Helix.Server.Internal.Server do

  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Server.Model.Motherboard
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

  @spec create(Server.type) ::
    repo_return
  def create(server_type) do
    %{type: server_type}
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
    |> Repo.update()
  end

  @spec attach(Server.t, Motherboard.id) ::
    repo_return
  @doc """
  Updates the `server` motherboard to be `mobo_id`.

  It doesn't matter if the server already has a motherboard attached to it; this
  operation will overwrite any existing motherboard.
  """
  def attach(server, mobo_id) do
    result =
      server
      |> Server.attach_motherboard(mobo_id)
      |> Repo.update()

    with {:ok, _} <- result do
      CacheAction.update_server(server)
    end

    result
  end

  @spec detach(Server.t) ::
    repo_return
  @doc """
  Detaches the currently attached motherboard from `server`

  It doesn't matter if the server has no motherboard attached to it.
  """
  def detach(server = %Server{}) do
    result =
      server
      |> Server.detach_motherboard()
      |> Repo.update()

    with {:ok, _} <- result do
      CacheAction.update_server(server)
    end

    result
  end

  @spec delete(Server.t) ::
    :ok
  def delete(server) do
    Repo.delete(server)

    CacheAction.purge_server(server)

    :ok
  end
end
