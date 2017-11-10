defmodule Helix.Software.Public.Index do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Software.Query.Storage, as: StorageQuery

  @type index ::
    %{File.path => index_file}

  @type index_file ::
    %{
      file_id: File.id,
      path: File.full_path,
      size: File.size,
      software_type: File.type,
      modules: map
    }

  @type rendered_index ::
    %{path :: String.t => rendered_index_file}

  @type rendered_index_file ::
    %{
      file_id: String.t,
      path: String.t,
      size: File.size,
      software_type: String.t,
      modules: map
    }

  @spec index(Server.id) ::
    index
  def index(server_id) do
    {:ok, storages} = CacheQuery.from_server_get_storages(server_id)

    storages
    |> Enum.map(&StorageQuery.storage_contents/1)
    |> Enum.reduce(%{}, fn el, acc ->
      # Merge the maps, so %{"foo" => [1]} and %{"foo" => [2]} becomes
      # %{"foo" => [1, 2]}
      Map.merge(acc, el, fn _k, v1, v2 -> v1 ++ v2 end)
    end)
  end

  @spec index(index) ::
    rendered_index
  def render_index(index) do
    Enum.reduce(index, %{}, fn {folder, files}, acc ->
      rendered_files = Enum.map(files, &render_file/1)

      Map.put(acc, folder, rendered_files)
    end)
  end

  @spec render_file(File.t) ::
    rendered_index_file
  def render_file(file = %File{}) do
    %{
      file_id: to_string(file.file_id),
      path: file.full_path,
      size: file.file_size,
      software_type: to_string(file.software_type),
      modules: file.modules
    }
  end
end
