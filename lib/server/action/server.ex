defmodule Helix.Server.Action.Server do

  alias HELL.Constant
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Server.Model.Server

  @spec create(Constant.t) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates a server of given type
  """
  def create(server_type) do
    ServerInternal.create(%{server_type: server_type})
  end

  @spec attach(Server.t, Motherboard.id) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Attaches a motherboard to the server

  This function will fail if either the `motherboard_id` or the `server`
  are already attached
  """
  def attach(server, motherboard_id) do
    ServerInternal.attach(server, motherboard_id)
  end

  @spec detach(Server.t) ::
    :ok
  @doc """
  Detaches the motherboard linked to server

  This function is idempotent
  """
  def detach(server) do
    ServerInternal.detach(server)
  end

  @spec delete(Server.t | Server.id) ::
    {:ok, Server.t}
    | {:error, reason :: term}
  @doc """
  Deletes `server`
  """
  defdelegate delete(server),
    to: ServerInternal
end
