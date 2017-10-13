defmodule Helix.Software.Henforcer.Storage do

  import Helix.Henforcer

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Model.Server
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Henforcer.File, as: FileHenforcer
  alias Helix.Software.Query.Storage, as: StorageQuery

  @type storage_exists_relay :: %{storage: Storage.t}
  @type storage_exists_relay_partial :: %{}
  @type storage_exists_error ::
    {false, {:storage, :not_found}, storage_exists_relay_partial}

  @spec storage_exists?(Storage.id) ::
    {true, storage_exists_relay}
    | storage_exists_error
  @doc """
  Ensures the requested storage exists on the database.
  """
  def storage_exists?(storage_id = %Storage.ID{}) do
    with storage = %{} <- StorageQuery.fetch(storage_id) do
      {true, relay(%{storage: storage})}
    else
      _ ->
        reply_error({:storage, :not_found})
    end
  end

  @type has_enough_space_relay :: %{storage: Storage.t, file: File.t}
  @type has_enough_space_relay_partial :: has_enough_space_relay
  @type has_enough_space_error ::
    {false, {:storage, :full}, has_enough_space_relay_partial}
    | storage_exists_error
    | FileHenforcer.file_exists_error

  @spec has_enough_space?(Storage.idt, File.idt) ::
    {true, has_enough_space_relay}
    | has_enough_space_error
  @doc """
  Verifies whether the given storage has enough space left to store `file`
  """
  def has_enough_space?(storage_id = %Storage.ID{}, file) do
    henforce storage_exists?(storage_id) do
      has_enough_space?(relay.storage, file)
    end
  end

  def has_enough_space?(storage, file_id = %File.ID{}) do
    henforce FileHenforcer.file_exists?(file_id) do
      has_enough_space?(storage, relay.file)
    end
  end

  def has_enough_space?(storage = %Storage{}, file = %File{}) do
    relay = %{storage: storage, file: file}

    # TODO #279
    reply_ok(relay)
  end

  @type belongs_to_server_relay :: %{storage: Storage.t, server: Server.t}
  @type belongs_to_server_relay_partial :: belongs_to_server_relay
  @type belongs_to_server_error ::
    {false, {:storage, :not_belongs}, belongs_to_server_relay_partial}

  @spec belongs_to_server?(Storage.idt, Server.idt) ::
    {true, belongs_to_server_relay}
    | belongs_to_server_error
  @doc """
  Verifies whether the given storage belongs to the server.
  """
  def belongs_to_server?(storage_id = %Storage.ID{}, server_id) do
    henforce storage_exists?(storage_id) do
      belongs_to_server?(relay.storage, server_id)
    end
  end

  def belongs_to_server?(storage, server_id = %Server.ID{}) do
    henforce ServerHenforcer.server_exists?(server_id) do
      belongs_to_server?(storage, relay.server)
    end
  end

  def belongs_to_server?(storage = %Storage{}, server = %Server{}) do
    relay = %{server: server, storage: storage}

    with \
      {:ok, owner_id} <- CacheQuery.from_storage_get_server(storage),
      true <- owner_id == server.server_id || :not_belongs
    do
      reply_ok(relay)
    else
      _ ->
        reply_error({:storage, :not_belongs},  relay)
    end
  end
end
