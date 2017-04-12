defmodule Helix.Server.Websocket.Channel.Server do
  @moduledoc """
  Channel to notify all players connected to a certain server about events
  regarding said server
  """

  use Phoenix.Channel

  alias Helix.Network.Service.Henforcer.Network, as: NetworkHenforcer
  alias Helix.Entity.Service.API.Entity, as: EntityAPI
  alias Helix.Log.Controller.Log, as: LogController
  alias Helix.Process.Controller.Process, as: ProcessController
  alias Helix.Process.Service.API.Process, as: ProcessAPI
  alias Helix.Hardware.Service.API.Component, as: ComponentAPI
  alias Helix.Hardware.Service.API.Motherboard, as: MotherboardAPI
  alias Helix.Software.Controller.Storage, as: StorageController
  alias Helix.Software.Service.API.File, as: FileAPI
  alias Helix.Server.Service.API.Server, as: ServerAPI
  alias Helix.Server.Service.Henforcer.Server, as: Henforcer

  # Events
  alias Helix.Process.Model.Process.ProcessCreatedEvent
  alias Helix.Process.Model.Process.ProcessConclusionEvent

  @doc false
  def join(topic, message, socket)

  # Connecting to an external server
  def join("server:" <> server_id, %{"gateway_id" => gateway}, socket) do
    has_connection? = fn ->
      NetworkHenforcer.has_ssh_connection?(gateway, server_id)
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
      true <- has_connection?.() || {:error, :not_connected}
    do
      # PHEW! That means that the server exists, the player owns the specified
      # gateway and that it has an SSH connection to the target server

      socket = assign(
        socket,
        :servers,
        %{gateway: gateway, destination: server_id})

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
  def handle_in("get_files", _, socket) do
    server = ServerAPI.fetch(socket.assigns.servers.destination)
    hdds =
      server.motherboard_id
      |> ComponentAPI.fetch()
      |> MotherboardAPI.fetch!()
      |> MotherboardAPI.get_slots()
      # TODO: Delegate this to a function on Motherboard API
      # Gets hdds linked to the motherboard
      |> Enum.filter_map(
        &(&1.link_component_type == :hdd && &1.link_component_id),
        &(&1.link_component_id))

    files =
      hdds
      # FIXME: This belongs to an API function that facades this boring shit
      |> Enum.map(&StorageController.get_storage_from_hdd/1)
      |> Enum.uniq()
      |> Enum.reject(&is_nil/1)
      # Returns a map %{path => [files]}
      |> Enum.map(&FileAPI.storage_contents/1)
      |> Enum.reduce(%{}, fn el, acc ->
        # Merge the maps, so %{"foo" => [1]} and %{"foo" => [2]} becomes
        # %{"foo" => [1, 2]}
        Map.merge(acc, el, fn _k, v1, v2 -> v1 ++ v2 end)
      end)
      # HACK: FIXME: This belongs to a viewable protocol. We're doing it as it
      #   is now so it works before we do the real work (?)
      |> Enum.map(fn {path, files} ->
        files = for file <- files do
          Map.take(
            file,
            [
              :file_id,
              :name,
              :path,
              :full_path,
              :file_size,
              :software_type,
              :inserted_at,
              :updated_at])
        end

        {path, files}
      end)
      |> :maps.from_list()

    {:reply, {:ok, files}, socket}
  end

  # TODO: Paginate
  def handle_in("get_logs", _message, socket) do
    server = socket.assigns.servers.destination

    # FIXME: Log API
    # TODO: Ensure chronological order
    logs = LogController.find(server_id: server)

    # HACK: FIXME: This belongs to a viewable protocol. We're doing it as it
    #   is now so it works before we do the real work (?)
    formatted_logs = Enum.map(logs, fn log ->
      # REVIEW: How is crypto going to work on logs ?
      Map.take(log, [:log_id, :message, :crypto_version, :updated_at])
    end)

    {:reply, {:ok, formatted_logs}, socket}
  end

  def handle_in("get_processes", _message, socket) do
    server = socket.assigns.servers.destination
    processes_on_server = ProcessAPI.get_processes_on_server(server)

    processes_targeting_server = ProcessController.find(target: server)

    # HACK: FIXME: This belongs to a viewable protocol. We're doing it as it
    #   is now so it works before we do the real work (?)
    processes_on_server = Enum.map(processes_on_server, fn process ->
      Map.take(
        process,
        [
          :process_id,
          :file_id,
          :target_server_id,
          :network_id,
          :process_type,
          :state,
          :priority])
    end)
    processes_targeting_server = Enum.map(processes_targeting_server,
      fn process ->
        Map.take(
          process,
          [
            :process_id,
            :file_id,
            :target_server_id,
            :network_id,
            :process_type,
            :state,
            :priority])
    end)

    return = %{
      owned_processes: processes_on_server,
      affecting_processes: processes_targeting_server
    }

    {:reply, {:ok, return}, socket}
  end

  def notify(server_id, :processes_changed, _params) do
    # TODO: Use a view to always follow an standardized format
    notification = %{
      event: "processes_changed",
      data: %{
        server_id: server_id
      }
    }

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
end
