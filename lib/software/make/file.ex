defmodule Helix.Software.Make.File do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Model.Server
  alias Helix.Software.Action.File, as: FileAction
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Software
  alias Helix.Software.Model.Storage

  def cracker(parent, modules, data \\ %{}),
    do: file(parent, :cracker, modules, data)

  defp file(server = %Server{}, type, modules, data) do
    server
    |> CacheQuery.from_server_get_storages!()
    |> List.first()
    |> file(type, modules, data)
  end

  defp file(storage_id = %Storage.ID{}, type, modules, data) do
    path = Map.get(data, :path, File.Default.path())

    modules = format_modules(type, modules)

    params =
      %{
        name: File.Default.name(type, modules),
        software_type: type,
        path: path,
        file_size: File.Default.size(type, modules),
        storage_id: storage_id
      }

    # TODO: Flow
    {:ok, file} = FileAction.create(params, modules)
    file
  end

  def format_modules(type, version_map) do
    modules = Software.Type.get(type).modules

    Enum.reduce(modules, %{}, fn (module, acc) ->
      version = Map.fetch!(version_map, module)
      data = File.Module.Data.new(%{version: version})

      %{}
      |> Map.put(module, data)
      |> Map.merge(acc)
    end)
  end
end
