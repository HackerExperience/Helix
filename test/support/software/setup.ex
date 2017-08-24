defmodule Helix.Test.Software.Setup do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper

  @doc """
  Generates a bunch of files

  total: Set total of files to be generated. Defaults to 5
  file_opts: Opts of the files that will be created
  """
  def random_files(opts \\ []) do
    upper = Access.get(opts, :total, 5)
    1..upper
    |> Enum.map(fn _ -> file(opts[:file_opts])  end)
  end

  def random_files!(opts \\ []) do
    files = random_files(opts)

    files
    |> Enum.map(&(elem(&1, 0)))
  end

  @doc """
  See doc on `fake_file/1`
  """
  def file(opts \\ []) do
    {_, related = %{params: params}} = fake_file(opts)
    {:ok, inserted} = FileInternal.create(params)
    {:ok, inserted} = FileInternal.set_modules(inserted, params.modules)

    # Sync here because internally we used a CacheQuery. If we don't, any tests
    # calling `SoftwareSetup.[random_]file` would have to sync, and in some
    # cases it wouldn't be obvious why they are required to sync
    CacheHelper.sync_test()

    {inserted, related}
  end

  def file!(opts \\ []) do
    {file, _} = file(opts)
    file
  end

  @doc """
  - name: Set file name
  - size: Set file size
  - type: Set file type. SoftwareType.t
  - path: Set file path
  - module: Set file module. If set, `type` must also be set.
  - server_id: Server that file belongs to. Will use the first storage it finds.
  - fake_storage: Whether to use a fake storage. Defaults to true. In case a
    real storage is generated, the underlying server will be generated too.

  Related: File.creation_params, Storage.id, Server.id
  """
  def fake_file(opts \\ []) do
    if not is_nil(opts[:modules]) and is_nil(opts[:type]) do
      raise "You can't specify a module and ask for a random file type."
    end

    size = Access.get(opts, :size, Enum.random(1..1_048_576))
    name = Access.get(opts, :name, SoftwareHelper.random_file_name())
    path = Access.get(opts, :path, SoftwareHelper.random_file_path())
    type = Access.get(opts, :type, SoftwareHelper.random_file_type())
    modules = Access.get(opts, :modules, SoftwareHelper.get_modules(type))

    {storage_id, server_id} =
      cond do
        opts[:server_id] ->
        {:ok, storages} =
          CacheQuery.from_server_get_storages(opts[:server_id])

          {List.first(storages), opts[:server_id]}
        opts[:fake_storage] == false ->
          server = ServerSetup.server!()
        {:ok, storages} =
          CacheQuery.from_server_get_storages(server.server_id)

          {List.first(storages), server}
        true ->
          # TODO: This needs some polishing in order to work. But that's good
          # enough for my use case now. If you, dear reader, happens to need the
          # fake file with real storage, please implement it.
          {Storage.ID.generate(), nil}
      end

    params = %{
      file_size: size,
      name: name,
      software_type: type,
      path: path,
      storage_id: storage_id,
      modules: modules
    }

    file = File.create_changeset(params)

    {file, %{params: params, storage_id: storage_id, server_id: server_id}}
  end
end
