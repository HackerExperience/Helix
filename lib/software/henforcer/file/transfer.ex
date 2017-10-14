defmodule Helix.Software.Henforcer.File.Transfer do
  @moduledoc """
  Henforcers related to file transfer.
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
