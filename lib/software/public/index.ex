defmodule Helix.Software.Public.Index do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Software
  alias Helix.Software.Model.Storage
  alias Helix.Software.Query.Storage, as: StorageQuery

  @type index ::
    %{
      Storage.id => %{
        name: Storage.name,
        filesystem: filesystem
      }
    }

  @type rendered_index ::
    %{
      String.t => %{
        name: String.t,
        filesystem: rendered_filesystem
      }
    }

  @type filesystem ::
    %{File.path => filesystem_file}

  @type filesystem_file ::
    %{
      file_id: File.id,
      path: File.full_path,
      size: File.size,
      software_type: File.type,
      modules: map
    }

  @type rendered_filesystem ::
    %{path :: String.t => rendered_filesystem_file}

  @type rendered_filesystem_file ::
    %{
      id: String.t,
      path: String.t,
      size: File.size,
      type: String.t,
      modules: modules,
      name: String.t,
      extension: String.t
    }

  @typep modules ::
    [
      %{
        name: String.t,
        version: pos_integer
      }
    ]

  @spec index(Server.id) ::
    index
  def index(server_id) do
    {:ok, storage_ids} = CacheQuery.from_server_get_storages(server_id)

    storage_ids
    |> Enum.reduce(%{}, fn storage_id, acc ->
      storage_data =
        %{
          name: "/dev/sda",
          filesystem: StorageQuery.storage_contents(storage_id)
        }

      Map.put(%{}, storage_id, storage_data)
      |> Map.merge(acc)
    end)
  end

  @spec index(index) ::
    rendered_index
  def render_index(index) do
    Enum.reduce(index, %{}, fn {storage_id, storage_data}, acc ->

      rendered_fs =
        Enum.reduce(storage_data.filesystem, %{}, fn {folder, files}, acc2 ->
          rendered_files = Enum.map(files, &render_file/1)

          Map.put(acc2, folder, rendered_files)
        end)

      rendered_data =
        %{
          filesystem: rendered_fs,
          name: storage_data.name
        }

      %{}
      |> Map.put(to_string(storage_id), rendered_data)
      |> Map.merge(acc)
    end)
  end

  @spec render_file(File.t) ::
    rendered_filesystem_file
  def render_file(file = %File{}) do
    extension = Software.Type.get(file.software_type).extension |> to_string()

    render_modules =
      fn modules ->
        Enum.reduce(modules, %{}, fn {module, data}, acc ->
          %{}
          |> Map.put(to_string(module), %{version: data.version})
          |> Map.merge(acc)
        end)
      end

    %{
      id: to_string(file.file_id),
      path: file.path,
      size: file.file_size,
      type: to_string(file.software_type),
      modules: render_modules.(file.modules),
      name: to_string(file.name),
      extension: extension
    }
  end
end
