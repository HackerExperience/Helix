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

    import HELL.Macros

    alias HELL.IPv4
    alias Helix.Websocket.Utils, as: WebsocketUtils
    alias Helix.Cache.Query.Cache, as: CacheQuery
    alias Helix.Entity.Query.Entity, as: EntityQuery
    alias Helix.Network.Model.Network
    alias Helix.Server.Henforcer.Channel, as: ChannelHenforcer
    alias Helix.Server.Public.Server, as: ServerPublic
    alias Helix.Server.State.Websocket.Channel, as: ServerWebsocketChannelState
    alias Helix.Server.Websocket.Channel.Server.Join, as: ServerJoin
    alias Helix.Server.Websocket.Channel.Server.Join.Utils, as: ServerJoinUtils

    @doc """
    Detects whether the join is local or remote, and delegates to the expected
    method.
    """
    def check_params(request = %ServerJoin{type: nil}, socket) do
      access_type =
        if request.unsafe["gateway_ip"] do
          :remote
        else
          :local
        end

      %{request| type: access_type}
      |> check_params(socket)
    end

    @doc """
    Verifies params for local server join.
    """
    def check_params(request = %ServerJoin{type: :local}, _socket) do
      with \
        {:ok, data} <- get_topic_data(request.topic),
        {:ok, network_id} <- Network.ID.cast(data.network_id),
        true <- IPv4.valid?(data.ip),
        {:ok, server_id} <-
          CacheQuery.from_nip_get_server(network_id, data.ip)
      do
        params = %{
          network_id: network_id,
          gateway_ip: data.ip,
          gateway_id: server_id,
          counter: 0
        }

        {:ok, %{request| params: params}}
      else
        # Fix when elixir-lang issue #6426 gets fixed
        # :badserver ->
        #   {:error, %{message: "nip_not_found"}}
        _ ->
          {:error, %{message: "bad_request"}}
      end
    end

    @doc """
    Verifies params for remote server join.
    """
    def check_params(request = %ServerJoin{type: :remote}, socket) do
      gateway_ip = request.unsafe["gateway_ip"]
      entity_id = socket.assigns.entity_id

      with \
        {:ok, data} <- get_topic_data(request.topic),
        {:ok, network_id} <- Network.ID.cast(data.network_id),
        true <- IPv4.valid?(data.ip),
        true <- IPv4.valid?(gateway_ip),
        true <- not is_nil(gateway_ip),
        {:ok, gateway_id} <-
          CacheQuery.from_nip_get_server(network_id, gateway_ip),
        {:ok, destination_id} <-
          CacheQuery.from_nip_get_server(network_id, data.ip),
        {valid_counter?, counter} =
          validate_counter(
            entity_id,
            destination_id,
            {network_id, data.ip},
            data.counter
          ),
        true <- valid_counter? || :bad_counter
      do
        params = %{
          network_id: network_id,
          gateway_id: gateway_id,
          gateway_ip: gateway_ip,
          destination_id: destination_id,
          destination_ip: data.ip,
          counter: counter,
          password: request.unsafe["password"]
        }

        {:ok, %{request| params: params}}
      else
        # Fix when elixir-lang issue #6426 gets fixed
        # :badserver ->
        #   {:error, %{message: "nip_not_found"}}
        # :internal ->
        #   {:error, %{message: "internal"}}
        :bad_counter ->
          {:error, %{message: "bad_counter"}}
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
      destination_ip = request.params.destination_ip

      with \
        :ok <- ChannelHenforcer.validate_gateway(entity_id, gateway_id),
        :ok <-
          ChannelHenforcer.validate_server(
            destination_id,
            password,
            network_id,
            destination_ip)
      do
        {:ok, request}
      else
        {:error, {subject, reason}} ->
          msg = ServerJoinUtils.format_error(subject, reason)
          {:error, %{message: msg}}
      end
    end

    defp build_meta(request) do
      access_type =
        if Map.has_key?(request.params, :password) do
          :remote
        else
          :local
        end

      %{
        counter: request.params.counter,
        network_id: request.params.network_id,
        access_type: access_type
      }
    end

    @doc """
    Joins a local server. Note that when we've reached this point, previous
    permissions were already applied.

    Once joined, we must update the ServerWebsocketChannelState database, which
    is responsible for mapping NIPs to server IDs.
    """
    def join(request = %ServerJoin{type: :local}, socket, assign) do
      entity_id = socket.assigns.entity_id
      gateway_id = request.params.gateway_id
      gateway_ip = request.params.gateway_ip
      network_id = request.params.network_id
      counter = request.params.counter

      # Updates websocket state
      ServerWebsocketChannelState.join(
        entity_id,
        gateway_id,
        {network_id, gateway_ip},
        counter
      )

      gateway_data = %{
        server_id: gateway_id,
        entity_id: entity_id,
        ip: gateway_ip
      }

      socket =
        socket
        |> assign.(:access_type, :local)
        |> assign.(:gateway, gateway_data)
        |> assign.(:destination, gateway_data)
        |> assign.(:meta, build_meta(request))

      bootstrap =
        gateway_id
        |> ServerPublic.bootstrap(entity_id)
        |> ServerPublic.render_bootstrap()
        |> WebsocketUtils.wrap_data()

      {:ok, bootstrap, socket}
    end

    @doc """
    Joins a remote server. Note that when we've reached this point, previous
    permissions were already applied.

    Right before joining the remote server, an `ssh` connection is created
    between gateway and destination.

    Once joined, we must update the ServerWebsocketChannelState database, which
    is responsible for mapping NIPs to server IDs.
    """
    def join(request = %ServerJoin{type: :remote}, socket, assign) do
      gateway_entity_id = socket.assigns.entity_id
      network_id = request.params.network_id
      gateway_id = request.params.gateway_id
      gateway_ip = request.params.gateway_ip
      destination_id = request.params.destination_id
      destination_ip = request.params.destination_ip
      counter = request.params.counter

      # Updates websocket state
      ServerWebsocketChannelState.join(
        gateway_entity_id,
        destination_id,
        {network_id, destination_ip},
        counter
      )

      with \
        destination_entity = %{} <- EntityQuery.fetch_by_server(destination_id),
        {:ok, tunnel} <- ServerPublic.connect_to_server(
          gateway_id,
          destination_id,
          [])
      do
        gateway_data = %{
          server_id: gateway_id,
          entity_id: gateway_entity_id,
          ip: gateway_ip
        }

        destination_data = %{
          server_id: destination_id,
          entity_id: destination_entity.entity_id,
          ip: destination_ip
        }

        socket =
          socket
          |> assign.(:tunnel, tunnel)
          |> assign.(:gateway, gateway_data)
          |> assign.(:destination, destination_data)
          |> assign.(:meta, build_meta(request))

        bootstrap =
          destination_id
          |> ServerPublic.bootstrap(destination_entity.entity_id)
          |> ServerPublic.render_bootstrap()
          |> WebsocketUtils.wrap_data()

        {:ok, bootstrap, socket}
      end
    end

    docp """
    Iterates through the topic name, extract all data from it.
    """
    defp get_topic_data("server:" <> topic) do
      try do
        # Below splits are equivalent to the following pattern match:
        # `network_id <> "@" <> ip [<> "#" <> counter]`
        # Unfortunately, pattern-matching on such string with dynamic byte size
        # is not possible/trivial on erlang/elixir.
        [network_id, topic] = String.split(topic, "@", parts: 2)

        {ip, counter} =
          # If `topic` contains "#" then a counter was explicitly set.
          if String.contains?(topic, "#") do
            [ip, counter] = String.split(topic, "#", parts: 2)
            {ip, String.to_integer(counter)}

          # If counter was not specified, set it as `nil`. Later, the request
          # will figure out what is the next counter expected to be.
          else
            ip = topic
            {ip, nil}
          end

        data =
          %{
            network_id: network_id,
            ip: ip,
            counter: counter
          }

        {:ok, data}
      rescue
        _ ->
          :error
      end
    end

    docp """
    Validates and returns the next counter. If the given counter was `nil`, it

    Helix should automatically set it to the correct result.
    """
    defp validate_counter(entity_id, server_id, nip, nil) do
      next_counter =
        ServerWebsocketChannelState.get_next_counter(entity_id, server_id, nip)

      {true, next_counter}
    end
    defp validate_counter(entity_id, server_id, nip, counter) do
      valid? =
        ServerWebsocketChannelState.valid_counter?(
          entity_id,
          server_id,
          nip,
          counter
        )

      {valid?, counter}
    end
  end

  defmodule Utils do
    def format_error(object, reason),
      do: to_string(object) <> "_" <> to_string(reason)
  end
end
