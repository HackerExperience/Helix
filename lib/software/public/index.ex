defmodule Helix.Software.Public.Index do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Software.Public.View.File, as: FileView
  alias Helix.Software.Query.File, as: FileQuery

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
    |> Enum.map(&FileQuery.storage_contents/1)
    |> Enum.reduce(%{}, fn el, acc ->
      # Merge the maps, so %{"foo" => [1]} and %{"foo" => [2]} becomes
      # %{"foo" => [1, 2]}
      Map.merge(acc, el, fn _k, v1, v2 -> v1 ++ v2 end)
    end)
    |> Enum.map(fn {path, files} ->
      {path, Enum.map(files, &FileView.render/1)}
    end)
    |> :maps.from_list()
  end

  @spec index(index) ::
    rendered_index
  def render_index(index) do
    Enum.reduce(index, %{}, fn {folder, files}, acc ->
      rendered_files =
        Enum.map(files, fn entry ->
          %{
            file_id: to_string(entry.file_id),
            path: entry.path,
            size: entry.size,
            software_type: to_string(entry.software_type),
            modules: entry.modules
          }
        end)

      Map.put(acc, folder, rendered_files)
    end)
  end
end
