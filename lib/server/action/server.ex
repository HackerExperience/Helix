defmodule Helix.Server.Action.Server do

  alias HELL.Constant
  alias HELL.IPv4
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Model.Entity
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Network.Model.Network
  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery

  alias Helix.Server.Event.Server.Password.Acquired, as: PasswordAcquiredEvent
  alias Helix.Software.Event.Cracker.Bruteforce.Failed,
    as: BruteforceFailedEvent

  @spec create(Constant.t) ::
    {:ok, Server.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates a server of given type
  """
  def create(server_type) do
    ServerInternal.create(%{server_type: server_type})
  end

  @spec set_hostname(Server.t, Server.hostname) ::
    {:ok, Server.t}
    | {:error, :internal}
  @doc """
  Updates the server hostname
  """
  def set_hostname(server, hostname) do
    case ServerInternal.set_hostname(server, hostname) do
      {:ok, server} ->
        {:ok, server}

      {:error, _} ->
        {:error, :internal}
    end
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

  @spec delete(Server.t) ::
    :ok
  @doc """
  Deletes `server`
  """
  defdelegate delete(server),
    to: ServerInternal

  @spec crack(Entity.id, Server.id, Network.id, IPv4.t) ::
    {:ok, Server.password, [PasswordAcquiredEvent.t]}
    | {:error, :internal | {:nip, :notfound}, [BruteforceFailedEvent.t]}
  @doc """
  Cracks a server, i.e. returns its password, as well as the relevant events.

  This method is meant to be called after BruteforceConclusionEvent is emitted.

  It may fail if the target server is not found. This could happen e.g. if the
  target (victim) changed her IP while the Bruteforce process was active.

  Theoretically IP change should stop all ongoing process from the server, so
  this is just for good measure.
  """
  def crack(attacker, server_id, network_id, ip) do
    with \
      {:ok, _} <- CacheQuery.from_nip_get_server(network_id, ip),
      {:ok, password} <- ServerQuery.get_password(server_id)
    do
      event =
        PasswordAcquiredEvent.new(attacker, server_id, network_id, ip, password)

      {:ok, password, [event]}
    else
      {_, error} ->
        {reason, return} =

          # HACK: EXPERIENCE: workaround for Elixir issue 6426
          error
          |> Tuple.to_list()
          |> Enum.member?(:nip)
          |> case do
              true ->
                {:nip_notfound, {:nip, :notfound}}
              false ->
                {:internal, :internal}
            end

        failed_event =
          BruteforceFailedEvent.new(attacker, server_id, network_id, ip, reason)

        {:error, return, [failed_event]}
    end
  end
end
