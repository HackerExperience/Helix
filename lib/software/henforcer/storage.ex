defmodule Helix.Software.Henforcer.Storage do

  import Helix.Henforcer

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Henforcer.File, as: FileHenforcer
  alias Helix.Software.Query.Storage, as: StorageQuery

  @spec storage_exists?(Storage.id) ::
    {true, %{storage: Storage.t}}
    | {false, {:storage, :not_found}, %{}}
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

  @spec has_enough_space?(Storage.idt, File.idt) ::
    {true, %{storage: Storage.t, file: File.t}}
    | {false, {:storage, :full}, %{storage: Storage.t, file: File.t}}
    | {false, {:storage, :not_found}, %{}}
    | {false, {:file, :not_found}, %{}}
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

  @spec belongs_to_server?(Storage.idt, Server.id) ::
    {true, %{storage: Storage.t}}
    | {false, {:storage, :not_belongs}, %{}}
    | {false, {:server, :not_found}, %{}}
  @doc """
  Verifies whether the given storage belongs to the server.
  """
  def belongs_to_server?(storage_id = %Storage.ID{}, server_id) do
    henforce storage_exists?(storage_id) do
      belongs_to_server?(relay.storage, server_id)
    end
  end

  def belongs_to_server?(storage = %Storage{}, server_id) do
    with \
      {:ok, owner_id} <- CacheQuery.from_storage_get_server(storage),
      true <- owner_id == server_id || :not_belongs
    do
      reply_ok(relay(%{storage: storage}))
    else
      :not_belongs ->
        reply_error({:storage, :not_belongs})
      _ ->
        reply_error({:server, :not_found})
    end
  end
end
