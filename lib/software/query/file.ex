defmodule Helix.Software.Query.File do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Internal.File, as: FileInternal

  @spec fetch(File.id) ::
    File.t
    | nil
  defdelegate fetch(file_id),
    to: FileInternal

  @spec storage_contents(Storage.t) ::
    %{folder :: File.path => [File.t]}
  def storage_contents(storage) do
    storage
    |> FileInternal.get_files_on_target_storage()
    |> Enum.group_by(&(&1.path))
  end

  @spec files_on_storage(Storage.t) ::
    [File.t]
  defdelegate files_on_storage(storage),
    to: FileInternal,
    as: :get_files_on_target_storage

  @spec get_modules(File.t) ::
    File.modules
  defdelegate get_modules(file),
    to: FileInternal

  @spec fetch_best(Server.id, File.type, File.module_name) ::
    File.t
    | nil
  @doc """
  API helper to allow querying using a server ID.

  Future enhancement: find the best software of the server by looking at *all*
  storages
  """
  def fetch_best(server_id = %Server.ID{}, type, module) do
    {:ok, storages} = CacheQuery.from_server_get_storages(server_id)

    fetch_best(List.first(storages), type, module)
  end

  # TODO: I won't actually implement `fetch_best` because I think `file_modules`
  # will change a lot. Adapt this function once `file_modules` is refactored.
  # Note on refactor: we'll need to query modules based on their version, so
  # throwing them into a JSON might not be a good idea.
  @spec fetch_best(Storage.t, File.type, File.module_name) ::
    File.t
    | nil
  @doc """
  Fetches the best software on the `storage` that matches the given `type`,
  sorting by `module` version
  """
  def fetch_best(storage, type, _module) do
    files_of_type =
      storage
      |> files_on_storage()
      |> Enum.filter(&(&1.software_type == type))

    # @Charlots I believe it's a lot easier to sort on the DB.
    # Get all software of type CRC on storage S, then sort by version.
    # No need to index the version, everything has been filtered beforehand.
    # Leaving this comment here so we can discuss the `file_modules` refactor

    # Guaranteed to be the best
    List.first(files_of_type)
  end
end
