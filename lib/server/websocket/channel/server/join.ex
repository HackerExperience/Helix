defmodule Helix.Server.Websocket.Channel.Server.Join do
  @moduledoc """
  Joinable implementation for the Server channel.

  There are two main methods to joining a Server channel: local or remote.

  On local, player is requesting to join her own channel. In this case, nothing
  but the server ID is required. Obviously the player must be the owner of the
  server, otherwise she will be denied access to the channel.

  Remote, on the other hand, is naturally much more complex. It is called when
  a player wants to subscribe to events on a remote server (not owned by her).
  Because of this, extra params are required, including the server password and
  its nip.

  The given password and nip must match the target server, otherwise the user is
  denied access to the remote server.
  """

  require Helix.Websocket.Join

  Helix.Websocket.Join.register()

  defimpl Helix.Websocket.Joinable do

    alias Helix.Cache.Query.Cache, as: CacheQuery
    alias Helix.Entity.Query.Entity, as: EntityQuery
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Server.Henforcer.Channel, as: ChannelHenforcer
    alias Helix.Server.Public.Server, as: ServerPublic
    alias Helix.Server.Websocket.Channel.Server.Join, as: ServerJoin
    alias Helix.Server.Websocket.Channel.Server.Join.Utils, as: ServerJoinUtils

    @doc """
    Verifies params for local server join.
    """
    def check_params(request = %ServerJoin{type: :local}, _socket) do
      gateway_id = ServerJoinUtils.get_id_from_topic(request.topic)

      with \
        {:ok, gateway_id} <- Server.ID.cast(gateway_id)
      do
        params = %{
          gateway_id: gateway_id
        }

        {:ok, %{request| params: params}}
      else
        _ ->
          {:error, %{message: "bad_request"}}
      end
    end

    @doc """
    Verifies params for remote server join.
    """
    def check_params(request = %ServerJoin{type: :remote}, _socket) do
      destination_id = ServerJoinUtils.get_id_from_topic(request.topic)

      with \
        true <- not is_nil(request.unsafe["ip"]),
        {:ok, gateway_id} <- Server.ID.cast(request.unsafe["gateway_id"]),
        {:ok, destination_id} <- Server.ID.cast(destination_id),
        {:ok, network_id} <- Network.ID.cast(request.unsafe["network_id"])
      do
        params = %{
          gateway_id: gateway_id,
          destination_id: destination_id,
          network_id: network_id,
          ip: request.unsafe["ip"],
          password: request.unsafe["password"]
        }

        {:ok, %{request| params: params}}
      else
        _ ->
          {:error, %{message: "bad_request"}}
      end
    end

    @doc """
    Checks permission for local server join. Namely, the gateway server must
    belong to the player.
    """
    def check_permissions(request = %ServerJoin{type: :local}, socket) do
      entity_id = socket.assigns.entity_id
      gateway_id = request.params.gateway_id

      case ChannelHenforcer.validate_gateway(entity_id, gateway_id) do
        :ok ->
          {:ok, request}
        {:error, {subject, reason}} ->
          msg = ServerJoinUtils.format_error(subject, reason)
          {:error, %{message: msg}}
      end
    end

    @doc """
    Checks permission for remote server join. Namely:

    1 - Gateway must belong to the player who is using the socket.
    2 - Password must be correct.
    3 - The given NIP must match one of the server's NIP.
    """
    def check_permissions(request = %ServerJoin{type: :remote}, socket) do
      entity_id = socket.assigns.entity_id
      gateway_id = request.params.gateway_id
      destination_id = request.params.destination_id
      password = request.params.password
      network_id = request.params.network_id
      ip = request.params.ip

      with \
        :ok <- ChannelHenforcer.validate_gateway(entity_id, gateway_id),
        :ok <-
          ChannelHenforcer.validate_server(
            destination_id,
            password,
            network_id,
            ip)
      do
        {:ok, request}
      else
        {:error, {subject, reason}} ->
          msg = ServerJoinUtils.format_error(subject, reason)
          {:error, %{message: msg}}
      end
    end

    @doc """
    Joins a local server. Note that when we've reached this point, previous
    permissions were already applied.
    """
    def join(request = %ServerJoin{type: :local}, socket, assign) do
      gateway_id = request.params.gateway_id

      with \
        {:ok, nips} <- CacheQuery.from_server_get_nips(gateway_id)
      do
        gateway_data = %{
          server_id: gateway_id,
          entity_id: socket.assigns.entity_id,
          ips: ServerJoinUtils.format_nips(nips)
        }
        socket =
          socket
          |> assign.(:access_type, :local)
          |> assign.(:gateway, gateway_data)
          |> assign.(:destination, gateway_data)

        {:ok, socket}
      end
    end

    @doc """
    Joins a remote server. Note that when we've reached this point, previous
    permissions were already applied.

    Right before joining the remote server, an `ssh` connection is created
    between gateway and destination.
    """
    def join(request = %ServerJoin{type: :remote}, socket, assign) do
      gateway_id = request.params.gateway_id
      destination_id = request.params.destination_id
      network_id = request.params.network_id

      with \
        destination_entity = %{} <- EntityQuery.fetch_by_server(destination_id),
        {:ok, gateway_nips} <- CacheQuery.from_server_get_nips(gateway_id),
        {:ok, destination_nips} <-
          CacheQuery.from_server_get_nips(destination_id),
        {:ok, tunnel} <- ServerPublic.connect_to_server(
          gateway_id,
          destination_id,
          [])
      do
        gateway_data = %{
          server_id: gateway_id,
          entity_id: socket.assigns.entity_id,
          ips: ServerJoinUtils.format_nips(gateway_nips)
        }

        destination_data = %{
          server_id: destination_id,
          entity_id: destination_entity.entity_id,
          ips: ServerJoinUtils.format_nips(destination_nips)
        }

        socket =
          socket
          |> assign.(:network_id, network_id)
          |> assign.(:tunnel, tunnel)
          |> assign.(:access_type, :remote)
          |> assign.(:gateway, gateway_data)
          |> assign.(:destination, destination_data)

        {:ok, socket}
      end
    end
  end

  defmodule Utils do

    @doc """
    Helper to format NIPs to the expected socket assign format, which uses
    `network_id` as index.

    Example: 
      [%{network_id: network_id, ip: ip}]  ---->  %{network_id: ip}
    """
    def format_nips(nips) do
      nips
      |> Enum.reduce(%{}, fn nip, acc ->
        Map.put(acc, nip.network_id, nip.ip)
      end)
    end

    @doc """
    Gets the server ID from the specified topic.

    Example:
      "server:abcdef" -> "abcdef"
    """
    def get_id_from_topic(topic),
      do: List.last(String.split(topic, "server:"))

    def format_error(object, reason),
      do: to_string(object) <> "_" <> to_string(reason)
  end
end
