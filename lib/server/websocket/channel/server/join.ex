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

  import HELL.Macros

  alias Helix.Websocket.Utils, as: WebsocketUtils
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Henforcer.Network, as: NetworkHenforcer
  alias Helix.Server.Henforcer.Channel, as: ChannelHenforcer
  alias Helix.Server.Public.Server, as: ServerPublic
  alias Helix.Server.State.Websocket.Channel, as: ServerWebsocketChannelState
  alias Helix.Server.Websocket.Channel.Server.Join, as: ServerJoin

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
      # /\ Parse the join topic and fetch data from it

      # Validate gateway nip
      {:ok, network_id, ip} <- validate_nip(data.network_id, data.ip),

      # Ensure gateway nip exists
      {true, relay} <- NetworkHenforcer.nip_exists?(network_id, ip)
    do
      params = %{
        network_id: network_id,
        gateway_ip: data.ip,
        gateway_id: relay.server_id,
        counter: 0
      }

      update_params(request, params, reply: true)
    else
      {false, reason, _} ->
        reply_error(reason)

      _ ->
        bad_request()
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
      # /\ Parse the join topic and fetch data from it

      # Validate the given NIPs are in the expected format
      {:ok, network_id, destination_ip} <-
         validate_nip(data.network_id, data.ip),
      {:ok, _, gateway_ip} <- validate_nip(network_id, gateway_ip),

      # Ensure the given nips exist on the DB
      {true, relay} <- NetworkHenforcer.nip_exists?(network_id, gateway_ip),
      gateway_id = relay.server_id,
      {true, relay} <- NetworkHenforcer.nip_exists?(network_id, destination_ip),
      destination_id = relay.server_id,

      # Validate password
      {:ok, password} <- validate_input(request.unsafe["password"], :password),

      {valid_counter?, counter} =
        validate_counter(
          entity_id,
          destination_id,
          {network_id, destination_ip},
          data.counter
        ),
      true <- valid_counter? || :bad_counter
    do
      params = %{
        network_id: network_id,
        gateway_id: gateway_id,
        gateway_ip: gateway_ip,
        destination_id: destination_id,
        destination_ip: destination_ip,
        counter: counter,
        password: password
      }

      update_params(request, params, reply: true)
    else
      {false, reason, _} ->
        reply_error(reason)

      :bad_counter ->
        reply_error("bad_counter")

      _ ->
        bad_request()
    end
  end

  @doc """
  Checks permission for local server join. Namely, the gateway server must
  belong to the player.
  """
  def check_permissions(request = %ServerJoin{type: :local}, socket) do
    entity_id = socket.assigns.entity_id
    gateway_id = request.params.gateway_id

    case ChannelHenforcer.local_join_allowed?(entity_id, gateway_id) do
      {true, relay} ->
        meta = %{gateway: relay.server, entity: relay.entity}

        update_meta(request, meta, reply: true)

      {false, reason, _} ->
        reply_error(reason)
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

    remote_join_allowed? =
      ChannelHenforcer.remote_join_allowed?(
        entity_id,
        gateway_id,
        destination_id,
        password
      )

    case remote_join_allowed? do
      {true, relay} ->
        meta = %{
          gateway: relay.gateway,
          destination: relay.destination,
          entity: relay.entity
        }

        update_meta(request, meta, reply: true)

      {false, reason, _} ->
        reply_error(reason)
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
    gateway_ip = request.params.gateway_ip
    network_id = request.params.network_id
    counter = request.params.counter

    entity = request.meta.entity
    gateway = request.meta.gateway

    # Updates websocket state
    ServerWebsocketChannelState.join(
      entity.entity_id,
      gateway.server_id,
      {network_id, gateway_ip},
      counter
    )

    gateway_data = %{
      server_id: gateway.server_id,
      entity_id: entity.entity_id,
      ip: gateway_ip
    }

    socket =
      socket
      |> assign.(:access_type, :local)
      |> assign.(:gateway, gateway_data)
      |> assign.(:destination, gateway_data)
      |> assign.(:meta, build_meta(request))

    bootstrap =
      gateway
      |> ServerPublic.bootstrap_gateway(entity.entity_id)
      |> ServerPublic.render_bootstrap_gateway()
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
    network_id = request.params.network_id
    gateway_ip = request.params.gateway_ip
    destination_ip = request.params.destination_ip
    counter = request.params.counter

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
      {:ok, tunnel} <- ServerPublic.connect_to_server(
        gateway.server_id,
        destination.server_id,
        [])
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
        |> assign.(:gateway, gateway_data)
        |> assign.(:destination, destination_data)
        |> assign.(:meta, build_meta(request))

      bootstrap =
        destination
        |> ServerPublic.bootstrap_remote(destination_entity.entity_id)
        |> ServerPublic.render_bootstrap_remote()
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
