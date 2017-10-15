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

  @type can_transfer_relay ::
    %{
      gateway: Server.t,
      destination: Server.t,
      file: File.t,
      storage: Storage.t
    }
  @type can_transfer_relay_partial :: %{}

  @type can_transfer_error ::
    {false, {:target, :self}, can_transfer_relay_partial}
    | FileHenforcer.belongs_to_server_error
    | StorageHenforcer.belongs_to_server_error
    | StorageHenforcer.has_enough_space_error

  @spec can_transfer?(transfer, Server.id, Server.id, Storage.id, File.id) ::
    {true, can_transfer_relay}
    | can_transfer_error
  @doc """
  Verifies the FileTransfer can be made.

  Checks:
  - File being transferred must come/go from/to a different server.
  - The file belongs to the origin server
  - The target storage can accommodate the file size
  + indirect checks along the way
  """
  def can_transfer?(type, gateway_id, endpoint_id, storage_id, file_id) do
    # Within the transfer context, `origin` is the server which owns the file,
    # and `target` is the server which the file is being transferred to.
    # However, outside this context, the caller only works with `gateway` and
    # `destination`, which depending on the transfer type (download/upload) can
    # act as both `origin` and `target`. Hence we need to "map in", from
    # gateway/destination to origin/target and, once we are returning to the
    # caller we have to "map out", returning the contextless gateway/destination

    # "Maps in", from gateway/destination to origin/target.
    {origin_id, target_id} =
      if type == :download do
        {endpoint_id, gateway_id}
      else
        {gateway_id, endpoint_id}
      end

    # "Maps out", from origin/target to gateway/destination.
    assign_to_servers = fn origin, target ->
      {gateway, destination} =
        if type == :download do
          {target, origin}
        else
          {origin, target}
        end

      %{gateway: gateway, destination: destination}
    end

    with \
      true <- gateway_id != endpoint_id || :self_target,
      # /\ A transfer must be between different servers

      # The file being downloaded belongs to the transfer's origin server
      {true, r1} <- FileHenforcer.belongs_to_server?(file_id, origin_id),
      file = r1.file,
      {r1, origin} = get_and_drop(r1, :server),

      # The destination storage belongs to the server
      {true, r2} <- StorageHenforcer.belongs_to_server?(storage_id, target_id),
      storage = r2.storage,
      {r2, target} = get_and_drop(r2, :server),

      # The destination storage has enough room for the file
      {true, r3} <- StorageHenforcer.has_enough_space?(storage, file)
    do
      r = assign_to_servers.(origin, target)

      {true, relay([r1, r2, r3, r])}
    else
      :self_target ->
        {false, {:target, :self}, %{}}
      error ->
        error
    end
  end
end
