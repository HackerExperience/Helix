defmodule Helix.Server.Websocket.Channel.Server do
  @moduledoc """
  Channel to notify all players connected to a certain server about events
  regarding said server
  """

  use Phoenix.Channel

  alias Helix.Entity.Service.API.Entity, as: EntityAPI
  alias Helix.Hardware.Service.API.Component, as: ComponentAPI
  alias Helix.Hardware.Service.API.Motherboard, as: MotherboardAPI
  alias Helix.Log.Model.Log.LogCreatedEvent
  alias Helix.Log.Model.Log.LogModifiedEvent
  alias Helix.Log.Model.Log.LogDeletedEvent
  alias Helix.Log.Service.API.Log, as: LogAPI
  alias Helix.Network.Controller.Tunnel, as: TunnelController
  alias Helix.Network.Model.Network
  alias Helix.Network.Repo, as: NetworkRepo
  alias Helix.Network.Service.API.Tunnel, as: TunnelAPI
  alias Helix.Process.Public.ProcessView
  alias Helix.Process.Service.API.Process, as: ProcessAPI
  alias Helix.Software.Controller.Storage, as: StorageController
  alias Helix.Software.Service.API.File, as: FileAPI
  alias Helix.Software.Service.Flow.FileDownload
  alias Helix.Software.Service.Flow.LogDeleter
  alias Helix.Software.Public.View.File, as: FileView
  alias Helix.Server.Service.API.Server, as: ServerAPI
  alias Helix.Server.Service.Henforcer.Server, as: Henforcer

  # Events
  alias Helix.Process.Model.Process.ProcessCreatedEvent
  alias Helix.Process.Model.Process.ProcessConclusionEvent

  @doc false
  def join(topic, message, socket)

  # FIXME: This IS awful
  # Connecting to an external server without an established connection
  def join(
    "server:" <> server_id,
    %{
      "gateway_id" => gateway,
      "network_id" => network,
      "password" => password
    },
    socket)
  do
    # Right now i won't accept bounces. In the future we'll obviously have to
    # check them but at that time we'll have a better interface, HEnforcer and
    # proper APIs
    with \
      true <- Henforcer.server_exists?(server_id) || {:error, :not_found},
      true <- Henforcer.server_exists?(gateway) || {:error, :not_found},
      true <- Henforcer.functioning?(server_id) || {:error, :not_assembled},
      true <- Henforcer.functioning?(gateway) || {:error, :not_assembled},
      owner = EntityAPI.fetch_server_owner(gateway),
      account_id = EntityAPI.get_entity_id(socket.assigns.account),
      owner_id = EntityAPI.get_entity_id(owner),
      true <- owner_id == account_id || {:error, :not_owner},

      destination = %{} <- ServerAPI.fetch(server_id),
      true <- password == destination.password || {:error, :password},

      network = NetworkRepo.get(Network, "::"),
      {:ok, connection, events} <- TunnelAPI.connect(
        network,
        gateway,
        server_id,
        [],
        "ssh"),
      tunnel = NetworkRepo.preload(connection, :tunnel).tunnel
    do
      # Yup, most of the code in this function does not belongs here. It'll be
      # moved around (and be properly tested) ASAP
      Helix.Event.emit(events)

      socket =
        socket
        |> assign(:servers, %{gateway: gateway, destination: server_id})
        |> assign(:tunnel, tunnel)

      {:ok, socket}
    else
      {:error, :not_found} ->
        {:error, %{reason: "invalid server"}}
      {:error, :not_assembled} ->
        {:error, %{reason: "server is not assembled"}}
      {:error, :not_owner} ->
        {:error, %{reason: "player is not the server owner"}}
      {:error, :password} ->
        {:error, %{reason: "invalid password"}}
    end
  end

  # Connecting to an external server
  def join("server:" <> server_id, %{"gateway_id" => gateway}, socket) do
    # FIXME: this doesn't belongs here
    get_tunnel_for_ssh = fn ->
      connections_between = TunnelController.connections_on_tunnels_between(
        gateway,
        server_id)

      case Enum.find(connections_between, &(&1.connection_type == "ssh")) do
        connection = %{} ->
          {:ok, TunnelController.fetch(connection.tunnel_id)}
        _ ->
          {:error, :not_connected}
      end
    end

    with \
      true <- Henforcer.server_exists?(server_id) || {:error, :not_found},
      true <- Henforcer.server_exists?(gateway) || {:error, :not_found},
      true <- Henforcer.functioning?(server_id) || {:error, :not_assembled},
      true <- Henforcer.functioning?(gateway) || {:error, :not_assembled},
      owner = EntityAPI.fetch_server_owner(gateway),
      account_id = EntityAPI.get_entity_id(socket.assigns.account),
      owner_id = EntityAPI.get_entity_id(owner),
      true <- owner_id == account_id || {:error, :not_owner},
      {:ok, tunnel} <- get_tunnel_for_ssh.()
    do
      # PHEW! That means that the server exists, the player owns the specified
      # gateway and that it has an SSH connection to the target server

      socket =
        socket
        |> assign(:servers, %{gateway: gateway, destination: server_id})
        |> assign(:tunnel, tunnel)

      {:ok, socket}
    else
      {:error, :not_found} ->
        {:error, %{reason: "invalid server"}}
      {:error, :not_assembled} ->
        {:error, %{reason: "server is not assembled"}}
      {:error, :not_owner} ->
        {:error, %{reason: "player is not the server owner"}}
      {:error, :not_connected} ->
        {:error, %{reason: "gateway is not connected to target server"}}
    end
  end

  # Connecting to player's own gateways
  def join("server:" <> server_id, _, socket) do
    with \
      true <- Henforcer.server_exists?(server_id) || {:error, :not_found},
      true <- Henforcer.functioning?(server_id) || {:error, :not_assembled},
      owner = EntityAPI.fetch_server_owner(server_id),
      account = socket.assigns.account,
      owner_id = EntityAPI.get_entity_id(owner),
      account_id = EntityAPI.get_entity_id(account),
      true <- owner_id == account_id || {:error, :not_owner}
    do
      socket = assign(
        socket,
        :servers,
        %{gateway: server_id, destination: server_id})

      {:ok, socket}
    else
      {:error, :not_found} ->
        {:error, %{reason: "invalid server"}}
      {:error, :not_assembled} ->
        {:error, %{reason: "server is not assembled"}}
      {:error, :not_owner} ->
        {:error, %{reason: "player is not the server owner"}}
    end
  end

  @doc false
  def handle_in("file.index", _, socket) do
    files =
      socket.assigns.servers.destination
      |> ServerAPI.fetch()
      |> storages_on_server()
      # Returns a map %{path => [files]}
      |> Enum.map(&FileAPI.storage_contents/1)
      |> Enum.reduce(%{}, fn el, acc ->
        # Merge the maps, so %{"foo" => [1]} and %{"foo" => [2]} becomes
        # %{"foo" => [1, 2]}
        Map.merge(acc, el, fn _k, v1, v2 -> v1 ++ v2 end)
      end)
      |> Enum.map(fn {path, files} ->
        files = Enum.map(files, &FileView.render/1)

        {path, files}
      end)
      |> :maps.from_list()

    {:reply, {:ok, files}, socket}
  end

  # TODO: Paginate
  def handle_in("log.index", _message, socket) do
    server_id = socket.assigns.servers.destination

    logs = LogAPI.get_logs_on_server(server_id)

    # HACK: FIXME: This belongs to a viewable protocol. We're doing it as it
    #   is now so it works before we do the real work (?)
    formatted_logs = Enum.map(logs, fn log ->
      Map.take(log, [:log_id, :message, :inserted_at])
    end)

    {:reply, {:ok, %{data: %{logs: formatted_logs}}}, socket}
  end

  def handle_in("log.delete", %{log_id: log}, socket) do
    target_id = socket.assigns.servers.destination
    gateway_id = socket.assigns.servers.gateway
    network_id = "::"

    with \
      %{server_id: ^target_id} <- LogAPI.fetch(log),
      {:ok, _} <- LogDeleter.start_process(gateway_id, network_id, log)
    do
      {:reply, :ok, socket}
    else
      _ ->
        {:reply, :error, socket}
    end
  end

  def handle_in("process.index", _message, socket) do
    server = socket.assigns.servers.destination
    processes_on_server = ProcessAPI.get_processes_on_server(server)

    processes_targeting_server = ProcessAPI.get_processes_targeting_server(
      server)

    entity = EntityAPI.get_entity_id(socket.assigns.account)
    processes_on_server = Enum.map(processes_on_server, fn process ->
      ProcessView.render(process.process_data, process, server, entity)
    end)
    processes_targeting_server = Enum.map(processes_targeting_server, fn
      process ->
        ProcessView.render(process.process_data, process, server, entity)
    end)

    return = %{
      owned_processes: processes_on_server,
      affecting_processes: processes_targeting_server
    }

    {:reply, {:ok, return}, socket}
  end

  # TODO: This will hard fail if the user tries to download a file from their
  #   own gateway for obvious reasons
  def handle_in("file.download", %{file_id: file}, socket) do
    # This won't be necessary as soon as we have a cache server->storages
    destination_storage_ids =
      socket.assigns.servers.destination
      |> ServerAPI.fetch()
      |> storages_on_server()
      |> Enum.map(&(&1.storage_id))

    # FIXME
    gateway_storage =
      socket.assigns.servers.gateway
      |> ServerAPI.fetch()
      |> storages_on_server()
      |> Enum.random()

    tunnel = socket.assigns.tunnel

    start_download = fn file ->
      FileDownload.start_download_process(file, gateway_storage, tunnel)
    end

    with \
      file = %{} <- FileAPI.fetch(file),
      true <- file.storage_id in destination_storage_ids,
      {:ok, _process} <- start_download.(file)
    do
      {:reply, :ok, socket}
    else
      _ ->
        {:reply, :error, socket}
    end
  end

  @spec storages_on_server(struct) ::
    [struct]
  defp storages_on_server(server) do
    server.motherboard_id
    |> ComponentAPI.fetch()
    |> MotherboardAPI.fetch!()
    |> MotherboardAPI.get_slots()
    # TODO: Delegate this to a function on Motherboard API
    # Gets hdds linked to the motherboard
    |> Enum.filter_map(
      &(&1.link_component_type == :hdd && &1.link_component_id),
      &(&1.link_component_id))
    # FIXME: This belongs to an API function that facades this boring shit
    |> Enum.map(&StorageController.get_storage_from_hdd/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  def notify(server_id, :processes_changed, _params) do
    # TODO: Use a view to always follow an standardized format
    notify(server_id, %{
      event: "processes_changed",
      data: %{}
    })
  end

  def notify(server_id, :logs_changed, _params) do
    # TODO: Use a view to always follow an standardized format
    notify(server_id, %{
      event: "logs_changed",
      data: %{}
    })
  end

  defp notify(server_id, notification) do
    topic = "server:" <> server_id

    Helix.Endpoint.broadcast(topic, "notification", notification)
  end

  @doc false
  def event_process_created(
    %ProcessCreatedEvent{gateway_id: gateway, target_id: gateway})
  do
    notify(gateway, :processes_changed, %{})
  end
  def event_process_created(
    %ProcessCreatedEvent{gateway_id: gateway, target_id: target})
  do
    notify(gateway, :processes_changed, %{})
    notify(target, :processes_changed, %{})
  end

  @doc false
  def event_process_conclusion(
    %ProcessConclusionEvent{gateway_id: gateway, target_id: gateway})
  do
    notify(gateway, :processes_changed, %{})
  end
  def event_process_conclusion(
    %ProcessConclusionEvent{gateway_id: gateway, target_id: target})
  do
    notify(gateway, :processes_changed, %{})
    notify(target, :processes_changed, %{})
  end

  @doc false
  def event_log_created(%LogCreatedEvent{server_id: server}),
    do: notify(server, :logs_changed, %{})

  @doc false
  def event_log_modified(%LogModifiedEvent{server_id: server}),
    do: notify(server, :logs_changed, %{})

  @doc false
  def event_log_deleted(%LogDeletedEvent{server_id: server}),
    do: notify(server, :logs_changed, %{})
end
