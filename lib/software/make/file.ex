defmodule Helix.Software.Make.File do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Model.Server
  alias Helix.Software.Action.File, as: FileAction
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Software
  alias Helix.Software.Model.Storage

  @type modules :: cracker_modules

  @type cracker_modules :: %{bruteforce: version, overflow: version}

  @type data :: %{optional(:path) => File.path}

  @typep file_parent :: Server.t | Storage.id
  @typep version :: File.Module.version

  @doc """
  Generates a cracker.
  """
  @spec cracker(file_parent, cracker_modules, data) ::
    File.t_of_type(:cracker)
  def cracker(parent, modules, data \\ %{}),
    do: file(parent, :cracker, modules, data)

  @spec file(file_parent, Software.type, modules, data) ::
    File.t
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

    {:ok, file} = FileAction.create(params, modules)
    file
  end

  @spec format_modules(Software.type, modules) ::
    File.Module.t | term  # Requires OTP 20.1 or higher
  defp format_modules(type, version_map) do
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
