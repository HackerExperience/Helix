defmodule Helix.Software.Henforcer.File do

  import Helix.Henforcer

  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Software.Henforcer.Storage, as: StorageHenforcer
  alias Helix.Software.Query.File, as: FileQuery

  @spec file_exists?(File.id) ::
    {true, %{file: File.t}}
    | {false, {:file, :not_found}, %{}}
  def file_exists?(file_id = %File.ID{}) do
    with file = %{} <- FileQuery.fetch(file_id) do
      reply_ok(relay(%{file: file}))
    else
      _ ->
        reply_error({:file, :not_found})
    end
  end

  @spec belongs_to_server?(File.idt, Server.id) ::
    {true, %{file: File.t}}
    | {false, {:file, :not_found}, %{}}
    | {false, {:file, :not_belongs}, %{file: File.t}}
  @doc """
  Verifies whether the given file belongs to the server.
  """
  def belongs_to_server?(file_id = %File.ID{}, server_id) do
    henforce(file_exists?(file_id)) do
      belongs_to_server?(relay.file, server_id)
    end
  end

  def belongs_to_server?(file = %File{}, server_id) do
    r1 = %{file: file}

    case StorageHenforcer.belongs_to_server?(file.storage_id, server_id) do
      {true, r2} ->
        reply_ok(relay(r1, r2))

      {false, _, r2} ->
        {false, {:file, :not_belongs}, relay(r1, r2)}
    end
  end

  defmodule Cracker do

    alias HELL.IPv4
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server

    @spec can_bruteforce(Server.id, IPv4.t, Network.id, IPv4.t) ::
      :ok
      | {:error, {:target, :self}}
    def can_bruteforce(_source_id, source_ip, _network_id, target_ip) do
      # TODO: Check for noob protection
      if source_ip == target_ip do
        {:error, {:target, :self}}
      else
        :ok
      end
    end
  end

  defmodule Transfer do
    @moduledoc """
    Verifications related to file transfers.
    """

    import Helix.Henforcer

    alias Helix.Server.Model.Server
    alias Helix.Software.Model.File
    alias Helix.Software.Model.Storage
    alias Helix.Software.Henforcer.File, as: FileHenforcer
    alias Helix.Software.Henforcer.Storage, as: StorageHenforcer

    @type transfer :: :download | :upload

    @spec can_transfer?(transfer, Server.id, Server.id, Storage.id, File.id) ::
      {true, %{file: File.t, storage: Storage.t}}
      | {false, {:file, :not_belongs | :not_found}, term}
      | {false, {:storage, :full | :not_found}, term}
    @doc """
    Verifies the FileTransfer can be made.

    Checks:
    - File being transferred must come/go from/to a different server.
    - The file belongs to the origin server
    - The target storage can accommodate the file size
    + indirect checks along the way
    """
    def can_transfer?(type, gateway_id, endpoint_id, storage_id, file_id) do
      {origin_id, target_id} =
        if type == :download do
          {endpoint_id, gateway_id}
        else
          {gateway_id, endpoint_id}
        end

      with \
         true <- gateway_id != endpoint_id || :self_target,
        {true, %{file: file}} <-
           FileHenforcer.belongs_to_server?(file_id, origin_id),
        {true, %{storage: storage}} <-
          StorageHenforcer.belongs_to_server?(storage_id, target_id),
        {true, _} <- StorageHenforcer.has_enough_space?(storage, file)
      do
        {true, relay(%{storage: storage, file: file})}
      else
        :self_target ->
          {false, {:target, :self}, %{}}
        error ->
          error
      end
    end
  end
end
