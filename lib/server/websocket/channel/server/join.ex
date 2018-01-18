import Helix.Websocket.Join

join Helix.Server.Websocket.Channel.Server.Join do
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

  use Helix.Logger

  import HELL.Macros

  alias Helix.Event
  alias Helix.Websocket.Utils, as: WebsocketUtils
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Henforcer.Network, as: NetworkHenforcer
  alias Helix.Server.Henforcer.Channel, as: ChannelHenforcer
  alias Helix.Server.Model.Server
  alias Helix.Server.Public.Server, as: ServerPublic
  alias Helix.Server.State.Websocket.Channel, as: ServerWebsocketChannelState
  alias Helix.Server.Websocket.Channel.Server.Join, as: ServerJoin

  alias Helix.Server.Event.Server.Joined, as: ServerJoinedEvent

  @doc """
  Detects whether the join is local or remote, and delegates to the expected
  method.
  """
  def check_params(request = %ServerJoin{type: nil}, socket) do
    access =
      if request.unsafe["gateway_ip"] do
        :remote
      else
        :local
      end

    %{request| type: access}
    |> check_params(socket)
  end

  @doc """
  Verifies params for local server join.
  """
  def check_params(request = %ServerJoin{type: :local}, _socket) do
    with \
      "server:" <> server_id <- request.topic,
      {:ok, server_id} <- Server.ID.cast(server_id)
    do
      params = %{gateway_id: server_id}

      update_params(request, params, reply: true)
    else
      {false, reason, _} ->
        reply_error(request, reason)

      _ ->
        bad_request(request)
    end
  end

  @doc """
  Verifies params for remote server join.
  """
  def check_params(request = %ServerJoin{type: :remote}, _socket) do
    gateway_ip = request.unsafe["gateway_ip"]

    with \
      {:ok, data} <- get_topic_data(request.topic),
      # /\ Parse the join topic and fetch data from it

      # Validate the given NIPs are in the expected format
      {:ok, network_id, destination_ip} <-
         validate_nip(data.network_id, data.ip),
      {:ok, _, gateway_ip} <- validate_nip(network_id, gateway_ip),

      # Validate password
      {:ok, password} <- validate_input(request.unsafe["password"], :password)
    do
      params = %{
        network_id: network_id,
        gateway_ip: gateway_ip,
        destination_ip: destination_ip,
        password: password,
        unsafe_counter: data.counter
      }

      update_params(request, params, reply: true)
    else
      {false, reason, _} ->
        reply_error(request, reason)

      _ ->
        bad_request(request)
    end
  end

  @doc """
  Checks permission for local server join. Namely, the gateway server must
  belong to the player.
  """
  def check_permissions(request = %ServerJoin{type: :local}, socket) do
    entity_id = socket.assigns.entity_id
    gateway_id = request.params.gateway_id

    with \
      {true, r1} <- ChannelHenforcer.local_join_allowed?(entity_id, gateway_id)
    do
      meta = %{
        gateway: r1.server,
        entity: r1.entity
      }

      update_meta(request, meta, reply: true)
    else
      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  @doc """
  Checks permission for remote server join. Namely:

  1 - Gateway must belong to the player who is using the socket.
  2 - Password must be correct.
  3 - The given NIP must match one of the server's NIP.
  """
  def check_permissions(request = %ServerJoin{type: :remote}, socket) do
    password = request.params.password
    network_id = request.params.network_id
    gateway_ip = request.params.gateway_ip
    destination_ip = request.params.destination_ip
    entity_id = socket.assigns.entity_id
    unsafe_counter = request.params.unsafe_counter

    remote_join_allowed? = fn gateway, destination ->
      ChannelHenforcer.remote_join_allowed?(
        entity_id, gateway, destination, password
      )
    end

    valid_counter? = fn destination ->
      ChannelHenforcer.valid_counter?(
        entity_id, destination, {network_id, destination_ip}, unsafe_counter
      )
    end

    with \
      {true, r1} <- NetworkHenforcer.nip_exists?(network_id, gateway_ip),
      gateway = r1.server,
      {true, r2} <- NetworkHenforcer.nip_exists?(network_id, destination_ip),
      destination = r2.server,
      {true, r3} <- remote_join_allowed?.(gateway, destination),
      entity = r3.entity,
      {true, r4} <- valid_counter?.(destination),
      counter = r4.counter
    do
      meta = %{
        gateway: gateway,
        destination: destination,
        entity: entity,
        counter: counter
      }

      update_meta(request, meta, reply: true)
    else
      {false, {:counter, :invalid}, _} ->
        reply_error(request, "bad_counter")

      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  defp build_meta(%ServerJoin{type: :local}) do
    %{
      access: :local
    }
  end

  defp build_meta(request = %ServerJoin{type: :remote}) do
    %{
      access: :remote,
      counter: request.meta.counter,
      network_id: request.params.network_id
    }
  end

  @doc """
  Joins a local server. Note that when we've reached this point, previous
  permissions were already applied.

  Once joined, we must update the ServerWebsocketChannelState database, which
  is responsible for mapping NIPs to server IDs.
  """
  def join(request = %ServerJoin{type: :local}, socket, assign) do
    entity = request.meta.entity
    gateway = request.meta.gateway

    gateway_data = %{
      server_id: gateway.server_id,
      entity_id: entity.entity_id
    }

    socket =
      socket
      |> assign.(:access, :local)
      |> assign.(:gateway, gateway_data)
      |> assign.(:destination, gateway_data)
      |> assign.(:meta, build_meta(request))

    bootstrap =
      gateway
      |> ServerPublic.bootstrap_gateway(entity.entity_id)
      |> ServerPublic.render_bootstrap_gateway()
      |> WebsocketUtils.wrap_data()

    log :join, gateway.server_id,
      relay: request.relay,
      data: %{
        channel: :server,
        type: :local,
        gateway_id: gateway.server_id,
        status: :ok
      }

    server_joined_event(gateway, entity, :local, request.relay)

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
    network_id = request.params.network_id
    gateway_ip = request.params.gateway_ip
    destination_ip = request.params.destination_ip
    counter = request.meta.counter

    gateway = request.meta.gateway
    destination = request.meta.destination
    gateway_entity = request.meta.entity

    # Updates websocket state
    ServerWebsocketChannelState.join(
      gateway_entity.entity_id,
      destination.server_id,
      {network_id, destination_ip},
      counter
    )

    with \
      destination_entity = %{} <-
        EntityQuery.fetch_by_server(destination.server_id),
      {:ok, tunnel, ssh} <-
          ServerPublic.connect_to_server(
            gateway.server_id, destination.server_id, []
          )
    do
      gateway_data = %{
        server_id: gateway.server_id,
        entity_id: gateway_entity.entity_id,
        ip: gateway_ip
      }

      destination_data = %{
        server_id: destination.server_id,
        entity_id: destination_entity.entity_id,
        ip: destination_ip
      }

      socket =
        socket
        |> assign.(:tunnel, tunnel)
        |> assign.(:ssh, ssh)
        |> assign.(:gateway, gateway_data)
        |> assign.(:destination, destination_data)
        |> assign.(:meta, build_meta(request))

      bootstrap =
        destination
        |> ServerPublic.bootstrap_remote(destination_entity.entity_id)
        |> ServerPublic.render_bootstrap_remote()
        |> WebsocketUtils.wrap_data()

      log :join, destination.server_id,
        relay: request.relay,
        data: %{
          channel: :server,
          status: :ok,
          type: :remote,
          gateway_id: gateway.server_id,
          destination_id: destination.server_id
        }

      server_joined_event(destination, gateway_entity, :remote, request.relay)

     {:ok, bootstrap, socket}
    end
  end

  def log_error(request, _socket, reason) do
    id =
      if Enum.empty?(request.meta) do
        nil
      else
        if request.type == :local do
          request.meta.gateway.server_id
        else
          request.meta.destination.server_id
        end
      end

    log :join, id,
      relay: request.relay,
      data: %{
        channel: :server, status: :error, type: request.type, reason: reason
      }
  end

  defp server_joined_event(server, entity, type, relay) do
    server
    |> ServerJoinedEvent.new(entity, type)
    |> Event.emit(from: relay)
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
          {topic, nil}
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
end
