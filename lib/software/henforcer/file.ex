defmodule Helix.Software.Henforcer.File do

  import Helix.Henforcer

  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Software
  alias Helix.Software.Henforcer.Storage, as: StorageHenforcer
  alias Helix.Software.Query.File, as: FileQuery

  @type file_exists_relay :: %{file: File.t}
  @type file_exists_relay_partial :: %{}
  @type file_exists_error ::
    {false, {:file, :not_found}, file_exists_relay_partial}

  @spec file_exists?(File.id) ::
    {true, file_exists_relay}
    | file_exists_error
  def file_exists?(file_id = %File.ID{}) do
    with file = %{} <- FileQuery.fetch(file_id) do
      reply_ok(relay(%{file: file}))
    else
      _ ->
        reply_error({:file, :not_found})
    end
  end

  @type belongs_to_server_relay :: %{file: File.t, server: Server.t}
  @type belongs_to_server_relay_partial :: file_exists_relay
  @type belongs_to_server_error ::
    {false, {:file, :not_belongs}, belongs_to_server_relay_partial}
    | file_exists_error

  @spec belongs_to_server?(File.idt, Server.id) ::
    {true, belongs_to_server_relay}
    | belongs_to_server_error
  @doc """
  Verifies whether the given file belongs to the server.
  """
  def belongs_to_server?(file_id = %File.ID{}, server_id) do
    henforce(file_exists?(file_id)) do
      belongs_to_server?(relay.file, server_id)
    end
  end

  def belongs_to_server?(file = %File{}, server_id) do
    henforce_else(
      StorageHenforcer.belongs_to_server?(file.storage_id, server_id),
      {:file, :not_belongs}
    )
  end

  @type exists_software_module_relay :: %{server: Server.t, file: File.t}
  @type exists_software_module_relay_partial :: %{server: Server.t}
  @type exists_software_module_error ::
    {false, {:module, :not_found}, exists_software_module_relay_partial}

  @spec exists_software_module?(File.Module.name, Server.t) ::
    {true, exists_software_module_relay}
    | exists_software_module_error
  @doc """
  Henforces that at least one file with the given software module exists on the
  server, sorting by the module version (so it automatically fetches the best
  software of that module/type on the server).
  """
  def exists_software_module?(module, server = %Server{}) do
    with file = %{} <- FileQuery.fetch_best(server.server_id, module) do
      reply_ok(%{file: file})
    else
      _ ->
        reply_error({:module, :not_found})
    end
    |> wrap_relay(%{server: server})
  end

  @type is_virus_relay :: %{file: File.t}
  @type is_virus_relay_partial :: is_virus_relay
  @type is_virus_error ::
    {false, {:file, :not_virus}, is_virus_relay_partial}
    | file_exists_error

  @spec is_virus?(File.idt) ::
    {true, is_virus_relay}
    | is_virus_error
  def is_virus?(file_id = %File.ID{}) do
    henforce file_exists?(file_id) do
      is_virus?(relay.file)
    end
  end

  def is_virus?(file = %File{software_type: type}) do
    if Software.Type.is_virus?(type) do
      reply_ok()
    else
      reply_error({:file, :not_virus})
    end
    |> wrap_relay(%{file: file})
  end
end
