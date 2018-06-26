defmodule Helix.Test.Software.Helper do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Software
  alias Helix.Software.Model.Storage
  alias Helix.Software.Model.Virus
  alias Helix.Software.Query.Storage, as: StorageQuery
  alias Helix.Software.Repo, as: SoftwareRepo

  alias HELL.TestHelper.Random

  @doc """
  Returns raw DB entry for testing/debugging.
  """
  def raw_get(virus = %Virus{}),
    do: SoftwareRepo.get(Virus, virus.file_id)
  def raw_get(virus = %Virus{}, :active),
    do: SoftwareRepo.get(Virus.Active, virus.file_id)

  @doc """
  Returns the first `Storage.t` of the given server
  """
  def get_storage(server = %Server{}),
    do: get_storage(server.server_id)
  def get_storage(server_id = %Server.ID{}) do
    server_id
    |> get_storage_id()
    |> StorageQuery.fetch()
  end

  def get_storage(storage_id = %Storage.ID{}) do
    storage_id
    |> StorageQuery.fetch()
  end

  @doc """
  Returns the first `Storage.id` of the given server
  """
  def get_storage_id(server_id) do
    server_id
    |> CacheQuery.from_server_get_storages()
    |> elem(1)
    |> List.first()
  end

  @doc """
  Generates the expected module for the given type.

  Example of expected input:
    (:cracker, %{bruteforce: 20, overflow: 10})
  """
  def generate_module(type, version_map) do
    modules = Software.Type.get(type).modules

    Enum.reduce(modules, %{}, fn (module, acc) ->
      version = Map.fetch!(version_map, module)

      module
      |> generate_file_module(version)
      |> Map.merge(acc)
    end)
  end

  @doc """
  Returns modules with random versions for the given file.
  """
  def get_modules(type) do
    modules = Software.Type.get(type).modules

    Enum.reduce(modules, %{}, fn (module, acc) ->
      module
      |> generate_file_module(random_version())
      |> Map.merge(acc)
    end)
  end

  @doc """
  Returns the software extension
  """
  def get_extension(file = %File{}),
    do: get_extension(file.software_type)
  def get_extension(type) when is_atom(type) do
    type
    |> Software.Type.get()
    |> Map.fetch!(:extension)
  end

  defp generate_file_module(module, version) do
    data = File.Module.Data.new(%{name: module, version: version})

    Map.put(%{}, module, data)
  end

  def random_file_size,
    do: Enum.random(1..200)

  def random_file_name,
    do: Burette.Color.name()

  def random_file_path do
    1..5
    |> Random.repeat(fn -> Burette.Internet.username() end)
    |> Enum.join("/")
  end

  def random_file_type,
    do: Enum.random(Software.Type.all())

  def random_version,
    do: Random.number(min: 10, max: 50)

  def random_extension,
    do: random_file_type() |> get_extension()

  @doc """
  Generates a `File.ID`
  """
  def id,
    do: File.ID.generate()

  @doc """
  FileModel performs some operation on the file path, like ensuring leading
  slashes and removing trailing slashes. We try to mock this internal formatting
  so our tests can verify the resulting path.
  """
  def format_path(path) do
    path
    |> add_leading_slash()
    |> remove_trailing_slash()
  end

  defp add_leading_slash(path = "/" <> _),
    do: path
  defp add_leading_slash(path),
    do: "/" <> path

  defp remove_trailing_slash(path) do
    path_size = (byte_size(path) - 1) * 8

    case path do
      <<path::bits-size(path_size)>> <> "/" ->
        <<path::bits-size(path_size)>>
      path ->
        path
    end
  end
end
